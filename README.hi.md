<p align="center">
  <img src="docs/images/icon.png" width="128" alt="Melatonin आइकन">
</p>

<h1 align="center">Melatonin</h1>

<p align="center">
  <b>ढक्कन बंद करें, एजेंट चलते रहें।</b><br>
  macOS के लिए एक छोटा-सा मेन्यू बार ऐप, जो ढक्कन बंद होने पर भी आपके MacBook को जगाए रखता है —<br>
  बैटरी पर, बिना एक्सटर्नल डिस्प्ले के — जब तक Claude Code, Codex और बाकी एजेंट अपना काम पूरा करते हैं।
</p>

<p align="center">
  <a href="https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg"><b>डाउनलोड</b></a> ·
  <a href="https://jugol.github.io/Melatonin/">वेबसाइट</a>
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
  <img src="docs/images/notch-expanded-on.png" width="640" alt="नॉच में पूरा खुला Melatonin">
</p>

## क्यों

आप Claude Code में कोई लंबा काम शुरू करते हैं, ढक्कन बंद करते हैं और उठकर चले जाते हैं। macOS स्लीप में चला जाता है और काम बीच में ही रुक जाता है।

`caffeinate`, KeepingYouAwake और ज़्यादातर ऐसे ही दूसरे ऐप Mac को जगाए रखने के लिए power assertion का इस्तेमाल करते हैं, लेकिन ढक्कन बंद होते ही macOS उन्हें अनदेखा कर देता है। ढक्कन बंद होने पर स्लीप को असल में सिर्फ़ `pmset disablesleep` ही रोक पाता है, और उसके लिए root एक्सेस चाहिए। Melatonin इसे root अधिकारों वाले एक छोटे हेल्पर में रखता है, जिस पर सख़्त सुरक्षा पाबंदियाँ लगी हैं, और स्विच को वहाँ रखता है जहाँ आपकी नज़र पड़े: नॉच में।

## फ़ीचर्स

- **आपके नॉच में रहता है।** Melatonin चालू होने पर कैमरे के बगल में एक गर्म रोशनी वाला लैंप जलता है और बचा हुआ समय दिखता है। उस पर माउस ले जाते ही पूरा कंट्रोल पैनल खुल जाता है। जिन डिस्प्ले में नॉच नहीं है, वहाँ यह पिल मेन्यू बार से लटकी दिखती है।
- **मेन्यू बार स्विच।** आधे चाँद की सिर्फ़ आउटलाइन का मतलब है कि आपका Mac स्लीप में चला जाएगा; आधे चाँद में एम्बर लैंप दिखे, तो मतलब वह जागता रहेगा।
- **टाइमर।** 1, 2, 4 या 8 घंटे, या जब तक आप खुद बंद न करें।
- **चाँद, ऑटो, लैंप।** लैंप के नीचे एक ही स्विच: **बंद** पर Mac सामान्य रूप से स्लीप करता है, **ऑटो** पर सिर्फ़ एजेंट के काम करने तक जागा रहता है, **चालू** पर टाइमर खत्म होने तक जागा रहता है और फिर पिछले मोड पर लौट आता है।
- **AI एजेंट के लिए ऑटो।** Mac तभी जागता रहता है जब कोई एजेंट सच में काम कर रहा हो: Claude Code, Codex, Hermes, OpenCode, T3 Code, Gemini CLI, Cursor Agent, Amp, Goose या Crush। पहचान के लिए हर एजेंट के पूरे process tree की CPU गतिविधि देखी जाती है, इसलिए प्रॉम्प्ट पर खाली बैठा एजेंट नहीं गिना जाता। Claude Code और Codex के सेशन लॉग भी पढ़े जाते हैं, इसलिए मॉडल का लंबा जवाब, चुपचाप चलती कमांड या बैकग्राउंड सबएजेंट भी काम में गिने जाते हैं। T3 Code से चलाए गए एजेंट T3 Code के खाते में गिने जाते हैं।
- **ऑनलाइन रहें।** Melatonin जब आपके Mac को जगाए रखता है और इंटरनेट कट जाता है, जैसे ढक्कन बंद करके ऑफ़िस के Wi-Fi से बाहर निकलने पर, तो यह आपके सेव किए गए नेटवर्क में से चुनी गई प्राथमिकता सूची में रेंज में मौजूद पहले नेटवर्क से जुड़ जाता है, जैसे आपके फ़ोन का हॉटस्पॉट। नाम से नेटवर्क चुनने के लिए लोकेशन की अनुमति चाहिए, क्योंकि macOS Wi-Fi के नाम सिर्फ़ उन्हीं ऐप को दिखाता है जिनके पास यह अनुमति हो; आपकी लोकेशन कभी इस्तेमाल नहीं होती। कोई भी काम न करे तो यह Wi-Fi को रीस्टार्ट करता है ताकि macOS खुद किसी सेव किए गए नेटवर्क से जुड़ जाए।
- **आपकी गैरमौजूदगी में।** Mac पर लौटने पर नॉच बताता है कि क्या हुआ: Melatonin ने कितनी देर जगाए रखा, किन एजेंट ने कितनी देर काम किया, Wi-Fi कितनी बार कटकर फिर जुड़ा और कितनी बैटरी खर्च हुई।
- **सुरक्षा सबसे पहले।**
  - बैटरी पर चलते समय, बैटरी आपकी चुनी हुई सीमा (डिफ़ॉल्ट 20%) तक पहुँचते ही यह बंद हो जाता है।
  - Mac गर्म होने पर यह बंद हो जाता है। बंद बैग में चालू लैपटॉप रखना बैटरी को पका देने का पक्का तरीका है।
  - अगर Melatonin बंद हो जाए, क्रैश हो जाए या उसे ज़बरदस्ती बंद किया जाए, तो हेल्पर तुरंत सामान्य स्लीप वापस चालू कर देता है। रीबूट के बाद भी यह सब ठीक कर देता है।
