#!/bin/bash
set -euo pipefail

# Installs Flutter SDK and configures the development environment.
# Idempotent: safe to run multiple times.

FLUTTER_INSTALL_DIR="/home/claude/flutter"
FLUTTER_PROFILE="/etc/profile.d/flutter.sh"
# Minimum Dart SDK version from pubspec.yaml sdk constraint
DART_MIN_VERSION="3.10.4"

# ── Helpers ───────────────────────────────────────────────────────────────────

info() { echo "→ $*"; }
ok()   { echo "✓ $*"; }
err()  { echo "✗ $*" >&2; exit 1; }

# Basic system tools may be missing from PATH in some environments
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

# ── Check existing installation ───────────────────────────────────────────────

SKIP_DOWNLOAD=false

if [ -x "$FLUTTER_INSTALL_DIR/bin/flutter" ]; then
  INSTALLED=$(FLUTTER_ALLOW_ROOT=1 "$FLUTTER_INSTALL_DIR/bin/flutter" --version --no-version-check 2>/dev/null \
    | grep "^Flutter" | awk '{print $2}' || true)
  if [ -n "$INSTALLED" ]; then
    ok "Flutter $INSTALLED already installed at $FLUTTER_INSTALL_DIR — skipping download"
    SKIP_DOWNLOAD=true
  fi
fi

# ── Download Flutter SDK ──────────────────────────────────────────────────────

if [ "$SKIP_DOWNLOAD" = "false" ]; then
  info "Fetching Flutter release index..."
  RELEASES_JSON=$(curl -sf \
    "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json") \
    || err "Failed to fetch Flutter release index — check network connectivity"

  # Find the latest stable release whose bundled Dart SDK satisfies the minimum version
  ARCHIVE=$(python3 - <<PYEOF
import json, sys

data = json.loads("""$RELEASES_JSON""")
min_ver = [int(x) for x in "$DART_MIN_VERSION".split(".")]

for r in data["releases"]:
    if r["channel"] != "stable":
        continue
    dart_str = r.get("dart_sdk_version", "0.0.0")
    dart_ver = [int(x) for x in dart_str.split(".")]
    if dart_ver >= min_ver:
        print(r["archive"])
        break
PYEOF
  ) || err "Failed to resolve Flutter version from release index"

  [ -n "$ARCHIVE" ] || err "No stable Flutter release found with Dart SDK >= $DART_MIN_VERSION"

  FLUTTER_VERSION=$(python3 -c "print('$ARCHIVE'.split('flutter_linux_')[1].split('-')[0])")
  info "Downloading Flutter $FLUTTER_VERSION (Dart SDK satisfies ^$DART_MIN_VERSION)..."

  BASE_URL="https://storage.googleapis.com/flutter_infra_release/releases"
  curl -# -L "$BASE_URL/$ARCHIVE" -o /tmp/flutter_sdk.tar.xz \
    || err "Download failed — check network connectivity"

  info "Extracting to $FLUTTER_INSTALL_DIR..."
  rm -rf "$FLUTTER_INSTALL_DIR"
  mkdir -p "$(dirname "$FLUTTER_INSTALL_DIR")"
  tar -xf /tmp/flutter_sdk.tar.xz -C "$(dirname "$FLUTTER_INSTALL_DIR")"
  rm -f /tmp/flutter_sdk.tar.xz
  ok "Flutter $FLUTTER_VERSION installed"
fi

# ── Git safe.directory ────────────────────────────────────────────────────────

git config --global --add safe.directory "$FLUTTER_INSTALL_DIR" 2>/dev/null || true
git config --global --add safe.directory "$(pwd)" 2>/dev/null || true

# ── Persist environment variables ─────────────────────────────────────────────

info "Writing environment profile to $FLUTTER_PROFILE..."
mkdir -p "$(dirname "$FLUTTER_PROFILE")"

# Detect JAVA_HOME from the java binary already on PATH
DETECTED_JAVA_HOME=""
if JAVA_BIN=$(which java 2>/dev/null); then
  DETECTED_JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$JAVA_BIN")")")
fi

cat > "$FLUTTER_PROFILE" <<EOF
export FLUTTER_ROOT=$FLUTTER_INSTALL_DIR
export FLUTTER_ALLOW_ROOT=1
export PATH="\$FLUTTER_ROOT/bin:\$PATH"
${DETECTED_JAVA_HOME:+export JAVA_HOME=$DETECTED_JAVA_HOME}
EOF

ok "Profile written — shell sessions will inherit these variables automatically"

# ── Export for this session ───────────────────────────────────────────────────

export FLUTTER_ROOT="$FLUTTER_INSTALL_DIR"
export FLUTTER_ALLOW_ROOT=1
export PATH="$FLUTTER_INSTALL_DIR/bin:$PATH"
[ -n "$DETECTED_JAVA_HOME" ] && export JAVA_HOME="$DETECTED_JAVA_HOME"

# ── Flutter configuration ─────────────────────────────────────────────────────

_flutter() { flutter "$@" 2>&1 | grep -vE "^\s+(Woah|We strongly|/)|\x F0\x9F\x93\x8E|^📎"; }

info "Disabling Flutter analytics..."
_flutter config --no-analytics || true

# ── Install project dependencies ──────────────────────────────────────────────

if [ -f "$(pwd)/pubspec.yaml" ]; then
  info "Running flutter pub get..."
  _flutter pub get
  ok "Dependencies resolved"
else
  info "No pubspec.yaml in current directory — skipping flutter pub get"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
_flutter --version
echo ""
ok "Flutter environment ready"
echo ""
echo "  To activate in the current shell:"
echo "    source $FLUTTER_PROFILE"
echo ""
echo "  New shell sessions will pick up the environment automatically."
