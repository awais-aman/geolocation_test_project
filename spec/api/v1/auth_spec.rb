# frozen_string_literal: true

RSpec.describe 'Auth API' do
  describe 'POST /api/v1/auth/login' do
    let(:credentials) do
      client_id = 'auth-spec'
      _client, client_secret = ApiClient.register!(name: client_id)
      { client_id: client_id, client_secret: client_secret }
    end

    it 'returns a JWT for valid client credentials' do
      post '/api/v1/auth/login',
           json_api_payload(credentials, type: 'auth_sessions')

      expect(last_response).to be_ok
      expect(json.dig('data', 'type')).to eq('auth_sessions')
      access_token = json.dig('data', 'attributes', 'access_token')
      expect(Auth::JwtToken.valid?(access_token)).to be true
      expect(json.dig('data', 'attributes', 'token_type')).to eq('Bearer')
      expect(json.dig('links', 'self')).to eq('/api/v1/auth/login')
    end

    it 'rejects requests without credentials' do
      post '/api/v1/auth/login', json_api_payload(type: 'auth_sessions')

      expect(last_response.status).to eq(400)
      expect(json.dig('errors', 0, 'code')).to eq('bad_request')
    end

    it 'rejects invalid credentials' do
      post '/api/v1/auth/login',
           json_api_payload({ client_id: 'unknown', client_secret: 'gloc_bad' }, type: 'auth_sessions')

      expect(last_response.status).to eq(401)
      expect(json.dig('errors', 0, 'code')).to eq('unauthorized')
    end

    it 'rejects invalid JSON bodies' do
      post '/api/v1/auth/login', 'not-json'

      expect(last_response.status).to eq(400)
      expect(json.dig('errors', 0, 'code')).to eq('bad_request')
    end

    it 'rejects an invalid data.type' do
      post '/api/v1/auth/login',
           json_api_payload(credentials, type: 'wrong')

      expect(last_response.status).to eq(400)
      expect(json.dig('errors', 0, 'code')).to eq('bad_request')
    end
  end
end
