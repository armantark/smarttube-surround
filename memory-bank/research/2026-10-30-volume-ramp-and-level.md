# Volume rise on start and resume, and low volume

Owner report, 2026-10-30 15:30 PDT: SmartTube Surround audio rises in volume when a video starts and when it resumes after a pause of a few seconds. It is also soft: a video that played at soundbar volume 25 before now needs about 40.

## Low volume

`upmix` in `patches/0004-Play-stereo-from-the-rear-speakers-as-well-as-the-fr.patch` writes silence to the centre and LFE channels. In stereo PCM the HT-A3000 makes its own centre channel, and its Voice setting raises that centre. With a silent centre, voices play only from the front left and right, and Voice has nothing to raise. Proposed fix: centre = (left + right) / 2, computed in `int` so it cannot overflow. Not built or measured.

## Volume rise

Unconfirmed cause: `AacSurroundAudioSink.pause()` pauses the passthrough `AudioTrack`. After a few seconds the TV puts the compressed output in standby, the AAC stream to the soundbar stops, and on resume the soundbar locks on to a new stream and fades it in. A new video also starts a new stream. A pause shorter than the standby delay does not cause a rise, which matches the report. To test: log the soundbar input format during a pause with `soundbar.py` in ~/tv-setup, and time the rise against pause lengths of 1, 3, and 10 s. A fix keeps the stream alive by writing encoded silence while paused, and must keep the playback position correct when play resumes.
