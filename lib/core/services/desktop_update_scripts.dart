import 'package:flutter/foundation.dart';

/// Returns the detached installer for a supported desktop platform.
String desktopUpdateScript(TargetPlatform platform) =>
    platform == TargetPlatform.windows ? _windowsInstaller : _unixInstaller;

const _unixInstaller = r'''#!/bin/sh
set -eu
target=$1
staged=$2
work=$3
parent_pid=$4
platform=$5
backup="$work/previous"
exec >> "$work/install.log" 2>&1
cd /
printf 'ready\n' > "$work/ready"
attempt=0
while kill -0 "$parent_pid" 2>/dev/null; do
  if [ -e "$work/cancel" ]; then exit 1; fi
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 120 ]; then
    printf 'Application did not exit; installation aborted.\n'
    exit 1
  fi
  sleep 1
done
if [ -e "$work/cancel" ]; then exit 1; fi
launch() {
  if [ "$platform" = macOS ]; then
    /usr/bin/open -n "$target"
  else
    "$target" --appimage-extract-and-run >/dev/null 2>&1 &
    child=$!
    sleep 2
    kill -0 "$child" 2>/dev/null
  fi
}
if ! mv "$target" "$backup"; then
  printf 'Could not preserve the installed application.\n'
  launch || true
  exit 1
fi
if ! mv "$staged" "$target"; then
  mv "$backup" "$target"
  launch || true
  printf 'Could not install the update; previous version restored.\n'
  exit 1
fi
if ! launch; then
  rm -rf "$target"
  mv "$backup" "$target"
  launch || true
  printf 'Could not launch the update; previous version restored.\n'
  exit 1
fi
rm -rf "$work"
''';

const _windowsInstaller = r'''
param(
  [string]$Target,
  [string]$Staged,
  [string]$Work,
  [int]$ParentPid,
  [string]$Platform
)
$ErrorActionPreference = 'Stop'
$backup = Join-Path $Work 'previous'
$log = Join-Path $Work 'install.log'
Set-Location $env:TEMP
function Launch-App {
  $app = Start-Process -FilePath (Join-Path $Target 'arrmate.exe') -WorkingDirectory $Target -PassThru
  Start-Sleep -Seconds 2
  if ($app.HasExited) { throw 'The updated application exited during startup.' }
}
try {
  Set-Content -LiteralPath (Join-Path $Work 'ready') -Value 'ready'
  $deadline = (Get-Date).AddSeconds(120)
  while (Get-Process -Id $ParentPid -ErrorAction SilentlyContinue) {
    if (Test-Path -LiteralPath (Join-Path $Work 'cancel')) { exit 1 }
    if ((Get-Date) -gt $deadline) { throw 'Application did not exit; installation aborted.' }
    Start-Sleep -Milliseconds 500
  }
  if (Test-Path -LiteralPath (Join-Path $Work 'cancel')) { exit 1 }
  # Retry briefly while Windows releases DLL and antivirus file handles.
  for ($attempt = 0; $attempt -lt 30; $attempt++) {
    try {
      Move-Item -LiteralPath $Target -Destination $backup
      break
    } catch {
      if ($attempt -eq 29) { throw }
      Start-Sleep -Milliseconds 500
    }
  }
  Move-Item -LiteralPath $Staged -Destination $Target
  Launch-App
} catch {
  $_ | Out-String | Add-Content -LiteralPath $log
  if (Test-Path -LiteralPath $backup) {
    if (Test-Path -LiteralPath $Target) { Remove-Item -LiteralPath $Target -Recurse -Force }
    Move-Item -LiteralPath $backup -Destination $Target
  }
  if (-not (Get-Process -Id $ParentPid -ErrorAction SilentlyContinue)) {
    try { Launch-App } catch { $_ | Out-String | Add-Content -LiteralPath $log }
  }
  exit 1
}
# Cleanup failures must not roll back an application that is already running.
Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue
''';
