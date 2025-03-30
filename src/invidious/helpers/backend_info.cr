module BackendInfo
  extend self
  @@exvpp_url : Array(String) = Array.new(CONFIG.invidious_companion.size, "")
  @@status : Array(Int32) = Array.new(CONFIG.invidious_companion.size, 0)

  def check_backends
    check_companion()
  end

  def check_companion
    CONFIG.invidious_companion.each_with_index do |companion, index|
      spawn do
        begin
          response = HTTP::Client.get "#{companion.private_url}/healthz"
          if response.status_code == 200
            check_videoplayback_proxy(companion, index)
          else
            @@status[index] = 0
          end
        rescue
          @@status[index] = 0
        end
      end
    end
  end

  private def check_videoplayback_proxy(companion : Config::CompanionConfig, index : Int32)
    begin
      info = HTTP::Client.get "#{companion.private_url}/info"
      exvpp_url = JSON.parse(info.body)["external_videoplayback_proxy"]?.try &.to_s
      exvpp_url = "" if exvpp_url.nil?
      @@exvpp_url[index] = exvpp_url
      if exvpp_url.empty?
        @@status[index] = 2
        return
      else
        begin
          exvpp_health = HTTP::Client.get "#{exvpp_url}/health"
          if exvpp_health.status_code == 200
            @@status[index] = 2
            return
          else
            @@status[index] = 1
          end
        rescue
          @@status[index] = 1
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
