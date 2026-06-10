# frozen_string_literal: true

module Middleware
  class Authentication
    PUBLIC_PATHS = %w[
      /
      /api-docs
      /openapi.yaml
      /api/v1/auth/login
    ].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) if public_path?(env["PATH_INFO"])

      bearer_token = env["HTTP_AUTHORIZATION"]&.sub(/\ABearer\s+/i, "")
      raise Geolocator::Errors::Unauthorized unless Auth::JwtToken.valid?(bearer_token)

      @app.call(env)
    end

    def public_path?(path)
      PUBLIC_PATHS.include?(normalize_path(path))
    end

    def normalize_path(path)
      normalized = path.to_s.chomp("/")
      normalized.empty? ? "/" : normalized
    end
  end
end
