<p align="center">
  <img src="docs/images/icon.png" width="128" alt="Melatoninのアイコン">
</p>

<h1 align="center">Melatonin</h1>

<p align="center">
  <b>フタを閉じても、エージェントは動き続ける。</b><br>
  MacBookのフタを閉じても起きたままにしておける、小さなmacOSメニューバーアプリです。<br>
  バッテリー駆動でも外部ディスプレイなしでも、Claude CodeやCodexたちが最後まで作業をやり遂げます。
</p>

<p align="center">
  <a href="https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg"><b>ダウンロード</b></a> ·
  <a href="https://jugol.github.io/Melatonin/">ウェブサイト</a>
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
  <img src="docs/images/notch-expanded-on.png" width="640" alt="ノッチで展開したMelatonin">
</p>

## なぜ必要なのか

Claude Codeに長いタスクを任せ、フタを閉じて席を離れる。するとmacOSがスリープして、実行中の処理は止まってしまいます。

`caffeinate`やKeepingYouAwakeをはじめ、スリープ防止アプリの多くは電源アサーション（power assertion）を使っていますが、macOSはフタが閉じた瞬間にそれを無視します。フタを閉じたときのスリープを本当に止められるのは`pmset disablesleep`だけで、これにはroot権限が必要です。Melatoninはこれを厳しい安全策付きの小さな特権ヘルパーで包み、スイッチをいつでも目に入る場所、つまりノッチに置きました。

## 機能

- **ノッチに住む**：Melatoninがオンの間は、カメラの横に暖かなランプが灯り、残り時間を表示します。ポインタを重ねると、すべての操作ができるパネルに広がります。ノッチのないディスプレイでは、代わりにメニューバーから吊り下がるピル型で表示されます。
- **メニューバーのスイッチ**：三日月の輪郭だけならMacはスリープします。三日月が琥珀色のランプを抱えていれば、スリープしません。
- **タイマー**：1、2、4、8時間、またはオフにするまで。
- **AIエージェント自動モード**：Claude Code、Codex、Hermes、OpenCode、T3 Code、Gemini CLI、Cursor Agent、Amp、Goose、Crushが実際に作業している間だけ起きています。各エージェントのプロセスツリー全体のCPU使用状況を見て判定するので、プロンプトで待機しているだけのエージェントはカウントされません。T3 Codeから起動されたエージェントはT3 Codeとして扱われます。
- **オンラインを維持**：たとえばフタを閉じてオフィスのWi-Fiの圏外に出たときなど、MelatoninがMacを起こしている間にインターネットが切れると、Wi-Fiを再起動し、macOSが範囲内の保存済みネットワーク（スマートフォンのテザリングなど）に再接続できるようにします。macOSではアプリが名前を指定してWi-Fiネットワークを選ぶことができないため、テザリングを保存したうえで**このネットワークに自動接続**をオンにしておいてください。**今すぐテスト**ボタンで、実際に動く様子を確認できます。
- **安全第一**：
  - バッテリー駆動中は、設定した残量（デフォルトは20%）を下回るとオフになります。
  - Macが熱くなるとオフになります。閉じたバッグの中でノートパソコンを動かし続けるのは、バッテリーを蒸し焼きにするようなものです。
  - Melatoninが終了、クラッシュ、強制終了しても、ヘルパーがすぐに通常のスリープに戻します。再起動後もきちんと後片付けします。
- **ネイティブで軽量**：SwiftUIとAppKitで作られていて、Electronは不使用。アイドル時のCPU使用率はほぼ0%です。AppleシリコンとIntelの両方で動くユニバーサルバイナリです。
- **あなたの言語で**：English、한국어、简体中文、日本語、Español、Français、Deutsch、Português (Brasil)、Русский、العربية、हिन्दी、Bahasa Indonesiaに対応しています。デフォルトではmacOSの言語に合わせますが、**⋯ › 言語**からほかの言語も選べます。

<p align="center">
  <img src="docs/images/menu-on-light.png" width="300" alt="メニュー（起きている状態）">
  <img src="docs/images/menu-off-dark.png" width="300" alt="メニュー（スリープ可）">
