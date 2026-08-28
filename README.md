# Omarchy Proton Mail Notifier

**English** | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Italiano](README.it.md) | [中文](README.zh.md)

An [Omarchy](https://omarchy.org) shell plugin that shows your **unread Proton
Mail count in the bar** (top-right, next to the tray), drops down a list of
your **most recent messages** when clicked, and raises a desktop notification
when new mail arrives.

No browser extension, no Proton Mail Bridge — works with **free and paid
Proton accounts** and any Chromium-based browser (Brave, Chrome, Chromium,
Edge).

The widget speaks **English, Español, Français, Deutsch, Italiano and 中文**
(English by default), and everything — poll interval, dropdown size, header
nickname, notifications, language — is configurable live via `omarchy bar set`.

## Screenshots

![Dropdown with recent messages](screenshots/dropdown.jpg)

![Widget tooltip in the bar](screenshots/widget-tooltip.jpg)

## How it works

```
Proton Mail webapp (dedicated browser profile, --app window)
title: "(3) Inbox | … | Proton Mail"
        │
        ├─ hyprctl clients -j ──► omarchy-protonmail-unread ──► badge 󰇮 N + notification
        │   (window titles)          (every intervalSec)
        │
        ├─ CDP (ephemeral) ──► omarchy-protonmail-recent ──► dropdown with last N messages
        │   (DevTools protocol)      (on open / count change)
        │
        └─ CDP (ephemeral) ──► omarchy-protonmail-linkguard ──► external links open
            (DevTools protocol)      (while the webapp is open)        in the default browser
```

- **Unread count**: Proton Mail puts it in the page title as `(N)`, and
  Hyprland exposes window titles via `hyprctl clients -j`. Works with the
  webapp window *and* any regular browser tab showing Proton Mail.
- **Recent messages**: the installed webapp runs in a dedicated browser
  profile with an ephemeral DevTools port (`--remote-debugging-port=0`, recorded in `DevToolsActivePort`). The plugin reads the
  inbox rows straight from the page over CDP — stdlib-only Python, nothing
  else to install.
- **External links**: links clicked inside a message are forwarded to the
  default browser (your main profile, with cookies and logins) instead of
  opening in the webapp's dedicated profile. `omarchy-protonmail-linkguard`
  watches the CDP target list, opens any non-Proton tab with `xdg-open` and
  closes it in the webapp. It runs only while Proton Mail is open.

## Install

```bash
git clone https://github.com/686f6c61/Omarchy-Proton-Mail.git
cd Omarchy-Proton-Mail
./install.sh
```

The installer:

1. Downloads the Proton icon and creates a **"Proton Mail" webapp** launcher
   (`omarchy webapp install`) with a dedicated profile + CDP port.
2. Installs `omarchy-protonmail-unread` and `omarchy-protonmail-recent` to
   `~/.local/share/omarchy-protonmail/`.
3. Installs the shell plugin to `~/.config/omarchy/plugins/686f6c61.proton-mail/`.
4. Enables the widget in the **right section** of the bar (backs up
   `~/.config/omarchy/shell.json` first) and restarts the shell.
5. Asks for your **language** and an optional **nickname** (interactive).
   Non-interactive alternative:
   `./install.sh --language es --nickname "My mail"`

Then launch **Proton Mail** from the app launcher (SUPER + SPACE) and log in.
The dedicated profile means you log in once, separately from your main
browser.

## Usage

- **Left-click the widget**: dropdown with the last N messages (sender,
  subject, time; unread ones in bold). Click a message to jump to the Proton
  Mail window — the existing one is focused, never duplicated.
- The dropdown header shows the Proton Mail logo, and the bottom row has a
  **Pause notifications** switch that flips the `notify` setting live.
- Links clicked inside a message open in your **default browser** (main
  profile), not in the webapp's dedicated profile.
- With `recentCount: "0"` the dropdown is disabled and left-click just focuses
  the Proton Mail window (pure notifier mode).
- **Right/middle-click**: refresh now.
- Clicking the notification opens/focuses Proton Mail too.

Widget states (always visible while enabled):

| State                | Meaning                        |
|----------------------|--------------------------------|
| 󰇯 dimmed             | Proton Mail window not open    |
| 󰇯 normal             | Open, no unread mail           |
| 󰇮 N (accent)         | N unread — notification fired  |
| 󰇮 99+ (accent)       | More than 99 unread            |

## Settings

The quickest way is the `omarchy bar set` command (applies live, no restart):

```bash
omarchy bar set 686f6c61.proton-mail recentCount 7
omarchy bar set 686f6c61.proton-mail nickname "My mail"
omarchy bar set 686f6c61.proton-mail language es
omarchy bar set 686f6c61.proton-mail intervalSec 10
omarchy bar set 686f6c61.proton-mail notify false
```

You can also edit the widget entry inline in `~/.config/omarchy/shell.json`:

```json
{ "id": "686f6c61.proton-mail", "intervalSec": 5, "recentCount": "5", "notify": true, "nickname": "", "language": "en" }
```

- `intervalSec` (2–60, default 5): poll interval for the unread count.
- `recentCount` (0–20, default 5): messages listed in the dropdown. `0`
  disables the dropdown (notifier only).
- `notify` (default true): desktop notification when the count goes up.
- `nickname` (default empty): custom text for the dropdown header when there
  is no unread mail. Empty shows the default "All caught up".
- `language` (`en`/`es`/`fr`/`de`/`it`/`zh`, default `en`): widget,
  dropdown and notification language (English, Español, Français, Deutsch,
  Italiano, 中文).

## Troubleshooting

- **Widget missing after install**: run `omarchy restart shell` (the QML
  loader caches failures against plugin URLs; a fresh shell clears them).
- **Widget not picking up QML edits while developing**: same cause — the
  inotify hot-reload can keep serving cached bytecode for the plugin URL.
  Run `omarchy restart shell` after editing plugin files.
- **Dropdown shows the login row**: log in inside the "Proton Mail" webapp
  window (the dedicated profile has its own session).
- **Dropdown empty while logged in**: extraction may need retuning against
  your Proton version — run
  `~/.local/share/omarchy-protonmail/omarchy-protonmail-recent --dump` and
  open an issue with the output.
- The unread badge depends on Proton Mail's `(N)` page-title format; matching
  lives in `bin/omarchy-protonmail-unread`.

## Uninstall

```bash
omarchy webapp remove "Proton Mail"
rm -rf ~/.config/omarchy/plugins/686f6c61.proton-mail ~/.local/share/omarchy-protonmail
# then remove the { "id": "686f6c61.proton-mail" } entry from ~/.config/omarchy/shell.json
# (or restore the shell.json.bak.<timestamp> backup created by install.sh)
omarchy restart shell
```

## License

[MIT](LICENSE) © 686f6c61 <github@00b.tech>
