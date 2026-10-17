# 03: Stereo plays from the rear speakers in the patched build

**What to build:** the stereo-to-rear audio change in the patched build: 2-channel PCM becomes 5.1 with left and right copied to the rear channels, encoded with the encoder that ticket 01 picked, and passed through to the soundbar. Multichannel tracks and the switched-off setting keep the upstream path. A "Stereo to rear speakers" player setting, on by default, controls it.

**Blocked by:** 01 (Prove which 5.1 path reaches the rear speakers), 02 (A patched build installs beside SmartTube on the TV)

**Status:** claimed by implementer-03

- [ ] A script plays a known stereo video in the patched build with the soundbar muted, and passes only when audio_flinger shows a compressed 5.1 direct output during playback
- [ ] With the setting off, the same script shows the normal stereo PCM output
- [ ] A 5.1 video plays through the upstream path unchanged
- [ ] When the output reports no direct playback support for the encoded 5.1 format, playback falls back to normal stereo without silence
- [ ] The owner hears voices from the rear speakers (owner layer)
