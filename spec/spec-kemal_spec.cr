require "./spec_helper"

describe "SpecKemalApp" do
  it "handles get" do
    get "/" do
      "Hello world"
    end
    get "/"
    response.body.should eq "Hello world"
  end

  it "handles post" do
    post "/user" do |env|
      env.params.json.to_json
    end
    json_body = {"name": "Serdar", "age": 27, "skills": ["crystal, kemal"]}
    post("/user", headers: HTTP::Headers{"Content-Type" => "application/json"}, body: json_body.to_json)
    response.body.should eq(json_body.to_json)
  end

  it "handles sessions" do
    get "/session_var" do |env|
      env.session.string?(env.params.query["key"]) || "not found"
    end

    with_session do |session|
      session.string("hey ho!", "let's go! 🎸")
      get "/session_var?key=hey+ho!"
      response.body.should eq("let's go! 🎸")
    end
  end
end
