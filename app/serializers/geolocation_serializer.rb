# frozen_string_literal: true

class GeolocationSerializer
  TYPE = "geolocations"
  JSONAPI_VERSION = "1.1"

  def self.render(resource, self_link: nil)
    if resource.is_a?(Geolocation)
      json_api_response(data: document(resource), self_link:, total: nil)
    else
      total = resource.unscope(:limit, :offset).count
      json_api_response(
        data: resource.map { |geolocation| document(geolocation) },
        self_link:,
        total:
      )
    end
  end

  def self.json_api_response(data:, self_link:, total:)
    response = { jsonapi: { version: JSONAPI_VERSION }, data: data }
    response[:meta] = { total: total } unless total.nil?
    response[:links] = { self: self_link } if self_link
    response
  end

  def self.document(geolocation)
    {
      type: TYPE,
      id: geolocation.id.to_s,
      attributes: attributes_for(geolocation)
    }
  end

  def self.attributes_for(geolocation)
    {
      query_type: geolocation.query_type,
      query_value: geolocation.query_value,
      resolved_ip: geolocation.resolved_ip,
      latitude: decimal_to_float(geolocation.latitude),
      longitude: decimal_to_float(geolocation.longitude),
      country_name: geolocation.country_name,
      country_code: geolocation.country_code,
      region_name: geolocation.region_name,
      city: geolocation.city,
      provider: geolocation.provider,
      created_at: geolocation.created_at&.iso8601,
      updated_at: geolocation.updated_at&.iso8601
    }
  end

  def self.decimal_to_float(decimal_value)
    decimal_value.nil? ? nil : decimal_value.to_f
  end

  private_class_method :json_api_response, :document, :attributes_for, :decimal_to_float
end
