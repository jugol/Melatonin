<p align="center">
  <img src="docs/images/icon.png" width="128" alt="أيقونة Melatonin">
</p>

<h1 align="center">Melatonin</h1>

<div dir="rtl">

<p align="center">
  <b>أغلق الغطاء، ودَع الوكلاء يواصلون عملهم.</b><br>
  تطبيق صغير لشريط القوائم في macOS يُبقي جهاز MacBook مستيقظًا والغطاء مغلق —<br>
  على البطارية ومن دون شاشة خارجية — ريثما ينهي Claude Code وCodex ورفاقهما عملهم.
</p>

<p align="center">
  <a href="https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg"><b>تنزيل</b></a> ·
  <a href="https://jugol.github.io/Melatonin/">الموقع</a>
</p>

</div>

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

<div dir="rtl">

<p align="center">
  <img src="docs/images/notch-expanded-on.png" width="640" alt="واجهة Melatonin الموسّعة في النتوء">
</p>

## لماذا

تبدأ مهمة طويلة في Claude Code، ثم تغلق الغطاء وتمضي. يدخل macOS في الإسبات فتتوقف المهمة في منتصفها.

تطبيقات إبقاء الجهاز مستيقظًا مثل `caffeinate` وKeepingYouAwake ومعظم نظيراتها تعتمد على طلبات منع الإسبات (power assertions)، وهذه يتجاهلها macOS لحظة إغلاق الغطاء. الشيء الوحيد الذي يمنع الإسبات فعلًا عند إغلاق الغطاء هو `pmset disablesleep`، وهو يحتاج إلى صلاحيات root. يغلّفه Melatonin في أداة مساعدة صغيرة ذات صلاحيات مرتفعة مع ضوابط أمان صارمة، ويضع المفتاح حيث تراه دائمًا: في النتوء.

## الميزات

- **يسكن في النتوء.** عندما يكون Melatonin قيد التشغيل، يتوهّج مصباح دافئ بجوار الكاميرا ومعه الوقت المتبقي. مرّر المؤشر فوقه لتظهر لوحة التحكم كاملة. وعلى الشاشات التي لا تحتوي على نتوء، تتدلّى الكبسولة من شريط القوائم بدلًا من ذلك.
- **مفتاح في شريط القوائم.** هلال مفرَّغ يعني أن جهاز Mac سيدخل في الإسبات، وهلال يحتضن مصباحًا كهرمانيًا يعني أنه لن يفعل.
- **مؤقتات.** لمدة 1 أو 2 أو 4 أو 8 ساعات، أو حتى تُوقفه بنفسك.
- **قمر، تلقائي، مصباح.** مفتاح واحد أسفل المصباح: **إيقاف** يترك جهاز Mac ينام، و**تلقائي** يبقيه مستيقظًا فقط أثناء عمل الوكلاء، و**تشغيل** يبقيه مستيقظًا حتى ينتهي المؤقت ثم يعود إلى الوضع السابق.
- **تلقائي لوكلاء الذكاء الاصطناعي.** يبقى الجهاز مستيقظًا فقط ما دام أحد الوكلاء يعمل فعلًا: Claude Code أو Codex أو Hermes أو OpenCode أو T3 Code أو Gemini CLI أو Cursor Agent أو Amp أو Goose أو Crush. يعتمد الاكتشاف على نشاط المعالج عبر شجرة العمليات الخاصة بكل وكيل، لذا لا يُحتسب الوكيل الذي يقف خاملًا بانتظار أوامرك. والوكلاء الذين يُطلقهم T3 Code يُحتسبون لـ T3 Code.
- **البقاء متصلًا.** إذا انقطع الإنترنت بينما يُبقي Melatonin جهاز Mac مستيقظًا، مثلًا عندما تغلق الغطاء وتغادر نطاق Wi-Fi المكتب، فإنه يتصل بأول شبكة في النطاق من قائمة أولويات تختارها من شبكاتك المحفوظة، مثل نقطة اتصال هاتفك. يتطلب اختيار الشبكات بالاسم إذن الوصول إلى الموقع، لأن macOS لا يعرض أسماء شبكات Wi-Fi إلا للتطبيقات التي تملكه، ولا يُستخدم موقعك أبدًا. وإذا لم تنجح أي منها، يعيد تشغيل Wi-Fi ليعود macOS تلقائيًا إلى شبكة محفوظة.
- **أثناء غيابك.** عندما تعود إلى جهاز Mac، تخبرك منطقة النتوء بما حدث: كم من الوقت أبقاه Melatonin مستيقظًا، وأي الوكلاء عملوا ولكم من الوقت، وكم مرة استُعيد اتصال Wi-Fi، وكم استُهلك من البطارية.
- **الأمان أولًا.**
  - عند العمل على البطارية، يتوقف حين تبلغ الشحنة الحد الذي تختاره (20% افتراضيًا).
  - يتوقف إذا ارتفعت حرارة جهاز Mac. فتشغيل حاسوب محمول داخل حقيبة مغلقة أقصر طريق لشَيّ البطارية.
  - إذا أنهيت Melatonin، أو تعطّل، أو أُجبر على الإغلاق، تعيد الأداة المساعدة الإسبات المعتاد فورًا. وتتولى التنظيف أيضًا بعد إعادة التشغيل.
- **أصلي وخفيف.** SwiftUI وAppKit، بلا Electron، ونحو 0% من المعالج في وضع الخمول. إصدار شامل (Universal) يعمل على Apple silicon وIntel.
- **يتحدث لغتك.** English، 한국어، 简体中文، 日本語، Español، Français، Deutsch، Português (Brasil)، Русский، العربية، हिन्दी وBahasa Indonesia. يتبع لغة macOS افتراضيًا، ويمكنك اختيار لغة أخرى من **⋯ › اللغة**.

