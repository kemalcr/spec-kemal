require "spec"
require "kemal"

Kemal.config.logging = false

class Global
  @@response : HTTP::Client::Response?

  def self.response=(@@response)
  end

  def self.response
    @@response
  end
end

{% for method in %w(get post put head delete patch) %}
  def {{method.id}}(path, headers : HTTP::Headers? = nil, body : String? = nil)
    request = HTTP::Request.new("{{method.id}}".upcase, path, headers, body )
    Global.response = process_request request
  end
{% end %}

def process_request(request)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  main_handler = build_main_handler
  main_handler.call context
  response.close
  io.rewind
  client_response = HTTP::Client::Response.from_io(io, decompress: false)
  Global.response = client_response
end

def build_main_handler
  Kemal.config.setup
  main_handler = Kemal.config.handlers.first
  current_handler = main_handler
  Kemal.config.handlers.each_with_index do |handler, index|
    current_handler.next = handler
    current_handler = handler
  end
  main_handler
end

def response
  Global.response.not_nil!
end
