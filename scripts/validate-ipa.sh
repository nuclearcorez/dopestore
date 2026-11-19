#!/usr/bin/env bash
set -euo pipefail

IPA_PATH="${1:-}"
MODE="${2:-unsigned}"

if [[ -z "$IPA_PATH" || ! -f "$IPA_PATH" ]]; then
  echo "ERROR: IPA file does not exist: ${IPA_PATH:-<empty>}" >&2
  exit 2
fi

if [[ ! -s "$IPA_PATH" ]]; then
  echo "ERROR: IPA file is empty." >&2
  exit 2
fi

/usr/bin/unzip -t "$IPA_PATH" >/dev/null
ENTRY="$(/usr/bin/unzip -Z -1 "$IPA_PATH" | /usr/bin/grep -E '^Payload/[^/]+\.app/Info\.plist$' | /usr/bin/head -n 1 || true)"
if [[ -z "$ENTRY" ]]; then
  echo "ERROR: IPA has no Payload/<App>.app/Info.plist." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
/usr/bin/unzip -q "$IPA_PATH" -d "$TMP"
APP_DIR="$(dirname "$TMP/$ENTRY")"
INFO="$APP_DIR/Info.plist"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO")"
EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$INFO")"
if [[ -z "$BUNDLE_ID" || -z "$EXECUTABLE" || ! -f "$APP_DIR/$EXECUTABLE" ]]; then
  echo "ERROR: IPA bundle metadata or main executable is missing." >&2
  exit 1
fi

if [[ "$MODE" == "signed" ]]; then
  if [[ ! -f "$APP_DIR/embedded.mobileprovision" ]]; then
    echo "ERROR: Signed IPA has no embedded.mobileprovision." >&2
    exit 1
  fi
  /usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_DIR"
  /usr/bin/security cms -D -i "$APP_DIR/embedded.mobileprovision" > "$TMP/profile.plist"
  PROFILE_APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$TMP/profile.plist")"
  PROFILE_TEAM_ID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.developer.team-identifier' "$TMP/profile.plist")"
  PROFILE_BUNDLE_PATTERN="${PROFILE_APP_ID#*.}"
  if [[ "$BUNDLE_ID" != $PROFILE_BUNDLE_PATTERN ]]; then
    echo "ERROR: Provisioning profile application identifier does not match $BUNDLE_ID ($PROFILE_APP_ID)." >&2
    exit 1
  fi
  if [[ -z "$PROFILE_TEAM_ID" ]]; then
    echo "ERROR: Provisioning profile has no developer team identifier." >&2
    exit 1
  fi
  echo "VALID SIGNED IPA: bundle=$BUNDLE_ID team=$PROFILE_TEAM_ID executable=$EXECUTABLE"
else
  echo "VALID IPA STRUCTURE (NOT INSTALLABLE UNTIL SIGNED): bundle=$BUNDLE_ID executable=$EXECUTABLE"
fi
