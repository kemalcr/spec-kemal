require "http/web_socket"
require "socket"

# WebSocket test helpers. See the **WebSocket** section in the spec-kemal README.
#
# * **Handshake (in-memory)**: `get` with `websocket: true` or [websocket_request_headers] — the
#   `ws` block does not run (no [upgrade_handler] in [SpecKemal.process_request]).
# * **Session (duplex)**: [connect_websocket] — full WebSocket; uses a socket pair
#   and calls `response.upgrade_handler` like [HTTP::Server::RequestProcessor].

# :nodoc:
DEFAULT_WEBSOCKET_KEY = "dGhlIHNhbXBsZSBub25jZQ=="

# :nodoc:
DEFAULT_WEBSOCKET_HOST = "localhost"

# :nodoc:
DEFAULT_WEBSOCKET_ORIGIN = "http://#{DEFAULT_WEBSOCKET_HOST}"

# Returns headers for a valid WebSocket upgrade request.
# Use a fixed *sec_key* for deterministic [Sec-WebSocket-Accept] in assertions, or pass `nil` to use
# [DEFAULT_WEBSOCKET_KEY] (RFC 6455 example value).
#
# `Host` and `Origin` default to [DEFAULT_WEBSOCKET_HOST] / [DEFAULT_WEBSOCKET_ORIGIN] so the
# handshake passes Kemal's same-origin check — Kemal rejects an upgrade whose `Origin` is missing
# or does not match `Host` with `403`. Pass *origin* to test a cross-origin request, or override
# `Host` / delete `Origin` on the returned headers to test the other rejection paths.
def websocket_request_headers(
  sec_key : String? = nil,
  origin : String? = nil,
) : HTTP::Headers
  key = sec_key || DEFAULT_WEBSOCKET_KEY
  HTTP::Headers{
    "Host"                  => DEFAULT_WEBSOCKET_HOST,
    "Origin"                => origin || DEFAULT_WEBSOCKET_ORIGIN,
    "Connection"            => "Upgrade",
    "Upgrade"               => "websocket",
    "Sec-WebSocket-Version" => HTTP::WebSocket::Protocol::VERSION,
    "Sec-WebSocket-Key"     => key,
  }
end

# [GET] with a WebSocket-style handshake. Merges [websocket_request_headers] when *websocket* is `true`
# (*headers* override defaults for duplicate keys).
# The response is still in-memory [SpecKemal.process_request] — the `ws` route *handler* (e.g. [on_message])
# is **not** run; use [connect_websocket] for that.
def get(
  path : String,
  headers : HTTP::Headers? = nil,
  body : String? = nil,
  *,
  websocket : Bool,
) : HTTP::Client::Response
  h = (headers || HTTP::Headers.new).dup
  if websocket
    w = websocket_request_headers
    w.merge! h
    h = w
  end
  SpecKemal.process_request(HTTP::Request.new("GET", path, h, body))
end

# Duplex WebSocket: runs Kemal *ws* code on a real connection, then gives you a client [HTTP::WebSocket].
#
# The last [response] is the **101** as seen by the client. The block can send and receive messages.
# After the block, the client WebSocket and connection I/Os are closed.
def connect_websocket(
  path : String,
  headers : HTTP::Headers? = nil,
  sec_key : String? = nil,
  origin : String? = nil,
  &block : HTTP::WebSocket -> Nil
) : Nil
  base = websocket_request_headers(sec_key: sec_key, origin: origin)
  base.merge! headers if headers
  request = HTTP::Request.new("GET", path, base, nil)
  inner_connect_websocket(request) do |client_ws, _hs|
    block.call(client_ws)
  end
end

# :nodoc: — for advanced use (e.g. inspect the 101 in the same block)
def inner_connect_websocket(
  request : HTTP::Request,
  &block : (HTTP::WebSocket, HTTP::Client::Response) -> Nil
) : Nil
  ex_ch = Channel(Exception?).new(1)
  done = Channel(Nil).new(1)

  server_io, client_io = connected_socket_pair
  begin
    response = HTTP::Server::Response.new(server_io)
    SessionInjector.run(request)
    context = HTTP::Server::Context.new(request, response)
    main_handler = SpecKemal.build_main_handler
    main_handler.call(context)

    # Only `HTTP::Server::Response#upgrade` writes the `101` out on its own. A rejected handshake
    # (Kemal answers `403` for a bad `Origin`, `426` for a bad version, ...) stays in the response
    # buffer, so close it first or the read below blocks on an empty socket forever.
    response.close unless response.upgrade_handler

    handshake = HTTP::Client::Response.from_io(client_io, ignore_body: true, decompress: false)
    Global.response = handshake

    upgrade = context.response.upgrade_handler
    raise "Kemal did not set a WebSocket upgrade (status #{handshake.status_code}, path #{request.path})" unless upgrade

    spawn(name: "spec-kemal-ws-upgrade") do
      begin
        upgrade.call(server_io)
      rescue e : Exception
        ex_ch.send e
      else
        ex_ch.send nil
      end
    ensure
      done.send nil
    end
    spawned = true

    Fiber.yield

    client_ws = HTTP::WebSocket.new(HTTP::WebSocket::Protocol.new(client_io, masked: true, sync_close: true))
    block.call(client_ws, handshake)
  ensure
    client_io.close rescue nil
    server_io.close rescue nil
  end
  if spawned
    ex = ex_ch.receive
    raise ex if ex
    done.receive
  end
end

private def connected_socket_pair : {IO, IO}
  {% if !flag?(:win32) %}
    return UNIXSocket.pair
  {% end %}

  tcp = TCPServer.new("127.0.0.1", 0)
  begin
    local = tcp.local_address.as(Socket::IPAddress)
    port = local.port
    accept_ch = Channel(TCPSocket).new(1)
    spawn { accept_ch.send tcp.accept.as(TCPSocket) }
    client = TCPSocket.new("127.0.0.1", port)
    server = accept_ch.receive
    {server.as(IO), client.as(IO)}
  ensure
    tcp.close
  end
end
