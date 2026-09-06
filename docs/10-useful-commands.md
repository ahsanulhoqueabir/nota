# Useful Commands & Workflow Tips

> Noto app-er niyomito kaj, build, install, debug, ar maintain-er shob command ek jaygay. Ekhane shob useful ADB, Flutter, Gradle, ar troubleshooting command pabo — shathe kichu common workflow suggestion.

---

## ১. Quick Reference (সবচেয়ে বেশি ব্যবহৃত)

| কাজ | Command |
|------|---------|
| App run করা (debug mode, hot reload সহ) | `flutter run` |
| Specific device এ run করা | `flutter run -d 088345290601` |
| Debug APK build | `flutter build apk --debug` |
| Release APK build | `flutter build apk --release` |
| Small release APK (per-ABI) | `flutter build apk --release --split-per-abi` |
| App launch করা (ADB দিয়ে) | `adb -s 088345290601 shell am start -n com.example.note/.MainActivity` |
| Log দেখা | `adb -s 088345290601 logcat \| findstr "flutter"` |
| Uninstall | `adb -s 088345290601 uninstall com.example.note` |
| Connected devices দেখা | `flutter devices` |
| Code check (errors/warnings) | `flutter analyze` |
| Dependencies install | `flutter pub get` |
| Dependencies update | `flutter pub upgrade` |

---

## ২. Flutter Common Commands

### Project setup
```bash
# নতুন Flutter project তৈরি
flutter create my_app

# Project clean করা (build cache মুছে যায়)
flutter clean

# সব dependency reinstall
flutter pub get

# নতুন available version check
flutter pub outdated

# Dependency upgrade
flutter pub upgrade
```

### Code quality
```bash
# Static analysis — সব error/warning দেখায়
flutter analyze

# Auto-fix যেগুলো fix করা যায়
dart fix --apply

# Code formatting
dart format .
```

### Build commands

```bash
# Debug APK (development, বড় সাইজ ~150MB)
flutter build apk --debug

# Release APK একটাই (সব ABI এর জন্য ~25MB)
flutter build apk --release

# Release APK আলাদা আলাদা (প্রতিটা ~15-18MB)
flutter build apk --release --split-per-abi

# App Bundle (Play Store এ publish করার জন্য)
flutter build appbundle --release
```

### Run commands

```bash
# যেকোন connected device এ run
flutter run

# Specific device এ run
flutter run -d 088345290601

# Release mode এ run (debug info ছাড়া, fast)
flutter run --release -d 088345290601

# Profile mode (performance measure)
flutter run --profile -d 088345290601
```

`flutter run` চলাকালীন keyboard shortcuts:

| Key | কাজ |
|-----|------|
| `r` | Hot reload (state থাকবে) |
| `R` | Hot restart (state reset হবে) |
| `q` | Quit |
| `p` | Toggle debug paint (widget bounds দেখায়) |
| `o` | Toggle platform (Android <-> iOS preview) |

---

## ৩. ADB (Android Debug Bridge) Commands

### Device management

```bash
# Connected devices দেখা
adb devices

# Device info
adb -s 088345290601 shell getprop ro.product.model

# Battery level
adb -s 088345290601 shell dumpsys battery | findstr level
```

### App install / launch / uninstall

```bash
# APK install
adb -s 088345290601 install path/to/app.apk

# Replace existing install (-r)
adb -s 088345290601 install -r path/to/app.apk

# Test-only install (-t, allows debuggable APKs)
adb -s 088345290601 install -t -r path/to/app-debug.apk

# App launch
adb -s 088345290601 shell am start -n com.example.note/.MainActivity

# App force stop
adb -s 088345290601 shell am force-stop com.example.note

# Uninstall
adb -s 088345290601 uninstall com.example.note

# Installed packages দেখা (Noto আছে কিনা)
adb -s 088345290601 shell pm list packages | findstr note
```

### Logs

```bash
# সব log
adb -s 088345290601 logcat

# শুধু Flutter log
adb -s 088345290601 logcat | findstr "flutter"

# শুধু Noto app এর log
adb -s 088345290601 logcat --pid=$(adb -s 088345290601 shell pidof com.example.note)

# Log clear
adb -s 088345290601 logcat -c

# Log to file
adb -s 088345290601 logcat > logs.txt
```

