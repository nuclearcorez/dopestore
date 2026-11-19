#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p build

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install with: brew install xcodegen" >&2
  exit 2
fi

xcodegen generate --spec project.yml
xcodebuild -resolvePackageDependencies -project DopeStore.xcodeproj -scheme DopeStore

ARCHIVE="$ROOT/build/DopeStore.xcarchive"
rm -rf "$ARCHIVE" "$ROOT/build/unsigned" "$ROOT/build/export"

HAS_SIGNING="false"
if [[ -n "${APPLE_CERTIFICATE_BASE64:-}" && -n "${APPLE_CERTIFICATE_PASSWORD:-}" && -n "${PROVISIONING_PROFILE_BASE64:-}" && -n "${KEYCHAIN_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
  HAS_SIGNING="true"
fi

if [[ "$HAS_SIGNING" == "true" ]]; then
  "$ROOT/scripts/install-signing-assets.sh"
  # The helper writes a private, short-lived environment file for this build step.
  source "$ROOT/build/signing/profile.env"
  SIGNING_IDENTITY="${APPLE_SIGNING_IDENTITY:-Apple Distribution}"
  xcodebuild archive \
    -project DopeStore.xcodeproj \
    -scheme DopeStore \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGNING_ALLOWED=YES \
    CODE_SIGNING_REQUIRED=YES \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    PROVISIONING_PROFILE_SPECIFIER="$DOPESTORE_PROFILE_UUID" \
    | tee build/archive.log

  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath "$ROOT/build/export" \
    -exportOptionsPlist "$ROOT/build/signing/export-options.plist" \
    | tee build/export.log

  IPA="$(find "$ROOT/build/export" -maxdepth 1 -name '*.ipa' -print -quit)"
  if [[ -z "$IPA" || ! -s "$IPA" ]]; then
    echo "ERROR: Xcode export completed without producing an IPA." >&2
    exit 1
  fi
  cp "$IPA" "$ROOT/build/DopeStore-signed.ipa"
  "$ROOT/scripts/validate-ipa.sh" "$ROOT/build/DopeStore-signed.ipa" signed
  echo "Signed IPA created: build/DopeStore-signed.ipa"
else
  xcodebuild archive \
    -project DopeStore.xcodeproj \
    -scheme DopeStore \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    AD_HOC_CODE_SIGNING_ALLOWED=YES \
    | tee build/archive.log

  APP_PATH="$ARCHIVE/Products/Applications/DopeStore.app"
  if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: Xcode archive did not contain DopeStore.app." >&2
    exit 1
  fi
  mkdir -p "$ROOT/build/unsigned/Payload"
  cp -R "$APP_PATH" "$ROOT/build/unsigned/Payload/DopeStore.app"
  (cd "$ROOT/build/unsigned" && /usr/bin/zip -qr "$ROOT/build/DopeStore-unsigned.ipa" Payload)
  "$ROOT/scripts/validate-ipa.sh" "$ROOT/build/DopeStore-unsigned.ipa" unsigned
  echo "Unsigned IPA created. It is a build artifact only and cannot be installed until signed with a device-compatible provisioning profile."
fi
