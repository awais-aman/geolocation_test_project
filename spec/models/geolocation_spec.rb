# frozen_string_literal: true

RSpec.describe Geolocation do
  it "is valid with factory defaults" do
    expect(build(:geolocation)).to be_valid
  end

  it "validates query_type inclusion" do
    expect(build(:geolocation, query_type: "invalid")).not_to be_valid
  end

  it "enforces uniqueness per query type" do
    create(:geolocation, query_type: "ip", query_value: "8.8.8.8")

    expect(build(:geolocation, query_type: "ip", query_value: "8.8.8.8")).not_to be_valid
  end

  it "normalizes query_value before validation" do
    record = build(:geolocation, query_value: " 8.8.8.8 ")

    expect(record).to be_valid
    expect(record.query_value).to eq("8.8.8.8")
  end

  describe ".page_size" do
    it "defaults invalid values to DEFAULT_PAGE_SIZE" do
      expect(described_class.page_size(0)).to eq(described_class::DEFAULT_PAGE_SIZE)
      expect(described_class.page_size(-5)).to eq(described_class::DEFAULT_PAGE_SIZE)
    end

    it "caps values at MAX_PAGE_SIZE" do
      expect(described_class.page_size(500)).to eq(described_class::MAX_PAGE_SIZE)
    end
  end

  describe ".page_number" do
    it "defaults invalid values to 1" do
      expect(described_class.page_number(0)).to eq(1)
      expect(described_class.page_number(-2)).to eq(1)
    end

    it "accepts positive page numbers" do
      expect(described_class.page_number(3)).to eq(3)
    end
  end

  it "normalizes query_type before validation" do
    record = build(:geolocation, query_type: " IP ")

    expect(record).to be_valid
    expect(record.query_type).to eq("ip")
  end

  it "skips normalization when fields are blank" do
    record = build(:geolocation, query_value: nil, query_type: nil)

    expect(record).not_to be_valid
    expect(record.query_value).to be_nil
    expect(record.query_type).to be_nil
  end

  describe ".matching_query" do
    it "finds records by query_value or resolved_ip" do
      matching = create(:geolocation, query_value: "8.8.8.8")
      create(:geolocation, query_value: "1.1.1.1")

      expect(described_class.matching_query("8.8.8.8")).to eq([matching])
    end
  end

  it "serializes timestamps when present and omits them when absent" do
    record = build(:geolocation)
    payload = GeolocationSerializer.render(record)

    expect(payload.dig(:data, :attributes, :created_at)).to be_nil
    expect(payload.dig(:data, :attributes, :updated_at)).to be_nil
  end

  it "omits self links for serializer collections without a path" do
    record = create(:geolocation)
    payload = GeolocationSerializer.render(described_class.where(id: record.id))

    expect(payload).not_to have_key(:links)
    expect(payload.dig(:meta, :total)).to eq(1)
  end
end
