# spec-kemal - Testing helpers for the Kemal web framework
#
# This module provides convenient methods for testing Kemal applications
# using Crystal's built-in spec library.
#
# ## Basic Usage
#
# ```
# require "spec-kemal"
#
# describe "My App" do
#   it "renders homepage" do
#     get "/"
#     response.status_code.should eq 200
#   end
# end
# ```
#
# ## Available HTTP Methods
#
# - `get(path, headers?, body?)` - Send GET request
# - `post(path, headers?, body?)` - Send POST request
# - `put(path, headers?, body?)` - Send PUT request
# - `patch(path, headers?, body?)` - Send PATCH request
# - `delete(path, headers?, body?)` - Send DELETE request
# - `head(path, headers?, body?)` - Send HEAD request
# - `options(path, headers?, body?)` - Send OPTIONS request

require "spec"
require "kemal"

# Disable logging by default for cleaner test output
Kemal.config.logging = false

# Links Kemal's [HTTP::Handler] chain. Used by [process_request] and [./spec-kemal/websocket] WebSocket flow.
module SpecKemal
  def self.build_main_handler : HTTP::Handler
    main_handler = Kemal.config.handlers.first
    current_handler = main_handler

    Kemal.config.handlers.each do |handler|
      current_handler.next = handler
      current_handler = handler
    end

    main_handler
  end

  # In-memory handler run. Does **not** call [HTTP::Server::Response#upgrade_handler]; use
  # the top-level `connect_websocket` helper for full WebSocket message tests.
  def self.process_request(request : HTTP::Request) : HTTP::Client::Response
    io = IO::Memory.new
    response = HTTP::Server::Response.new(io)

    SessionInjector.run(request)

    context = HTTP::Server::Context.new(request, response)
    main_handler = build_main_handler
    main_handler.call(context)

    response.close
    io.rewind
    client_response = HTTP::Client::Response.from_io(io, decompress: false)
    Global.response = client_response
  end
end

# Internal hook for session cookie injection. When spec-kemal/session is required,
# it registers a callback here. This avoids referencing Global.session? in the
# base library, which would fail to compile when the session extension is not used.
class SessionInjector
  @@callback : (HTTP::Request -> Nil)? = nil

  def self.register(&block : HTTP::Request -> Nil)
    @@callback = block
  end

  def self.run(request : HTTP::Request) : Nil
    @@callback.try(&.call(request))
  end
end

# Internal class for storing the response between requests.
# This allows the `response` helper method to access the last response.
#
# NOTE: This uses class variables which are not thread-safe.
# Tests should be run sequentially, not in parallel.
class Global
  # The last HTTP response received from a test request
  @@response : HTTP::Client::Response?

  # Sets the response from the last request
  def self.response=(@@response)
  end

  # Returns the response from the last request
  def self.response
    @@response
  end
end

# Generate HTTP helper methods for each HTTP verb.
# Each method creates an HTTP request and processes it through Kemal's handlers.
#
# ## Parameters
#
# - `path` - The request path (e.g., "/users", "/api/posts?page=2")
# - `headers` - Optional HTTP headers to include in the request
# - `body` - Optional request body as a string
#
# ## Examples
#
# ```
# # Simple GET request
# get "/"
#
# # GET with headers
# get "/api/users", headers: HTTP::Headers{"Authorization" => "Bearer token"}
#
# # POST with JSON body
# post "/api/users",
#   headers: HTTP::Headers{"Content-Type" => "application/json"},
#   body: {name: "John"}.to_json
#
# # DELETE request
# delete "/api/users/1"
# ```
{% for method in %w[get post put patch delete head options] %}
  # Sends a {{ method.id.upcase }} request to the specified path.
  #
  # ## Parameters
  #
  # - `path` : The URL path to request
  # - `headers` : Optional HTTP headers
  # - `body` : Optional request body
  #
  # ## Example
  #
  # ```crystal
  # {{ method.id }} "/example"
  # response.status_code.should eq 200
  # ```
  def {{ method.id }}(path : String, headers : HTTP::Headers? = nil, body : String? = nil) : HTTP::Client::Response
    request = HTTP::Request.new("{{ method.id }}".upcase, path, headers, body)
    SpecKemal.process_request(request)
  end
{% end %}

# Returns the response from the last HTTP request.
#
# This method provides access to the `HTTP::Client::Response` object
# from the most recent test request. Use it to make assertions about
# the response status, body, headers, and cookies.
#
# ## Example
#
# ```
# get "/users"
#
# response.status_code.should eq 200
# response.body.should contain "John"
# response.headers["Content-Type"].should eq "application/json"
# ```
#
# ## Available Response Properties
#
# - `status_code : Int32` - HTTP status code (200, 404, etc.)
# - `status : HTTP::Status` - Status as enum (HTTP::Status::OK, etc.)
# - `body : String` - Response body content
# - `headers : HTTP::Headers` - Response headers
# - `cookies : HTTP::Cookies` - Response cookies
# - `success? : Bool` - True if status is 2xx
# - `content_type : String?` - Content-Type header value
#
# Raises `NilAssertionError` if called before making a request.
def response : HTTP::Client::Response
  # ameba:disable Lint/NotNil
  Global.response.not_nil!
  # ameba:enable Lint/NotNil
end

require "./spec-kemal/websocket"
