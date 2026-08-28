#!/bin/bash

# Install the Omarchy Proton Mail unread notifier:
#   1. Proton Mail webapp launcher (omarchy webapp install)
#   2. omarchy-protonmail-unread / -recent counter scripts
#   3. 686f6c61.proton-mail shell plugin (bar widget + dropdown + notifications)

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID="686f6c61.proton-mail"
DATA_DIR="$HOME/.local/share/omarchy-protonmail"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
SHELL_JSON="$HOME/.config/omarchy/shell.json"
# Staged here; `omarchy webapp install` copies it into the hicolor icon dir.
ICON_PATH="$DATA_DIR/proton-mail.png"
# Proton Mail logo shown in the dropdown header.
SVG_ICON_PATH="$DATA_DIR/proton-mail.svg"
DESKTOP_FILE="$HOME/.local/share/applications/Proton Mail.desktop"

# Preferences: --language <en|es|fr|de|it|zh> --nickname <text>
# Without flags, an interactive installer asks (gum); otherwise defaults apply.
LANGUAGE="en"
NICKNAME=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --language) LANGUAGE="$2"; shift 2 ;;
    --nickname) NICKNAME="$2"; shift 2 ;;
    *) echo "Unknown option: $1 (usage: install.sh [--language CODE] [--nickname TEXT])" >&2; exit 1 ;;
  esac
done
case "$LANGUAGE" in
  en | es | fr | de | it | zh) ;;
  *) echo "Invalid --language '$LANGUAGE' (expected: en es fr de it zh)" >&2; exit 1 ;;
esac

# --- 1. Icons -----------------------------------------------------------------
# Reviewed assets vendored in the repo (no install-time downloads of mutable
# remote content). The SVG is a single static path; the PNG is 128x128.
mkdir -p "$DATA_DIR"
install -m 644 "$PROJECT_DIR/assets/proton-mail.png" "$ICON_PATH"
install -m 644 "$PROJECT_DIR/assets/proton-mail.svg" "$SVG_ICON_PATH"

# --- 2. Webapp launcher -------------------------------------------------------
# The desktop entry launches through omarchy-protonmail-focus-or-launch, which
# focuses the existing window or spawns omarchy-protonmail-broker. The broker
# launches the browser with --remote-debugging-pipe and stays the only CDP
# client (inherited fds, no TCP debug port), serving a narrow local API for
# the recent-messages dropdown and forwarding external links to the default
# browser.
CUSTOM_EXEC="$DATA_DIR/omarchy-protonmail-focus-or-launch"
if [[ -f "$DESKTOP_FILE" ]] && grep -qF -- "omarchy-protonmail-focus-or-launch" "$DESKTOP_FILE"; then
  echo "Webapp 'Proton Mail' already up to date, skipping."
else
  echo "Creating 'Proton Mail' webapp (brokered launch, no debug port)..."
  omarchy webapp install "Proton Mail" "https://mail.proton.me" "$ICON_PATH" "$CUSTOM_EXEC"
fi

# --- 3. Helper scripts ---------------------------------------------------------
install -m 755 "$PROJECT_DIR/bin/omarchy-protonmail-unread" "$DATA_DIR/omarchy-protonmail-unread"
install -m 755 "$PROJECT_DIR/bin/omarchy-protonmail-recent" "$DATA_DIR/omarchy-protonmail-recent"
install -m 755 "$PROJECT_DIR/bin/omarchy-protonmail-broker" "$DATA_DIR/omarchy-protonmail-broker"
install -m 755 "$PROJECT_DIR/bin/omarchy-protonmail-focus-or-launch" "$DATA_DIR/omarchy-protonmail-focus-or-launch"
# Removed in 1.1.2: the linkguard's job now lives inside the broker.
rm -f "$DATA_DIR/omarchy-protonmail-linkguard"
pkill -f omarchy-protonmail-linkguard 2>/dev/null || true
echo "Installed counter scripts to $DATA_DIR/"

# --- 4. Shell plugin -----------------------------------------------------------
mkdir -p "$PLUGIN_DIR"
install -m 644 "$PROJECT_DIR/manifest.json" "$PLUGIN_DIR/manifest.json"
install -m 644 "$PROJECT_DIR/Panel.qml" "$PLUGIN_DIR/Panel.qml"
# A fresh shell avoids stale QML loader failures cached against plugin URLs
# (hot-reload keeps them otherwise). Restart refuses on a locked session.
if ! omarchy restart shell 2>/dev/null; then
  omarchy-shell shell rescanPlugins || true
fi
echo "Installed shell plugin to $PLUGIN_DIR/"

# --- 5. Enable in the bar -------------------------------------------------------
if grep -q "\"$PLUGIN_ID\"" "$SHELL_JSON"; then
  echo "Widget already enabled in shell.json, skipping."
else
  cp "$SHELL_JSON" "$SHELL_JSON.bak.$(date +%s)"
  omarchy plugin enable "$PLUGIN_ID"
  echo "Widget enabled in the right section of the bar."
fi

# --- 6. Preferences (language + nickname) ----------------------------------------
if [[ -t 0 && -t 1 ]] && command -v gum >/dev/null 2>&1; then
  echo
  echo "Choose the widget language / Elige el idioma del widget:"
  if choice=$(gum choose --selected "$LANGUAGE" en es fr de it zh); then
    LANGUAGE="$choice"
  fi
  if nick=$(gum input --prompt "Nickname for the dropdown header (empty = default)> " --placeholder "My mail" --value "$NICKNAME"); then
    NICKNAME="$nick"
  fi
fi
omarchy bar set "$PLUGIN_ID" language "$LANGUAGE" || true
if [[ -n "$NICKNAME" ]]; then
  omarchy bar set "$PLUGIN_ID" nickname "$NICKNAME" || true
fi
echo "Preferences: language=$LANGUAGE nickname='${NICKNAME:-<default>}'"

cat <<EOF

Done. Next steps:
  1. Launch "Proton Mail" from the app launcher (SUPER + SPACE) and log in.
     The webapp uses a dedicated browser profile, so this login is separate
     from your main browser (one time only).
  2. The 󰇮 widget sits in the top-right of the bar:
     - dimmed       -> Proton Mail window is not open
     - normal       -> open, no unread mail
     - 󰇮 N (accent) -> N unread; you also get a desktop notification
  3. Left-click the widget for a dropdown with your most recent messages.
     Click a message to jump to the open Proton Mail window.
     Right-click the widget to refresh.
  4. Change settings any time (applies live):
     omarchy bar set $PLUGIN_ID language es
     omarchy bar set $PLUGIN_ID nickname "My mail"
     omarchy bar set $PLUGIN_ID recentCount 7
EOF
