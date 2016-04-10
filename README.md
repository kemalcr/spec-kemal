# spec-kemal

Kemal helpers to Crystal's `spec` for easy testing.

## Installation

Add it to your `shard.yml`.

```yaml
name: your-kemal-app
version: 0.1.0

dependencies:
  spec-kemal:
    github: sdogruyol/spec-kemal
    branch: master
  kemal:
    github: sdogruyol/kemal
    branch: master
```

## Usage

Just require it before your files in your `spec/spec_helper.cr`

```crystal
require "spec-kemal"
require "../src/your-kemal-app"
```

Your Kemal application

```crystal
# src/your-kemal-app.cr

require "kemal"

get "/" do
  "Hello World!"
end

Kemal.run
```

Now you can easily test your `Kemal` application in your `spec`s.

```crystal
# spec/your-kemal-app-spec.cr

describe "Your::Kemal::App" do
  # Be sure to start your app in test mode
  start

  it "renders #index" do
    response = HTTP::Client.get "http://localhost:3000/"
    response.body.should eq "Hello World!"
  end

  # Be sure to stop your app after the specs
  stop
end
```

## Contributing

1. Fork it ( https://github.com/sdogruyol/spec-kemal/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [sdogruyol](https://github.com/sdogruyol) Sdogruyol - creator, maintainer
