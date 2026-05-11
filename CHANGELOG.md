# Changelog

## Unreleased

## [v0.4.0]

This release contains performance improvements, breaking changes in public API, and upgrades the
library to Zig 0.16.

## Changed
- Use `Sqids.init` to create a new Sqids encoder/decoder instance.
  There is no need for an allocator anymore.
  User is responsible for managing the blocklist.
  There is no need to deinit instances.
- `Sqids.encode` and `Sqids.decode` now both take an allocator. Caller owns the memory.

## Added
- `blocklist_from_words` is now a public function, intended for users to create minimal blocklists for their input alphabet.
- `Sqids.default` is a handy shortcut to a Sqids instance with default alphabet, default blocklist
  and no minimum length.

## Removed
- `Sqids.deinit`

[0.4.0]: https://github.com/sqids/sqids-zig/compare/v0.3.0...v0.4.0
