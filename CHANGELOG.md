# Changelog

## 25.0.1 - 2026-10-22

First public release of the source. The script is the v25.0.1 build, with these changes for the public repository:

- The skin sync server is now `Config.SyncUrl`. An empty string turns skin sync off.
- The last Portuguese messages are now in English.
- `Store.write` no longer returns an error message together with a successful save. Callers only read the message after a failure, so nothing visible changes.
- Comments were trimmed to the ones that explain fragile or non-obvious code. The longer explanations moved to `docs/`.

Changes in the 25.0.1 build itself: saved skins accept HDR colours and particle acceleration, and effect values Roblox cannot rebuild are skipped instead of failing the whole skin.

## Earlier versions

Summaries come from the original release notes.

- **25.0.0**: skin sync between script users, a visual-only overlay mode that follows Evade's render rig, a fix for hovering and double jumps after a body change, lighter saving, and the shop's Limiteds filter and item ID search.
- **20.0.0**: skins keep their visual effects (particles, fire, sparkles, smoke, lights, trails and beams). An unused `__namecall` hook was removed.
- **15**: released as Avatar Studio. The updates that followed added reopening the hidden window by opening the Roblox menu 3 times, reopen hints limited to the methods that work on the device, shop emotes, folded advanced options, applied avatars kept in Recent, the interface size setting at the top of Settings with an 85% default, shop sub-filters, and your worn avatar in the Roblox menu.
- **14.7**: in-window toast notifications, resize animations and Creator page tweaks. 14.7.1 fixed toasts stretching to the full screen height.
- **14.6**: swap effect, visual timeline and a compact, resizable window.
- **14.5**: first version kept in source control.
