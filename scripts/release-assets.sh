#!/usr/bin/env bash
# Stages the release assets of a finished build: the APKs under stable names, so that
# releases/latest/download/<name> URLs keep working, and the update manifest in upstream's format.
#
# Usage: scripts/release-assets.sh <upstream-tag> <output-dir>
#
# Run after scripts/build.sh; BUILD_DIR must match the one the build used.
set -euo pipefail

tag=${1:?usage: release-assets.sh <upstream-tag> <output-dir>}
out_dir=${2:?usage: release-assets.sh <upstream-tag> <output-dir>}
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
build_dir=${BUILD_DIR:-$HOME/.cache/smarttube-surround/upstream}
apk_dir=$build_dir/smarttubetv/build/outputs/apk/stbeta/release
repository=${GITHUB_REPOSITORY:-armantark/smarttube-surround}

revision=$(<"$repo_dir/patch-revision")
version_code=$(sed -nE 's/^[[:space:]]*versionCode ([0-9]+)[[:space:]]*$/\1/p' "$build_dir/smarttubetv/build.gradle")
release=$tag-r$revision
download_url=https://github.com/$repository/releases/download/$release

mkdir -p "$out_dir"
for abi in armeabi-v7a arm64-v8a x86 universal; do
  cp "$apk_dir"/SmartTube_beta_*_"$abi".apk "$out_dir/SmartTube_Surround_$abi.apk"
done

# Keep the history from the currently published update channel. Only a missing manifest starts
# an empty history; network and server failures must not erase previous versions.
previous_manifest=$(mktemp)
trap 'rm -f "$previous_manifest"' EXIT
status=$(curl --location --silent --show-error --retry 3 --retry-all-errors --retry-delay 5 \
  --connect-timeout 10 --max-time 60 --output "$previous_manifest" --write-out '%{http_code}' \
  "https://github.com/$repository/releases/latest/download/smarttube_surround.json")
case $status in
  200) ;;
  404) printf '{}\n' > "$previous_manifest" ;;
  *) echo "could not download the latest manifest: HTTP $status" >&2; exit 1 ;;
esac

# The updater installs the highest version code in the manifest from the package URLs, so a release
# that is not newer than every published one would advertise one build and download another.
published=$(jq '[to_entries[] | select(.key != "package") | .value.versionCode] | max // 0' "$previous_manifest")
(( version_code > published )) || {
  echo "version code $version_code is not newer than the published $published; build a newer upstream tag or raise patch-revision" >&2
  exit 1
}

# The TV's userspace is 32-bit, so armeabi-v7a is the default list, as in upstream's manifest.
# The universal APK is for manual installs and has no place in the update channel.
jq \
  --arg url "$download_url" \
  --arg version "$tag-surround-r$revision" \
  --argjson code "$version_code" \
  --arg changelog "Upstream SmartTube $tag with patch revision $revision" \
  '.package = {
      downloadUrlList: [$url + "/SmartTube_Surround_armeabi-v7a.apk"],
      "downloadUrlList_arm64-v8a": [$url + "/SmartTube_Surround_arm64-v8a.apk"],
      downloadUrlList_x86: [$url + "/SmartTube_Surround_x86.apk"]
    } | .[$version] = {versionCode: $code, changelog: [$changelog]}' "$previous_manifest" > "$out_dir/smarttube_surround.json"

echo "staged $release, version code $version_code, in $out_dir"
