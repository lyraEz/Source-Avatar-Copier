[Docs](../README.md) / Features / **The window**

# <img src="../assets/icons/window.png" width="40" alt=""> The window

How to move, resize, hide and bring back the Avatar Studio window, and what each part of it is.

![Map of the Avatar Studio window](../assets/window.svg)

| # | Part | What it does |
| :-: | --- | --- |
| 1 | **Header** | Drag it to move the window. |
| 2 | **Minimize, maximize, close** | Minimize leaves only the header. Maximize fills the screen. Close **hides** the window (the script keeps running). |
| 3 | **Side menu** | The eight [tabs](../README.md#the-tabs). |
| 4 | **Page** | The selected tab. |
| 5 | **Status line** | The latest message. Its dot is green for success, gold for a warning, red for an error. |
| 6 | **Resize grip** | Drag it to change the window size. The size is saved. |
| 7 | **Floating button** | Shown while the window is hidden. Tap it to bring the window back, or drag it out of the way. |

> [!NOTE]
> The map shows the default window on a computer (820 × 600 at 100%). The real window uses the logo image and your interface size.

## On phones and small windows

The side menu changes with the width of the window:

| Window width | Side menu |
| --- | --- |
| 760 or more | Icons and names |
| 520 to 759 | Icons only |
| Under 520 | Hidden. The **menu** button in the header opens it as a drawer. |

On screens smaller than 500 pixels the window takes the full height, and **Auto** interface size is a little smaller.

## Hiding and reopening

Tap **close** (the X) to hide the window. To bring it back:

| Way | Works when |
| --- | --- |
| **Floating button** | [Floating button](../tabs/settings.md#open--close) is on (the default). |
| **Hub shortcut** (<kbd>RightControl</kbd>) | You have a keyboard. Pressing it again hides the window. |
| `/e copier` (or `/e hub`, `/copier`, `/hub`) in chat | Roblox lets your account chat. |
| Open and close the Roblox menu **3 times within 5 seconds** | [Reopen with the Roblox menu](../tabs/settings.md#open--close) is on (the default). |

The **How to reopen the window** card in [Settings](../tabs/settings.md) shows, live, which of these work on your device.

> [!IMPORTANT]
> The script never lets you lock yourself out. With the floating button off:
> - the first time you hide the window it tells you how to get it back, and asks to confirm;
> - if **nothing** could reopen it (no keyboard, no chat, menu shortcut off), it offers to turn the menu shortcut on before hiding;
> - **Start hidden** is skipped when nothing could reopen the window.

When the Roblox menu shortcut reopens the window, a notification says so and offers **Turn off shortcut**, in case it happened by accident.

## Notifications and dialogs

- **Notifications** slide in at the bottom-right corner, at most 4 at a time. A line under each one shows the time left. Tap one to close it. **Show notifications** in [Settings](../tabs/settings.md) turns them all off.
- **Dialogs** ask before anything that deletes data (removing a favorite, clearing a list, deleting a skin). Some count down and cancel themselves.

## Under the hood

| Part | Code | What it does |
| --- | --- | --- |
| Building the window | [`UI.buildShell`](../../src/avatar-copier.lua#L3476-L3544) | The `ScreenGui`, header, buttons, side menu, status line, floating button and blur. |
| Layout | [`UI.layout`](../../src/avatar-copier.lua#L3582-L3687) | Sizes everything from the screen, the interface size and the saved window size. |
| Interface size | [`UI.scale`](../../src/avatar-copier.lua#L3576-L3581) | The `UIScale` value. |
| Moving | [`UI.drag`](../../src/avatar-copier.lua#L3545-L3573) | Dragging the header and the floating button, kept inside the screen. |
| Resizing | [`UI.buildResizeGrip`](../../src/avatar-copier.lua#L3717-L3763) | The grip and the "820 × 600" badge while you drag. |
| Switching tabs | [`UI.selectTab`](../../src/avatar-copier.lua#L3901-L3911) | Shows one page and refreshes it. |
| Show / hide | [`UI.setVisible`](../../src/avatar-copier.lua#L3843-L3900) | The flight to and from the floating button. Calling it twice does nothing. |
| Close button | [`UI.closeHub`](../../src/avatar-copier.lua#L3806-L3824) | The lock-out checks described above. |
| Reopen methods | [`UI.reopenMethods`](../../src/avatar-copier.lua#L3780-L3786), [`UI.canReopen`](../../src/avatar-copier.lua#L3787) | Which ways back work right now. |
| Menu shortcut | [`UI.watchMenu`](../../src/avatar-copier.lua#L5443-L5461), [`UI.menuReopen`](../../src/avatar-copier.lua#L5431-L5442) | Counts menu open/close pairs while hidden. |
| Blur and glass | [`UI.effects`](../../src/avatar-copier.lua#L3764-L3769) | Background blur, transparency, floating button visibility. |
| Status line | [the status handler](../../src/avatar-copier.lua#L6097 "App.Notify=function(message,kind)") | Colours the dot and text by message kind. |
| Notifications | [`Toast.new`](../../src/avatar-copier.lua#L2651-L2677), [`Toast:Notify`](../../src/avatar-copier.lua#L2713-L2816) | A self-contained component; its options are in [Development](../reference/development.md#toast-notifier). |
| Dialogs | [`UI.buildModal`](../../src/avatar-copier.lua#L5234-L5243), [`UI.confirm`](../../src/avatar-copier.lua#L5245-L5260) | Title, text, Cancel and Confirm, with an optional countdown. |

### The side menu follows the window width

```lua excerpt
    UI.Narrow=w<520
    local rail=not UI.Narrow and (w<760 and 60 or 196) or 0
```

### The menu shortcut only counts while the window is hidden

```lua excerpt
    -- A close only counts when its open was seen while the window was hidden and the shortcut was on.
    UI.connect(GuiService.MenuClosed,function()
        local opened=openedAt; openedAt=nil
        if not opened or UI.Visible or not Store.Settings.MenuReopen then table.clear(stamps); return end
        local now=os.clock()
        table.insert(stamps,now)
        while #stamps>0 and now-stamps[1]>5 do table.remove(stamps,1) end
        if #stamps>=3 then table.clear(stamps); UI.menuReopen() end
    end)
```

### Roblox APIs used

| API | Used for |
| --- | --- |
| `ScreenGui`, `Frame`, `CanvasGroup`, `UIScale`, `UICorner`, `UIStroke`, `UIGradient` | The window itself |
| `BlurEffect` in `Lighting` | The background blur |
| `TweenService` | Every animation |
| `GuiService.MenuOpened`, `MenuClosed` | The menu shortcut |
| `UserInputService` | Dragging, resizing and the shortcut key |

---

| ← Previous | Up | Next → |
| :--- | :---: | ---: |
| [Creator](../tabs/creator.md) | [All docs](../README.md) | [Hotkeys and chat](hotkeys-and-chat.md) |