</p>

<p align="center">
  <img src="docs/images/notch-compact.png" width="640" alt="カウントダウン付きのコンパクトなノッチ表示">
</p>

<p align="center">
  <img src="docs/images/connection-light.png" width="420" alt="「オンラインを維持」の設定">
</p>

## インストール

macOS 14 Sonoma以降が必要です。

**ダウンロード**：[最新リリース](https://github.com/jugol/Melatonin/releases/latest)から[Melatonin.dmg](https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg)をダウンロードし、アプリを「アプリケーション」フォルダにドラッグします。

**Homebrew**：

```bash
brew install --cask jugol/tap/melatonin
```

**初回起動**：初期のビルドはまだAppleの公証を受けていないため、初回起動時にmacOSがブロックします。**システム設定 › プライバシーとセキュリティ**を開いて**このまま開く**をクリックするか、次のコマンドを実行してください：

```bash
xattr -dr com.apple.quarantine /Applications/Melatonin.app
```

初めてMelatoninをオンにするときは、ヘルパーをインストールするためにmacOSがパスワードを一度だけ尋ねます。

**ソースからビルド**：Xcode Command Line Tools（`xcode-select --install`）が必要です。

```bash
git clone https://github.com/jugol/Melatonin.git
cd Melatonin
make run
```

## 仕組み

```
Melatonin.app  ──XPC──▶  io.github.jugol.melatonin.helper (root, launchd)
  UI, timers,              pmset -a disablesleep 1 / 0
  safety checks,           …and back to 0 when the app disconnects
  connection watch         networksetup -setairportpower (Wi-Fi off and on)
```

- **ヘルパーの窓口はごく小さい**：インターフェースは`setSleepDisabled(Bool)`と、2つのWi-Fi呼び出し（Wi-Fiの再起動と、Macに保存済みのネットワークへの接続）だけです。シェルへのアクセス権はなく、任意のコマンドも実行しません。詳しくは[`Sources/MelatoninHelper/main.swift`](Sources/MelatoninHelper/main.swift)をご覧ください。
- **Melatoninとしか通信しない**：XPC接続は、アプリのバンドルIDに対するコード署名要件を満たす必要があります。
- **フェイルセーフ**：スリープが無効になるのは、接続中のアプリがそれを求めている間だけです。接続が切れれば、スリープは元に戻ります。ヘルパーやMacの再起動には、マーカーファイルで対応します。
- **インストールとアンインストールはただのシェルスクリプト**なので、中身を読んで確認できます：[`Support/install-helper.sh`](Support/install-helper.sh)、[`Support/uninstall-helper.sh`](Support/uninstall-helper.sh)

## アンインストール

メニューで **⋯ › ヘルパーをアンインストール…** を選び、アプリを削除してください。ヘルパーを手動で削除する場合は：

```bash
sudo bash Support/uninstall-helper.sh
```

## 開発

```bash
make app        # build build/Melatonin.app (ad-hoc signed)
make run        # build and launch
make package    # universal build, DMG and zip in dist/
make icon       # regenerate the app icon from Scripts/make-icon.swift
swift build && .build/debug/Melatonin --snapshot /tmp/shots   # render every UI state to PNGs
swift build && .build/debug/Melatonin --agents                 # watch agent detection live
```

翻訳を追加・修正したら、`python3 Scripts/check-localizations.py` を実行して、抜けている文字列やプレースホルダの不一致を確認してください。

Developer IDで署名するには、`SIGN_IDENTITY`を設定し、`HelperConstants.clientRequirement`にチームIDを書き込んで固定します：

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make app
```

## ロードマップ

- [ ] 署名・公証済みのリリース、Homebrew cask、Sparkleによるアップデート
- [ ] オンラインを維持：再接続する保存済みネットワークを選べるようにする（位置情報へのアクセスが必要）
- [ ] Claude Code hooksとの連携で、開始と終了を正確に検知
- [ ] フタを開けたときに「離れていた間」のまとめを表示

## ライセンス

[MIT](LICENSE)
