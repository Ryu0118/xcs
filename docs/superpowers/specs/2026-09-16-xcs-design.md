# xcs — Xcode version switcher CLI

Status: approved for planning
Date: 2026-09-16

## Problem

The user runs multiple Xcode versions in parallel (e.g. Xcode 27.0 and
26.6 installed side by side) and wants to pin the required Xcode version
per workspace/project in a config file, then:

1. Open a given workspace/project with the pinned Xcode version from the
   command line (a version-aware replacement for `xed`).
2. Look up the resolved Xcode.app path (or its `Contents/Developer`
   path) from the command line, e.g. for `DEVELOPER_DIR` injection.
3. Override the pinned version for a one-off open, without touching the
   config file.
4. Run `xcs` with no arguments inside a project directory and have it
   "just open the right thing" — a single unambiguous target opens
   immediately; multiple candidates prompt an interactive picker.

## Key empirical finding (drives the whole design)

Verified on the user's machine with two installed Xcode versions
(`Xcode_27.app`, `Xcode_26.6.app`, both `CFBundleIdentifier
com.apple.dt.Xcode`):

- `open -a <path>`, plain `open <path>`, and `open -na <path>` **all fail
  with `-10664`**, reproducibly, including from a clean state with no
  Xcode running at all. Launch Services resolves by bundle ID, and two
  installs sharing one bundle ID collide — `-n` does not help.
- `xed` opens whatever `xcode-select -p` currently points at; setting
  `DEVELOPER_DIR` before calling `xed` did **not** change which Xcode it
  launched (confirmed empirically, not just from docs) — `xed` also goes
  through Launch Services under the hood.
- **Directly exec'ing `<Xcode.app>/Contents/MacOS/Xcode <file-path>`
  bypasses Launch Services entirely and works.** Confirmed: launches the
  correct version, opens the given file, and — critically — **two
  different Xcode.app versions launched this way coexist as separate
  running processes** (verified with both 26.6 and 27 running
  concurrently, each with its own PID).
- `xcode-select -p` is never touched by any of the above; it's safe to
  leave alone.

Consequence: `xcs` must launch Xcode by exec'ing the app bundle's binary
directly. `xed`/`open -a` are unusable as the primary mechanism — no
fallback to them is planned since they cannot express "open in a
specific version" when multiple installs share a bundle ID.

## Scope for v1

Both GUI opening and CLI execution are in scope:

- `xcs open` (or bare `xcs`) — open the resolved workspace/project in
  the resolved Xcode version's GUI.
- `xcs exec <target> -- <cmd...>` — run an arbitrary command (typically
  `xcodebuild`) with `DEVELOPER_DIR` set to the resolved installation,
  so build tooling and agents can target a specific Xcode version too.
- `xcs path` — print the resolved Xcode.app path (or its
  `Contents/Developer` path with `--developer-dir`), for scripting.

MCP server support is explicitly **out of scope for v1**. `xcs`'s only
side effect is "launch one process"; there's no staged-transaction model
worth an MCP surface the way Egg's `hatch` flow has. Revisit if demand
appears.

## Config: `.xcodeversions.yml`

```yaml
targets:
  App/a.xcworkspace: "27.0"
  b.xcworkspace: "26.6"                 # suffix-match shorthand
  "Modules/**/*.xcodeproj": "26.3"      # glob
```

- Nested under `targets:` (not a flat map) so top-level keys are
  reserved for future config (e.g. a `default:` version) without
  colliding with filenames.
- Keys may be a path relative to the yml's directory (preferred, avoids
  ambiguity in a monorepo), a bare suffix like `b.xcworkspace` (matched
  by path suffix), or a glob pattern.
- Resolution precedence when a candidate target matches more than one
  key: exact relative-path match > suffix match > glob match. Two
  matches at the **same** precedence tier is an ambiguity error listing
  every matching key — never silently pick one.
- Discovery of `.xcodeversions.yml` walks up from the current directory
  to the nearest ancestor that has one (same pattern as x8's
  `X8ConfigurationLocator`).

## Version matching

Given a pinned version string and the set of discovered installations'
`CFBundleShortVersionString` values:

1. Exact string match wins.
2. Otherwise, dot-segment prefix match (`"27"` matches `27.0`, `27.1`,
   ...).
3. If step 2 yields more than one candidate, or step 1 has no match and
   step 2 has none either, fail with an error listing every discovered
   version — never guess "closest."

No `prefer: latest` / build-number disambiguation in v1; add only if a
real collision shows up in practice.

## Xcode discovery

`XcodeDiscovery` protocol, implementations tried in order:

1. `mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'"` (primary
   — Spotlight, catches installs anywhere, not just `/Applications`).
2. `/Applications/Xcode*.app` glob (fallback if Spotlight is
   unavailable/disabled, e.g. `mdfind` returns nothing or errors).

