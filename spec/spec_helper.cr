require "spec"
require "kemal"
require "../src/spec-kemal"

Spec.before_each do
  config = Kemal.config
  config.env = "test"
  config.setup
end

Spec.after_each do
  Kemal.config.clear
end
