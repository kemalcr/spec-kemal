require "spec"
require "kemal"

TIME_TO_SLEEP = 0.00001
APP_PORT = 1989
APP_ENV = "test"
APP_URL = "http://localhost:#{APP_PORT}"

Kemal.config.env = APP_ENV
Kemal.config.port = APP_PORT

Spec.before_each do
  spawn do
    Kemal.run
    Kemal.config.server.listen
  end
  sleep TIME_TO_SLEEP
end

Spec.after_each do
  spawn do
    Kemal.config.server.close
  end
end

{% for method in %w(get post put head delete patch) %}
  def {{method.id}}(path, headers : HTTP::Headers? = nil, body : String? = nil)
    HTTP::Client.{{method.id}}(APP_URL + path, headers, body)
  end
{% end %}
