[Docs](README.md) / **Troubleshooting**

# <img src="assets/icons/help.png" width="40" alt=""> Troubleshooting

Problems you can run into, grouped by what you see. Quoted text is the message the script shows in the status line at the bottom of the window.

> [!TIP]
> Use your browser's find (<kbd>Ctrl</kbd>+<kbd>F</kbd>) with a few words of the message you see.

## Applying an avatar

**"Wait for your character to load."** or **"Wait for your character to respawn."**
You have no character, or it is dead. Apply again once you can move.

**"Wait for the current change to finish."**
Another avatar, Undo or shop edit is still being applied. Changes run one at a time.

**"Your character changed during the operation. Try again."** (and similar)
You died or respawned while the avatar was being built or applied. Nothing more is changed; apply again.

**"Roblox could not load mesh rbxassetid://… Your character has not been changed yet."**
A saved skin uses a mesh Roblox can't load right now (removed asset or a network problem). Your character was left alone. Try later or use another skin.

**"The character rig is already disconnected. Respawn or rejoin before applying another avatar."**
A body part is no longer jointed to the root, usually because the game or another script broke the character. Applying onto it would make things worse, so the script stops. Respawn or rejoin.

**"This game's character has none of the expected body parts (…)."**
The game uses a fully custom character. Try **Visual-only avatar** in the advanced settings, which draws the avatar over the character instead of changing it.

**"Avatar applied with limitations: N unavailable items/body parts in this game."**
The character is missing some standard parts, or some accessories had nowhere to attach. N counts both. Everything else was applied.

**"This game did not respawn your character. Turn off "Reset character first" in Settings, wait until you can move, and try again."**
**Reset character first** is on and the game blocks or delays respawning (common in round-based games).

**The message ends with "Use Restore original to recover your appearance."**
The apply failed after it had started changing your character. Tap **Restore** below the timeline.

**My character floats or sinks after applying.**
The hip height only follows the new body when every leg part could take the new size. In a game that keeps its own legs the game's hip height stays, which can look slightly off but avoids hovering and double jumps.

**Other players don't see my avatar.**
That is expected: avatar changes are made on your client and Roblox doesn't replicate them. Animations are the exception. Other script users see your skin through skin sync.

**The animations didn't change.**
**Copy animations** is off by default. It only works on R15 characters (R6 games keep their own animations), and it reads the animation assets with `game:GetObjects`, which some executors don't provide. Saved skins restore their recorded animation ids without that setting.

## Restore and saved skins

### Restore left items on my character

Two situations cause this:

- **Visual-only avatar** was turned on while an avatar was applied normally. In visual-only mode Restore only removes the drawn overlay. Turn visual-only off and tap Restore again, or respawn.
- Restore rebuilds your starting appearance from a snapshot of your character taken when the script started. Every accessory on the character at that moment is in it, including accessories the game had added. A game accessory without a script is replaced by its recorded copy; one with a script stays and also gets a copy, so it can appear twice. Respawning gives the game a fresh character.

If you ran the script again while wearing a copied avatar, that avatar became the starting point for Restore. Respawn first, or run the script once with `Config.TargetUsername = "restore"`.

### A saved skin added a weapon, holster or other game item

**Save** records every accessory you are wearing, including the ones the game put on you. Wearing the skin later adds static copies of them. Save the skin where the game hasn't added anything, or update it after removing those items.

**"Multi-part accessories are not supported: <name>"**
Saving needs every accessory to be a single part. Remove that accessory, or save in a place where it isn't added.

**"Wait for the application to finish or restore your character before saving."**
An apply is running, or the last one failed halfway. Wait, or tap Restore, then save.

**The skin looks different on another game's character.**
Skins are rig specific. On the other rig (R6 or R15) the skin is rebuilt from its avatar description and the status line says custom details may differ.

## Importing codes

