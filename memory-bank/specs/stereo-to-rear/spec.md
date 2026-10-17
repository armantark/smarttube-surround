# Stereo-to-rear SmartTube

## Problem Statement

The owner watches YouTube in SmartTube on a Sony XR-65A80L TV with an HT-A3000 soundbar, a
subwoofer, and two rear speakers. Most YouTube videos are stereo. The soundbar's own upmix sends
only the room sound of a stereo track to the rear speakers, so voices stay in the front and the
rear speakers sound almost silent. At 2x playback speed, speech is hard to follow from where the
owner sits. No soundbar or TV setting copies the full stereo to the rear speakers: the TV sends
plain PCM to the soundbar in stereo only, and it sends more channels only as compressed audio
(see `memory-bank/research/2026-10-17-tv-audio-paths.md`).

The owner also does not want to maintain a patched app by hand. SmartTube releases often, and a
patched build that falls behind loses fixes for YouTube changes.

## Solution

A patched build of SmartTube plays every stereo track as 5.1, with the left and right channels
also sent to the rear speakers, so voices come from the rear speakers too. Tracks that are already
multichannel play exactly as before. The patched build installs beside the owner's current
SmartTube, under its own app name, so the current one stays as a fallback.

A GitHub repository builds the patched build by itself: every day it checks for a new upstream
release, applies the patch, builds, signs, and publishes the APK with an update manifest. The
patched app's own update check reads that manifest, so the TV updates the patched build the same
way SmartTube updates today. When any step fails, the owner gets an ntfy notification on the topic
the owner already uses; when a new patched build is published, the owner gets a quiet one.

## User Stories

1. As the owner, I want stereo YouTube videos to play from the rear speakers as well as the front, so that I hear voices clearly from where I sit.
2. As the owner, I want voices, not only room sound, in the rear speakers, so that speech at 2x speed stays easy to follow.
3. As the owner, I want the rear speakers to get the same stereo as the front left and right, so that nothing in the mix is lost or moved.
4. As the owner, I want videos that already have 5.1 sound to play exactly as they do now, so that movies keep their real surround mix.
5. As the owner, I want Shorts and regular videos to behave the same, so that I do not need to think about the video type.
6. As the owner, I want a player setting to turn stereo-to-rear off, so that I can compare or go back without reinstalling.
7. As the owner, I want stereo-to-rear on by default, so that the patched build works the first time I open it.
8. As the owner, I want the patched build to keep working when the soundbar or TV cannot take the 5.1 format, by playing normal stereo, so that I never get silence.
9. As the owner, I want the patched build to install beside my current SmartTube, so that I keep a working fallback while I test it.
10. As the owner, I want the patched build to have its own name on the home screen, so that I can tell the two apps apart.
11. As the owner, I want the patched build to update itself from the patched releases, so that I never install an APK by hand again.
12. As the owner, I want each patched build to follow the newest upstream release within a day, so that YouTube fixes reach me quickly.
13. As the owner, I want an ntfy notification when a build fails, so that I know the patch needs attention.
14. As the owner, I want the notification to say which step failed and link to the failed run, so that I or an agent can fix it fast.
15. As the owner, I want a quiet ntfy notification when a new patched build is published, so that I know updates still flow.
16. As the owner, I want the build job to do nothing when the newest upstream release is already built, so that it does not spam me or waste build time.
17. As the owner, I want to start a build by hand for a chosen upstream release, so that I can rebuild after a patch fix without waiting a day.
18. As the owner, I want every patched build signed with the same key, so that each update installs over the last one.
19. As the owner, I want the signing key kept outside the repository and backed up on my Mac, so that losing GitHub does not end updates.
20. As the owner, I want the public repository to carry SmartTube's and ExoPlayer's license notices, so that the published APKs respect their licenses.
21. As another member of the household, I want the official YouTube app unchanged, so that my profiles and sign-in keep working.
22. As a future agent, I want the patch kept small and separate from upstream code, so that an upstream change rarely breaks it and a break is easy to fix.
23. As a future agent, I want one command that checks the 5.1 output on the TV while a stereo video plays, so that I can verify a fix without the owner.

## Implementation Decisions

