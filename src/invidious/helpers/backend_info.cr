module BackendInfo
  extend self
  @@exvpp_url : String = ""

  def get_videoplayback_proxy
    begin
      response = HTTP::Client.get "#{CONFIG.invidious_companion.sample.private_url}/info"
      exvpp_url = JSON.parse(response.body)["external_videoplayback_proxy"].to_s
      @@exvpp_url = exvpp_url
    rescue
    end
  end

  def get_exvpp
    return @@exvpp_url
  end
end
