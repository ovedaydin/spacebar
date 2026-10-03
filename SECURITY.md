# Security

Spacebar deletes files and can hold Full Disk Access, so security reports are taken seriously.

## Reporting a vulnerability

Please **don't open a public issue**. Use GitHub's private reporting instead:
[Report a vulnerability](https://github.com/ovedaydin/spacebar/security/advisories/new).
You'll get a reply within a few days.

## How Spacebar protects you

- **Every deletion is checked twice.** Paths are validated by `PathRules` when an item is listed and again right
  before removal. Protected locations (Keychains, Mail, Messages, iCloud Drive, standard folders, security keys,
  the developer tools in use, Time Machine backups…) are refused.
- **Cached results are never acted on.** Results restored from the cache in `~/Library/Caches` are only shown
  until a fresh scan confirms them.
- **No confused-deputy tools.** Child processes inherit Spacebar's Full Disk Access, so external tools are run by
  absolute path with a clean environment. Tools outside the system's protected folders are only run after a
  code-signature check: `simctl` must be Apple's root-owned copy, `docker` must be signed by Docker, Inc.
- **No test hooks in releases.** Scripted test hooks are compiled only into local test builds.
- **Signed updates.** Sparkle verifies every update with an EdDSA signature before installing it.
- **Reproducible releases.** Releases are built by GitHub Actions from tagged source, with actions pinned to exact
  commits, and published with SHA-256 checksums.

## Known limitation

Builds signed with the project's self-signed certificate have no Apple Team ID, so they turn off library
validation to load Sparkle. Someone who can already run code as you could add a library to
`/Applications/Spacebar.app` and have it run with Spacebar's Full Disk Access. Developer ID builds won't need this.
