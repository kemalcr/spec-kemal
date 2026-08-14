# Unreleased

- Add `query` HTTP helper for testing HTTP QUERY ([RFC 10008](https://www.rfc-editor.org/rfc/rfc10008)) routes, matching Kemal's `query` route DSL ([kemal#769](https://github.com/kemalcr/kemal/pull/769)). Needs a Kemal version that ships QUERY support.

# 1.3.0 (04-05-2026)

- WebSocket testing support [#25](https://github.com/kemalcr/spec-kemal/pull/25), thanks @sdogruyol :pray:
- Set minimum Crystal version to 1.12.0 in `shard.yml`

# 1.2.0 (05-04-2026)

- Add `options` HTTP helper for CORS and preflight-style tests.
- Deduplicate `Global.response` assignment in request helpers.
- Strengthen specs: HEAD body assertion, session cleanup after `with_session`.
- CI: fail the build when Ameba reports issues (remove `continue-on-error`).

# 1.1.1 (23-02-2026)

- Fix `undefined method 'session?' for Global.class` when using spec-kemal without the session extension. Thanks @sdogruyol :pray:

# 1.1.0 (02-02-2026)

- Session testing support via `with_session` helper [#23](https://github.com/kemalcr/spec-kemal/pull/23) Thanks @hugopl :pray:
- Migrated from Travis CI to GitHub Actions
- Improved documentation with comprehensive examples
- Added inline documentation to source code

# (1.0.0) - 25-04-2021

- Support for all HTTP methods: GET, POST, PUT, PATCH, DELETE, HEAD
- Custom headers support for requests
- Request body support for POST/PUT/PATCH requests
- Updated for Kemal 1.x compatibility
- Improved handler chain building
