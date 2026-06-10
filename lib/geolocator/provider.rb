# frozen_string_literal: true

module Geolocator
  # Port for external geolocation providers. Add a new adapter under
  # `providers/` and register it in ProviderFactory to swap vendors.
  class Provider
    def lookup_ip(_ip)
      raise NotImplementedError, "#{self.class} must implement #lookup_ip"
    end

    def name
      self.class.provider_name
    end

    def self.provider_name
      name.split('::').last.downcase
    end
  end
end
