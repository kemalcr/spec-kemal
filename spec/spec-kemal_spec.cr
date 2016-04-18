require "./spec_helper"

describe "SpecKemalApp" do
  start

  it "handles get" do
    get "/"
    response.body.should eq "Hello world"
  end

  it "handles post" do
    json_body = {"name": "Serdar", "age": 27, "skills": ["crystal, kemal"]}
    post("/user", headers: HTTP::Headers{"Content-Type": "application/json"}, body: json_body.to_json)
    response.body.should eq(json_body.to_json)
  end
end
