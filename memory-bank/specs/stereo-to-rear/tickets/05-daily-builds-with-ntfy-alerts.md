# 05: Daily builds with ntfy alerts

**What to build:** the workflow also runs daily, finds the newest upstream beta release, does nothing when this repository already has its release, and otherwise builds and publishes it. Every failed step posts a high-priority ntfy message to the owner's existing topic with the step, the tag, and the run link; a published build posts a low-priority message.

**Blocked by:** 04 (GitHub builds and publishes a patched build on dispatch)

**Status:** built; the published-release message is checked on the next real release

- [x] NTFY_TOPIC is an Actions secret, set from ~/.config/mbp-power-watch/ntfy-topic without printing it
- [x] The scheduled path with no new upstream release ends quietly with no release and no message (proved by no-tag dispatch; a cron-triggered run has not been observed)
- [x] A dispatch with a deliberately broken patch fails at the apply step, and the ntfy poll API shows the alert with the step name and run link
- [ ] A successful publish shows the low-priority message in the ntfy poll API (check on the next real release; no test release was created)

Verification (2026-10-17):

- No-tag dispatch: https://github.com/armantark/smarttube-surround/actions/runs/39068448954 succeeded at "Skip existing release" with `32.56-r1 already exists; nothing to build.` All build, publish, and notification steps were skipped. Release IDs and tags were unchanged, and the ntfy poll returned no messages before or after the run. This checks the scheduled path by dispatch; a cron-triggered run has not been observed.

- Review: the spec and standards passes found blind release-creation retries could leave a draft that later runs skipped. Publication now reconciles remote release state on each attempt and replaces draft assets before publishing; the skip gate excludes drafts. The split build phases preserve the caller's directory for relative key paths, and the build directory is made absolute before the signing-file cleanup trap. Publication recovery has been reviewed, not exercised against a live release.

- Failure dispatch: https://github.com/armantark/smarttube-surround/actions/runs/39068509192 used upstream `32.54` on throwaway branch `test/ticket-05-daily-builds-20261017` at `e0accef`. The branch added an incomplete hunk in `patches/0000-failure-seam.patch` without changing `patch-revision`. "Apply patches" failed; signing-key restoration, compilation, publication, and publication notification were skipped. "Notify failure" succeeded. Release IDs and tags were unchanged. The branch was deleted from GitHub, and `git ls-remote` returned no matching ref.

  Exact runner error (GitHub masked the repository path): `error: corrupt patch at /home/runner/work/***/***/patches/0000-failure-seam.patch:7`, followed by `Process completed with exit code 128.`

  The Mac polled ntfy's JSON API and verified the body contained `Upstream 32.54`. Only these fields were printed:

```json
{"title":"SmartTube failed: Apply patches","priority":5,"click":"https://github.com/armantark/smarttube-surround/actions/runs/39068509192"}
```

- Local checks: Bash syntax checking passed for every script in `scripts/`; actionlint passed for `.github/workflows/build.yml` with its optional ShellCheck integration disabled (ShellCheck is unavailable on PATH). No new published release or publication notification was tested. The initial no-tag dispatch, before the review fixes, also succeeded: https://github.com/armantark/smarttube-surround/actions/runs/39068333347.
