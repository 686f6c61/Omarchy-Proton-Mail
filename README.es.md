# Omarchy Proton Mail Notifier

[English](README.md) | **Español** | [Français](README.fr.md) | [Deutsch](README.de.md) | [Italiano](README.it.md) | [中文](README.zh.md)

Un plugin del shell de [Omarchy](https://omarchy.org) que muestra el **número
de correos sin leer de Proton Mail en la barra** (arriba a la derecha, junto
a la bandeja del sistema), despliega una lista con los **mensajes más
recientes** al hacer clic, y lanza una notificación de escritorio cuando
llega correo nuevo.

Sin extensión de navegador, sin Proton Mail Bridge — funciona con **cuentas
gratuitas y de pago de Proton** y cualquier navegador basado en Chromium
(Brave, Chrome, Chromium, Edge).

El widget habla **English, Español, Français, Deutsch, Italiano y 中文**
(inglés por defecto), y todo — intervalo de sondeo, tamaño del desplegable,
nickname de la cabecera, notificaciones, idioma — se configura en caliente
con `omarchy bar set`.

## Capturas

![Desplegable con mensajes recientes](screenshots/dropdown.jpg)

![Tooltip del widget en la barra](screenshots/widget-tooltip.jpg)

## Cómo funciona

```
Webapp de Proton Mail (perfil de navegador dedicado, ventana --app)
título: "(3) Inbox | … | Proton Mail"
        │
        ├─ hyprctl clients -j ──► omarchy-protonmail-unread ──► badge 󰇮 N + notificación
        │   (títulos de ventana)   (cada intervalSec)
        │
        ├─ CDP (ephemeral) ──► omarchy-protonmail-recent ──► desplegable con los últimos N
        │   (protocolo DevTools)     (al abrir / cambiar el contador)
        │
        └─ CDP (ephemeral) ──► omarchy-protonmail-linkguard ──► los enlaces externos se
            (protocolo DevTools)     (mientras la webapp está abierta)   abren en el navegador por defecto
```

- **Número de no leídos**: Proton Mail lo pone en el título de la página como
  `(N)`, y Hyprland expone los títulos de ventana vía `hyprctl clients -j`.
  Funciona con la ventana de la webapp *y* con cualquier pestaña normal del
  navegador que tenga Proton Mail abierto.
- **Mensajes recientes**: la webapp instalada corre en un perfil de navegador
  dedicado con un puerto DevTools efímero (`--remote-debugging-port=0`,
  anotado en `DevToolsActivePort`). El plugin lee las
  filas de la bandeja directamente de la página por CDP — Python solo con la
  librería estándar, nada más que instalar.
- **Enlaces externos**: los enlaces pulsados dentro de un mensaje se abren en
  el navegador por defecto (tu perfil principal, con cookies y sesiones) en
  lugar del perfil dedicado de la webapp. `omarchy-protonmail-linkguard`
  vigila las pestañas vía CDP, abre las que no son de Proton con `xdg-open` y
  las cierra en la webapp. Solo corre mientras Proton Mail está abierto.

## Instalación

```bash
git clone https://github.com/686f6c61/Omarchy-Proton-Mail.git
cd Omarchy-Proton-Mail
./install.sh
```

El instalador:

1. Descarga el icono de Proton y crea el lanzador de la **webapp "Proton
   Mail"** (`omarchy webapp install`) con perfil dedicado + puerto CDP.
2. Instala `omarchy-protonmail-unread` y `omarchy-protonmail-recent` en
   `~/.local/share/omarchy-protonmail/`.
3. Instala el plugin del shell en
   `~/.config/omarchy/plugins/686f6c61.proton-mail/`.
4. Activa el widget en la **sección derecha** de la barra (con copia de
   seguridad de `~/.config/omarchy/shell.json`) y reinicia el shell.
5. Te pregunta el **idioma** y un **nickname** opcional (interactivo).
   Alternativa no interactiva:
   `./install.sh --language es --nickname "Mi correo"`

Después lanza **Proton Mail** desde el menú de aplicaciones (SUPER + ESPACIO)
e inicia sesión. El perfil dedicado implica que inicias sesión una vez, de
forma independiente a tu navegador principal.

## Uso

- **Clic izquierdo en el widget**: desplegable con los últimos N mensajes
  (remitente, asunto, hora; los no leídos en negrita). Clic en un mensaje
  para saltar a la ventana de Proton Mail — se enfoca la existente, nunca se
  duplica.
- La cabecera del desplegable muestra el logo de Proton Mail, y la fila
  inferior tiene un interruptor de **Pausar notificaciones** que cambia el
  ajuste `notify` en vivo.
- Los enlaces pulsados dentro de un mensaje se abren en tu **navegador por
  defecto** (perfil principal), no en el perfil dedicado de la webapp.
- Con `recentCount: 0` el desplegable se desactiva y el clic izquierdo solo
  enfoca la ventana de Proton Mail (modo avisador puro).
- **Clic derecho/central**: refrescar ahora.
- Al hacer clic en la notificación también se abre/enfoca Proton Mail.

Estados del widget (siempre visible mientras esté activado):

| Estado               | Significado                       |
|----------------------|-----------------------------------|
| 󰇯 atenuado           | La ventana de Proton Mail no está abierta |
| 󰇯 normal             | Abierto, sin correos sin leer     |
| 󰇮 N (acento)         | N sin leer — notificación lanzada |
| 󰇮 99+ (acento)       | Más de 99 sin leer                |

## Configuración

La forma más rápida es el comando `omarchy bar set` (aplica en caliente, sin
reiniciar):

```bash
omarchy bar set 686f6c61.proton-mail recentCount 7
omarchy bar set 686f6c61.proton-mail nickname "Mi correo"
omarchy bar set 686f6c61.proton-mail language es
omarchy bar set 686f6c61.proton-mail intervalSec 10
omarchy bar set 686f6c61.proton-mail notify false
```

También puedes editar la entrada del widget en `~/.config/omarchy/shell.json`:

```json
{ "id": "686f6c61.proton-mail", "intervalSec": 5, "recentCount": "5", "notify": true, "nickname": "", "language": "en" }
```

- `intervalSec` (2–60, por defecto 5): intervalo de sondeo del número de no
  leídos.
- `recentCount` (0–20, por defecto 5): mensajes listados en el desplegable.
  `0` desactiva el desplegable (solo avisador).
- `notify` (por defecto true): notificación de escritorio cuando sube el
  número.
- `nickname` (por defecto vacío): texto personalizado para la cabecera del
  desplegable cuando no hay correos sin leer. Vacío muestra el texto por
  defecto del idioma elegido ("Bandeja al día" en español).
- `language` (`en`/`es`/`fr`/`de`/`it`/`zh`, por defecto `en`): idioma del
  widget, el desplegable y las notificaciones (English, Español, Français,
  Deutsch, Italiano, 中文).

## Solución de problemas

- **El widget no aparece tras instalar**: ejecuta `omarchy restart shell`
  (el cargador de QML cachea fallos contra las URLs de plugins; un shell
  nuevo las limpia).
- **El widget no recoge los cambios de QML al desarrollar**: misma causa —
  la recarga en caliente por inotify puede seguir sirviendo bytecode cacheado
  para la URL del plugin. Ejecuta `omarchy restart shell` tras editar los
  archivos del plugin.
- **El desplegable pide abrir la app**: inicia sesión dentro de la ventana de
  la webapp "Proton Mail" (el perfil dedicado tiene su propia sesión) y usa
  esa ventana como tu app de correo — los mensajes solo se leen de ella.
- **Desplegable vacío estando logueado**: puede que la extracción necesite
  reajustarse a tu versión de Proton — ejecuta
  `~/.local/share/omarchy-protonmail/omarchy-protonmail-recent --dump` y abre
  un issue con la salida.
- El badge depende del formato `(N)` del título de página de Proton Mail; la
  lógica está en `bin/omarchy-protonmail-unread`.

## Desinstalación

```bash
omarchy webapp remove "Proton Mail"
rm -rf ~/.config/omarchy/plugins/686f6c61.proton-mail ~/.local/share/omarchy-protonmail
# luego elimina la entrada { "id": "686f6c61.proton-mail" } de ~/.config/omarchy/shell.json
# (o restaura la copia shell.json.bak.<timestamp> que creó install.sh)
omarchy restart shell
```

## Licencia

[MIT](LICENSE) © 686f6c61 <github@00b.tech>
