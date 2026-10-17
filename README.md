# SmartTube Surround

A patched build of [SmartTube](https://github.com/yuliskov/SmartTube) beta that installs beside
the official SmartTube beta as its own app, "SmartTube Surround", and updates itself from this
repository's releases. It is built for one Sony TV whose soundbar plays stereo only from the front;
`memory-bank/specs/stereo-to-rear/spec.md` describes the goal.

This repository is not a fork. It holds the patch as a series of patch files in `patches/`,
made against an upstream beta tag, and a script that applies them to a fresh upstream checkout.

## Build

Requirements: JDK 17, the Android SDK with the platform and build-tools that upstream's
`SharedModules/constants.gradle` names, and the project keystore.

```sh
scripts/build.sh 32.56
```

The script checks out the upstream tag with its submodules in `~/.cache/smarttube-surround/upstream`,
applies the patch series with a three-way apply, signs with the keystore, and lists the APKs it
built under `smarttubetv/build/outputs/apk/stbeta/release/`. The comment at the top of the script
lists the environment variables that move the build directory and the keystore.

The keystore lives outside the repository, at `~/.config/smarttube-surround/release.jks`, with its
passwords in `keystore.env` beside it. Every release must be signed with this key, or the TV cannot
update the installed app, so keep a backup of both files.

## Releases

The "Build and publish" workflow runs daily at 08:23 UTC and on manual dispatch with an optional
upstream beta tag (the newest upstream beta release when empty). If the release already exists at
the current patch revision, it succeeds without building, publishing, or notifying. Otherwise,
it builds with JDK 17, verifies every APK against the
project certificate (`certificate-sha256`), and publishes a release named
`<upstream tag>-r<patch revision>` as the latest release. The APKs have stable names
(`SmartTube_Surround_<abi>.apk`) and the update manifest is `smarttube_surround.json`, so the patched
app finds it at
`https://github.com/armantark/smarttube-surround/releases/latest/download/smarttube_surround.json`.

The version code is upstream's version code times 100 plus the number in `patch-revision`. Raise
that number in the same commit as any change to `patches/`, so the TV sees the fix as an update.

The workflow reads the keystore and its passwords from the Actions secrets `KEYSTORE_BASE64`,
`KEYSTORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD`. The `NTFY_TOPIC` secret selects the owner's
existing ntfy.sh topic. A failed step sends a priority 5 alert with the step name, upstream tag,
and run link; publishing sends a priority 2 message with the release name and link. Notification
requests retry network failures and never print the topic. Patch application and compilation run
as separate steps; the local build command still runs both.

## Licenses

SmartTube is MIT licensed, Copyright (c) 2020-present yuliskov; see its
[LICENSE](https://github.com/yuliskov/SmartTube/blob/master/LICENSE). The APKs also bundle
SmartTube's vendored ExoPlayer 2.10.6 tree, licensed under the Apache License 2.0; see
[exoplayer-amzn-2.10.6/LICENSE](https://github.com/yuliskov/SmartTube/blob/master/exoplayer-amzn-2.10.6/LICENSE).

The license texts are in `LICENSE` and `LICENSE-ExoPlayer`.
