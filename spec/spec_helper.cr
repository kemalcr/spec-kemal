require "spec"
require "kemal"
require "kemal-session"

require "../src/spec-kemal"
require "../src/spec-kemal/session"

Spec.before_each do
  config = Kemal.config
  config.env = "test"
  Kemal::Session.config.secret = "🤫"
  config.setup
end

Spec.after_each do
  Kemal.config.clear
end
