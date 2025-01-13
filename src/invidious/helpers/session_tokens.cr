module SessionTokens
  extend self
  @@po_token : String | Nil
  @@visitor_data : String | Nil

  def refresh_tokens
    begin
      response = HTTP::Client.get "#{CONFIG.tokens_server}/generate"
      if !response.status_code == 200
        LOGGER.error("RefreshSessionTokens: Expected response to have status code 200 but got #{response.status_code} from #{CONFIG.tokens_server}")
      end
      json = JSON.parse(response.body)
      @@po_token = json.try &.["potoken"].as_s || nil
      @@visitor_data = json.try &.["visitorData"].as_s || nil
    rescue ex
      LOGGER.error("RefreshSessionTokens: Failed to fetch tokens from #{CONFIG.tokens_server}: #{ex.message}")
      return
    end

    if !@@po_token.nil? && !@@visitor_data.nil?
      set_tokens
      LOGGER.debug("RefreshSessionTokens: Successfully updated po_token and visitor_data")
    else
      LOGGER.warn("RefreshSessionTokens: Tokens are empty!. Invidious will use the tokens that are on the configuration file")
    end
    LOGGER.trace("RefreshSessionTokens: Tokens are:")
    LOGGER.trace("RefreshSessionTokens: po_token: #{CONFIG.po_token}")
    LOGGER.trace("RefreshSessionTokens: visitor_data: #{CONFIG.visitor_data}")
  end

  def set_tokens
    CONFIG.po_token = @@po_token
    CONFIG.visitor_data = @@visitor_data
  end
end
