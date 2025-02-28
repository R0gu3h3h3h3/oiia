class Invidious::Jobs::CheckBackend < Invidious::Jobs::BaseJob
  def initialize
  end

  def begin
    loop do
      # BackendInfo.check_backends
      BackendInfo.get_videoplayback_proxy
      LOGGER.info("Backend Checker: Done, sleeping for 120 seconds")
      sleep 120.seconds
      Fiber.yield
    end
  end
end
