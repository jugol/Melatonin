<p align="center">
  <img src="docs/images/icon.png" width="128" alt="Melatonin 图标">
</p>

<h1 align="center">Melatonin</h1>

<p align="center">
  <b>合上盖子，智能体照常运行。</b><br>
  一款小巧的 macOS 菜单栏应用，让 MacBook 合盖后依然保持唤醒——<br>
  用电池供电、不接外接显示器也没问题——Claude Code、Codex 等工具可以安心把活干完。
</p>

<p align="center">
  <a href="https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg"><b>下载</b></a> ·
  <a href="https://jugol.github.io/Melatonin/">官网</a>
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
  <img src="docs/images/notch-expanded-on.png" width="640" alt="在刘海中展开的 Melatonin">
</p>

## 为什么需要它

你让 Claude Code 跑一个耗时很长的任务，合上盖子就走开了。结果 macOS 进入睡眠，任务也跟着中断。

`caffeinate`、KeepingYouAwake 以及大多数同类防睡眠应用用的都是电源断言（power assertion），而一旦合盖，macOS 就会直接忽略它们。真正能阻止合盖睡眠的只有 `pmset disablesleep`，而它需要 root 权限。Melatonin 把它封装进一个带有严格安全防护的小型特权辅助程序，并把开关放在你一眼就能看到的地方：刘海里。

## 功能

- **住在刘海里**：Melatonin 开启时，摄像头旁会亮起一盏暖色小灯，并显示剩余时间。将指针悬停在上面，即可展开完整的控制面板。在没有刘海的显示器上，这枚胶囊会改为挂在菜单栏下方。
- **菜单栏开关**：只有月牙轮廓时，Mac 会进入睡眠；月牙里亮着一盏琥珀色小灯时，就不会。
- **定时**：1、2、4 或 8 小时，或者一直保持到你手动关闭。
- **AI 智能体自动模式**：只在智能体真正工作时保持唤醒，支持 Claude Code、Codex、Hermes、OpenCode、T3 Code、Gemini CLI、Cursor Agent、Amp、Goose 和 Crush。检测时会查看每个智能体整个进程树的 CPU 活动，所以停在提示符前闲着的智能体不算在内。由 T3 Code 启动的智能体会算在 T3 Code 名下。
- **保持在线**：如果在 Melatonin 保持 Mac 唤醒期间断网，例如你合上盖子、走出了办公室 Wi-Fi 的覆盖范围，它会重启 Wi-Fi，让 macOS 重新加入范围内已存储的网络，比如你的手机热点。macOS 不允许应用按名称选择 Wi-Fi 网络，所以请确保热点已经存储，并开启了**自动加入此网络**。点一下**立即测试**按钮，就能看到它的实际效果。
- **安全第一**：
  - 使用电池时，电量降到你设定的下限（默认 20%）就会自动关闭。
  - Mac 过热时会自动关闭。运行中的笔记本闷在合上的包里，电池就是这么被烤坏的。
  - 如果 Melatonin 退出、崩溃或被强制结束，辅助程序会立即恢复正常睡眠。重启后它也会自动清理。
- **原生且轻巧**：基于 SwiftUI 和 AppKit，不用 Electron，空闲时 CPU 占用约为 0%。通用二进制，同时支持 Apple 芯片和 Intel。
- **说你的语言**：支持 English、한국어、简体中文、日本語、Español、Français、Deutsch、Português (Brasil)、Русский、العربية、हिन्दी 和 Bahasa Indonesia。默认跟随 macOS 的语言，也可以在 **⋯ › 语言** 中选择其他语言。

<p align="center">
  <img src="docs/images/menu-on-light.png" width="300" alt="菜单：保持唤醒">
  <img src="docs/images/menu-off-dark.png" width="300" alt="菜单：允许睡眠">
</p>

<p align="center">
  <img src="docs/images/notch-compact.png" width="640" alt="带倒计时的紧凑刘海胶囊">
</p>

<p align="center">
  <img src="docs/images/connection-light.png" width="420" alt="“保持在线”设置">
</p>

## 安装

需要 macOS 14 Sonoma 或更高版本。

**下载**：从[最新发行版](https://github.com/jugol/Melatonin/releases/latest)中下载 [Melatonin.dmg](https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg)，然后把应用拖到“应用程序”文件夹。

**Homebrew**：

```bash
brew install --cask jugol/tap/melatonin
```

**首次启动**：早期版本尚未经过 Apple 公证，所以 macOS 会拦下首次启动。打开**系统设置 › 隐私与安全性**，点按**仍要打开**；或者运行：

```bash
xattr -dr com.apple.quarantine /Applications/Melatonin.app
```

首次开启 Melatonin 时，macOS 会请你输入一次密码，用来安装辅助程序。

**从源码构建**：需要先安装 Xcode Command Line Tools（`xcode-select --install`）。

```bash
git clone https://github.com/jugol/Melatonin.git
cd Melatonin
make run
```

## 工作原理

```
Melatonin.app  ──XPC──▶  io.github.jugol.melatonin.helper (root, launchd)
  UI, timers,              pmset -a disablesleep 1 / 0
  safety checks,           …and back to 0 when the app disconnects
  connection watch         networksetup -setairportpower (Wi-Fi off and on)
```

- **辅助程序的暴露面极小**：它的全部接口只有 `setSleepDisabled(Bool)`，外加两个 Wi-Fi 调用：重启 Wi-Fi，以及加入这台 Mac 上已存储的网络。它没有 shell 访问权限，也不会执行任意命令。详见 [`Sources/MelatoninHelper/main.swift`](Sources/MelatoninHelper/main.swift)。
- **它只和 Melatonin 通信**：XPC 连接必须满足针对本应用 Bundle ID 的代码签名要求。
- **故障时自动恢复**：只有在已连接的应用提出请求时，睡眠才会保持禁用。连接一旦断开，睡眠就会恢复。辅助程序重启和系统重启的情况则由一个标记文件兜底。
- **安装和卸载都是普通的 shell 脚本**，你可以直接查看：[`Support/install-helper.sh`](Support/install-helper.sh) 和 [`Support/uninstall-helper.sh`](Support/uninstall-helper.sh)。

## 卸载

在菜单中选择 **⋯ › 卸载辅助程序…**，然后删除应用。如果想手动移除辅助程序：

```bash
sudo bash Support/uninstall-helper.sh
```

## 开发

```bash
make app        # build build/Melatonin.app (ad-hoc signed)
make run        # build and launch
make package    # universal build, DMG and zip in dist/
make icon       # regenerate the app icon from Scripts/make-icon.swift
swift build && .build/debug/Melatonin --snapshot /tmp/shots   # render every UI state to PNGs
swift build && .build/debug/Melatonin --agents                 # watch agent detection live
```

添加或修改翻译后，运行 `python3 Scripts/check-localizations.py` 检查缺失的字符串和不匹配的占位符。

如需使用 Developer ID 签名，请设置 `SIGN_IDENTITY`，并在 `HelperConstants.clientRequirement` 中固定填入你的团队 ID：

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make app
```

## 路线图

- [ ] 经过签名和公证的发行版、Homebrew cask，以及 Sparkle 自动更新
- [ ] 保持在线：自行选择要重新加入哪个已存储的网络（需要定位权限）
- [ ] 集成 Claude Code hooks，获取精确的开始和结束信号
- [ ] 打开盖子时显示“离开期间”摘要

## 许可证

[MIT](LICENSE)
