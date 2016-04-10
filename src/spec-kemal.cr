require "spec"
require "kemal"

TIME_TO_SLEEP = 0.00001
APP_PORT = 1989
APP_ENV = "test"

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
