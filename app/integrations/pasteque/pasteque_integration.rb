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
    PAYMENT_MODES_URL = "/api/paymentmode/getAll".freeze
    CASH_REGISTER_URL = "/api/cashregister/getAll".freeze
    SEARCH_TICKET_URL = "/api/ticket/search".freeze
    TAX_URL = "/api/tax/getAll".freeze

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

    calls :get_token, :fetch_category, :fetch_taxes, :fetch_product_by_category, :fetch_payment_modes, :fetch_cash_registers, :set_token, :fetch_tickets

    # Get token with login and password
    def get_token
      integration = fetch
      payload = {"user": integration.parameters['user'], "password": integration.parameters['password']}
      post_json(integration.parameters['host'] + TOKEN_URL, payload) do |r|
        r.success do
          JSON(r.body)
        end
      end
    end

    def fetch_category(token)
      integration = fetch
      # Call API
      get_json(integration.parameters['host'] + CATEGORY_URL, 'Token' => token) do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
          response(r, list: list)
        end
      end
    end

    def fetch_taxes(token)
      integration = fetch
      # Call API
      get_json(integration.parameters['host'] + TAX_URL, 'Token' => token) do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
          response(r, list: list)
        end
      end
    end

    def fetch_product_by_category(category_id, token)
      integration = fetch
      # Call API
      get_json(integration.parameters['host'] + PROD_BY_CATEGORY_URL + category_id.to_s, 'Token' => token) do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
          response(r, list: list)
        end
      end
    end

    def fetch_payment_modes(token)
      integration = fetch
      # Call API
      get_json(integration.parameters['host'] + PAYMENT_MODES_URL, 'Token' => token) do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
          response(r, list: list)
        end
      end
    end

    def fetch_cash_registers(token)
      integration = fetch
      # Call API
      get_json(integration.parameters['host'] + CASH_REGISTER_URL, 'Token' => token) do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
          response(r, list: list)
        end
      end
    end

    def fetch_tickets(token, cash_register_id = nil, start = nil, stop = nil)
      integration = fetch
      params = {}
      params['Token'] = token
      if cash_register_id
        params['cashRegister'] = cash_register_id
      end
      # Call API
      get_json(integration.parameters['host'] + SEARCH_TICKET_URL, params) do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
          response(r, list: list)
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

    def response(r, **values)
      { token: r.headers['token'].first, **values }.to_struct
    end

  end
end
