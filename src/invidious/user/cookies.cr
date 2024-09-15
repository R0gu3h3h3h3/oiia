require "http/cookie"

struct Invidious::User
  module Cookies
    extend self

    # Note: we use ternary operator because the two variables
    # used in here are not booleans.
    @@secure = (Kemal.config.ssl || CONFIG.https_only) ? true : false

    # Session ID (SID) cookie
    # Parameter "domain" comes from the global config
    def sid(domain : String?, sid) : HTTP::Cookie
      # Not secure if it's being accessed from I2P
      # Browsers expect the domain to include https. On I2P there is no HTTPS
      if domain.not_nil!.split(".").last == "i2p"
        @@secure = false
      end
      return HTTP::Cookie.new(
        name: "SID",
        domain: domain,
        value: sid,
        expires: Time.utc + 2.years,
        secure: @@secure,
        http_only: true,
        samesite: HTTP::Cookie::SameSite::Lax
      )
    end

    # Preferences (PREFS) cookie
    # Parameter "domain" comes from the global config
    def prefs(domain : String?, preferences : Preferences) : HTTP::Cookie
      # Not secure if it's being accessed from I2P
      # Browsers expect the domain to include https. On I2P there is no HTTPS
      if domain.not_nil!.split(".").last == "i2p"
        @@secure = false
      end
      return HTTP::Cookie.new(
        name: "PREFS",
        domain: domain,
        value: URI.encode_www_form(preferences.to_json),
        expires: Time.utc + 2.years,
        secure: @@secure,
        http_only: false,
        samesite: HTTP::Cookie::SameSite::Lax
      )
    end

    # Server ID (SERVER_ID) cookie used for Sticky Sessions
    # Parameter "domain" comes from the global config
    def server_id(domain : String?, server_id) : HTTP::Cookie
      return HTTP::Cookie.new(
        name: "SERVER_ID",
        domain: domain,
        value: server_id,
        secure: false,
        http_only: true,
        samesite: HTTP::Cookie::SameSite::Lax
      )
    end
  end
end
