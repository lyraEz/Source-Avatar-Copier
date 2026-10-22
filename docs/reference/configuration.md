[Docs](../README.md) / Reference / **Configuration**

# <img src="../assets/icons/reference.png" width="40" alt=""> Configuration

The [`Config`](../../src/avatar-copier.lua#L8-L29) table at the top of `src/avatar-copier.lua` holds the startup options and the hotkeys. Most people never need to touch it: everything a player changes lives in the [Settings](../tabs/settings.md) tab and is saved there.

To change a value, edit the script before running it:

```lua
local Config = {
    ...
    FreeCamKey = Enum.KeyCode.B,   -- free camera on B instead of V
    ...
}
```

## Every key

| Key | Default | What it does |
| --- | --- | --- |
| `TargetUsername` | `""` | A username or user ID to open in the 3D preview when the script starts (needs `CopyAvatar` or `CopyAvatarHD`). `"restore"`, `"stop"` or your own username start **restore mode** instead (see below). Auto-load is skipped while this is set. |
| `CopyAvatar`, `CopyAvatarHD` | `true`, `false` | Either one enables the `TargetUsername` preview. |
| `AutoReapply` | `true` | Follows **Keep avatar after respawn** once the window loads. |
| `MapPersist` | `true` | Follows **Keep avatar between rounds** once the window loads. |
| `CopyAnimation` | `false` | The default for **Copy animations** before you change it in Settings. |
| `AnimResync` | `true` | Repeats the animation swap once, 1.2 s after applying, so other players load the new animations completely. |
| `EnableFreeCam` | `true` | Turns the free camera key on or off. |
| `FreeCamKey` | `V` | Free camera. |
| `FreeCamSpeed` | `1.5` | How fast the free camera flies. |
| `DualWieldKey` | `R` | Copy the held tool's handle to the left hand. |
| `ToolsGiverKey` | `L` | ToolsGiver on or off. |
| `HideUIKey` | `K` | Hide the game's interface. |
| `SyncUrl` | `""` | The [skin sync](../features/skin-sync.md) server. Empty keeps skin sync off. |
| `DoorsCameraFix`, `SpoofGameEvents`, `RestoreYourTagAfterRespawn` | | Not used by this version (see [Legacy code](development.md#legacy-code)). |

The hub shortcut (<kbd>RightControl</kbd>) isn't in `Config`; change it in [Settings](../tabs/settings.md#open--close).

## Restore mode

With `TargetUsername = "restore"` (or `"stop"`, or your own username), the script doesn't open the window. It gives back the camera, the top bar and Roblox's interface, resets your character so the game gives you a fresh one, and stops. Use it when something went wrong and you want a clean start.

[The restore mode block](../../src/avatar-copier.lua#L142-L150 "targetLower == lp.Name:lower()") is near the top of the script.

## Under the hood

```lua excerpt
-- AutoReapply, MapPersist and CopyAnimation follow the Settings page once the hub loads.
-- CopyAnimation is only the default for "Copy animations".
local Config = {
    AutoReapply = true,
    MapPersist = true,
…
    -- Skin sync server, see docs/features/skin-sync.md. Empty keeps skin sync off.
    SyncUrl = "",
}
```

| Part | Code | What it does |
| --- | --- | --- |
| Settings into `Config` | [`Store.sync`](../../src/avatar-copier.lua#L1751-L1755) | Copies three settings into `Config` on every save. |
| The preview on start | [the startup block](../../src/avatar-copier.lua#L6432-L6467 "local built,buildError=xpcall(function()") | Searches `TargetUsername` once the window is built. |
| Hotkeys | [the `InputBegan` handler](../../src/avatar-copier.lua#L1008-L1014 "RegisterConnection(UIS.InputBegan:Connect(function(input, processed)") | Reads the four `Config` keys. |

---

| ← Previous | Up | Next → |
| :--- | :---: | ---: |
| [Data formats](data-formats.md) | [All docs](../README.md) | [Development](development.md) |
