require "spec"
require "kemal"

Kemal.config.env = "test"

Spec.before_each do
  spawn do
    Kemal.run
    Kemal.config.server.listen
  end
  sleep 0.00001
end

Spec.after_each do
  spawn do
    Kemal.run
    Kemal.config.server.listen
  end
end
