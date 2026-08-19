# TrafoReport Mobile - Production APK Generation & Deployment Guide

This repository is fully configured for standalone, headless production release APK generation without requiring Android Studio as an IDE.

---

## 📋 Executive Overview

- **Target Distribution**: Company-owned Android Tablets (Internal Manual / Side-loading Distribution)
- **Application ID / Package Name**: `com.btselektrik.traforeport.trafo_report_mobile`
- **Build Output**: `build/app/outputs/flutter-apk/app-release.apk`
- **Supported Android Architectures**: `arm64-v8a`, `armeabi-v7a`, `x86_64`
- **Minimum Android SDK**: API 21+ (Android 5.0 Lollipop or higher)
- **Target / Compile Android SDK**: API 35 (Android 15)

---

## 🛠️ Environment Specifications

| Component | Version / Location |
|---|---|
| **Flutter SDK** | `3.41.1` (Channel `stable`) |
| **Dart SDK** | `3.11.0` |
| **Android Gradle Plugin (AGP)** | `8.11.1` |
| **Gradle Wrapper** | `8.14-all` |
| **Kotlin** | `2.2.20` |
| **Java JDK** | OpenJDK 17 or OpenJDK 21 (bundled JBR or standard JDK) |
| **Android SDK Path** | `%LOCALAPPDATA%\Android\Sdk` (Windows) or `~/Android/Sdk` (Linux/macOS) |

---

## ⚙️ Environment Variables Setup

Ensure the following environment variables are set on your build machine:

### Windows (PowerShell):
```powershell
[System.Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Android\Android Studio\jbr', 'User')
[System.Environment]::SetEnvironmentVariable('ANDROID_HOME', "$env:LOCALAPPDATA\Android\Sdk", 'User')
$env:Path += ";C:\src\flutter\bin;$env:ANDROID_HOME\platform-tools"
[System.Environment]::SetEnvironmentVariable('Path', $env:Path, 'User')
```

### Linux / macOS (`~/.bashrc` or `~/.zshrc`):
```bash
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk" # or Mac path
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$HOME/flutter/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"
```

---

## 🔑 Signing & Keystore Configuration

Release builds are signed using standard Android Java Keystore (`upload-keystore.jks`).

### 1. Generating Keystore (One-time Setup)

Run the included automated generator script:

- **Windows (PowerShell)**:
  ```powershell
  .\generate_keystore.ps1
  ```
- **Linux / macOS (Shell)**:
  ```bash
  chmod +x generate_keystore.sh && ./generate_keystore.sh
  ```

Or manually execute:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias traforeport_key \
  -storepass BTS_TrafoReport_2026_ProdKey! \
  -keypass BTS_TrafoReport_2026_ProdKey! \
  -dname "CN=BTS Elektrik, OU=TrafoReport, O=BTS Elektrik, L=Istanbul, ST=Istanbul, C=TR"
```

### 2. Configuration (`android/key.properties`)

The build system automatically reads `android/key.properties`:
```properties
storePassword=BTS_TrafoReport_2026_ProdKey!
keyPassword=BTS_TrafoReport_2026_ProdKey!
keyAlias=traforeport_key
storeFile=app/upload-keystore.jks
```

> 🔒 **Security Note**: `key.properties`, `*.jks`, and `*.keystore` are strictly excluded in `android/.gitignore` and must never be committed to source control.

---

## 🚀 Building the Production Release APK

### Option A: Standard Flutter Command
```bash
flutter build apk --release
```

### Option B: Automated Production Release Builder Script (Recommended)

The automated script cleans build artifacts, fetches dependencies, runs static analysis, builds the signed APK, and performs post-build verification:

- **Windows (PowerShell)**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File build_release.ps1
  ```
- **Linux / macOS (Shell)**:
  ```bash
  chmod +x build_release.sh && ./build_release.sh
  ```

---

## 🔍 APK Verification & Output Location

Upon build completion, the signed production APK is located at:

```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

### Verification Checklist:
1. **File Exists**: Confirmed (~52 MB).
2. **Signature Verified**: Signed with production release key.
3. **Supported ABIs**: `arm64-v8a`, `armeabi-v7a`, `x86_64` (Compatible with all modern Android tablets).

---

## 📱 Company Tablet Deployment & APK Replacement

### Method 1: USB Direct Transfer
1. Connect company Android tablet to build machine via USB.
2. Copy `app-release.apk` to tablet's `Downloads` folder.
3. Open **Files / Dosyalar** app on tablet and tap `app-release.apk`.
4. Confirm update/installation (*Bilinmeyen Kaynaklar / Allow from this source permission enabled*).

### Method 2: ADB Wireless / Cable Installation
```bash
# Verify tablet connection
adb devices

# Install / update application preserving user data
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Replacing an Existing Installation:
- Using `adb install -r` automatically updates the app without clearing technician drafts or login sessions.
- Minimum Android SDK support (API 21+) guarantees compatibility across older and newer company tablets.

---

## ❓ Troubleshooting & Common Errors

---

## 📁 Taşınabilir Excel Şablon ve Tools Yolu Yapılandırması (Windows Desktop / CLI)

Uygulama ve `generate_excel.py` Excel şablonlarını ve bağımlılıkları dinamik olarak aşağıdaki sırayla arar (Sabit `C:\Users\...` veya `OneDrive` yolları kullanılmaz):

### Şablon ve Tools Arama Sırası:
1. `TRAFO_TOOLS_DIR` ortam değişkeni -> `generate_excel.py` ve şablon dizinleri
2. `TRAFO_REPO_ROOT` ortam değişkeni -> `tools/` + `backend/templates/hybrid/`
3. Çalıştırılabilir dosya (`.exe`) yanındaki veya üst klasöründeki dizinler:
   - `tools/generate_excel.py`
   - `backend/templates/hybrid/`
   - `templates/hybrid/`
4. Çalışma dizini (`Directory.current`) ve göreli repo kökü

### Ortam Değişkeni Ayarlama (Farklı PC / Klasör için):
- **Windows (PowerShell)**:
  ```powershell
  [System.Environment]::SetEnvironmentVariable('TRAFO_REPO_ROOT', 'C:\Projeler\BTS_Elektrik_TrafoReport', 'User')
  ```
- **Windows (CMD)**:
  ```cmd
  setx TRAFO_REPO_ROOT "C:\Projeler\BTS_Elektrik_TrafoReport"
  ```

Veya Release uygulamanızın (`.exe`) yanına `tools/` ve `backend/templates/hybrid/` klasörlerini kopyalamanız yeterlidir.

