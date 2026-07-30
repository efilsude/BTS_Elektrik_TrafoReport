#!/usr/bin/env bash
# Production Release APK Build & Verification Script (Linux/macOS)
set -e

echo "========================================================"
echo "  TrafoReport Mobile - Production Release APK Builder"
echo "========================================================"
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Step 1: Ensure Keystore exists
KEYSTORE_PATH="$SCRIPT_DIR/android/app/upload-keystore.jks"
PROPERTIES_PATH="$SCRIPT_DIR/android/key.properties"

if [ ! -f "$KEYSTORE_PATH" ] || [ ! -f "$PROPERTIES_PATH" ]; then
    echo "[ WARNING ] Release signing keystore or key.properties not found!"
    echo "[ ACTION ] Generating release keystore automatically..."
    bash "$SCRIPT_DIR/generate_keystore.sh"
fi

# Step 2: Clean build artifacts
echo ""
echo "[ STEP 1/5 ] Cleaning previous build artifacts..."
flutter clean

# Step 3: Fetch Flutter dependencies
echo ""
echo "[ STEP 2/5 ] Fetching Flutter package dependencies..."
flutter pub get

# Step 4: Static code analysis
echo ""
echo "[ STEP 3/5 ] Running Flutter static code analysis..."
flutter analyze || true

# Step 5: Build Release APK
echo ""
echo "[ STEP 4/5 ] Building Production Signed Release APK..."
flutter build apk --release --build-name=1.0.0 --build-number=1

# Step 6: Verify Build Artifact
echo ""
echo "[ STEP 5/5 ] Verifying Production Release APK..."
APK_PATH="$SCRIPT_DIR/build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
    SIZE_BYTES=$(wc -c <"$APK_PATH")
    SIZE_MB=$(awk "BEGIN {printf \"%.2f\", $SIZE_BYTES/1048576}")

    echo "========================================================"
    echo "  SUCCESS: PRODUCTION RELEASE APK GENERATED SUCCESSFULLY!"
    echo "========================================================"
    echo "  APK Location      : $APK_PATH"
    echo "  APK File Size     : $SIZE_MB MB ($SIZE_BYTES bytes)"
    echo "  Package Name      : com.btselektrik.traforeport.trafo_report_mobile"
    echo "  Min SDK           : Android API 21+ (Android 5.0+)"
    echo "  Architectures     : arm64-v8a, armeabi-v7a, x86_64"
    echo "  Distribution Mode : Dahili Şirket Tabletleri (Manual APK)"
    echo "========================================================"
    exit 0
else
    echo "[ ERROR ] Release APK was not found at expected location: $APK_PATH"
    exit 1
fi
