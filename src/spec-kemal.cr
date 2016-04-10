require "spec"
require "kemal"

TIME_TO_SLEEP = 0.00001
APP_PORT = 1989
APP_ENV = "test"
APP_URL = "http://localhost:#{APP_PORT}"

Kemal.config.env = APP_ENV
Kemal.config.port = APP_PORT

def start
  spawn do
    Kemal.run
    Kemal.config.server.listen
  end
  sleep TIME_TO_SLEEP
end

def stop
  Kemal.config.server.close
  sleep TIME_TO_SLEEP
end

{% for method in %w(get post put head delete patch) %}
  def {{method.id}}(path, headers : HTTP::Headers? = nil, body : String? = nil)
    HTTP::Client.{{method.id}}(APP_URL + path, headers, body)
  end
{% end %}