### File transfer (phone ↔ computer)

```bash
# Phone থেকে file আনা
adb -s 088345290601 pull /sdcard/Download/file.txt C:\Users\DELL\Desktop\

# Phone এ file পাঠানো
adb -s 088345290601 push C:\Users\DELL\Desktop\file.txt /sdcard/Download/

# Phone এর SQLite database আনা (debug useful)
adb -s 088345290601 shell run-as com.example.note cat databases/noto.db > noto.db
```

### Storage check (gulu gulu space problem solve)

```bash
# Phone এর free space দেখা
adb -s 088345290601 shell df -h

# App এর data size
adb -s 088345290601 shell du -sh /data/data/com.example.note

# App এর cache clear করা (uninstall ছাড়া)
adb -s 088345290601 shell pm clear com.example.note
```

### Screenshot

```bash
# Screenshot নেওয়া
adb -s 088345290601 exec-out screencap -p > screenshot.png
```

### Other useful

```bash
# Device reboot
adb -s 088345290601 reboot

# ADB server restart
adb kill-server
adb start-server

# Wifi debugging enable (Android 11+)
adb -s 088345290601 tcpip 5555
adb -s 08821119SG connect 192.168.x.x:5555
```

---

## ৪. Common Error ও সমাধান

### ❌ "INSTALL_FAILED_USER_RESTRICTED"
**মানে:** Phone এ "Install from unknown source" block করা আছে।
**সমাধান:**
1. Phone → **Settings → Apps → Special app access → Install unknown apps**
2. **ADB** / **USB debugging** enable করুন
3. অথবা APK manually copy করে Files app থেকে install করুন

### ❌ "Requested internal only, but not enough space"
**মানে:** Debug APK (~150MB) install করার মতো space নেই।
**সমাধান:**
1. Phone থেকে অপ্রয়োজনীয় app/photo clear করুন
2. অথবা release APK install করুন (`app-arm64-v8a-release.apk`, ~16MB):
   ```bash
   adb -s 088345290601 install -r D:\Flutter\note\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
   ```

### ❌ "Gradle build failed"
**সমাধান:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### ❌ "Waiting for another flutter command to release the startup lock"
**সমাধান:**
```bash
# Lock file delete করুন
del D:\Flutter\note\bin\cache\lockfile
# অথবা
flutter clean
```

### ❌ App crash হচ্ছে, log দেখতে চান
```bash
adb -s 088345290601 logcat *:E | findstr "flutter"
```

### ❌ Hot reload কাজ করছে না
- `R` (capital) press করে hot restart try করুন
- যদি তাও না হয়, `q` দিয়ে quit করে আবার `flutter run` করুন

### ❌ sqflite database reset করতে চান (testing)
```bash
# App uninstall করলেই database মুছে যাবে
adb -s 088345290601 uninstall com.example.note
adb -s 088345290601 install -r D:\Flutter\note\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

---

## ৫. Workflow Suggestions (কাজের ধারা)

### প্রতিদিন development এর জন্য recommended flow:

```bash
# ১. প্রথমবার (একবারই)
git clone <repo>
cd note
flutter pub get

# ২. Code edit করুন (VS Code / Android Studio তে)

# ৩. Test করুন (debug mode, hot reload সহ — phone এ space থাকলে)
flutter run -d 088345290601

# ৪. Code quality check
flutter analyze

# ৫. Code format
dart format .

# ৬. Commit
git add .
git commit -m "your message"

# ৭. Final release build
flutter build apk --release --split-per-abi
```

### Phone এ space কম থাকলে workaround:

Phone এ storage tight হলে `flutter run` skip করুন, সরাসরি release APK install করে test করুন:

```bash
flutter build apk --release --split-per-abi
adb -s 088345290601 install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
adb -s 088345290601 shell am start -n com.example.note/.MainActivity
```

এটা debug এর চেয়ে slow feedback loop, কিন্তু low-storage phone এ কাজ করে।

### Multiple devices থাকলে:

```bash
# সব device দেখুন
flutter devices

