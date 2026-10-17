#!/usr/bin/env bash
# Fails unless every APK in a directory verifies and is signed with the project certificate.
#
# Usage: scripts/verify-apks.sh <apk-dir>
#
# ANDROID_HOME defaults to the Android Studio location on macOS.
set -euo pipefail

apk_dir=${1:?usage: verify-apks.sh <apk-dir>}
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
expected=$(<"$repo_dir/certificate-sha256")
apksigner=$(ls -d "${ANDROID_HOME:-$HOME/Library/Android/sdk}"/build-tools/*/apksigner | sort -V | tail -n 1)

shopt -s nullglob
apks=("$apk_dir"/*.apk)
((${#apks[@]})) || { echo "no APKs in $apk_dir" >&2; exit 1; }

for apk in "${apks[@]}"; do
  actual=$("$apksigner" verify --print-certs "$apk" 2>/dev/null \
    | sed -nE 's/^Signer #1 certificate SHA-256 digest: //p')
  [[ $actual == "$expected" ]] || { echo "$(basename "$apk"): certificate $actual, expected $expected" >&2; exit 1; }
  echo "$(basename "$apk"): signed with the project certificate"
done
