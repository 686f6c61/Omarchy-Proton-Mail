# Omarchy Proton Mail Notifier

[English](README.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | **Italiano** | [中文](README.zh.md)

Un plugin shell di [Omarchy](https://omarchy.org) che mostra il **conteggio
delle email Proton Mail non lette nella barra** (in alto a destra, accanto al
vassoio di sistema), apre un elenco dei **messaggi più recenti** al clic e
solleva una notifica desktop all'arrivo di nuova posta.

Nessuna estensione del browser, nessun Proton Mail Bridge — funziona con
**account Proton gratuiti e a pagamento** e qualsiasi browser basato su
Chromium (Brave, Chrome, Chromium, Edge).

Il widget parla **English, Español, Français, Deutsch, Italiano e 中文**
(inglese per impostazione predefinita), e tutto — intervallo di polling,
dimensione del menu a discesa, nickname dell'intestazione, notifiche, lingua
— è configurabile al volo tramite `omarchy bar set`.

## Screenshot

![Menu a discesa con i messaggi recenti](screenshots/dropdown.jpg)

![Tooltip del widget nella barra](screenshots/widget-tooltip.jpg)

## Come funziona

```
Proton Mail webapp (dedicated browser profile, --app window)
title: "(3) Inbox | … | Proton Mail"
        │
        ├─ hyprctl clients -j ──► omarchy-protonmail-unread ──► badge 󰇮 N + notification
        │   (window titles)          (every intervalSec)
        │
        └─ --remote-debugging-pipe ──► omarchy-protonmail-broker ──► dropdown with last N
            (CDP su fd 3/4 ereditati,             (unico client CDP, API   messages + link esterni
             nessuna porta TCP di debug)           unix socket + sweep)    al browser predefinito
```

- **Conteggio dei non letti**: Proton Mail lo inserisce nel titolo della
  pagina come `(N)`, e Hyprland espone i titoli delle finestre tramite
  `hyprctl clients -j`. Funziona sia con la finestra della webapp *sia* con
  qualsiasi scheda normale del browser che mostra Proton Mail.
- **Messaggi recenti**: la webapp viene lanciata tramite
  `omarchy-protonmail-broker` con `--remote-debugging-pipe`, quindi il
  browser parla CDP su descrittori di file ereditati dal broker — non c'è
  alcuna porta TCP di debug, né fissa né casuale, a cui altri processi
  possano collegarsi. Il broker serve le righe della posta in arrivo
  (truncate) su un socket unix (autenticato con SO_PEERCRED) a
  `omarchy-protonmail-recent` — Python solo con la libreria standard,
  nient'altro da installare.
- **Link esterni**: il broker analizza anche la lista delle schede e apre
  nel browser predefinito (il tuo profilo principale, con cookie e sessioni)
  qualsiasi scheda il cui host non sia nella lista esatta dei domini Proton,
  chiudendola nella webapp.

## Installazione

```bash
git clone https://github.com/686f6c61/Omarchy-Proton-Mail.git
cd Omarchy-Proton-Mail
./install.sh
```

L'installer:

1. Scarica l'icona di Proton e crea un lanciatore per la **webapp "Proton
   Mail"** (`omarchy webapp install`) con un profilo dedicato + porta CDP.
2. Installa `omarchy-protonmail-unread` e `omarchy-protonmail-recent` in
   `~/.local/share/omarchy-protonmail/`.
3. Installa il plugin shell in
   `~/.config/omarchy/plugins/686f6c61.proton-mail/`.
4. Abilita il widget nella **sezione destra** della barra (eseguendo prima un
   backup di `~/.config/omarchy/shell.json`) e riavvia la shell.
5. Chiede la tua **lingua** e un **nickname** opzionale (interattivo).
   Alternativa non interattiva: `./install.sh --language es --nickname "My mail"`

Poi avvia **Proton Mail** dal lanciatore di applicazioni (SUPER + SPACE) ed
effettua l'accesso. Il profilo dedicato significa che accedi una sola volta,
in modo separato dal tuo browser principale.

## Utilizzo

- **Clic sinistro sul widget**: menu a discesa con gli ultimi N messaggi
  (mittente, oggetto, orario; i non letti in grassetto). Clicca un messaggio
  per passare alla finestra di Proton Mail — quella esistente viene portata in
  primo piano, mai duplicata.
- L'intestazione del menu mostra il logo di Proton Mail, e la riga in fondo
  ha un interruttore **Metti in pausa le notifiche** che cambia
  l'impostazione `notify` al volo.
- I link cliccati dentro un messaggio si aprono nel **browser predefinito**
  (profilo principale), non nel profilo dedicato della webapp.
- Con `recentCount: "0"` il menu a discesa è disabilitato e il clic sinistro
  porta semplicemente in primo piano la finestra di Proton Mail (modalità
  notificatore puro).
- **Clic destro/centrale**: aggiorna ora.
- Anche il clic sulla notifica apre/porta in primo piano Proton Mail.

Stati del widget (sempre visibile finché abilitato):

| Stato                 | Significato                     |
|-----------------------|---------------------------------|
| 󰇯 attenuato           | Finestra di Proton Mail non aperta |
| 󰇯 normale             | Aperto, nessuna email non letta |
| 󰇮 N (accento)         | N non lette — notifica emessa   |
| 󰇮 99+ (accento)       | Più di 99 non lette             |

## Impostazioni

Il modo più rapido è il comando `omarchy bar set` (applica al volo, senza
riavvio):

```bash
omarchy bar set 686f6c61.proton-mail recentCount 7
omarchy bar set 686f6c61.proton-mail nickname "My mail"
omarchy bar set 686f6c61.proton-mail language es
omarchy bar set 686f6c61.proton-mail intervalSec 10
omarchy bar set 686f6c61.proton-mail notify false
```

Puoi anche modificare inline la voce del widget in
`~/.config/omarchy/shell.json`:

```json
{ "id": "686f6c61.proton-mail", "intervalSec": 5, "recentCount": "5", "notify": true, "nickname": "", "language": "en" }
```

- `intervalSec` (2–60, predefinito 5): intervallo di polling per il conteggio
  dei non letti.
- `recentCount` (0–20, predefinito 5): messaggi elencati nel menu a discesa.
  `0` disabilita il menu a discesa (solo notificatore).
- `notify` (predefinito true): notifica desktop quando il conteggio aumenta.
- `nickname` (predefinito vuoto): testo personalizzato per l'intestazione del
  menu a discesa quando non ci sono email non lette. Vuoto mostra il testo
  predefinito "All caught up".
- `language` (`en`/`es`/`fr`/`de`/`it`/`zh`, predefinito `en`): lingua di
  widget, menu a discesa e notifiche (English, Español, Français, Deutsch,
  Italiano, 中文).

## Risoluzione dei problemi

- **Il widget non compare dopo l'installazione**: esegui `omarchy restart
  shell` (il loader QML memorizza nella cache i fallimenti rispetto agli URL
  dei plugin; una shell nuova li elimina).
- **Il widget non recepisce le modifiche QML durante lo sviluppo**: stessa
  causa — il ricaricamento a caldo via inotify può continuare a servire
  bytecode in cache per l'URL del plugin. Esegui `omarchy restart shell` dopo
  aver modificato i file del plugin.
- **Il menu a discesa mostra la riga di accesso**: effettua l'accesso
  all'interno della finestra della webapp "Proton Mail" (il profilo dedicato
  ha una sessione propria).
- **Menu a discesa vuoto pur avendo effettuato l'accesso**: l'estrazione
  potrebbe dover essere ricalibrata rispetto alla tua versione di Proton —
  esegui `~/.local/share/omarchy-protonmail/omarchy-protonmail-recent --dump`
  e apri una issue con l'output.
- Il badge dei non letti dipende dal formato `(N)` del titolo della pagina di
  Proton Mail; la logica di corrispondenza è in
  `bin/omarchy-protonmail-unread`.

## Disinstallazione

```bash
omarchy webapp remove "Proton Mail"
rm -rf ~/.config/omarchy/plugins/686f6c61.proton-mail ~/.local/share/omarchy-protonmail
# then remove the { "id": "686f6c61.proton-mail" } entry from ~/.config/omarchy/shell.json
# (or restore the shell.json.bak.<timestamp> backup created by install.sh)
omarchy restart shell
```

## Licenza

[MIT](LICENSE) © 686f6c61 <github@00b.tech>
