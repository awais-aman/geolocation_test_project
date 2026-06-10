# frozen_string_literal: true

module Geolocator
  class ProviderFactory
    def self.build(provider_name = ENV.fetch("GEOLOCATION_PROVIDER", "ipstack"), **dependencies)
      key = provider_name.to_s.downcase
      provider_class = registry[key]
      raise Errors::ProviderMisconfigured, "Unknown geolocation provider: #{provider_name}" unless provider_class

      provider_class.new(**dependencies)
    end

    def self.registry
      @registry ||= {
        "ipstack" => Providers::Ipstack
      }
    end
  end
end