- **Repository shape.** A public GitHub repository, `armantark/smarttube-surround`, holds the patch as a series of patch files against upstream SmartTube, the build workflow, the update manifest tooling, and this spec. It is not a GitHub fork: the build checks out the upstream tag with its submodules and applies the patch on top, so the repository never merges upstream history.
- **Upstream channel.** The patch follows upstream beta releases (version-only tags, published as prereleases), because the owner runs the beta build (`org.smarttube.beta`).
- **App identity.** The patched build uses the beta flavor with its own application ID and app name ("SmartTube Surround"). Every value that upstream links to the application ID (search suggestion authority, search intent data, the video content provider authority) moves with it, so both apps install side by side without a provider conflict. The build removes upstream's `google-services.json` because it has no Firebase client for the patched application ID.
- **Versions.** The version code is the upstream version code times 100 plus the patch revision, a number this repository raises whenever the patch changes. Update ordering follows upstream, and a patch fix on the same upstream release still reaches the TV, because SmartTube's update check compares version codes. The version name adds a `-surround` suffix so the two apps are distinguishable. A release is named `<upstream tag>-r<patch revision>`.
- **Update channel.** The patch points the beta flavor's update URL list at the manifest attached to this repository's latest release. The manifest has upstream's format: a `package` block with a download URL list per ABI, and one entry per version with its version code and changelog. The TV's userspace is 32-bit, so the `armeabi-v7a` APK is the one that matters; the build publishes every ABI that upstream builds.
- **Signing.** A dedicated release keystore, generated once on the owner's Mac and stored at `~/.config/smarttube-surround/` with mode 600, signs every build. The workflow receives it and its passwords as GitHub Actions secrets and writes the `keystore.properties` file that upstream's build reads.
- **Audio change.** Inside the player's audio sink, when the input is 2-channel PCM and the stereo-to-rear setting is on, the patch maps stereo to 5.1 as front left = left, front right = right, center = silence, LFE = silence, rear left = left, rear right = right, encodes the 5.1 PCM, and writes the encoded stream to an AudioTrack in passthrough. Multichannel or already compressed input, a switched-off setting, or an output that does not report direct playback support for the encoded 5.1 format all leave the upstream path untouched.
- **Encoder.** The patch encodes with the TV's own AAC-LC encoder (`c2.android.aac.encoder`, 6 channels) and passes the AAC-LC 5.1 stream through, so it adds no native code. The on-TV prototype proved this path (see `memory-bank/research/2026-10-17-tv-audio-paths.md`) and found three rules the patch follows:
  - The encoded stream goes to the AudioTrack in ADTS framing; raw access units play nothing.
  - The 6 PCM channels go into the encoder in AAC order (center, left, right, rear left, rear right, LFE), not in Android's channel order; in Android order the front left channel came out of the center.
  - An AAC passthrough track ends with pause and flush, never with stop: a stopped AAC track keeps its output open after the app closes, and the TV has only two 5.1 passthrough outputs, so two leaks block all 5.1 passthrough, AC3 included, until the TV restarts.
  AC3 with a bundled encoder is the fallback only if the owner's listening test shows that AAC 5.1 does not reach the rear speakers while AC3 does.
- **Setting.** One boolean player setting, "Stereo to rear speakers", on by default, stored with SmartTube's other player settings. It also appears first in the player's quality dialog; flipping it there restarts the video.
- **Build workflow.** One GitHub Actions workflow runs daily and on manual dispatch with an optional upstream tag. It finds the newest upstream beta release, stops quietly when this repository already has a release for that upstream tag at the current patch revision, checks out the tag with submodules, applies the patch series with a three-way apply, builds the beta release APKs with JDK 17 (upstream CI's JDK), verifies the signature, and publishes a release named `<upstream tag>-r<patch revision>` with the APKs and the manifest.
- **Notifications.** Every failed step posts to the owner's existing ntfy topic (GitHub secret `NTFY_TOPIC`) with the step name, the upstream tag, and a link to the run, at high priority. A published build posts at low priority.
- **Patch size.** New behaviour lives in new files; the patch touches upstream files only at the hooks: the renderers factory or audio sink construction, the delay renderer's audio sync fix (so it reaches the sink that is actually playing), the player settings screen and the player's quality dialog, the update URL resource, and the flavor's application ID and app name.

## Testing Decisions

- A good test checks behaviour the owner or the TV can observe: what the TV sends to the soundbar, what the workflow publishes, and what arrives on ntfy. No test checks the patch's internal classes.
- **On-TV seam (carries the verification weight).** A script installs a patched build on the Sony TV, plays a known stereo video in it with the soundbar muted, and passes only when `dumpsys media.audio_flinger` shows a compressed direct output with a 5.1 channel mask while the video plays. The same script with the setting off must show the normal stereo PCM output. The owner's listening check, voices from the rear speakers, is the one manual layer, and each ticket that needs it ends as built, waiting for the owner.
- **Pipeline seam.** A manual dispatch of the workflow on the current upstream tag must publish a release whose APK verifies with the project's certificate, whose version code is upstream's times 100 plus the patch revision, and whose manifest lists that version code and the APK URLs.
- **Failure seam.** A dispatch with a deliberately broken patch must fail at the apply step and produce an ntfy message on the topic, checked through ntfy's poll API.
- **Update seam.** On the TV, the installed patched build must offer and install a newer patched release from the manifest.
- Prior art: `memory-bank/research/2026-10-17-tv-audio-paths.md` records the on-TV prototype; `scripts/check-surround.sh` provides the standalone on-TV check.

## Out of Scope

- The official YouTube app, the stable and F-Droid flavors, and the projector.
- Changing any multichannel track, or adding effects, level changes, or a center channel to stereo.
- Upstreaming the patch to SmartTube.
- Any change to the TV's or the soundbar's settings: Digital audio out stays Auto 2, and the soundbar stays in Vertical Surround Engine with 360 Spatial Sound Mapping off.

## Further Notes

- SmartTube is MIT-licensed and its vendored ExoPlayer 2.10.6 tree is Apache 2.0; the published repository keeps both notices.
- If the signing key is lost, the TV must uninstall the patched build before a build with a new key installs, which loses its sign-in and settings, so the owner keeps the key backed up.
- Facts behind these decisions: `memory-bank/research/2026-10-17-tv-audio-paths.md` and `memory-bank/research/2026-10-17-smarttube-internals.md`.
