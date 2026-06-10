# frozen_string_literal: true

require 'sinatra/base'

module Api
  module Swagger
    OPENAPI_PATH = File.join(ROOT, 'openapi', 'openapi.yaml')

    SWAGGER_UI_HTML = <<~HTML
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="UTF-8" />
          <title>Geolocation API — Swagger UI</title>
          <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui.css" />
        </head>
        <body>
          <div id="swagger-ui"></div>
          <script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-bundle.js"></script>
          <script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-standalone-preset.js"></script>
          <script>
            window.onload = function () {
              SwaggerUIBundle({
                url: "/openapi.yaml",
                dom_id: "#swagger-ui",
                deepLinking: true,
                presets: [SwaggerUIBundle.presets.apis, SwaggerUIStandalonePreset],
                layout: "StandaloneLayout"
              });
            };
          </script>
        </body>
      </html>
    HTML

    def self.registered(app)
      app.get '/openapi.yaml' do
        content_type 'application/yaml'
        send_file OPENAPI_PATH
      end

      app.get %r{/api-docs/?} do
        content_type 'text/html'
        SWAGGER_UI_HTML
      end

      app.get '/' do
        redirect '/api-docs'
      end
    end
  end
end
