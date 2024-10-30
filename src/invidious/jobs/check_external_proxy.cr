class Invidious::Jobs::CheckExternalProxy < Invidious::Jobs::BaseJob
  def initialize
  end

  def begin
    loop do
      HttpServer::Utils.check_external_proxy
      HttpServer::Utils.select_proxy
      LOGGER.info("CheckExternalProxy: Done, sleeping for 15 seconds")
      sleep 15.seconds
      Fiber.yield
    end
  end
end
