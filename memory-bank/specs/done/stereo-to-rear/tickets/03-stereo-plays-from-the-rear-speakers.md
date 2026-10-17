# 03: Stereo plays from the rear speakers in the patched build

**What to build:** the stereo-to-rear audio change in the patched build: 2-channel PCM becomes 5.1 with left and right copied to the rear channels, encoded with the encoder that ticket 01 picked, and passed through to the soundbar. Multichannel tracks and the switched-off setting keep the upstream path. A "Stereo to rear speakers" player setting, on by default, controls it.

**Blocked by:** 01 (Prove which 5.1 path reaches the rear speakers), 02 (A patched build installs beside SmartTube on the TV)

**Status:** done

- [x] A script plays a known stereo video in the patched build with the soundbar muted, and passes only when audio_flinger shows a compressed 5.1 direct output during playback
- [x] With the setting off, the same script shows the normal stereo PCM output
- [x] A 5.1 video plays through the upstream path unchanged
- [x] When the output reports no direct playback support for the encoded 5.1 format, playback falls back to normal stereo without silence
- [x] The owner hears voices from the rear speakers (owner layer; 2026-10-17, and they leave the rear speakers with the setting off)

TV-side verdict (2026-10-17, patches 0003 and 0004 on upstream 32.56), evidence in `memory-bank/specs/stereo-to-rear/evidence/03/`:

- `scripts/check-surround.sh on` passed: a DIRECT output with HAL format AAC_LC, mask 0x3f, on HDMI ARC, carrying the app's active track (`check-on.txt`). `scripts/check-surround.sh off` passed: the app's 16-bit stereo track on the PCM mixer output (`check-off.txt`). Both closed every compressed output after the player closed.
- SmartTube 32.56 gets no 5.1 track from YouTube (its Audio formats list only Opus and MP4A, upstream issue [#6335](https://github.com/yuliskov/SmartTube/issues/6335)), so a test build played local 5.1 files instead (`test-build.patch`). With the setting on and off alike, 5.1 AC3 went to the AC3 direct output and 5.1 AAC played as 6-channel PCM on the mixer, the upstream path (`surround-ac3-*.txt`, `surround-aac-*.txt`).
- The same test build forced both fallbacks. With no direct playback support reported, and with the AAC output failing to open, stereo played on the PCM mixer, its frame counter advancing in real time (`fallback-no-direct.txt`, `fallback-no-output.txt`).
- Also checked on the TV: 2x speed (the position advanced 23 s in 12 s on the AAC path), seeking, a video's end moving on to the next one, 44.1 kHz stereo (`stereo-44100-setting-on.txt`), and Back, Home, and three force-stops during AAC playback, none of which left a compressed output open.

The owner's listening check: unmute the soundbar, play a stereo video with speech in SmartTube Surround, for example [Do schools kill creativity?](https://www.youtube.com/watch?v=iG9CE55wbtY), and listen for the voice in the rear speakers and for lip sync. "Stereo to rear speakers", the first switch under the player's HQ button, flips between this path and plain stereo for comparison.
