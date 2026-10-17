#!/usr/bin/env bash
# Capture a manual updater step on the owner's Sony TV, with one remote key per call.
# Usage: scripts/tv-update-screen.sh <screenshot.png> [KEYCODE_... ...]
set -euo pipefail
[[ $# -ge 1 ]] || { echo "usage: $0 <screenshot.png> [KEYCODE_... ...]" >&2; exit 2; }
out=$1
shift
export ADB_USB=0
for key in "$@"; do
  adb -s 192.168.0.3:5555 shell input keyevent "$key"
  sleep 1
done
TV=192.168.0.3:5555 "$HOME/tv-setup/tv-shot.sh" "$out"
