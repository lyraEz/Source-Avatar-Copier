[Docs](../README.md) / Reference / **Lifecycle**

# <img src="../assets/icons/reference.png" width="40" alt=""> Lifecycle

How the script keeps an avatar on you across respawns and rounds, what it remembers, and what happens when it stops.

## One run at a time

Each run takes a new `_G.Copier_ExecutionID` (see [`IsAlive`](../../src/avatar-copier.lua#L33)). Running the script again calls the previous run's cleanup first, then disconnects whatever was left in `_G.Copier_Connections`. Loops and delayed tasks of the old run check their execution id (or `App.alive()`) and stop by themselves, so two copies never fight over your character.

## The initial appearance

`App.Initial` is the appearance **Restore** goes back to. It is captured once per run by [`App.captureInitial`](../../src/avatar-copier.lua#L1840-L1863): when the script starts if you already have a character, otherwise just before the first avatar is applied. It holds your description, the animation ids in your `Animate` script and a visual snapshot of the character's parts.

It is captured from the character as it is at that moment. If you run the script again while wearing a copied avatar, that avatar becomes the starting point for Restore. Respawn first (a new character comes with your real avatar), or use restore mode (`Config.TargetUsername = "restore"`), to get your own look back.

## Respawns

On every `CharacterAdded` ([the handler](../../src/avatar-copier.lua#L2941-L2946 "RegisterConnection(lp.CharacterAdded:Connect(function(char)")):

1. Item recovery for the old character stops.
2. A `Died` listener is connected for the avatar cycle.
3. If the cycle has an avatar ready for this respawn, it is applied (mode `cycle`). Otherwise, with **Keep avatar after respawn** on, the current avatar is reapplied (mode `reapply`, [`F.reapply`](../../src/avatar-copier.lua#L2929-L2940)): the script waits up to 8 s for the Humanoid and root part and up to 4 s for the appearance to load, then applies it unless something else changed the avatar meanwhile.

Nothing is reapplied while you wear your initial appearance. A reapply doesn't add a timeline entry, and the built avatar model is reused from a cache, so it is faster than the first apply.

## During a life

- **Item recovery** (Keep avatar between rounds): [`Repair.watch`](../../src/avatar-copier.lua#L1932-L1939) listens to `ChildRemoved` on the character and [`Repair.queue`](../../src/avatar-copier.lua#L1911-L1931) puts items back. When an item the script added disappears, it is put back 0.8 s later, at most twice per item and twelve times per applied avatar. Past that the recovery pauses and says so. It never re-runs the whole apply and never polls the body.
- **Stand-ins**: a model named after you that appears in the workspace and is not your character gets the current avatar once per apply ([`applyToStandIn`](../../src/avatar-copier.lua#L2950-L2966)).
- **Deaths and the cycle**: each death (or respawn, depending on **Switch when**) is counted. When the threshold is reached and the cooldown has passed, the next avatar is resolved during the respawn timer and applied to the new character. Deaths caused by **Reset character first** are not counted ([`Auto.count`](../../src/avatar-copier.lua#L2813-L2828), [`Auto.onRespawn`](../../src/avatar-copier.lua#L2830-L2852)). The timer modes check once per second and switch on the live character.

## What lasts only for the session

These live in memory and start empty on every run:

- the timeline and Undo history (up to 12 earlier appearances), the preview and the current snapshot;
- resolved profiles (two minutes each, up to 20), catalog product info and bundle details;
- built meshes (up to 64) and the last built avatar model;
- skin sync peers and the skins drawn over them;
- the session death counter.

## What is saved

`Copier_SavedProfiles.json` in the executor workspace holds favorites, recent searches, saved skins, every setting, the auto-load and cycle options (the cycle position is saved too and used on the next run when **Remember position** is on) and the Discord invite counters. The format is in [DATA-FORMATS.md](data-formats.md#saved-file).

- **When**: after every change that affects it ([`Store.save`](../../src/avatar-copier.lua#L1756-L1760), [`Store.write`](../../src/avatar-copier.lua#L1651-L1671)). A write is skipped when the JSON is identical to the last one written, because writing a large file can freeze a phone for a moment.
- **Backup**: before overwriting, the previous file is copied to `Copier_SavedProfiles.json.bak`, unless it looks cut short by an interrupted write.
- **Size**: at most 16 MB. A save that would be larger is refused with "Storage is full (16 MB). Remove some skins to save again."
- **Loading** ([`Store.load`](../../src/avatar-copier.lua#L1690-L1750)): every value is checked by type and clamped to its range; invalid entries are dropped. A file that can't be read falls back to the backup ("A recovery copy of your data was loaded."). A file written by a newer version (format above 4) is opened read-only so it is never overwritten.
- **Migrations**: favorites saved under the old key `SavedUsers` are read, skin names and sources saved in Portuguese by older builds are translated, and a saved interface size of Auto from before 85% was the default becomes 85% once.
- **Without file access** everything still works for the session and the status line says so.

## Restore

**Restore** ([`App.restore`](../../src/avatar-copier.lua#L2165-L2167)) applies the initial appearance through the same path as any avatar (mode `restore`): the body parts take their original meshes, sizes and offsets back, the added items are removed and the recorded ones come back, the original animation ids are restored and automatic scaling is given back. In visual-only mode it removes the overlay instead. Restore mode (`Config.TargetUsername = "restore"`) is different: it resets your character so the game gives you a fresh one, then exits without opening the window.

## Cleanup

[`cleanup`](../../src/avatar-copier.lua#L6406-L6429) runs when the script is run again or when building the window fails. It:

- stops item recovery, animation reloads and every loop;
- turns off the free camera and gives back the game's hidden interface;
- disconnects every registered connection and cancels the tweens;
- removes the toasts, the Roblox menu avatar, the skin sync (telling the server you left) and all overlays;
- destroys the window, the blur, the chat command and the cached models;
- clears its `_G` state, keeping only the cleanup function and the execution id for the next run.

The avatar on your character is left as it is; Restore or a respawn removes it.

---

| ← Previous | Up | Next → |
| :--- | :---: | ---: |
| [Architecture](architecture.md) | [All docs](../README.md) | [Compatibility](compatibility.md) |