# নির্দিষ্ট device এ run
flutter run -d <device-id>
```

### VS Code এর জন্য recommended extensions:
- **Flutter** (by Dart Code)
- **Dart** (by Dart Code)
- **SQLite Viewer** (database দেখার জন্য, debug এ কাজে লাগবে)

### Android Studio এর জন্য:
- **Flutter** plugin
- **Dart** plugin
- **Database Inspector** (built-in, sqflite database দেখা যায়)

---

## ৬. Database Inspection (SQLite দেখা)

### Local file থেকে (rooted phone / emulator):
```bash
# Pull database from phone
adb -s 088345290601 shell run-as com.example.note cat databases/noto.db > noto.db

# Open with sqlite3
sqlite3 noto.db
> .tables
> SELECT * FROM notes;
> .quit
```

### VS Code তে:
1. `noto.db` file open করুন
2. SQLite Viewer extension দিয়ে দেখুন

### Android Studio তে:
1. **View → Tool Windows → App Inspection**
2. **Database Inspector** tab
3. Running emulator/device select করুন

---

## ৭. Git Tips (Noto project এর জন্য)

```bash
# সব common gitignore entry .gitignore এ আছে
# .dart_tool/, build/, .gradle/ ইত্যাদি by default ignore হয়

# প্রথমবার commit
git init
git add .
git commit -m "Initial commit: Noto MVP"

# Feature branch workflow
git checkout -b feature/dark-mode
# ... changes ...
git add .
git commit -m "Add dark mode toggle"
git checkout main
git merge feature/dark-mode
```

### Useful .gitignore additions (Noto এ already আছে):
```
# Build outputs
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db
```

---

## ৮. Performance Tips

### APK size কমাতে:
1. `--split-per-abi` use করুন (per-ABI build)
2. ProGuard/R8 enable করুন (release এ by default থাকে)
3. অপ্রয়োজনীয় dependencies avoid করুন

### App startup speed:
1. sqflite database lazy load হচ্ছে (`DatabaseHelper.instance.database`) — ঠিক আছে
2. Theme data তৈরি expensive নয়
3. Initial load এ খুব বেশি data load হচ্ছে না (notes table only)

### Hot reload slow হলে:
```bash
flutter clean
flutter pub get
```

---

## ৯. Useful External Tools

| Tool | কাজ | Download |
|------|------|----------|
| **DB Browser for SQLite** | Local .db file দেখা/edit করা | https://sqlitebrowser.org |
| **Android Studio Device Explorer** | Phone এর files browse করা | Built-in |
| **scrcpy** | Phone এর screen mirror করা PC তে | https://github.com/Genymobile/scrcpy |
| **Vysor** | Same as scrcpy, GUI সহ | https://www.vysor.io |

---

## ১০. Emergency Commands (সব বিগড়ে গেলে)

```bash
# সব reset করুন
cd D:\Flutter\note
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..

# Cache পুরো মুছে ফেলুন (last resort)
rd /s /q %LOCALAPPDATA%\Pub\Cache\hosted
flutter pub cache repair

# যদি কিছুতেই কাজ না হয়
flutter doctor -v
```

`flutter doctor` সবসময় run করে দেখুন — green tick থাকলে সব ঠিক আছে।

---

## ১১. Quick Troubleshooting Checklist

যখন কিছু কাজ করবে না, এই order এ check করুন:

1. ☐ Phone cable connected? WiFi debugging use করলনি?
2. ☐ USB debugging phone এ enable?
3. ☐ Phone এ "Install unknown apps" permission ADB এর জন্য on?
4. ☐ Phone এ enough storage?
5. ☐ `flutter doctor` সব green?
6. ☐ `flutter analyze` clean?
7. ☐ `flutter clean && flutter pub get` run করেছেন?
8. ☐ Last build এর cache issue? → `flutter clean`

---

**Happy coding! 🚀**

এই file টা bookmark করে রাখো — Flutter project এ কাজ করতে গেলে বারবার কাজে লাগবে।
