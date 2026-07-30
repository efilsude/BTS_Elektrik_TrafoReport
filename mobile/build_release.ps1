# Production Release APK Build & Verification Script (Windows PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  TrafoReport Mobile - Production Release APK Builder" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$mobileDir = $PSScriptRoot
Set-Location $mobileDir

# Step 1: Ensure Keystore exists
$keystorePath = Join-Path $mobileDir "android\app\upload-keystore.jks"
$propertiesPath = Join-Path $mobileDir "android\key.properties"

if (-not (Test-Path $keystorePath) -or -not (Test-Path $propertiesPath)) {
    Write-Host "[ WARNING ] Release signing keystore or key.properties not found!" -ForegroundColor Yellow
    Write-Host "[ ACTION ] Generating release keystore automatically..." -ForegroundColor Yellow
    & "$mobileDir\generate_keystore.ps1"
}

# Step 2: Clean build artifacts
Write-Host ""
Write-Host "[ STEP 1/5 ] Cleaning previous build artifacts..." -ForegroundColor Yellow
flutter clean

# Step 3: Fetch Flutter dependencies
Write-Host ""
Write-Host "[ STEP 2/5 ] Fetching Flutter package dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ ERROR ] flutter pub get failed!" -ForegroundColor Red
    exit 1
}

# Step 4: Static code analysis
Write-Host ""
Write-Host "[ STEP 3/5 ] Running Flutter static code analysis..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ WARNING ] Static code analysis produced warnings or issues." -ForegroundColor Yellow
}

# Step 5: Build Release APK
Write-Host ""
Write-Host "[ STEP 4/5 ] Building Production Signed Release APK..." -ForegroundColor Yellow
flutter build apk --release --build-name=1.0.0 --build-number=1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ ERROR ] flutter build apk --release failed!" -ForegroundColor Red
    exit 1
}

# Step 6: Verify Build Artifact
Write-Host ""
Write-Host "[ STEP 5/5 ] Verifying Production Release APK..." -ForegroundColor Yellow
$apkPath = Join-Path $mobileDir "build\app\outputs\flutter-apk\app-release.apk"

if (Test-Path $apkPath) {
    $apkFile = Get-Item $apkPath
    $sizeMb = [math]::Round($apkFile.Length / 1MB, 2)

    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "  SUCCESS: PRODUCTION RELEASE APK GENERATED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "  APK Location      : $($apkFile.FullName)" -ForegroundColor White
    Write-Host "  APK File Size     : $sizeMb MB ($($apkFile.Length) bytes)" -ForegroundColor White
    Write-Host "  Package Name      : com.btselektrik.traforeport.trafo_report_mobile" -ForegroundColor White
    Write-Host "  Target SDK        : Android 34 / 35 / 36" -ForegroundColor White
    Write-Host "  Min SDK           : Android API 21+ (Android 5.0+)" -ForegroundColor White
    Write-Host "  Architectures     : arm64-v8a, armeabi-v7a, x86_64" -ForegroundColor White
    Write-Host "  Distribution Mode : Dahili Şirket Tabletleri (Manual APK)" -ForegroundColor White
    Write-Host "========================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[ ERROR ] Release APK was not found at expected location: $apkPath" -ForegroundColor Red
    exit 1
}
