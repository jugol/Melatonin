<p align="center">
  <img src="docs/images/icon.png" width="128" alt="Icono de Melatonin">
</p>

<h1 align="center">Melatonin</h1>

<p align="center">
  <b>Cierra la tapa. Tus agentes siguen trabajando.</b><br>
  Una pequeña app de la barra de menús de macOS que mantiene tu MacBook despierto con la tapa cerrada<br>
  —con batería y sin pantalla externa— mientras Claude Code, Codex y compañía terminan su trabajo.
</p>

<p align="center">
  <a href="https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg"><b>Descargar</b></a> ·
  <a href="https://jugol.github.io/Melatonin/">Sitio web</a>
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português</a> ·
  <a href="README.ru.md">Русский</a> ·
  <a href="README.ar.md">العربية</a> ·
  <a href="README.hi.md">हिन्दी</a> ·
  <a href="README.id.md">Bahasa Indonesia</a>
</p>

<p align="center">
  <img src="docs/images/notch-expanded-on.png" width="640" alt="Melatonin desplegado en el notch">
</p>

## ¿Por qué?

Lanzas una tarea larga en Claude Code, cierras la tapa y te vas. macOS entra en reposo y la ejecución se queda a medias.

Las apps para mantener el Mac despierto, como `caffeinate`, KeepingYouAwake y casi todas sus primas, usan aserciones de energía (power assertions), y macOS las ignora en cuanto cierras la tapa. Lo único que de verdad evita el reposo al cerrar la tapa es `pmset disablesleep`, y eso requiere permisos de root. Melatonin lo envuelve en una pequeña herramienta auxiliar con privilegios y salvaguardas estrictas, y pone el interruptor donde lo vas a ver: en el notch.

## Funciones

- **Vive en tu notch.** Cuando Melatonin está activado, una lámpara cálida brilla junto a la cámara con el tiempo restante. Pasa el puntero por encima para desplegar todos los controles. En pantallas sin notch, la píldora cuelga de la barra de menús.
- **Interruptor en la barra de menús.** Si ves solo el contorno de una media luna, tu Mac se dormirá; si la media luna sostiene una lámpara ámbar, no.
- **Temporizadores.** 1, 2, 4 u 8 horas, o hasta que lo desactives.
- **Automático con agentes de IA.** Se mantiene despierto solo mientras un agente está trabajando de verdad: Claude Code, Codex, Hermes, OpenCode, T3 Code, Gemini CLI, Cursor Agent, Amp, Goose o Crush. La detección mira la actividad de CPU de todo el árbol de procesos de cada agente, así que un agente esperando en su prompt no cuenta. Los agentes que lanza T3 Code se atribuyen a T3 Code.
- **Seguir conectado.** Si se cae internet mientras Melatonin mantiene despierto tu Mac, por ejemplo cuando cierras la tapa y sales del alcance del Wi-Fi de la oficina, reinicia el Wi-Fi para que macOS vuelva a conectarse a una red guardada cercana, como el punto de acceso de tu teléfono. macOS no permite que las apps elijan una red Wi-Fi por su nombre, así que asegúrate de que el punto de acceso esté guardado con **Conectarse automáticamente a esta red** activado. El botón **Probar ahora** te muestra que funciona.
- **La seguridad, lo primero.**
  - Con batería, se desactiva al llegar al mínimo que elijas (20 % por defecto).
  - Se desactiva si tu Mac se calienta. Un portátil encendido dentro de una mochila cerrada es la receta perfecta para cocinar la batería.
  - Si Melatonin se cierra, sufre un fallo o se fuerza su salida, la herramienta auxiliar restablece el reposo normal al instante. Tras un reinicio, también lo deja todo en orden.
- **Nativa y ligera.** SwiftUI y AppKit, sin Electron y alrededor de un 0 % de CPU cuando está inactiva. Binario universal para Apple silicon e Intel.
- **Habla tu idioma.** English, 한국어, 简体中文, 日本語, Español, Français, Deutsch, Português (Brasil), Русский, العربية, हिन्दी y Bahasa Indonesia. Por defecto usa el idioma de macOS; puedes elegir otro en **⋯ › Idioma**.

