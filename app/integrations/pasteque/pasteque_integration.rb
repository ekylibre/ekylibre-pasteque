require 'rest-client'

module Pasteque
  mattr_reader :default_options do
    {
      globals: {
        strip_namespaces: true,
        convert_response_tags_to: ->(tag) { tag.snakecase.to_sym },
        raise_errors: true
      },
      locals: {
        advanced_typecasting: true
      }
    }
  end

  class ServiceError < StandardError; end

  class PastequeIntegration < ActionIntegration::Base
    # Set url needed for Pasetque API v8

    TOKEN_URL = "/api/login".freeze

    authenticate_with :check do
      parameter :host
      parameter :login
      parameter :password
    end

    calls :get_token

    # Get token with login and password
    def get_token
      integration = fetch
      payload = {"login": integration.parameters['login'], "password": integration.parameters['password']}
      post_json(integration.parameters['host'] + TOKEN_URL, payload) do |r|
        r.error :api_down unless r.body.include? 'ok'
        r.success do
          list = JSON(r.body).deep_symbolize_keys
          integration.parameters['token'] = list[:jwt]
          integration.save!
          Rails.logger.info 'CHECKED'.green
        end
      end
    end

    # Check if the API is up
    def check(integration = nil)
      integration = fetch integration
      puts integration.inspect.red
      payload = {"login": integration.parameters['login'], "password": integration.parameters['password']}
      post_json(integration.parameters['host'] + TOKEN_URL, payload) do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
          if list[:status] == 'ok'
            puts "check success".inspect.green
            Rails.logger.info 'CHECKED'.green
          end
          r.error :wrong_password if list[:status] == '401'
          r.error :no_account_exist if list[:status] == '404'
        end
      end
    end

  end
end
