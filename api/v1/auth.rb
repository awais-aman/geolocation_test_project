# frozen_string_literal: true

require "sinatra/base"

module Api
  module V1
    module Auth
      def self.registered(app)
        app.helpers Helpers::JsonApi

        app.namespace "/api/v1/auth" do
          post "/login" do
            client_id, client_secret = parse_login_credentials_from_request
            unless ApiClient.authenticate(client_id: client_id, client_secret: client_secret)
              raise Geolocator::Errors::Unauthorized, "Invalid client credentials"
            end

            access_token = ::Auth::JwtToken.issue(client_id: client_id)

            status 200
            {
              jsonapi: { version: GeolocationSerializer::JSONAPI_VERSION },
              data: {
                type: Helpers::JsonApi::AUTH_SESSION_TYPE,
                id: "current",
                attributes: {
                  access_token: access_token,
                  token_type: "Bearer",
                  expires_in: ::Auth::JwtToken::EXPIRY_SECONDS
                }
              },
              links: { self: "/api/v1/auth/login" }
            }.to_json
          end
        end
      end
    end
  end
end
