class Invidious::Jobs::CheckBackend < Invidious::Jobs::BaseJob
  def initialize
  end

  def begin
    loop do
      BackendInfo.check_backends
      LOGGER.info("Backend Checker: Done, sleeping for 30 seconds")
      sleep 30.seconds
      Fiber.yield
    end
  end
end
