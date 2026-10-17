# Sony TV update check, 2026-10-17

SmartTube Surround installed release `32.56-r2` over `32.56-r1` through its own update
flow on `192.168.0.3:5555`. No patch fix, release publication, or push was needed.

The initial installed version was `244602` ([initial package dump](version-initial.txt)).
The owner authorized uninstalling only `io.github.armantark.smarttubesurround` and installing
the GitHub `32.56-r1` armeabi-v7a APK with adb. Both commands returned `Success`.
The downloaded Android package (APK) had the expected package, versionCode `244601`, and the certificate digest
in the repository's `certificate-sha256` file. Android's package dump then reported
`versionCode=244601 minSdk=17 targetSdk=34` ([before](version-before.txt)).

The APK's [update URL resource](r1-update-url.txt) names
https://github.com/armantark/smarttube-surround/releases/latest/download/smarttube_surround.json.
The [downloaded manifest](smarttube_surround.json) lists `244602` and the `32.56-r2` APK URLs.
The app's update screen displayed the manifest's changelog, “Upstream SmartTube 32.56 with
patch revision 2.” Selecting Install update opened Android's installer. The newer APK was
installed through that flow, with remote keys. Codex used Android Debug Bridge (adb) to install
only the older build.

After Android displayed “App installed.”, the package dump reported
`versionCode=244602 minSdk=17 targetSdk=34` ([after](version-after.txt),
[final recheck](version-final.txt)). The Teal color setting selected on r1 remained selected
on r2. The app showed Sign in afterward. Codex did not check signed-in session preservation.
The owner accepted the signed-out state. Codex then restored the Dark Grey color setting.

Screens passed, in order (paths are relative to this evidence directory):

| Screen | Screenshot |
| --- | --- |
| Teal setting selected on r1 | [screens/07-r1-teal.png](screens/07-r1-teal.png) |
| Settings > About | [screens/08-about.png](screens/08-about.png) |
| Check for updates offered Install update | [screens/09-update-offer.png](screens/09-update-offer.png) |
| Changelog identified patch revision 2 | [screens/10-changelog.png](screens/10-changelog.png) |
| Android required unknown-source permission | [screens/11-unknown-source-blocked.png](screens/11-unknown-source-blocked.png) |
| Sony settings showed SmartTube Surround Allowed | [screens/17-surround-allowed-in-settings.png](screens/17-surround-allowed-in-settings.png) |
| Android asked “Do you want to update this app?” | [screens/32-installer.png](screens/32-installer.png) |
| Installing | [screens/33-installing.png](screens/33-installing.png) |
| App installed | [screens/34-installed.png](screens/34-installed.png) |
| Teal setting retained on r2 | [screens/36-r2-teal-preserved.png](screens/36-r2-teal-preserved.png) |
| App remained signed out | [screens/37-r2-signed-out.png](screens/37-r2-signed-out.png) |
| Original Dark Grey setting restored | [screens/40-restored-color-selection.png](screens/40-restored-color-selection.png) |
| Final idle screen after the app restarted | [screens/42-final-idle.png](screens/42-final-idle.png) |

A manual updater helper captured the settings and final screens in this record, with one
remote key per adb call and a pause. The helper is no longer part of the repository.
`scripts/check-surround.sh` performs the audio check without an external repository.

## Sony permission failure and recovery

The first Install update showed this exact Android message:

> For your security, your phone currently isn’t allowed to install unknown apps from this source. You can change this in Settings.

The Sony screen changed SmartTube Surround to Allowed, but Install update showed the same
message again. [AppOps](install-appops.txt) showed `REQUEST_INSTALL_PACKAGES (deny)` for
`u0a233` and `REQUEST_INSTALL_PACKAGES (allow)` for `u10a233`. Android reported current user
`0`; user `10` was the inactive `com.android.tv.profile` in `QUIET_MODE`. The Sony list had
granted permission to user 10 instead of user 0.

The owner explicitly authorized this same permission for user 0, then the installation with
remote keys. Codex used these commands:

```sh
ADB_USB=0 adb -s 192.168.0.3:5555 shell appops set --user 0 io.github.armantark.smarttubesurround REQUEST_INSTALL_PACKAGES allow
ADB_USB=0 adb -s 192.168.0.3:5555 shell appops get --user 0 io.github.armantark.smarttubesurround REQUEST_INSTALL_PACKAGES
```

The [verification output](user-0-install-permission.txt) was
`REQUEST_INSTALL_PACKAGES: allow; rejectTime=+1m41s523ms ago`. The reject time records the
earlier denial; the current mode was allow. A subsequent Install update reached the update
confirmation dialog. Codex selected Update and Open with remote keys.

## Audio after the update

Both checks ran against the installed package without an APK argument. The soundbar's Audio
Control application programming interface (API) kept the soundbar muted. Full stdout is in [check-off.txt](check-off.txt) and
[check-on.txt](check-on.txt). The audio_flinger dumps, extracted outputs, route logs, and
settings screenshots are in [check-off/](check-off/) and [check-on/](check-on/).

The off check output included:

```text
[16:02:47] outputs with an active track of the app (attempt 1): type, HAL format, mask, devices, track format, track mask
MIXER 0x1 0x00000003 (AUDIO_DEVICE_OUT_HDMI_ARC) 00000001 00000003
[16:02:52] compressed outputs after the player closed: 0 open, 0 active
```

It ended with `PASS (off)`. The on check output included:

```text
10-17 16:03:09.120 12004 12824 I StereoToRear: AAC-LC 5.1 at 48000 Hz with the rear pair copying the front
[16:03:17] outputs with an active track of the app (attempt 1): type, HAL format, mask, devices, track format, track mask
DIRECT 0x4000002 0x0000003f (AUDIO_DEVICE_OUT_HDMI_ARC) 04000002 0000003F
[16:03:23] compressed outputs after the player closed: 0 open, 0 active
```

It ended with `PASS (on)`. Stereo to rear speakers stayed on. Codex closed the player before
the API call to unmute the soundbar. The final Audio Control API read reported
`{"maxVolume":100,"minVolume":0,"mute":"off","step":1,"volume":26}`
([raw response](soundbar-final.json)). Codex did not do a listening check during this test.

## Other resolved test friction

- `apkanalyzer manifest application-id` and `apkanalyzer manifest version-code` failed with
  `java.lang.IllegalStateException: Cannot locate latest build tools`. Calling the SDK's
  `build-tools/35.0.0/aapt` directly verified the package and version instead.
- The attempt to view `/tmp/smarttube-ticket-06/36-r2-teal-preserved.png` before a long navigation command
  finished failed with `No such file or directory (os error 2)`. The command completed.
  Codex then viewed the saved image. Longer key sequences used a 30-second wait.
- The audio check clears logcat, so an attempt to save the earlier updater log afterward
  found no `App update received` lines. The resource, manifest, changelog, and installer
  screenshots above remain the saved evidence of the update flow.

Codex logged these incidents and the user-10 permission grant in
`/Users/ArmanTarkhanian1/tv-setup/PAPERCUTS.md`. The commit excludes that file.
