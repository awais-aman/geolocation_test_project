# frozen_string_literal: true

require 'faraday'
require 'json'

module Geolocator
  module Providers
    class Ipstack < Geolocator::Provider
      BASE_URL = 'https://api.ipstack.com'

      def initialize(access_key: ENV.fetch('IPSTACK_ACCESS_KEY', nil), http_client: nil)
        super()
        @access_key = access_key
        @http_client = http_client
      end

      def lookup_ip(ip_address)
        raise Errors::ProviderMisconfigured if @access_key.to_s.strip.empty?

        response = connection.get("/#{ip_address}") do |request|
          request.params['access_key'] = @access_key
        end

        parse_response(response.body)
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError => e
        raise Errors::ProviderUnavailable, "ipstack connection failed: #{e.message}"
      rescue Faraday::Error => e
        raise Errors::ProviderError, "ipstack request failed: #{e.message}"
      end

      private

      def connection
        @http_client || @connection ||= Faraday.new(url: BASE_URL) do |faraday|
          faraday.options.timeout = 10
          faraday.options.open_timeout = 5
          faraday.response :raise_error
        end
      end

      def parse_response(response_body)
        provider_response = JSON.parse(response_body)
        raise Errors::ProviderError, 'ipstack returned invalid JSON' unless provider_response.is_a?(Hash)

        if provider_response['success'] == false
          provider_error = provider_response.fetch('error', {})
          raise Errors::ProviderError.new(
            provider_error['info'] || 'ipstack request failed',
            status: map_provider_status(provider_error['code'])
          )
        end

        Result.from_hash(
          resolved_ip: provider_response['ip'],
          latitude: provider_response['latitude'],
          longitude: provider_response['longitude'],
          country_name: provider_response['country_name'],
          country_code: provider_response['country_code'],
          region_name: provider_response['region_name'],
          city: provider_response['city'],
          raw_response: provider_response
        )
      rescue JSON::ParserError
        raise Errors::ProviderError, 'ipstack returned invalid JSON'
      end

      def map_provider_status(code)
        case code
        when 101, 102, 103 then :service_unavailable
        when 104 then :too_many_requests
        when 301 then :not_found
        else :bad_gateway
        end
      end
    end
  end
end