Each discovered `.app` is turned into an `XcodeInstallation` (path,
version from `Info.plist`'s `CFBundleShortVersionString`) via a
plist-reading step (`defaults read`/`PropertyListSerialization`, not a
shell-out to `defaults` in-process).

## Launching

`XcodeLauncher` protocol; the real implementation directly execs
`<installation path>/Contents/MacOS/Xcode <file-path>` as a detached
background process (fire-and-forget, matching `xed`'s non-blocking
default). A `--wait`-equivalent is not supported in v1, since `open -W`
doesn't map cleanly onto multiple simultaneous different-version
instances and direct exec has no built-in "notify on window close"; skip
it rather than build something unreliable.

## No-argument / picker behavior (confirmed with the user)

Running bare `xcs` (no target argument):

- Resolve the set of targets from `.xcodeversions.yml` in scope (or, if
  no config exists yet, the `*.xcworkspace`/`*.xcodeproj` found directly
  in the cwd).
- Exactly one candidate → open it immediately, no prompt.
- Multiple candidates, **TTY attached** → interactive single-choice
  picker via `swift-interaction`'s `Terminal().choose(ChoicePrompt(...))`
  (arrow-key navigable), listing each target with its resolved version.
- Multiple candidates, **no TTY** (agents, CI, piped) → never prompt;
  print the candidate list as an error (or as `changes`-style JSON under
  `--json`) and exit non-zero, mirroring Egg/x8's "fail fast instead of
  hanging on a prompt" rule.

`swift-interaction` (`https://github.com/Ryu0118/swift-interaction`) is
added as a Package.swift dependency of `XcsCLI` for this.

## CLI surface

```
xcs                                   # open resolved target (single) or prompt (multiple, TTY only)
xcs open [<target>] [--xcode <version>] [--xcode-path <path>] [--json]
xcs path [<target>] [--xcode <version>] [--developer-dir] [--json]
xcs exec <target> -- <command> [args...]
xcs list [--json]                     # discovered installations: path, version, running?
xcs doctor                            # config discovery, mdfind availability, per-entry resolvability
xcs init                              # (nice-to-have) scaffold .xcodeversions.yml from cwd's workspaces/projects
```

`--xcode <version>` and `--xcode-path <path>` both bypass the yml for a
one-off run; neither mutates `.xcodeversions.yml` or `xcode-select`.
`--json` is supported on every subcommand; non-interactive contexts get
immediate, structured errors instead of hanging.

## Architecture (mirrors Egg/x8-new's SwiftPM layering)

```
Sources/xcs/        thin executable — composition root only
Sources/XcsCLI/     ArgumentParser command tree, injected dependencies
Sources/XcsKit/     use cases: TargetResolver, XcodeDiscovery, XcodeLauncher, Execer
Sources/XcsConfig/  .xcodeversions.yml Locator/Loader/Decoder/Resolver
Sources/XcsCore/    value types only: XcodeInstallation, VersionSpec, TargetKey, ResolvedTarget
```

Dependency direction: `xcs` → `XcsCLI` → `XcsKit` → `XcsConfig` →
`XcsCore`. `XcsCore` has no I/O. `XcsConfig` does yml I/O only.
`XcsKit` owns process launching, `mdfind`/plist reads, and the
`swift-interaction` picker integration — protocol-boundaried
(`XcodeDiscovery`, `XcodeLauncher`) so `XcsCLI`'s command `run()` bodies
stay testable with fakes, matching x8's Runner-ownership rule.

## Tooling parity with Egg/x8-new

- `.agents/rules/*.md` split by concern; `CLAUDE.md` is the real file,
  `AGENTS.md` a symlink to it.
- `.mise.toml`, `.swiftformat`, `.swiftlint.yml`, `.swift-ast-lint.yml`,
  `docsync.yml`, `Makefile`, `install.sh`.
- `*.docc` per target.
- `Tests/` per target (`XcsCoreTests`, `XcsConfigTests`, `XcsKitTests`,
  `XcsCLITests`), with `XcodeDiscovery`/`XcodeLauncher` fakes so tests
  never actually launch Xcode.

## Testing strategy

- `XcsCore`: pure value-type tests (version match precedence, target-key
  resolution precedence, ambiguity detection).
- `XcsConfig`: yml locator/loader tests against fixture directory trees
  (nested `.xcodeversions.yml`, glob targets, malformed yml).
- `XcsKit`: `XcodeDiscovery`/`XcodeLauncher` behind protocols, fake
  implementations returning canned `XcodeInstallation` lists and
  recording launch calls instead of exec'ing anything.
- `XcsCLI`: command `run()` tests with fake context, covering the
  TTY-vs-non-TTY picker branch and `--json` output shape.
- No test ever launches a real Xcode process or calls real `mdfind`.

## Open items deferred past v1

- `xcs init` scaffold command — nice-to-have, not required for the core
  flow to work; build after the resolver/launcher core is solid.
- Build-number-level version disambiguation (`ProductBuildVersion`) for
  beta version collisions — add only if a real collision is hit.
- `xed`-style `--wait`/`-l <line>` support — not expressible reliably
  with direct-exec launching; explicitly out of scope.
