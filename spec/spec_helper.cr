require "spec"
require "kemal"
require "../src/spec-kemal"

# Create a dummy app
get "/" do
  "Hello world"
end

post "/user" do |env|
  env.response.content_type = "application/json"
  name = env.params.json["name"]
  age = env.params.json["age"] as Int
  skills = env.params.json["skills"] as Array
  {"name": name, "age": age, "skills": skills}.to_json
end
