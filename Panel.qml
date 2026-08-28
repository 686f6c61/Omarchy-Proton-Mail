import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Proton Mail unread-count widget with a dropdown of recent messages.
//
// Badge: polls omarchy-protonmail-unread (hyprctl window titles) for the
// unread count. Dropdown: polls omarchy-protonmail-recent, a thin client of
// omarchy-protonmail-broker — the broker is the only CDP client and reaches
// the webapp over --remote-debugging-pipe (inherited fds, no TCP port), so
// the authenticated mailbox session exposes no debug endpoint at all.
// recentCount=0 disables the dropdown and turns the widget into a plain
// notifier whose click focuses the Proton Mail window.
Panel {
  id: root
  moduleName: "686f6c61.proton-mail"
  ipcTarget: "686f6c61.proton-mail"

  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property int recentCount: Math.max(0, parseInt(root.setting("recentCount", "5")) || 0)
  // Custom text for the "all caught up" header; empty keeps the default.
  readonly property string nickname: String(root.setting("nickname", "")).trim()
  // UI language: en (default), es, fr, de, it, zh.
  readonly property string language: String(root.setting("language", "en"))

  readonly property var i18n: ({
    en: {
      closed: "Proton Mail is not open",
      tipClosed: "Proton Mail (not open)",
      upToDate: "All caught up",
      upToDateTip: "Proton Mail: all caught up",
      unreadOne: "1 unread message",
      unreadMany: "%1 unread messages",
      unreadShortOne: "1 unread",
      unreadShortMany: "%1 unread",
      noSubject: "(no subject)",
      noRecent: "No recent messages",
      openMail: "Open Proton Mail",
      dedicatedOnly: "Messages are only read from the Proton Mail app (launcher)",
      pauseNotifications: "Pause notifications"
    },
    es: {
      closed: "Proton Mail no está abierto",
      tipClosed: "Proton Mail (no abierto)",
      upToDate: "Bandeja al día",
      upToDateTip: "Proton Mail: al día",
      unreadOne: "1 mensaje sin leer",
      unreadMany: "%1 mensajes sin leer",
      unreadShortOne: "1 sin leer",
      unreadShortMany: "%1 sin leer",
      noSubject: "(sin asunto)",
      noRecent: "Sin correos recientes",
      openMail: "Abrir Proton Mail",
      dedicatedOnly: "Los mensajes solo se leen de la app Proton Mail (launcher)",
      pauseNotifications: "Pausar notificaciones"
    },
    fr: {
      closed: "Proton Mail n'est pas ouvert",
      tipClosed: "Proton Mail (non ouvert)",
      upToDate: "Boîte à jour",
      upToDateTip: "Proton Mail : à jour",
      unreadOne: "1 message non lu",
      unreadMany: "%1 messages non lus",
      unreadShortOne: "1 non lu",
      unreadShortMany: "%1 non lus",
      noSubject: "(sans objet)",
      noRecent: "Aucun message récent",
      openMail: "Ouvrir Proton Mail",
      dedicatedOnly: "Les messages ne sont lus que depuis l'app Proton Mail (lanceur)",
      pauseNotifications: "Mettre les notifications en pause"
    },
    de: {
      closed: "Proton Mail ist nicht geöffnet",
      tipClosed: "Proton Mail (nicht geöffnet)",
      upToDate: "Alles erledigt",
      upToDateTip: "Proton Mail: alles erledigt",
      unreadOne: "1 ungelesene Nachricht",
      unreadMany: "%1 ungelesene Nachrichten",
      unreadShortOne: "1 ungelesen",
      unreadShortMany: "%1 ungelesen",
      noSubject: "(kein Betreff)",
      noRecent: "Keine aktuellen Nachrichten",
      openMail: "Proton Mail öffnen",
      dedicatedOnly: "Nachrichten werden nur aus der Proton-Mail-App (Launcher) gelesen",
      pauseNotifications: "Benachrichtigungen pausieren"
    },
    it: {
      closed: "Proton Mail non è aperto",
      tipClosed: "Proton Mail (non aperto)",
      upToDate: "Posta in regola",
      upToDateTip: "Proton Mail: in regola",
      unreadOne: "1 messaggio non letto",
      unreadMany: "%1 messaggi non letti",
      unreadShortOne: "1 non letto",
      unreadShortMany: "%1 non letti",
      noSubject: "(nessun oggetto)",
      noRecent: "Nessun messaggio recente",
      openMail: "Apri Proton Mail",
      dedicatedOnly: "I messaggi vengono letti solo dall'app Proton Mail (launcher)",
      pauseNotifications: "Metti in pausa le notifiche"
    },
    zh: {
      closed: "Proton Mail 未打开",
      tipClosed: "Proton Mail（未打开）",
      upToDate: "收件箱已处理完毕",
      upToDateTip: "Proton Mail：已全部处理",
      unreadOne: "1 封未读邮件",
      unreadMany: "%1 封未读邮件",
      unreadShortOne: "1 封未读",
      unreadShortMany: "%1 封未读",
      noSubject: "（无主题）",
      noRecent: "没有最近的邮件",
      openMail: "打开 Proton Mail",
      dedicatedOnly: "只能从 Proton Mail 应用（启动器）读取邮件",
      pauseNotifications: "暂停通知"
    }
  })

  function t(key) {
    var pack = i18n[language] || i18n.en
    return pack[key] || i18n.en[key] || key
  }

  function unreadText(n) {
    return n === 1 ? t("unreadOne") : t("unreadMany").replace("%1", n)
  }

  function unreadShort(n) {
    return n === 1 ? t("unreadShortOne") : t("unreadShortMany").replace("%1", n)
  }

  property int unread: 0
  property bool mailOpen: false
  // False until the first successful poll, so we never notify on startup
  // about mail that was already there.
  property bool haveSample: false
  property bool loggedIn: false
  property var messages: []

  function refresh() {
    if (!pollProc.running) pollProc.running = true
  }

  function refreshRecent() {
    if (recentCount > 0 && mailOpen && !recentProc.running) recentProc.running = true
  }

  // Focus the existing Proton Mail window (any workspace) or launch the
  // webapp through the broker, which keeps the DevTools pipe to itself.
  readonly property string focusScript: Quickshell.env("HOME") + "/.local/share/omarchy-protonmail/omarchy-protonmail-focus-or-launch"
  // Proton Mail logo shown before the dropdown header; installed by install.sh.
  readonly property string mailIconPath: Quickshell.env("HOME") + "/.local/share/omarchy-protonmail/proton-mail.svg"

  // shell.json stores settings as strings ("false"), so a plain boolean
  // coercion would read "false" as enabled.
  function notifyEnabled() {
    var v = root.setting("notify", true)
    return v === true || v === "true" || v === 1 || v === "1"
  }

  // Notifications paused = notify setting off. The switch at the bottom of the
  // dropdown flips it live.
  readonly property bool notificationsPaused: !notifyEnabled()

  // Persist a setting the same way first-party panels do: update the local
  // copy so the UI redraws on the click, then write shell.json through the
  // shell so the change survives restarts.
  function persistSetting(key, value) {
    var entry = { id: root.moduleName }
    for (var existing in root.settings) if (existing !== "id") entry[existing] = root.settings[existing]
    entry[key] = value
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function focusMail() {
    if (bar) bar.run(root.focusScript)
  }

  function applyState(raw) {
    var s
    try {
      s = JSON.parse(raw)
    } catch (e) {
      return
    }
    var n = parseInt(s.unread) || 0
    var prev = root.unread
    root.unread = n
    root.mailOpen = !!s.open
    if (n !== prev) root.refreshRecent()
    if (root.notifyEnabled() && root.haveSample && n > prev) {
      Quickshell.execDetached(["omarchy-notification-send",
        "-g", "󰇮", "-r", "4242",
        "Proton Mail",
        root.unreadText(n),
        "--exec", root.focusScript])
    }
    root.haveSample = true
  }

  function applyRecent(raw) {
    var s
    try {
      s = JSON.parse(raw)
    } catch (e) {
      return
    }
    root.loggedIn = !!s.loggedIn
    root.messages = s.messages || []
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    refreshRecent()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  Process {
    id: pollProc
    command: [Quickshell.env("HOME") + "/.local/share/omarchy-protonmail/omarchy-protonmail-unread"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyState(String(text || "").trim())
    }
  }

  Process {
    id: recentProc
    command: [Quickshell.env("HOME") + "/.local/share/omarchy-protonmail/omarchy-protonmail-recent",
      "--limit", String(root.recentCount)]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyRecent(String(text || "").trim())
    }
  }

  Timer {
    interval: Math.max(2, root.setting("intervalSec", 5)) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.unread > 0 ? "󰇮 " + (root.unread > 99 ? "99+" : root.unread) : "󰇯"
    fontSize: Style.font.caption
    active: root.unread > 0
    dimmed: !root.mailOpen
    tooltipText: !root.mailOpen
      ? root.t("tipClosed")
      : (root.unread > 0 ? root.unreadShort(root.unread) : root.t("upToDateTip"))
    onPressed: function(b) {
      if (b === Qt.RightButton || b === Qt.MiddleButton) {
        root.refresh()
      } else if (root.recentCount > 0) {
        root.toggle()
      } else {
        root.focusMail()
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: column
          width: parent.width
          spacing: Style.space(2)

          Row {
            width: parent.width
            leftPadding: Style.space(12)
            topPadding: Style.space(8)
            bottomPadding: Style.space(8)
            spacing: Style.space(8)

            Image {
              id: headerIcon
              anchors.verticalCenter: parent.verticalCenter
              width: Style.font.subtitle
              height: Style.font.subtitle
              source: "file://" + root.mailIconPath
              sourceSize.width: width * 2
              sourceSize.height: height * 2
              visible: status === Image.Ready
            }

            Text {
              width: parent.width - parent.leftPadding - parent.spacing
                - (headerIcon.visible ? headerIcon.width : 0)
              anchors.verticalCenter: parent.verticalCenter
              text: !root.mailOpen
                ? root.t("closed")
                : (root.unread > 0
                  ? root.unreadText(root.unread)
                  : (root.nickname !== "" ? root.nickname : root.t("upToDate")))
              color: root.foreground
              opacity: 0.6
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
            }
          }

          Repeater {
            model: root.messages

            Rectangle {
              required property var modelData
              width: column.width
              height: rowText.implicitHeight + Style.space(12)
              radius: Style.cornerRadius
              color: rowMouse.containsMouse ? Style.hoverFillFor(root.foreground, Color.accent) : "transparent"

              Text {
                id: rowText
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Style.space(12)
                anchors.rightMargin: Style.space(12)
                anchors.verticalCenter: parent.verticalCenter
                text: (modelData.time ? modelData.time + " · " : "")
                  + (modelData.sender || "—")
                  + " — " + (modelData.subject || root.t("noSubject"))
                // Mailbox content is attacker-controlled: never let it be
                // parsed as rich text (inline resource loads).
                textFormat: Text.PlainText
                color: root.foreground
                opacity: modelData.unread ? 1 : 0.75
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: modelData.unread
                elide: Text.ElideRight
              }

              MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.focusMail()
                  root.close()
                }
              }
            }
          }

          Text {
            visible: root.mailOpen && root.loggedIn && root.messages.length === 0
            width: parent.width
            leftPadding: Style.space(12)
            bottomPadding: Style.space(8)
            text: root.t("noRecent")
            color: root.foreground
            opacity: 0.6
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          Rectangle {
            visible: !root.mailOpen || !root.loggedIn
            width: column.width
            height: openText.implicitHeight + Style.space(12)
            radius: Style.cornerRadius
            color: openMouse.containsMouse ? Style.hoverFillFor(root.foreground, Color.accent) : "transparent"

            Text {
              id: openText
              anchors.left: parent.left
              anchors.leftMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              text: !root.mailOpen ? root.t("openMail") : root.t("dedicatedOnly")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }

            MouseArea {
              id: openMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.focusMail()
                root.close()
              }
            }
          }
          // Breathing room between the last message row and the switch.
          Item {
            width: 1
            height: Style.space(10)
          }

          Toggle {
            width: column.width
            opacity: 0.55
            label: root.t("pauseNotifications")
            checked: root.notificationsPaused
            foreground: root.foreground
            fontFamily: root.fontFamily
            titleSize: Style.font.body
            onClicked: root.persistSetting("notify", root.notificationsPaused)
          }

          Item {
            width: 1
            height: Style.space(6)
          }
        }
      }
    }
  }
}
