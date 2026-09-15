# 🧭 xcs

**A version-aware Xcode launcher and build tool selector.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-lightgrey)](https://developer.apple.com/macos/)

If you run more than one Xcode version side by side, `xed <path>` and
`open -a Xcode.app <path>` can't tell them apart — every Xcode.app shares the
same bundle identifier (`com.apple.dt.Xcode`), so Launch Services resolves to
whichever one it feels like, and asking for a specific installation fails
outright (`-10664`) once more than one version is running. `xcs` pins the
Xcode version per workspace/project in a small YAML file, resolves it from
the command line, and opens or builds with exactly that version — without
touching `xcode-select` or Launch Services at all.

## Table of Contents

- [Why not `xed`/`open -a`](#why-not-xedopen--a)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [`.xcodeversions.yml`](#xcodeversionsyml)
- [Commands](#commands)
- [Architecture](#architecture)
- [Development](#development)
- [License](#license)

## Why not `xed`/`open -a`

This was verified on-device, not assumed: with two Xcode versions installed
(e.g. `Xcode_27.app` and `Xcode_26.6.app`, both `com.apple.dt.Xcode`),
`open -a <path-to-specific-Xcode.app>` and `xed` both fail to select a
specific installation. `xed` always opens whatever `xcode-select -p` points
at; `open -a`/`open -na` fail with `-10664`, reproducibly, even from a clean
state with nothing running. Both go through Launch Services, which resolves
by bundle identifier — and every Xcode.app has the same one.

The only mechanism that reliably works is exec'ing the app bundle's binary
directly:

```sh
/Applications/Xcode_26.6.app/Contents/MacOS/Xcode /path/to/Foo.xcworkspace
```

This bypasses Launch Services entirely. Two different Xcode versions
launched this way coexist as separate running processes — confirmed with
both versions running concurrently on the same machine. `xcs open` does
exactly this, so you never need to remember it yourself.

## Installation

### Swift Package Manager (build from source)

```sh
git clone https://github.com/Ryu0118/xcs.git
cd xcs
swift build -c release
cp .build/release/xcs /usr/local/bin/xcs
```

## Quick Start

1. Add a `.xcodeversions.yml` next to your workspace/project (or anywhere in
   an ancestor directory):

   ```yaml
   targets:
     App.xcworkspace: "27.0"
     Modules/Tools.xcodeproj: "26.6"
   ```

2. Open it with the pinned version:

   ```sh
   xcs open App.xcworkspace
   # or, from a directory with exactly one workspace/project:
   xcs
   ```

3. Look up the resolved path for scripting:

   ```sh
   DEVELOPER_DIR=$(xcs path App.xcworkspace --developer-dir) xcodebuild -version
   # or, equivalently:
   xcs exec App.xcworkspace -- xcodebuild -version
   ```

## `.xcodeversions.yml`

```yaml
targets:
  App/a.xcworkspace: "27.0"          # path relative to the yml's directory
  b.xcworkspace: "26.6"              # suffix match — matches any b.xcworkspace found
  "Modules/**/*.xcodeproj": "26.3"   # glob, ** crosses directory boundaries
```

- **Discovery**: `xcs` walks up from the current directory looking for the
  nearest ancestor that has a `.xcodeversions.yml`, the same way tools like
  `git` find `.git`.
- **Key resolution order**: exact relative-path match, then suffix match,
  then glob match. Two keys matching at the *same* tier is an ambiguity
  error listing every match — `xcs` never silently guesses.
- **Version matching**: an exact version string wins outright; otherwise a
  dot-segment prefix match is tried (`"27"` matches `27.0`, `27.1`, ...),
  and more than one candidate at that stage is also an ambiguity error.
  `xcs` never picks the "closest" version silently.
- **No config, no problem**: with no `.xcodeversions.yml` in scope, `xcs`
  looks for `*.xcworkspace`/`*.xcodeproj` directly in the current directory
  instead.

## Commands

| Command | What it does |
| --- | --- |
| `xcs` | Shorthand for `xcs open` with no target. |
| `xcs open [<target>] [--xcode <version>] [--xcode-path <path>] [--json]` | Opens the resolved target with the resolved Xcode version. A single candidate opens immediately; multiple candidates prompt an interactive picker on a terminal, or fail fast with no prompt when not interactive (scripts, CI, piped input). |
| `xcs path [<target>] [--xcode <version>] [--xcode-path <path>] [--developer-dir] [--json]` | Prints the resolved `Xcode.app` path, or its `Contents/Developer` path with `--developer-dir`. |
| `xcs exec <target> -- <command...>` | Runs a command (typically `xcodebuild`) with `DEVELOPER_DIR` set to the resolved installation. |
| `xcs list [--json]` | Lists every discovered Xcode installation: path, version, and whether it's currently running. |
| `xcs doctor [--json]` | Diagnoses `.xcodeversions.yml` discovery and reports whether each entry resolves to an installed Xcode. |

`--xcode <version>` and `--xcode-path <path>` bypass `.xcodeversions.yml`
for a single run, without mutating the yml or `xcode-select`. `--xcode-path`
wins if both are given. Every command supports `--json` for scripting, and
never falls back to an interactive prompt when stdin/stdout isn't a
terminal — an ambiguous or unresolved target fails immediately with a
structured error instead of hanging.

## Architecture

```text
Sources/xcs/         thin executable — composition root only
Sources/XcsCLI/      ArgumentParser command tree, injected dependencies
Sources/XcsKit/      use cases: discovery, launching, exec, the picker
Sources/XcsConfig/   .xcodeversions.yml locator/decoder/loader/resolver
Sources/XcsCore/     value types only: XcodeInstallation, VersionSpec, ...
```

Dependency direction: `xcs → XcsCLI → XcsKit → XcsConfig → XcsCore`.
`XcsCore` has no I/O. `XcsConfig` only reads YAML. `XcsKit` owns process
launching, Spotlight lookups, and Info.plist reads, all behind protocols
(`XcodeDiscovery`, `XcodeLauncher`) so the CLI layer stays testable with
fakes — no test in this repo launches a real Xcode process or shells out to
`mdfind`.

Xcode discovery tries Spotlight (`mdfind`) first, since it finds
installations anywhere on disk, and falls back to scanning `/Applications`
directly if Spotlight is unavailable or returns nothing.

## Development

```sh
swift build          # build all targets
swift test            # run the test suite
```

## License

MIT — see [LICENSE](LICENSE).
