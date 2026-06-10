# frozen_string_literal: true

RSpec.describe ApiClient do
  describe '.register!' do
    it 'stores a digest, not the plaintext secret' do
      client, client_secret = described_class.register!(name: 'acme')

      expect(client.secret_digest).not_to eq(client_secret)
      expect(client.secret_prefix).to start_with('gloc_')
      expect(described_class.authenticate(client_id: 'acme', client_secret: client_secret)).to be true
    end
  end

  describe '.authenticate' do
    it 'rejects unknown clients and wrong secrets' do
      _client, client_secret = described_class.register!(name: 'auth-check')

      expect(described_class.authenticate(client_id: 'auth-check', client_secret: client_secret)).to be true
      expect(described_class.authenticate(client_id: 'auth-check', client_secret: 'gloc_wrong')).to be false
      expect(described_class.authenticate(client_id: 'missing', client_secret: client_secret)).to be false
    end

    it 'rejects blank client_id values' do
      expect(described_class.authenticate(client_id: ' ', client_secret: 'gloc_secret')).to be false
    end

    it 'rejects secrets that do not match the stored digest length' do
      described_class.create!(
        name: 'digest-mismatch',
        secret_digest: 'short',
        secret_prefix: 'gloc_12345678'
      )

      expect(described_class.authenticate(client_id: 'digest-mismatch', client_secret: "gloc_#{'a' * 64}"))
        .to be false
    end
  end
end
