<p align="center">
  <img src="docs/images/icon.png" width="128" alt="Melatonin-Symbol">
</p>

<h1 align="center">Melatonin</h1>

<p align="center">
  <b>Deckel zu. Die Agenten laufen weiter.</b><br>
  Eine winzige Menüleisten-App für macOS, die dein MacBook auch zugeklappt wach hält –<br>
  im Batteriebetrieb, ohne externen Monitor –, während Claude Code, Codex und Co. ihre Arbeit erledigen.
</p>

<p align="center">
  <a href="https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg"><b>Download</b></a> ·
  <a href="https://jugol.github.io/Melatonin/">Website</a>
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
  <img src="docs/images/notch-expanded-on.png" width="640" alt="Melatonin ausgeklappt in der Notch">
</p>

## Warum

Du startest eine lange Aufgabe in Claude Code, klappst den Deckel zu und gehst. macOS wechselt in den Ruhezustand, und der Lauf bricht ab.

Wachhalte-Apps wie `caffeinate`, KeepingYouAwake und die meisten ihrer Verwandten setzen auf Power Assertions – und die ignoriert macOS, sobald der Deckel zugeht. Das Einzige, was den Ruhezustand beim Zuklappen wirklich verhindert, ist `pmset disablesleep`, und dafür braucht es Root-Rechte. Melatonin verpackt das in ein kleines privilegiertes Hilfsprogramm mit strengen Sicherheitsvorkehrungen und legt den Schalter dorthin, wo du ihn siehst: in die Notch.

## Funktionen

- **Wohnt in deiner Notch.** Ist Melatonin eingeschaltet, leuchtet neben der Kamera eine warme Lampe und zeigt die verbleibende Zeit. Fahr mit dem Zeiger darüber, und alle Bedienelemente klappen auf. Auf Displays ohne Notch hängt die Anzeige stattdessen an der Menüleiste.
- **Schalter in der Menüleiste.** Nur der Umriss einer Mondsichel heißt: Dein Mac geht in den Ruhezustand. Hält die Sichel eine bernsteinfarbene Lampe, bleibt er wach.
- **Timer.** 1, 2, 4 oder 8 Stunden – oder bis du es ausschaltest.
- **Automatisch für KI-Agenten.** Bleibt nur wach, solange ein Agent wirklich arbeitet: Claude Code, Codex, Hermes, OpenCode, T3 Code, Gemini CLI, Cursor Agent, Amp, Goose oder Crush. Die Erkennung prüft die CPU-Aktivität im gesamten Prozessbaum jedes Agenten. Ein Agent, der untätig am Prompt wartet, zählt also nicht. Von T3 Code gestartete Agenten werden T3 Code zugerechnet.
- **Online bleiben.** Fällt das Internet aus, während Melatonin deinen Mac wach hält – zum Beispiel wenn du den Deckel zuklappst und dich aus dem Büro-WLAN entfernst –, startet es das WLAN neu, damit macOS sich wieder mit einem gespeicherten Netzwerk in Reichweite verbindet, etwa dem Hotspot deines Handys. macOS lässt Apps kein WLAN-Netzwerk nach Namen auswählen. Achte deshalb darauf, dass der Hotspot gespeichert und **Automatisch mit diesem Netzwerk verbinden** aktiviert ist. Mit der Taste **Jetzt testen** siehst du, dass es funktioniert.
- **Sicherheit zuerst.**
  - Schaltet sich im Batteriebetrieb bei einem Ladestand ab, den du festlegst (standardmäßig 20 %).
  - Schaltet sich ab, wenn dein Mac heiß wird. Ein laufender Laptop in einer geschlossenen Tasche ist der sicherste Weg, eine Batterie zu grillen.
  - Wird Melatonin beendet, stürzt es ab oder wird es zwangsweise beendet, stellt das Hilfsprogramm den normalen Ruhezustand sofort wieder her. Auch nach einem Neustart räumt es auf.
- **Nativ und schlank.** SwiftUI und AppKit, kein Electron, im Leerlauf etwa 0 % CPU. Universal Binary für Apple Silicon und Intel.
- **Spricht deine Sprache.** English, 한국어, 简体中文, 日本語, Español, Français, Deutsch, Português (Brasil), Русский, العربية, हिन्दी und Bahasa Indonesia. Folgt standardmäßig der Sprache von macOS; eine andere wählst du unter **⋯ › Sprache**.