- **नेटिव और हल्का।** SwiftUI और AppKit, कोई Electron नहीं, खाली बैठे होने पर लगभग 0% CPU। Apple सिलिकॉन और Intel दोनों के लिए यूनिवर्सल बाइनरी।
- **आपकी भाषा बोलता है।** English, 한국어, 简体中文, 日本語, Español, Français, Deutsch, Português (Brasil), Русский, العربية, हिन्दी और Bahasa Indonesia। डिफ़ॉल्ट रूप से यह आपकी macOS भाषा अपनाता है; कोई और भाषा चाहिए तो **⋯ › भाषा** में चुनें।

<p align="center">
  <img src="docs/images/menu-on-light.png" width="300" alt="मेन्यू, जाग रहा है">
  <img src="docs/images/menu-off-dark.png" width="300" alt="मेन्यू, स्लीप की अनुमति है">
</p>

<p align="center">
  <img src="docs/images/notch-compact.png" width="640" alt="काउंटडाउन के साथ छोटी नॉच पिल">
</p>

<p align="center">
  <img src="docs/images/notch-recap.png" width="640" alt="नॉच में गैरमौजूदगी का सारांश">
</p>

<p align="center">
  <img src="docs/images/connection-light.png" width="420" alt="ऑनलाइन रहें की सेटिंग">
</p>

## इंस्टॉल

macOS 14 Sonoma या उसके बाद का वर्ज़न चाहिए।

