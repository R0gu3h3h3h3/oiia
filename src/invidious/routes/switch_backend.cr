{% skip_file if flag?(:api_only) %}

module Invidious::Routes::BackendSwitcher
  def self.switch(env)
    referer = get_referer(env)
    backend_id = env.params.query["backend_id"]

    # Checks if there is any alternative domain, like a second domain name,
    # TOR or I2P address
    if alt = CONFIG.alternative_domains.index(env.request.headers["Host"])
      env.response.cookies["SERVER_ID"] = Invidious::User::Cookies.server_id(CONFIG.alternative_domains[alt], backend_id)
    else
      env.response.cookies["SERVER_ID"] = Invidious::User::Cookies.server_id(CONFIG.domain, backend_id)
    end

    env.redirect referer
  end
end
