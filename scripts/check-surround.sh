#!/usr/bin/env bash
# Checks which audio output SmartTube Surround opens on the Sony TV for a stereo video.
#
# Usage: scripts/check-surround.sh <on|off>
#   on   passes when the "Stereo to rear speakers" setting is on and audio_flinger shows a
#        compressed AAC-LC 5.1 direct output on HDMI ARC with a playing track from the app
#   off  passes when the setting is off and the app's track plays on the stereo PCM mixer output
#
# The soundbar is muted through its own Audio Control API before anything plays, and stays muted:
# the TV's mute key toggles, and the TV's mute does not silence passthrough. When the setting
# differs from the request, the script flips the first switch in the player's playback settings,
# so the setting stays as requested afterwards. Playback is paused as soon as the output is
# measured, then the player closes, and the check fails if a compressed output is still open:
# the TV has two, and a leaked one blocks 5.1 passthrough until the TV restarts.
#
# Environment:
#   TV            adb address of the TV (192.168.0.3:5555)
#   SOUNDBAR      host:port of the soundbar's Audio Control API (192.168.0.196:10000)
#   VIDEO         a stereo YouTube video ID (iG9CE55wbtY, a TED talk with stereo Opus audio)
#   EVIDENCE_DIR  where the audio_flinger capture, log lines, and screenshots go (a new temp dir)
set -euo pipefail

mode=${1:-}
[[ $mode == on || $mode == off ]] || { echo "usage: $0 <on|off>" >&2; exit 2; }
export ADB_USB=0 # adb's USB backend hangs the owner's Mac
tv=${TV:-192.168.0.3:5555}
soundbar=${SOUNDBAR:-192.168.0.196:10000}
video=${VIDEO:-iG9CE55wbtY}
evidence=${EVIDENCE_DIR:-$(mktemp -d -t check-surround)}
mkdir -p "$evidence"
package=io.github.armantark.smarttubesurround
splash=$package/com.liskovsoft.smartyoutubetv2.tv.ui.main.SplashActivity

adb() { command adb -s "$tv" "$@"; }
key() { adb shell input keyevent "$1"; sleep "${2:-1}"; }
note() { echo "[$(date '+%H:%M:%S')] $*"; }
fail() { echo "FAIL: $*" >&2; echo "evidence: $evidence" >&2; exit 1; }

soundbar_call() {
  curl -sS -m 10 --retry 3 --retry-all-errors -X POST "http://$soundbar/sony/audio" \
    -H 'Content-Type: application/json' -d "$1"
}

soundbar_muted() {
  soundbar_call '{"method":"getVolumeInformation","id":1,"params":[{"output":""}],"version":"1.1"}' |
    python3 -I -c 'import json, sys; outputs = json.load(sys.stdin)["result"][0]; sys.exit(0 if outputs and all(o["mute"] == "on" for o in outputs) else 1)'
}

mute_soundbar() {
  soundbar_muted && return
  note "muting the soundbar"
  soundbar_call '{"method":"setAudioMute","id":1,"params":[{"mute":"on"}],"version":"1.1"}' >/dev/null
  sleep 1
  soundbar_muted || fail "the soundbar at $soundbar does not report mute on"
}

# Sets $open and $active to the counts of the TV's compressed passthrough outputs.
read_compressed_outputs() {
  local i counts
  for i in 1 2 3; do
    counts=$(adb shell dumpsys media.audio_policy | awk '
      /name: non_hw_av_sync_compressed/ { found = 1 }
      found && /curOpenCount/ { open = $NF }
      found && /curActiveCount/ { print open, $NF; exit }')
    [[ -n $counts ]] && break
    sleep 2
  done
  [[ -n $counts ]] || fail "dumpsys media.audio_policy shows no non_hw_av_sync_compressed output"
  read -r open active <<<"$counts"
}

# The audio format line of ExoPlayer's renderer, then the sink's routing line if the setting is on.
audio_started() { adb logcat -d | command grep -a -q 'onInputFormatChanged: format = Format(.*audio/'; }
route_lines() { adb logcat -d -s StereoToRear:I | command grep -a 'StereoToRear' || true; }

# Waits for the audio track to start and prints "on" when the stereo-to-rear sink handles it.
read_setting() {
  local i
  for i in $(seq 1 45); do audio_started && break; sleep 1; done
  audio_started || fail "no audio format was logged within 45 s of opening the video"
  sleep 3
  if [[ -n $(route_lines) ]]; then echo on; else echo off; fi
}

# Prints the audio_flinger output threads that carry an active track of process $1, one line each:
# "<type> <hal format> <channel mask> <devices> <track format> <track mask>".
active_outputs() {
  awk -v pid="$1" '
    /^Output thread/ { type = ($0 ~ /\(DIRECT\)/) ? "DIRECT" : ($0 ~ /\(MIXER\)/) ? "MIXER" : "OTHER" }
    /^  HAL format:/ { format = $3 }
    /^  Channel mask:/ { mask = $3 }
    /^  Output devices:/ { devices = $4 }
    {
      for (i = 1; i < NF; i++) {
        if ($i == "yes" && $(i + 1) == pid) { print type, format, mask, devices, $(i + 6), $(i + 7) }
      }
    }'
}

expected_output() {
  case $mode in
    on) command grep -a -q -E '^DIRECT 0x4000002 0x0000003f \(AUDIO_DEVICE_OUT_HDMI_ARC\)' ;;
    off) command grep -a -q -E '^MIXER 0x1 0x00000003 \(AUDIO_DEVICE_OUT_HDMI_ARC\) 00000001 00000003' ;;
  esac
}

