[Docs](../README.md) / Reference / **Data formats**

# <img src="../assets/icons/reference.png" width="40" alt=""> Data formats

The formats the script reads and writes: the saved file, the description codec, visual snapshots, share codes, old JSON backups and the skin sync protocol. Everything is JSON produced by `HttpService:JSONEncode`.

## Saved file

`Copier_SavedProfiles.json` in the executor workspace, format version 4, written by [`Store.save`](../../src/avatar-copier.lua#L1756-L1760) and read by [`Store.load`](../../src/avatar-copier.lua#L1690-L1750):

```json
{
  "Version": 4,
  "Favorites": [{"Id": 156, "Name": "Builderman", "DisplayName": "Builderman"}],
  "Recent": [{"Id": 156, "Name": "Builderman", "DisplayName": "Builderman"}],
  "Looks": [{"Key": "8F0C…", "Name": "My skin", "Source": "My character · R15", "Updated": 1792354503, "Data": {}}],
  "Settings": {"UIScale": 85, "Keybind": "RightControl", "SkinSync": true},
  "Auto": {"LoadEnabled": false, "LoadSource": "Chosen", "Chosen": null, "Games": {}, "List": [], "Index": 0},
  "Promo": {"Runs": 3, "Shown": 0, "FirstAt": 0}
}
```

- `Favorites` (up to 200) and `Recent` (up to 30) hold Roblox profiles. Older files used `SavedUsers` for favorites; it is still read.
- `Looks` (up to 100) are saved skins. `Data` is a description in the codec below, usually with a `Visual` snapshot. A skin whose data doesn't validate is dropped on load.
- `Settings` holds the toggles listed in [Settings](../tabs/settings.md) by key: `AutoReset`, `CopyAnims`, `AutoReapply`, `MapPersist`, `GlassBlur`, `MobileOrb`, `ReducedMotion`, `LowEffects`, `Keybind`, `SwapEffect`, `Notifications`, `StartHidden`, `MenuReopen`, `HideTipSeen`, `MenuAvatar`, `SkinSync`, `VisualOnly`, `UIScale` (0 for Auto, or 70 to 130), `ScaleMigrated`, `WindowW` and `WindowH` (0 for automatic, or 300 to 4000 and 240 to 4000 unscaled pixels).
- `Auto` holds `LoadEnabled`, `LoadSource` (`Chosen`, `Last`, `Random`, `Cycle`), `LoadDelay` (0 to 30), `Chosen`, `Last`, `Games` (place id string to entry, up to 100), `CycleEnabled`, `Trigger` (`Death`, `Respawn`, `Timer`, `Both`), `EveryDeaths` (1 to 50), `TimerSeconds` (10 to 3600), `Order` (`Sequential`, `Shuffle`, `Random`, `PingPong`), `Cooldown` (0 to 300), `EndAction` (`Loop`, `Stop`, `Restore`), `Resume`, `Notify`, `Index` (0 to 50) and `List` (up to 50 entries).
- An **entry** is `{"Kind": "User", "Id": 156, "Name": "Builderman", "DisplayName": "Builderman"}` or `{"Kind": "Look", "Key": "8F0C…", "Name": "My skin"}`. Entries never hold a description; profiles are fetched again and skins are read from `Looks` when used.
- `Promo` paces the Discord invite.

Values of the wrong type are ignored and numbers are clamped to their ranges. A file with a `Version` above 4 is opened read-only.

## Description codec

[`Codec.encode`](../../src/avatar-copier.lua#L1043-L1068) turns a `HumanoidDescription` into this table (version 2) and [`Codec.decode`](../../src/avatar-copier.lua#L1069-L1139) builds one back:

```json
{
  "Version": 2,
  "Properties": {"Face": 7699174, "Shirt": 0, "HeadScale": 1, "HatAccessory": "", "IdleAnimation": 0},
  "Colors": {"HeadColor": [1, 0.8, 0.6]},
  "HasAccessories": true,
  "Accessories": [{"AssetId": 1028606, "AccessoryType": "Hat", "IsLayered": false}],
  "Emotes": {"Wave": [3576686446]},
  "EquippedEmotes": [{"Name": "Wave", "Slot": 1}],
  "Visual": {}
}
```

- `Properties` holds the asset fields (`Face`, `Head`, `Torso`, `LeftArm`, `RightArm`, `LeftLeg`, `RightLeg`, `Shirt`, `Pants`, `GraphicTShirt` and the eight animation fields, including `MoodAnimation`), the six scale fields and the comma-separated accessory string fields.
- `Accessories` is `GetAccessories(true)`: `AssetId`, the `AccessoryType` name, `IsLayered` and, when set, `Order`, `Puffiness`, `Position`, `Rotation` and `Scale` (as `[x, y, z]`).
- A table without `Version` is read as the older flat format, where the properties sit at the top level.

Decoding keeps only valid values: asset ids are whole numbers from 0 to 2⁵³−1, scales 0 to 10, colours 0 to 1, accessory strings digits and commas under 6000 characters, up to 150 accessories (`Order` 0 to 1000, `Puffiness` 0 to 10, vectors within ±10000), up to 100 emote names of 100 characters with 20 ids each, and up to 8 equipped emotes in slots 1 to 8. Decoding fails when no asset field is valid or Roblox rejects the accessory list.

## Visual snapshot

`Data.Visual`, version 1, records the real parts of a character ([`Visual.capture`](../../src/avatar-copier.lua#L1353-L1392)):

```json
{
  "Version": 1,
  "RigType": "R15",
  "Body": {"Head": {"Class": "MeshPart", "Size": [1.2, 1.2, 1.2], "Color": [1, 0.8, 0.6], "Transparency": 0,
                    "MeshId": "rbxassetid://123", "TextureId": "", "Material": "Plastic", "Reflectance": 0, "Nodes": []}},
  "Accessories": [{"Name": "Cap", "Type": "Hat", "Handle": {"Class": "Part"}, "AttachmentPoint": [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]}],
  "Clothes": {"Shirt": "rbxassetid://1", "Pants": "", "Graphic": ""},
  "Colors": {"Head": [1, 0.8, 0.6]},
  "Scales": {"BodyHeightScale": 1},
  "Links": [{"A": "UpperTorso", "B": "Head", "C0": [0, 0.8, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1], "C1": [0, -0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]}],
  "HipHeight": 2,
  "RootSize": [2, 2, 1],
  "Animations": [{"Path": ["idle", "Animation1"], "Id": "rbxassetid://507766666"}]
}
```

- `Body` maps standard body part names (R15 or R6, never `HumanoidRootPart`) to a **part row**: `Class` (`Part` or `MeshPart`), `Size`, `Color`, `Transparency`, `MeshId` and `TextureId` for mesh parts, `Material`, `Reflectance`, optional `OriginalSize` and `ScaleType`, and `Nodes`.
- `Nodes` is the part's children as `{"Class", "Name", "Properties", "Children"}`. Only these classes are recorded and rebuilt: `Attachment`, `Bone`, `SpecialMesh`, `BlockMesh`, `CylinderMesh`, `Decal`, `Texture`, `SurfaceAppearance`, `WrapTarget`, `WrapLayer`, `FaceControls`, and the effects `ParticleEmitter`, `Fire`, `Sparkles`, `Smoke`, `PointLight`, `SpotLight`, `SurfaceLight`, `Trail` and `Beam`. Created effects get the `Lyra_Effect` attribute.
- `Links` are the joint offsets between body parts; `Animations` are the ids under `Animate`, by path.
- Old JSON imports carry `"Legacy": true`.

Property values are encoded by type: a CFrame is its 12 components, a Vector3 `[x, y, z]`, a Color3 `[r, g, b]`, an enum `[EnumName, ItemName]`, a Vector2 `[x, y]`, a NumberRange `[min, max]`, a ColorSequence `[[time, r, g, b], …]`, a NumberSequence `[[time, value, envelope], …]`, and a trail or beam attachment the name of a sibling attachment.

### Limits

[`Visual.validate`](../../src/avatar-copier.lua#L1317-L1352) refuses a snapshot when any of these fail, whatever its source (your file, a share code or skin sync):

- version 1 and a rig of `R15` or `R6`; 1 to 20 body parts with standard names; up to 150 accessories, 32 joints and 100 animations;
- part sizes 0.001 to 64 studs, colours 0 to 1, transparency 0 to 1;
- asset ids `rbxassetid://<digits>`, `rbxasset://…` or an `http(s)` link with `id=<digits>`, at most 300 characters;
- CFrame positions within ±128 studs and rotation components within ±1.001;
- at most 4000 nodes in total, nested less than 12 deep, of the classes above only;
- effect values (colours above 1 for HDR glow, forces such as particle acceleration) within ±100000. A single effect value that is out of range is dropped instead of refusing the skin.

## Share codes

A share code ([`Looks.share`](../../src/avatar-copier.lua#L2681-L2683)) is `LYRA3:` followed by the JSON `{"Version": 2, "Name": "...", "Data": {...}}`, where `Data` is a description with its visual snapshot. Import ([`Looks.import`](../../src/avatar-copier.lua#L2659-L2680)) also accepts the `LYRA2:` prefix, the JSON without a prefix and packets with `Version` 1, up to 2,000,000 characters. Imported data is re-encoded through the codec, so only valid fields are kept.

## Old JSON backups

Earlier versions exported skins as JSON with Portuguese keys. Import recognises them by `MembrosCorpo` or `MembrosCustom` and converts them with [`Visual.legacy`](../../src/avatar-copier.lua#L1393-L1419):

| Key | Meaning |
| --- | --- |
| `RigType` | `R15` or `R6` |
| `MembrosCorpo`, `MembrosCustom` | Body parts: `Size`, `Color`, `Transparency`, `MeshId`, `TextureId`, `SurfaceColorMap` |
| `Acessorios` | Accessories: `Nome`, the same part fields, `AttachmentName`, `AttachmentCFrame`, `Scale`, `Offset` |
| `Roupas` | Clothing: `Shirt`, `Pants`, `Graphic` |
| `Cores` | Body colours |
| `Escalas` | Scale values |
| `Animacoes` | Animation ids by name |
| `IsHeadless` | Hides the head |

These files have no joint offsets, so offsets are scaled from the size change and the hip height is measured from the feet. Accessories with a non-default mesh scale or offset are rebuilt as a `Part` with a `SpecialMesh`.

## Skin sync protocol

> [!NOTE]
> `Config.SyncUrl` is empty in this repository, so none of these requests are made until you set a server. See [Skin sync](../features/skin-sync.md).

The client ([`Sync.call`](../../src/avatar-copier.lua#L6286-L6292)) posts JSON to `Config.SyncUrl` with `Content-Type: application/json`, through the executor's `request` function. It only runs while **See other script users' skins** is on, `Config.SyncUrl` is not empty, the server has a `JobId` and `request` exists. Every request carries `job` (the server's `JobId`) and `user` (your user id).

**beat**, about every 8 s, and at most every 5 s right after your avatar changes:

```json
{"a": "beat", "job": "6f0b2c4e-…", "user": 1, "hash": "1a2b3c4d000008f3", "data": "{\"Version\":2,\"Data\":{…}}"}
```

- `hash` identifies the skin you wear and is `""` when you wear your own appearance. It is the 32-bit FNV-1a hash of `data` followed by its length, as two 8-digit hex numbers ([`Sync.hash`](../../src/avatar-copier.lua#L6294-L6298)).
- `data` is sent only when the hash changed since the last accepted beat. A skin longer than 250,000 characters is not shared at all: the beat carries `""` as if you wore your own appearance.
- The reply is `{"ok": true, "need": false, "peers": [{"user": 777, "hash": "…"}]}`. `need: true` means the server doesn't have the data for that hash; the client sends the beat again with `data`. `peers` lists the other users in the same server who share a skin.

**get**, for each peer whose hash is new:

```json
{"a": "get", "job": "6f0b2c4e-…", "user": 1, "peer": 777}
```

The reply is `{"ok": true, "hash": "…", "data": "…"}`. The client uses it only when `hash` matches the one listed for that peer and `data` (at most 262,144 characters) passes the same checks as an imported share code ([`Sync.decode`](../../src/avatar-copier.lua#L6311-L6320)). A failed fetch is retried after 8 s; a skin that can't be built waits 10 s longer after each failure, up to 60 s.

**leave**, when skin sync is turned off or the script is cleaned up:

```json
{"a": "leave", "job": "6f0b2c4e-…", "user": 1}
```

Any reply that isn't JSON with `ok: true` is ignored, so a server can refuse a request by answering `{"ok": false}`.

A compatible server keeps the latest `hash` and `data` per job and user, lists the other users of the same job in `peers`, forgets users who stop sending beats, and should validate and rate-limit what it receives, since any client can post.

---

| ← Previous | Up | Next → |
| :--- | :---: | ---: |
| [Compatibility](compatibility.md) | [All docs](../README.md) | [Configuration](configuration.md) |
