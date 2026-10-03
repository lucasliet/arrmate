#!/usr/bin/env bash
# Packages the complete Flutter bundle and its non-system dependencies.
set -euo pipefail
cd "${1:-$(dirname "$0")/..}"

bundle=build/linux/x64/release/bundle
appdir=build/release/Arrmate.AppDir
tools_dir=build/appimage-tools
mkdir -p "$tools_dir" build/release

download_tool() {
  local name=$1 url=$2 checksum=$3
  if ! printf '%s  %s\n' "$checksum" "$tools_dir/$name" | sha256sum --check --status 2>/dev/null; then
    curl --fail --location --retry 3 --max-time 120 "$url" -o "$tools_dir/$name"
  fi
  printf '%s  %s\n' "$checksum" "$tools_dir/$name" | sha256sum --check
  chmod +x "$tools_dir/$name"
}

download_tool linuxdeploy.AppImage \
  https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20251107-1/linuxdeploy-x86_64.AppImage \
  c20cd71e3a4e3b80c3483cef793cda3f4e990aca14014d23c544ca3ce1270b4d
download_tool appimagetool.AppImage \
  https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage \
  ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0

rm -rf "$appdir"
mkdir -p "$appdir/usr/bin"
cp -a "$bundle/." "$appdir/usr/bin/"
cp web/icons/Icon-512.png "$appdir/arrmate.png"
cat > "$appdir/arrmate.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Arrmate
Comment=Companion for Radarr, Sonarr and qBittorrent
Exec=arrmate
Icon=arrmate
Categories=Network;Utility;
Terminal=false
EOF

libraries=()
while IFS= read -r -d '' library; do
  libraries+=(--library "$library")
done < <(find "$appdir/usr/bin/lib" -type f -name '*.so*' -print0)
"$tools_dir/linuxdeploy.AppImage" --appimage-extract-and-run \
  --appdir "$appdir" --executable "$appdir/usr/bin/arrmate" \
  --desktop-file "$appdir/arrmate.desktop" --icon-file "$appdir/arrmate.png" \
  "${libraries[@]}"

# Keep Flutter's data/lib directories relative to the actual runner executable.
rm -f "$appdir/AppRun"
cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
appdir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export LD_LIBRARY_PATH="$appdir/usr/lib:$appdir/usr/bin/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$appdir/usr/bin/arrmate" "$@"
EOF
chmod +x "$appdir/AppRun"
ARCH=x86_64 "$tools_dir/appimagetool.AppImage" --appimage-extract-and-run \
  "$appdir" build/release/arrmate-linux-x64.AppImage
chmod +x build/release/arrmate-linux-x64.AppImage
test -s build/release/arrmate-linux-x64.AppImage
