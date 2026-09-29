<p align="center">
  <img src="docs/images/icon.png" width="128" alt="Melatonin icon">
</p>

<h1 align="center">Melatonin</h1>

<p align="center">
  <b>Close the lid. Keep the agents running.</b><br>
  A tiny macOS menu bar app that keeps your MacBook awake with the lid closed —<br>
  on battery, no external display — while Claude Code, Codex and friends finish their work.
</p>

<p align="center">
  <a href="https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg"><b>Download</b></a> ·
  <a href="https://jugol.github.io/Melatonin/">Website</a> ·
  <a href="README.ko.md">한국어</a>
</p>

<p align="center">
  <img src="docs/images/notch-expanded-on.png" width="640" alt="Melatonin expanded in the notch">
</p>

## Why

You start a long task in Claude Code, close the lid, and walk away. macOS goes to sleep and the run dies.

Keep-awake apps like `caffeinate`, KeepingYouAwake and most of their cousins use power assertions, and macOS ignores those the moment the lid closes. The only thing that actually stops lid-close sleep is `pmset disablesleep`, and that needs root. Melatonin wraps it in a small privileged helper with strict safety rails and puts the switch where you'll see it: in the notch.

## Features

- **Lives in your notch.** When Melatonin is on, a warm lamp glows beside the camera with the time left. Hover to expand the full control surface. On displays without a notch, the pill hangs from the menu bar instead.
- **Menu bar switch.** A crescent outline means your Mac will sleep; a crescent holding an amber lamp means it won't.
- **Timers.** 1, 2, 4 or 8 hours, or until you turn it off.
- **Auto for AI agents.** Stays awake only while an agent is actually working: Claude Code, Codex, Hermes, OpenCode, T3 Code, Gemini CLI, Cursor Agent, Amp, Goose or Crush. Detection looks at CPU activity across each agent's process tree, so an agent sitting idle at its prompt doesn't count. Agents launched by T3 Code are credited to T3 Code.
- **Stay online.** Pick backup networks from the Wi-Fi networks your Mac already knows, drag them into priority order, and mark your phone's hotspot. If the internet drops while Melatonin is keeping your Mac awake, it joins the next network on the list using the saved password.
- **Safety first.**
  - Turns off at a battery floor you choose (20% by default) when on battery.
  - Turns off if your Mac gets hot. A running laptop in a closed bag is how you cook a battery.
  - If Melatonin quits, crashes or is force-killed, the helper restores normal sleep immediately. After a reboot it cleans up too.
- **Native and light.** SwiftUI and AppKit, no Electron, about 0% CPU when idle. Universal binary for Apple silicon and Intel.
- **Speaks your language.** English, 한국어, 简体中文, 日本語, Español, Français, Deutsch, Português (Brasil), Русский, العربية, हिन्दी and Bahasa Indonesia.

<p align="center">
  <img src="docs/images/menu-on-light.png" width="300" alt="Menu, awake">
  <img src="docs/images/menu-off-dark.png" width="300" alt="Menu, sleep allowed">
</p>

<p align="center">
  <img src="docs/images/notch-compact.png" width="640" alt="Compact notch pill with countdown">
</p>

<p align="center">
  <img src="docs/images/connection-light.png" width="420" alt="Stay online settings">
</p>

## Install

Requires macOS 14 Sonoma or later.

**Download:** grab [Melatonin.dmg](https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg) from the [latest release](https://github.com/jugol/Melatonin/releases/latest) and drag the app to Applications.

**Homebrew:**

```bash
brew install --cask jugol/tap/melatonin
```

**First launch:** early builds aren't notarized by Apple yet, so macOS stops the first launch. Open **System Settings › Privacy & Security** and click **Open Anyway**, or run:

```bash
xattr -dr com.apple.quarantine /Applications/Melatonin.app
```

The first time you turn Melatonin on, macOS asks for your password once to install the helper.

**From source:** you need the Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/jugol/Melatonin.git
cd Melatonin
make run
```

## How it works

```
Melatonin.app  ──XPC──▶  io.github.jugol.melatonin.helper (root, launchd)
  UI, timers,              pmset -a disablesleep 1 / 0
  safety checks,           …and back to 0 when the app disconnects
  connection watch         networksetup -setairportnetwork (saved networks only)
```

- **The helper has a tiny surface.** Its whole interface is `setSleepDisabled(Bool)` and `joinWiFi(ssid)`, and it refuses any network that isn't already saved on the Mac. It has no shell access and runs no arbitrary commands. See [`Sources/MelatoninHelper/main.swift`](Sources/MelatoninHelper/main.swift).
- **It only talks to Melatonin.** XPC connections must satisfy a code-signing requirement for the app's bundle identifier.
- **It's fail-safe.** Sleep stays disabled only while a connected app asks for it. When the connection drops, sleep comes back. A marker file covers helper restarts and reboots.
- **Install and uninstall are plain shell scripts** you can read: [`Support/install-helper.sh`](Support/install-helper.sh) and [`Support/uninstall-helper.sh`](Support/uninstall-helper.sh).

## Uninstall

Choose **⋯ › Uninstall helper…** in the menu, then delete the app. To remove the helper by hand instead:

```bash
sudo bash Support/uninstall-helper.sh
```

## Development

```bash
make app        # build build/Melatonin.app (ad-hoc signed)
make run        # build and launch
make package    # universal build, DMG and zip in dist/
make icon       # regenerate the app icon from Scripts/make-icon.swift
swift build && .build/debug/Melatonin --snapshot /tmp/shots   # render every UI state to PNGs
swift build && .build/debug/Melatonin --agents                 # watch agent detection live
```

To sign with a Developer ID, set `SIGN_IDENTITY` and pin your team ID in `HelperConstants.clientRequirement`:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make app
```

## Roadmap

- [ ] Signed, notarized releases, a Homebrew cask and Sparkle updates
- [ ] Stay online: move back to the preferred network when it returns
- [ ] Claude Code hooks integration for exact start and stop signals
- [ ] "While you were away" summary when you open the lid

## License

[MIT](LICENSE)