**डाउनलोड:** [Melatonin.dmg](https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg) को [लेटेस्ट रिलीज़](https://github.com/jugol/Melatonin/releases/latest) से डाउनलोड करें और ऐप को ऐप्लिकेशन फ़ोल्डर में ड्रैग करें।

**Homebrew:**

```bash
brew install --cask jugol/tap/melatonin
```

रिलीज़ Developer ID से साइन और Apple से नोटराइज़ की गई हैं, इसलिए ये किसी भी दूसरे ऐप की तरह सीधे खुलती हैं।

Melatonin खुद अपडेट होता है। नया वर्ज़न आने पर मेन्यू के ऊपर एक छोटा बैज दिखता है; आप **⋯ › अपडेट देखें…** भी चुन सकते हैं।

पहली बार Melatonin चालू करने पर, हेल्पर इंस्टॉल करने के लिए macOS एक बार आपका पासवर्ड माँगता है।

**सोर्स से:** इसके लिए Xcode Command Line Tools (`xcode-select --install`) चाहिए।

```bash
git clone https://github.com/jugol/Melatonin.git
cd Melatonin
make run
```

## यह कैसे काम करता है

```
Melatonin.app  ──XPC──▶  io.github.jugol.melatonin.helper (root, launchd)
  UI, timers,              pmset -a disablesleep 1 / 0
  safety checks,           …and back to 0 when the app disconnects
  connection watch         networksetup -setairportpower (Wi-Fi off and on)
```

- **हेल्पर का दायरा बहुत छोटा है।** उसका पूरा इंटरफ़ेस बस `setSleepDisabled(Bool)` और दो Wi-Fi कॉल हैं: Wi-Fi को फिर से चालू करना, और Mac पर पहले से सेव किए गए किसी नेटवर्क से जुड़ना। उसके पास shell एक्सेस नहीं है और वह कोई मनमाना कमांड नहीं चलाता। देखें [`Sources/MelatoninHelper/main.swift`](Sources/MelatoninHelper/main.swift)।
- **यह सिर्फ़ Melatonin से बात करता है।** XPC कनेक्शन को ऐप के bundle identifier के लिए तय code-signing requirement पूरी करनी होती है।
- **गड़बड़ी होने पर भी सुरक्षित।** स्लीप तभी तक बंद रहती है जब तक कोई जुड़ा हुआ ऐप ऐसा चाहता है। कनेक्शन टूटते ही स्लीप वापस आ जाती है। हेल्पर के रीस्टार्ट और Mac के रीबूट की स्थिति एक मार्कर फ़ाइल सँभालती है।
- **इंस्टॉल और अनइंस्टॉल सीधी-सादी shell स्क्रिप्ट हैं**, जिन्हें आप खुद पढ़ सकते हैं: [`Support/install-helper.sh`](Support/install-helper.sh) और [`Support/uninstall-helper.sh`](Support/uninstall-helper.sh)।

## अनइंस्टॉल

मेन्यू में **⋯ › हेल्पर अनइंस्टॉल करें…** चुनें, फिर ऐप डिलीट कर दें। हेल्पर को खुद हाथ से हटाना हो, तो:

```bash
sudo bash Support/uninstall-helper.sh
```

## डेवलपमेंट

```bash
make app        # build build/Melatonin.app (signed with the best identity on this Mac)
make run        # build and launch
make package    # universal build, DMG and zip in dist/
make icon       # regenerate the app icon from Scripts/make-icon.swift
swift build && .build/debug/Melatonin --snapshot /tmp/shots   # render every UI state to PNGs
swift build && .build/debug/Melatonin --agents                 # watch agent detection live
```

अनुवाद जोड़ने या बदलने के बाद, छूटी हुई स्ट्रिंग्स और मेल न खाने वाले प्लेसहोल्डर पकड़ने के लिए `python3 Scripts/check-localizations.py` चलाएँ।

बिल्ड इस Mac के Developer ID से साइन होते हैं अगर वह मौजूद हो; नहीं तो `Scripts/make-signing-identity.sh` से बनी लोकल आइडेंटिटी से (दोबारा बिल्ड करने पर भी लोकेशन की अनुमति बनी रहती है); और वह भी न हो तो ad hoc। `melatonin` नाम की notarytool कीचेन प्रोफ़ाइल हो तो `make package` नोटराइज़ भी करता है। अपने Developer ID से साइन करने के लिए `SIGN_IDENTITY` सेट करें:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make app
```

## रोडमैप

- [x] साइन और नोटराइज़ की गई रिलीज़ और Homebrew cask
- [x] ऑनलाइन रहें: सेव किए गए नेटवर्क से आपके तय क्रम में जुड़ना
- [x] लौटने पर "आपकी गैरमौजूदगी में" सारांश
- [x] Sparkle से अपने आप अपडेट
- [x] Claude Code और Codex के सेशन लॉग से हर टर्न की शुरुआत और अंत की पहचान

## लाइसेंस

[MIT](LICENSE)
