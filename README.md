# spec-kemal

[![CI](https://github.com/kemalcr/spec-kemal/actions/workflows/ci.yml/badge.svg)](https://github.com/kemalcr/spec-kemal/actions/workflows/ci.yml)
[![GitHub release](https://img.shields.io/github/release/kemalcr/spec-kemal.svg)](https://github.com/kemalcr/spec-kemal/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Testing helpers for the [Kemal](https://kemalcr.com) web framework. Write expressive and readable tests for your Kemal applications using Crystal's built-in `spec` library.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
  - [HTTP Methods](#http-methods)
  - [QUERY requests](#query-requests)
  - [WebSocket testing](#websocket-testing)
  - [Response Object](#response-object)
  - [Headers](#headers)
  - [Request Body](#request-body)
- [Testing Patterns](#testing-patterns)
  - [JSON APIs](#json-apis)
  - [Form Data](#form-data)
  - [Authentication](#authentication)
  - [Sessions](#sessions)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Installation

Add spec-kemal to your `shard.yml` as a **development dependency**:

```yaml
name: your-kemal-app
version: 0.1.0

dependencies:
  kemal:
    github: kemalcr/kemal

development_dependencies:
  spec-kemal:
    github: kemalcr/spec-kemal
```

Then run:

```bash
shards install
```

## Quick Start

### 1. Set up your spec helper

Create or update `spec/spec_helper.cr`:

```crystal
require "spec"
require "spec-kemal"
require "../src/your-kemal-app"

Spec.before_each do
  Kemal.config.env = "test"
  Kemal.config.setup
end

Spec.after_each do
  Kemal.config.clear
end
```

### 2. Write your tests

```crystal
# spec/your-kemal-app_spec.cr
require "./spec_helper"

describe "My Kemal App" do
  it "renders the homepage" do
    get "/"
    response.status_code.should eq 200
    response.body.should contain "Welcome"
  end

  it "creates a new user" do
    post "/users", body: {name: "Crystal"}.to_json,
      headers: HTTP::Headers{"Content-Type" => "application/json"}
    
    response.status_code.should eq 201
  end
end
```

### 3. Run your tests

```bash
KEMAL_ENV=test crystal spec
```

## API Reference

### HTTP Methods

spec-kemal provides helper methods for all standard HTTP verbs:

| Method | Description |
|--------|-------------|
| `get(path, headers?, body?)` | Sends a GET request |
| `post(path, headers?, body?)` | Sends a POST request |
| `put(path, headers?, body?)` | Sends a PUT request |
| `patch(path, headers?, body?)` | Sends a PATCH request |
| `delete(path, headers?, body?)` | Sends a DELETE request |
| `head(path, headers?, body?)` | Sends a HEAD request |
| `options(path, headers?, body?)` | Sends an OPTIONS request |
| `query(path, headers?, body?)` | Sends a QUERY request ([RFC 10008](https://www.rfc-editor.org/rfc/rfc10008)) |

**Parameters:**

- `path : String` - The request path (e.g., `"/users"`, `"/api/v1/posts?page=2"`)
- `headers : HTTP::Headers?` - Optional HTTP headers
- `body : String?` - Optional request body

An additional overload is available for GET with a WebSocket handshake:

- `get(path, headers?, body?, *, websocket : Bool)` — when `websocket` is `true`, builds a valid `Upgrade: websocket` request (see [WebSocket testing](#websocket-testing)).

### QUERY requests

Kemal supports the HTTP QUERY method ([RFC 10008](https://www.rfc-editor.org/rfc/rfc10008)), a safe and idempotent method that carries the query in the request body instead of the URL. The `query` helper works like every other verb:

```crystal
query "/search" do |env|
  env.params.json["q"].to_s
end

query "/search",
  headers: HTTP::Headers{"Content-Type" => "application/json"},
  body: {q: "crystal"}.to_json

response.status_code.should eq 200
response.body.should eq "crystal"
```

Kemal rejects a QUERY request that has a body but **no** `Content-Type` header with `400`, so set the header whenever you send a query body:

```crystal
query "/search", body: %({"q":"crystal"})
response.status_code.should eq 400
```

### WebSocket testing

Kemal exposes WebSockets with `ws "/path"`. spec-kemal splits testing into **handshake-only** (fast, in-memory) and **full duplex** (real upgrade, your `on_message` runs).

| Approach | API | `ws` handler runs? | Typical assertions |
|----------|-----|-------------------|--------------------|
| Handshake only | `get path, websocket: true` or `SpecKemal.process_request` + `websocket_request_headers` | No | **101**, `Sec-WebSocket-Accept`, **400** / **426** on bad requests |
| Messages | `connect_websocket` | Yes | Echo, broadcast, auth via `Origin` / cookies |

Handshake-only requests go through `SpecKemal.process_request`, which does **not** call [HTTP::Server::Response#upgrade_handler](https://crystal-lang.org/api/latest/HTTP/Server/Response.html). That matches normal `get`/`post` helpers: the route is matched and the upgrade response is built, but no WebSocket I/O runs. Use `connect_websocket` whenever you need `socket.on_message`, pings, or closing behavior.

Assume an echo route (adjust the path to your app):

```crystal
ws "/chat" do |socket, _env|
  socket.on_message { |message| socket.send message }
end
```

#### Handshake-only (`get …, websocket: true`)

```crystal
get "/chat", websocket: true

response.status_code.should eq 101
response.headers["Upgrade"].should eq "websocket"
```

To assert `Sec-WebSocket-Accept` for a **known** key (RFC 6455 test vector), pass headers from `websocket_request_headers(sec_key:)` into `get` (`connect_websocket` also accepts `sec_key:` for the same purpose):

```crystal
key = "dGhlIHNhbXBsZSBub25jZQ=="
headers = websocket_request_headers(sec_key: key)
get "/chat", headers: headers, websocket: true

response.status_code.should eq 101
response.headers["Sec-WebSocket-Accept"].should eq HTTP::WebSocket::Protocol.key_challenge(key)
```

Invalid handshakes are ordinary HTTP responses — still in-memory (reuse the same `/chat` route):

```crystal
bad = websocket_request_headers
bad.delete "Sec-WebSocket-Key"
SpecKemal.process_request HTTP::Request.new("GET", "/chat", bad)
response.status_code.should eq 400

bad = websocket_request_headers
bad["Sec-WebSocket-Version"] = "7"
SpecKemal.process_request HTTP::Request.new("GET", "/chat", bad)
response.status_code.should eq 426
```

#### Full session (`connect_websocket`)

Runs the real upgrade on a loopback socket pair (UNIX socket pair on Unix-like systems, TCP on Windows), then yields a client [HTTP::WebSocket](https://crystal-lang.org/api/latest/HTTP/WebSocket.html). After the block returns, the client and server I/O are closed. The last `response` is the client’s **101 Switching Protocols** handshake.

Pattern: register `on_message`, **spawn** `client.run` so frames are processed, **yield** once so the fiber starts, then `send` / assert on a `Channel`:

```crystal
connect_websocket "/chat" do |client|
  replies = Channel(String).new(1)
  client.on_message { |message| replies.send message }
  spawn { client.run }
  Fiber.yield

  client.send "hello"
  replies.receive.should eq "hello"
end

response.status_code.should eq 101
```

Optional keyword arguments on `connect_websocket`:

- `headers` — merged after the default WebSocket upgrade headers (e.g. `Authorization`, extra cookies).
- `sec_key` — fixed `Sec-WebSocket-Key` for deterministic `Sec-WebSocket-Accept` checks.
- `origin` — sets `Origin` when your handler rejects unknown origins.

```crystal
connect_websocket "/chat", origin: "https://myapp.test" do |client|
  # ...
end
```

For the same handshake object **inside** the block (not only via `response` after), use `inner_connect_websocket` (advanced; see `src/spec-kemal/websocket.cr`).

When you `require "spec-kemal/session"`, cookies from `with_session` apply to both `get(..., websocket: true)` and `connect_websocket`, the same as for normal HTTP helpers.

### Response Object

After making a request, access the response using the `response` method:

```crystal
get "/users"

# Status
response.status_code          # => 200
response.status               # => HTTP::Status::OK
response.success?             # => true

# Body
response.body                 # => "{\"users\": []}"

# Headers
response.headers              # => HTTP::Headers
response.headers["Content-Type"]  # => "application/json"
response.content_type         # => "application/json"

# Cookies
response.cookies              # => HTTP::Cookies
response.cookies["session"]   # => HTTP::Cookie
```

### Headers

Pass custom headers to your requests:

```crystal
headers = HTTP::Headers{
  "Content-Type"  => "application/json",
  "Authorization" => "Bearer token123",
  "Accept"        => "application/json"
}

get "/protected", headers: headers
```

### Request Body

Send data in the request body:

```crystal
# JSON body
post "/api/users",
  headers: HTTP::Headers{"Content-Type" => "application/json"},
  body: {name: "John", email: "john@example.com"}.to_json

# Form-encoded body
post "/login",
  headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"},
  body: "username=john&password=secret"
```

## Testing Patterns

### JSON APIs

```crystal
describe "Users API" do
  it "returns users as JSON" do
    get "/api/users",
      headers: HTTP::Headers{"Accept" => "application/json"}

    response.status_code.should eq 200
    response.content_type.should eq "application/json"

    users = JSON.parse(response.body)
    users.as_a.size.should eq 3
  end

  it "creates a user" do
    payload = {
      name:  "Alice",
      email: "alice@example.com"
    }

    post "/api/users",
      headers: HTTP::Headers{"Content-Type" => "application/json"},
      body: payload.to_json

    response.status_code.should eq 201

    user = JSON.parse(response.body)
    user["name"].should eq "Alice"
  end

  it "handles validation errors" do
    post "/api/users",
      headers: HTTP::Headers{"Content-Type" => "application/json"},
      body: {name: ""}.to_json

    response.status_code.should eq 422
  end
end
```

### Form Data

```crystal
describe "Login" do
  it "authenticates with valid credentials" do
    post "/login",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"},
      body: "email=user@example.com&password=secret123"

    response.status_code.should eq 302
    response.headers["Location"].should eq "/dashboard"
  end
end
```

### Authentication

```crystal
describe "Protected Routes" do
  it "requires authentication" do
    get "/admin/dashboard"
    response.status_code.should eq 401
  end

  it "allows access with valid token" do
    headers = HTTP::Headers{
      "Authorization" => "Bearer valid-jwt-token"
    }

    get "/admin/dashboard", headers: headers
    response.status_code.should eq 200
  end
end
```

### Sessions

For testing session-based features, require the session module:

```crystal
require "spec-kemal/session"
```

**Important:** Configure your session secret before tests:

```crystal
Spec.before_each do
  Kemal::Session.config.secret = "your-test-secret"
end
```

Use `with_session` to create an authenticated session:

```crystal
describe "Dashboard" do
  it "shows user data from session" do
    with_session do |session|
      session.int("user_id", 42)
      session.string("username", "alice")

      get "/dashboard"
      response.body.should contain "Welcome, alice"
    end
  end

  it "handles session expiry" do
    with_session do |session|
      session.int("user_id", 42)
      # Session is automatically destroyed after the block
    end

    get "/dashboard"
    response.status_code.should eq 401
  end
end
```

**Available session methods:**

```crystal
session.string("key", "value")     # String
session.int("key", 42)             # Int32
session.bigint("key", 12345_i64)   # Int64
session.float("key", 3.14)         # Float64
session.bool("key", true)          # Bool
session.object("key", my_object)   # Any serializable object
```

## Configuration

### Disable Logging

Logging is disabled by default in spec-kemal. To enable it:

```crystal
Kemal.config.logging = true
```

### Error Handling

By default, Kemal rescues errors and renders an error page. For testing, you may want exceptions to propagate:

```crystal
Spec.before_each do
  Kemal.config.always_rescue = false
end
```

This is useful when testing error handling:

```crystal
it "raises on invalid input" do
  expect_raises(JSON::ParseException) do
    post "/api/data",
      headers: HTTP::Headers{"Content-Type" => "application/json"},
      body: "invalid json"
  end
end
```

### Test Environment

Always run tests with `KEMAL_ENV=test`:

```bash
KEMAL_ENV=test crystal spec
```

Or set it in your spec helper:

```crystal
ENV["KEMAL_ENV"] = "test"
```

## Troubleshooting

### "No response available" Error

Make sure you've made a request before accessing `response`:

```crystal
# Wrong
response.body  # Error: No response available. Make a request (get, post, ...) before calling `response`.

# Correct
get "/"
response.body  # Works!
```

### Tests Interfering with Each Other

Clear Kemal's configuration between tests:

```crystal
Spec.after_each do
  Kemal.config.clear
end
```

### Session Not Working

1. Ensure you've required the session module:
   ```crystal
   require "spec-kemal/session"
   ```

2. Set the session secret:
   ```crystal
   Kemal::Session.config.secret = "test-secret"
   ```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork it (<https://github.com/kemalcr/spec-kemal/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`crystal spec`)
5. Ensure code is formatted (`crystal tool format`)
6. Commit your changes (`git commit -am 'Add some feature'`)
7. Push to the branch (`git push origin my-new-feature`)
8. Create a new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributors

- [sdogruyol](https://github.com/sdogruyol) - Creator and maintainer