pause_if_playing() {
  if adb shell dumpsys activity activities | command grep -a -q 'mResumedActivity.*PlaybackActivity'; then
    adb shell input keyevent KEYCODE_MEDIA_PAUSE
  fi
}

leave_player() {
  local i
  for i in 1 2 3; do
    adb shell dumpsys activity activities | command grep -a -q 'mResumedActivity.*PlaybackActivity' || return 0
    key KEYCODE_BACK 2
  done
  fail "the player is still open after three presses of Back"
}

adb get-state >/dev/null || fail "no adb connection to $tv"
adb shell pm path "$package" >/dev/null || fail "$package is not installed on $tv"
mute_soundbar
read_compressed_outputs
[[ $active == 0 ]] || fail "$active compressed output(s) already active before the check; another app is playing 5.1, or one leaked"

note "opening https://www.youtube.com/watch?v=$video"
key KEYCODE_WAKEUP # a screensaver would hide the player
trap pause_if_playing EXIT # nothing plays after the script ends, even when it fails
adb logcat -c
adb shell am start -a android.intent.action.VIEW -d "https://www.youtube.com/watch?v=$video" -n "$splash" >/dev/null
setting=$(read_setting)
note "stereo to rear speakers is $setting"
if [[ $setting != "$mode" ]]; then
  note "flipping the setting in the player's playback settings"
  sleep 4 # the player controls hide 3 s after the last key; the next key must show them, not press a button
  adb logcat -c
  key KEYCODE_DPAD_CENTER # shows the player controls, focus on play/pause
  key KEYCODE_DPAD_DOWN   # the playback settings button, first in the lower row
  key KEYCODE_DPAD_CENTER # opens them, with the stereo-to-rear switch first and focused
  key KEYCODE_DPAD_CENTER # flips it; the player restarts with the new setting
  adb shell screencap -p /sdcard/check-surround.png && adb pull -q /sdcard/check-surround.png "$evidence/settings.png"
  key KEYCODE_BACK
  setting=$(read_setting)
  [[ $setting == "$mode" ]] || fail "the setting is still $setting after flipping it; see $evidence/settings.png"
fi
route_lines > "$evidence/route.txt"
cat "$evidence/route.txt"

mute_soundbar
key KEYCODE_MEDIA_PLAY 0 # a restart for the new setting can leave the player paused
pid=$(adb shell pidof "$package")
passed=false
for attempt in $(seq 1 15); do
  # The dump sometimes comes back empty or cut short, so sample until the output shows up.
  adb shell dumpsys media.audio_flinger > "$evidence/audio_flinger.txt" 2>&1 || true
  active_outputs "$pid" < "$evidence/audio_flinger.txt" > "$evidence/outputs.txt"
  if expected_output < "$evidence/outputs.txt"; then
    passed=true
    break
  fi
  sleep 2
done
key KEYCODE_MEDIA_PAUSE 0
note "outputs with an active track of the app (attempt $attempt): type, HAL format, mask, devices, track format, track mask"
cat "$evidence/outputs.txt"

leave_player
sleep 3
read_compressed_outputs
note "compressed outputs after the player closed: $open open, $active active"
[[ $open == 0 && $active == 0 ]] ||
  fail "a compressed output is still open after the player closed; 5.1 passthrough may stay blocked until the TV restarts"
$passed || fail "no $([[ $mode == on ]] && echo 'AAC-LC 5.1 direct' || echo 'stereo PCM mixer') output with an active track of the app in $attempt samples"
note "PASS ($mode); the soundbar stays muted; evidence: $evidence"
