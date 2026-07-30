# Automatic Keystore and key.properties Generator Script (Windows PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  TrafoReport Mobile - Production Keystore Generator" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$keyDir = Join-Path $PSScriptRoot "android"
$keystoreFile = Join-Path $keyDir "app\upload-keystore.jks"
$propertiesFile = Join-Path $keyDir "key.properties"

if (Test-Path $keystoreFile) {
    Write-Host "[ INFO ] Keystore already exists at: $keystoreFile" -ForegroundColor Yellow
} else {
    Write-Host "[ STEP 1 ] Generating production release keystore..." -ForegroundColor Yellow
    
    $storePass = "BTS_TrafoReport_2026_ProdKey!"
    $keyPass = "BTS_TrafoReport_2026_ProdKey!"
    $alias = "traforeport_key"

    # Use keytool from JAVA_HOME or PATH
    $keytool = "keytool"
    if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\keytool.exe")) {
        $keytool = "$env:JAVA_HOME\bin\keytool.exe"
    }

    & $keytool -genkey -v -keystore $keystoreFile -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias $alias -storepass $storePass -keypass $keyPass -dname "CN=BTS Elektrik, OU=TrafoReport, O=BTS Elektrik, L=Istanbul, ST=Istanbul, C=TR"

    Write-Host "[ SUCCESS ] Created Keystore: $keystoreFile" -ForegroundColor Green

    # Create key.properties automatically
    $propContent = @"
storePassword=$storePass
keyPassword=$keyPass
keyAlias=$alias
storeFile=app/upload-keystore.jks
"@
    Set-Content -Path $propertiesFile -Value $propContent
    Write-Host "[ SUCCESS ] Created key.properties: $propertiesFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  Keystore and Signing Configuration are Ready!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
