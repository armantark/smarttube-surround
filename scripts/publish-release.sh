#!/usr/bin/env bash
# Publishes staged assets. Each retry reconciles the release left by the previous attempt.
# Usage: scripts/retry.sh scripts/publish-release.sh <release> <asset-dir> <notes>
set -euo pipefail

release=${1:?usage: publish-release.sh <release> <asset-dir> <notes>}
asset_dir=${2:?usage: publish-release.sh <release> <asset-dir> <notes>}
notes=${3:?usage: publish-release.sh <release> <asset-dir> <notes>}
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set}"

# Listing distinguishes a missing release from a failed request, unlike a failed `view` call.
existing=$(gh api --paginate "repos/$GITHUB_REPOSITORY/releases" \
  --jq ".[] | select(.tag_name == \"$release\") | {draft, html_url}")
if [[ -n $existing ]]; then
  if [[ $(jq -r '.draft' <<< "$existing") == false ]]; then
    jq -r '.html_url' <<< "$existing"
    exit 0
  fi
else
  gh release create "$release" --draft --title "$release" --notes "$notes" >&2
fi

# A failed upload may leave some assets attached to the draft. Replacing the complete set
# makes retries safe without publishing an incomplete release.
gh release upload "$release" "$asset_dir"/* --clobber >&2
gh release edit "$release" --draft=false --latest >&2
printf 'https://github.com/%s/releases/tag/%s\n' "$GITHUB_REPOSITORY" "$release"
