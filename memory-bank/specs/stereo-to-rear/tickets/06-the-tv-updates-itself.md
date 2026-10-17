# 06: The TV updates the patched build by itself

**What to build:** the patched build on the TV finds a newer patched release through the manifest and installs it through SmartTube's own update flow.

**Blocked by:** 03 (Stereo plays from the rear speakers in the patched build), 04 (GitHub builds and publishes a patched build on dispatch)

**Status:** claimed by implementer-06 (GPT-6.1 Sol)

- [ ] With an older patched build installed, the app offers the newer release from the manifest
- [ ] The update installs over the old build, and the sign-in and settings survive
- [ ] After the update, ticket 03's on-TV check still passes
