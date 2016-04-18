require "spec"
require "kemal"

TIME_TO_SLEEP = 0.00001
APP_HOST_BINDING = "127.0.0.1"
APP_PORT = 1989
APP_ENV = "test"
APP_URL = "http://localhost:#{APP_PORT}"

Kemal.config.env = APP_ENV
Kemal.config.host_binding = APP_HOST_BINDING
Kemal.config.port = APP_PORT
Kemal.config.logging = false

$response : HTTP::Client::Response?

def start
  spawn do
    Kemal.run
    Kemal.config.server.not_nil!.listen
  end
  sleep TIME_TO_SLEEP
end

def stop
  Kemal.config.server.not_nil!.close
  sleep TIME_TO_SLEEP
end

{% for method in %w(get post put head delete patch) %}
  def {{method.id}}(path, headers : HTTP::Headers? = nil, body : String? = nil)
    $response = HTTP::Client.{{method.id}}(APP_URL + path, headers, body)
  end
{% end %}

def response
  $response.not_nil!
end
