# frozen_string_literal: true

require "jwt"
require "securerandom"

module Auth
  class JwtToken
    ALGORITHM = "HS256"
    EXPIRY_SECONDS = 86_400

    class << self
      def issue(client_id:, expires_in: EXPIRY_SECONDS)
        payload = {
          sub: client_id.to_s,
          iat: Time.now.to_i,
          exp: Time.now.to_i + expires_in
        }
        JWT.encode(payload, signing_key, ALGORITHM)
      end

      def valid?(token)
        return false if token.to_s.empty?

        JWT.decode(token, signing_key, true, { algorithm: ALGORITHM })
        true
      rescue JWT::DecodeError
        false
      end

      def reset!
        @signing_key = nil
      end

      private

      def signing_key
        @signing_key ||= SecureRandom.hex(32)
      end
    end
  end
end
