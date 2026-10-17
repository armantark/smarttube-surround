#!/usr/bin/env bash
# Builds the signed SmartTube Surround beta APKs from one upstream SmartTube tag.
#
# Usage: scripts/build.sh <upstream-tag>
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
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
config_dir=$HOME/.config/smarttube-surround
build_dir=${BUILD_DIR:-$HOME/.cache/smarttube-surround/upstream}
keystore_file=${KEYSTORE_FILE:-$config_dir/release.jks}

if [[ -z ${KEYSTORE_PASSWORD:-} ]]; then
  # shellcheck source=/dev/null
  source "${KEYSTORE_ENV:-$config_dir/keystore.env}"
fi
: "${KEYSTORE_PASSWORD:?}" "${KEY_ALIAS:?}" "${KEY_PASSWORD:?}"
[[ -f $keystore_file ]] || { echo "no keystore at $keystore_file" >&2; exit 1; }
keystore_file=$(cd "$(dirname "$keystore_file")" && pwd)/$(basename "$keystore_file")

export JAVA_HOME=${JAVA_HOME:-$(/usr/libexec/java_home -v 17)}
export ANDROID_HOME=${ANDROID_HOME:-$HOME/Library/Android/sdk}

retry() {
  local attempt
  for attempt in 1 2 3; do
    "$@" && return
    echo "attempt $attempt of 3 failed: $*" >&2
    sleep $((attempt * 10))
  done
  return 1
}

if [[ ! -d $build_dir/.git ]]; then
  git init --quiet "$build_dir"
  git -C "$build_dir" remote add origin https://github.com/yuliskov/SmartTube
fi
cd "$build_dir"
retry git fetch --quiet --force --tags origin
git checkout --quiet --force --detach "refs/tags/$tag"
git clean --quiet -ffdx
retry git submodule update --quiet --init --recursive --force
git submodule foreach --quiet --recursive git clean --quiet -ffdx

for patch in "$repo_dir"/patches/*.patch; do
  echo "applying $(basename "$patch")"
  git apply --3way "$patch"
done

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

bash gradlew --no-daemon assembleStbetaRelease

ls "$build_dir"/smarttubetv/build/outputs/apk/stbeta/release/*.apk
