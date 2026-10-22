# Avatar Copier

Avatar Copier (the window is called **Avatar Studio**) is a Roblox client script that puts another player's avatar on your character. You search a username or user ID, look at the avatar in a 3D preview and apply it. It can also save skins, edit the worn avatar with items from the Roblox catalog and rotate through a list of avatars while you play.

It has always been free: no key system, no link shorteners, no payment.

The change happens on your client. Other players keep seeing your normal avatar, except for the animations Roblox replicates from your character and other Avatar Copier users with skin sync turned on. See [Limitations](#limitations).

## Features

- **Copy Avatar**: search by username, `@username` or user ID, rotate and zoom the 3D preview, then apply.
- **Timeline**: every appearance of the session as a thumbnail, Undo, and Restore to get your own avatar back.
- **Server, Favorites and Recent**: wear or preview anyone in the server or in your lists with one tap.
- **Saved Skins**: save what you are wearing (body, accessories, clothes, effects), share it as a `LYRA3:` code and import codes or old JSON backups.
- **Roblox Shop**: search the catalog by name, item ID or link, filter and sort, open bundles part by part, and add or remove items on the avatar you are wearing.
- **Auto & Cycle**: apply an avatar when the script starts (one per game if you want) and switch through a list on death, respawn or a timer.
- **Persistence**: the avatar comes back after a respawn, and items a round-based game removes are put back.
- **Visual-only mode**: draws the avatar over your character without changing it, for games where changing the character breaks movement.
- **Skin sync**: script users in the same server see each other's skins.
- **Hotkeys**: free camera, a mirrored tool in the left hand, copying tools into your backpack and hiding the game's interface.

Every feature is described in [docs/FEATURES.md](docs/FEATURES.md).

## Requirements

- A Roblox executor that can run a client-side Luau script. Third-party executors are against the Roblox Terms of Use; use them at your own risk.
- Optional executor functions. Without them the script still runs and only the related feature is off:

| Function | Used for |
| --- | --- |
| `readfile`, `writefile`, `isfile` | Saving favorites, skins and settings between sessions |
| `getcustomasset` (or `getsynasset`) | The icon sheet, the logo and the creator photo; vector icons are drawn without it |
| `setclipboard` (or `toclipboard`) | Copying share codes and links; the text is shown for manual copying without it |
| `request` (or `http_request`, `syn.request`) | Skin sync and the creator photo |
| `firetouchinterest` | ToolsGiver picking up tools lying in the workspace |

## Usage

Run [`src/avatar-copier.lua`](src/avatar-copier.lua) in your executor. While this repository is public, you can also load it straight from GitHub:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/lyraEz/Source-Avatar-Copier/main/src/avatar-copier.lua"))()
```

Running it again closes the previous copy first, so a re-run never leaves two windows behind.

1. Type a username or user ID in **Copy Avatar** and press Enter.
2. Check the 3D preview, then tap **Apply avatar**.
3. Use **Undo**, the timeline thumbnails or **Restore** to go back.

| Input | Action |
| --- | --- |
| `RightControl` (changeable in Settings) | Show or hide the window |
| Floating button | Show the window while it is hidden |
| Open and close the Roblox menu 3 times within 5 s | Show the hidden window (can be turned off) |
| `/e copier`, `/e hub`, `/copier`, `/hub` in chat | Show the window |
| `/e next`, `/e prev`, `/e cycle` in chat | Next or previous avatar in the cycle, turn the cycle on or off |
| `V` | Free camera (arrow keys move, hold the right mouse button to look around) |
| `R` | Mirror the held tool's handle to your left hand |
| `L` | ToolsGiver on or off |
| `K` | Hide or show the game's interface (the hub stays) |

The `Config` table at the top of the script holds the startup options and hotkeys. It is documented in [docs/FEATURES.md](docs/FEATURES.md#configuration).

## Privacy and network

The script does not collect analytics. Besides Roblox's own services (profiles, avatars, catalog, chat), it makes these requests:

- **Skin sync**, on by default: about every 8 seconds while you are in a live server it posts your user ID, the server's JobId and a hash of the skin you wear to the address in `Config.SyncUrl`, and the skin itself when it changes. The server learns that you are using the script in that server. Turn it off with **Settings > See other script users' skins**, or set `Config.SyncUrl = ""` to remove it completely. The protocol is in [docs/DATA-FORMATS.md](docs/DATA-FORMATS.md#skin-sync-protocol).
- **Catalog fallback**: when the in-game catalog search is unavailable, the shop searches `catalog.roblox.com` instead.
- **Creator photo**: the first time you open the Creator tab it downloads `github.com/lyraEz.png` and caches it.

Saved data stays on your device, in the executor's workspace folder: `Copier_SavedProfiles.json` and its `.bak` backup, plus the cached images `LyraAvatarStudio_icons_v14_7.png`, `LyraAvatarStudio_logo_v15.png` and `LyraAvatarStudio_github_lyraEz.png`.

## Limitations

- Copied avatars are local. Accessories, clothes and body changes are not replicated to other players. Roblox does replicate animations played on your own character, so copied animations can be seen.
- Games that rebuild or replace the character, use custom rigs or remove accessories every round may only take part of an avatar. The script applies what fits and says what it skipped.
- Saved skins record every accessory you wear, including ones the game added (a weapon holster, for example). Wearing that skin later adds static copies of them.

[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) lists the messages the script shows and what to do about them. [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) covers rigs and game-specific behaviour.

## Documentation

- [Features](docs/FEATURES.md): every tab, setting, hotkey and the `Config` options.
- [Architecture](docs/ARCHITECTURE.md): how the single file is organised and what happens when an avatar is applied.
- [Compatibility](docs/COMPATIBILITY.md): R6, R15, custom rigs and game-specific handling.
- [Lifecycle](docs/LIFECYCLE.md): respawns, reapplying, saved state, restoring and cleanup.
- [Data formats](docs/DATA-FORMATS.md): the saved file, share codes, the skin format and the skin sync protocol.
- [Development](docs/DEVELOPMENT.md): where to change things, how to test, and the parts that need care.
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Development

```sh
tools/check.sh path/to/luau-bin      # syntax, unknown globals, URL allowlist, versions, credentials
tests/run.sh path/to/luau-bin/luau   # runs the script against a stand-in of the Roblox API
```

Both need the [Luau](https://github.com/luau-lang/luau/releases) command-line tools (CI uses 0.741). The tests do not replace trying a change in a real game. See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

## License

No license has been published yet. Until a `LICENSE` file is added, all rights are reserved.

## Credits

Made by [lyraEz](https://github.com/lyraEz). Icons from [Lucide](https://lucide.dev) (ISC) and the GitHub and Discord marks from [Simple Icons](https://simpleicons.org) (CC0); see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
