--[[
    Drives Avatar Copier through tests/mock.lua: the hub, its settings and saved data, skins, the catalog,
    the avatar cycle, skin sync, avatar application on a stand-in character, and cleanup.
    Fails on any error raised inside the script, its tasks or its callbacks.

    This checks the script's own logic against a stand-in of the Roblox API. It does not replace a test
    inside a real game: rendering, physics, replication and game-specific rigs are not simulated.
]]
local checks = 0
local function check(condition, message)
    checks = checks + 1
    if not condition then error("CHECK FAILED: " .. message, 2) end
end
local function settle(seconds) task.wait(seconds or 0.6) end
local SAVE = "Copier_SavedProfiles.json"
local function saved() return Mock.jsonDecode(Mock.Files[SAVE]) end
local function scriptWarnings()
    local list = {}
    for _, line in ipairs(Mock.Warnings) do
        if line:find("[Lyra", 1, true) or line:find("[Copier", 1, true) then table.insert(list, line) end
    end
    return list
end
-- Removes the warnings a step was expected to log; fails when none matched.
local function expectWarning(text)
    local found = false
    for i = #Mock.Warnings, 1, -1 do
        if Mock.Warnings[i]:find(text, 1, true) then table.remove(Mock.Warnings, i); found = true end
    end
    if not found then error("CHECK FAILED: expected a warning containing " .. text, 2) end
    checks = checks + 1
end
local function find(root, text) return Mock.findText(root, text, true) end
-- The toggle switch of a settings card, found by the card's title.
local function toggleOf(page, title)
    for _, label in ipairs(page:GetDescendants()) do
        if label:IsA("TextLabel") and label.Text == title then
            for _, child in ipairs(label.Parent:GetChildren()) do if child:IsA("TextButton") then return child end end
        end
    end
    error("no setting with a switch titled " .. title)
