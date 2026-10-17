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

## Licenses

SmartTube is MIT licensed, Copyright (c) 2020-present yuliskov; see its
[LICENSE](https://github.com/yuliskov/SmartTube/blob/master/LICENSE). The APKs also bundle
SmartTube's vendored ExoPlayer 2.10.6 tree, licensed under the Apache License 2.0; see
[exoplayer-amzn-2.10.6/LICENSE](https://github.com/yuliskov/SmartTube/blob/master/exoplayer-amzn-2.10.6/LICENSE).
