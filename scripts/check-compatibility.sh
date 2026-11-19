#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

grep -q 'iOS: "16.0"' project.yml || { echo "ERROR: iOS deployment target must remain 16.0." >&2; exit 1; }
grep -q '<string>com.apple.itunes.ipa</string>' DopeStore/Info.plist || { echo "ERROR: IPA document type is not registered." >&2; exit 1; }
if grep -R -nE 'com\.apple\.private|LocalDevVPN|allow-jit|task_for_pid-allow' DopeStore/DopeStore.entitlements; then
  echo "ERROR: Private or privileged entitlements must not be added to the ordinary DopeStore target." >&2
  exit 1
fi
for workflow in .github/workflows/*.yml; do
  grep -q 'workflow_dispatch:' "$workflow" || { echo "ERROR: $workflow lacks workflow_dispatch." >&2; exit 1; }
done

echo "Compatibility configuration checks passed (minimum deployment target iOS 16.0; no private entitlements)."
