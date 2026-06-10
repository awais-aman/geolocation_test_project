# frozen_string_literal: true

module Geolocator
  module Errors
    class Base < StandardError
      attr_reader :code, :detail, :status, :title

      def initialize(message = nil, code:, status:, title: nil, detail: nil)
        super(message || detail)
        @code = code
        @status = status
        @title = title || code.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')
        @detail = detail || message || @title
      end

      def to_h
        {
          status: Rack::Utils.status_code(status).to_s,
          title: title,
          detail: detail,
          code: code
        }
      end
    end

    class InvalidQuery < Base
      def initialize(detail)
        super(detail, code: 'invalid_query', status: :unprocessable_content)
      end
    end

    class NotFound < Base
      def initialize(detail = 'The requested resource was not found')
        super(detail, code: 'not_found', status: :not_found, title: 'Not Found')
      end
    end

    class Conflict < Base
      DUPLICATE_GEOLOCATION = 'Geolocation for this query already exists'

      def initialize(detail = DUPLICATE_GEOLOCATION)
        super(detail, code: 'conflict', status: :conflict, title: 'Conflict')
      end
    end

    class ProviderError < Base
      def initialize(detail, status: :bad_gateway)
        super(detail, code: 'provider_error', status: status, title: 'Provider Error')
      end
    end

    class ProviderUnavailable < ProviderError
      def initialize(detail = 'Geolocation provider is unavailable')
        super(detail, status: :service_unavailable)
      end
    end

    class ProviderMisconfigured < Base
      def initialize(detail = 'Geolocation provider is not configured')
        super(detail, code: 'provider_misconfigured', status: :service_unavailable, title: 'Service Unavailable')
      end
    end

    class DnsResolutionFailed < Base
      def initialize(hostname)
        super(
          "Could not resolve hostname: #{hostname}",
          code: 'dns_resolution_failed',
          status: :unprocessable_content
        )
      end
    end

    class Unauthorized < Base
      def initialize(detail = 'Invalid or missing API token')
        super(detail, code: 'unauthorized', status: :unauthorized, title: 'Unauthorized')
      end
    end

    class BadRequest < Base
      def initialize(detail)
        super(detail, code: 'bad_request', status: :bad_request, title: 'Bad Request')
      end
    end
  end
end
