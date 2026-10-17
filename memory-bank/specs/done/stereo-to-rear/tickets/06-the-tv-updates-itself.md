# 06: The TV updates the patched build by itself

**What to build:** the patched build on the TV finds a newer patched release through the manifest and installs it through SmartTube's own update flow.

**Blocked by:** 03 (Stereo plays from the rear speakers in the patched build), 04 (GitHub builds and publishes a patched build on dispatch)

**Status:** done

- [x] With an older patched build installed, the app offers the newer release from the manifest
- [x] The update installs over the old build and preserves settings and the signed-out state (the owner accepted staying signed out; signed-in session preservation was not tested)
- [x] After the update, ticket 03's on-TV check still passes

Verified on the Sony TV at `192.168.0.3:5555` on 2026-10-17: release `32.56-r1`
(versionCode `244601`) offered and installed `32.56-r2` (versionCode `244602`) through
Settings > About > Check for updates > Install update and Android's installer. The
Teal color setting survived; it was then restored to Dark Grey. Both
`scripts/check-surround.sh off` and `scripts/check-surround.sh on` passed after the update,
with no compressed output left open or active. Stereo-to-rear was left on and the soundbar
was unmuted through its API.

Sony's unknown-source settings screen granted permission to inactive user 10 instead of
active user 0. With the owner's explicit approval, the user-0 install permission was granted
through `appops` and verified as `allow` before continuing with remote keys. The update
required no patch change. See [the test record and screenshots](../evidence/06/README.md).
