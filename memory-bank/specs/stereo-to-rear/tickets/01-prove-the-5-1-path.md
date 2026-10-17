# 01: Prove which 5.1 path reaches the rear speakers

**What to build:** evidence, on the owner's Sony TV, of which way an ordinary app can send a 5.1 stream through the TV to the soundbar: AC3 passthrough, AAC-LC 5.1 passthrough, or 6-channel PCM encoded on the TV with its own AAC encoder and then passed through. The verdict picks the patch's encoder.

**Blocked by:** None (can start immediately)

**Status:** built; the owner's listening test waits for the owner

- [x] For each path, the TV-side result is recorded: AudioTrack created or the exact error, playback head moving, and the audio_flinger output (format, channel mask, device) while it plays
- [x] A one-command listening test exists for each path, for the owner
- [x] The prototype README states the question, the verdict per path, and what waits for the owner's ears
- [ ] The owner has listened and confirmed which path plays voices from the rear speakers

TV-side verdict (2026-10-17): AC3 5.1, AAC-LC 5.1 in ADTS, and 6-channel PCM through the TV's AAC encoder all opened a compressed 5.1 output on HDMI ARC and played to the end; raw AAC access units played nothing. Listening commands are in `~/tv-setup/memory-bank/prototypes/surround-probe/README.md`.
