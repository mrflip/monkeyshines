require 'net/http'
Net::HTTP.version_1_2
module Monkeyshines
  module Fetcher

    #
    class AuthedHttpFetcher
      cattr_accessor :auth_params

      def get_request_token
      end

      def authorize
      end

      def get_access_token
      end

      def api_key
      end
      def api_secret
      end
      def session_key
      end
      
      # authenticate request
      def authenticate req
        get_session_key unless session_key
      end

      
    end

  end
end
