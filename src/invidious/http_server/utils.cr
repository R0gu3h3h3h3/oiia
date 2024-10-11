require "uri"

module Invidious::HttpServer
  module Utils
    extend self

    @@proxy_alive : String = ""

    def check_external_proxy
      CONFIG.external_videoplayback_proxy.each do |proxy|
        begin
          response = HTTP::Client.get(proxy)
          if response.status_code == 200
            @@proxy_alive = proxy
            LOGGER.debug("CheckExternalProxy: Proxy set to: '#{proxy}'")
            break
          end
        rescue
          LOGGER.debug("CheckExternalProxy: Proxy '#{proxy}' is not available")
        end
      end
    end

    def proxy_video_url(raw_url : String, *, region : String? = nil, absolute : Bool = false)
      url = URI.parse(raw_url)

      # Add some URL parameters
      params = url.query_params
      params["host"] = url.host.not_nil! # Should never be nil, in theory
      params["region"] = region if !region.nil?
      url.query_params = params

      if absolute
        if !@@proxy_alive.empty?
          return "#{@@proxy_alive}#{url.request_target}"
        else
          return "#{HOST_URL}#{url.request_target}"
        end
      else
        return url.request_target
      end
    end

    def add_params_to_url(url : String | URI, params : URI::Params) : URI
      url = URI.parse(url) if url.is_a?(String)

      url_query = url.query || ""

      # Append the parameters
      url.query = String.build do |str|
        if !url_query.empty?
          str << url_query
          str << '&'
        end

        str << params
      end

      return url
    end
  end
end
