<p align="center"><img src="docs/icon.png" width="128" alt=""></p>

# Spacebar

**A free, open-source disk space analyzer and cleaner for Mac.** It shows what's using your disk and helps you safely remove caches, logs, build data, and leftovers.

- **Disk breakdown.** See what your disk is used for (macOS, Apps, Documents, Developer, App Data, Shared, System Data…), measured rather than estimated. Click a category to explore it.
- **Space Explorer.** Drill into any folder as a sorted list or a treemap. Subfolders are measured in the same pass, so opening them is instant.
- **Menu bar & alerts.** Available space in the menu bar, one-click cleaning of safe items, and a notification when the disk is almost full.
- **Trash that frees space.** After a clean, **Delete Now** permanently removes just what Spacebar moved to the Trash. Empty Trash is built in.
- **Remembers results.** The last scan is shown immediately at launch and refreshed in the background.
- **Cleanup.** Finds app caches, logs, Xcode data, package-manager caches, the Trash, old downloads, large files, iPhone backups, Mail attachments, and macOS installers.
- **Safe by design.** You review everything first. "Review" categories are never preselected. Most Apple caches are left alone, apps that are running are skipped, and every removal is logged.
- **Fast and accurate.** A parallel `getattrlistbulk` scanner that is about 4× faster than `du`, with matching totals (see [Benchmarks](#benchmarks)).
- **Private.** No network access, no telemetry, no accounts.

Requires macOS 13 Ventura or later, on Apple silicon or Intel.

## Install

### Homebrew (recommended)

```sh
brew install --cask ovedaydin/tap/spacebar
```

### Install script

```sh
curl -fsSL https://raw.githubusercontent.com/ovedaydin/spacebar/main/install.sh | bash
```

The script downloads the latest release, checks its SHA-256, and installs it into `/Applications`.

### Manual download

1. Download `Spacebar-x.y.z.dmg` from [Releases](https://github.com/ovedaydin/spacebar/releases) and drag Spacebar to Applications.
2. Spacebar isn't notarized by Apple yet, so the first launch is blocked:
   1. Open Spacebar. When macOS says it can't verify the app, click **Done**.
   2. Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to Spacebar.
   3. Confirm with your password.

   You only need to do this once. To skip it, run `xattr -dr com.apple.quarantine /Applications/Spacebar.app`.

## Permissions

Spacebar works without special permissions, but some locations are hidden from apps by macOS. To include them, grant **Full Disk Access**:

1. Open **System Settings → Privacy & Security → Full Disk Access**.
2. Turn on Spacebar.
3. Quit and reopen Spacebar.

With Full Disk Access, Spacebar can also clean:

- the Trash
- Mail attachments
- iPhone backups
- caches of sandboxed apps

The **Old Downloads** and **Large Files** scans only run when you ask, because reading Desktop, Documents, and Downloads makes macOS show privacy prompts.

## What gets cleaned

| Category | Default | How it's removed |
|---|---|---|
| App caches (`~/Library/Caches`, container caches) | Suggested if unused for 30+ days | Deleted |
| Logs & crash reports | Selected | Deleted |
| Xcode: DerivedData, Products, simulator caches, old DeviceSupport (keeps the newest 2) | Suggested if unused for 30+ days | Deleted |
| Developer caches: npm, Yarn, Bun, Cargo, Gradle, SwiftPM, uv, … | Suggested if unused for 30+ days | Deleted |
| Trash | Selected | Deleted |
| Xcode Archives, iPhone backups, Mail attachments, macOS installers | Review | Moved to Trash |
| Large Files (over 500 MB) | Review, on demand | Moved to Trash |

**Why the age rule:** a cache an app wrote to recently will just be rebuilt, so deleting it frees space only briefly.

- "Last used" is the newest modification date of anything inside the folder. Access times aren't reliable on APFS, so they aren't used.
- You can change the threshold on the category page: 1 week, 1 month, 3 months, or 6 months.
- Caches with no matching installed app are suggested after 7 days.
- Caches of apps that are running are never suggested.

### Find Space

| Category | What it finds | Suggested | Removal |
|---|---|---|---|
| Forgotten Files | Items in Downloads (30+ days) and on the Desktop (90+ days) not opened or changed since, using Spotlight's open records | Installers for apps you already have, archives already unzipped, and installers/archives with no open recorded in 6 months. Never photos, videos, music, documents, or Desktop items | Trash |
| Unused Apps | Your apps, least recently used first. Uses Spotlight's last-used date plus traces apps leave when they run | Never | Trash (asks for a password if needed) |
| Old Simulators | Simulator devices whose runtime is gone, and devices or runtimes unused for 90+ days | Unusable devices | `xcrun simctl delete` |
| App Leftovers | Data of apps that are no longer installed (Application Support, containers, web data) | Bundle-ID matches that are web data or unchanged for 90+ days; name-only matches are left for review | Trash |
| Mail | Opened attachments, plus cached attachments of server-synced accounts (IMAP, Exchange, Gmail, iCloud). Never mailboxes, POP or "On My Mac" | Never | Trash |
| Duplicate Files | Identical files over 1 MB, matched by size, then partial and full SHA-256 hashes. APFS clones, hard links, iCloud-only files, build output and files inside git repos are excluded | Never | Trash |
| Project Build Files | `node_modules`, `target`, `build`, `Pods`, `.venv`, … next to their project file | Projects untouched for 90+ days | Deleted (rebuildable) |

Developer tools you're using (`xcode-select`) are never removed. SSH keys, certificates, and shell configuration files are locked in Space Explorer.

**Never touched:**

- Keychains, Mail, Messages, iCloud Drive, Group Containers, Preferences, and whole app containers.
- Model weights (Ollama, LM Studio, Hugging Face) and dependency stores like `~/.m2`.
- Most `com.apple.*` caches. Some hold state, and removing them causes problems such as blank System Settings panes or iCloud re-syncs.

The rules are in [`PathRules.swift`](Sources/SpacebarCore/PathRules.swift), and every path is checked again right before it is removed.

**Scan cache.** Results are stored in `~/Library/Caches/<bundle id>/` (`catalog.json`, `explorer.json`). Cached sizes are shown first and always measured again, because a folder's size can change deep inside it without its own date changing.

**Dry Run** (eye icon in the toolbar) simulates a cleanup and only writes what it would remove to `~/Library/Logs/Spacebar/operations.log`.

## Benchmarks

`spacebar-bench` is a read-only command-line tool that can't delete files. It compares Spacebar's scanner with `FileManager` and `du`:

```sh
swift run -c release spacebar-bench                       # ~/Library/Caches and ~/Library/Developer
swift run -c release spacebar-bench --path ~ --runs 3     # any folder
swift run -c release spacebar-bench --catalog             # time the cleanup scan the app runs
swift run -c release spacebar-bench --tree 2              # one-pass subfolder sizes, checked against separate scans
```

Results on an 8-core Apple silicon Mac running macOS 15.7 (warm cache, median of 3 runs):

| Folder | Files | `getattrlistbulk` | FileManager | `du -skx` | Size difference vs `du` |
|---|---|---|---|---|---|
| `~/Library/Caches` (20 GB) | 334k | **2.1 s** | 9.3 s | 8.5 s | 0.00% |
| `~/Library/Developer` (39 GB) | 694k | **4.9 s** | 20.2 s | 14.0 s | 0.00% |

How the scanner works:

- One `getattrlistbulk(2)` call returns metadata for many entries at once.
- Worker threads share a flat work queue.
- It counts allocated size, so sparse and compressed files are measured correctly.
- Hard links are counted once.
- It never follows symlinks, crosses into other volumes, or descends into firmlinks.
- It sets `IOPOL_MATERIALIZE_DATALESS_FILES_OFF`, so scanning never downloads iCloud-only files.
- **APFS clones count once.** For files that may share blocks, it reads their private size and clone ID, so a Finder duplicate isn't counted twice. Edited clones are counted conservatively, because APFS doesn't expose which file they still share blocks with.

## Build from source

```sh
git clone https://github.com/ovedaydin/spacebar && cd spacebar
swift run Spacebar                # run the app directly
ARCHS=arm64 ./scripts/build-app.sh  # build dist/Spacebar.app (drop ARCHS for a universal build)
./scripts/install-local.sh          # build and install to /Applications (replaces the running copy)
./scripts/package.sh                # create dist/Spacebar-x.y.z.{zip,dmg} and SHA256SUMS.txt
```

The project uses Swift Package Manager with no Xcode project:

- `SpacebarCore`: a read-only library for scanning and the cleanup catalog.
- `Spacebar`: the SwiftUI app. It is the only part that can delete files.
- `spacebar-bench`: the benchmark tool.

## Releasing (maintainers)

1. **One-time: create a signing certificate.** Run `./scripts/create-signing-cert.sh` and add the three secrets it prints to the repository.
   - A stable self-signed certificate keeps users' Full Disk Access across updates. With ad-hoc signing, users have to grant it again after every update.
   - Back up the `signing/` folder. It holds the code-signing certificate and the Sparkle update key; losing the update key means existing installs can't verify future updates.
2. **Optional: set up a Homebrew tap.**
   1. Create a repository named `ovedaydin/homebrew-tap`.
   2. Copy [`packaging/homebrew/spacebar.rb`](packaging/homebrew/spacebar.rb) into it as `Casks/spacebar.rb`.
   3. Add a `TAP_TOKEN` secret: a fine-grained token with Contents read/write access to the tap repository.
3. **Auto-updates (Sparkle).** `signing/sparkle_private_key` was created with Sparkle's `generate_keys`. Add its contents as the secret `SPARKLE_PRIVATE_KEY`. Each release then publishes a signed `appcast.xml`, and the app checks `…/releases/latest/download/appcast.xml` daily. The public key is in `packaging/app.env`.
4. **Publish a release:** `git tag v0.1.0 && git push --tags`.
   - GitHub Actions builds a universal app, signs it, creates the ZIP, DMG, and checksums, publishes the release, and updates the tap.

**With an Apple Developer account:**

- Set `SIGN_IDENTITY` to your "Developer ID Application" certificate.
- Set the repository variable `NOTARIZE=true` and add the secrets `ASC_KEY_P8`, `ASC_KEY_ID`, and `ASC_ISSUER_ID`.
- Releases are then notarized, so there's no Gatekeeper prompt. Remove the `postflight_steps` block from the cask.
- Developer ID builds use `packaging/Spacebar.entitlements`, which keeps library validation on. Self-signed builds need `Spacebar.selfsigned.entitlements` to load Sparkle, because they have no Team ID.

## License

MIT
