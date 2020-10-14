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

    BASE_URL = "https://app.samsys.io/api/v1".freeze
    TOKEN_URL = BASE_URL + "/auth".freeze

    authenticate_with :check do
      parameter :email
      parameter :password
    end

    calls :get_token

    # Get token with login and password
    #DOC https://doc.samsys.io/#api-Authentication-Authentication
    def get_token
      integration = fetch
      payload = {"email": integration.parameters['email'], "password": integration.parameters['password']}
      post_json(TOKEN_URL, payload) do |r|
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
    # https://doc.samsys.io/#api-Authentication-Authentication
    def check(integration = nil)
      integration = fetch integration
      puts integration.inspect.red
      payload = {"email": integration.parameters['email'], "password": integration.parameters['password']}
      post_json(TOKEN_URL, payload) do |r|
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
