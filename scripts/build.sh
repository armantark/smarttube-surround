#!/usr/bin/env bash
# Builds the signed SmartTube Surround beta APKs from one upstream SmartTube tag.
#
# Usage: scripts/build.sh <upstream-tag> [--prepare-only|--build-only]
# The workflow separates patch application from compilation; omit the flag to do both.
#
# Environment, with defaults for the owner's Mac (GitHub Actions sets its own):
#   BUILD_DIR          upstream checkout, reused between runs (~/.cache/smarttube-surround/upstream)
#   KEYSTORE_FILE      release keystore (~/.config/smarttube-surround/release.jks)
#   KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD
#                      read from KEYSTORE_ENV (~/.config/smarttube-surround/keystore.env) when unset
#   JAVA_HOME          JDK 17, the JDK upstream CI builds with (found with java_home on macOS)
#   ANDROID_HOME       Android SDK (~/Library/Android/sdk)
set -euo pipefail

tag=${1:?usage: build.sh <upstream-tag>}
phase=${2:-all}
case $phase in
  all|--prepare-only|--build-only) ;;
  *) echo "unknown build phase: $phase" >&2; exit 1 ;;
esac
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
config_dir=$HOME/.config/smarttube-surround
build_dir=${BUILD_DIR:-$HOME/.cache/smarttube-surround/upstream}
keystore_file=${KEYSTORE_FILE:-$config_dir/release.jks}

if [[ $phase != --build-only ]]; then
  (
    if [[ ! -d $build_dir/.git ]]; then
      git init --quiet "$build_dir"
      git -C "$build_dir" remote add origin https://github.com/yuliskov/SmartTube
    fi
    cd "$build_dir"
    "$repo_dir/scripts/retry.sh" git fetch --quiet --force --tags origin
    git checkout --quiet --force --detach "refs/tags/$tag"
    git clean --quiet -ffdx
    "$repo_dir/scripts/retry.sh" git submodule update --quiet --init --recursive --force
    git submodule foreach --quiet --recursive git clean --quiet -ffdx

    for patch in "$repo_dir"/patches/*.patch; do
      echo "applying $(basename "$patch")"
      git apply --3way "$patch"
    done
  )
fi
[[ $phase != --prepare-only ]] || exit 0

if [[ -z ${KEYSTORE_PASSWORD:-} ]]; then
  # shellcheck source=/dev/null
  source "${KEYSTORE_ENV:-$config_dir/keystore.env}"
fi
: "${KEYSTORE_PASSWORD:?}" "${KEY_ALIAS:?}" "${KEY_PASSWORD:?}"
[[ -f $keystore_file ]] || { echo "no keystore at $keystore_file" >&2; exit 1; }
keystore_file=$(cd "$(dirname "$keystore_file")" && pwd)/$(basename "$keystore_file")

export JAVA_HOME=${JAVA_HOME:-$(/usr/libexec/java_home -v 17)}
export ANDROID_HOME=${ANDROID_HOME:-$HOME/Library/Android/sdk}

cd "$build_dir"
build_dir=$PWD

# The patch revision is a counter in this repository, so the version code cannot live in a patch:
# it would conflict with every upstream version bump.
revision=$(<"$repo_dir/patch-revision")
[[ $revision =~ ^[0-9]+$ ]] || { echo "patch-revision must hold a number" >&2; exit 1; }
upstream_code=$(git show "refs/tags/$tag:smarttubetv/build.gradle" |
  sed -nE 's/^[[:space:]]*versionCode ([0-9]+)[[:space:]]*$/\1/p')
[[ $upstream_code =~ ^[0-9]+$ ]] || { echo "expected one versionCode line in smarttubetv/build.gradle" >&2; exit 1; }
sed -E -i.bak "s/^([[:space:]]*versionCode )[0-9]+/\1$((upstream_code * 100 + revision))/" smarttubetv/build.gradle
rm smarttubetv/build.gradle.bak

# Upstream's Firebase config has no client for this application ID, so its Google Services
# plugin would fail the build; without it, crashes of the patched build also stay out of
# upstream's Firebase project. Removed here rather than in a patch, because a deletion patch
# would copy upstream's Firebase keys into this repository.
rm -f smarttubetv/google-services.json

trap 'rm -f "$build_dir/keystore.properties"' EXIT
(
  umask 077
  printf 'storeFile=%s\nstorePassword=%s\nkeyAlias=%s\nkeyPassword=%s\n' \
    "$keystore_file" "$KEYSTORE_PASSWORD" "$KEY_ALIAS" "$KEY_PASSWORD" > keystore.properties
)

"$repo_dir/scripts/retry.sh" bash gradlew --no-daemon assembleStbetaRelease

ls "$build_dir"/smarttubetv/build/outputs/apk/stbeta/release/*.apk