<p align="center">
  <img src="docs/images/menu-on-light.png" width="300" alt="Menü, wach">
  <img src="docs/images/menu-off-dark.png" width="300" alt="Menü, Ruhezustand erlaubt">
</p>

<p align="center">
  <img src="docs/images/notch-compact.png" width="640" alt="Kompakte Notch-Anzeige mit Countdown">
</p>

<p align="center">
  <img src="docs/images/connection-light.png" width="420" alt="Einstellungen für „Online bleiben“">
</p>

## Installation

Erfordert macOS 14 Sonoma oder neuer.

**Download:** Lade [Melatonin.dmg](https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg) aus dem [neuesten Release](https://github.com/jugol/Melatonin/releases/latest) und zieh die App in den Ordner „Programme“.

**Homebrew:**

```bash
brew install --cask jugol/tap/melatonin
```

**Erster Start:** Frühe Builds sind noch nicht von Apple notarisiert, deshalb blockiert macOS den ersten Start. Öffne **Systemeinstellungen › Datenschutz & Sicherheit** und klicke auf **Dennoch öffnen** oder führe Folgendes aus:

```bash
xattr -dr com.apple.quarantine /Applications/Melatonin.app
```

Wenn du Melatonin zum ersten Mal einschaltest, fragt macOS einmalig nach deinem Passwort, um das Hilfsprogramm zu installieren.

**Aus dem Quellcode:** Du brauchst die Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/jugol/Melatonin.git
cd Melatonin
make run
```

## So funktioniert’s

```
Melatonin.app  ──XPC──▶  io.github.jugol.melatonin.helper (root, launchd)
  UI, timers,              pmset -a disablesleep 1 / 0
  safety checks,           …and back to 0 when the app disconnects
  connection watch         networksetup -setairportpower (Wi-Fi off and on)
```

- **Das Hilfsprogramm bietet kaum Angriffsfläche.** Seine gesamte Schnittstelle besteht aus `setSleepDisabled(Bool)` plus zwei WLAN-Aufrufen: WLAN neu starten und mit einem Netzwerk verbinden, das bereits auf dem Mac gespeichert ist. Es hat keinen Shell-Zugriff und führt keine beliebigen Befehle aus. Siehe [`Sources/MelatoninHelper/main.swift`](Sources/MelatoninHelper/main.swift).
- **Es spricht nur mit Melatonin.** XPC-Verbindungen müssen eine Codesignatur-Anforderung für die Bundle-ID der App erfüllen.
- **Es ist ausfallsicher.** Der Ruhezustand bleibt nur deaktiviert, solange eine verbundene App das anfordert. Bricht die Verbindung ab, kommt der Ruhezustand zurück. Eine Markierungsdatei deckt Neustarts des Hilfsprogramms und des Macs ab.
- **Installation und Deinstallation sind einfache Shell-Skripte**, die du nachlesen kannst: [`Support/install-helper.sh`](Support/install-helper.sh) und [`Support/uninstall-helper.sh`](Support/uninstall-helper.sh).

## Deinstallation

Wähle im Menü **⋯ › Hilfsprogramm deinstallieren …** und lösche dann die App. Um das Hilfsprogramm stattdessen manuell zu entfernen:

```bash
sudo bash Support/uninstall-helper.sh
```

## Entwicklung

```bash
make app        # build build/Melatonin.app (ad-hoc signed)
make run        # build and launch
make package    # universal build, DMG and zip in dist/
make icon       # regenerate the app icon from Scripts/make-icon.swift
swift build && .build/debug/Melatonin --snapshot /tmp/shots   # render every UI state to PNGs
swift build && .build/debug/Melatonin --agents                 # watch agent detection live
```

Wenn du eine Übersetzung hinzufügst oder änderst, führe `python3 Scripts/check-localizations.py` aus, um fehlende Texte und abweichende Platzhalter zu finden.

Um mit einer Developer ID zu signieren, setze `SIGN_IDENTITY` und hinterlege deine Team-ID fest in `HelperConstants.clientRequirement`:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make app
```

## Roadmap

- [ ] Signierte, notarisierte Releases, ein Homebrew-Cask und Updates über Sparkle
- [ ] Online bleiben: auswählen, mit welchem gespeicherten Netzwerk sich der Mac wieder verbindet (erfordert Standortzugriff)
- [ ] Integration der Claude Code Hooks für exakte Start- und Stoppsignale
- [ ] Zusammenfassung „Während du weg warst“ beim Aufklappen

## Lizenz

[MIT](LICENSE)
