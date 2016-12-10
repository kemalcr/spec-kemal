# spec-kemal

Kemal helpers to Crystal's `spec` for easy testing.

## Installation

Add it to your `shard.yml`.

```yaml
name: your-kemal-app
version: 0.1.0

dependencies:
  spec-kemal:
    github: kemalcr/spec-kemal
    branch: master
  kemal:
    github: kemalcr/kemal
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

```
KEMAL_ENV=test crystal spec
```

```crystal
# spec/your-kemal-app-spec.cr

describe "Your::Kemal::App" do

  # You can use get,post,put,patch,delete to call the corresponding route.
  it "renders /" do
    get "/"
    response.body.should eq "Hello World!"
  end

end
```

## Contributing

1. Fork it ( https://github.com/kemalcr/spec-kemal/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [sdogruyol](https://github.com/sdogruyol) Sdogruyol - creator, maintainer