<p align="center">
  <img src="docs/images/menu-on-light.png" width="300" alt="القائمة: مستيقظ">
  <img src="docs/images/menu-off-dark.png" width="300" alt="القائمة: الإسبات مسموح">
</p>

<p align="center">
  <img src="docs/images/notch-compact.png" width="640" alt="كبسولة النتوء المصغّرة مع العد التنازلي">
</p>

<p align="center">
  <img src="docs/images/notch-recap.png" width="640" alt="ملخص أثناء غيابك في منطقة النتوء">
</p>

<p align="center">
  <img src="docs/images/connection-light.png" width="420" alt="إعدادات البقاء متصلًا">
</p>

## التثبيت

يتطلب macOS 14 Sonoma أو أحدث.

**التنزيل:** نزّل [Melatonin.dmg](https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg) من [أحدث إصدار](https://github.com/jugol/Melatonin/releases/latest) واسحب التطبيق إلى مجلد التطبيقات.

**Homebrew:**

</div>

```bash
brew install --cask jugol/tap/melatonin
```

<div dir="rtl">

الإصدارات موقعة بمعرّف Developer ID وموثّقة من Apple، لذا تفتح مثل أي تطبيق آخر.

في أول مرة تُفعّل فيها Melatonin، يطلب منك macOS كلمة السر مرة واحدة لتثبيت الأداة المساعدة.

**من المصدر:** تحتاج إلى Xcode Command Line Tools (`xcode-select --install`).

</div>

```bash
git clone https://github.com/jugol/Melatonin.git
cd Melatonin
make run
```

<div dir="rtl">

## آلية العمل

</div>

```
Melatonin.app  ──XPC──▶  io.github.jugol.melatonin.helper (root, launchd)
  UI, timers,              pmset -a disablesleep 1 / 0
  safety checks,           …and back to 0 when the app disconnects
  connection watch         networksetup -setairportpower (Wi-Fi off and on)
```

<div dir="rtl">

- **الأداة المساعدة لا تفعل إلا القليل.** تقتصر واجهتها كلها على `setSleepDisabled(Bool)` إضافةً إلى استدعاءين خاصين بـ Wi-Fi: إعادة تشغيل Wi-Fi، والانضمام إلى شبكة محفوظة مسبقًا على جهاز Mac. لا تملك وصولًا إلى الـ shell ولا تنفّذ أي أوامر عشوائية. راجع [`Sources/MelatoninHelper/main.swift`](Sources/MelatoninHelper/main.swift).
- **لا تتحدث إلا مع Melatonin.** يجب أن تستوفي اتصالات XPC شرط توقيع الشيفرة الخاص بمعرّف حزمة التطبيق.
- **آمنة عند الفشل.** يبقى الإسبات معطّلًا فقط ما دام تطبيق متصل يطلب ذلك، وعند انقطاع الاتصال يعود الإسبات. ويتكفّل ملف علامة بحالات إعادة تشغيل الأداة المساعدة أو الجهاز.
- **التثبيت وإلغاء التثبيت مجرد سكربتات shell عادية** يمكنك قراءتها: [`Support/install-helper.sh`](Support/install-helper.sh) و[`Support/uninstall-helper.sh`](Support/uninstall-helper.sh).

## إلغاء التثبيت

اختر **⋯ › إلغاء تثبيت الأداة المساعدة…** من القائمة، ثم احذف التطبيق. ولإزالة الأداة المساعدة يدويًا بدلًا من ذلك:

</div>

```bash
sudo bash Support/uninstall-helper.sh
```

<div dir="rtl">

## التطوير

</div>

```bash
make app        # build build/Melatonin.app (signed with the best identity on this Mac)
make run        # build and launch
make package    # universal build, DMG and zip in dist/
make icon       # regenerate the app icon from Scripts/make-icon.swift
swift build && .build/debug/Melatonin --snapshot /tmp/shots   # render every UI state to PNGs
swift build && .build/debug/Melatonin --agents                 # watch agent detection live
```

<div dir="rtl">

بعد إضافة ترجمة أو تعديلها، شغّل `python3 Scripts/check-localizations.py` لاكتشاف النصوص الناقصة والعناصر النائبة غير المتطابقة.

تُوقَّع الإصدارات بمعرّف Developer ID الخاص بهذا الجهاز إن وُجد، وإلا بهوية محلية من `Scripts/make-signing-identity.sh` (تحافظ على إذن الموقع بين عمليات البناء)، وإلا توقيعًا مؤقتًا (ad hoc). ويوثّق `make package` التطبيق أيضًا عند وجود ملف تعريف notarytool في سلسلة المفاتيح باسم `melatonin`. للتوقيع بمعرّف Developer ID الخاص بك، اضبط `SIGN_IDENTITY`:

</div>

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make app
```

<div dir="rtl">

## خارطة الطريق

- [x] إصدارات موقعة وموثّقة من Apple وحزمة Homebrew cask
- [x] البقاء متصلًا: الانضمام إلى شبكاتك المحفوظة بالترتيب الذي تختاره
- [x] ملخص "أثناء غيابك" عند عودتك
- [ ] تحديثات عبر Sparkle
- [ ] تكامل مع hooks في Claude Code لرصد البداية والنهاية بدقة

## الترخيص

[MIT](LICENSE)

</div>
