# frozen_string_literal: true

require "digest"
require "securerandom"
require "active_support/security_utils"

class ApiClient < ApplicationRecord
  SECRET_PREFIX = "gloc_"

  validates :name, presence: true, uniqueness: true
  validates :secret_digest, presence: true, uniqueness: true
  validates :secret_prefix, presence: true

  # Returns [record, client_secret]. The secret is only available at creation.
  def self.register!(name:)
    client_secret = "#{SECRET_PREFIX}#{SecureRandom.hex(32)}"
    client = create!(
      name: name,
      secret_digest: digest(client_secret),
      secret_prefix: client_secret[0, SECRET_PREFIX.length + 8]
    )
    [client, client_secret]
  end

  def self.authenticate(client_id:, client_secret:)
    client = find_by(name: client_id.to_s.strip)
    return false unless client

    secure_compare(client.secret_digest, digest(client_secret.to_s.strip))
  end

  def self.digest(client_secret)
    Digest::SHA256.hexdigest(client_secret)
  end

  def self.secure_compare(left, right)
    return false unless left.bytesize == right.bytesize

    ActiveSupport::SecurityUtils.secure_compare(left, right)
  end

  private_class_method :digest, :secure_compare
end