end
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local H
local finished = false
task.spawn(function()
    -- Boot --------------------------------------------------------------------------------------------
    H = Mock.Run()
    settle()
    local UI, App, Store = H.UI, H.App, H.Store
    check(UI.Gui and UI.Gui.Parent == Mock.PlayerGui, "the hub is parented to PlayerGui")
    check(UI.Visible and UI.Main.Visible, "the window opens on start")
    check(type(UI.IconSheet) == "string" and UI.IconSheet:find("LyraAvatarStudio_icons_v14_7.png", 1, true), "the embedded icon sheet decodes")
    check(type(UI.LogoImage) == "string", "the embedded logo decodes")
    check(game:GetService("Lighting"):FindFirstChild("CopierLiquidBlur") ~= nil, "background blur is created")
    check(game:GetService("TextChatService"):FindFirstChild("LyraCopierCommand") ~= nil, "the /copier chat command is registered")
    check(Mock.Files[SAVE] ~= nil and saved().Promo.Runs == 1, "the run counter is saved on start")
    check(#Mock.Requests == 0, "nothing is requested before a server JobId exists")
    check(UI.HeaderSubtitle.Text:find("v25.0.1", 1, true) ~= nil, "the header shows the version")

    -- Every tab opens ---------------------------------------------------------------------------------
    for _, name in ipairs({"Avatar", "Players", "Collection", "Looks", "Catalog", "Auto", "Settings", "Creator"}) do
        Mock.click(UI.NavButtons[name].Root)
        settle(0.4)
        check(UI.Tab == name and UI.Pages[name].Visible, "tab " .. name .. " opens")
    end
    local photo = false
    for _, req in ipairs(Mock.Requests) do if req.Url == "https://github.com/lyraEz.png?size=256" then photo = true end end
    check(photo and UI.CreatorPhoto.Image == "", "the creator photo is requested once and the initial stays when it fails")
    check(UI.CatalogCount > 0, "opening the shop runs a first search")
    Mock.click(UI.NavButtons.Players.Root); settle(0.4)
    check(find(UI.PlayerList, "Lyra Tester") ~= nil and UI.PlayerCount.Text == "Showing 1 of 1 players", "the server list shows the local player")

    -- Profile search and preview ----------------------------------------------------------------------
    Mock.click(UI.NavButtons.Avatar.Root); settle(0.3)
    Mock.type(UI.SearchBox, "a", true); settle(1)
    check(UI.StatusText.Text == "Enter a valid username or numeric user ID.", "short names are rejected")
    expectWarning("Enter a valid username")
    Mock.type(UI.SearchBox, "NoSuchUser123", true); settle(1)
    check(UI.StatusText.Text:find("User not found", 1, true) ~= nil, "unknown users report an error")
    expectWarning("User not found")
    Mock.type(UI.SearchBox, "@Builderman", true); settle(2)
    check(App.Preview and App.Preview.Id == 156, "a profile resolves by username")
    check(UI.PreviewModel and UI.PreviewModel.Parent == UI.World and UI.Viewport.Visible, "the 3D preview is built")
    check(UI.RigText.Text == "PREVIEW IN R15", "the preview uses R15 without a character")
    check(Store.Recent[1] and Store.Recent[1].Id == 156 and saved().Recent[1].Id == 156, "previewed profiles go to Recent and are saved")
    Mock.click(UI.Favorite.Root); settle()
    check(Store.Favorites[1] and Store.Favorites[1].Id == 156 and saved().Favorites[1].Name == "Builderman", "Add favorite saves the profile")
    Mock.type(UI.SearchBox, "2207291", true); settle(2)
    check(App.Preview and App.Preview.Name == "Korbloxian", "a profile resolves by user id")
    Mock.click(UI.Apply.Root); settle()
    check(UI.StatusText.Text == "Wait for your character to load.", "apply waits for a character")

    -- Settings ----------------------------------------------------------------------------------------
    Mock.click(UI.NavButtons.Settings.Root); settle(0.3)
    local settings = UI.Pages.Settings
    Mock.click(Mock.button(settings, "Show advanced options")); settle(0.2)
    local toggles = {
        {"Copy animations", "CopyAnims"}, {"Keep avatar after respawn", "AutoReapply"}, {"See other script users' skins", "SkinSync"},
        {"Show notifications", "Notifications"}, {"Start hidden", "StartHidden"}, {"Floating button", "MobileOrb"},
        {"Reopen with the Roblox menu", "MenuReopen"}, {"Keep avatar between rounds", "MapPersist"}, {"Reset character first", "AutoReset"},
        {"Visual-only avatar", "VisualOnly"}, {"Glow when avatar changes", "SwapEffect"}, {"Show my avatar in the Roblox menu", "MenuAvatar"},
        {"Background blur", "GlassBlur"}, {"Reduced motion", "ReducedMotion"}, {"Performance mode", "LowEffects"},
    }
    for _, row in ipairs(toggles) do
        local before = Store.Settings[row[2]]
        Mock.click(toggleOf(settings, row[1])); settle(0.2)
        check(Store.Settings[row[2]] == not before and saved().Settings[row[2]] == not before, row[1] .. " switches and is saved")
        Mock.click(toggleOf(settings, row[1])); settle(0.2)
        check(Store.Settings[row[2]] == before and saved().Settings[row[2]] == before, row[1] .. " switches back")
    end
    local sizeCard = find(settings, "Interface size").Parent
    local plus
    for _, item in ipairs(sizeCard:GetDescendants()) do if item:IsA("TextButton") then plus = item end end
    Mock.click(plus); settle()
    check(Store.Settings.UIScale == 90 and UI.WindowScale.Scale == 0.9, "the interface size steps up and scales the window")
    Mock.click(Mock.button(settings, "Reset")); settle()
    check(Store.Settings.UIScale == 85 and Store.Settings.WindowW == 0 and UI.WindowScale.Scale == 0.85, "Reset restores the window size")
    Mock.click(Mock.button(settings, "RightControl"))
    check(UI.CapturingKey, "the shortcut waits for a key")
    Mock.key("H"); settle(0.2)
    check(Store.Settings.Keybind == "H" and saved().Settings.Keybind == "H", "a new shortcut is saved")
    Mock.click(Mock.button(settings, "H"))
    Mock.key("V"); settle(0.2)
    check(Store.Settings.Keybind == "H" and UI.StatusText.Text:find("already used", 1, true), "keys used by the hotkeys are refused")
    Mock.key("H"); settle(1)
    check(not UI.Visible and not UI.Main.Visible, "the shortcut hides the window")
    Mock.key("H"); settle(1)
    check(UI.Visible and UI.Main.Visible, "the shortcut shows the window again")

    -- Hiding and the ways back ------------------------------------------------------------------------
    Store.Settings.HideTipSeen = false
    Store.Settings.MobileOrb = false
    Mock.click(Mock.button(UI.Header, "") ) -- the first header button is the close button
    settle(0.2)
    check(UI.Modal.Visible and UI.ModalTitle.Text == "Hide Avatar Studio?", "hiding without the floating button asks first")
    Mock.click(UI.ModalConfirm.Root); settle(1)
    check(not UI.Visible and Store.Settings.HideTipSeen, "confirming hides the window")
    for _ = 1, 3 do GuiService.MenuOpened:Fire(); settle(0.2); GuiService.MenuClosed:Fire(); settle(0.2) end
    settle(0.6)
    check(UI.Visible, "opening the Roblox menu 3 times reopens the window")
    check(UI.Toasts.Active[#UI.Toasts.Active] ~= nil, "the menu shortcut explains itself with a toast")
    UI.hide(); settle(1)
    Mock.Player.Chatted:Fire("/e copier"); settle(1)
    check(UI.Visible, "/e copier reopens the window")
    UI.hide(); settle(1)
    Mock.EmoteCommand.Triggered:Fire(nil, "/e copier"); settle(1)
    check(UI.Visible, "the emote command path reopens the window")
    Store.Settings.MobileOrb = true; App.persist()
    UI.hide(); settle(1)
    check(UI.Orb.Visible and not UI.Main.Visible, "the floating button shows while hidden")
    Mock.click(UI.Orb); settle(1)
    check(UI.Visible and UI.Main.Visible, "the floating button reopens the window")


    -- Skins: codec, share codes, old JSON and the library --------------------------------------------
    local Codec, Looks = H.Codec, H.Looks
    local builder = Mock.describe(Mock.Users[2])
    local data = Codec.encode(builder)
    check(data.Version == 2 and data.Properties.Face == 7699174 and #data.Accessories == 2 and data.Emotes.Wave[1] == 3576686446, "a description encodes")
    local decoded = Codec.decode(data)
    check(decoded.Face == 7699174 and #decoded:GetAccessories(true) == 2 and decoded:GetEmotes().Wave ~= nil and decoded:GetEquippedEmotes()[1].Name == "Wave",
        "an encoded description decodes back")
    check(not pcall(Codec.decode, {Version = 3, Properties = {Face = 1}}), "unknown codec versions are refused")
    check(not pcall(Codec.decode, {Version = 2, Properties = {}}), "empty avatar data is refused")
    check(Codec.decode({Face = 7699174, Shirt = 1}).Face == 7699174, "old flat tables still decode")
    local odd = Codec.decode({Version = 2, Properties = {Face = 12, HeadScale = 99, HatAccessory = "12,abc"}, Colors = {HeadColor = {2, 0, 0}}})
    check(odd.HeadScale == 1 and odd.HatAccessory == "" and odd.HeadColor == Color3.new(1, 1, 1), "out-of-range values are ignored")
    local many = {Version = 2, Properties = {Face = 1}, Colors = {}, HasAccessories = true, Accessories = {}}
    for i = 1, 200 do many.Accessories[i] = {AssetId = i, AccessoryType = "Hat", IsLayered = false} end
    check(#Codec.decode(many):GetAccessories(true) == 150, "at most 150 accessories are read")

    Mock.click(UI.NavButtons.Looks.Root); settle(0.3)
    local looksPage = UI.Pages.Looks
    local code = Looks.share({Name = "Builder look", Data = data})
    check(code:sub(1, 6) == "LYRA3:", "share codes start with LYRA3:")
    Mock.type(UI.ImportBox, code, false)
    Mock.click(Mock.button(looksPage, "Import code / JSON")); settle(2)
    check(#Store.Looks == 1 and Store.Looks[1].Name == "Builder look" and Store.Looks[1].Source == "Shared code", "a share code imports into the library")
    check(saved().Looks[1].Name == "Builder look" and UI.ImportBox.Text == "", "imported skins are saved")
    check(Mock.count(UI.LookList, "ViewportFrame") == 1 and Mock.count(UI.LookList, "Model") == 1, "the skin gets a rendered thumbnail")
    local legacy = '{"RigType":"R15","MembrosCorpo":{"Head":{"Size":[1.2,1.2,1.2],"Color":[1,0.8,0.6],"MeshId":"rbxassetid://123","TextureId":""}},'
        .. '"Acessorios":[{"Nome":"Cap","Size":[1,1,1],"Color":[1,0,0],"MeshId":"rbxassetid://456","AttachmentName":"HatAttachment",'
        .. '"AttachmentCFrame":[0,0,0,1,0,0,0,1,0,0,0,1],"Scale":[1.1,1,1]}],"Roupas":{"Shirt":"rbxassetid://1"}}'
    Mock.type(UI.LookName, "Old one", false)
    Mock.type(UI.ImportBox, legacy, false)
    Mock.click(Mock.button(looksPage, "Import code / JSON")); settle(2)
    check(#Store.Looks == 2 and Store.Looks[1].Name == "Old one" and Store.Looks[1].Data.Visual.Legacy, "old JSON backups import")
    check(Store.Looks[1].Source == "Old JSON · estimated attachments", "old JSON imports are labelled")
    check(Mock.count(UI.LookList, "ViewportFrame") == 2, "the old skin renders a thumbnail too")
    Mock.type(UI.LookName, "", false)
    Mock.type(UI.ImportBox, "LYRA3:{broken", false)
    Mock.click(Mock.button(looksPage, "Import code / JSON")); settle()
    check(#Store.Looks == 2 and UI.StatusText.Text:find("Paste a LYRA code or the full contents of the old JSON.", 1, true), "broken codes are refused")
    expectWarning("Paste a LYRA code")
    local huge = Looks.share({Name = "Huge", Data = {Version = 2, Properties = {Face = 1}, Colors = {}, Accessories = {}, HasAccessories = true,
        Visual = {Version = 1, RigType = "R15", Accessories = {}, Body = {Head = {Class = "MeshPart", Size = {500, 1, 1}, Color = {1, 1, 1}, Transparency = 0, MeshId = "rbxassetid://1"}}}}})
    Mock.type(UI.ImportBox, huge, false)
    Mock.click(Mock.button(looksPage, "Import code / JSON")); settle()
    check(#Store.Looks == 2 and UI.StatusText.Text:find("Invalid dimensions", 1, true), "oversized parts are refused")
    expectWarning("Invalid dimensions")
    local scripted = Looks.share({Name = "Scripted", Data = {Version = 2, Properties = {Face = 1}, Colors = {}, Accessories = {}, HasAccessories = true,
        Visual = {Version = 1, RigType = "R15", Accessories = {}, Body = {Head = {Class = "MeshPart", Size = {1, 1, 1}, Color = {1, 1, 1}, Transparency = 0,
            MeshId = "rbxassetid://1", Nodes = {{Class = "LocalScript", Name = "Evil", Properties = {}, Children = {}}}}}}}})
    Mock.type(UI.ImportBox, scripted, false)
    Mock.click(Mock.button(looksPage, "Import code / JSON")); settle()
    check(#Store.Looks == 2 and UI.StatusText.Text:find("Invalid visual node.", 1, true), "classes outside the skin schema are refused")
    expectWarning("Invalid visual node")

    UI.SelectedLook = Store.Looks[2].Key; UI.renderLooks(); settle(0.3)
    local nameBox
    for _, item in ipairs(UI.LookList:GetDescendants()) do if item:IsA("TextBox") and item.Text == "Builder look" then nameBox = item end end
    Mock.type(nameBox, "Renamed", false)
    Mock.click(Mock.button(UI.LookList, "Rename")); settle()
    check(Store.Looks[2].Name == "Renamed" and saved().Looks[2].Name == "Renamed", "Rename renames and saves")
    Mock.click(Mock.button(UI.LookList, "Share")); settle()
    check(type(Mock.Clipboard) == "string" and Mock.Clipboard:sub(1, 6) == "LYRA3:" and UI.ExportBox.Text == Mock.Clipboard, "Share copies the code")
    Mock.click(Mock.button(UI.LookList, "Cycle")); settle()
    check(#Store.Auto.List == 1 and Store.Auto.List[1].Kind == "Look", "a skin can join the avatar cycle")
    Mock.click(Mock.button(UI.LookList, "Copy")); settle()
    check(#Store.Looks == 3 and Store.Looks[1].Name == "Renamed copy" and UI.SelectedLook == Store.Looks[1].Key, "Copy duplicates the skin")
    Mock.click(Mock.button(UI.LookList, "Delete")); settle(0.2)
    check(UI.Modal.Visible and UI.ModalTitle.Text == "Delete skin?", "Delete asks first")
    Mock.click(UI.ModalConfirm.Root); settle()
    check(#Store.Looks == 2 and Store.Looks[1].Name == "Old one", "Delete removes the skin")
    Mock.type(UI.LookSearch, "renam", false); settle()
    check(find(UI.LookList, "Renamed") ~= nil and find(UI.LookList, "Old one") == nil, "the library search filters skins")
    Mock.type(UI.LookSearch, "", false); settle()

    -- Roblox Shop ---------------------------------------------------------------------------------------
    local Catalog = H.Catalog
    local id, kind = Catalog.idFrom("https://www.roblox.com/catalog/1028606/Red-Baseball-Cap")
    check(id == 1028606 and kind == "Asset", "catalog links give the item id")
    id, kind = Catalog.idFrom("roblox.com/bundles/192/Korblox")
    check(id == 192 and kind == "Bundle", "bundle links give the bundle id")
    id, kind = Catalog.idFrom("#123")
    check(id == 123 and kind == nil, "a bare number is an id of unknown kind")
    check(Catalog.idFrom("korblox") == nil, "words are not ids")
    local free = Catalog.option(Catalog.Prices, "Free")
    check(Catalog.priced({Price = 0}, free) and not Catalog.priced({Price = 5}, free) and not Catalog.priced({}, free), "the Free price filter")
    check(not Catalog.priced({Price = 10, OffSale = true}, Catalog.option(Catalog.Prices, "ForSale")), "For sale hides off-sale items")

    Mock.click(UI.NavButtons.Catalog.Root); settle(0.5)
    Mock.type(UI.CatalogBox, "1028606", true); settle(1)
    check(UI.CatalogCount == 1 and find(UI.CatalogGrid, "Red Baseball Cap") ~= nil, "an item id finds that exact item")
    Mock.type(UI.CatalogBox, "korblox", true); settle(1)
    check(find(UI.CatalogGrid, "Korblox Deathspeaker") ~= nil and find(UI.CatalogGrid, "BUNDLE") ~= nil, "searches list bundles")
    Mock.click(Mock.button(UI.CatalogGrid, "View parts")); settle(1)
    local bundle = UI.CatalogBundleData
    check(bundle and #bundle.Parts == 2 and bundle.Parts[1].Kind.Name == "LeftArm" and bundle.Parts[2].Kind.Name == "RightLeg",
        "bundle parts are listed body first, falling back to the part name")
    Mock.click(Mock.button(UI.CatalogBundleBody, "Back to results")); settle(0.3)
    check(UI.CatalogGrid.Visible and UI.CatalogBundleItem == nil, "Back returns to the results")
    Mock.type(UI.CatalogBox, "", false)
    Mock.click(UI.CatalogChips.Hats); settle(1)
    check(UI.CatalogCount == 2, "the Hats filter keeps hats only")
    Mock.click(UI.CatalogChips.Limiteds); settle(1)
    check(UI.CatalogCount == 2 and find(UI.CatalogGrid, "Red Sparkle Time Fedora") ~= nil, "the Limiteds filter keeps limited items")
    Mock.click(UI.CatalogChips.All); settle(1)
    Mock.CatalogSearchFails = true
    Mock.HttpGet = function(url)
        return Mock.jsonEncode({nextPageCursor = "", data = {{id = 1028606, name = "Red Baseball Cap", itemType = "Asset", assetType = 8, price = 75}}})
    end
    Mock.type(UI.CatalogBox, "cap", true); settle(1)
    check(UI.CatalogCount == 1 and Mock.HttpGets[#Mock.HttpGets]:find("^https://catalog%.roblox%.com/v1/search/items/details%?") ~= nil
        and Mock.HttpGets[#Mock.HttpGets]:find("Keyword=cap", 1, true) ~= nil, "the web catalog is the fallback when in-game search fails")
    expectWarning("In-game search unavailable")
    Mock.CatalogSearchFails = false; Mock.HttpGet = nil
    Mock.click(UI.CatWearTab.Root); settle(0.5)
    check(UI.CatalogWearView.Visible and find(UI.CatalogWearList, "No catalog items") ~= nil, "Wearing is empty without a character")
    Mock.click(UI.CatSearchTab.Root); settle(0.3)

    -- Avatar cycle order ----------------------------------------------------------------------------------
    local Auto = H.Auto
    local function entry(n) return Store.entry({Kind = "User", Id = n, Name = "User" .. n}) end
    Store.Auto.List = {entry(11), entry(12), entry(13)}
    Store.Auto.Order = "Sequential"; Store.Auto.EndAction = "Loop"; Store.Auto.Index = 0
    check(Auto.pick(1) == 1, "the cycle starts at the top")
    Store.Auto.Index = 3
    check(Auto.pick(1) == 1, "Start over loops")
    Store.Auto.EndAction = "Stop"; check(Auto.pick(1) == "stop", "Stay on last stops")
    Store.Auto.EndAction = "Restore"; check(Auto.pick(1) == "restore", "Restore mine restores")
    check(Auto.pick(-1) == 2, "Previous goes back")
    Store.Auto.Index = 1; check(Auto.pick(-1) == 3, "Previous wraps around")
    Store.Auto.Order = "PingPong"; Store.Auto.Index = 0
    local path = {}
    for _ = 1, 6 do local index = Auto.pick(1); table.insert(path, index); Store.Auto.Index = index end
    check(table.concat(path, ",") == "1,2,3,2,1,2", "Ping-pong goes back and forth")
    Store.Auto.Order = "Shuffle"; Store.Auto.Index = 2; table.clear(Auto.Bag)
    local seen, first = {}, nil
    for _ = 1, 3 do local index = Auto.pick(1); first = first or index; seen[index] = true; Store.Auto.Index = index end
    check(first ~= 2 and seen[1] and seen[2] and seen[3], "Shuffle wears everyone once and never starts with the current avatar")
    Store.Auto.Order = "Random"; Store.Auto.Index = 2
    local repeated = false
    for _ = 1, 30 do if Auto.pick(1) == 2 then repeated = true end end
    check(not repeated, "Random never picks the avatar being worn")
    Store.Auto.Index = 1
    Auto.move(1, 3)
    check(Store.Auto.List[3].Id == 11 and Store.Auto.Index == 3, "moving an entry keeps the current position on it")
    Store.Auto.Order = "Sequential"; Store.Auto.EndAction = "Loop"; Store.Auto.List = {}; Store.Auto.Index = 0; App.persist()
    Mock.Player.Chatted:Fire("/e cycle"); settle(0.3)
    check(Store.Auto.CycleEnabled and saved().Auto.CycleEnabled, "/e cycle turns the cycle on")
    Mock.Player.Chatted:Fire("/e cycle"); settle(0.3)
    check(Store.Auto.CycleEnabled, "the same command within a second counts once (it can arrive through two chat events)")
    settle(1)
    Mock.Player.Chatted:Fire("/e cycle"); settle(0.3)
    check(not Store.Auto.CycleEnabled, "/e cycle turns it off again")
    Mock.click(UI.NavButtons.Auto.Root); settle(0.3)
    Mock.click(Mock.button(UI.Pages.Auto, "Add favorites")); settle()
    check(#Store.Auto.List == 1 and Store.Auto.List[1].Id == 156 and UI.CycleCount.Text == "1/50 avatars in the cycle", "Add favorites fills the cycle")
    Store.Auto.List = {}; App.persist(); UI.renderAuto()

    -- Hotkeys ---------------------------------------------------------------------------------------------
    local StarterGui = game:GetService("StarterGui")
    local hud = Instance.new("ScreenGui"); hud.Name = "GameHud"; hud.Parent = Mock.PlayerGui
    Mock.key("K"); settle(0.2)
    check(not hud.Enabled and UI.Gui.Enabled and StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat) == false, "K hides the game's interface but not the hub")
    Mock.key("K"); settle(0.2)
    check(hud.Enabled and StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat) == true, "K brings it back")
    Mock.key("L"); settle(0.2)
    check(Mock.G.ToolsGiverActive == true and UI.StatusText.Text == "ToolsGiver enabled.", "L turns ToolsGiver on")
    Mock.key("L"); settle(1.6)
    check(Mock.G.ToolsGiverActive == false and UI.StatusText.Text == "ToolsGiver disabled.", "L turns it off")
    hud:Destroy()

    -- Skin sync -------------------------------------------------------------------------------------------
    local Sync, Overlay = H.Sync, H.Overlay
    check(Sync.Url == "https://sync.test/v1/sync" and H.Config.SyncUrl == Sync.Url, "the sync server comes from Config.SyncUrl")
    local friend = Mock.newInstance("Player", true)
    friend.Name = "Friend"; friend.UserId = 777; friend.DisplayName = "Friend"
    local friendCharacter = Mock.buildRig(Mock.describe(Mock.Users[3]), Enum.HumanoidRigType.R15)
    friendCharacter.Name = "Friend"; friendCharacter.Parent = Mock.Workspace; friend.Character = friendCharacter
    table.insert(Mock.OtherPlayers, friend)
    local peerSkin = Mock.jsonEncode({Version = 2, Data = data})
    local peerHash = Sync.hash(peerSkin)
    local syncLog = {}
    Mock.RequestHandler = function(req)
        if req.Url ~= Sync.Url then return {StatusCode = 404, Body = ""} end
        check(req.Method == "POST" and req.Headers["Content-Type"] == "application/json", "sync requests are JSON posts")
        local body = Mock.jsonDecode(req.Body)
        table.insert(syncLog, body)
        if body.a == "beat" then return {StatusCode = 200, Body = Mock.jsonEncode({ok = true, need = false, peers = {{user = 777, hash = peerHash}}})} end
        if body.a == "get" then return {StatusCode = 200, Body = Mock.jsonEncode({ok = true, hash = peerHash, data = peerSkin})} end
        return {StatusCode = 200, Body = '{"ok":true}'}
    end
    Mock.JobId = "6f0b2c4e-1a2b-4c3d-9e8f-001122334455"
    settle(5)
    local beat = syncLog[1]
    check(beat and beat.a == "beat" and beat.job == Mock.JobId and beat.user == 1 and beat.hash == "" and beat.data == nil,
        "a beat without an applied skin sends no skin data")
    local asked = false
    for _, body in ipairs(syncLog) do if body.a == "get" and body.peer == 777 then asked = true end end
    check(asked, "the other user's skin is fetched")
    local entry = Overlay.Active[friendCharacter]
    check(entry and entry.Mode == "joints" and entry.Model.Parent and entry.Model.Parent.Name == "LyraSkinOverlays"
        and entry.Model.Parent.Parent == Mock.Camera, "the other user's skin is drawn as a local overlay in the camera")
    check(friendCharacter.Head.LocalTransparencyModifier == 1 and friendCharacter.Head.Transparency == 0, "their real body is hidden locally only")
    friendCharacter.HumanoidRootPart.CFrame = CFrame.new(10, 0, 5)
    Mock.frame(); settle(0.1)
    check((entry.Model.HumanoidRootPart.CFrame.Position - Vector3.new(10, 0, 5)).Magnitude < 3, "the overlay follows the character")
    local bad = Mock.jsonEncode({Version = 2, Data = {Version = 2, Properties = {Face = 1}, Colors = {}, Accessories = {}, HasAccessories = true,
        Visual = {Version = 1, RigType = "R15", Accessories = {}, Body = {Head = {Class = "Script"}}}}})
    peerSkin, peerHash = bad, Sync.hash(bad)
    settle(10)
    check(Sync.Shown[777] and Sync.Shown[777].Hash == peerHash and Sync.Shown[777].Data == nil, "an invalid skin from another user is refused")
    Mock.click(UI.NavButtons.Settings.Root); settle(0.3)
    local before = #syncLog
    Mock.click(toggleOf(UI.Pages.Settings, "See other script users' skins")); settle(1)
    check(syncLog[#syncLog].a == "leave" and #syncLog == before + 1, "turning skin sync off says goodbye to the server")
    check(Overlay.Active[friendCharacter] == nil and friendCharacter.Head.LocalTransparencyModifier == 0, "turning it off removes the overlays")
    Sync.Url = ""
    Mock.click(toggleOf(UI.Pages.Settings, "See other script users' skins")); settle(10)
    check(#syncLog == before + 1 and not Sync.enabled(), "an empty sync URL turns skin sync off")
    Sync.Url = H.Config.SyncUrl


    -- Applying avatars to a character -----------------------------------------------------------------
    local Rig = H.Rig
    local function gameObjects(model)
        local tool = Instance.new("Tool"); tool.Name = "Knife"
        local knife = Instance.new("Part"); knife.Name = "Handle"; knife.Parent = tool; tool.Parent = model
        local grip = Instance.new("Weld"); grip.Name = "RightGrip"; grip.Part0 = model.RightHand; grip.Part1 = knife; grip.C0 = CFrame.new(0, -0.15, 0); grip.Parent = model.RightHand
        local holster = Instance.new("Accessory"); holster.Name = "GunHolster"
        local holsterHandle = Instance.new("Part"); holsterHandle.Name = "Handle"; holsterHandle.Parent = holster
        Instance.new("Script").Parent = holster
        local holsterWeld = Instance.new("Weld"); holsterWeld.Part0 = holsterHandle; holsterWeld.Part1 = model.LowerTorso; holsterWeld.Parent = holsterHandle
        holster.Parent = model
        local belt = Instance.new("Attachment"); belt.Name = "GunBelt"; belt.Position = Vector3.new(1.2, 0, 0); belt.Parent = model.LowerTorso
        Instance.new("ParticleEmitter").Parent = belt
        local tag = Instance.new("BillboardGui"); tag.Name = "NameTag"; tag.Adornee = model.Head; tag.Parent = model.Head
        local folder = Instance.new("Folder"); folder.Name = "GameData"; folder.Parent = model
    end
    local function copiedAccessories(model)
        local list = {}
        for _, item in ipairs(model:GetChildren()) do if item:IsA("Accessory") and item:GetAttribute("Copier_CopiedItem") then table.insert(list, item) end end
        return list
    end
    local function rigConnected(model)
        local known = Rig.reachable(model, false)
        for _, part in ipairs(model:GetChildren()) do
            if part:IsA("BasePart") and H.S.BD[part.Name] and not known[part] then return false, part.Name end
        end
        return true
    end
    local function gameObjectsIntact(model, label)
        local knife = model:FindFirstChild("Knife")
        check(knife and model.RightHand:FindFirstChild("RightGrip") and model.RightHand.RightGrip.Part1 == knife.Handle
            and model.RightHand.RightGrip.Part0 == model.RightHand, label .. ": the tool and its grip weld survive")
        local holster = model:FindFirstChild("GunHolster")
        check(holster and holster.Handle:FindFirstChildOfClass("Weld").Part1 == model.LowerTorso, label .. ": a scripted game accessory stays welded")
        local belt = model.LowerTorso:FindFirstChild("GunBelt")
        check(belt and belt:FindFirstChildOfClass("ParticleEmitter") ~= nil, label .. ": the game's belt attachment keeps its effect")
        check(model.Head:FindFirstChild("NameTag") and model.Head.NameTag.Adornee == model.Head, label .. ": the name tag stays on the head")
        check(model:FindFirstChild("GameData") ~= nil, label .. ": game folders stay")
        local connected, missing = rigConnected(model)
        check(connected, label .. ": every body part is still jointed (" .. tostring(missing) .. ")")
        check(Mock.Camera:FindFirstChild("Lyra_PreservedObjects") == nil, label .. ": the transaction holder is removed")
    end

    local character = Mock.spawnCharacter(Enum.HumanoidRigType.R15, gameObjects)
    settle(3)
    Mock.click(UI.NavButtons.Avatar.Root); settle(0.3)
    Mock.type(UI.SearchBox, "Builderman", true); settle(2)
    Mock.click(UI.Apply.Root); settle(3)
    check(App.Current and App.Current.Id == 156 and UI.StatusText.Text:find("Avatar applied", 1, true), "Apply avatar applies the previewed profile")
    check(App.Initial and App.Initial.Original and App.History[1] == App.Initial, "the initial appearance is captured first")
    local hum = character.Humanoid
    check(hum:FindFirstChildOfClass("HumanoidDescription").Face == 7699174, "the applied description is kept on the Humanoid")
    local copied = copiedAccessories(character)
    check(#copied == 2, "the profile's accessories are added")
    for _, accessory in ipairs(copied) do
        local weld = accessory.Handle:FindFirstChild("AccessoryWeld")
        check(weld and weld.Part0 == accessory.Handle and weld.Part1.Parent == character, "copied accessories are welded to the body")
    end
    check(character:FindFirstChildOfClass("Shirt").ShirtTemplate == "rbxassetid://1", "clothing is applied")
    gameObjectsIntact(character, "apply")
    check(hum.AutomaticScalingEnabled == false and hum:GetAttribute("Lyra_OriginalAutomaticScaling") == true, "automatic scaling is paused while an avatar is worn")
    check(Mock.Camera:FindFirstChild("LyraSwapGlow") == nil, "the swap glow is cleaned up")
    check(Store.Recent[1].Id == 156, "worn profiles move to the top of Recent")

    Mock.type(UI.SearchBox, "Korbloxian", true); settle(2)
    Mock.click(UI.Apply.Root); settle(3)
    check(App.Current.Id == 2207291 and character.RightUpperLeg.MeshId == "rbxassetid://139607718", "a custom body part replaces the mesh in place")
    check(#copiedAccessories(character) == 1 and character:FindFirstChild("Accessory1028606") == nil, "the previous avatar's items are removed")
    gameObjectsIntact(character, "second apply")
    check(#App.History == 2, "each apply adds to the timeline")
    Mock.click(UI.Undo.Root); settle(3)
    check(App.Current.Id == 156 and #copiedAccessories(character) == 2 and character.RightUpperLeg.MeshId ~= "rbxassetid://139607718", "Undo goes back one avatar")
    gameObjectsIntact(character, "undo")

    -- Respawn keeps the avatar.
    character = Mock.spawnCharacter(Enum.HumanoidRigType.R15, gameObjects)
    settle(4)
    check(UI.StatusText.Text == "Avatar reapplied." and #copiedAccessories(character) == 2, "the avatar is reapplied after a respawn")
    gameObjectsIntact(character, "respawn")

    -- Items the game removes come back, but not forever.
    local key = copiedAccessories(character)[1]:GetAttribute("Lyra_ItemKey")
    copiedAccessories(character)[1]:Destroy(); settle(1.5)
    local back = false
    for _, item in ipairs(copiedAccessories(character)) do if item:GetAttribute("Lyra_ItemKey") == key then back = true end end
    check(back, "a removed accessory is put back")
    for _ = 1, 3 do
        for _, item in ipairs(copiedAccessories(character)) do if item:GetAttribute("Lyra_ItemKey") == key then item:Destroy() end end
        settle(1.5)
    end
    check(UI.StatusText.Text:find("keeps removing", 1, true) ~= nil, "repeated removals stop the recovery")

    -- Shop edits on the worn avatar.
    Mock.click(UI.NavButtons.Catalog.Root); settle(0.5)
    Mock.type(UI.CatalogBox, "fedora", true); settle(1)
    Mock.click(Mock.button(UI.CatalogGrid, "Add")); settle(4)
    check(App.Current.Catalog and App.Current.Change.Text == "Added Red Sparkle Time Fedora" and character:FindFirstChild("Accessory48474313") ~= nil,
        "Add puts a catalog item on the worn avatar")
    check(find(UI.CatalogGrid, "Remove") ~= nil and UI.CatalogUndo.Visible, "the card turns into Remove and the undo bar shows the change")
    Mock.type(UI.CatalogBox, "hello", true); settle(1)
    Mock.click(Mock.button(UI.CatalogGrid, "Add")); settle(4)
    check(Mock.PlayedEmote == "Hello" and character.Humanoid:FindFirstChildOfClass("HumanoidDescription"):GetEmotes().Hello ~= nil, "an added emote is equipped and played once")
    Mock.click(UI.CatWearTab.Root); settle(1)
    check(find(UI.CatalogWearList, "ID 48474313") ~= nil or find(UI.CatalogWearList, "Red Sparkle Time Fedora") ~= nil, "Wearing lists the items on the avatar")
    Mock.click(UI.CatalogUndoButton.Root); settle(4)
    check(character:FindFirstChild("Accessory48474313") ~= nil and character.Humanoid:FindFirstChildOfClass("HumanoidDescription"):GetEmotes().Hello == nil,
        "the undo bar removes the last change")
    Mock.click(UI.CatSearchTab.Root); settle(0.3)

    -- Saving the worn skin.
    Mock.click(UI.NavButtons.Looks.Root); settle(0.3)
    Mock.type(UI.LookName, "Worn look", false)
    Mock.click(Mock.button(UI.Pages.Looks, "Save")); settle(2)
    local worn = Store.Looks[1]
    check(worn.Name == "Worn look" and worn.Source == "My character · R15" and worn.Data.Visual and #worn.Data.Visual.Accessories >= 3, "Save captures the worn skin")
    Mock.click(Mock.button(UI.LookList, "Wear")); settle(4)
    check(App.Current.LookKey == worn.Key and UI.StatusText.Text:find("Avatar applied", 1, true), "a saved skin can be worn")
    gameObjectsIntact(character, "saved skin")

    -- Restore. The initial snapshot recorded every accessory on the character, so a game accessory that
    -- holds a script is kept and its recorded copy comes back too (documented in docs/troubleshooting.md).
    Mock.click(UI.NavButtons.Avatar.Root); settle(0.3)
    Mock.click(UI.Restore.Root); settle(4)
    local restored = copiedAccessories(character)
    check(App.Current == App.Initial and UI.StatusText.Text == "Initial appearance restored." and #restored == 1 and restored[1].Name == "GunHolster",
        "Restore puts the initial appearance back")
    gameObjectsIntact(character, "restore")
    check(character.Humanoid.AutomaticScalingEnabled == true and character.Humanoid:GetAttribute("Lyra_OriginalAutomaticScaling") == nil, "Restore gives automatic scaling back")

    -- Visual-only draws the avatar over the character instead of changing it.
    Store.Settings.VisualOnly = true
    Mock.type(UI.SearchBox, "Builderman", true); settle(2)
    Mock.click(UI.Apply.Root); settle(3)
    local overlay = H.Overlay.Active[character]
    check(overlay and overlay.Local and #copiedAccessories(character) == 1, "visual-only leaves the character untouched")
    check(character.Head.Transparency == 1 and overlay.Model.Parent.Parent == Mock.Camera, "your own body is hidden under the local overlay")
    Mock.click(UI.Restore.Root); settle(4)
    check(H.Overlay.Active[character] == nil and character.Head.Transparency == 0, "Restore removes the overlay and shows the body again")
    Store.Settings.VisualOnly = false; App.persist()

    -- Hotkeys that need a character.
    Mock.key("V"); settle(0.2)
    check(H.S.freeCamActive and character.HumanoidRootPart.Anchored and Mock.Camera.CameraType == Enum.CameraType.Scriptable, "V starts the free camera")
    local start = Mock.Camera.CFrame.Position
    Mock.InputService.InputBegan:Fire(Mock.input("Keyboard", nil, Enum.KeyCode.Up), false)
    for _ = 1, 10 do Mock.frame(1 / 60) end
    Mock.InputService.InputEnded:Fire(Mock.input("Keyboard", nil, Enum.KeyCode.Up), false)
    check((Mock.Camera.CFrame.Position - start).Magnitude > 1, "arrow keys move the free camera")
    Mock.key("V"); settle(0.2)
    check(not H.S.freeCamActive and not character.HumanoidRootPart.Anchored and Mock.Camera.CameraType == Enum.CameraType.Custom, "V gives the camera back")
    Mock.key("R"); settle(0.2)
    local mirror = Mock.G.Copier_LeftToolClone
    check(mirror and mirror.Parent == character and mirror.Name == "Knife_LeftWield", "R mirrors the held tool to the left hand")
    Mock.key("R"); settle(0.2)
    check(Mock.G.Copier_LeftToolClone == nil and mirror.Parent == nil, "R removes the mirrored tool")

    -- Avatar cycle on death and on a timer.
    local function respawnAfterDeath()
        character.Humanoid.Died:Connect(function() task.delay(1, function() character = Mock.spawnCharacter(Enum.HumanoidRigType.R15, gameObjects) end) end)
    end
    Store.Auto.List = {Store.entry({Kind = "User", Id = 156, Name = "Builderman"}), Store.entry({Kind = "User", Id = 2207291, Name = "Korbloxian"})}
    Store.Auto.Index = 0; Store.Auto.CycleEnabled = true; Store.Auto.Trigger = "Death"; Store.Auto.EveryDeaths = 1; Store.Auto.Cooldown = 0
    respawnAfterDeath()
    character.Humanoid.Health = 0
    settle(6)
    check(App.Current.Id == 156 and Store.Auto.Index == 1 and #copiedAccessories(character) == 2, "a death switches to the next avatar in the cycle")
    gameObjectsIntact(character, "cycle")
    respawnAfterDeath()
    character.Humanoid.Health = 0
    settle(6)
    check(App.Current.Id == 2207291 and Store.Auto.Index == 2, "the next death moves on again")
    Store.Auto.Trigger = "Timer"; Store.Auto.TimerSeconds = 10
    H.Auto.TimerStart = os.clock()
    settle(13)
    check(App.Current.Id == 156 and Store.Auto.Index == 1, "the timer switches avatars and loops the list")
    Store.Auto.CycleEnabled = false; Store.Auto.List = {}; Store.Auto.Index = 0; App.persist()

    -- Reset character first.
    Store.Settings.AutoReset = true
    respawnAfterDeath()
    local beforeReset = character
    Mock.type(UI.SearchBox, "Korbloxian", true); settle(2)
    Mock.click(UI.Apply.Root); settle(8)
    check(character ~= beforeReset and App.Current.Id == 2207291 and #copiedAccessories(character) == 1, "Reset character first respawns before applying")
    Store.Settings.AutoReset = false; App.persist()

    -- Skin sync shares the applied skin.
    local shared
    for _, body in ipairs(syncLog) do if body.a == "beat" and body.data then shared = body end end
    check(shared and shared.hash == Sync.hash(shared.data) and Mock.jsonDecode(shared.data).Version == 2, "beats carry the applied skin when it changes")

    -- A stand-in model with the player's name gets the avatar too.
    local standIn = Mock.buildRig(Mock.describe(Mock.Users[1]), Enum.HumanoidRigType.R15)
    standIn.Name = "LyraTester"; standIn.Parent = Mock.Workspace
    settle(2)
    check(#copiedAccessories(standIn) == 1, "a local stand-in of the player gets the avatar")


    -- R6, custom characters and parts that refuse new meshes -------------------------------------------
    character = Mock.spawnCharacter(Enum.HumanoidRigType.R6)
    settle(5)
    Mock.type(UI.SearchBox, "Builderman", true); settle(2)
    check(UI.RigText.Text == "PREVIEW IN R6", "the preview follows the character's rig")
    Mock.click(UI.Apply.Root); settle(3)
    check(App.Current.Id == 156 and UI.StatusText.Text == "Avatar applied. This game does not use an R15 rig, so its own animations were kept.",
        "an R6 character gets the avatar and keeps the game's animations")
    check(#copiedAccessories(character) == 2 and rigConnected(character), "R6: accessories added and joints intact")

    character = Mock.spawnCharacter(Enum.HumanoidRigType.R15, function(model) model.Head:Destroy() end)
    settle(5)
    -- The head and the two accessories that hang from it are reported; the rest is applied.
    check(UI.StatusText.Text:find("Avatar applied with limitations: 3", 1, true) ~= nil and character:FindFirstChild("Head") == nil
        and character:FindFirstChildOfClass("Shirt") ~= nil, "a character without a head gets what fits and reports the rest")
    check(rigConnected(character), "the headless character stays jointed")

    character = Mock.spawnCharacter(Enum.HumanoidRigType.R15, function(model) model.LeftUpperArm:SetAttribute("MockRejectApplyMesh", true) end)
    settle(5)
    local visual = character:FindFirstChild("LyraVisual_LeftUpperArm")
    check(visual and visual:GetAttribute("Lyra_VisualFor") == "LeftUpperArm" and visual.LyraVisualWeld.Part0 == character.LeftUpperArm,
        "a part that rejects ApplyMesh gets a welded local visual")
    check(character.LeftUpperArm.Transparency == 1 and not visual.CanCollide and visual.Massless, "the real part is hidden and the visual is inert")
    expectWarning("LeftUpperArm: using a local visual")
    character.LeftUpperArm:SetAttribute("MockRejectApplyMesh", nil)
    Mock.click(UI.Restore.Root); settle(4)
    check(character:FindFirstChild("LyraVisual_LeftUpperArm") == nil and character.LeftUpperArm.Transparency == 0, "the next apply clears old local visuals")

    -- Saved data on start -------------------------------------------------------------------------------
    local Lighting = game:GetService("Lighting")
    local function rerun(files)
        H.cleanup()
        for path, value in pairs(files) do Mock.Files[path] = value end
        H = Mock.Run()
        settle(1)
        UI, App, Store = H.UI, H.App, H.Store
    end
    character = Mock.spawnCharacter(Enum.HumanoidRigType.R15, gameObjects)
    settle(2)
    local good = Mock.Files[SAVE]
    rerun({[SAVE] = "{broken", [SAVE .. ".bak"] = good})
    check(Store.LoadIssue == "A recovery copy of your data was loaded." and UI.StatusText.Text == Store.LoadIssue and #Store.Looks == 3,
        "a damaged save falls back to its backup")
    rerun({[SAVE] = '{"Version":99,"Favorites":[]}'})
    check(Store.ReadOnly and Store.LoadIssue:find("Unsupported data format", 1, true), "a save from a newer version is opened read-only")
    local newer = Mock.Files[SAVE]
    check(not App.persist() and Mock.Files[SAVE] == newer, "a newer save is never overwritten")
    rerun({[SAVE] = '{"Version":4,"Settings":{"UIScale":500,"WindowW":10,"WindowH":-5,"Keybind":"NotAKey","GlassBlur":"yes"},'
        .. '"Auto":{"LoadDelay":99,"Order":"Bogus","Games":{"abc":{"Kind":"User","Id":1,"Name":"x"}},"List":[{"Kind":"Look","Key":""},{"Kind":"User","Id":5,"Name":"Five"}]}}'})
    check(Store.Settings.UIScale == 130 and Store.Settings.WindowW == 300 and Store.Settings.WindowH == 0 and Store.Settings.Keybind == "RightControl"
        and Store.Settings.GlassBlur == true, "saved settings are clamped and checked by type")
    check(Store.Auto.LoadDelay == 30 and Store.Auto.Order == "Sequential" and Store.Auto.Games.abc == nil and #Store.Auto.List == 1, "saved auto options are checked")
    local writes = Mock.Writes[SAVE]
    Store.Settings.SwapEffect = not Store.Settings.SwapEffect
    App.persist(); App.persist()
    check(Mock.Writes[SAVE] == writes + 1, "unchanged data is not written again")
    check(Mock.Files[SAVE .. ".bak"] ~= nil, "the previous file is kept as a backup")
    rerun({[SAVE] = '{"Version":4,"Settings":{"StartHidden":true,"MobileOrb":true,"HideTipSeen":true}}'})
    check(not UI.Visible and not UI.Main.Visible and UI.Orb.Visible, "Start hidden opens straight into the floating button")
    local inputExtra, chatExtra = Mock.info(Mock.InputService).Extra, Mock.info(Mock.ChatService).Extra
    local canChat = chatExtra.CanUserChatAsync
    inputExtra.KeyboardEnabled = false; chatExtra.CanUserChatAsync = function() task.wait(0.2); return false end
    rerun({[SAVE] = '{"Version":4,"Settings":{"StartHidden":true,"MobileOrb":false,"MenuReopen":false}}'})
    check(UI.Visible and UI.StartSkipped and UI.StatusText.Text:find("Start hidden was skipped", 1, true), "Start hidden is skipped when nothing could reopen the window")
    inputExtra.KeyboardEnabled = true; chatExtra.CanUserChatAsync = canChat
    rerun({[SAVE] = '{"Version":4,"Auto":{"LoadEnabled":true,"LoadSource":"Chosen","LoadDelay":0,"Chosen":{"Kind":"User","Id":156,"Name":"Builderman"}}}'})
    settle(6)
    check(App.Current and App.Current.Id == 156 and #copiedAccessories(character) == 2, "Auto-load applies the chosen avatar on start")
    rerun({[SAVE] = '{"Version":4,"Auto":{"LoadEnabled":true,"LoadSource":"Chosen","LoadDelay":0,"Chosen":{"Kind":"User","Id":156,"Name":"Builderman"},'
        .. '"Games":{"1818":{"Kind":"User","Id":2207291,"Name":"Korbloxian"}}}}'})
    settle(6)
    check(App.Current and App.Current.Id == 2207291, "an avatar chosen for this game wins over the general choice")
    Mock.GameId = 3647333358
    rerun({[SAVE] = '{"Version":4}'})
    check(H.Overlay.visualOnly(), "visual-only is forced in Evade")
    Mock.GameId = nil

    -- Running again and cleaning up ---------------------------------------------------------------------
    local first = H
    local leaves = 0
    for _, body in ipairs(syncLog) do if body.a == "leave" then leaves += 1 end end
    H = Mock.Run(); settle(1)
    UI, App, Store = H.UI, H.App, H.Store
    local guis = 0
    for _, gui in ipairs(Mock.PlayerGui:GetChildren()) do if gui.Name == "CopierHubGUI" then guis += 1 end end
    check(first.UI.Gui.Parent == nil and first.App.Closed and guis == 1, "running the script again closes the previous run")
    local blurs = 0
    for _, item in ipairs(Lighting:GetChildren()) do if item.Name == "CopierLiquidBlur" then blurs += 1 end end
    check(blurs == 1, "only one blur effect exists")
    local newLeaves = 0
    for _, body in ipairs(syncLog) do if body.a == "leave" then newLeaves += 1 end end
    check(newLeaves == leaves + 1, "the closed run leaves skin sync")
    H.cleanup(); settle(1)
    check(UI.Gui.Parent == nil and Lighting:FindFirstChild("CopierLiquidBlur") == nil and game:GetService("TextChatService"):FindFirstChild("LyraCopierCommand") == nil,
        "cleanup removes the window, the blur and the chat command")
    check(Mock.Camera:FindFirstChild("LyraSkinOverlays") == nil and Mock.G.Copier_ToolsGiverToggle == nil, "cleanup removes overlays and globals")
    local requests = #Mock.Requests
    settle(20)
    check(#Mock.Requests == requests, "nothing keeps running after cleanup")

    finished = true
end)

for _ = 1, 20000 do
    if finished or #Mock.Errors > 0 then break end
    Mock.frame(0.05)
    Mock.advance(0.05)
end

if #Mock.Errors > 0 then
    Mock.out("FAILED with " .. #Mock.Errors .. " error(s):")
    for _, problem in ipairs(Mock.Errors) do Mock.out(problem) end
    error("tests failed")
end
if not finished then error("the scenario did not finish") end
local warnings = scriptWarnings()
if #warnings > 0 then
    for _, line in ipairs(warnings) do Mock.out(line) end
    error("unexpected script warnings")
end
Mock.out(string.format("OK: %d checks passed", checks))
