# Omarchy Proton Mail Notifier

[English](README.md) | [Español](README.es.md) | [Français](README.fr.md) | **Deutsch** | [Italiano](README.it.md) | [中文](README.zh.md)

Ein [Omarchy](https://omarchy.org)-Shell-Plugin, das die **Anzahl ungelesener
Proton-Mail-Nachrichten in der Leiste** anzeigt (oben rechts, neben dem
System-Tray), bei Klick eine Liste der **neuesten Nachrichten** aufklappt und
eine Desktop-Benachrichtigung auslöst, wenn neue E-Mails eintreffen.

Keine Browser-Erweiterung, keine Proton Mail Bridge — funktioniert mit
**kostenlosen und kostenpflichtigen Proton-Konten** und jedem
Chromium-basierten Browser (Brave, Chrome, Chromium, Edge).

Das Widget spricht **English, Español, Français, Deutsch, Italiano und
中文** (standardmäßig English), und alles — Abfrageintervall,
Dropdown-Größe, Kopfzeilen-Spitzname, Benachrichtigungen, Sprache — lässt
sich live über `omarchy bar set` konfigurieren.

## Screenshots

![Dropdown mit den neuesten Nachrichten](screenshots/dropdown.jpg)

![Widget-Tooltip in der Leiste](screenshots/widget-tooltip.jpg)

## Funktionsweise

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
        └─ CDP (ephemeral) ──► omarchy-protonmail-linkguard ──► externe Links öffnen im
            (DevTools protocol)      (solange die Webapp offen ist)      Standard-Browser
```

- **Anzahl ungelesener Mails**: Proton Mail schreibt sie als `(N)` in den
  Seitentitel, und Hyprland stellt Fenstertitel über `hyprctl clients -j`
  bereit. Funktioniert mit dem Webapp-Fenster *und* mit jedem normalen
  Browser-Tab, in dem Proton Mail geöffnet ist.
- **Neueste Nachrichten**: Die installierte Webapp läuft in einem dedizierten
  Browser-Profil mit einem ephemeralen DevTools-Port (`--remote-debugging-port=0`,
  vermerkt in `DevToolsActivePort`). Das
  Plugin liest die Posteingangszeilen direkt aus der Seite über CDP aus —
  Python nur mit Standardbibliothek, nichts weiter zu installieren.
- **Externe Links**: In einer Nachricht angeklickte Links werden im
  Standard-Browser geöffnet (Hauptprofil mit Cookies und Anmeldungen) statt
  im dedizierten Profil der Webapp. `omarchy-protonmail-linkguard` überwacht
  die Tabs über CDP, öffnet Nicht-Proton-Tabs mit `xdg-open` und schließt sie
  in der Webapp. Läuft nur, solange Proton Mail geöffnet ist.

## Installation

```bash
git clone https://github.com/686f6c61/Omarchy-Proton-Mail.git
cd Omarchy-Proton-Mail
./install.sh
```

Das Installationsprogramm:

1. Lädt das Proton-Symbol herunter und erstellt einen Starter für die
   **Webapp „Proton Mail"** (`omarchy webapp install`) mit dediziertem
   Profil + CDP-Port.
2. Installiert `omarchy-protonmail-unread` und `omarchy-protonmail-recent`
   nach `~/.local/share/omarchy-protonmail/`.
3. Installiert das Shell-Plugin nach
   `~/.config/omarchy/plugins/686f6c61.proton-mail/`.
4. Aktiviert das Widget im **rechten Abschnitt** der Leiste (erstellt
   vorher ein Backup von `~/.config/omarchy/shell.json`) und startet die
   Shell neu.
5. Fragt nach deiner **Sprache** und einem optionalen **Spitznamen**
   (interaktiv). Nicht-interaktive Alternative:
   `./install.sh --language es --nickname "My mail"`

Starte danach **Proton Mail** über den Anwendungsstarter (SUPER + LEERTASTE)
und melde dich an. Das dedizierte Profil bedeutet, dass du dich einmalig
anmeldest, unabhängig von deinem Hauptbrowser.

## Verwendung

- **Linksklick auf das Widget**: Dropdown mit den letzten N Nachrichten
  (Absender, Betreff, Uhrzeit; ungelesene in Fettdruck). Klick auf eine
  Nachricht, um zum Proton-Mail-Fenster zu springen — das vorhandene Fenster
  wird fokussiert, nie dupliziert.
- Die Dropdown-Kopfzeile zeigt das Proton-Mail-Logo, und die untere Zeile
  enthält einen Schalter **Benachrichtigungen pausieren**, der die
  Einstellung `notify` live umschaltet.
- In einer Nachricht angeklickte Links öffnen im **Standard-Browser**
  (Hauptprofil), nicht im dedizierten Profil der Webapp.
- Mit `recentCount: "0"` ist das Dropdown deaktiviert und ein Linksklick
  fokussiert nur das Proton-Mail-Fenster (reiner Benachrichtigungsmodus).
- **Rechts-/Mittelklick**: Jetzt aktualisieren.
- Ein Klick auf die Benachrichtigung öffnet/fokussiert ebenfalls Proton Mail.

Widget-Zustände (solange aktiviert immer sichtbar):

| Zustand              | Bedeutung                           |
|----------------------|-------------------------------------|
| 󰇯 abgeblendet        | Proton-Mail-Fenster nicht geöffnet  |
| 󰇯 normal             | Geöffnet, keine ungelesenen Mails   |
| 󰇮 N (Akzentfarbe)    | N ungelesen — Benachrichtigung ausgelöst |
| 󰇮 99+ (Akzentfarbe)  | Mehr als 99 ungelesen               |

## Einstellungen

Am schnellsten geht es mit dem Befehl `omarchy bar set` (wird sofort
angewendet, kein Neustart nötig):

```bash
omarchy bar set 686f6c61.proton-mail recentCount 7
omarchy bar set 686f6c61.proton-mail nickname "Meine Mails"
omarchy bar set 686f6c61.proton-mail language es
omarchy bar set 686f6c61.proton-mail intervalSec 10
omarchy bar set 686f6c61.proton-mail notify false
```

Du kannst den Widget-Eintrag auch direkt in `~/.config/omarchy/shell.json`
bearbeiten:

```json
{ "id": "686f6c61.proton-mail", "intervalSec": 5, "recentCount": "5", "notify": true, "nickname": "", "language": "en" }
```

- `intervalSec` (2–60, Standard 5): Abfrageintervall für die Anzahl
  ungelesener Mails.
- `recentCount` (0–20, Standard 5): Anzahl der im Dropdown aufgelisteten
  Nachrichten. `0` deaktiviert das Dropdown (nur Benachrichtigung).
- `notify` (Standard true): Desktop-Benachrichtigung, wenn die Zahl steigt.
- `nickname` (Standard leer): Benutzerdefinierter Text für die
  Dropdown-Kopfzeile, wenn keine ungelesenen Mails vorliegen. Leer zeigt den
  Standardtext an („All caught up" auf Englisch).
- `language` (`en`/`es`/`fr`/`de`/`it`/`zh`, Standard `en`): Sprache von
  Widget, Dropdown und Benachrichtigungen (English, Español, Français,
  Deutsch, Italiano, 中文).

## Fehlerbehebung

- **Widget fehlt nach der Installation**: Führe `omarchy restart shell` aus
  (der QML-Loader zwischenspeichert Fehler zu Plugin-URLs; eine frische
  Shell löscht sie).
- **Widget übernimmt QML-Änderungen während der Entwicklung nicht**: gleiche
  Ursache — das Hot-Reload per inotify kann weiterhin zwischengespeicherten
  Bytecode für die Plugin-URL ausliefern. Führe `omarchy restart shell` aus,
  nachdem du Plugin-Dateien bearbeitet hast.
- **Dropdown zeigt die Anmeldezeile**: Melde dich im Fenster der Webapp
  „Proton Mail" an (das dedizierte Profil hat eine eigene Sitzung).
- **Dropdown leer trotz Anmeldung**: Möglicherweise muss die Extraktion an
  deine Proton-Version angepasst werden — führe
  `~/.local/share/omarchy-protonmail/omarchy-protonmail-recent --dump` aus
  und öffne ein Issue mit der Ausgabe.
- Das Ungelesen-Badge hängt vom `(N)`-Format des Seitentitels von Proton
  Mail ab; die Abgleichlogik liegt in `bin/omarchy-protonmail-unread`.

## Deinstallation

```bash
omarchy webapp remove "Proton Mail"
rm -rf ~/.config/omarchy/plugins/686f6c61.proton-mail ~/.local/share/omarchy-protonmail
# dann den Eintrag { "id": "686f6c61.proton-mail" } aus ~/.config/omarchy/shell.json entfernen
# (oder das von install.sh erstellte Backup shell.json.bak.<timestamp> wiederherstellen)
omarchy restart shell
```

## Lizenz

[MIT](LICENSE) © 686f6c61 <github@00b.tech>
