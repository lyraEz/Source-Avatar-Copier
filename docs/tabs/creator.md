[Docs](../README.md) / Tabs / **Creator**

# <img src="../assets/icons/creator.png" width="40" alt=""> Creator

Who made the script and where to find them: the Discord server and the GitHub profile of [lyraEz](https://github.com/lyraEz).

## What is on the tab

| Card | What it does |
| --- | --- |
| **Discord** | The invite link `https://discord.gg/8bxXcn2Vfb`. Tap the link or **Copy link** to copy it. |
| **GitHub profile** | lyraEz's photo, name and bio, with the link `https://github.com/lyraEz` and **Copy link**. |

**Copy link** changes to "Copied!" for a moment. When your executor can't copy to the clipboard, the link turns into a selected text box so you can copy it by hand.

> [!NOTE]
> The GitHub photo is downloaded the first time you open this tab and saved as `LyraAvatarStudio_github_lyraEz.png` in your executor's workspace, so later runs don't download it again. Without `getcustomasset` and `writefile` the card shows a letter "L" instead.

## The Discord invite notification

A notification inviting you to the Discord appears **at most twice, ever**:

1. 5 minutes into a session.
2. Once more, 1 minute into the 10th run after that.

It needs saved data (otherwise the counters would reset every run) and respects **Show notifications** in [Settings](settings.md). **Join the Discord** copies the invite, or opens this tab when copying isn't possible.

## Under the hood

| Part | Code | What it does |
| --- | --- | --- |
| The page | [`UI.buildCreator`](../../src/avatar-copier.lua#L5181-L5232) | The two cards, the copy buttons and the manual-copy fallback. |
| The links | [`App.Creator`](../../src/avatar-copier.lua#L1430) | Name, GitHub and Discord addresses in one place. |
| The photo | [`UI.loadCreatorPhoto`](../../src/avatar-copier.lua#L5154-L5179) | Downloads the photo once, checks it is a real PNG or JPEG under 2 MB, caches it. |
| The invite | [`UI.schedulePromo`](../../src/avatar-copier.lua#L5515-L5539) | Counts runs in `Store.Promo` and shows the notification at most twice. |

### The photo is checked before it is used

```lua excerpt
                    local response=requestFn({Url="https://github.com/lyraEz.png?size=256",Method="GET"})
                    assert(response and response.StatusCode==200,"Profile photo unavailable")
                    body=response.Body
                else body=game:HttpGet("https://github.com/lyraEz.png?size=256") end
                assert(type(body)=="string" and #body>16 and #body<2097152,"Invalid profile photo")
                assert(body:sub(1,8)=="\137PNG\13\10\26\10" or body:sub(1,3)=="\255\216\255","Invalid image format")
                writefile(path,body)
```

The first 8 bytes of every PNG file, and the first 3 of every JPEG, are fixed. Checking them means the script never hands anything else to `getcustomasset`.

### At most two invites

```lua excerpt
function UI.schedulePromo()
    if type(writefile)~="function" or Store.ReadOnly then return end
    local promo=Store.Promo
    if promo.Shown>=2 then return end
    promo.Runs=math.min(promo.Runs+1,1000)
    if not App.persist() then return end
    local second=promo.Shown==1
    if second and (promo.Runs<10 or promo.Runs<=promo.FirstAt) then return end
    task.delay(second and 60 or 300,function()
```

### Executor functions used

| Function | Used for |
| --- | --- |
| `setclipboard` / `toclipboard` | Copying a link |
| `request` / `http_request` / `syn.request`, or `game:HttpGet` | Downloading the photo |
| `writefile`, `isfile`, `getcustomasset` / `getsynasset` | Caching and showing the photo |

All of them are optional; see [Compatibility](../reference/compatibility.md#executors).

---

| ← Previous | Up | Next → |
| :--- | :---: | ---: |
| [Settings](settings.md) | [All docs](../README.md) | [The window](../features/window.md) |
