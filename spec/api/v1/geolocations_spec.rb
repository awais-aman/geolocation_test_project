# frozen_string_literal: true

RSpec.describe "Geolocations API" do
  describe "authentication" do
    it "rejects unauthenticated requests" do
      get "/api/v1/geolocations"

      expect(last_response.status).to eq(401)
      expect(json.dig("errors", 0, "code")).to eq("unauthorized")
    end

    it "rejects invalid bearer tokens" do
      get "/api/v1/geolocations", {}, { "HTTP_AUTHORIZATION" => "Bearer not-a-valid-jwt" }

      expect(last_response.status).to eq(401)
      expect(json.dig("errors", 0, "code")).to eq("unauthorized")
    end
  end

  describe "GET /api/v1/geolocations" do
    it "returns JSON:API collection payloads" do
      FactoryBot.create_list(:geolocation, 2)

      get "/api/v1/geolocations", {}, auth_headers

      expect(last_response).to be_ok
      expect(json.dig("jsonapi", "version")).to eq("1.1")
      expect(json.dig("links", "self")).to eq("/api/v1/geolocations")
      expect(json.dig("meta", "total")).to eq(2)
      expect(json.fetch("data").size).to eq(2)
      expect(json.dig("data", 0, "type")).to eq("geolocations")
    end

    it "filters records by query_type" do
      ip_record = FactoryBot.create(:geolocation, query_type: "ip", query_value: "8.8.8.8")
      FactoryBot.create(:geolocation, query_type: "url", query_value: "example.com")

      get "/api/v1/geolocations", { "filter" => { "query_type" => "ip" } }, auth_headers

      expect(last_response).to be_ok
      expect(json.fetch("data").size).to eq(1)
      expect(json.dig("data", 0, "id")).to eq(ip_record.id.to_s)
    end

    it "filters records by IP or URL query" do
      record = FactoryBot.create(:geolocation, query_value: "8.8.8.8")
      FactoryBot.create(:geolocation, query_value: "1.1.1.1")

      get "/api/v1/geolocations", { "filter" => { "query" => "8.8.8.8" } }, auth_headers

      expect(last_response).to be_ok
      expect(json.fetch("data").size).to eq(1)
      expect(json.dig("data", 0, "id")).to eq(record.id.to_s)
    end

    it "filters records by resolved_ip" do
      record = FactoryBot.create(:geolocation, query_value: "example.com", resolved_ip: "93.184.216.34")
      FactoryBot.create(:geolocation, resolved_ip: "1.1.1.1")

      get "/api/v1/geolocations", { "filter" => { "query" => "93.184.216.34" } }, auth_headers

      expect(last_response).to be_ok
      expect(json.fetch("data").size).to eq(1)
      expect(json.dig("data", 0, "id")).to eq(record.id.to_s)
    end

    it "paginates collections with page_size and page_number query params" do
      oldest = FactoryBot.create(:geolocation, query_value: "1.1.1.1", created_at: 5.minutes.ago)
      middle = FactoryBot.create(:geolocation, query_value: "2.2.2.2", created_at: 3.minutes.ago)
      newest = FactoryBot.create(:geolocation, query_value: "3.3.3.3", created_at: 1.minute.ago)

      get "/api/v1/geolocations?page_size=2&page_number=1", {}, auth_headers

      expect(last_response).to be_ok
      expect(json.fetch("data").map { |row| row["id"] }).to eq([newest.id.to_s, middle.id.to_s])
      expect(json.dig("meta", "total")).to eq(3)

      get "/api/v1/geolocations?page_size=2&page_number=2", {}, auth_headers

      expect(last_response).to be_ok
      expect(json.fetch("data").map { |row| row["id"] }).to eq([oldest.id.to_s])
      expect(json.dig("meta", "total")).to eq(3)
    end

    it "defaults page_number to 1 when the query param is invalid" do
      records = FactoryBot.create_list(:geolocation, 2)

      get "/api/v1/geolocations?page_size=1&page_number=0", {}, auth_headers
      first_page_ids = json.fetch("data").map { |row| row["id"] }

      get "/api/v1/geolocations?page_size=1&page_number=1", {}, auth_headers
      expect(json.fetch("data").map { |row| row["id"] }).to eq(first_page_ids)
      expect(json.dig("meta", "total")).to eq(records.size)
    end

    it "uses the default page size when page_size is omitted" do
      FactoryBot.create_list(:geolocation, Geolocation::DEFAULT_PAGE_SIZE + 1)

      get "/api/v1/geolocations", {}, auth_headers

      expect(last_response).to be_ok
      expect(json.fetch("data").size).to eq(Geolocation::DEFAULT_PAGE_SIZE)
      expect(json.dig("meta", "total")).to eq(Geolocation::DEFAULT_PAGE_SIZE + 1)
    end

  end

  describe "GET /api/v1/geolocations/:id" do
    it "returns a single resource" do
      record = FactoryBot.create(:geolocation)

      get "/api/v1/geolocations/#{record.id}", {}, auth_headers

      expect(last_response).to be_ok
      expect(json.dig("jsonapi", "version")).to eq("1.1")
      expect(json.dig("links", "self")).to eq("/api/v1/geolocations/#{record.id}")
      expect(json.dig("data", "id")).to eq(record.id.to_s)
      expect(json).not_to have_key("meta")
    end

    it "serializes nullable coordinates" do
      record = FactoryBot.create(:geolocation, latitude: nil, longitude: nil)

      get "/api/v1/geolocations/#{record.id}", {}, auth_headers

      expect(last_response).to be_ok
      expect(json.dig("data", "attributes", "latitude")).to be_nil
      expect(json.dig("data", "attributes", "longitude")).to be_nil
    end

    it "returns 404 for unknown ids" do
      get "/api/v1/geolocations/0", {}, auth_headers

      expect(last_response.status).to eq(404)
    end
  end

  describe "POST /api/v1/geolocations" do
    let(:provider_body) do
      {
        ip: "8.8.4.4",
        latitude: 37.386052,
        longitude: -122.083851,
        country_name: "United States",
        country_code: "US",
        region_name: "California",
        city: "Mountain View"
      }.to_json
    end

    it "creates a geolocation from an IP query" do
      stub_request(:get, "https://api.ipstack.com/8.8.4.4")
        .with(query: hash_including(access_key: "test-ipstack-key"))
        .to_return(status: 200, body: provider_body)

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(201)
      expect(json.dig("jsonapi", "version")).to eq("1.1")
      expect(json.dig("data", "attributes", "query_value")).to eq("8.8.4.4")
      expect(json.dig("data", "attributes", "provider")).to eq("ipstack")
    end

    it "creates a geolocation from a URL query" do
      allow(Resolv).to receive(:getaddress).with("example.com").and_return("93.184.216.34")
      stub_request(:get, "https://api.ipstack.com/93.184.216.34")
        .with(query: hash_including(access_key: "test-ipstack-key"))
        .to_return(
          status: 200,
          body: {
            ip: "93.184.216.34",
            latitude: 37.386052,
            longitude: -122.083851,
            country_name: "United States",
            country_code: "US",
            region_name: "California",
            city: "Los Angeles"
          }.to_json
        )

      post "/api/v1/geolocations", json_api_payload(query: "https://example.com"), auth_headers

      expect(last_response.status).to eq(201)
      expect(json.dig("data", "attributes", "query_type")).to eq("url")
      expect(json.dig("data", "attributes", "query_value")).to eq("example.com")
    end

    it "creates a geolocation from a bare hostname" do
      allow(Resolv).to receive(:getaddress).with("example.org").and_return("93.184.216.35")
      stub_request(:get, "https://api.ipstack.com/93.184.216.35")
        .with(query: hash_including(access_key: "test-ipstack-key"))
        .to_return(status: 200, body: provider_body.gsub("8.8.4.4", "93.184.216.35"))

      post "/api/v1/geolocations", json_api_payload(query: "example.org/path"), auth_headers

      expect(last_response.status).to eq(201)
      expect(json.dig("data", "attributes", "query_type")).to eq("url")
      expect(json.dig("data", "attributes", "query_value")).to eq("example.org")
    end

    it "validates required attributes" do
      post "/api/v1/geolocations", json_api_payload, auth_headers

      expect(last_response.status).to eq(400)
    end

    it "rejects invalid JSON bodies" do
      post "/api/v1/geolocations", "not-json", auth_headers

      expect(last_response.status).to eq(400)
      expect(json.dig("errors", 0, "code")).to eq("bad_request")
    end

    it "requires a data object" do
      post "/api/v1/geolocations", { foo: "bar" }.to_json, auth_headers

      expect(last_response.status).to eq(400)
      expect(json.dig("errors", 0, "detail")).to include("data object is required")
    end

    it "rejects an invalid data.type" do
      post "/api/v1/geolocations", json_api_payload({ query: "8.8.4.4" }, type: "locations"), auth_headers

      expect(last_response.status).to eq(400)
      expect(json.dig("errors", 0, "code")).to eq("bad_request")
      expect(json.dig("errors", 0, "detail")).to include("data.type must be geolocations")
    end

    it "rejects blank lookup queries" do
      post "/api/v1/geolocations", json_api_payload(query: "   "), auth_headers

      expect(last_response.status).to eq(422)
      expect(json.dig("errors", 0, "code")).to eq("invalid_query")
    end

    it "rejects unsupported lookup queries" do
      post "/api/v1/geolocations", json_api_payload(query: "not a valid query"), auth_headers

      expect(last_response.status).to eq(422)
      expect(json.dig("errors", 0, "code")).to eq("invalid_query")
    end

    it "rejects malformed URLs" do
      post "/api/v1/geolocations", json_api_payload(query: "http://[::1"), auth_headers

      expect(last_response.status).to eq(422)
      expect(json.dig("errors", 0, "code")).to eq("invalid_query")
    end

    it "rejects malformed IP addresses" do
      post "/api/v1/geolocations", json_api_payload(query: "999.999.999.999"), auth_headers

      expect(last_response.status).to eq(422)
      expect(json.dig("errors", 0, "code")).to eq("invalid_query")
    end

    it "rejects URLs without a hostname" do
      post "/api/v1/geolocations", json_api_payload(query: "https://"), auth_headers

      expect(last_response.status).to eq(422)
      expect(json.dig("errors", 0, "code")).to eq("invalid_query")
    end

    it "surfaces DNS resolution failures" do
      allow(Resolv).to receive(:getaddress).with("missing.example").and_raise(Resolv::ResolvError)

      post "/api/v1/geolocations", json_api_payload(query: "missing.example"), auth_headers

      expect(last_response.status).to eq(422)
      expect(json.dig("errors", 0, "code")).to eq("dns_resolution_failed")
    end

    it "surfaces provider rate limits" do
      stub_request(:get, "https://api.ipstack.com/8.8.4.4")
        .with(query: hash_including(access_key: "test-ipstack-key"))
        .to_return(
          status: 200,
          body: { success: false, error: { code: 104, info: "monthly limit reached" } }.to_json
        )

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(429)
      expect(json.dig("errors", 0, "code")).to eq("provider_error")
    end

    it "surfaces provider authentication failures" do
      stub_request(:get, "https://api.ipstack.com/8.8.4.4")
        .with(query: hash_including(access_key: "test-ipstack-key"))
        .to_return(
          status: 200,
          body: { success: false, error: { code: 101, info: "invalid access key" } }.to_json
        )

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(503)
      expect(json.dig("errors", 0, "code")).to eq("provider_error")
    end

    it "surfaces provider not-found responses" do
      stub_request(:get, "https://api.ipstack.com/8.8.4.4")
        .with(query: hash_including(access_key: "test-ipstack-key"))
        .to_return(
          status: 200,
          body: { success: false, error: { code: 301, info: "invalid ip address" } }.to_json
        )

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(404)
      expect(json.dig("errors", 0, "code")).to eq("provider_error")
    end

    it "surfaces unknown provider error codes" do
      stub_request(:get, "https://api.ipstack.com/8.8.4.4")
        .with(query: hash_including(access_key: "test-ipstack-key"))
        .to_return(
          status: 200,
          body: { success: false, error: { code: 999, info: "unexpected provider failure" } }.to_json
        )

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(502)
      expect(json.dig("errors", 0, "code")).to eq("provider_error")
    end

    it "surfaces provider connection failures" do
      stub_request(:get, "https://api.ipstack.com/8.8.4.4")
        .with(query: hash_including(access_key: "test-ipstack-key"))
        .to_raise(Faraday::ConnectionFailed.new("connection refused"))

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(503)
      expect(json.dig("errors", 0, "code")).to eq("provider_error")
    end

    it "surfaces generic provider request failures" do
      stub_request(:get, "https://api.ipstack.com/8.8.4.4")
        .with(query: hash_including(access_key: "test-ipstack-key"))
        .to_raise(Faraday::ClientError.new("bad response"))

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(502)
      expect(json.dig("errors", 0, "code")).to eq("provider_error")
    end

    it "surfaces invalid provider JSON payloads" do
      stub_request(:get, "https://api.ipstack.com/8.8.4.4")
        .with(query: hash_including(access_key: "test-ipstack-key"))
        .to_return(status: 200, body: "not-json")

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(502)
      expect(json.dig("errors", 0, "code")).to eq("provider_error")
    end

    it "surfaces non-object provider JSON payloads" do
      stub_request(:get, "https://api.ipstack.com/8.8.4.4")
        .with(query: hash_including(access_key: "test-ipstack-key"))
        .to_return(status: 200, body: [].to_json)

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(502)
      expect(json.dig("errors", 0, "code")).to eq("provider_error")
    end

    it "surfaces misconfigured providers" do
      original_key = ENV.delete("IPSTACK_ACCESS_KEY")
      Dependencies.reset!

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(503)
      expect(json.dig("errors", 0, "code")).to eq("provider_misconfigured")
    ensure
      ENV["IPSTACK_ACCESS_KEY"] = original_key || "test-ipstack-key"
      Dependencies.reset!
    end

    it "surfaces unknown provider configuration" do
      original_provider = ENV["GEOLOCATION_PROVIDER"]
      ENV["GEOLOCATION_PROVIDER"] = "unknown"
      Dependencies.reset!

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(503)
      expect(json.dig("errors", 0, "code")).to eq("provider_misconfigured")
    ensure
      if original_provider
        ENV["GEOLOCATION_PROVIDER"] = original_provider
      else
        ENV.delete("GEOLOCATION_PROVIDER")
      end
      Dependencies.reset!
    end

    it "returns conflict for duplicate queries" do
      FactoryBot.create(:geolocation, query_type: "ip", query_value: "8.8.4.4", resolved_ip: "8.8.4.4")

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(409)
    end

    it "returns conflict when the database unique index is hit" do
      service = instance_double(Geolocator::Services::CreateGeolocation)
      allow(Dependencies).to receive(:create_geolocation_service).and_return(service)
      allow(service).to receive(:call).and_raise(ActiveRecord::RecordNotUnique.new("duplicate"))

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(409)
      expect(json.dig("errors", 0, "code")).to eq("conflict")
    end

    it "returns validation errors from the persistence layer" do
      invalid_record = Geolocation.new
      invalid_record.errors.add(:base, "invalid record")
      service = instance_double(Geolocator::Services::CreateGeolocation)
      allow(Dependencies).to receive(:create_geolocation_service).and_return(service)
      allow(service).to receive(:call).and_raise(ActiveRecord::RecordInvalid.new(invalid_record))

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(422)
      expect(json.dig("errors", 0, "code")).to eq("invalid_query")
    end

    it "returns internal errors for unexpected failures" do
      allow(Dependencies).to receive(:create_geolocation_service).and_raise(StandardError, "boom")

      post "/api/v1/geolocations", json_api_payload(query: "8.8.4.4"), auth_headers

      expect(last_response.status).to eq(500)
      expect(json.dig("errors", 0, "code")).to eq("internal_error")
    end
  end

  describe "DELETE /api/v1/geolocations/:id" do
    it "removes the record" do
      record = FactoryBot.create(:geolocation)

      delete "/api/v1/geolocations/#{record.id}", {}, auth_headers

      expect(last_response.status).to eq(204)
      expect(Geolocation.find_by(id: record.id)).to be_nil
    end

    it "returns 404 for unknown ids" do
      delete "/api/v1/geolocations/0", {}, auth_headers

      expect(last_response.status).to eq(404)
    end
  end
end
