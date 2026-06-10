# frozen_string_literal: true

module Geolocator
  Result = Data.define(
    :resolved_ip,
    :latitude,
    :longitude,
    :country_name,
    :country_code,
    :region_name,
    :city,
    :raw_response
  ) do
    def self.from_hash(attrs)
      new(
        resolved_ip: attrs[:resolved_ip],
        latitude: attrs[:latitude],
        longitude: attrs[:longitude],
        country_name: attrs[:country_name],
        country_code: attrs[:country_code],
        region_name: attrs[:region_name],
        city: attrs[:city],
        raw_response: attrs.fetch(:raw_response, {})
      )
    end

    def to_record_attributes
      {
        resolved_ip: resolved_ip,
        latitude: latitude,
        longitude: longitude,
        country_name: country_name,
        country_code: country_code,
        region_name: region_name,
        city: city,
        raw_response: raw_response
      }
    end
  end
end
