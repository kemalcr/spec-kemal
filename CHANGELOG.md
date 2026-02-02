# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Migrated from Travis CI to GitHub Actions
- Improved documentation with comprehensive examples
- Added inline documentation to source code

## [1.0.0] - 2023-XX-XX

### Added
- Session testing support via `with_session` helper
- Support for all HTTP methods: GET, POST, PUT, PATCH, DELETE, HEAD
- Custom headers support for requests
- Request body support for POST/PUT/PATCH requests

### Changed
- Updated for Kemal 1.x compatibility
- Improved handler chain building

## [0.5.0] - Previous Release

### Added
- Initial session support
- Basic HTTP method helpers

## [0.1.0] - Initial Release

### Added
- Basic testing helpers for Kemal
- GET, POST support
- Response assertions

[Unreleased]: https://github.com/kemalcr/spec-kemal/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/kemalcr/spec-kemal/compare/v0.5.0...v1.0.0
[0.5.0]: https://github.com/kemalcr/spec-kemal/compare/v0.1.0...v0.5.0
[0.1.0]: https://github.com/kemalcr/spec-kemal/releases/tag/v0.1.0
