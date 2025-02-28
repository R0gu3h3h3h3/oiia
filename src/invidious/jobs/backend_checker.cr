class Invidious::Jobs::CheckBackend < Invidious::Jobs::BaseJob
  def initialize
  end

  def begin
    loop do
      BackendInfo.get_videoplayback_proxy
      LOGGER.info("Backend Checker: Done, sleeping for 60 seconds")
      sleep 60.seconds
      Fiber.yield
    end
  end
end
