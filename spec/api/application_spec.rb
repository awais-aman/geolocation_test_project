# frozen_string_literal: true

RSpec.describe "API documentation" do
  it "redirects the root URL to Swagger UI" do
    get "/"

    expect(last_response).to be_redirect
    expect(last_response.location).to end_with("/api-docs")
  end

  it "serves Swagger UI without authentication" do
    get "/api-docs"

    expect(last_response).to be_ok
    expect(last_response.body).to include("swagger-ui-bundle.js")
    expect(last_response.body).to include("swagger-ui-standalone-preset.js")
    expect(last_response.body).to include("/openapi.yaml")

    get "/api-docs/"

    expect(last_response).to be_ok
    expect(last_response.body).to include("swagger-ui")
  end

  it "serves the OpenAPI specification without authentication" do
    get "/openapi.yaml"

    expect(last_response).to be_ok
    expect(last_response.content_type).to include("application/yaml")
    expect(last_response.body).to include("openapi: 3.0.3")
    expect(last_response.body).to include("/api/v1/auth/login")
    expect(last_response.body).to include("page_size")
  end
end
