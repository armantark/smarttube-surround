# 04: GitHub builds and publishes a patched build on dispatch

**What to build:** the public repository armantark/smarttube-surround with a workflow that, on manual dispatch with an upstream tag, checks out that tag with submodules, applies the patch series, builds and signs the beta release APKs with the project key from Actions secrets, and publishes a release with the APKs and an update manifest in upstream's format.

**Blocked by:** 02 (A patched build installs beside SmartTube on the TV)

**Status:** claimed by implementer-04

- [ ] The repository is public and carries SmartTube's MIT notice and ExoPlayer's Apache 2.0 notice
- [ ] The keystore and its passwords are Actions secrets, set from the files on the Mac, never printed in a log
- [ ] A dispatch on the newest upstream beta tag publishes a release named `<upstream tag>-r<patch revision>`
- [ ] The release APK verifies with the project certificate (apksigner), and its version code is upstream's times 100 plus the patch revision
- [ ] The manifest lists that version code and the APK URL for each published ABI
