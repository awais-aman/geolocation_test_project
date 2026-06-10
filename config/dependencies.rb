# frozen_string_literal: true

module Dependencies
  module_function

  def geolocation_provider
    @geolocation_provider ||= Geolocator::ProviderFactory.build
  end

  def create_geolocation_service
    @create_geolocation_service ||= Geolocator::Services::CreateGeolocation.new(provider: geolocation_provider)
  end

  def reset!
    @geolocation_provider = nil
    @create_geolocation_service = nil
  end
end
