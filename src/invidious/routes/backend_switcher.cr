{% skip_file if flag?(:api_only) %}

module Invidious::Routes::BackendSwitcher
  def self.switch(env)
    referer = get_referer(env)
    backend_id = env.params.query["backend_id"]?.try &.to_i

    if backend_id.nil?
      return error_template(400, "Backend ID is required")
    end

    env.response.cookies[CONFIG.server_id_cookie_name] = Invidious::User::Cookies.server_id(env.request.headers["Host"], backend_id)

    env.redirect referer
  end
end
