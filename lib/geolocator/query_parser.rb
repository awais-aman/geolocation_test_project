# frozen_string_literal: true

require "ipaddr"
require "resolv"
require "uri"

module Geolocator
  class QueryParser
    ParsedQuery = Data.define(:query_type, :query_value, :resolved_ip)

    def self.parse(lookup_query)
      new(lookup_query).parse
    end

    def initialize(lookup_query)
      @lookup_query = lookup_query.to_s.strip
    end

    def parse
      raise Errors::InvalidQuery, "Query cannot be blank" if @lookup_query.empty?

      if ip_address?(@lookup_query)
        ip_address = normalize_ip(@lookup_query)
        ParsedQuery.new(query_type: "ip", query_value: ip_address, resolved_ip: ip_address)
      elsif url?(@lookup_query)
        hostname = extract_host_from_url(@lookup_query)
        ParsedQuery.new(query_type: "url", query_value: hostname, resolved_ip: resolve_host(hostname))
      elsif hostname?(@lookup_query)
        hostname = normalize_host(@lookup_query)
        ParsedQuery.new(query_type: "url", query_value: hostname, resolved_ip: resolve_host(hostname))
      else
        raise Errors::InvalidQuery, "Query must be a valid IP address, URL, or hostname"
      end
    rescue IPAddr::InvalidAddressError
      raise Errors::InvalidQuery, "Invalid IP address format"
    rescue URI::InvalidURIError
      raise Errors::InvalidQuery, "URL format is invalid"
    end

    private

    def ip_address?(value)
      value.match?(/\A(?:\d{1,3}\.){3}\d{1,3}\z/) || value.match?(/\A[\da-f:]+\z/i)
    end

    def url?(value)
      value.match?(%r{\Ahttps?://}i)
    end

    def hostname?(value)
      value.include?(".") && !value.include?(" ")
    end

    def normalize_ip(value)
      IPAddr.new(value).to_s
    end

    def normalize_host(value)
      value.downcase.split("/").first
    end

    def extract_host_from_url(value)
      host = URI.parse(value).host
      raise Errors::InvalidQuery, "URL must include a hostname" if host.to_s.empty?

      host.downcase
    end

    def resolve_host(hostname)
      Resolv.getaddress(hostname)
    rescue Resolv::ResolvError
      raise Errors::DnsResolutionFailed, hostname
    end
  end
end
