# Contributing to spec-kemal

First off, thank you for considering contributing to spec-kemal! It's people like you that make spec-kemal such a great tool.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Style Guidelines](#style-guidelines)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

## Code of Conduct

This project and everyone participating in it is governed by our commitment to providing a welcoming and inclusive environment. Please be respectful and constructive in all interactions.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/spec-kemal.git
   cd spec-kemal
   ```
3. **Add the upstream remote**:
   ```bash
   git remote add upstream https://github.com/kemalcr/spec-kemal.git
   ```

## Development Setup

### Prerequisites

- [Crystal](https://crystal-lang.org/install/) (1.10 or later recommended)
- Git

### Installing Dependencies

```bash
shards install
```

### Running Tests

```bash
crystal spec
```

Or with verbose output:

```bash
crystal spec --verbose
```

## Making Changes

1. **Create a feature branch** from `master`:
   ```bash
   git checkout -b my-feature-branch
   ```

2. **Make your changes** with clear, descriptive commits

3. **Write or update tests** for your changes

4. **Ensure all tests pass**:
   ```bash
   crystal spec
   ```

5. **Format your code**:
   ```bash
   crystal tool format
   ```

6. **Check for issues** (optional but recommended):
   ```bash
   # If you have ameba installed
   ameba
   ```

## Testing

### Running the Test Suite

```bash
# Run all tests
crystal spec

# Run specific test file
crystal spec spec/spec-kemal_spec.cr

# Run with random order
crystal spec --order=random
```

### Writing Tests

- Place tests in the `spec/` directory
- Name test files with `_spec.cr` suffix
- Use descriptive test names that explain what is being tested

Example:

```crystal
describe "HTTP Methods" do
  describe "#get" do
    it "sends a GET request to the specified path" do
      get "/" do
        "Hello"
      end

      get "/"
      response.body.should eq "Hello"
    end

    it "includes custom headers in the request" do
      # test implementation
    end
  end
end
```

## Submitting Changes

1. **Push your branch** to your fork:
   ```bash
   git push origin my-feature-branch
   ```

2. **Create a Pull Request** from your branch to `kemalcr/spec-kemal:master`

3. **Fill out the PR template** with:
   - A clear description of the changes
   - Any related issues (use "Fixes #123" to auto-close)
   - Screenshots if applicable (for documentation changes)

4. **Wait for review** - maintainers will review your PR and may request changes

### PR Guidelines

- Keep PRs focused on a single feature or fix
- Include tests for new functionality
- Update documentation if needed
- Ensure CI passes before requesting review

## Style Guidelines

### Code Style

- Follow Crystal's standard formatting (use `crystal tool format`)
- Use meaningful variable and method names
- Keep methods small and focused
- Add documentation comments for public methods

### Documentation Style

```crystal
# Brief description of what the method does.
#
# More detailed explanation if needed, including any
# important notes or caveats.
#
# ## Parameters
#
# - `param1` : Description of param1
# - `param2` : Description of param2
#
# ## Example
#
# ```crystal
# result = my_method("value")
# result.should eq expected
# ```
#
# Returns description of return value.
def my_method(param1 : String, param2 : Int32? = nil) : ReturnType
  # implementation
end
```

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Keep the first line under 72 characters
- Reference issues when relevant

Good examples:
```
Add support for custom request timeout

Fix session cookie not being set correctly

Update README with session testing examples

Fixes #42
```

## Reporting Bugs

### Before Submitting

1. **Search existing issues** to avoid duplicates
2. **Try the latest version** to see if the bug has been fixed
3. **Gather information** about your environment

### Bug Report Template

```markdown
## Description
A clear description of the bug.

## Steps to Reproduce
1. Step one
2. Step two
3. ...

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- Crystal version: [e.g., 1.10.0]
- Kemal version: [e.g., 1.1.0]
- spec-kemal version: [e.g., 1.0.0]
- OS: [e.g., Ubuntu 22.04]

## Additional Context
Any other relevant information.
```

## Suggesting Features

We welcome feature suggestions! Please:

1. **Check existing issues** for similar suggestions
2. **Create a new issue** with the "feature request" label
3. **Describe the feature** and its use case
4. **Provide examples** of how it would be used

### Feature Request Template

```markdown
## Feature Description
A clear description of the feature.

## Use Case
Why this feature would be useful.

## Proposed API
```crystal
# How you envision using this feature
```

## Alternatives Considered
Other approaches you've thought about.
```

## Questions?

If you have questions about contributing, feel free to:

- Open an issue with the "question" label
- Reach out to maintainers

Thank you for contributing to spec-kemal! 🎉
