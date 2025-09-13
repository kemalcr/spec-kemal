require "kemal-session"

class Global
  class_property? session : Kemal::Session?
end

private def create_session : Kemal::Session
  raise "Kemal session secret not set." if Kemal::Session.config.secret.empty?

  destroy_session
  Global.session = Kemal::Session.new(Random::Secure.hex)
end

# Creates a new session, yields it to the block, and ensures it is destroyed afterwards.
#
# All spec-kemal requests made within the block will use this session.
def with_session(&)
  session = create_session
  yield session
ensure
  destroy_session
end

private def destroy_session
  Global.session?.try(&.destroy)
  Global.session = nil
end
