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
end
