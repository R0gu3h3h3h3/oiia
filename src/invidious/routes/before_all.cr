module Invidious::Routes::BeforeAll
  def self.handle(env)
    preferences = Preferences.from_json("{}")

    begin
      if prefs_cookie = env.request.cookies["PREFS"]?
        preferences = Preferences.from_json(URI.decode_www_form(prefs_cookie.value))
      else
        if language_header = env.request.headers["Accept-Language"]?
          if language = ANG.language_negotiator.best(language_header, LOCALES.keys)
            preferences.locale = language.header
          end
        end
      end
    rescue
      preferences = Preferences.from_json("{}")
    end

    env.set "preferences", preferences
    env.response.headers["X-XSS-Protection"] = "1; mode=block"
    env.response.headers["X-Content-Type-Options"] = "nosniff"

    extra_media_csp = ""
    extra_connect_csp = ""

    if CONFIG.invidious_companion.present?
      CONFIG.invidious_companion.each_with_index do |companion, index|
        if companion.domain.each_with_index do |domain, domain_index|
             if domain == env.request.headers["Host"]
               env.set "current_companion", index
               env.set "companion_public_url", companion.public_url.to_s
               env.set "domain_index", domain_index
               if domain_index == 2
                 env.set "companion_public_url", companion.i2p_public_url.to_s
               end
               break
             end
           end
        end
        break if env.get?("current_companion")
      end

      if env.get?("current_companion").try &.as(Int32) == nil
        if !env.request.cookies[CONFIG.server_id_cookie_name]?
          env.response.cookies[CONFIG.server_id_cookie_name] = Invidious::User::Cookies.server_id(env.request.headers["Host"])
        end

        begin
          current_companion = env.request.cookies[CONFIG.server_id_cookie_name].value.try &.to_i
        rescue
          current_companion = rand(CONFIG.invidious_companion.size)
        end

        if current_companion > CONFIG.invidious_companion.size
          current_companion = current_companion % CONFIG.invidious_companion.size
          env.response.cookies[CONFIG.server_id_cookie_name] = Invidious::User::Cookies.server_id(env.request.headers["Host"], current_companion)
        end

        env.set "current_companion", current_companion
        env.set "companion_public_url", CONFIG.invidious_companion[current_companion].public_url.to_s
      end

      extra_media_csp, extra_connect_csp = BackendInfo.get_csp(env.get("current_companion").as(Int32))
    end

    # Allow media resources to be loaded from google servers
    # TODO: check if *.youtube.com can be removed
    if CONFIG.disabled?("local") || !preferences.local
      extra_media_csp += " https://*.googlevideo.com:443 https://*.youtube.com:443"
    end

    # Only allow the pages at /embed/* to be embedded
    if env.request.resource.starts_with?("/embed")
      frame_ancestors = "'self' file: http: https:"
    else
      frame_ancestors = "'none'"
    end

    scheme = env.request.headers["X-Forwarded-Proto"]? || ("https" if CONFIG.https_only) || "http"
    env.set "scheme", scheme

    # TODO: Remove style-src's 'unsafe-inline', requires to remove all
    # inline styles (<style> [..] </style>, style=" [..] ")
    env.response.headers["Content-Security-Policy"] = {
      "default-src 'none'",
      "script-src 'self'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: " + "#{scheme}://#{env.request.headers["Host"]?}",
      "font-src 'self' data:",
      "connect-src 'self'" + extra_connect_csp,
      "manifest-src 'self'",
      "media-src 'self' blob:" + extra_media_csp,
      "child-src 'self' blob:",
      "frame-src 'self'",
      "frame-ancestors " + frame_ancestors,
    }.join("; ") if CONFIG.csp

    env.response.headers["Referrer-Policy"] = "same-origin"

    # Ask the chrom*-based browsers to disable FLoC
    # See: https://blog.runcloud.io/google-floc/
    env.response.headers["Permissions-Policy"] = "interest-cohort=()"

    if (Kemal.config.ssl || CONFIG.https_only) && CONFIG.hsts
      env.response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"
    end

    return if {
                "/sb/",
                "/vi/",
                "/s_p/",
                "/yts/",
                "/ggpht/",
                "/api/manifest/",
                "/videoplayback",
                "/latest_version",
                "/download",
              }.any? { |r| env.request.resource.starts_with? r }

    if env.request.cookies.has_key? "SID"
      sid = env.request.cookies["SID"].value

      if sid.starts_with? "v1:"
        raise "Cannot use token as SID"
      end

      if email = Database::SessionIDs.select_email(sid)
        user = Database::Users.select!(email: email)
        csrf_token = generate_response(sid, {
          ":authorize_token",
          ":playlist_ajax",
          ":signout",
          ":subscription_ajax",
          ":token_ajax",
          ":watch_ajax",
        }, HMAC_KEY, 1.week)

        preferences = user.preferences
        env.set "preferences", preferences

        env.set "sid", sid
        env.set "csrf_token", csrf_token
        env.set "user", user
      end
    end

    dark_mode = convert_theme(env.params.query["dark_mode"]?) || preferences.dark_mode.to_s
    thin_mode = env.params.query["thin_mode"]? || preferences.thin_mode.to_s
    thin_mode = thin_mode == "true"
    locale = env.params.query["hl"]? || preferences.locale

    preferences.dark_mode = dark_mode
    preferences.thin_mode = thin_mode
    preferences.locale = locale
    env.set "preferences", preferences

    current_page = env.request.path
    if env.request.query
      query = HTTP::Params.parse(env.request.query.not_nil!)

      if query["referer"]?
        query["referer"] = get_referer(env, "/")
      end

      current_page += "?#{query}"
    end

    env.set "current_page", URI.encode_www_form(current_page)
  end
end
