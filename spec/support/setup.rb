# frozen_string_literal: true

require 'rack/test'
require 'factory_bot'

FactoryBot.find_definitions

# Share one DB connection so Rack requests roll back with the example transaction.
module ActiveRecord
  class Base
    mattr_accessor :shared_connection
  end
end

module RequestHelpers
  def app
    Api::Application
  end

  def json
    JSON.parse(last_response.body)
  end

  def auth_headers(client_id: test_client_id, client_secret: test_client_secret)
    post '/api/v1/auth/login',
         json_api_payload({ client_id: client_id, client_secret: client_secret }, type: 'auth_sessions')

    token = json.dig('data', 'attributes', 'access_token')
    {
      'HTTP_AUTHORIZATION' => "Bearer #{token}",
      'CONTENT_TYPE' => 'application/vnd.api+json'
    }
  end

  def test_client_id
    test_credentials[:client_id]
  end

  def test_client_secret
    test_credentials[:client_secret]
  end

  def test_credentials
    @test_credentials ||= begin
      client_id = 'rspec'
      _client, client_secret = ApiClient.register!(name: client_id)
      { client_id: client_id, client_secret: client_secret }
    end
  end

  def json_api_payload(attributes = {}, type: 'geolocations', **keyword_attributes)
    attrs = attributes.empty? ? keyword_attributes : attributes

    {
      data: {
        type: type,
        attributes: attrs
      }
    }.to_json
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    Database.connect!
    ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

    next unless Database.env == 'test'

    connection = ActiveRecord::Base.connection
    connection.tables.each do |table|
      next if %w[schema_migrations ar_internal_metadata].include?(table)

      connection.execute("TRUNCATE TABLE #{connection.quote_table_name(table)} RESTART IDENTITY CASCADE")
    end
  end

  config.after(:suite) do
    ActiveRecord::Base.shared_connection = nil
  end

  config.around do |example|
    connection = ActiveRecord::Base.connection
    connection.begin_transaction(joinable: false)
    example.run
  ensure
    connection.rollback_transaction if connection.open_transactions.positive?
  end

  config.before do
    Dependencies.reset!
    Auth::JwtToken.reset!
  end

  config.include FactoryBot::Syntax::Methods
  config.include Rack::Test::Methods
  config.include RequestHelpers
end

class << ActiveRecord::Base
  def connection
    shared_connection || super
  end
end
