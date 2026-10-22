[Docs](../README.md) / Tabs / **Favorites & Recent**

# <img src="../assets/icons/favorites-recent.png" width="40" alt=""> Favorites & Recent

Two lists of Roblox profiles: the ones you starred, and the ones you looked at lately. Both are saved on your device, so they are still there next time.

| List | What goes in it | Holds up to |
| --- | --- | --- |
| **Favorites** | Profiles you starred with **Add favorite** or the star in [Server](server.md) | 200 |
| **Recent searches** | Every profile you previewed in [Copy Avatar](copy-avatar.md) or wore from a list | 30, newest first |

## Try it

1. Open **Favorites & Recent**.
2. Pick **Favorites** or **Recent searches** at the top.
3. Tap **Wear** on a row to put that avatar on, or **Preview** to see it in 3D first.

## What every control does

| Control | What it does |
| --- | --- |
| **Favorites** / **Recent searches** | Switches between the two lists. The selected one is highlighted. |
| **Filter this list by name** | Shows only rows whose name, display name or id contains the text. |
| Count | How many profiles are shown. |
| **Clear list** | Empties the selected list after you confirm. Your current avatar doesn't change. |
| **Wear** | Applies the profile's avatar (loaded fresh from Roblox). |
| **Preview** | Opens it in [Copy Avatar](copy-avatar.md). |
| **X** | Removes that one profile from the list, after you confirm. |

> [!NOTE]
> Lists store only the id, the username and the display name, never the avatar itself. Wearing a favorite always gives you the avatar that person has **today**. To keep a look exactly as it is, save it in [Saved Skins](saved-skins.md).

> [!TIP]
> **Auto & Cycle** can use your favorites too: **Add favorites** puts all of them in the avatar cycle, and the auto-load source "Random favorite" picks one when the script starts. See [Auto & Cycle](auto-cycle.md).

## Under the hood

| Part | Code | What it does |
| --- | --- | --- |
| The page | [`UI.buildCollection`](../../src/avatar-copier.lua#L4486-L4504) | The two list buttons, the filter, the count, **Clear list** and the list. |
| Filling the list | [`UI.renderCollection`](../../src/avatar-copier.lua#L4505-L4524) | Picks `Store.Favorites` or `Store.Recent`, filters it and adds one row per profile with a remove button. |
| One row | [`UI.profileRow`](../../src/avatar-copier.lua#L4434-L4450) | Shared with [Server](server.md). Here the last button removes the row instead of starring. |
| Starring | [`App.toggleFavorite`](../../src/avatar-copier.lua#L1786-L1794) | Adds to the top, refuses past 200, saves. |
| Is it a favorite? | [`App.favoriteIndex`](../../src/avatar-copier.lua#L1781-L1785) | Matches by user id, or by name when there is no id. |
| Recent | [`App.addRecent`](../../src/avatar-copier.lua#L1795-L1800) | Moves the profile to the top, keeps 30. |
| Confirmations | [`UI.confirm`](../../src/avatar-copier.lua#L5588-L5603) | The Cancel / Confirm dialog. |
| Saving | [`App.persist`](../../src/avatar-copier.lua#L1777-L1780) → [`Store.save`](../../src/avatar-copier.lua#L1756-L1760) | Writes `Copier_SavedProfiles.json` (see [Data formats](../reference/data-formats.md#saved-file)). |

### Recent keeps one entry per person, newest first

```lua excerpt
function App.addRecent(profile)
    for i = #Store.Recent, 1, -1 do if Store.Recent[i].Id == profile.Id then table.remove(Store.Recent, i) end end
    table.insert(Store.Recent, 1, {Id = profile.Id, Name = profile.Name, DisplayName = profile.DisplayName})
    while #Store.Recent > 30 do table.remove(Store.Recent) end
    App.Refresh(); App.persist()
end
```

### Favorites stop at 200

```lua excerpt
function App.toggleFavorite(profile)
    if not profile then return end
    local i = App.favoriteIndex(profile)
    if i then table.remove(Store.Favorites, i) else
        if #Store.Favorites >= 200 then App.report("The 200-favorite limit has been reached.", "warning"); return end
        table.insert(Store.Favorites, 1, {Id = profile.Id, Name = profile.Name, DisplayName = profile.DisplayName})
    end
    App.Refresh(); App.persist()
end
```

### Where the lists are saved

Both lists live in `Copier_SavedProfiles.json` in your executor's workspace folder, under `Favorites` and `Recent`. Without file access they last until you leave the game. See [Lifecycle](../reference/lifecycle.md#what-is-saved).

---

| ← Previous | Up | Next → |
| :--- | :---: | ---: |
| [Server](server.md) | [All docs](../README.md) | [Saved Skins](saved-skins.md) |
