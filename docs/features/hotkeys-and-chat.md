[Docs](../README.md) / Features / **Hotkeys and chat**

# <img src="../assets/icons/hotkeys.png" width="40" alt=""> Hotkeys and chat commands

Keyboard shortcuts and chat commands that work while the script runs, even with the window hidden.

## Keys

| Key | What it does |
| --- | --- |
| <kbd>RightControl</kbd> | Shows or hides the window. Change it in [Settings](../tabs/settings.md#open--close). |
| <kbd>V</kbd> | **Free camera.** Your character is frozen in place, the arrow keys fly the camera and holding the right mouse button looks around. Press <kbd>V</kbd> again to stop. Applying an avatar or respawning also stops it. |
| <kbd>R</kbd> | **Left-hand copy.** Copies the handle of the tool you hold (without its scripts) and welds it to your left hand. Press again to remove it. |
| <kbd>L</kbd> | **ToolsGiver** on or off. Every 1.5 s it looks for tools you don't have in the workspace, `Lighting`, `ReplicatedStorage`, `ReplicatedFirst`, `StarterPack` and `Players`, and puts a copy in your backpack. |
| <kbd>K</kbd> | Hides the game's interface (everything except this window and the touch controls) plus Roblox's own interface. Press again to bring back exactly what was visible. |

> [!NOTE]
> Keys are ignored while you type in a text box or the chat. <kbd>V</kbd>, <kbd>R</kbd>, <kbd>L</kbd> and <kbd>K</kbd> need a keyboard; they have no touch buttons. You can change them in the `Config` table at the top of the script ([Configuration](../reference/configuration.md)).

> [!WARNING]
> ToolsGiver copies exist **on your client only**. Whether a copied tool does anything depends on the game; most games check tools on the server.

## Chat commands

| Command | What it does |
| --- | --- |
| `/e copier`, `/e hub`, `/copier`, `/hub` | Shows the window. (`/e dance1` and `/dance1` do too.) |
| `/e next` | Next avatar in the [cycle](../tabs/auto-cycle.md). |
| `/e prev` | Previous avatar in the cycle. |
| `/e cycle` | Turns the cycle on or off. |

`/e` commands go through Roblox's emote command, so they don't show up in the chat window.

> [!TIP]
> A message can reach the script through more than one chat event. The script acts on it once: the cycle commands are ignored when the same one arrived less than a second ago, and showing a window that is already open does nothing.

## Under the hood

| Part | Code | What it does |
| --- | --- | --- |
| The key handler | [the `InputBegan` handler](../../src/avatar-copier.lua#L1008-L1014 "RegisterConnection(UIS.InputBegan:Connect(function(input, processed)") | <kbd>L</kbd>, <kbd>K</kbd>, <kbd>R</kbd> and <kbd>V</kbd>, plus the arrow keys and right mouse button for the free camera. |
| Free camera | [`F.enableFreeCam`](../../src/avatar-copier.lua#L998-L1002), [`F.disableFreeCam`](../../src/avatar-copier.lua#L1004-L1006) | Anchors your root part, binds the `CopierFreeCam` render step, gives the camera back. |
| Hide interface | [`F.ToggleUI`](../../src/avatar-copier.lua#L216-L239) | Remembers which interfaces were on and restores exactly those. |
| ToolsGiver | [`F.startToolsGiverLoop`](../../src/avatar-copier.lua#L244), [the toggle](../../src/avatar-copier.lua#L2973 "ToolsGiver enabled.") | The 1.5 s scan, and the on/off switch with its status message. |
| Window key and chat | [`UI.inputs`](../../src/avatar-copier.lua#L5805-L5854) | The hub shortcut, the key capture in Settings and every chat command. |

### One function reads every chat message

```lua excerpt
    local function chat(message)
        local normalized=message:lower():gsub("%s+","")
        if normalized=="/ecopier" or normalized=="/ehub" or normalized=="/copier" or normalized=="/hub" or normalized=="/edance1" or normalized=="/dance1" then
            UI.Minimized=false; UI.setVisible(true); UI.layout(false); App.report("Hub opened.","info")
            return
        end
        -- The same message can arrive through more than one chat event; act on it once.
        local command=normalized:gsub("^/e","/")
        if command~="/next" and command~="/prev" and command~="/cycle" then return end
        if UI.LastChatCommand==command and os.clock()-(UI.LastChatAt or 0)<1 then return end
```

It is connected to the old chat (`Player.Chatted`), the new chat (`TextChatService.MessageReceived`), Roblox's emote command and a `TextChatCommand` named `LyraCopierCommand` for `/copier` and `/hub`.

### Hiding the interface remembers what was visible

```lua excerpt
            for _, gui in ipairs(pg:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Name ~= "CopierHubGUI" and gui.Name ~= "TouchGui" then
                    HiddenGuis[gui] = gui.Enabled
                    gui.Enabled = false
                end
            end
```

### Roblox APIs and executor functions used

| Name | Used for |
| --- | --- |
| `UserInputService.InputBegan`, `InputEnded`, `InputChanged` | Keys, mouse and touch |
| `RunService:BindToRenderStep` | Moving the free camera every frame |
| `StarterGui:SetCoreGuiEnabled` | Hiding Roblox's interface |
| `Player.Chatted`, `TextChatService`, `TextChatCommand` | Chat commands |
| `firetouchinterest` (executor, optional) | ToolsGiver touching tools lying in the workspace |

---

| ← Previous | Up | Next → |
| :--- | :---: | ---: |
| [The window](window.md) | [All docs](../README.md) | [Skin sync](skin-sync.md) |
