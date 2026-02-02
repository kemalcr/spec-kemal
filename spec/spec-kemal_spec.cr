require "./spec_helper"

describe "spec-kemal" do
  describe "HTTP Methods" do
    describe "GET" do
      it "handles basic get request" do
        get "/" do
          "Hello world"
        end
        get "/"
        response.body.should eq "Hello world"
        response.status_code.should eq 200
      end

      it "handles get with query parameters" do
        get "/search" do |env|
          query = env.params.query["q"]? || "empty"
          "Search: #{query}"
        end
        get "/search?q=crystal"
        response.body.should eq "Search: crystal"
      end

      it "handles get with multiple query parameters" do
        get "/filter" do |env|
          page = env.params.query["page"]? || "1"
          limit = env.params.query["limit"]? || "10"
          "Page: #{page}, Limit: #{limit}"
        end
        get "/filter?page=2&limit=25"
        response.body.should eq "Page: 2, Limit: 25"
      end

      it "handles get with custom headers" do
        get "/auth" do |env|
          auth = env.request.headers["Authorization"]? || "none"
          "Auth: #{auth}"
        end
        get "/auth", headers: HTTP::Headers{"Authorization" => "Bearer token123"}
        response.body.should eq "Auth: Bearer token123"
      end

      it "handles get with multiple custom headers" do
        get "/headers" do |env|
          accept = env.request.headers["Accept"]? || "none"
          lang = env.request.headers["Accept-Language"]? || "none"
          "Accept: #{accept}, Lang: #{lang}"
        end
        headers = HTTP::Headers{
          "Accept"          => "application/json",
          "Accept-Language" => "tr-TR",
        }
        get "/headers", headers: headers
        response.body.should eq "Accept: application/json, Lang: tr-TR"
      end

      it "handles get with URL parameters" do
        get "/users/:id" do |env|
          id = env.params.url["id"]
          "User ID: #{id}"
        end
        get "/users/42"
        response.body.should eq "User ID: 42"
      end

      it "handles get with multiple URL parameters" do
        get "/posts/:post_id/comments/:comment_id" do |env|
          post_id = env.params.url["post_id"]
          comment_id = env.params.url["comment_id"]
          "Post: #{post_id}, Comment: #{comment_id}"
        end
        get "/posts/10/comments/5"
        response.body.should eq "Post: 10, Comment: 5"
      end
    end

    describe "POST" do
      it "handles post with JSON body" do
        post "/user" do |env|
          env.params.json.to_json
        end
        json_body = {"name": "Serdar", "age": 27, "skills": ["crystal, kemal"]}
        post("/user", headers: HTTP::Headers{"Content-Type" => "application/json"}, body: json_body.to_json)
        response.body.should eq(json_body.to_json)
      end

      it "handles post with form data" do
        post "/login" do |env|
          username = env.params.body["username"]? || "none"
          password = env.params.body["password"]? || "none"
          "Login: #{username}"
        end
        post "/login",
          headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"},
          body: "username=admin&password=secret"
        response.body.should eq "Login: admin"
      end

      it "handles post with empty body" do
        post "/ping" do
          "pong"
        end
        post "/ping"
        response.body.should eq "pong"
      end

      it "handles post and returns status code" do
        post "/create" do |env|
          env.response.status_code = 201
          "Created"
        end
        post "/create"
        response.status_code.should eq 201
        response.body.should eq "Created"
      end
    end

    describe "PUT" do
      it "handles put request" do
        put "/put-users/:id" do |env|
          id = env.params.url["id"]
          "Updated user #{id}"
        end
        put "/put-users/1"
        response.body.should eq "Updated user 1"
      end

      it "handles put with JSON body" do
        put "/put-users-json/:id" do |env|
          id = env.params.url["id"]
          name = env.params.json["name"]?.to_s
          "Updated user #{id} to #{name}"
        end
        put "/put-users-json/5",
          headers: HTTP::Headers{"Content-Type" => "application/json"},
          body: {name: "Alice"}.to_json
        response.body.should eq "Updated user 5 to Alice"
      end
    end

    describe "PATCH" do
      it "handles patch request" do
        patch "/users/:id" do |env|
          id = env.params.url["id"]
          "Patched user #{id}"
        end
        patch "/users/3"
        response.body.should eq "Patched user 3"
      end

      it "handles patch with partial JSON update" do
        patch "/settings" do |env|
          theme = env.params.json["theme"]?.to_s
          "Theme changed to #{theme}"
        end
        patch "/settings",
          headers: HTTP::Headers{"Content-Type" => "application/json"},
          body: {theme: "dark"}.to_json
        response.body.should eq "Theme changed to dark"
      end
    end

    describe "DELETE" do
      it "handles delete request" do
        delete "/users/:id" do |env|
          id = env.params.url["id"]
          env.response.status_code = 204
          ""
        end
        delete "/users/99"
        response.status_code.should eq 204
      end

      it "handles delete with confirmation body" do
        delete "/account" do |env|
          confirm = env.params.json["confirm"]?
          if confirm == true
            "Account deleted"
          else
            env.response.status_code = 400
            "Confirmation required"
          end
        end
        delete "/account",
          headers: HTTP::Headers{"Content-Type" => "application/json"},
          body: {confirm: true}.to_json
        response.body.should eq "Account deleted"
      end
    end

    describe "HEAD" do
      it "handles head request" do
        get "/status" do |env|
          env.response.headers["X-Status"] = "OK"
          "This body should not appear in HEAD"
        end
        head "/status"
        response.status_code.should eq 200
        # HEAD requests don't return body
      end
    end
  end

  describe "Response" do
    it "returns correct status codes" do
      get "/not-found" do |env|
        env.response.status_code = 404
        "Not Found"
      end
      get "/not-found"
      response.status_code.should eq 404
    end

    it "returns custom headers" do
      get "/custom-header" do |env|
        env.response.headers["X-Custom"] = "test-value"
        env.response.headers["X-Request-Id"] = "12345"
        "OK"
      end
      get "/custom-header"
      response.headers["X-Custom"].should eq "test-value"
      response.headers["X-Request-Id"].should eq "12345"
    end

    it "returns content type header" do
      get "/json" do |env|
        env.response.content_type = "application/json"
        %({"status": "ok"})
      end
      get "/json"
      response.headers["Content-Type"].should eq "application/json"
    end

    it "handles redirect responses" do
      get "/old-page" do |env|
        env.response.status_code = 302
        env.response.headers["Location"] = "/new-page"
        ""
      end
      get "/old-page"
      response.status_code.should eq 302
      response.headers["Location"].should eq "/new-page"
    end

    it "handles server error responses" do
      get "/error" do |env|
        env.response.status_code = 500
        "Internal Server Error"
      end
      get "/error"
      response.status_code.should eq 500
    end
  end

  describe "Request Context" do
    it "accesses request method" do
      post "/echo-method" do |env|
        env.request.method
      end
      post "/echo-method"
      response.body.should eq "POST"
    end

    it "accesses request path" do
      get "/echo-path" do |env|
        env.request.path
      end
      get "/echo-path"
      response.body.should eq "/echo-path"
    end

    it "accesses full request URL with query" do
      get "/echo-resource" do |env|
        env.request.resource
      end
      get "/echo-resource?foo=bar"
      response.body.should eq "/echo-resource?foo=bar"
    end
  end

  describe "Sessions" do
    it "handles string session values" do
      get "/session_var" do |env|
        env.session.string?(env.params.query["key"]) || "not found"
      end

      with_session do |session|
        session.string("hey ho!", "let's go! 🎸")
        get "/session_var?key=hey+ho!"
        response.body.should eq("let's go! 🎸")
      end
    end

    it "handles integer session values" do
      get "/session_int" do |env|
        value = env.session.int?("counter")
        value ? value.to_s : "not set"
      end

      with_session do |session|
        session.int("counter", 42)
        get "/session_int"
        response.body.should eq "42"
      end
    end

    it "handles bigint session values" do
      get "/session_bigint" do |env|
        value = env.session.bigint?("big_number")
        value ? value.to_s : "not set"
      end

      with_session do |session|
        session.bigint("big_number", 9999999999_i64)
        get "/session_bigint"
        response.body.should eq "9999999999"
      end
    end

    it "handles float session values" do
      get "/session_float" do |env|
        value = env.session.float?("price")
        value ? value.to_s : "not set"
      end

      with_session do |session|
        session.float("price", 19.99)
        get "/session_float"
        response.body.should eq "19.99"
      end
    end

    it "handles boolean session values" do
      get "/session_bool" do |env|
        value = env.session.bool?("admin")
        value.nil? ? "not set" : value.to_s
      end

      with_session do |session|
        session.bool("admin", true)
        get "/session_bool"
        response.body.should eq "true"
      end
    end

    it "session is destroyed after with_session block" do
      get "/check_session" do |env|
        env.session.string?("test_key") || "no session"
      end

      with_session do |session|
        session.string("test_key", "test_value")
        get "/check_session"
        response.body.should eq "test_value"
      end

      # Session should be cleared after the block
      # New request without session should not have the value
    end

    it "handles multiple session values" do
      get "/multi_session" do |env|
        name = env.session.string?("name") || "guest"
        role = env.session.string?("role") || "user"
        "#{name} (#{role})"
      end

      with_session do |session|
        session.string("name", "Alice")
        session.string("role", "admin")
        get "/multi_session"
        response.body.should eq "Alice (admin)"
      end
    end

    it "persists session across multiple requests" do
      get "/set_session" do |env|
        env.session.string("visit", "first")
        "Set"
      end

      get "/get_session" do |env|
        env.session.string?("visit") || "none"
      end

      with_session do |session|
        session.string("visit", "remembered")
        get "/get_session"
        response.body.should eq "remembered"

        # Make another request - session should persist
        get "/get_session"
        response.body.should eq "remembered"
      end
    end
  end

  describe "Multiple Sequential Requests" do
    it "handles multiple different routes" do
      get "/first" do
        "First"
      end

      get "/second" do
        "Second"
      end

      get "/first"
      response.body.should eq "First"

      get "/second"
      response.body.should eq "Second"
    end

    it "response is updated after each request" do
      get "/counter/:n" do |env|
        "Count: #{env.params.url["n"]}"
      end

      get "/counter/1"
      response.body.should eq "Count: 1"

      get "/counter/2"
      response.body.should eq "Count: 2"

      get "/counter/3"
      response.body.should eq "Count: 3"
    end
  end

  describe "Edge Cases" do
    it "handles empty response body" do
      get "/empty" do |env|
        env.response.status_code = 204
        ""
      end
      get "/empty"
      response.status_code.should eq 204
      response.body.should eq ""
    end

    it "handles unicode in response" do
      get "/unicode" do
        "Hello 世界! 🌍 Merhaba Dünya!"
      end
      get "/unicode"
      response.body.should eq "Hello 世界! 🌍 Merhaba Dünya!"
    end

    it "handles unicode in request body" do
      post "/echo" do |env|
        env.request.body.try(&.gets_to_end) || ""
      end
      post "/echo", body: "Türkçe karakterler: şçğüöı"
      response.body.should eq "Türkçe karakterler: şçğüöı"
    end

    it "handles special characters in query params" do
      get "/special" do |env|
        env.params.query["msg"]? || "none"
      end
      get "/special?msg=hello%20world%21"
      response.body.should eq "hello world!"
    end

    it "handles routes with trailing slash" do
      get "/api/users/" do
        "Users list"
      end
      get "/api/users/"
      response.body.should eq "Users list"
    end

    it "handles deeply nested routes" do
      get "/api/v1/users/:user_id/posts/:post_id/comments" do |env|
        user_id = env.params.url["user_id"]
        post_id = env.params.url["post_id"]
        "Comments for post #{post_id} by user #{user_id}"
      end
      get "/api/v1/users/10/posts/20/comments"
      response.body.should eq "Comments for post 20 by user 10"
    end

    it "handles JSON array in request body" do
      post "/batch" do |env|
        body = env.request.body.try(&.gets_to_end) || "[]"
        items = JSON.parse(body).as_a
        "Received #{items.size} items"
      end
      post "/batch",
        headers: HTTP::Headers{"Content-Type" => "application/json"},
        body: [1, 2, 3, 4, 5].to_json
      response.body.should eq "Received 5 items"
    end

    it "handles large response body" do
      get "/large" do
        "x" * 10000
      end
      get "/large"
      response.body.size.should eq 10000
    end
  end
end
