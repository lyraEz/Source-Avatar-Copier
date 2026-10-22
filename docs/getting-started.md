[Docs](README.md) / **Getting started**

# <img src="assets/icons/start.png" width="40" alt=""> Getting started

From nothing to wearing someone else's avatar, in a few steps.

## What you need

- **Roblox** on PC or phone.
- **An executor** that can run a client-side Luau script.

> [!CAUTION]
> Third-party executors are against the Roblox Terms of Use. Use them at your own risk.

Some executor functions are optional. Without them the script still runs, and only the related feature is off:

| Function | Used for | Without it |
| --- | --- | --- |
| `readfile`, `writefile`, `isfile` | Saving favorites, skins and settings | Everything lasts until you leave the game |
| `getcustomasset` (or `getsynasset`) | The icon sheet, the logo, the creator photo | Simpler drawn icons and an "AC" logo |
| `setclipboard` (or `toclipboard`) | Copying share codes and links | The text is shown so you can copy it by hand |
| `request` (or `http_request`, `syn.request`) | Skin sync and the creator photo | No skin sync |
| `firetouchinterest` | ToolsGiver touching tools lying in the world | Tools are still copied, just not touched first |

## 1. Run the script

Paste the contents of [`src/avatar-copier.lua`](../src/avatar-copier.lua) into your executor and run it. While this repository is public you can also load it straight from GitHub:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/lyraEz/Source-Avatar-Copier/main/src/avatar-copier.lua"))()
```

The **Avatar Studio** window opens. Running the script again closes the old copy first, so you never end up with two windows.

## 2. Copy an avatar

1. In **Copy Avatar**, type a username or a user ID and press <kbd>Enter</kbd>.
2. Turn the 3D preview around with your mouse or finger.
3. Tap **Apply avatar**.

That's it. Details in [Copy Avatar](tabs/copy-avatar.md).

## 3. Get your own look back

- **Undo** goes back one step.
- The **timeline** pictures go back to any look of this session.
- **Restore** puts back the avatar you had when the script started.

> [!TIP]
> Respawning also gives you a fresh character from the game. With **Keep avatar after respawn** on (the default), the copied avatar comes back on the new character; turn it off in [Settings](tabs/settings.md#avatar) if you don't want that.

## 4. Hide the window

Tap the **X** in the corner. The script keeps working. To bring it back:

| How | Notes |
| --- | --- |
| Tap the **floating button** | On by default |
| Press <kbd>RightControl</kbd> | Changeable in Settings |
| Type `/e copier` in chat | Doesn't show in the chat |
| Open and close the Roblox menu 3 times within 5 seconds | Works without keyboard or chat |

More in [The window](features/window.md#hiding-and-reopening).

## Good to know

> [!IMPORTANT]
> **Only you see the copied avatar.** Changes happen on your device and Roblox doesn't send them to other players. Animations are the exception: Roblox replicates the animations your own character plays.

- **Some games fight back.** Round-based games may remove items or replace your character. The script puts items back and reapplies after respawns, and says what it couldn't apply. See [Compatibility](reference/compatibility.md).
- **If a game breaks** when your avatar changes (you can't move, you fall), try [Visual-only mode](features/visual-only.md).
- **Your data stays on your device**, in the executor's workspace folder (`Copier_SavedProfiles.json`).

## Where next?

- [Saved Skins](tabs/saved-skins.md): keep a look forever and share it as a code.
- [Roblox Shop](tabs/roblox-shop.md): swap single items on the avatar you wear.
- [Auto & Cycle](tabs/auto-cycle.md): a new avatar every death.
- [Troubleshooting](troubleshooting.md): what each message means.

---

| Up | Next → |
| :---: | ---: |
| [All docs](README.md) | [Copy Avatar](tabs/copy-avatar.md) |
