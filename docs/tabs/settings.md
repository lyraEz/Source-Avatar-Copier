[Docs](../README.md) / Tabs / **Settings**

# <img src="../assets/icons/settings.png" width="40" alt=""> Settings

> The defaults work for most people. Change only what you need.

That is the first line of the tab, and it is true: you can use the script without ever opening this page. Every change is saved right away and kept for the next run.

Each setting name below links to the line in the script that creates its switch. The last column links to the code that reads it.

## Window

| Setting | Default | What it does | Read by |
| --- | --- | --- | --- |
| [Interface size](../../src/avatar-copier.lua#L4767 "Makes the window and its text smaller or larger. Auto fits your screen.") | 85% | Scales the window and its text: **Auto**, or 70% to 130%. Auto is 94% on small screens and 100% elsewhere. | [`UI.scale`](../../src/avatar-copier.lua#L3576-L3581) |
| [Window size](../../src/avatar-copier.lua#L4769 "Drag the corner at the bottom right of the window to resize it.") | Automatic | Drag the grip in the bottom-right corner of the window to resize it. **Reset** brings back the automatic size and 85%. | [`UI.buildResizeGrip`](../../src/avatar-copier.lua#L3717-L3763), [`UI.layout`](../../src/avatar-copier.lua#L3582-L3687) |

## Avatar

| Setting | Default | What it does | Read by |
| --- | --- | --- | --- |
| [Copy animations](../../src/avatar-copier.lua#L4776 "Also copy the avatar's idle, walk, run and jump animations.") | Off | Also copies the avatar's idle, walk, run, jump, fall, climb and swim animations. R15 only. | [`App.applySnapshot`](../../src/avatar-copier.lua#L1654-L1801), [`F.applyAnimationIdsToAnimate`](../../src/avatar-copier.lua#L235-L272) |
| [Keep avatar after respawn](../../src/avatar-copier.lua#L4777 "Puts your avatar back on when you respawn.") | On | Puts the avatar back on every new character. | [`F.reapply`](../../src/avatar-copier.lua#L2589-L2600) |
| [See other script users' skins](../../src/avatar-copier.lua#L4778 "Script users in your server see each other's skins.") | On | Skin sync. Does nothing until a sync server is set in `Config.SyncUrl`, which is empty in this repository. See [Skin sync](../features/skin-sync.md). | [`Sync.enabled`](../../src/avatar-copier.lua#L5940-L5942) |

## Notifications

| Setting | Default | What it does | Read by |
| --- | --- | --- | --- |
| [Show notifications](../../src/avatar-copier.lua#L4780 "Small pop-ups in the bottom-right corner") | On | The small pop-ups in the bottom-right corner (cycle switches, the hidden-window hint…). Off hides them all. | [`App.toast`](../../src/avatar-copier.lua#L1436) |

## Open & close

| Setting | Default | What it does | Read by |
| --- | --- | --- | --- |
| [Start hidden](../../src/avatar-copier.lua#L4782 "The window stays closed when the script runs.") | Off | The window stays closed when the script runs. Skipped when nothing could reopen it. | [`UI.buildShell`](../../src/avatar-copier.lua#L3476-L3544) |
| [Floating button](../../src/avatar-copier.lua#L4785 "Shows a draggable button while the window is closed.") | On | A draggable button that brings the window back while it is hidden. | [`UI.effects`](../../src/avatar-copier.lua#L3764-L3769), [`UI.closeHub`](../../src/avatar-copier.lua#L3806-L3824) |
| [Reopen with the Roblox menu](../../src/avatar-copier.lua#L4786 "While the window is hidden, open and close the Roblox menu 3 times in a row") | On | While the window is hidden, open and close the Roblox menu 3 times within 5 seconds (<kbd>Esc</kbd> on PC, the Roblox logo on phones). Works without chat or a keyboard. | [`UI.watchMenu`](../../src/avatar-copier.lua#L5443-L5461) |
| [Hub shortcut](../../src/avatar-copier.lua#L4787 "Tap, then press a key to change it. Esc cancels.") | <kbd>RightControl</kbd> | Shows or hides the window. Tap it, then press the new key. <kbd>Esc</kbd> cancels. | [`UI.inputs`](../../src/avatar-copier.lua#L5462-L5511) |

The **How to reopen the window** card shows, live, which ways back work on this device. See [The window](../features/window.md#hiding-and-reopening).

> [!NOTE]
> The shortcut refuses keys the script or most games already use: <kbd>V</kbd>, <kbd>L</kbd>, <kbd>R</kbd>, <kbd>K</kbd>, <kbd>W</kbd>, <kbd>A</kbd>, <kbd>S</kbd>, <kbd>D</kbd>, <kbd>Space</kbd>, <kbd>Return</kbd>, <kbd>Tab</kbd> and <kbd>Backspace</kbd>.

## Advanced options

Tap **Show advanced options** to see these.

| Setting | Default | What it does | Read by |
| --- | --- | --- | --- |
| [Keep avatar between rounds](../../src/avatar-copier.lua#L4797 "Puts your avatar items back if the game removes them when a round starts.") | On | Puts back avatar items the game removes, and dresses local stand-in models of you. | [`Repair.queue`](../../src/avatar-copier.lua#L1571-L1591), [`applyToStandIn`](../../src/avatar-copier.lua#L2610-L2626) |
| [Reset character first](../../src/avatar-copier.lua#L4798 "Respawns you before applying, which gives the cleanest result.") | Off | Respawns you before applying, for the cleanest result. | [`App.applySnapshot`](../../src/avatar-copier.lua#L1654-L1801) |
| [Visual-only avatar](../../src/avatar-copier.lua#L4799 "Draws the avatar over your character instead of changing it.") | Off | Draws the avatar over your character instead of changing it. Always on in Evade. See [Visual-only mode](../features/visual-only.md). | [`Overlay.visualOnly`](../../src/avatar-copier.lua#L5546-L5548) |
| [Glow when avatar changes](../../src/avatar-copier.lua#L4800 "A short glow when your avatar changes. Only you can see it.") | On | A short glow and a sparkle burst when your avatar changes. Only you see it. | [`F.Swap.begin`](../../src/avatar-copier.lua#L1608-L1621) |
| [Show my avatar in the Roblox menu](../../src/avatar-copier.lua#L4801 "Your picture in the Players tab of the Roblox menu shows the avatar you are wearing.") | On | Your card in the Players page of the Roblox menu shows the avatar you wear, on your screen only. | [`UI.patchMenuAvatar`](../../src/avatar-copier.lua#L5378-L5403) |
| [Background blur](../../src/avatar-copier.lua#L4803 "Blurs the game behind the window.") | On | Blurs the game behind the window. | [`UI.effects`](../../src/avatar-copier.lua#L3764-L3769) |
| [Reduced motion](../../src/avatar-copier.lua#L4804 "Turns off window animations.") | Off | Turns off window animations. | [`UI.tween`](../../src/avatar-copier.lua#L3273-L3282) |
| [Performance mode](../../src/avatar-copier.lua#L4805 "Turns off extra visual effects. Helps on slower devices.") | Off | Turns off the blur, the glass background, the sparkle burst and the animations. | [`UI.effects`](../../src/avatar-copier.lua#L3764-L3769), [`F.Swap.burst`](../../src/avatar-copier.lua#L1622-L1641) |

> [!TIP]
> **Visual-only avatar** applies the next time you wear an avatar, not to the one you have on.

## Under the hood

| Part | Code | What it does |
| --- | --- | --- |
| The page | [`UI.buildSettings`](../../src/avatar-copier.lua#L4762-L4807) | Every card on this tab, in order. |
| A switch | [`UI.toggle`](../../src/avatar-copier.lua#L4705-L4718) | Flips `Store.Settings[key]`, runs the setting's own callback and saves. |
| A stepper | [`UI.stepper`](../../src/avatar-copier.lua#L4842-L4859) | The **−** / **+** control used by Interface size. |
| Advanced section | [`UI.collapsible`](../../src/avatar-copier.lua#L4748-L4761) | **Show advanced options** / **Hide advanced options**. |
| Reopen card | [`UI.reopenCard`](../../src/avatar-copier.lua#L4719-L4730), [`UI.refreshReopenCard`](../../src/avatar-copier.lua#L4731-L4747) | The live list of ways to reopen the window. |
| Defaults | [`Store.Settings`](../../src/avatar-copier.lua#L1244-L1246) | Every setting and its default value. |
| Ranges | [`Store.SettingRanges`](../../src/avatar-copier.lua#L1248) | Interface size 70 to 130, window 300 to 4000 × 240 to 4000. |
| Loading | [`Store.load`](../../src/avatar-copier.lua#L1350-L1410) | Reads saved settings, ignores wrong types and clamps numbers. |
| Settings into `Config` | [`Store.sync`](../../src/avatar-copier.lua#L1411-L1415) | Copies three settings into the `Config` table that older parts of the script read. |

### Every switch works the same way

```lua excerpt
function UI.toggle(parent,title,description,key,onChange,store)
    store=store or Store.Settings
…
    UI.connect(button.Activated,function() store[key]=not store[key]; refresh(); if onChange then onChange(store[key]) end; App.persist() end)
```

### The defaults

```lua excerpt
Store.Settings = {AutoReset = false, CopyAnims = Config.CopyAnimation, AutoReapply = true, MapPersist = true,
    GlassBlur = true, MobileOrb = true, ReducedMotion = false, LowEffects = false, Keybind = "RightControl",
    SwapEffect = true, Notifications = true, StartHidden = false, MenuReopen = true, HideTipSeen = false, MenuAvatar = true, SkinSync = true, VisualOnly = false, UIScale = 85, ScaleMigrated = false, WindowW = 0, WindowH = 0}
```

`HideTipSeen` and `ScaleMigrated` have no switch: the first remembers that you saw the "Hide Avatar Studio?" tip, the second that an old saved size was moved to 85% once.

### Settings and `Config`

Three settings also exist as `Config` keys at the top of the script. Once the window loads, the Settings page wins:

```lua excerpt
function Store.sync()
    Config.CopyAnimation = Store.Settings.CopyAnims
    Config.AutoReapply = Store.Settings.AutoReapply
    Config.MapPersist = Store.Settings.MapPersist
end
```

`Config.CopyAnimation` is only the default for **Copy animations** before you change it. See [Configuration](../reference/configuration.md).

---

| ← Previous | Up | Next → |
| :--- | :---: | ---: |
| [Auto & Cycle](auto-cycle.md) | [All docs](../README.md) | [Creator](creator.md) |
