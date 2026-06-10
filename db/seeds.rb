# frozen_string_literal: true

GEOLOCATION_RECORDS = [
  {
    query_type: "ip",
    query_value: "8.8.8.8",
    resolved_ip: "8.8.8.8",
    latitude: 37.386052,
    longitude: -122.083851,
    country_name: "United States",
    country_code: "US",
    region_name: "California",
    city: "Mountain View",
    provider: "seed",
    raw_response: { source: "seed" }
  },
  {
    query_type: "ip",
    query_value: "1.1.1.1",
    resolved_ip: "1.1.1.1",
    latitude: -33.8688,
    longitude: 151.2093,
    country_name: "Australia",
    country_code: "AU",
    region_name: "New South Wales",
    city: "Sydney",
    provider: "seed",
    raw_response: { source: "seed" }
  },
  {
    query_type: "url",
    query_value: "google.com",
    resolved_ip: "142.250.185.78",
    latitude: 37.422485,
    longitude: -122.085585,
    country_name: "United States",
    country_code: "US",
    region_name: "California",
    city: "Mountain View",
    provider: "seed",
    raw_response: { source: "seed" }
  }
].freeze

DEFAULT_CLIENT_NAME = "default"

puts "Seeding geolocation records (skips duplicates)..."

created = 0
GEOLOCATION_RECORDS.each do |attrs|
  record = Geolocation.find_or_initialize_by(
    query_type: attrs[:query_type],
    query_value: attrs[:query_value]
  )
  next unless record.new_record?

  record.assign_attributes(attrs)
  record.save!
  created += 1
end

puts "Seed complete: #{created} created, #{Geolocation.count} total."

if ApiClient.exists?(name: DEFAULT_CLIENT_NAME)
  client = ApiClient.find_by!(name: DEFAULT_CLIENT_NAME)
  puts "API client '#{client.name}' already exists (secret prefix: #{client.secret_prefix}…)."
  puts "The client_secret is not stored — if you lost it, run: make credentials"
else
  _client, client_secret = ApiClient.register!(name: DEFAULT_CLIENT_NAME)
  puts "API client created:"
  puts "  client_id:     #{DEFAULT_CLIENT_NAME}"
  puts "  client_secret: #{client_secret}"
end
