# 01: Prove which 5.1 path reaches the rear speakers

**What to build:** evidence, on the owner's Sony TV, of which way an ordinary app can send a 5.1 stream through the TV to the soundbar: AC3 passthrough, AAC-LC 5.1 passthrough, or 6-channel PCM encoded on the TV with its own AAC encoder and then passed through. The verdict picks the patch's encoder.

**Blocked by:** None (can start immediately)

**Status:** claimed by the surround-probe prototype agent

- [ ] For each path, the TV-side result is recorded: AudioTrack created or the exact error, playback head moving, and the audio_flinger output (format, channel mask, device) while it plays
- [ ] A one-command listening test exists for each path, for the owner
- [ ] The prototype README states the question, the verdict per path, and what waits for the owner's ears
- [ ] The owner has listened and confirmed which path plays voices from the rear speakers
