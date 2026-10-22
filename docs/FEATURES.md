# Features

This page follows the window from top to bottom: each tab, the settings, the shortcuts and the `Config` table at the top of the script. Behaviour that depends on the game is in [COMPATIBILITY.md](COMPATIBILITY.md).

## Copy Avatar

The search box takes a username (3 to 20 letters, digits or underscores, with or without `@`) or a numeric user ID. It searches 0.6 s after you stop typing; Enter or the arrow button searches right away. Players in your server are matched by name first, then Roblox is asked. A resolved profile is cached for two minutes (up to 20 profiles).

The **3D preview** is built with the rig your character uses (R15 when you have no character yet), so it shows what will actually be applied. Drag to rotate, use the mouse wheel or the − and + buttons to zoom, and the reset button to frame it again. When Roblox can't build the model, or it takes more than 25 seconds, a picture of the avatar is shown instead and **Apply avatar** still works. Previewing a profile adds it to Recent. The preview is a separate model; it never touches your character.

**Apply avatar** puts the profile's avatar on your character. **Add favorite** stars it.

### Timeline

Below the preview, every appearance of the session is a thumbnail, up to 12 earlier ones plus the current one. Tapping one goes straight back to it.

- **Undo** goes back one step.
- **Customize** opens the Roblox Shop on the list of items you are wearing.
- **Restore** puts back the appearance your character had when the script started (or, if you had no character then, the first time it applied an avatar).

The timeline lives in memory and starts empty on every run.

## Server

Lists the players in your server, filtered by name, display name or user ID. **Wear** applies a player's avatar in one tap, **Preview** opens it in Copy Avatar, and the star adds it to Favorites.

## Favorites & Recent

**Favorites** holds up to 200 starred profiles and **Recent searches** the last 30 you previewed or wore. Both can be filtered, and each row has Wear, Preview and remove. **Clear list** empties the selected list after a confirmation.

## Saved Skins

A saved skin records what your character actually looks like, not just a list of catalog items, so a skin built in a "Catalog Creator" game can be worn in other games.

Type a name and tap **Save** to capture the skin you are wearing. It records:

- every body part: mesh, texture, colour, transparency, material, size, attachments and the visual effects on it (particles, fire, sparkles, smoke, lights, trails and beams);
- accessories, clothing, body colours, scale values, joint offsets and the hip height. Each accessory must be a single part; a multi-part accessory stops the capture with an error;
- the animation ids in your `Animate` script;
- the avatar description, so the skin can still be rebuilt on a different rig.

The library holds up to 100 skins. Each row has **Wear**, **Preview** and a pencil that opens:

- **Rename**, and **Update** to capture your current look over the skin;
- **Copy** to duplicate it, **Share** to copy a share code, **Cycle** to add it to the avatar cycle;
- **Delete**, after a confirmation.

