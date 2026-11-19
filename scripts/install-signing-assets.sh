#!/usr/bin/env bash
set -euo pipefail

: "${APPLE_CERTIFICATE_BASE64:?Set APPLE_CERTIFICATE_BASE64 in GitHub Secrets}"
: "${APPLE_CERTIFICATE_PASSWORD:?Set APPLE_CERTIFICATE_PASSWORD in GitHub Secrets}"
: "${PROVISIONING_PROFILE_BASE64:?Set PROVISIONING_PROFILE_BASE64 in GitHub Secrets}"
: "${KEYCHAIN_PASSWORD:?Set KEYCHAIN_PASSWORD in GitHub Secrets}"
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID in GitHub Secrets}"

mkdir -p build/signing
printf '%s' "$APPLE_CERTIFICATE_BASE64" | base64 --decode > build/signing/certificate.p12
printf '%s' "$PROVISIONING_PROFILE_BASE64" | base64 --decode > build/signing/profile.mobilyprovision

KEYCHAIN_PATH="${RUNNER_TEMP:-$PWD/build}/dopestore-signing.keychain-db"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import build/signing/certificate.p12 -k "$KEYCHAIN_PATH" -P "$APPLE_CERTIFICATE_PASSWORD -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security list-keychains -d user -s "$KEYCHAIN_PATH"

security cms -D -i build/signing/profile.mobileprovision > build/signing/profile.plist
PROFILE_UUID=$(/usr/libexec/PlistBuddy -c 'Print :UUID' build/signing/profile.plist)
PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILE_DIR"
cp build/signing/profile.mobileprovision "$PROFILE_DIR/${PROFILE_UUID}.mobileprovision"
PROFILE_NAME=$(/usr/libexec/PlistBuddy -c 'Print :Name' build/signing/profile.plist)
cat > build/signing/export-options.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>ad-hoc</string>
  <key>signingStyle</key><string>manual</string>
  <key>teamID</key><string>${APPLE_TEAM_ID}</string>
  <key>provisioningProfiles</key><dict>
    <key>com.dopestore.app</key><string>${PROFILE_UUID}</string>
  </dict>
</dict></plist>
PLIST

echo "Provisioning profile loaded: ${PROFILE_NAME} (${PROFILE_UUID})"
printf 'DOPESTORE_KEYCHAIN_PATH=%s\nDOPESTORE_PROFILE_UUID=%s\n' "$KEYCHAIN_PATH" "$PROFILE_UUID" > build/signing/profile.env