**"Paste a LYRA code or the full contents of the old JSON."**, **"Code not recognized."** or an **"Invalid …"** message
The code is incomplete or was changed. Codes are long; chat apps and some text boxes cut them. Codes over 2 MB are refused. Every value is checked (see [DATA-FORMATS.md](reference/data-formats.md#limits)) and anything outside the limits refuses the whole code.

**"Old JSON applied. Attachments were estimated because the backup contains no joints."**
Old backups don't record joints, so accessory and limb positions are estimated from the part sizes. Saving the skin again after wearing it records the exact values.

## Saved data

**"Storage unavailable. Data will remain in this session."** or **"File access unavailable. Changes will remain in this session."**
Your executor has no `readfile`/`writefile`. Everything works, but nothing is kept after you leave.

**"A recovery copy of your data was loaded."**
`Copier_SavedProfiles.json` couldn't be read (often a write that was interrupted), so the `.bak` backup was used. The next save writes a fresh file.

**"Unsupported data format. Saving was disabled to protect the file."**
The file was written by a newer version of the script. This version reads what it can and never overwrites it.

**"Storage is full (16 MB). Remove some skins to save again."**
Skins with many effects or meshes are large. Delete some from Saved Skins.

## The shop

**"The catalog is unavailable right now. Try again in a moment."** or **"The catalog returned an unexpected answer."**
Both the in-game search and the web fallback failed. The web fallback needs `game:HttpGet` to reach `catalog.roblox.com`.

**"Roblox rejected this change: …"**
Roblox refused the new item list. The rest of the message is Roblox's reason.

**"This item cannot be worn on an avatar."** / **"That item is not on your avatar."**
The item type can't go on an avatar (gear, for example), or you tried to remove something the current appearance doesn't have.

## Profiles and the preview

**"User not found or the service is unavailable. Check the username."**
The name doesn't exist, or Roblox's user service didn't answer. Try the numeric user ID.

**"The profile exists, but its avatar could not be loaded. Try again."**
Roblox returned the user but not their avatar. It is usually temporary.

**"3D preview unavailable. You can still apply the avatar."**
Building the preview model failed or took longer than 25 seconds, so a picture is shown instead. Applying builds the model again and may still work.

## The window

**I hid the window and can't get it back.**
Use any method listed under **How to reopen the window** in Settings: the floating button, your shortcut key, `/e copier` in chat, or opening and closing the Roblox menu 3 times within 5 seconds. Running the script again also opens a new window, unless **Start hidden** is on.

**"Start hidden was skipped: nothing could reopen the window. Turn on a way to reopen it in Settings."**
Start hidden is on but the floating button and the menu shortcut are off, there is no keyboard and chat isn't available, so hiding would have locked you out.

**The icons look simpler and the logo is just "AC".**
Your executor has no `getcustomasset`, so the embedded images can't be loaded and the built-in vector icons are drawn instead.

## Skin sync

**I don't see other script users' skins.**
Skin sync is off in this repository: `Config.SyncUrl` is empty until you set a server (see [Skin sync](features/skin-sync.md)). With an address set, all of these must be true: **See other script users' skins** is on for both of you, `Config.SyncUrl` is set, your executor has `request` (or `http_request`/`syn.request`), and you are in a live server (Roblox Studio has no `JobId`). Skins are checked every few seconds, and a skin that fails validation or can't be built is not drawn.

## Auto & Cycle

**"Auto-load is on, but no chosen avatar is set. Choose one in Auto & Cycle."**
Auto-load is on with no avatar for the selected source. Set one, or turn auto-load off.

**"Add avatars to the cycle list first."**
The cycle is on but the list is empty.

## Messages with a file and line number

Some errors come from `assert`, and Luau adds the location of the failing line to those messages, so the status line can show something like `[string "…"]:4362: Invalid dimensions or colors.` The text after the number is the message that matters. This shows up when running the script in the Luau test runner; executors may name the chunk differently.

Still stuck? See [Contributing](../CONTRIBUTING.md#reporting-a-bug) for what to include in a bug report.

---

| ← Previous | Up |
| :--- | :---: |
| [Development](reference/development.md) | [All docs](README.md) |
