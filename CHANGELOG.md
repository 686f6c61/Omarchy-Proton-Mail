# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.0.0]: https://github.com/686f6c61/Omarchy-Proton-Mail/releases/tag/v1.0.0
