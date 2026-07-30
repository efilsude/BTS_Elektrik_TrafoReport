#!/usr/bin/env bash
# Automatic Keystore and key.properties Generator Script (Linux/macOS)
set -e

echo "========================================================"
echo "  TrafoReport Mobile - Production Keystore Generator"
echo "========================================================"
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
KEY_DIR="$SCRIPT_DIR/android"
KEYSTORE_FILE="$KEY_DIR/app/upload-keystore.jks"
PROPERTIES_FILE="$KEY_DIR/key.properties"

if [ -f "$KEYSTORE_FILE" ]; then
    echo "[ INFO ] Keystore already exists at: $KEYSTORE_FILE"
else
    echo "[ STEP 1 ] Generating production release keystore..."
    
    STORE_PASS="BTS_TrafoReport_2026_ProdKey!"
    KEY_PASS="BTS_TrafoReport_2026_ProdKey!"
    ALIAS="traforeport_key"

    keytool -genkey -v -keystore "$KEYSTORE_FILE" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias "$ALIAS" -storepass "$STORE_PASS" -keypass "$KEY_PASS" -dname "CN=BTS Elektrik, OU=TrafoReport, O=BTS Elektrik, L=Istanbul, ST=Istanbul, C=TR"

    echo "[ SUCCESS ] Created Keystore: $KEYSTORE_FILE"

    cat <<EOF > "$PROPERTIES_FILE"
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=$ALIAS
storeFile=app/upload-keystore.jks
EOF
    echo "[ SUCCESS ] Created key.properties: $PROPERTIES_FILE"
fi

echo ""
echo "========================================================"
echo "  Keystore and Signing Configuration are Ready!"
echo "========================================================"
