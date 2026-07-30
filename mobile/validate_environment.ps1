# Environment Validation Script for TrafoReport Mobile Build (Windows PowerShell)
$ErrorActionPreference = "Continue"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  TrafoReport Mobile - Build Environment Validation" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$failed = $false

function Check-Command ($cmdName, $label) {
    $cmd = Get-Command $cmdName -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "[ PASS ] $label: Found at $($cmd.Source)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[ FAIL ] $label: NOT found in PATH" -ForegroundColor Red
        return $false
    }
}

function Check-EnvVar ($varName, $label) {
    $val = [Environment]::GetEnvironmentVariable($varName)
    if ($val -and (Test-Path $val)) {
        Write-Host "[ PASS ] $label ($varName): $val" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[ FAIL ] $label ($varName): NOT set or path does not exist ($val)" -ForegroundColor Red
        return $false
    }
}

# 1. Check Flutter
if (-not (Check-Command "flutter" "Flutter SDK")) { $failed = $true }

# 2. Check Dart
if (-not (Check-Command "dart" "Dart SDK")) { $failed = $true }

# 3. Check Java & JAVA_HOME
if (-not (Check-Command "java" "Java Runtime")) { $failed = $true }
if (-not (Check-EnvVar "JAVA_HOME" "JAVA_HOME Environment Variable")) {
    # Check if Android Studio bundled JDK exists as fallback
    $asJdk = "C:\Program Files\Android\Android Studio\jbr"
    if (Test-Path $asJdk) {
        Write-Host "[ INFO ] Fallback JAVA_HOME detected: $asJdk" -ForegroundColor Yellow
    } else {
        $failed = $true
    }
}

# 4. Check Android SDK & ANDROID_HOME
$androidHomeOk = Check-EnvVar "ANDROID_HOME" "ANDROID_HOME Environment Variable"
if (-not $androidHomeOk) {
    Check-EnvVar "ANDROID_SDK_ROOT" "ANDROID_SDK_ROOT Environment Variable"
    # Fallback check standard path
    $stdSdk = "$env:LOCALAPPDATA\Android\Sdk"
    if (Test-Path $stdSdk) {
        Write-Host "[ INFO ] Standard Android SDK detected at: $stdSdk" -ForegroundColor Yellow
    } else {
        $failed = $true
    }
}

# 5. Check Android SDK Tools (adb, sdkmanager, zipalign, apksigner)
Check-Command "adb" "Android Debug Bridge (adb)" | Out-Null
Check-Command "sdkmanager" "Android SDK Manager (sdkmanager)" | Out-Null
Check-Command "zipalign" "Android zipalign Tool" | Out-Null
Check-Command "apksigner" "Android apksigner Tool" | Out-Null

# 6. Check Git
if (-not (Check-Command "git" "Git Version Control")) { $failed = $true }

# 7. Flutter Doctor Check
Write-Host ""
Write-Host "Running Flutter Doctor..." -ForegroundColor Yellow
flutter doctor

Write-Host ""
if ($failed) {
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host "  RESULT: ENVIRONMENT VALIDATION FAILED!" -ForegroundColor Red
    Write-Host "  Please resolve missing dependencies before building." -ForegroundColor Red
    Write-Host "========================================================" -ForegroundColor Red
    exit 1
} else {
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "  RESULT: BUILD ENVIRONMENT IS READY FOR APK GENERATION!" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    exit 0
}
