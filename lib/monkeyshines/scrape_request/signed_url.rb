module Monkeyshines
  module ScrapeRequestCore
    module SignedUrl
      def authed_url(session_key)
        parsed_uri = Addressable::URI.parse(url)
        qq = parsed_uri.query_values.merge(
          'api_key' => api_key, 'nonce' => nonce, 'session_key' => session_key, 'format' => 'json').sort.map{|k,v| k+'='+v }
        p qq
        str = [
          parsed_uri.path,
          qq,
          api_secret].flatten.join("")
        p str
        sig = Digest::MD5.hexdigest(str)
        qq << "sig=#{sig}"
        au = [parsed_uri.scheme, '://', parsed_uri.host, parsed_uri.path, '?', qq.join("&")].join("")
        p au
        au
      end

      def nonce
        Time.now.utc.to_f.to_s
      end

      def token_request_url
        "http://api.friendster.com/v1/token?api_key=#{api_key}&nonce=#{nonce}&format=json"
      end

    end
  end
end


      # class TokenRequest < Base
      #   def authed_url
      #     qq = parsed_uri.query_values.merge(
      #       'api_key' => api_key,
      #       'nonce' => nonce,
      #       # 'auth_token' => auth_token,
      #       'format' => 'json').sort.map{|k,v| k+'='+v }
      #     p qq
      #     str = [
      #       parsed_uri.path,
      #       qq,
      #       api_secret].flatten.join("")
      #     p str
      #     sig = Digest::MD5.hexdigest(str)
      #     qq << "sig=#{sig}"
      #     au = [parsed_uri.scheme, '://', parsed_uri.host, parsed_uri.path, '?', qq.join("&")].join("")
      #     p au
      #     au
      #   end
      # end
      #
      # class SessionRequest < Base
      #   def authed_url(auth_token)
      #     qq = parsed_uri.query_values.merge(
      #       'api_key' => api_key,
      #       'nonce' => nonce,
      #       'auth_token' => auth_token,
      #       'format' => 'json').sort.map{|k,v| k+'='+v }
      #     p qq
      #     str = [
      #       parsed_uri.path,
      #       qq,
      #       api_secret].flatten.join("")
      #     p str
      #     sig = Digest::MD5.hexdigest(str)
      #     qq << "sig=#{sig}"
      #     au = [parsed_uri.scheme, '://', parsed_uri.host, parsed_uri.path, '?', qq.join("&")].join("")
      #     p au
      #     au
      #   end
      #   def make_url()
      #     "http://api.friendster.com/v1/session?"
      #   end
      # end
      #
      # # require 'monkeyshines' ; require 'wuclan' ; require 'wukong' ; require 'addressable/uri' ; require 'rest_client' ; scrape_config = YAML.load(File.open(ENV['HOME']+'/.monkeyshines'))
      # # load(ENV['HOME']+'/ics/wuclan/lib/wuclan/friendster/scrape/base.rb') ; Wuclan::Friendster::Scrape::Base.api_key = scrape_config[:friendster_api][:api_key] ; tokreq = Wuclan::Friendster::Scrape::TokenRequest.new(scrape_config[:friendster_api][:user_id]) ; tok= RestClient.post(tokreq.authed_url, {}).gsub(/\"/,"")
      # # sessreq = Wuclan::Friendster::Scrape::SessionRequest.new(scrape_config[:friendster_api][:user_id])
      # # sessreq.auth_token = '' ; sessreq.make_url! ; RestClient.post(sessreq.url+'&sig='+sessreq.url_sig[1], {})
      # # # => "{"session_key":"....","uid":"...","expires":"..."}"
