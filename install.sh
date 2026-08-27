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

# --- 1. Icon -----------------------------------------------------------------
mkdir -p "$DATA_DIR"
if [[ ! -s "$ICON_PATH" ]]; then
  echo "Downloading Proton Mail icon..."
  # mail.proton.me serves its SPA shell for icon paths, so use Google's
  # favicon service first and Proton's own .ico (48px) as a fallback.
  curl -fsSL --max-time 10 -o "$ICON_PATH" "https://www.google.com/s2/favicons?domain=proton.me&sz=128" || {
    curl -fsSL --max-time 10 -o "$ICON_PATH.ico" "https://proton.me/favicon.ico" &&
      magick "$ICON_PATH.ico" "$ICON_PATH" && rm -f "$ICON_PATH.ico"
  }
  if ! file -b --mime-type "$ICON_PATH" | grep -q '^image/'; then
    rm -f "$ICON_PATH"
    echo "Error: could not download a valid Proton Mail icon." >&2
    exit 1
  fi
fi

# --- 2. Webapp launcher -------------------------------------------------------
# Dedicated browser profile + CDP port so the recent-messages dropdown can
# read the inbox via the DevTools protocol without touching the user's main
# browser profile.
CUSTOM_EXEC="omarchy-launch-webapp https://mail.proton.me --user-data-dir=$DATA_DIR/browser-profile --remote-debugging-port=9229"
if [[ -f "$DESKTOP_FILE" ]] && grep -qF -- "--remote-debugging-port=9229" "$DESKTOP_FILE"; then
  echo "Webapp 'Proton Mail' already up to date, skipping."
else
  echo "Creating 'Proton Mail' webapp (dedicated profile + CDP)..."
  omarchy webapp install "Proton Mail" "https://mail.proton.me" "$ICON_PATH" "$CUSTOM_EXEC"
fi

# --- 3. Counter scripts ---------------------------------------------------------
install -m 755 "$PROJECT_DIR/bin/omarchy-protonmail-unread" "$DATA_DIR/omarchy-protonmail-unread"
install -m 755 "$PROJECT_DIR/bin/omarchy-protonmail-recent" "$DATA_DIR/omarchy-protonmail-recent"
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