**Share & import** shows the last share code and takes a pasted `LYRA3:` or `LYRA2:` code or the contents of an old JSON backup from earlier versions. An old backup is named after the text in the name field. Every import is validated against the limits in [DATA-FORMATS.md](DATA-FORMATS.md#limits), the same ones used for skins received through skin sync, and refused when anything is outside them.

A skin saved on R15 only applies as-is to an R15 character (the same for R6). On the other rig it is rebuilt from its avatar description, and the status line says custom details may differ.

## Roblox Shop

Tries catalog items on the avatar you are wearing. Changes are local and go through the same path as any other avatar, so they appear in the timeline and Undo covers them.

**Search** takes a name, an item ID, a catalog link (`/catalog/<id>`) or a bundle link (`/bundles/<id>`). A bare number is looked up as an item first and as a bundle when it is not a wearable item, because item and bundle IDs overlap.

- **Filters**: All, Limiteds, Bodies, Heads, Hair, Hats, Accessories, Clothing, Faces, Animations and Emotes. Clothing and Accessories have a second row (classic shirts, pants and T-shirts or layered clothing; face, neck, shoulder, front, back and waist).
- **Sort**: most popular (all time, the default, so a search like "korblox" leads with the original item), best selling, best match, newest, and price in either direction.
- **Price**: any, for sale only, free, up to R$ 100, R$ 100 to 1,000, R$ 1,000 and up. Off-sale items are listed unless a price filter is set, since they still load on a local avatar.
- **Load more** continues the same search.

Tapping a **bundle** lists its parts, body parts first. **Add all** and **Remove all** change every part at once, or each part can be added on its own. A removed body part goes back to the default Roblox shape.

**Wearing** lists every item on your current appearance, grouped, each with Remove. Editing a saved skin rebuilds it from its items, so details that only the saved snapshot had are dropped.

An added emote goes into the first free slot of the emote wheel (slot 8 when all are taken) and plays once. Items that can't be worn (gear, for example) are shown as "Not wearable". When the in-game catalog search isn't available, the shop uses the web catalog instead.

The bar at the top shows the last change with its picture and an Undo button.

## Auto & Cycle

### Auto-load on execute

**Apply an avatar on start** puts an avatar on as soon as the script runs and your character is ready. **Which avatar to apply** is one of:

- the **chosen avatar**, set from the current preview or what you are wearing;
- the **last applied** avatar;
- a **random favorite**;
- the cycle's current position.

An avatar set under **This game only** always wins for that place. **Delay before loading** (0 to 30 s) helps in games that change your look on spawn. Auto-load is skipped when `Config.TargetUsername` is set.

### Avatar cycle

**Cycle avatars** switches to the next avatar in the list on its own. The folded options:

| Option | Values |
| --- | --- |
| Switch when | On death, on respawn, on a timer, death or timer |
| Deaths per switch | 1 to 50 deaths (or respawns) |
| Timer interval | 10 s to 60 min |
| Order | In order, shuffle (everyone once per round), random (never the one you wear), ping-pong |
| At the end of the list | Start over, stay on last, go back to your own avatar (In order only) |
| Cooldown | 0 to 300 s between two switches |
| Remember position | Continue from the same avatar on the next run |
| Notify on switch | A toast with the new avatar's name |

On a death the next avatar starts loading during the respawn timer, so it is ready when the new character appears. Deaths caused by **Reset character first** don't count.

The status card shows what is worn, how many deaths or how much time is left before the next switch, the cooldown and the deaths this session, with **Previous**, **Next** and **Reset**. The list holds up to 50 profiles or saved skins: add the preview, what you are wearing or all your favorites, drag the number or picture to reorder, and tap **Wear** to jump to one.

## Settings

The defaults work for most people.

| Setting | Default | What it does |
| --- | --- | --- |
| Interface size | 85% | Scales the window and its text (Auto, or 70% to 130%) |
| Window size | Automatic | Drag the bottom-right corner to resize; Reset restores the size and 85% |
| Copy animations | Off | Also copies the avatar's idle, walk, run, jump, fall, climb and swim animations (R15 only) |
| Keep avatar after respawn | On | Reapplies the avatar to each new character |
| See other script users' skins | On | Skin sync (see below) |
| Show notifications | On | Toasts in the bottom-right corner |
| Start hidden | Off | Opens straight into the hidden state; skipped when nothing could reopen the window |
| Floating button | On | A draggable button while the window is hidden |
| Reopen with the Roblox menu | On | Open and close the Roblox menu 3 times within 5 s to show the hidden window |
| Hub shortcut | RightControl | Shows or hides the window. V, L, R, K, W, A, S, D, Space, Return, Tab and Backspace are refused |

Under **Show advanced options**:

| Setting | Default | What it does |
| --- | --- | --- |
| Keep avatar between rounds | On | Puts back items the game removes, and applies the avatar to local stand-in models of you |
| Reset character first | Off | Respawns you before applying, for the cleanest result |
| Visual-only avatar | Off | Draws the avatar over your character instead of changing it; always on in Evade |
| Glow when avatar changes | On | A short local glow and sparkle burst when the avatar changes |
| Show my avatar in the Roblox menu | On | Your card in the Roblox menu's Players page shows the avatar you wear, on your screen only |
| Background blur | On | Blurs the game behind the window |
| Reduced motion | Off | Turns off window animations |
| Performance mode | Off | Turns off the blur, the glass background and other extra effects |

**How to reopen the window** shows, live, which ways back work on this device: the floating button, the Roblox menu shortcut, the shortcut key (only with a keyboard) and the chat command (unless Roblox says the account can't chat). Hiding the window with the floating button off asks for a confirmation the first time; when nothing at all could reopen it, the script offers to turn the menu shortcut on instead.

## Creator

The Discord invite and the GitHub profile of the author, each with a copy button. The GitHub photo is downloaded the first time the tab opens.

A toast inviting you to the Discord appears at most twice ever: 5 minutes into a session, and once more a minute into the 10th run after that. It needs working saved data (otherwise the counters would reset every run) and respects **Show notifications**.

## Skin sync

While **See other script users' skins** is on, the skin you wear is posted to the sync server for your current Roblox server only, and the skins of other script users in the same server are drawn over their characters, on your screen. Players without the script see nothing different. A received skin goes through the same checks as an imported share code and is drawn as a separate local model, so it never changes anyone's real character. Turning the setting off tells the server you left and removes the drawn skins.

The server address is `Config.SyncUrl`; an empty string turns the feature off. See [DATA-FORMATS.md](DATA-FORMATS.md#skin-sync-protocol).

## Visual-only mode

Instead of changing your character, the avatar is built as a separate local model that follows your character every frame, and your real body and accessories are hidden on your screen. The game's rig, joints, animations and movement stay exactly as they were. It applies the next time you wear an avatar. Restore removes the overlay; it doesn't undo an avatar that was applied before visual-only was turned on (see [TROUBLESHOOTING.md](TROUBLESHOOTING.md#restore-left-items-on-my-character)).

## Shortcuts

| Key | Action |
| --- | --- |
| Hub shortcut (RightControl) | Show or hide the window |
| `V` | Free camera. Your root part is anchored, the arrow keys move the camera and holding the right mouse button looks around. Turning it off, applying an avatar or respawning gives the camera back |
| `R` | Copies the held tool's handle (without its scripts) into a model welded to your left hand; press again to remove it |
| `L` | ToolsGiver: every 1.5 s, looks for tools you don't have in the workspace, Lighting, ReplicatedStorage, ReplicatedFirst, StarterPack and Players, touches the ones lying in the workspace and puts a local copy in your backpack. Copies exist on your client only; whether they work depends on the game |
| `K` | Hides every interface in PlayerGui except the hub and the touch controls, plus Roblox's own interface; press again to bring back exactly what was visible |

The free camera, mirror and ToolsGiver keys are set in `Config` and need a keyboard; they have no touch controls.

Chat commands, typed in the chat box:

| Command | Action |
| --- | --- |
| `/e copier`, `/e hub`, `/copier`, `/hub`, `/e dance1`, `/dance1` | Show the window |
| `/e next`, `/e prev` | Next or previous avatar in the cycle |
| `/e cycle` | Turn the cycle on or off |

`/e` commands go through Roblox's emote command, so they don't appear in the chat. The same message can arrive through more than one chat event; it is acted on once.

## Configuration

The `Config` table at the top of `src/avatar-copier.lua`:

| Key | Default | Meaning |
| --- | --- | --- |
| `TargetUsername` | `""` | A username or id to preview on start (needs `CopyAvatar` or `CopyAvatarHD`). `"restore"`, `"stop"` or your own username switch to restore mode instead: the camera, the top bar and the core interface are given back, your character is reset and the script exits |
| `CopyAvatar`, `CopyAvatarHD` | `true`, `false` | Either one enables the `TargetUsername` preview |
| `AutoReapply`, `MapPersist`, `CopyAnimation` | `true`, `true`, `false` | Follow the matching settings once the hub loads; `CopyAnimation` is the default for "Copy animations" |
| `AnimResync` | `true` | Repeats the animation swap once after applying, so other players load the new animations completely |
| `EnableFreeCam`, `FreeCamKey`, `FreeCamSpeed` | `true`, `V`, `1.5` | Free camera |
| `DualWieldKey` | `R` | Mirror the held tool to the left hand |
| `ToolsGiverKey` | `L` | ToolsGiver |
| `HideUIKey` | `K` | Hide the game's interface |
| `SyncUrl` | the Lyra sync server | Skin sync server; `""` turns skin sync off |
| `DoorsCameraFix`, `SpoofGameEvents`, `RestoreYourTagAfterRespawn` | | Not used by this version |
