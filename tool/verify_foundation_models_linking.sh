#!/usr/bin/env bash
# Verifies that an iOS or macOS app bundle weak-links FoundationModels.
#
# The framework only exists on iOS/macOS 26 and later, so a strong link would
# stop the app from launching on older systems. A bundle that does not link
# it at all was built with an SDK older than Xcode 26 and ships without
# Apple Intelligence support.
#
# Usage: tool/verify_foundation_models_linking.sh <path/to/App.app>

set -euo pipefail

app_bundle="${1:?Usage: $0 <path/to/App.app>}"
linked=0

while IFS= read -r -d '' binary; do
  commands=$(otool -l "$binary" 2>/dev/null) || continue
  if grep -A2 'cmd LC_LOAD_DYLIB$' <<<"$commands" |
    grep -q 'FoundationModels.framework'; then
    echo "::error::$binary links FoundationModels strongly."
    exit 1
  fi
  if grep -q 'FoundationModels.framework' <<<"$commands"; then
    linked=1
  fi
done < <(find "$app_bundle" -type f -perm -u+x -print0)

if [ "$linked" -ne 1 ]; then
  echo "::error::Apple Intelligence support was compiled out; build with an Xcode 26 or later SDK."
  exit 1
fi

echo "FoundationModels is weak-linked in $app_bundle."
