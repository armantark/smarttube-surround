# 02: A patched build installs beside SmartTube on the TV

**What to build:** a locally built, project-signed SmartTube beta build from the newest upstream beta tag, with its own app name and application ID, that installs on the Sony TV next to the owner's current SmartTube and plays a video. No audio change yet. The patch lives as patch files against the upstream tag.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The project keystore exists at ~/.config/smarttube-surround/ with mode 600, and its passwords live beside it, never in the repository
- [x] One script checks out a given upstream tag with submodules, applies the patch series, and builds the signed beta release APKs
- [x] The APK installs on the TV while org.smarttube.beta stays installed, and both apps open
- [x] "SmartTube Surround" shows in Projectivy's app list, and a video plays in it
- [x] The update URL points at this repository's latest release manifest