<p align="center">
  <img src="docs/images/menu-on-light.png" width="300" alt="Menú, despierto">
  <img src="docs/images/menu-off-dark.png" width="300" alt="Menú, reposo permitido">
</p>

<p align="center">
  <img src="docs/images/notch-compact.png" width="640" alt="Píldora compacta en el notch con cuenta atrás">
</p>

<p align="center">
  <img src="docs/images/connection-light.png" width="420" alt="Ajustes de «Seguir conectado»">
</p>

## Instalación

Requiere macOS 14 Sonoma o posterior.

**Descarga:** baja [Melatonin.dmg](https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg) de la [última versión](https://github.com/jugol/Melatonin/releases/latest) y arrastra la app a Aplicaciones.

**Homebrew:**

```bash
brew install --cask jugol/tap/melatonin
```

**Primera apertura:** las primeras versiones aún no están notarizadas por Apple, así que macOS bloqueará la app la primera vez que la abras. Ve a **Ajustes del Sistema › Privacidad y seguridad** y haz clic en **Abrir igualmente**, o ejecuta:

```bash
xattr -dr com.apple.quarantine /Applications/Melatonin.app
```

La primera vez que actives Melatonin, macOS te pedirá la contraseña una sola vez para instalar la herramienta auxiliar.

**Desde el código fuente:** necesitas las Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/jugol/Melatonin.git
cd Melatonin
make run
```

## Cómo funciona

```
Melatonin.app  ──XPC──▶  io.github.jugol.melatonin.helper (root, launchd)
  UI, timers,              pmset -a disablesleep 1 / 0
  safety checks,           …and back to 0 when the app disconnects
  connection watch         networksetup -setairportpower (Wi-Fi off and on)
```

- **La herramienta auxiliar expone lo mínimo.** Toda su interfaz se reduce a `setSleepDisabled(Bool)` más dos llamadas de Wi-Fi: reiniciar el Wi-Fi y conectarse a una red ya guardada en el Mac. No tiene acceso a la shell ni ejecuta comandos arbitrarios. Compruébalo en [`Sources/MelatoninHelper/main.swift`](Sources/MelatoninHelper/main.swift).
- **Solo habla con Melatonin.** Las conexiones XPC deben cumplir un requisito de firma de código ligado al identificador de paquete de la app.
- **Es a prueba de fallos.** El reposo solo sigue desactivado mientras una app conectada lo pida. Si se corta la conexión, vuelve el reposo. Un archivo marcador cubre los reinicios de la herramienta auxiliar y del sistema.
- **La instalación y la desinstalación son simples scripts de shell** que puedes leer: [`Support/install-helper.sh`](Support/install-helper.sh) y [`Support/uninstall-helper.sh`](Support/uninstall-helper.sh).

## Desinstalar

Elige **⋯ › Desinstalar herramienta auxiliar…** en el menú y luego borra la app. Si prefieres eliminar la herramienta auxiliar a mano:

```bash
sudo bash Support/uninstall-helper.sh
```

## Desarrollo

```bash
make app        # build build/Melatonin.app (ad-hoc signed)
make run        # build and launch
make package    # universal build, DMG and zip in dist/
make icon       # regenerate the app icon from Scripts/make-icon.swift
swift build && .build/debug/Melatonin --snapshot /tmp/shots   # render every UI state to PNGs
swift build && .build/debug/Melatonin --agents                 # watch agent detection live
```

Después de añadir o editar una traducción, ejecuta `python3 Scripts/check-localizations.py` para detectar textos que falten o marcadores que no coincidan.

Para firmar con un Developer ID, define `SIGN_IDENTITY` y fija tu ID de equipo en `HelperConstants.clientRequirement`:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make app
```

## Hoja de ruta

- [ ] Versiones firmadas y notarizadas, un cask de Homebrew y actualizaciones con Sparkle
- [ ] Seguir conectado: elegir a qué red guardada volver a conectarse (requiere acceso a la ubicación)
- [ ] Integración con los hooks de Claude Code para detectar con exactitud el inicio y el fin
- [ ] Resumen «Mientras no estabas» al abrir la tapa

## Licencia

[MIT](LICENSE)
