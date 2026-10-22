# Compatibility

What the script does with different rigs, custom characters, game objects and executors. Messages quoted here are the ones shown in the status line; [TROUBLESHOOTING.md](TROUBLESHOOTING.md) lists them all.

## Detecting the rig

`F.getTrueRigType` looks at the parts, not only at `Humanoid.RigType`, because some games set the property wrong: a character with an `UpperTorso` is R15, one with a `Torso` is R6, and only a character with neither falls back to `Humanoid.RigType`. The avatar model is always built for the rig that was detected, so an R15 avatar is rebuilt as R6 on an R6 character, and the 3D preview uses the same rig.

## R15

The full avatar applies: meshes, sizes, joint offsets, scale values, accessories, layered and classic clothing and body colours. Characters built with `AnimationConstraint`s instead of `Motor6D`s are handled the same way; `Rig.links` reads both.

The hip height is copied only when every leg part took the new size. A hip height taller than the real legs makes the character hover and lets it jump again in mid-air, which happened in games that keep their own legs.

## R6

The avatar is rebuilt as an R6 model and applied the same way. Description animations are R15 animations and play nothing on R6, so an R6 character keeps the game's animations and the status line says "Avatar applied. This game does not use an R15 rig, so its own animations were kept." Saved skins are rig specific: a skin saved on R15 is rebuilt from its description on R6, and the reverse.

## Custom and partial characters

Many games ship characters with missing or extra parts. The script applies to every standard body part the character really has and skips the rest:

- A missing body part, and any accessory that needs an attachment on it, is counted in "Avatar applied with limitations: N unavailable items/body parts in this game."
- Only when the character has none of the expected parts does it stop with "This game's character has none of the expected body parts (...)."
- If a body part is no longer jointed to the root, the character is already broken and the script stops with "The character rig is already disconnected. Respawn or rejoin before applying another avatar."

Accessories are attached with `Humanoid:AddAccessory`. When that doesn't connect them, the script welds the handle's attachment to the body attachment with the same name, and an accessory with no attachment at all goes on top of the head. An accessory that still can't be connected is skipped.

## Parts that refuse new meshes

Some games replicate `MeshPart`s that reject `ApplyMesh`. For those, the real part keeps its mesh, joint and collisions, and a non-colliding, massless local copy of the new part is welded on top while the real one is hidden on your screen (a warning `[Lyra Appearance] <part>: using a local visual` is printed). The next apply removes these copies first.

## What the game added to your character

Because the character is changed in place, everything the game attached to it stays where it was: tools and their grip welds, folders, models and parts welded to a limb, attachments with their effects, and the `BillboardGui`/`SurfaceGui` tags on the head. Attachments the avatar also has are updated in place, since game weapons can hold references to them.

An accessory is removed only when the script added it, or when it holds no script and matches one of your own avatar's accessories by name (the script builds your own avatar once to learn the names). Everything else is treated as the game's and kept, which is how game items such as MM2's waist weapons survive. After an apply, the tags on the head are switched on and their text made fully visible.

Two cases worth knowing:

- **Save** records every accessory on the character, including game accessories, and wearing the skin later adds static copies of them.
- **Restore** and saved skins rebuild from a visual snapshot, so a game accessory without a script is replaced by its recorded copy, and one with a script stays and also gets a copy.

## Round-based games

- **Respawns**: with **Keep avatar after respawn** on, every new character gets the current avatar back. The script waits up to 8 s for the Humanoid and root part and up to 4 s for the appearance to load.
- **Removed items**: with **Keep avatar between rounds** on, an item the game removes is put back 0.8 s later. Each item gets two tries and each applied avatar twelve in total; after that the recovery stops and says "The game keeps removing some items. Recovery was paused to prevent repeated reconstruction."
- **Stand-ins**: some games show a local copy of your character named after you instead of respawning it. Models with your name added to the workspace get the current avatar too.
- **Blocked respawns**: with **Reset character first**, if the game doesn't respawn you within 12 s and your character is still alive, the avatar is applied to it anyway.

## Games with special handling

- **Evade** (`game.GameId` 3647333358): visual-only mode is always on, and the overlay follows Evade's separate render rig in `workspace.Rigs`.
- **Murder Mystery 2**: waist weapons are game accessories and are kept (see above).

## Visual-only mode

The game's character is never touched, so it works where changing the body breaks movement or the game's own scripts. Your real body and accessories are hidden on your screen (with `Transparency`, because the camera keeps rewriting `LocalTransparencyModifier` on your own character), and the overlay follows them every frame. In first person the overlay fades out when the camera is inside the head. The overlay is local: other players see your normal character.

## What other players see

Everything the script changes on your character is a client-side change, and Roblox doesn't replicate those to other players. The exception is animation: Roblox replicates what the Animator plays on your own character, so copied animations can be seen. `Config.AnimResync` replays the animation swap once, 1.2 s later, so players who missed the first start still load the new animations. Other Avatar Copier users with skin sync on see your skin drawn over your character.

## Phones and tablets

The window adapts to the screen: a side rail with labels on wide windows, an icon rail below 760 px and a drawer below 520 px, with the interface slightly smaller on small screens when the size is Auto. Everything in the window works by touch. The hotkeys (free camera, mirror, ToolsGiver, hide interface) need a keyboard. To reopen the hidden window without a keyboard, use the floating button, the chat command or the Roblox menu shortcut; the settings page shows which of these work on the device.

## Executors

The script checks every executor function with `type()` before calling it, so a missing one only turns its feature off:

| Missing | Effect |
| --- | --- |
| `readfile`/`writefile`/`isfile` | Favorites, skins and settings last for the session only ("Storage unavailable…") |
| `getcustomasset`/`getsynasset` | Vector icons and an "AC" text logo instead of the images; no creator photo |
| `setclipboard`/`toclipboard` | Share codes and links are shown in a text box to copy by hand |
| `request`/`http_request`/`syn.request` | No skin sync; the creator photo falls back to `game:HttpGet` |
| `firetouchinterest` | ToolsGiver doesn't touch tools lying in the workspace |

**Copy animations** reads animation assets with `game:GetObjects`, and the Roblox menu avatar edits `CoreGui`; both need an executor that allows them, and both fail quietly when it doesn't.
