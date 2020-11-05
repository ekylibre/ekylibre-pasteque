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
    CATEGORY_URL = "/api/category/getAll".freeze
    PROD_BY_CATEGORY_URL = "/api/product/getByCategory/".freeze
    PAYMENT_MODES_URL = "/api/paymentmodes/getAll".freeze
    CASH_REGISTER_URL = "/api/cashregister/getAll".freeze

    authenticate_with :check do
      parameter :host
      parameter :user
      parameter :password
    end

    # for testing the API in console
    # host = 'https://5.pasteque.pro/8'
    # TOKEN_URL = "/api/login".freeze
    # call_url = host + TOKEN_URL
    # user = 'ekylibre'
    # password = 'pasteque'
    # payload = {"login": login, "password": password}
    # r =

    calls :get_token, :fetch_category, :fetch_product_by_category, :fetch_payment_modes, :fetch_cash_registers

    # Get token with login and password
    def get_token
      integration = fetch
      payload = {"user": integration.parameters['user'], "password": integration.parameters['password']}
      post_json(integration.parameters['host'] + TOKEN_URL, payload) do |r|
        r.success do
          list = JSON(r.body)
          integration.parameters['token'] = list
          integration.save!
          Rails.logger.info 'CHECKED'.green
        end
      end
    end

    def fetch_category
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end
      # Call API
      get_json(integration.parameters['host'] + CATEGORY_URL, 'Token' => integration.parameters['token']) do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
        end
      end
    end

    def fetch_product_by_category(category_id)
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end
      # Call API
      get_json(integration.parameters['host'] + PROD_BY_CATEGORY_URL + category_id.to_s, 'Token' => integration.parameters['token']) do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
        end
      end
    end

    def fetch_payment_modes
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end
      # Call API
      get_json(integration.parameters['host'] + PAYMENT_MODES_URL, 'Token' => integration.parameters['token']) do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
        end
      end
    end

    def fetch_cash_registers
      integration = fetch
      # Get token
      if integration.parameters['token'].blank?
        get_token
      end
      # Call API
      get_json(integration.parameters['host'] + CASH_REGISTER_URL, 'Token' => integration.parameters['token']) do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
        end
      end
    end

    # Check if the API is up
    def check(integration = nil)
      integration = fetch integration
      payload = {"user": integration.parameters['user'], "password": integration.parameters['password']}
      post_json(integration.parameters['host'] + TOKEN_URL, payload) do |r|
        r.success do
          list = JSON(r.code)
          if list == '200'
            puts "check success".inspect.green
            Rails.logger.info 'CHECKED'.green
          end
          r.error :wrong_password if list == '401'
          r.error :no_account_exist if list == '404'
        end
      end
    end

  end
end
