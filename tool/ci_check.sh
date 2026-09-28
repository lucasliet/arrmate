#!/usr/bin/env bash
# Mirrors .github/workflows/run-tests.yml so the CI verdict is known locally
# before anything is pushed. Run it before every push that must go green and
# always before creating/pushing a release tag.

set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> flutter pub get"
flutter pub get

echo "==> build_runner build"
dart run build_runner build --delete-conflicting-outputs

echo "==> flutter analyze lib test"
flutter analyze lib test

echo "==> flutter test"
flutter test

echo "==> flutter_launcher_icons"
flutter pub run flutter_launcher_icons

echo "Local CI check passed."
