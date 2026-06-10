# frozen_string_literal: true

module Middleware
  class ErrorHandler
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue Geolocator::Errors::Base => e
      render_error(e)
    rescue ActiveRecord::RecordNotFound
      render_error(Geolocator::Errors::NotFound.new)
    rescue ActiveRecord::RecordNotUnique
      render_error(Geolocator::Errors::Conflict.new)
    rescue ActiveRecord::RecordInvalid => e
      render_error(Geolocator::Errors::InvalidQuery.new(e.record.errors.full_messages.join(", ")))
    rescue StandardError => e
      warn "[ERROR] #{e.class}: #{e.message}\n#{Array(e.backtrace).first(5).join("\n")}"
      render_error(
        Geolocator::Errors::Base.new(
          "An unexpected error occurred",
          code: "internal_error",
          status: :internal_server_error,
          title: "Internal Server Error"
        )
      )
    end

    private

    def render_error(api_error)
      error_response_body = {
        jsonapi: { version: GeolocationSerializer::JSONAPI_VERSION },
        errors: [api_error.to_h]
      }.to_json
      http_status = Rack::Utils.status_code(api_error.status)
      [http_status, { "Content-Type" => "application/vnd.api+json" }, [error_response_body]]
    end
  end
end
