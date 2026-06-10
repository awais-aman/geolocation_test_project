# frozen_string_literal: true

require "sinatra/base"
require "sinatra/namespace"
require "rack/cors"

module Api
  class Application < Sinatra::Base
    register Sinatra::Namespace

    configure do
      set :show_exceptions, false
      set :raise_errors, true
      set :dump_errors, false
    end

    use Rack::Cors do
      allow do
        origins ENV.fetch("CORS_ORIGINS", "*").split(",").map(&:strip)
        resource "*", headers: :any, methods: %i[get post delete options head]
      end
    end

    use Middleware::ErrorHandler
    use Middleware::Authentication

    before "/api/*" do
      content_type "application/vnd.api+json"
    end

    register Api::Swagger
    register Api::V1::Auth
    register Api::V1::Geolocations
  end
end
