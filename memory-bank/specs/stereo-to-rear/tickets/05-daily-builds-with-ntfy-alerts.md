# 05: Daily builds with ntfy alerts

**What to build:** the workflow also runs daily, finds the newest upstream beta release, does nothing when this repository already has its release, and otherwise builds and publishes it. Every failed step posts a high-priority ntfy message to the owner's existing topic with the step, the tag, and the run link; a published build posts a low-priority message.

**Blocked by:** 04 (GitHub builds and publishes a patched build on dispatch)

**Status:** open

- [ ] NTFY_TOPIC is an Actions secret, set from ~/.config/mbp-power-watch/ntfy-topic without printing it
- [ ] A scheduled run with no new upstream release ends quietly with no release and no message
- [ ] A dispatch with a deliberately broken patch fails at the apply step, and the ntfy poll API shows the alert with the step name and run link
- [ ] A successful publish shows the low-priority message in the ntfy poll API
