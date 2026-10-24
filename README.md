<p align="center">
  <img src="docs/assets/logo.png" width="112" alt="Avatar Copier logo">
</p>

<h1 align="center">Avatar Copier</h1>

<p align="center">
  Put any Roblox player's avatar on your character, save skins, try catalog items and cycle through avatars while you play.
  <br>
  <a href="https://source.lyraez.lol"><b>Website</b></a> ·
  <a href="docs/getting-started.md"><b>Getting started</b></a> ·
  <a href="docs/README.md"><b>Documentation</b></a> ·
  <a href="docs/troubleshooting.md"><b>Troubleshooting</b></a>
</p>

---

Avatar Copier (the window is called **Avatar Studio**) is a Roblox client script. You search a username or user ID, look at the avatar in a 3D preview and apply it. It has always been free: no key system, no link shorteners, no payment.

> [!NOTE]
> The change happens on your client. Other players keep seeing your normal avatar, except for the animations Roblox replicates from your character. See [Limitations](#limitations).

## Features

Each tab of the window has its own page in the docs, with step-by-step use and links into the code.

| | Tab | What you can do |
| :-: | --- | --- |
| <img src="docs/assets/icons/copy-avatar.png" width="28" alt=""> | [Copy Avatar](docs/tabs/copy-avatar.md) | Search by username, `@username` or user ID, turn the 3D preview, apply. A timeline of every look, Undo and Restore. |
| <img src="docs/assets/icons/server.png" width="28" alt=""> | [Server](docs/tabs/server.md) | Wear or preview anyone in your server with one tap. |
| <img src="docs/assets/icons/favorites-recent.png" width="28" alt=""> | [Favorites & Recent](docs/tabs/favorites-recent.md) | Up to 200 starred profiles and your last 30 searches. |
| <img src="docs/assets/icons/saved-skins.png" width="28" alt=""> | [Saved Skins](docs/tabs/saved-skins.md) | Save what you wear (body, accessories, clothes, effects), wear it in any game, share it as a `LYRA3:` code. |
| <img src="docs/assets/icons/roblox-shop.png" width="28" alt=""> | [Roblox Shop](docs/tabs/roblox-shop.md) | Search the catalog, filter and sort, open bundles part by part, add or remove items on the avatar you wear. |
| <img src="docs/assets/icons/auto-cycle.png" width="28" alt=""> | [Auto & Cycle](docs/tabs/auto-cycle.md) | An avatar when the script starts (one per game if you want), and a new one on death, respawn or a timer. |
| <img src="docs/assets/icons/settings.png" width="28" alt=""> | [Settings](docs/tabs/settings.md) | Interface size, persistence, visual-only mode, effects and the ways to reopen the window. |
| <img src="docs/assets/icons/creator.png" width="28" alt=""> | [Creator](docs/tabs/creator.md) | The author's Discord and GitHub. |

Also: the avatar comes back after a respawn, items a round-based game removes are put back, a [visual-only mode](docs/features/visual-only.md) for games that break when the character changes, and [hotkeys](docs/features/hotkeys-and-chat.md) for a free camera, a left-hand tool copy, ToolsGiver and hiding the game's interface.

## Quick start

Run [`src/avatar-copier.lua`](src/avatar-copier.lua) in your executor. While this repository is public, you can also load it straight from GitHub:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/lyraEz/Source-Avatar-Copier/main/src/avatar-copier.lua"))()
```

1. Type a username or user ID in **Copy Avatar** and press <kbd>Enter</kbd>.
2. Check the 3D preview, then tap **Apply avatar**.
3. Use **Undo**, the timeline pictures or **Restore** to go back.

Running the script again closes the previous copy first. The full walkthrough, with the optional executor functions, is in [Getting started](docs/getting-started.md).

| Input | Action |
| --- | --- |
| <kbd>RightControl</kbd> (changeable in Settings) | Show or hide the window |
| Floating button | Show the window while it is hidden |
| Open and close the Roblox menu 3 times within 5 s | Show the hidden window (can be turned off) |
| `/e copier`, `/e hub`, `/copier`, `/hub` in chat | Show the window |
| `/e next`, `/e prev`, `/e cycle` in chat | Next or previous avatar in the cycle, turn the cycle on or off |
| <kbd>V</kbd> / <kbd>R</kbd> / <kbd>L</kbd> / <kbd>K</kbd> | Free camera / left-hand tool copy / ToolsGiver / hide the game's interface |

## Requirements

- A Roblox executor that can run a client-side Luau script. Third-party executors are against the Roblox Terms of Use; use them at your own risk.
- Optional executor functions (`readfile`/`writefile`, `getcustomasset`, `setclipboard`, `request`, `firetouchinterest`). Without them the script still runs and only the related feature is off. See [Getting started](docs/getting-started.md#what-you-need).

## Privacy and network

The script doesn't collect analytics. Besides Roblox's own services (profiles, avatars, catalog, chat), it can make these requests:

- **Catalog fallback**: when the in-game catalog search is unavailable, the shop searches `catalog.roblox.com` instead.
- **Creator photo**: the first time you open the Creator tab it downloads `github.com/lyraEz.png` and caches it.
- **Skin sync**: off in this repository. `Config.SyncUrl` is empty, so nothing is sent. If you set a server address, the script shares the skin you wear with that server for your current Roblox server; see [Skin sync](docs/features/skin-sync.md) for exactly what is sent.

Saved data stays on your device, in the executor's workspace folder: `Copier_SavedProfiles.json` and its `.bak` backup, plus the cached images `LyraAvatarStudio_icons_v14_7.png`, `LyraAvatarStudio_logo_v15.png` and `LyraAvatarStudio_github_lyraEz.png`.

## Limitations

- Copied avatars are local. Accessories, clothes and body changes are not replicated to other players. Roblox does replicate animations played on your own character, so copied animations can be seen.
- Games that rebuild or replace the character, use custom rigs or remove accessories every round may only take part of an avatar. The script applies what fits and says what it skipped.
- Saved skins record every accessory you wear, including ones the game added (a weapon holster, for example). Wearing that skin later adds static copies of them.

[Troubleshooting](docs/troubleshooting.md) lists the messages the script shows and what to do about them. [Compatibility](docs/reference/compatibility.md) covers rigs and game-specific behaviour.

## Development

```sh
tools/check.sh path/to/luau-bin      # syntax, globals, URLs, versions, credentials, doc links
tests/run.sh path/to/luau-bin/luau   # runs the script against a stand-in of the Roblox API
```

Both need the [Luau](https://github.com/luau-lang/luau/releases) command-line tools (CI uses 0.741) and Python 3. The tests don't replace trying a change in a real game. See [Development](docs/reference/development.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Avatar Copier is free software: you can redistribute it and/or modify it under the terms of the [GNU General Public License](LICENSE), version 3 or (at your option) any later version. It is distributed without any warranty.

In short: you can use, study, change and share it. If you share a changed version, it has to stay under the same license, with its source available.

## Credits

Made by [lyraEz](https://github.com/lyraEz). Icons from [Lucide](https://lucide.dev) (ISC) and the GitHub and Discord marks from [Simple Icons](https://simpleicons.org) (CC0); see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
