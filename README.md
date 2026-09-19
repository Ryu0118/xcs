# ⚒️ xcs

**A version-aware Xcode launcher and build tool selector.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-lightgrey)](https://developer.apple.com/macos/)

xcs pins an Xcode version to each workspace/project in a YAML file, then
opens or builds with exactly that version — reliably, even with multiple
Xcode installations that `xed`/`open -a` can't tell apart.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [`.xcodeversions.yml`](#xcodeversionsyml)
- [Commands](#commands)
- [License](#license)

## Installation

### Nest ([mtj0928/nest](https://github.com/mtj0928/nest))

```sh
nest install Ryu0118/xcs
```

### Mise ([jdx/mise](https://github.com/jdx/mise))

```sh
mise use -g github:Ryu0118/xcs
```

### Build from source

Requires **macOS 26+** and **Swift 6.2**.

```sh
git clone https://github.com/Ryu0118/xcs.git
cd xcs
swift build -c release
cp .build/release/xcs /usr/local/bin/xcs
```

## Quick Start

```yaml
# .xcodeversions.yml
targets:
  App.xcworkspace: "27.0"
  Modules/Tools.xcodeproj: "26.6"
```

```sh
xcs open App.xcworkspace
# or, from a directory with exactly one workspace/project:
xcs

xcs exec App.xcworkspace -- xcodebuild -version
```

## `.xcodeversions.yml`

```yaml
targets:
  App/a.xcworkspace: "27.0"          # path relative to the yml's directory
  b.xcworkspace: "26.6"              # suffix match
  "Modules/**/*.xcodeproj": "26.3"   # glob
```

- xcs walks up from the current directory to the nearest ancestor holding
  `.xcodeversions.yml`.
- Key resolution order: exact relative-path match, then suffix match, then
  glob match. Two matches at the same tier is an ambiguity error.
- Version matching: exact string match first, then a dot-segment prefix
  match (`"27"` matches `27.0`, `27.1`, ...). Never guesses.
- With no config in scope, xcs looks for `*.xcworkspace`/`*.xcodeproj`
  directly in the current directory instead.

## Commands

| Command | Purpose |
| --- | --- |
| `xcs [<target>]` | Shorthand for `xcs open`. |
| `xcs open [<target>] [--xcode <version>] [--xcode-path <path>] [--json]` | Opens the resolved target with the resolved Xcode version. Multiple candidates prompt an interactive picker on a terminal, or fail fast with no prompt otherwise. |
| `xcs path [<target>] [--xcode <version>] [--xcode-path <path>] [--developer-dir] [--json]` | Prints the resolved `Xcode.app` path, or its `Contents/Developer` path with `--developer-dir`. |
| `xcs exec <target> -- <command...>` | Runs a command with `DEVELOPER_DIR` set to the resolved installation. |
| `xcs list [--json]` | Lists every discovered Xcode installation and whether it's running. |
| `xcs doctor [--json]` | Diagnoses `.xcodeversions.yml` discovery and entry resolvability. |

`--xcode`/`--xcode-path` bypass `.xcodeversions.yml` for a single run without
mutating it or `xcode-select`. Every command supports `--json` and never
falls back to an interactive prompt when stdin/stdout isn't a terminal.

## License

xcs is available under the MIT License. See [LICENSE](LICENSE) for details.
