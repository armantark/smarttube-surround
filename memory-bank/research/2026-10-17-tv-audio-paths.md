# Sony XR-65A80L audio paths to the HT-A3000 (measured 2026-10-17)

Input for the SmartTube stereo-to-rear patch spec. All facts read from the TV over adb or
heard by the owner; none from memory.

## What the TV can send to the soundbar

- Output device: `AUDIO_DEVICE_OUT_HDMI_ARC` (eARC HAL running, eARC mode Auto).
- Every PCM output port (`primary output`, `hw_av_sync`, `mmap_no_irq_out`) takes channel
  mask `0x0003` (stereo) at most. An app cannot hand the TV 5.1 PCM.
- The compressed passthrough ports (`non_hw_av_sync_compressed`, `hw_av_sync_compressed`) take
  AC3, E-AC3, E-AC3-JOC, AC4, DTS, DTS-HD, AAC-LC, HE-AAC v1/v2, with channel masks up to
  `0x003f` (5.1) and `0x063f` (7.1).
- Sony Settings > Display & Sound > Audio output > Digital audio out must stay `Auto 2`
  ("Output only compressed audio for multi-channel content without change"). With `Auto 1`
  stereo reached no rear speaker in any soundbar mode.

## Encoders an app can use on the TV

- No AC3, E-AC3, or DTS encoder in any `media_codecs*.xml`.
- `c2.android.aac.encoder` (and `OMX.google.aac.encoder`), `audio/mp4a-latm`, channel-count max 6.

## Soundbar behaviour (owner listened)

- Mode in use: 360 Spatial Sound Mapping Off, Sound Field Setting Sony | Vertical Surround
  Engine, Sound Field on, Voice on, rear level 12 (`./soundbar.py list`).
- Stereo from the TV now reaches the rear speakers, but only the room sound; voices stay in front.
- With 360 Spatial Sound Mapping on, stereo never reaches the rear speakers (TV or Spotify cast).
- Real 5.1 content plays from the rear speakers in every mode.

## Open question for a prototype

Does the soundbar play a 5.1 AAC-LC stream sent by an app through the TV, with sound in the
rear channels? If yes, the patch can use the TV's own AAC encoder; if no, it must bundle an
AC3 encoder (for example FFmpeg's) and send AC3. Test with two files whose rear channels
carry a distinct tone: 5.1 AAC-LC and 5.1 AC3.

## Measured while building the patch (ticket 03)

- `c2.android.aac.encoder` puts 2048 frames of priming ahead of the input: decoding the
  prototype's `encoded-c.aac` gave the first loud sample at frame 6390, against 4342 in
  `channels-5.1.wav`. The AAC track's playback position counts those frames.
- At the end of a stream the encoder takes the end-of-stream flag only in a free input buffer, and
  it frees none while its encoded output waits to be dequeued; a sink that waits for the input
  buffer before writing the output stalls one second before the end of every video.
- A playing AAC track whose app is killed (`am force-stop`, three runs) closes its compressed
  output within 5 s. Only a track ended with `stop()` held its output open.
- The direct AAC track's playback head trails the written stream by about 1.5 s (the HAL's buffer
  plus a 32 KiB track buffer); `AudioTrack.getTimestamp` works on it.
- AAC-LC 5.1 at 44.1 kHz opens the same direct output as 48 kHz.
- SmartTube 32.56 plays Opus 48 kHz stereo (itag 251) by default on this TV, and YouTube sends it no
  5.1 track at all ([SmartTube #6335](https://github.com/yuliskov/SmartTube/issues/6335)). Its auto
  volume sets the player volume per video (0.5 on a TED talk), which a passthrough track ignores.
- The TV's mute key mutes `STREAM_MUSIC` on the TV, yet test playback was still audible
  through the soundbar. Only the soundbar's own mute, set and read back through its Audio Control
  API (`setAudioMute`, `getVolumeInformation`), keeps tests silent.

