# Final review fixes, 2026-10-17

Patch revision 3 fixes the seven final-review findings. No release was published and no remote
was pushed. Only `io.github.armantark.smarttubesurround` was installed or stopped on the TV.

## Production build and TV checks

The private upstream checkout used `BUILD_DIR=$HOME/.cache/smarttube-surround/upstream-fixes`.
Two consecutive `scripts/build.sh 32.56 --build-only` invocations succeeded. The second reused
the already-patched build file, which is the case that compounded version codes. Both
[aapt2 badging lines](badging-first.txt) report `244603` ([second](badging-second.txt)).
The APKs passed [certificate verification](signatures.txt).

The new armeabi-v7a APK installed with `ADB_USB=0 adb -s 192.168.0.3:5555 install -r`:
[install output](install.txt). Both standalone checks passed, off first and on second:

- [Off stdout](check-off.txt): stereo PCM mixer on HDMI ARC; zero compressed outputs open or active after closing the player.
- [On stdout](check-on.txt): AAC-LC 5.1 direct output on HDMI ARC; zero compressed outputs open or active after closing the player.

The setting stayed on. The soundbar was muted through its Audio Control API while testing,
then unmuted through the API. The [final API response](soundbar-final.json) reports
`"mute":"off"`, volume `26`. The production APK was reinstalled after the diagnostic probes:
[installed version](installed-final.txt). The [final compressed port dump](compressed-final.txt)
reports `curOpenCount: 0` and `curActiveCount: 0`.

## Finding 2: upstream renderer, sink, and sync fix

A throwaway build added `[DEBUG-r3]` logs and a local media-source override. A file flag enabled
the real sync fix without changing the stored setting. Stereo-to-rear remained on throughout.
The diagnostic source changes and APK are not committed.

- [Decoded 5.1 AAC](upstream-sync/observations.txt): six channels, PCM encoding `2`, default path; `sync fix applied: sink=DefaultAudioSink, tracker=AudioTrackPositionTracker, timestamp=null, state=3`.
- [Compressed AC3](upstream-compressed/observations.txt): six channels, encoding `5`, default path; the same sync-fix success log.
- [Sync fix off](upstream-renderer/observations.txt): `upstream renderer, stereoToRear=true`, followed by the six-channel default path. This proves the factory's early return runs again.

Each probe's `audio_flinger.txt` records the playing output; each `audio_policy-after.txt`
records zero compressed outputs open or active after the app stopped.

## Finding 3: silence skipping and EOS

The diagnostic build forced silence skipping in the actual AAC sink's processor chain. The
local stereo fixture was 12 seconds, 48 kHz, with three seconds of left/right tones followed
by silence. Its generation command was:

```sh
ffmpeg -hide_banner -loglevel error -f lavfi -i 'color=c=blue:s=320x180:r=15:d=12' -f lavfi -i 'aevalsrc=if(lt(t\,3)\,0.1*sin(2*PI*440*t)\,0)|if(lt(t\,3)\,0.1*sin(2*PI*660*t)\,0):s=48000:d=12' -c:v libx264 -preset ultrafast -c:a aac -b:a 128k -shortest /tmp/stereo-trailing-silence.mp4
```

[The completion excerpt](stereo-eos/completion.txt) contains this sequence:

- `16:19:16.585`: `applyPlaybackParameters skipSilence=true`.
- `16:19:18.653`: `processors drained: skippedFrames=430595`.
- `16:19:18.656`: `encoder EOS queued`.
- `16:19:18.661`: `encoder EOS received and track draining`.
- `16:19:19.394`: `state=STATE_ENDED`, position `12004`, duration `12000`.
- `16:19:20.271`: another media source opens.
- `16:19:20.526`: the next video reaches `STATE_READY`, playing true, position zero.

[The full selected log](stereo-eos/observations.txt) shows further end/next transitions. The
first fixture load sought to its end; the excerpt above selects the following playback,
which processed and skipped the trailing silence. Screenshots alone show only the synthetic
blue video, so the log carries the end/next proof.

## Build and release-tool findings

The version code now comes from `git show refs/tags/<tag>:smarttubetv/build.gradle`.
Gradle runs through `scripts/retry.sh`, so the wrapper's distribution download and dependency
requests receive retries. The workflow failure header and README now say priority `4`.
No live ntfy message or GitHub workflow dispatch was sent for this review.

[Release staging](release-assets.txt) downloaded the live latest manifest with retries and
preserved its r2 entry (`244602`) while adding r3 (`244603`): [history](manifest-history.json).
Version-entry keys include the patch revision to retain rebuilds on the same upstream tag.
The [fixture check](manifest-fixture-check.py), run from the repository root, covers preserved
history, an absent manifest, and failure without history replacement:
[results](manifest-fixtures.txt). The intentional HTTP 503 fixture returns
`could not download the latest manifest: HTTP 503` and creates no replacement manifest.

The manual updater helper was deleted. `scripts/`, `.github/`, `patches/`, and `README.md`
have no `tv-setup` reference; the production on/off commands ran without that repository.
The spec also records the quality-dialog switch/restart and Firebase-config removal.

## Test friction

No build or TV check failed. The non-blocking inspection and probe issues are recorded with
exact strings in `memory-bank/papercuts.md`: CRLF-bearing patch context makes the default
Git whitespace check complain, the app's external-files directory needed creation, and the
probe's EOS grep used the wrong spelling of `STATE_ENDED`, so it waited longer than needed.
The patch's reverse-application check passed. A final full build reapplied the committed
patch series from the pristine tag after removing all diagnostic source changes.
