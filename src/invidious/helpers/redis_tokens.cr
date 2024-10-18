module Tokens
  extend self
  @@po_token : String | Nil
  @@visitor_data : String | Nil

  def refresh_tokens
    @@po_token = REDIS_DB.get("invidious:po_token")
    @@visitor_data = REDIS_DB.get("invidious:visitor_data")
    LOGGER.debug("RefreshTokens: Tokens are:")
    LOGGER.debug("RefreshTokens: po_token: #{@@po_token}")
    LOGGER.debug("RefreshTokens: visitor_data: #{@@visitor_data}")
  end

  def get_tokens
    return {@@po_token, @@visitor_data}
  end

  def get_po_token
    return @@po_token
  end

  def get_visitor_data
    return @@visitor_data
  end

  def generate_tokens(user : String)
    po_token = ""
    visitor_data = ""
    attempts = 0

    LOGGER.debug("Generating po_token and visitor_data for user: '#{user}'")
    REDIS_DB.publish("generate-token", "#{user}")

    while REDIS_DB.get("invidious:#{user}:po_token").nil? && REDIS_DB.get("invidious:#{user}:visitor_data").nil?
      if attempts > 50
        break
      end
      LOGGER.debug("Waiting for tokens to arrive at redis for user: '#{user}'")
      attempts += 1
      sleep 250.milliseconds
    end

    po_token = REDIS_DB.get("invidious:#{user}:po_token")
    visitor_data = REDIS_DB.get("invidious:#{user}:visitor_data")

    LOGGER.debug("Tokens successfully generated for user: '#{user}'")
    return {po_token, visitor_data}
  end
end
