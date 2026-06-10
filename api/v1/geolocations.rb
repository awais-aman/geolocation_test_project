# frozen_string_literal: true

require 'sinatra/base'

module Api
  module V1
    module Geolocations
      def self.registered(app)
        app.helpers Helpers::JsonApi

        app.namespace '/api/v1/geolocations' do
          get '' do
            geolocations = Geolocation.recent
            filter_query_type = params.dig('filter', 'query_type').to_s.strip
            filter_query = params.dig('filter', 'query').to_s.strip
            page_size = Geolocation.page_size(params['page_size'])
            page_number = Geolocation.page_number(params['page_number'])
            offset = (page_number - 1) * page_size

            geolocations = geolocations.by_query_type(filter_query_type) if filter_query_type.present?
            geolocations = geolocations.matching_query(filter_query) if filter_query.present?

            render_json_api(geolocations.limit(page_size).offset(offset))
          end

          get '/:id' do
            geolocation = Geolocation.find(params['id'])
            render_json_api(geolocation)
          end

          post '' do
            lookup_query = parse_lookup_query_from_request
            raise Geolocator::Errors::BadRequest, 'query attribute is required' if lookup_query.nil?

            geolocation = Dependencies.create_geolocation_service.call(lookup_query)
            render_json_api(geolocation, status: 201)
          end

          delete '/:id' do
            geolocation = Geolocation.find(params['id'])
            geolocation.destroy!
            status 204
            body ''
          end
        end
      end
    end
  end
end
