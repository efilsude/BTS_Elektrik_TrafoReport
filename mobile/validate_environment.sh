#!/usr/bin/env bash
# Environment Validation Script for TrafoReport Mobile Build (Linux/macOS)
set -e

echo "========================================================"
echo "  TrafoReport Mobile - Build Environment Validation"
echo "========================================================"
echo ""

FAILED=0

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "[ PASS ] $2: Found at $(command -v "$1")"
    else
        echo "[ FAIL ] $2: NOT found in PATH"
        FAILED=1
    fi
}

check_env_var() {
    eval val=\$$1
    if [ -n "$val" ] && [ -d "$val" ]; then
        echo "[ PASS ] $2 ($1): $val"
    else
        echo "[ FAIL ] $2 ($1): NOT set or directory does not exist ($val)"
        FAILED=1
    fi
}

# 1. Flutter
check_command "flutter" "Flutter SDK"

# 2. Dart
check_command "dart" "Dart SDK"

# 3. Java & JAVA_HOME
check_command "java" "Java Runtime"
check_env_var "JAVA_HOME" "JAVA_HOME Environment Variable"

# 4. Android SDK
if [ -n "$ANDROID_HOME" ]; then
    check_env_var "ANDROID_HOME" "ANDROID_HOME Environment Variable"
elif [ -n "$ANDROID_SDK_ROOT" ]; then
    check_env_var "ANDROID_SDK_ROOT" "ANDROID_SDK_ROOT Environment Variable"
else
    echo "[ FAIL ] Neither ANDROID_HOME nor ANDROID_SDK_ROOT is set"
    FAILED=1
fi

# 5. Tools
check_command "adb" "Android Debug Bridge (adb)"
check_command "git" "Git Version Control"

echo ""
echo "Running Flutter Doctor..."
flutter doctor

echo ""
if [ $FAILED -ne 0 ]; then
    echo "========================================================"
    echo "  RESULT: ENVIRONMENT VALIDATION FAILED!"
    echo "========================================================"
    exit 1
else
    echo "========================================================"
    echo "  RESULT: BUILD ENVIRONMENT IS READY FOR APK GENERATION!"
    echo "========================================================"
    exit 0
fi
