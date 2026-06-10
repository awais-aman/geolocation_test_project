# frozen_string_literal: true

FactoryBot.define do
  factory :geolocation do
    query_type { 'ip' }
    sequence(:query_value) { |n| "203.0.113.#{n}" }
    resolved_ip { query_value }
    latitude { 40.7128 }
    longitude { -74.0060 }
    country_name { 'United States' }
    country_code { 'US' }
    region_name { 'New York' }
    city { 'New York' }
    provider { 'ipstack' }
    raw_response { { ip: query_value } }
  end
end
