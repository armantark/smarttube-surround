#!/usr/bin/env bash
# Retries a network command without logging its arguments, which may contain secrets.
set -euo pipefail

for attempt in 1 2 3; do
  "$@" && exit 0
  echo "attempt $attempt of 3 failed" >&2
  if ((attempt < 3)); then
    sleep $((attempt * 10))
  fi
done
exit 1
