# spec-kemal/session - Session testing support for Kemal applications
#
# This module extends spec-kemal with session testing capabilities.
# It integrates with kemal-session to allow setting and testing
# session values in your specs.
#
# ## Installation
#
# Add kemal-session to your development dependencies:
#
# ```yaml
# development_dependencies:
#   kemal-session:
#     github: kemalcr/kemal-session
# ```
#
# ## Usage
#
# Require this module instead of the base spec-kemal:
#
# ```crystal
# require "spec-kemal/session"
# ```
#
# Configure the session secret in your spec helper:
#
# ```crystal
# Spec.before_each do
#   Kemal::Session.config.secret = "test-secret"
# end
# ```
#
# Use `with_session` to test session-based features:
#
# ```crystal
# it "shows user dashboard" do
#   with_session do |session|
#     session.int("user_id", 42)
#
#     get "/dashboard"
#     response.body.should contain "Welcome"
#   end
# end
# ```

require "./version"
require "../spec-kemal"
require "kemal-session"

# Extend Global class with session storage.
# This allows the session to be shared between `with_session` and
# the HTTP helper methods (get, post, etc.)
class Global
  # The current test session, if any.
  # When set, all HTTP requests will include this session's cookie.
  class_property? session : Kemal::Session?
end

# Creates a new Kemal session for testing.
#
# This method:
# 1. Validates that the session secret is configured
# 2. Destroys any existing session
# 3. Creates a new session with a secure random ID
#
# Raises if `Kemal::Session.config.secret` is not set.
#
# NOTE: This is a private method. Use `with_session` instead.
private def create_session : Kemal::Session
  if Kemal::Session.config.secret.empty?
    raise "Kemal session secret not set. " \
          "Set Kemal::Session.config.secret in your spec helper."
  end

  destroy_session
  Global.session = Kemal::Session.new(Random::Secure.hex)
end

# Creates a new session, yields it to the block, and ensures cleanup.
#
# All spec-kemal HTTP requests (get, post, etc.) made within the block
# will automatically include this session's cookie, simulating an
# authenticated user.
#
# The session is automatically destroyed when the block exits,
# even if an exception is raised.
#
# ## Parameters
#
# Yields a `Kemal::Session` instance for setting session values.
#
# ## Example
#
# ```crystal
# it "requires login" do
#   get "/dashboard"
#   response.status_code.should eq 401
# end
#
# it "shows dashboard for logged-in user" do
#   with_session do |session|
#     session.int("user_id", 123)
#     session.string("username", "alice")
#     session.bool("admin", false)
#
#     get "/dashboard"
#     response.status_code.should eq 200
#     response.body.should contain "Welcome, alice"
#   end
# end
# ```
#
# ## Available Session Methods
#
# ```crystal
# session.string("key", "value")     # Store a String
# session.int("key", 42)             # Store an Int32
# session.bigint("key", 123_i64)     # Store an Int64
# session.float("key", 3.14)         # Store a Float64
# session.bool("key", true)          # Store a Bool
# session.object("key", user)        # Store any JSON-serializable object
# ```
#
# ## Notes
#
# - The session is destroyed after the block, simulating logout
# - Each `with_session` call creates a fresh session
# - Nested `with_session` calls will destroy the outer session
def with_session(&) : Nil
  session = create_session
  yield session
ensure
  destroy_session
end

# Destroys the current test session.
#
# This method:
# 1. Calls `destroy` on the session (clears stored data)
# 2. Sets `Global.session` to nil (stops cookie injection)
#
# NOTE: This is a private method. Sessions are automatically
# destroyed when exiting a `with_session` block.
private def destroy_session : Nil
  Global.session?.try(&.destroy)
  Global.session = nil
end
