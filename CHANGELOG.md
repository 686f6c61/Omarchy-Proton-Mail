# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.5] - 2026-08-30

Fourth marketplace review round: cross-uid path in the client and an honest
authorization boundary.

### Security

- `omarchy-protonmail-recent` no longer falls back to `/tmp` when
  `XDG_RUNTIME_DIR` is unset: it refuses to run (exit 1), mirroring the
  broker. The predictable runtime path under a world-writable directory —
  where a different local user could pre-create the directory and serve
  arbitrary JSON — is gone from both halves of the pair, not just one.
- `omarchy-protonmail-recent` now connects to the broker socket the same way
  the broker creates it: relative to a directory descriptor opened with
  `O_NOFOLLOW`, after validating ownership and `0700` mode of
  `XDG_RUNTIME_DIR` and the broker subdirectory, and the socket type and
  ownership (stat with `follow_symlinks=False`). The connect path is
  `/proc/self/fd/<dirfd>/broker.sock`, so nothing on disk is re-resolved at
  connect time.
- `omarchy-protonmail-broker`: the `/proc/<pid>/exe` + `argv[1]` peer
  checks were removed. They were not an authorization boundary — any
  same-uid process can execute the real client script and satisfy them by
  construction — and they introduced a pid-reuse window between `accept()`
  and the `/proc` reads. The boundary is now stated as what it is:
  `SO_PEERCRED` (peer uid equals the broker's euid), captured atomically at
  accept time, over a `0600` socket inside a `0700` per-user runtime
  directory. Every same-uid process is inside that boundary by
  construction (it can ptrace the broker and reach its CDP pipe fds), so no
  handshake can exclude it; the API therefore grants nothing beyond
  same-uid reach — read-only `recent`, size- and row-capped replies, and
  every dangerous capability (JavaScript execution, session cookies, full
  mailbox access) stays inside the broker process. The broker and client
  docstrings state this residual explicitly.

## [1.1.4] - 2026-08-28

Third marketplace review round: hardening of the broker's local boundary.

### Security

- Broker API is now read-only (`recent` only; the `selftest` diagnostic was
  removed) and client authorization goes beyond `SO_PEERCRED`: the peer
  process must be the Python interpreter running exactly this plugin's
  installed client script. The broker docstring states the residual same-uid
  exposure honestly (truncated metadata of the last N messages; no bodies,
  no session, no JS execution).
- The broker refuses to start without a trusted per-user `XDG_RUNTIME_DIR`
  (no `/tmp` fallback) and creates/opens its subdirectory, lock and socket
  relative to a validated directory descriptor with `O_NOFOLLOW`.
- `hyprctl clients -j` output is capped at 256 KiB on the producer side (and
  time-bounded) in both `omarchy-protonmail-unread` and
  `omarchy-protonmail-focus-or-launch`.
- `omarchy-protonmail-recent` caps broker replies at 64 KiB and normalizes
  the exact schema, record count and field lengths before QML parses them.

## [1.1.2] - 2026-08-28

Rework of the DevTools access after the second marketplace review round: a
random port is still an unauthenticated port, so the debug endpoint is gone
entirely.

### Security

- **No TCP debug port at all.** The webapp now launches with
  `--remote-debugging-pipe`: the browser speaks CDP over file descriptors
  inherited from its launcher, so no process — not even one running as the
  same user — can connect to the authenticated mailbox session.
- New `omarchy-protonmail-broker`: the sole CDP client. It launches the
  browser, serves a narrowly scoped API on a unix socket
  (`recent` truncated metadata only; per-client `SO_PEERCRED` uid check) and
  forwards external tabs to the default browser itself.
- `omarchy-protonmail-recent` is now a thin broker client with the same
  output contract; `omarchy-protonmail-linkguard` was removed (its job lives
  in the broker's sweep).
- The launcher, widget and notification now focus-or-launch through
  `omarchy-protonmail-focus-or-launch`.

### Fixed

- Window focusing on newer Hyprland versions that dispatch through
  `hl.dsp.focus(...)` (legacy `focuswindow address:` syntax is kept as a
  fallback).

## [1.1.1] - 2026-08-28

Security hardening after the Omarchy marketplace review.

### Security

- No more fixed, unauthenticated DevTools port: the webapp now launches with
  `--remote-debugging-port=0`, so Chromium picks a random ephemeral port that
  helpers discover through the `DevToolsActivePort` file inside the
  0700-permission profile directory.
- WebSocket client hardened: exact loopback hosts only, and hard caps on
  frame (1 MiB) and reassembled message (4 MiB) sizes, enforced before any
  allocation or accumulation.
- Mailbox sender/subject/time text forced to `Text.PlainText` in the dropdown
  so crafted messages can never be parsed as rich text.
- Installer no longer downloads mutable remote assets: the Proton Mail PNG
  and SVG ship vendored (and reviewed) in the repo under `assets/`.
- External-link guard now allowlists exact parsed hostnames
  (`proton.me`, `protonmail.com`, `protonvpn.com` and their subdomains)
  instead of substring matching, and helper processes run with timeouts and
  intrinsically bounded output.

## [1.1.0] - 2026-08-28

### Added

- External links clicked inside the Proton Mail webapp now open in the default
  browser (main profile, with your cookies and logins) instead of the webapp's
  dedicated profile: `omarchy-protonmail-linkguard` watches the CDP target
  list, forwards non-Proton tabs to `xdg-open` and closes them in the webapp.
  The widget spawns the guard when Proton Mail is open; a file lock keeps a
  single instance and the guard self-exits when the webapp closes.
- Proton Mail logo (SVG, downloaded by the installer) in front of the dropdown
  header text.
- "Pause notifications" switch at the bottom of the dropdown: flips the
  `notify` setting live and persists it to `shell.json`.

## [1.0.0] - 2026-08-27

First public release.

### Added

- Bar widget (top-right, always visible) with the unread Proton Mail count,
  derived from the `(N)` page title via `hyprctl clients` — works with the
  bundled webapp and with any regular browser tab showing Proton Mail. Open
  envelope icon when there is no unread mail, closed envelope + counter when
  there is (capped at `99+`).
- Dropdown panel below the bar listing the most recent messages, one per line
  (`time · sender — subject`, unread in bold), read from the inbox over the
  Chrome DevTools Protocol against a dedicated browser profile.
- Desktop notification when the unread count goes up (fixed replacement id,
  no stacked toasts). Clicking it focuses the Proton Mail window.
- Click behavior that always focuses the existing Proton Mail window — on any
  workspace — instead of opening duplicates (widget, dropdown rows and
  notification).
- "Proton Mail" webapp launcher created with `omarchy webapp install`, using
  a dedicated browser profile with a local DevTools port (`127.0.0.1:9229`).
- `install.sh` one-step installer (icon, webapp, counter scripts, shell
  plugin, bar registration with `shell.json` backup) and README uninstall
  steps.

### Configuration

All settings apply live (no shell restart) via
`omarchy bar set 686f6c61.proton-mail <key> <value>`, from the shell settings
UI, or inline in `~/.config/omarchy/shell.json`:

- `intervalSec` (2–60, default 5): unread-count poll interval.
- `recentCount` (0–20, default 5): messages listed in the dropdown; `0`
  disables the dropdown and turns the widget into a pure notifier whose click
  focuses Proton Mail.
- `notify` (default true): desktop notification when the count goes up.
- `nickname` (default empty): custom text for the dropdown header when there
  is no unread mail.
- `language` (`en`/`es`/`fr`/`de`/`it`/`zh`, default `en`): widget, dropdown
  and notification language.

### Languages

- Widget UI in **English by default**, with Español, Français, Deutsch,
  Italiano and 中文 available through the `language` setting. Translations
  live in a single dictionary in `Panel.qml`, easy to extend.
- Documentation (`README`) available in all six languages.

[1.1.4]: https://github.com/686f6c61/Omarchy-Proton-Mail/releases/tag/v1.1.4
[1.1.2]: https://github.com/686f6c61/Omarchy-Proton-Mail/releases/tag/v1.1.2
[1.1.1]: https://github.com/686f6c61/Omarchy-Proton-Mail/releases/tag/v1.1.1
[1.1.0]: https://github.com/686f6c61/Omarchy-Proton-Mail/releases/tag/v1.1.0
[1.0.0]: https://github.com/686f6c61/Omarchy-Proton-Mail/releases/tag/v1.0.0
