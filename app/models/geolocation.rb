# frozen_string_literal: true

class Geolocation < ApplicationRecord
  QUERY_TYPES = %w[ip url].freeze
  DEFAULT_PAGE_SIZE = 50
  MAX_PAGE_SIZE = 100

  validates :query_type, presence: true, inclusion: { in: QUERY_TYPES }
  validates :query_value, presence: true
  validates :provider, presence: true
  validates :query_value, uniqueness: { scope: :query_type, case_sensitive: false }

  before_validation :normalize_fields

  scope :recent, -> { order(created_at: :desc) }
  scope :by_query_type, ->(type) { where(query_type: type) }
  scope :matching_query, lambda { |lookup_query|
    normalized_query = lookup_query.to_s.downcase.strip
    where(query_value: normalized_query).or(where(resolved_ip: normalized_query))
  }

  def self.page_size(requested_size)
    size = requested_size.to_i
    size = DEFAULT_PAGE_SIZE if size <= 0
    [size, MAX_PAGE_SIZE].min
  end

  def self.page_number(requested_number)
    number = requested_number.to_i
    [number, 1].max
  end

  private

  def normalize_fields
    self.query_value = query_value.to_s.downcase.strip if query_value.present?
    self.query_type = query_type.to_s.downcase.strip if query_type.present?
  end
end
