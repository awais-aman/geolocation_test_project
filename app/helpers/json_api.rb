# frozen_string_literal: true

module Helpers
  module JsonApi
    CONTENT_TYPE = 'application/vnd.api+json'
    AUTH_SESSION_TYPE = 'auth_sessions'

    def render_json_api(resource, status: 200)
      content_type CONTENT_TYPE
      status status
      GeolocationSerializer.render(resource, self_link: request.fullpath).to_json
    end

    def parse_lookup_query_from_request
      data = parse_json_api_data!(GeolocationSerializer::TYPE)
      data.dig('attributes', 'query')
    end

    def parse_login_credentials_from_request
      data = parse_json_api_data!(AUTH_SESSION_TYPE)
      client_id = data.dig('attributes', 'client_id')
      client_secret = data.dig('attributes', 'client_secret')

      if client_id.to_s.strip.empty? || client_secret.to_s.strip.empty?
        raise Geolocator::Errors::BadRequest, 'client_id and client_secret are required'
      end

      [client_id, client_secret]
    end

    def parse_json_api_data!(expected_type)
      request.body.rewind
      payload = JSON.parse(request.body.read)
      data = payload.fetch('data') do
        raise Geolocator::Errors::BadRequest, 'data object is required'
      end
      raise Geolocator::Errors::BadRequest, "data.type must be #{expected_type}" unless data['type'] == expected_type

      data
    rescue JSON::ParserError
      raise Geolocator::Errors::BadRequest, 'Request body must be valid JSON'
    end
  end
end
