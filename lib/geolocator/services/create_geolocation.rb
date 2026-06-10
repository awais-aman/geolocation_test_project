# frozen_string_literal: true

module Geolocator
  module Services
    class CreateGeolocation
      def initialize(provider:)
        @provider = provider
      end

      def call(lookup_query)
        parsed_lookup_query = QueryParser.parse(lookup_query)
        raise Errors::Conflict if duplicate?(parsed_lookup_query)

        provider_result = @provider.lookup_ip(parsed_lookup_query.resolved_ip)
        Geolocation.create!(
          {
            query_type: parsed_lookup_query.query_type,
            query_value: parsed_lookup_query.query_value,
            provider: @provider.name
          }.merge(provider_result.to_record_attributes)
        )
      end

      private

      def duplicate?(parsed_lookup_query)
        Geolocation.exists?(
          query_type: parsed_lookup_query.query_type,
          query_value: parsed_lookup_query.query_value
        )
      end
    end
  end
end
