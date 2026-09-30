#!/usr/bin/env bash
# Runs the web build against a pinned port so the browser origin stays stable.
# localStorage (instances, settings, filters) is scoped to host:port, so a
# random port would look like every restart wiped the configuration.

set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> flutter run -d chrome --web-port 8123"
flutter run -d chrome --web-port 8123 "$@"
