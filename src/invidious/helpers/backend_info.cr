module BackendInfo
  extend self
  @@exvpp_url : String = ""
  @@status : Int32 = 0

  def check_backends
    check_videoplayback_proxy()
    check_companion()
  end

  def check_companion
    begin
      response = HTTP::Client.get "#{CONFIG.invidious_companion.sample.private_url}/healthz"
      if response.status_code == 200
        @@status = 1
        check_videoplayback_proxy()
      else
        @@status = 0
      end
    rescue
      @@status = 0
    end
  end

  def check_videoplayback_proxy
    begin
      info = HTTP::Client.get "#{CONFIG.invidious_companion.sample.private_url}/info"
      exvpp_url = JSON.parse(info.body)["external_videoplayback_proxy"]?.try &.to_s
      exvpp_url = "" if exvpp_url.nil?
      @@exvpp_url = exvpp_url
      if exvpp_url.empty?
        @@status = 2
        return
      else
        begin
          exvpp_health = HTTP::Client.get "#{exvpp_url}/health"
          if exvpp_health.status_code == 200
            @@status = 2
            return
          end
        rescue
          @@status = 1
        end
      end
    rescue
    end
  end

  def get_status
    return @@status
  end

  def get_exvpp
    return @@exvpp_url
  end
end
