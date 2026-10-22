[Docs](../README.md) / Reference / **Development**

# <img src="../assets/icons/reference.png" width="40" alt=""> Development

How the repository is organised, how to check a change, where to make common changes and which parts need care. Read [Architecture](architecture.md) first for the overall flow.

## Repository layout

```
src/avatar-copier.lua      the script (the only file users run)
tests/mock.lua             a stand-in of the Roblox API for the Luau CLI
tests/run.lua              the test scenario
tests/run.sh               builds and runs the tests
tools/check.sh             static checks
tools/doclinks.py          keeps the docs' line links and code excerpts in step with the script
tools/globals.txt          globals the script may use
tools/allowed-urls.txt     URLs the script may contain
docs/README.md             the documentation home
docs/tabs/                 one page per tab of the window
docs/features/             the window, hotkeys, skin sync, visual-only mode
docs/reference/            architecture, lifecycle, compatibility, formats, configuration, this page
docs/assets/               the icons, the logo and the window map used by the docs
```

## Checking a change

Install the [Luau command-line tools](https://github.com/luau-lang/luau/releases) and Python 3. CI uses version 0.741 from `luau-ubuntu.zip` (SHA-256 `134dc762ad26232af83e43f98dec03ff6030dd3a4452f9408b9d50ccea025503`).

```sh
tools/check.sh path/to/luau-bin
tests/run.sh path/to/luau-bin/luau
```

`tools/check.sh` fails on:

- a syntax error (`luau-compile`);
- a global that is not in `tools/globals.txt`, which is how a typo like `Instnace` is caught (`luau-analyze`);
- a URL in the script that is not in `tools/allowed-urls.txt`;
- a version mismatch between the first line of the script, the window subtitle and the newest `CHANGELOG.md` entry;
- CRLF line endings or trailing whitespace in any file;
- anything that looks like a token or a private key;
- a doc link or code excerpt that no longer matches the script (`tools/doclinks.py`, see [Writing docs](#writing-docs)).

CI runs both on every push and pull request.

### The tests

`tests/run.sh` concatenates `tests/mock.lua`, the script wrapped in `Mock.Run()` and `tests/run.lua` into one chunk, so the script's globals resolve to the mock's locals. `Mock.Run()` returns the script's tables (`App`, `UI`, `Store`, `Codec`, `Visual`, `Catalog`, `Auto`, `Sync`, `Overlay` and the rest), so the scenario can drive the window and also check internal state.

The mock is strict: unknown classes, properties, methods and enum items, values of the wrong type and writes to read-only properties raise errors, as they would in Roblox. Time is virtual (`task.wait` and `task.delay` run on `Mock.advance`), and every error inside the script, its tasks or its callbacks fails the run. It also fakes:

- users and avatars (`Mock.Users`), the catalog (`Mock.Catalog`, `Mock.Bundles`) and the in-game catalog search, which can be made to fail with `Mock.CatalogSearchFails`;
- R6 and R15 rigs built from a description (`Mock.buildRig`) and characters for the local player (`Mock.spawnCharacter`);
- executor functions: files (`Mock.Files`), the clipboard, `request` (answered by `Mock.RequestHandler` and logged in `Mock.Requests`) and `game:HttpGet` (`Mock.HttpGet`);
- input with `Mock.click`, `Mock.key`, `Mock.type`, and frames with `Mock.frame`.

A part with the `MockRejectApplyMesh` attribute refuses `ApplyMesh`, like the replicated parts some games use.

The scenario covers the window and every tab, settings and their saving, profile search and preview, skins (codec, share codes, old JSON, refused input), the shop, the cycle order, hotkeys, skin sync, applying avatars to R15, R6, headless and mesh-refusing characters while keeping the game's objects, respawns, item recovery, saved data on start and cleanup.

The mock is not an engine. There is no rendering, physics, replication, animation playback or layout beyond sizes and positions, and `ApplyMesh` and `AddAccessory` are simplified. A change that touches characters still needs a try in real games (see below). Add a `check(...)` for new behaviour; when a step is expected to log a warning, consume it with `expectWarning(text)` so the run doesn't fail on it.

### Trying it in a game

The tests can't tell how a game reacts. Before a release, try at least:

- an R15 game and an R6 game: apply, Undo, Restore, respawn;
- a round-based game that removes accessories or uses stand-ins;
- a game with weapons or tags on the character (MM2 is a good one);
- Evade, for visual-only mode;
- a phone, for the layout and the reopen methods.

## Where to change things

| To change | Look at |
| --- | --- |
| A startup option or hotkey | [`Config`](../../src/avatar-copier.lua#L8-L26) at the top ([Configuration](configuration.md)) |
| A setting | Its default in [`Store.Settings`](../../src/avatar-copier.lua#L1244-L1246), its switch in [`UI.buildSettings`](../../src/avatar-copier.lua#L4762-L4807) ([`UI.toggle`](../../src/avatar-copier.lua#L4705-L4718)), and [Settings](../tabs/settings.md) |
| A setting range | [`Store.SettingRanges`](../../src/avatar-copier.lua#L1248) or [`Store.AutoRanges`](../../src/avatar-copier.lua#L1257), and the stepper values in [`UI.buildSettings`](../../src/avatar-copier.lua#L4762-L4807) / [`UI.buildAuto`](../../src/avatar-copier.lua#L4885-L4959) |
| A tab | A `UI.build<Name>` function, the tab list in [`UI.buildShell`](../../src/avatar-copier.lua#L3476-L3544) and [`UI.layout`](../../src/avatar-copier.lua#L3582-L3687), and [`UI.selectTab`](../../src/avatar-copier.lua#L3901-L3911) if it renders on open |
| Catalog item types and filters | [`Catalog.Types`](../../src/avatar-copier.lua#L1834-L1874), [`Catalog.Filters`](../../src/avatar-copier.lua#L1881), [`Catalog.Categories`](../../src/avatar-copier.lua#L1882-L1895), [`Catalog.Subs`](../../src/avatar-copier.lua#L1896-L1899) |
| What a saved skin records | [`Visual.schemas`](../../src/avatar-copier.lua#L821-L831) and [`Visual.effects`](../../src/avatar-copier.lua#L833-L851) (each class with its fields and value kinds), and the limits in [`Visual.validate`](../../src/avatar-copier.lua#L977-L1012) |
| How an avatar is applied | [`App.applySnapshot`](../../src/avatar-copier.lua#L1654-L1801) and [`Appearance.apply`](../../src/avatar-copier.lua#L508-L571) |
| Status messages | [`App.report`](../../src/avatar-copier.lua#L1434)`(message, kind)` with `info`, `success`, `warning`, `error` or `loading` |
| Toasts | [`App.toast`](../../src/avatar-copier.lua#L1436)`(spec)` (respects **Show notifications**), see below |
| The skin sync server | `Config.SyncUrl`; the protocol is in [Data formats](data-formats.md#skin-sync-protocol) |
| The icons or the logo | [`UI.IconData`](../../src/avatar-copier.lua#L2851-L3074) / [`UI.LogoData`](../../src/avatar-copier.lua#L3077-L3220) (base64 PNG) and [`UI.IconBytes`](../../src/avatar-copier.lua#L2850) / [`UI.LogoBytes`](../../src/avatar-copier.lua#L3076) (the decoded size, which is checked). The icon sheet is a grid of 64 px cells, 8 per row, in the order of [`UI.IconNames`](../../src/avatar-copier.lua#L2839-L2840) |

When a new setting or saved field is added, give it a default so older files still load, and keep the type checks in [`Store.load`](../../src/avatar-copier.lua#L1350-L1410). `Store.load` opens any file with a `Version` above 4 read-only, so only raise the version for a change older builds can't read, and add the migration in the same change.

## Parts that need care

- **One apply path.** Everything that changes the character goes through `App.applySnapshot`, guarded by `App.Busy`. After every yield it checks that `lp.Character` is still the same, alive character; keep those checks when adding steps, because the player can die or respawn at any wait.
- **In-place changes.** `Appearance.apply` never replaces body parts or joints. Game objects stay attached only because the parts they hang on are the same instances. `copySurface` restores the physical properties after `ApplyMesh`, and automatic scaling is paused while an avatar is worn (the original value is kept in an attribute and given back on Restore).
- **Hip height.** It follows the new body only when every leg part took the new size; otherwise characters hover and can jump again in mid-air.
- **Animations.** Changed `Animation` instances are replaced, not edited, because tracks already loaded from the old instance keep playing the old animation. Restarts go through `F.restartAnimate`, which serialises them with `F.AnimSerial` and gives preloading a short head start.
- **Outside data.** Saved files, share codes and skins from other players all go through `Codec.decode` and `Visual.validate`. Anything that adds fields to the skin format needs a matching check there.
- **Connections.** Long-lived connections go through `RegisterConnection` or `UI.connect`, row connections through `UI.rowConnect`, and loops check `App.alive()`. Otherwise a re-run leaves the old copy running.
- **Executor functions.** Check each one with `type()` before calling it, and keep the feature working without it.
- **Window scale.** Children of the window are laid out before its `UIScale`, so absolute pixel values are divided by the scale (see `UI.openDropdown` and the cycle drag).
- **Chat.** The same message can arrive through `Player.Chatted`, `TextChatService.MessageReceived` and the emote command. The cycle commands are de-duplicated for one second, and showing a window that is already visible does nothing.

## Legacy code

Version 25.0.1 of this repository removed the code nothing called anymore: an older apply path that replaced body parts (`Appearance.capture`, `Appearance.restore`), camera, dummy and tool-protection helpers, the name tag restore chain, and the `Config` keys `DoorsCameraFix`, `SpoofGameEvents` and `RestoreYourTagAfterRespawn`. A syntax-tree comparison confirmed that every statement left in the script is unchanged.

A few old pieces stay, because live code still reaches them:

- [`F.ensureOriginalTagsScanned`](../../src/avatar-copier.lua#L687) and [`F.scanYourOriginalTags`](../../src/avatar-copier.lua#L686) run on every apply. They keep copies of the name tags on your head, which nothing reads now, but they also set `Archivable` on those tags. Removing them would change what happens to the game's objects, so they were kept.
- The [first `_G.Copier_ToolsGiverToggle`](../../src/avatar-copier.lua#L202 "_G.Copier_ToolsGiverToggle = function() if not IsAlive()") and [`F.showToolsGUI`](../../src/avatar-copier.lua#L204). A second definition further down replaces the toggle, but the <kbd>L</kbd> key can reach the first one while the script is still loading.
- The camera lock loop, [`F.unlockCamera`](../../src/avatar-copier.lua#L661) and [`F.resumeCamScripts`](../../src/avatar-copier.lua#L660). Nothing locks the camera or suspends camera scripts anymore, so they do nothing, but `App.applySnapshot` and `cleanup` call them.
- `S_SafeTools`, which `App.applySnapshot` clears but nothing fills, and the `_G` leftovers listed in [Architecture](architecture.md#globals-and-names).

## Toast notifier

[`Toast`](../../src/avatar-copier.lua#L2638) only needs TweenService, TextService and the instances it creates, so the block can be reused elsewhere ([`Toast.new`](../../src/avatar-copier.lua#L2651-L2677), [`Toast:Notify`](../../src/avatar-copier.lua#L2713-L2816)).

```lua
local notifier = Toast.new({
    Parent = someFrameOrScreenGui,  -- required; toasts stack in its bottom-right corner
    Theme = {                       -- optional; every key has a default (Toast.DefaultTheme)
        Background = Color3, Text = Color3, Muted = Color3, Line = Color3,
        Kinds = {info = Color3, success = Color3, warning = Color3, error = Color3},
    },
    Icon = function(parent, name, position, color) end, -- optional; draws a 24x24 icon for spec.Icon
    Font = {Regular = Enum.Font.Gotham, Bold = Enum.Font.GothamBold}, -- optional
    Width = 264,                    -- optional; shrinks on small screens
    Max = 4,                        -- optional; the oldest toast leaves when a new one exceeds it
    Margin = 12,                    -- optional; distance from the parent's bottom-right corner
    Lift = 0,                       -- optional; extra space at the bottom
    ReducedMotion = function() return false end, -- optional; true means no slide or fade
})

local handle = notifier:Notify({
    Title = "Saved",                -- required
    Text = "Your skin was saved.",  -- optional second line, wraps
    Kind = "success",               -- "info" (default), "success", "warning" or "error"
    Icon = "circle-check",          -- optional; drawn with the Icon option instead of the kind's glyph
    Duration = 4,                   -- optional seconds; 0 keeps it until tapped
    Image = "rbxassetid://…",       -- optional picture in the badge
    Action = {Text = "Open", Callback = function() end}, -- optional button under the text
    Featured = true,                -- optional; wider card, larger badge, stronger accent
    Dismissible = false,            -- optional; a tap on the card doesn't close it
})
handle:Dismiss()
notifier:Clear()
notifier:Destroy()
```

If the `Icon` function errors, the kind's built-in glyph is drawn instead. Heights are measured from the text with TextService rather than `AutomaticSize`, which can feed back on itself and stretch the card. A toast slides in from the right, a line under it shows the time left, and the newest one sits closest to the corner.

## Writing docs

The docs are written for players first: say what a control does and how to use it, then show the code in an **Under the hood** section. Each tab of the window has its own page in `docs/tabs/`, with the same layout: what the tab is for, a short "Try it", a table of every control, notes and warnings, a diagram, then the code.

### Links into the script

A link into `src/avatar-copier.lua` must say what it points at, so `tools/doclinks.py` can check it. There are two forms:

```md
[`Catalog.search`](../../src/avatar-copier.lua)
[the key handler](../../src/avatar-copier.lua "RegisterConnection(UIS.InputBegan")
```

- **A name in backticks** links the whole definition. It must be a top-level name: `Name`, `Table.field`, `Table:method` or a local function.
- **A title** (the text in quotes) links the one line of the script that contains it, or the whole statement when that line starts a top-level statement. The title must be on exactly one line.

Leave the line numbers out (or wrong) when you write a link and run:

```sh
python3 tools/doclinks.py path/to/luau-bin/luau-ast --write
```

It fills in `#Lstart-Lend` from the script's syntax tree. When the script changes and lines move, run it again; `tools/check.sh` fails until you do. A title that matches no line or several lines is reported, never guessed.

### Code excerpts

A block that starts with ` ```lua excerpt ` must be copied from the script: each line has to appear in the script, in the same order (indentation is ignored). A line that is only `…` skips over code. Use plain ` ```lua ` for examples that aren't in the script.

### Pictures

`docs/assets/icons/*.png` are the tab icons from the script's own icon sheet ([Lucide](https://lucide.dev), ISC), drawn on a purple badge so they show on light and dark pages. `docs/assets/window.svg` is a map of the default window, drawn from the sizes in [`UI.buildShell`](../../src/avatar-copier.lua#L3476-L3544), [`UI.layout`](../../src/avatar-copier.lua#L3582-L3687) and [`UI.buildAvatar`](../../src/avatar-copier.lua#L3913-L3971).

## Style

- Keep the existing style: 4-space indentation, the compact one-line helpers where the file already uses them, and English for every message the player sees.
- Comment only what another developer could get wrong: why an order matters, a Roblox quirk, a game that behaves differently. Don't narrate what the next line does.
- No new dependencies and no code loaded from the network at run time.
- Mark functions that yield with a `-- Yields.` comment, as the file already does.

## Releasing

1. Update the version in the first line of the script, in the window subtitle (`UI.buildShell`) and at the top of `CHANGELOG.md`. `tools/check.sh` fails when they differ.
2. Run `python3 tools/doclinks.py path/to/luau-ast --write` if the script changed.
3. Run `tools/check.sh` and `tests/run.sh`.
4. Try the change in real games.

---

| ← Previous | Up | Next → |
| :--- | :---: | ---: |
| [Configuration](configuration.md) | [All docs](../README.md) | [Troubleshooting](../troubleshooting.md) |
