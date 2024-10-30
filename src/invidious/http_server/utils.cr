require "uri"

module Invidious::HttpServer
  module Utils
    extend self

    @@proxy_list : Array(String) = [] of String
    @@current_proxy : String = ""
    @@count : Int64 = Time.utc.to_unix

    def check_external_proxy
      CONFIG.external_videoplayback_proxy.each do |proxy|
        begin
          response = HTTP::Client.get("#{proxy[:url]}/health")
          if response.status_code == 200
            if @@proxy_list.includes?(proxy[:url])
              next
            end
            if proxy[:balance]
              @@proxy_list << proxy[:url]
              LOGGER.debug("CheckExternalProxy: Adding proxy '#{proxy[:url]}' to the list of proxies")
            end
            break if proxy[:balance] == false && !@@proxy_list.empty?
            @@proxy_list << proxy[:url]
          end
        rescue
          if @@proxy_list.includes?(proxy[:url])
            LOGGER.debug("CheckExternalProxy: Proxy '#{proxy[:url]}' is not available, removing it from the list of proxies")
            @@proxy_list.delete(proxy[:url])
          end
          LOGGER.debug("CheckExternalProxy: Proxy '#{proxy[:url]}' is not available")
        end
      end
      LOGGER.trace("CheckExternalProxy: List of proxies:")
      LOGGER.trace("#{@@proxy_list.inspect}")
    end

    # TODO: If the function is called many times, it will return a random
    # proxy from the list. That is not how it should be.
    # It should return the same proxy, in multiple function calls
    def select_proxy
      if (@@count - (Time.utc.to_unix - 30)) <= 0
        return if @@proxy_list.size <= 0
        @@current_proxy = @@proxy_list[Random.rand(@@proxy_list.size)]
        LOGGER.debug("Current proxy is: '#{@@current_proxy}'")
        @@count = Time.utc.to_unix
      end
    end

    def get_external_proxy
      return @@current_proxy
    end

    def proxy_video_url(raw_url : String, *, region : String? = nil, absolute : Bool = false)
      url = URI.parse(raw_url)

      # Add some URL parameters
      params = url.query_params
      params["host"] = url.host.not_nil! # Should never be nil, in theory
      params["region"] = region if !region.nil?
      url.query_params = params

      if absolute
        if !(proxy = get_external_proxy()).empty?
          return "#{proxy}#{url.request_target}"
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
