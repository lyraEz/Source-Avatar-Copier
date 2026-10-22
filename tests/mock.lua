--[[
    A small Roblox stand-in for running Avatar Copier with the plain Luau CLI.

    It is not an engine: there is no rendering, no physics and no real layout. It exists to execute the
    script's code paths and fail loudly on the mistakes that matter outside Studio: unknown classes,
    misspelled properties or enum items, wrong value types, writes to read-only properties, use of
    destroyed instances and errors inside callbacks or tasks.

    Roblox web APIs (users, avatars, catalog) and executor functions (files, clipboard, HTTP requests) are
    faked with small in-memory tables, so the tests never touch the network.

    tests/run.sh concatenates this file, src/avatar-copier.lua (wrapped in Mock.Run) and tests/run.lua
    into one chunk, so everything below is a local that the script sees as its globals.
]]

local Mock = {Errors = {}, Warnings = {}, Prints = {}, Files = {}, Clipboard = nil, Now = 0, Requests = {}, HttpGets = {}}
Mock.out = print
local realOs = os
local os = setmetatable({clock = function() return Mock.Now end}, {__index = realOs})

local function fail(message) error(message, 3) end

-- -----------------------------------------------------------------------------
-- typeof and data types
-- -----------------------------------------------------------------------------
local function typeof(value)
    local meta = getmetatable(value)
    if type(meta) == "table" and meta.__type then return meta.__type end
    return type(value)
end
local function strict(typeName, fields, methods)
    local meta = {__type = typeName}
    meta.__index = function(self, key)
        if methods and methods[key] then return methods[key] end
        if fields and fields[key] then return fields[key](self) end
        fail(tostring(key) .. " is not a valid member of " .. typeName)
    end
    meta.__newindex = function(_, key) fail(typeName .. "." .. tostring(key) .. " cannot be assigned to") end
    return meta
end
local function expect(value, typeName, where)
    if typeof(value) ~= typeName then fail(where .. " expects " .. typeName .. ", got " .. typeof(value)) end
end
local function number(value, where)
    if type(value) ~= "number" then fail(where .. " expects a number, got " .. typeof(value)) end
    if value ~= value then fail(where .. " got NaN") end
    return value
end

local Vector2Meta
local function v2(x, y) return setmetatable({X = number(x or 0, "Vector2.new"), Y = number(y or 0, "Vector2.new")}, Vector2Meta) end
Vector2Meta = strict("Vector2", {Magnitude = function(self) return math.sqrt(self.X * self.X + self.Y * self.Y) end})
Vector2Meta.__add = function(a, b) expect(a, "Vector2", "Vector2 +"); expect(b, "Vector2", "Vector2 +"); return v2(a.X + b.X, a.Y + b.Y) end
Vector2Meta.__sub = function(a, b) expect(a, "Vector2", "Vector2 -"); expect(b, "Vector2", "Vector2 -"); return v2(a.X - b.X, a.Y - b.Y) end
Vector2Meta.__mul = function(a, b)
    if type(a) == "number" then return v2(a * b.X, a * b.Y) end
    if type(b) == "number" then return v2(a.X * b, a.Y * b) end
    return v2(a.X * b.X, a.Y * b.Y)
end
Vector2Meta.__div = function(a, b)
    if type(b) == "number" then return v2(a.X / b, a.Y / b) end
    return v2(a.X / b.X, a.Y / b.Y)
end
Vector2Meta.__unm = function(a) return v2(-a.X, -a.Y) end
Vector2Meta.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
Vector2Meta.__tostring = function(a) return a.X .. ", " .. a.Y end
local Vector2 = {new = v2, zero = v2(0, 0), one = v2(1, 1)}

local Vector3Meta
local function v3(x, y, z) return setmetatable({X = number(x or 0, "Vector3.new"), Y = number(y or 0, "Vector3.new"), Z = number(z or 0, "Vector3.new")}, Vector3Meta) end
Vector3Meta = strict("Vector3", {
    Magnitude = function(self) return math.sqrt(self.X ^ 2 + self.Y ^ 2 + self.Z ^ 2) end,
    Unit = function(self) local m = math.sqrt(self.X ^ 2 + self.Y ^ 2 + self.Z ^ 2); return m > 0 and v3(self.X / m, self.Y / m, self.Z / m) or v3() end,
}, {
    Dot = function(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end,
    Cross = function(a, b) return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end,
    Lerp = function(a, b, t) return v3(a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t, a.Z + (b.Z - a.Z) * t) end,
})
Vector3Meta.__add = function(a, b) expect(a, "Vector3", "Vector3 +"); expect(b, "Vector3", "Vector3 +"); return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
Vector3Meta.__sub = function(a, b) expect(a, "Vector3", "Vector3 -"); expect(b, "Vector3", "Vector3 -"); return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
Vector3Meta.__mul = function(a, b)
    if type(a) == "number" then return v3(a * b.X, a * b.Y, a * b.Z) end
    if type(b) == "number" then return v3(a.X * b, a.Y * b, a.Z * b) end
    expect(b, "Vector3", "Vector3 *")
    return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
Vector3Meta.__div = function(a, b)
    if type(b) == "number" then return v3(a.X / b, a.Y / b, a.Z / b) end
    expect(b, "Vector3", "Vector3 /")
    return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
Vector3Meta.__unm = function(a) return v3(-a.X, -a.Y, -a.Z) end
Vector3Meta.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
Vector3Meta.__tostring = function(a) return a.X .. ", " .. a.Y .. ", " .. a.Z end
local Vector3 = {new = v3, zero = v3(), one = v3(1, 1, 1), xAxis = v3(1, 0, 0), yAxis = v3(0, 1, 0), zAxis = v3(0, 0, 1)}

-- CFrame: a position and a row-major 3x3 rotation, laid out like CFrame:GetComponents().
local CFrameMeta
local function cframe(x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
    local c = {x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22}
    for i = 1, 12 do number(c[i], "CFrame") end
    return setmetatable({C = c}, CFrameMeta)
end
local function rotate(c, x, y, z) return c[4] * x + c[5] * y + c[6] * z, c[7] * x + c[8] * y + c[9] * z, c[10] * x + c[11] * y + c[12] * z end
local function compose(a, b)
    local A, B = a.C, b.C
    local px, py, pz = rotate(A, B[1], B[2], B[3])
    local function m(i, j) return A[4 + i * 3] * B[4 + j] + A[5 + i * 3] * B[7 + j] + A[6 + i * 3] * B[10 + j] end
    return cframe(px + A[1], py + A[2], pz + A[3], m(0, 0), m(0, 1), m(0, 2), m(1, 0), m(1, 1), m(1, 2), m(2, 0), m(2, 1), m(2, 2))
end
local function inverse(a)
    local c = a.C
    local x, y, z = -c[1], -c[2], -c[3]
    return cframe(c[4] * x + c[7] * y + c[10] * z, c[5] * x + c[8] * y + c[11] * z, c[6] * x + c[9] * y + c[12] * z,
        c[4], c[7], c[10], c[5], c[8], c[11], c[6], c[9], c[12])
end
local function fromRotation(r00, r01, r02, r10, r11, r12, r20, r21, r22) return cframe(0, 0, 0, r00, r01, r02, r10, r11, r12, r20, r21, r22) end
local function rx(a) local c, s = math.cos(a), math.sin(a); return fromRotation(1, 0, 0, 0, c, -s, 0, s, c) end
local function ry(a) local c, s = math.cos(a), math.sin(a); return fromRotation(c, 0, s, 0, 1, 0, -s, 0, c) end
local function rz(a) local c, s = math.cos(a), math.sin(a); return fromRotation(c, -s, 0, s, c, 0, 0, 0, 1) end
CFrameMeta = strict("CFrame", {
    Position = function(self) return v3(self.C[1], self.C[2], self.C[3]) end,
    p = function(self) return v3(self.C[1], self.C[2], self.C[3]) end,
    X = function(self) return self.C[1] end, Y = function(self) return self.C[2] end, Z = function(self) return self.C[3] end,
    LookVector = function(self) return v3(-self.C[6], -self.C[9], -self.C[12]) end,
    RightVector = function(self) return v3(self.C[4], self.C[7], self.C[10]) end,
    UpVector = function(self) return v3(self.C[5], self.C[8], self.C[11]) end,
    Rotation = function(self) local c = self.C; return fromRotation(c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12]) end,
}, {
    Inverse = function(self) return inverse(self) end,
    ToObjectSpace = function(self, other) expect(other, "CFrame", "CFrame:ToObjectSpace"); return compose(inverse(self), other) end,
    ToWorldSpace = function(self, other) expect(other, "CFrame", "CFrame:ToWorldSpace"); return compose(self, other) end,
    PointToObjectSpace = function(self, point) local c = inverse(self).C; local x, y, z = rotate(c, point.X, point.Y, point.Z); return v3(x + c[1], y + c[2], z + c[3]) end,
    GetComponents = function(self) return table.unpack(self.C) end,
    components = function(self) return table.unpack(self.C) end,
    ToEulerAnglesYXZ = function(self)
        local c = self.C
        local x = math.asin(math.clamp(-c[9], -1, 1))
        return x, math.atan2(c[6], c[12]), math.atan2(c[7], c[8])
    end,
    Lerp = function(a, b, t)
        local A, B, out = a.C, b.C, {}
        for i = 1, 12 do out[i] = A[i] + (B[i] - A[i]) * t end
        return cframe(table.unpack(out))
    end,
})
CFrameMeta.__mul = function(a, b)
    expect(a, "CFrame", "CFrame *")
    if typeof(b) == "Vector3" then local x, y, z = rotate(a.C, b.X, b.Y, b.Z); return v3(x + a.C[1], y + a.C[2], z + a.C[3]) end
    expect(b, "CFrame", "CFrame *")
    return compose(a, b)
end
CFrameMeta.__add = function(a, b) expect(a, "CFrame", "CFrame +"); expect(b, "Vector3", "CFrame +"); local c = table.clone(a.C); c[1] += b.X; c[2] += b.Y; c[3] += b.Z; return cframe(table.unpack(c)) end
CFrameMeta.__sub = function(a, b) expect(a, "CFrame", "CFrame -"); expect(b, "Vector3", "CFrame -"); local c = table.clone(a.C); c[1] -= b.X; c[2] -= b.Y; c[3] -= b.Z; return cframe(table.unpack(c)) end
CFrameMeta.__eq = function(a, b) for i = 1, 12 do if a.C[i] ~= b.C[i] then return false end end; return true end
CFrameMeta.__tostring = function(a) return table.concat(a.C, ", ") end
local CFrame = {
    identity = cframe(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    new = function(...)
        local n = select("#", ...)
        if n == 0 then return cframe(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) end
        local a = ...
        if n == 1 then expect(a, "Vector3", "CFrame.new"); return cframe(a.X, a.Y, a.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1) end
        if n == 3 then local x, y, z = ...; return cframe(x, y, z, 1, 0, 0, 0, 1, 0, 0, 0, 1) end
        if n == 12 then return cframe(...) end
        fail("CFrame.new does not take " .. n .. " arguments here")
    end,
    lookAt = function(at, target, up)
        expect(at, "Vector3", "CFrame.lookAt"); expect(target, "Vector3", "CFrame.lookAt")
        local look = (target - at).Unit
        if look.Magnitude == 0 then look = v3(0, 0, -1) end
        local right = look:Cross(up or v3(0, 1, 0)).Unit
        if right.Magnitude == 0 then right = v3(1, 0, 0) end
        local upward = right:Cross(look)
        return cframe(at.X, at.Y, at.Z, right.X, upward.X, -look.X, right.Y, upward.Y, -look.Y, right.Z, upward.Z, -look.Z)
    end,
    fromEulerAnglesYXZ = function(x, y, z) return compose(compose(ry(y), rx(x)), rz(z)) end,
    Angles = function(x, y, z) return compose(compose(rx(x), ry(y)), rz(z)) end,
}
CFrame.fromOrientation = CFrame.fromEulerAnglesYXZ

local UDimMeta = strict("UDim")
UDimMeta.__eq = function(a, b) return a.Scale == b.Scale and a.Offset == b.Offset end
local function udim(scale, offset) return setmetatable({Scale = number(scale or 0, "UDim.new"), Offset = math.floor(number(offset or 0, "UDim.new"))}, UDimMeta) end
local UDim = {new = udim}

local UDim2Meta
local function udim2(xs, xo, ys, yo)
    local x, y = udim(xs, xo), udim(ys, yo)
    return setmetatable({X = x, Y = y, Width = x, Height = y}, UDim2Meta)
end
UDim2Meta = strict("UDim2")
UDim2Meta.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
UDim2Meta.__add = function(a, b) return udim2(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset) end
UDim2Meta.__sub = function(a, b) return udim2(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset) end
local UDim2 = {
    new = function(xs, xo, ys, yo) return udim2(xs, xo, ys, yo) end,
    fromOffset = function(x, y) return udim2(0, x, 0, y) end,
    fromScale = function(x, y) return udim2(x, 0, y, 0) end,
}

local Color3Meta
local function color(r, g, b)
    for _, value in ipairs({r or 0, g or 0, b or 0}) do number(value, "Color3.new") end
    return setmetatable({R = r or 0, G = g or 0, B = b or 0}, Color3Meta)
end
Color3Meta = strict("Color3", nil, {Lerp = function(a, b, t)
    expect(b, "Color3", "Color3:Lerp")
    return color(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end})
Color3Meta.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end
local Color3 = {new = color, fromRGB = function(r, g, b) return color((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end}

local NumberRangeMeta = strict("NumberRange")
local NumberRange = {new = function(min, max)
    number(min, "NumberRange.new")
    return setmetatable({Min = min, Max = max == nil and min or number(max, "NumberRange.new")}, NumberRangeMeta)
end}
local ColorKeyMeta, NumberKeyMeta = strict("ColorSequenceKeypoint"), strict("NumberSequenceKeypoint")
local ColorSequenceKeypoint = {new = function(t, c)
    number(t, "ColorSequenceKeypoint.new"); expect(c, "Color3", "ColorSequenceKeypoint.new")
    return setmetatable({Time = t, Value = c}, ColorKeyMeta)
end}
local NumberSequenceKeypoint = {new = function(t, v, e)
    number(t, "NumberSequenceKeypoint.new"); number(v, "NumberSequenceKeypoint.new")
    return setmetatable({Time = t, Value = v, Envelope = e or 0}, NumberKeyMeta)
end}
local ColorSequenceMeta, NumberSequenceMeta = strict("ColorSequence"), strict("NumberSequence")
local function checkKeys(keys, typeName, where)
    if #keys < 2 then fail(where .. " needs at least 2 keypoints") end
    for i, key in ipairs(keys) do
        expect(key, typeName, where)
        if (i == 1 and key.Time ~= 0) or (i == #keys and key.Time ~= 1) then fail(where .. " keypoints must start at 0 and end at 1") end
        if i > 1 and key.Time < keys[i - 1].Time then fail(where .. " keypoints must be sorted by time") end
    end
end
local ColorSequence = {new = function(a, b)
    local keys
    if typeof(a) == "Color3" then
        if b ~= nil then expect(b, "Color3", "ColorSequence.new") end
        keys = {ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, b or a)}
    else
        if type(a) ~= "table" then fail("ColorSequence.new expects Color3 or keypoints") end
        checkKeys(a, "ColorSequenceKeypoint", "ColorSequence.new"); keys = a
    end
    return setmetatable({Keypoints = keys}, ColorSequenceMeta)
end}
local NumberSequence = {new = function(a, b)
    local keys
    if type(a) == "number" then keys = {NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b or a)}
    else
        if type(a) ~= "table" then fail("NumberSequence.new expects a number or keypoints") end
        checkKeys(a, "NumberSequenceKeypoint", "NumberSequence.new"); keys = a
    end
    return setmetatable({Keypoints = keys}, NumberSequenceMeta)
end}
local TweenInfoMeta = strict("TweenInfo")
local TweenInfo = {new = function(time, style, direction)
    if style ~= nil then expect(style, "EnumItem", "TweenInfo.new") end
    if direction ~= nil then expect(direction, "EnumItem", "TweenInfo.new") end
    return setmetatable({Time = number(time or 1, "TweenInfo.new"), EasingStyle = style, EasingDirection = direction}, TweenInfoMeta)
end}
local ContentMeta = strict("Content")
local Content = {fromUri = function(uri)
    if type(uri) ~= "string" then fail("Content.fromUri expects a string") end
    return setmetatable({Uri = uri}, ContentMeta)
end}
local RandomMeta = strict("Random", nil, {
    NextInteger = function(self, low, high)
        number(low, "Random:NextInteger"); number(high, "Random:NextInteger")
        if low > high then fail("Random:NextInteger: max must be >= min") end
        self.Seed = (self.Seed * 1103515245 + 12345) % 2147483648
        return low + self.Seed % (high - low + 1)
    end,
    NextNumber = function(self)
        self.Seed = (self.Seed * 1103515245 + 12345) % 2147483648
        return self.Seed / 2147483648
    end,
})
RandomMeta.__newindex = function(self, key, value) if key == "Seed" then rawset(self, key, value) else fail("Random." .. tostring(key) .. " cannot be assigned to") end end
local Random = {new = function(seed) return setmetatable({Seed = math.floor(seed or 1)}, RandomMeta) end}

-- -----------------------------------------------------------------------------
-- Enums: only the items listed here exist, so a typo fails like it would in Roblox.
-- -----------------------------------------------------------------------------
local ENUMS = {
    Font = {"Gotham", "GothamBold", "GothamMedium", "Code", "BuilderSans", "BuilderSansMedium", "BuilderSansBold", "SourceSans"},
    AutomaticSize = {"None", "X", "Y", "XY"},
    TextXAlignment = {"Left", "Center", "Right"},
    TextYAlignment = {"Top", "Center", "Bottom"},
    TextTruncate = {"None", "AtEnd", "SplitWord"},
    SortOrder = {"LayoutOrder", "Name"},
    FillDirection = {"Horizontal", "Vertical"},
    HorizontalAlignment = {"Left", "Center", "Right"},
    VerticalAlignment = {"Top", "Center", "Bottom"},
    ScrollingDirection = {"X", "Y", "XY"},
    ElasticBehavior = {"WhenScrollable", "Always", "Never"},
    ZIndexBehavior = {"Global", "Sibling"},
    EasingStyle = {"Linear", "Sine", "Back", "Quad", "Quart", "Quint", "Bounce", "Elastic", "Exponential", "Circular", "Cubic"},
    EasingDirection = {"In", "Out", "InOut"},
    ScaleType = {"Stretch", "Slice", "Tile", "Fit", "Crop"},
    ApplyStrokeMode = {"Contextual", "Border"},
    UserInputType = {"MouseButton1", "MouseButton2", "MouseMovement", "MouseWheel", "Touch", "Keyboard", "Focus", "Gamepad1", "None"},
    UserInputState = {"Begin", "Change", "End", "Cancel", "None"},
    KeyCode = {"Unknown", "Escape", "Return", "Space", "Tab", "Backspace", "Slash", "LeftControl", "RightControl", "LeftShift", "RightShift",
        "LeftAlt", "RightAlt", "Insert", "Delete", "Home", "End", "PageUp", "PageDown", "Up", "Down", "Left", "Right",
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "One", "Two", "Three"},
    PlaybackState = {"Begin", "Playing", "Paused", "Completed", "Cancelled"},
    HumanoidRigType = {"R6", "R15"},
    MouseBehavior = {"Default", "LockCenter", "LockCurrentPosition"},
    CameraType = {"Fixed", "Attach", "Watch", "Track", "Follow", "Custom", "Scriptable", "Orbital"},
    RenderPriority = {"First", "Input", "Camera", "Character", "Last"},
    CoreGuiType = {"PlayerList", "Health", "Backpack", "Chat", "All", "EmotesMenu", "SelfView", "Captures"},
    HighlightDepthMode = {"AlwaysOnTop", "Occluded"},
    BulkMoveMode = {"FireAllEvents", "FireCFrameChanged"},
    HumanoidDisplayDistanceType = {"Viewer", "Subject", "None"},
    HumanoidHealthDisplayType = {"DisplayWhenDamaged", "AlwaysOn", "AlwaysOff"},
    Material = {"Plastic", "SmoothPlastic", "Neon", "Wood", "Metal", "Glass", "Fabric", "ForceField", "Foil", "Granite", "Marble", "Sand", "Slate", "Concrete", "Brick"},
    NormalId = {"Right", "Top", "Back", "Left", "Bottom", "Front"},
    MeshType = {"Head", "Torso", "Wedge", "Prism", "Pyramid", "ParallelRamp", "RightAngleRamp", "CornerWedge", "Brick", "Sphere", "Cylinder", "FileMesh"},
    AlphaMode = {"Overlay", "Transparency", "TintMask"},
    ParticleEmitterShape = {"Box", "Sphere", "Cylinder", "Disc"},
    TextureMode = {"Stretch", "Wrap", "Static"},
    WrapLayerAutoSkin = {"Disabled", "EnabledPreserve", "EnabledOverride"},
    CollisionFidelity = {"Default", "Hull", "Box", "PreciseConvexDecomposition"},
    RenderFidelity = {"Automatic", "Precise", "Performance"},
    InfoType = {"Asset", "Product", "GamePass", "Subscription", "Bundle"},
    AccessoryType = {"Unknown", "Hat", "Hair", "Face", "Neck", "Shoulder", "Front", "Back", "Waist", "TShirt", "Shirt", "Pants", "Jacket",
        "Sweater", "Shorts", "LeftShoe", "RightShoe", "DressSkirt", "Eyebrow", "Eyelash"},
    BodyPartR15 = {"Head", "UpperTorso", "LowerTorso", "LeftFoot", "LeftLowerLeg", "LeftUpperLeg", "RightFoot", "RightLowerLeg", "RightUpperLeg",
        "LeftHand", "LeftLowerArm", "LeftUpperArm", "RightHand", "RightLowerArm", "RightUpperArm", "RootPart", "Unknown"},
    AvatarAssetType = {"TShirt", "Hat", "Shirt", "Pants", "Head", "Face", "Gear", "Torso", "RightArm", "LeftArm", "LeftLeg", "RightLeg",
        "HairAccessory", "FaceAccessory", "NeckAccessory", "ShoulderAccessory", "FrontAccessory", "BackAccessory", "WaistAccessory",
        "ClimbAnimation", "DeathAnimation", "FallAnimation", "IdleAnimation", "JumpAnimation", "RunAnimation", "SwimAnimation", "WalkAnimation",
        "PoseAnimation", "EmoteAnimation", "TShirtAccessory", "ShirtAccessory", "PantsAccessory", "JacketAccessory", "SweaterAccessory",
        "ShortsAccessory", "LeftShoeAccessory", "RightShoeAccessory", "DressSkirtAccessory", "EyebrowAccessory", "EyelashAccessory",
        "MoodAnimation", "DynamicHead"},
    BundleType = {"BodyParts", "Animations", "Shoes", "DynamicHead", "DynamicHeadAvatar"},
    CatalogSortType = {"Relevance", "PriceHighToLow", "PriceLowToHigh", "RecentlyCreated", "MostFavorited", "Bestselling"},
    CatalogSortAggregation = {"PastDay", "PastWeek", "AllTime"},
    SalesTypeFilter = {"All", "Collectibles", "Premium"},
}
local EnumItemMeta = {__type = "EnumItem", __tostring = function(self) return "Enum." .. self.EnumType .. "." .. self.Name end}
EnumItemMeta.__index = function(_, key) fail(tostring(key) .. " is not a valid member of EnumItem") end
local Enum = {}
for enumName, items in pairs(ENUMS) do
    local enum, index = {}, {}
    for position, itemName in ipairs(items) do
        local item = setmetatable({Name = itemName, EnumType = enumName, Value = position - 1}, EnumItemMeta)
        enum[itemName] = item
        table.insert(index, item)
    end
    setmetatable(enum, {__index = function(_, key)
        if key == "GetEnumItems" then return function() return index end end
        fail(tostring(key) .. " is not a valid EnumItem of Enum." .. enumName)
    end})
    Enum[enumName] = enum
end
setmetatable(Enum, {__index = function(_, key) fail(tostring(key) .. " is not a valid Enum") end})

-- -----------------------------------------------------------------------------
-- Scheduler: task.* on a virtual clock. Mock.advance(seconds) runs everything due by then.
-- -----------------------------------------------------------------------------
local Queue = {}
local sequence = 0
local function report(thread, problem)
    local trace = debug.traceback(thread, tostring(problem))
    table.insert(Mock.Errors, trace)
end
local function resume(thread, ...)
    local ok, problem = coroutine.resume(thread, ...)
    if not ok then report(thread, problem) end
    return thread
end
local function schedule(at, thread, ...)
    sequence = sequence + 1
    table.insert(Queue, {At = at, Seq = sequence, Thread = thread, Args = table.pack(...)})
end
local function threadOf(fn)
    if type(fn) == "thread" then return fn end
    if type(fn) ~= "function" then fail("task expects a function or thread, got " .. typeof(fn)) end
    return coroutine.create(fn)
end
local task = {}
function task.spawn(fn, ...) return resume(threadOf(fn), ...) end
function task.defer(fn, ...) local thread = threadOf(fn); schedule(Mock.Now, thread, ...); return thread end
function task.delay(seconds, fn, ...) local thread = threadOf(fn); schedule(Mock.Now + (seconds or 0), thread, ...); return thread end
function task.wait(seconds)
    local thread = coroutine.running()
    if not thread or not coroutine.isyieldable() then fail("task.wait called outside a yieldable thread") end
    seconds = math.max(seconds or 0.03, 0.001)
    schedule(Mock.Now + seconds, thread, seconds)
    return coroutine.yield()
end
function task.cancel(thread) for i = #Queue, 1, -1 do if Queue[i].Thread == thread then table.remove(Queue, i) end end end
function Mock.advance(seconds)
    local target = Mock.Now + (seconds or 0)
    while true do
        local best, bestIndex
        for index, item in ipairs(Queue) do
            if item.At <= target and (not best or item.At < best.At or (item.At == best.At and item.Seq < best.Seq)) then best, bestIndex = item, index end
        end
        if not best then break end
        table.remove(Queue, bestIndex)
        Mock.Now = math.max(Mock.Now, best.At)
        if coroutine.status(best.Thread) == "suspended" then resume(best.Thread, table.unpack(best.Args, 1, best.Args.n)) end
    end
    Mock.Now = target
end

-- -----------------------------------------------------------------------------
-- Signals
-- -----------------------------------------------------------------------------
local SignalMeta = {__type = "RBXScriptSignal"}
SignalMeta.__index = SignalMeta
local function signal(name) return setmetatable({Name = name, Connections = {}, Waiting = {}}, SignalMeta) end
function SignalMeta:Connect(fn)
    if type(fn) ~= "function" then fail("Connect expects a function") end
    local connection = {Connected = true, Fn = fn}
    function connection.Disconnect(item) item.Connected = false end
    setmetatable(connection, {__type = "RBXScriptConnection"})
    table.insert(self.Connections, connection)
    return connection
end
SignalMeta.connect = SignalMeta.Connect
function SignalMeta:Wait()
    local thread = coroutine.running()
    if not thread or not coroutine.isyieldable() then fail(self.Name .. ":Wait called outside a yieldable thread") end
    table.insert(self.Waiting, thread)
    return coroutine.yield()
end
function SignalMeta:Fire(...)
    local list = table.clone(self.Connections)
    for _, connection in ipairs(list) do
        if connection.Connected then task.spawn(connection.Fn, ...) end
    end
    local waiting = self.Waiting
    self.Waiting = {}
    for _, thread in ipairs(waiting) do if coroutine.status(thread) == "suspended" then resume(thread, ...) end end
end
function SignalMeta:DisconnectAll() for _, connection in ipairs(self.Connections) do connection.Connected = false end; self.Connections = {} end
function SignalMeta:Count()
    local count = 0
    for _, connection in ipairs(self.Connections) do if connection.Connected then count = count + 1 end end
    return count
end

-- -----------------------------------------------------------------------------
-- Instances
-- -----------------------------------------------------------------------------
local GROUPS = {
    Instance = {props = {"Name", "Parent", "ClassName", "Archivable"}, readonly = {ClassName = true},
        events = {"Changed", "ChildAdded", "ChildRemoved", "DescendantAdded", "DescendantRemoving", "Destroying", "AncestryChanged"}},
    GuiBase2d = {props = {"AbsoluteSize", "AbsolutePosition", "AbsoluteRotation"}, readonly = {AbsoluteSize = true, AbsolutePosition = true, AbsoluteRotation = true}},
    GuiObject = {props = {"Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel", "ClipsDescendants",
        "LayoutOrder", "Position", "Rotation", "Selectable", "Size", "Visible", "ZIndex", "Interactable"},
        types = {Position = "UDim2", Size = "UDim2", AnchorPoint = "Vector2", BackgroundColor3 = "Color3", BackgroundTransparency = "number", Visible = "boolean",
            ZIndex = "number", LayoutOrder = "number", AutomaticSize = "EnumItem", Rotation = "number", BorderSizePixel = "number", Active = "boolean", ClipsDescendants = "boolean",
            Selectable = "boolean"},
        events = {"InputBegan", "InputChanged", "InputEnded", "MouseEnter", "MouseLeave", "MouseMoved", "TouchTap"}},
    Text = {props = {"Font", "RichText", "Text", "TextColor3", "TextScaled", "TextSize", "TextTransparency", "TextTruncate", "TextWrapped", "TextXAlignment",
        "TextYAlignment", "LineHeight", "TextStrokeTransparency", "ContentText", "TextBounds", "TextFits"},
        readonly = {ContentText = true, TextBounds = true, TextFits = true},
        types = {Font = "EnumItem", Text = "string", TextColor3 = "Color3", TextSize = "number", TextTransparency = "number", TextWrapped = "boolean", RichText = "boolean",
            TextXAlignment = "EnumItem", TextYAlignment = "EnumItem", TextTruncate = "EnumItem"}},
    TextBox = {props = {"ClearTextOnFocus", "CursorPosition", "MultiLine", "PlaceholderColor3", "PlaceholderText", "SelectionStart", "TextEditable", "ShowNativeInput"},
        types = {PlaceholderColor3 = "Color3", PlaceholderText = "string", MultiLine = "boolean", TextEditable = "boolean", ClearTextOnFocus = "boolean", CursorPosition = "number", SelectionStart = "number"},
        events = {"Focused", "FocusLost"}},
    GuiButton = {props = {"AutoButtonColor", "Modal", "Selected"}, types = {AutoButtonColor = "boolean"},
        events = {"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}},
    Image = {props = {"Image", "ImageColor3", "ImageRectOffset", "ImageRectSize", "ImageTransparency", "ScaleType", "SliceCenter", "ResampleMode"},
        types = {Image = "string", ImageColor3 = "Color3", ImageRectOffset = "Vector2", ImageRectSize = "Vector2", ScaleType = "EnumItem", ImageTransparency = "number"}},
    ScrollingFrame = {props = {"AbsoluteCanvasSize", "AbsoluteWindowSize", "AutomaticCanvasSize", "CanvasPosition", "CanvasSize", "ElasticBehavior", "ScrollBarImageColor3",
        "ScrollBarImageTransparency", "ScrollBarThickness", "ScrollingDirection", "ScrollingEnabled", "VerticalScrollBarInset"},
        readonly = {AbsoluteCanvasSize = true, AbsoluteWindowSize = true},
        types = {CanvasSize = "UDim2", CanvasPosition = "Vector2", ScrollBarImageColor3 = "Color3", ScrollingEnabled = "boolean", AutomaticCanvasSize = "EnumItem",
            ScrollingDirection = "EnumItem", ElasticBehavior = "EnumItem", ScrollBarThickness = "number"}},
    CanvasGroup = {props = {"GroupColor3", "GroupTransparency"}, types = {GroupTransparency = "number"}},
    ViewportFrame = {props = {"Ambient", "CurrentCamera", "ImageColor3", "ImageTransparency", "LightColor", "LightDirection"},
        types = {Ambient = "Color3", LightColor = "Color3", LightDirection = "Vector3", CurrentCamera = "Instance"}},
    LayerCollector = {props = {"Enabled", "ResetOnSpawn", "ZIndexBehavior"}, types = {Enabled = "boolean", ResetOnSpawn = "boolean", ZIndexBehavior = "EnumItem"}},
    ScreenGui = {props = {"DisplayOrder", "IgnoreGuiInset", "ScreenInsets"}, types = {DisplayOrder = "number", IgnoreGuiInset = "boolean"}},
    BillboardGui = {props = {"Adornee", "AlwaysOnTop", "Size", "StudsOffset", "MaxDistance"}, types = {Adornee = "Instance", Size = "UDim2"}},
    SurfaceGui = {props = {"Adornee", "Face", "AlwaysOnTop"}, types = {Adornee = "Instance"}},
    UICorner = {props = {"CornerRadius"}, types = {CornerRadius = "UDim"}},
    UIStroke = {props = {"ApplyStrokeMode", "Color", "Enabled", "LineJoinMode", "Thickness", "Transparency"}, types = {Color = "Color3", Thickness = "number", Transparency = "number"}},
    UIScale = {props = {"Scale"}, types = {Scale = "number"}},
    UIGradient = {props = {"Color", "Enabled", "Offset", "Rotation", "Transparency"}, types = {Color = "ColorSequence", Rotation = "number", Transparency = "NumberSequence"}},
    UIListLayout = {props = {"FillDirection", "HorizontalAlignment", "Padding", "SortOrder", "VerticalAlignment", "Wraps", "AbsoluteContentSize"},
        readonly = {AbsoluteContentSize = true}, types = {Padding = "UDim", FillDirection = "EnumItem", SortOrder = "EnumItem"}},
    UIGridLayout = {props = {"CellPadding", "CellSize", "FillDirection", "FillDirectionMaxCells", "HorizontalAlignment", "SortOrder", "StartCorner", "VerticalAlignment", "AbsoluteContentSize"},
        readonly = {AbsoluteContentSize = true}, types = {CellPadding = "UDim2", CellSize = "UDim2", FillDirectionMaxCells = "number"}},
    UIPadding = {props = {"PaddingBottom", "PaddingLeft", "PaddingRight", "PaddingTop"}, types = {PaddingBottom = "UDim", PaddingLeft = "UDim", PaddingRight = "UDim", PaddingTop = "UDim"}},
    UISizeConstraint = {props = {"MaxSize", "MinSize"}, types = {MaxSize = "Vector2", MinSize = "Vector2"}},
    BlurEffect = {props = {"Enabled", "Size"}, types = {Size = "number", Enabled = "boolean"}},
    Camera = {props = {"CFrame", "FieldOfView", "Focus", "CameraType", "CameraSubject"}, types = {CFrame = "CFrame", FieldOfView = "number", CameraType = "EnumItem", CameraSubject = "Instance"}},
    TextChatCommand = {props = {"Enabled", "PrimaryAlias", "SecondaryAlias", "AutocompleteVisible"}, types = {PrimaryAlias = "string"}, events = {"Triggered"}},
    PVInstance = {},
    BasePart = {props = {"Anchored", "CFrame", "Position", "Size", "CanCollide", "CanTouch", "CanQuery", "Massless", "Transparency", "LocalTransparencyModifier",
        "Color", "Material", "Reflectance", "RootPriority", "CollisionGroup", "CustomPhysicalProperties", "AssemblyLinearVelocity"},
        types = {Anchored = "boolean", CFrame = "CFrame", Position = "Vector3", Size = "Vector3", CanCollide = "boolean", CanTouch = "boolean", CanQuery = "boolean",
            Massless = "boolean", Transparency = "number", LocalTransparencyModifier = "number", Color = "Color3", Material = "EnumItem", Reflectance = "number",
            RootPriority = "number", CollisionGroup = "string"},
        events = {"Touched"}},
    MeshPart = {props = {"MeshId", "TextureID"}, readonly = {MeshId = true}, types = {TextureID = "string"}},
    Model = {props = {"PrimaryPart", "WorldPivot"}, types = {PrimaryPart = "Instance"}},
    Player = {props = {"UserId", "DisplayName", "Character"}, events = {"Chatted", "CharacterAdded", "CharacterRemoving", "CharacterAppearanceLoaded"}},
    Humanoid = {props = {"RigType", "Health", "MaxHealth", "HipHeight", "AutomaticScalingEnabled", "RequiresNeck", "DisplayName", "EvaluateStateMachine",
        "DisplayDistanceType", "HealthDisplayType", "BreakJointsOnDeath", "CameraOffset", "WalkSpeed"},
        types = {RigType = "EnumItem", Health = "number", MaxHealth = "number", HipHeight = "number", AutomaticScalingEnabled = "boolean", RequiresNeck = "boolean",
            DisplayName = "string", EvaluateStateMachine = "boolean", DisplayDistanceType = "EnumItem", HealthDisplayType = "EnumItem", BreakJointsOnDeath = "boolean",
            CameraOffset = "Vector3", WalkSpeed = "number"},
        events = {"Died", "StateChanged"}},
    HumanoidDescription = {props = {"BodyTypeScale", "DepthScale", "HeadScale", "HeightScale", "ProportionScale", "WidthScale",
        "Face", "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Shirt", "Pants", "GraphicTShirt",
        "ClimbAnimation", "FallAnimation", "IdleAnimation", "JumpAnimation", "RunAnimation", "SwimAnimation", "WalkAnimation", "MoodAnimation",
        "HeadColor", "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor", "TorsoColor",
        "HatAccessory", "HairAccessory", "FaceAccessory", "NeckAccessory", "ShouldersAccessory", "FrontAccessory", "BackAccessory", "WaistAccessory"},
        types = {}},
    Accessory = {props = {"AccessoryType", "AttachmentPoint"}, types = {AccessoryType = "EnumItem", AttachmentPoint = "CFrame"}},
    Attachment = {props = {"CFrame", "Position", "WorldCFrame", "WorldPosition", "Visible"}, readonly = {WorldCFrame = true, WorldPosition = true},
        types = {CFrame = "CFrame", Position = "Vector3", Visible = "boolean"}},
    JointInstance = {props = {"Part0", "Part1", "C0", "C1", "Enabled"}, types = {Part0 = "Instance", Part1 = "Instance", C0 = "CFrame", C1 = "CFrame", Enabled = "boolean"}},
    Motor6D = {props = {"Transform", "CurrentAngle", "DesiredAngle", "MaxVelocity"}, types = {Transform = "CFrame"}},
    WeldConstraint = {props = {"Part0", "Part1", "Enabled"}, types = {Part0 = "Instance", Part1 = "Instance", Enabled = "boolean"}},
    Constraint = {props = {"Attachment0", "Attachment1", "Enabled"}, types = {Attachment0 = "Instance", Attachment1 = "Instance", Enabled = "boolean"}},
    AnimationConstraint = {props = {"Transform"}, types = {Transform = "CFrame"}},
    Shirt = {props = {"ShirtTemplate"}, types = {ShirtTemplate = "string"}},
    Pants = {props = {"PantsTemplate"}, types = {PantsTemplate = "string"}},
    ShirtGraphic = {props = {"Graphic"}, types = {Graphic = "string"}},
    BodyColors = {props = {"HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3"},
        types = {HeadColor3 = "Color3", TorsoColor3 = "Color3", LeftArmColor3 = "Color3", RightArmColor3 = "Color3", LeftLegColor3 = "Color3", RightLegColor3 = "Color3"}},
    Decal = {props = {"Texture", "Face", "Color3", "Transparency", "LocalTransparencyModifier"}, types = {Texture = "string", Face = "EnumItem", Color3 = "Color3", Transparency = "number"}},
    Texture = {props = {"StudsPerTileU", "StudsPerTileV", "OffsetStudsU", "OffsetStudsV"}},
    DataModelMesh = {props = {"Scale", "Offset", "VertexColor"}, types = {Scale = "Vector3", Offset = "Vector3", VertexColor = "Vector3"}},
    SpecialMesh = {props = {"MeshId", "TextureId", "MeshType"}, types = {MeshId = "string", TextureId = "string", MeshType = "EnumItem"}},
    SurfaceAppearance = {props = {"ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap", "AlphaMode", "Color"}},
    WrapTarget = {props = {"CageMeshId", "CageOrigin", "ImportOrigin", "Stiffness"}},
    WrapLayer = {props = {"CageMeshId", "CageOrigin", "ImportOrigin", "ReferenceMeshId", "ReferenceOrigin", "BindOffset", "Order", "Puffiness", "Enabled", "AutoSkin"}},
    FaceControls = {},
    Effect = {props = {"Enabled", "Color"}},
    ParticleEmitter = {props = {"Texture", "Size", "Transparency", "Lifetime", "Speed", "Rate", "SpreadAngle", "Rotation", "RotSpeed", "LightEmission", "LightInfluence",
        "Drag", "Acceleration", "EmissionDirection", "Shape", "ZOffset"}, methods = {Emit = function(_, count) number(count, "ParticleEmitter:Emit") end}},
    Fire = {props = {"SecondaryColor", "Heat", "Size"}},
    Sparkles = {props = {"SparkleColor"}},
    Smoke = {props = {"Opacity", "RiseVelocity", "Size"}},
    Light = {props = {"Brightness", "Range", "Shadows", "Angle", "Face"}},
    Trail = {props = {"Attachment0", "Attachment1", "Transparency", "WidthScale", "Texture", "TextureLength", "TextureMode", "Lifetime", "MinLength", "MaxLength",
        "LightEmission", "LightInfluence", "Brightness", "FaceCamera"}},
    Beam = {props = {"Attachment0", "Attachment1", "Transparency", "Texture", "TextureLength", "TextureMode", "TextureSpeed", "Width0", "Width1", "CurveSize0",
        "CurveSize1", "Segments", "LightEmission", "LightInfluence", "Brightness", "FaceCamera", "ZOffset"}},
    Highlight = {props = {"Adornee", "DepthMode", "FillColor", "OutlineColor", "FillTransparency", "OutlineTransparency", "Enabled"},
        types = {Adornee = "Instance", DepthMode = "EnumItem", FillColor = "Color3", OutlineColor = "Color3", FillTransparency = "number", OutlineTransparency = "number"}},
    ValueBase = {props = {"Value"}},
    BaseScript = {props = {"Enabled", "Disabled"}, types = {Enabled = "boolean", Disabled = "boolean"}},
    Animation = {props = {"AnimationId"}, types = {AnimationId = "string"}},
    Animator = {},
    Tool = {props = {"RequiresHandle", "CanBeDropped", "Grip"}},
}
local CLASSES = {
    Folder = {groups = {}, isa = {}},
    Frame = {groups = {"GuiBase2d", "GuiObject"}, isa = {"GuiBase2d", "GuiObject"}},
    CanvasGroup = {groups = {"GuiBase2d", "GuiObject", "CanvasGroup"}, isa = {"GuiBase2d", "GuiObject"}},
    ScrollingFrame = {groups = {"GuiBase2d", "GuiObject", "ScrollingFrame"}, isa = {"GuiBase2d", "GuiObject"}},
    TextLabel = {groups = {"GuiBase2d", "GuiObject", "Text"}, isa = {"GuiBase2d", "GuiObject", "GuiLabel"}},
    TextButton = {groups = {"GuiBase2d", "GuiObject", "Text", "GuiButton"}, isa = {"GuiBase2d", "GuiObject", "GuiButton"}},
    TextBox = {groups = {"GuiBase2d", "GuiObject", "Text", "TextBox"}, isa = {"GuiBase2d", "GuiObject"}},
    ImageLabel = {groups = {"GuiBase2d", "GuiObject", "Image"}, isa = {"GuiBase2d", "GuiObject", "GuiLabel"}},
    ImageButton = {groups = {"GuiBase2d", "GuiObject", "Image", "GuiButton"}, isa = {"GuiBase2d", "GuiObject", "GuiButton"}},
    ViewportFrame = {groups = {"GuiBase2d", "GuiObject", "ViewportFrame"}, isa = {"GuiBase2d", "GuiObject"}},
    ScreenGui = {groups = {"GuiBase2d", "LayerCollector", "ScreenGui"}, isa = {"GuiBase2d", "LayerCollector"}},
    BillboardGui = {groups = {"LayerCollector", "BillboardGui"}, isa = {"LayerCollector"}},
    SurfaceGui = {groups = {"LayerCollector", "SurfaceGui"}, isa = {"LayerCollector"}},
    UICorner = {groups = {"UICorner"}, isa = {"UIComponent"}},
    UIStroke = {groups = {"UIStroke"}, isa = {"UIComponent"}},
    UIScale = {groups = {"UIScale"}, isa = {"UIComponent"}},
    UIGradient = {groups = {"UIGradient"}, isa = {"UIComponent"}},
    UIListLayout = {groups = {"UIListLayout"}, isa = {"UIComponent", "UILayout", "UIGridStyleLayout"}},
    UIGridLayout = {groups = {"UIGridLayout"}, isa = {"UIComponent", "UILayout", "UIGridStyleLayout"}},
    UIPadding = {groups = {"UIPadding"}, isa = {"UIComponent"}},
    UISizeConstraint = {groups = {"UISizeConstraint"}, isa = {"UIComponent", "UIConstraint"}},
    BlurEffect = {groups = {"BlurEffect"}, isa = {"PostEffect"}},
    WorldModel = {groups = {"PVInstance", "Model"}, isa = {"WorldRoot", "Model", "PVInstance"}},
    Camera = {groups = {"Camera"}, isa = {}},
    TextChatCommand = {groups = {"TextChatCommand"}, isa = {}},
    Model = {groups = {"PVInstance", "Model"}, isa = {"PVInstance"}},
    Part = {groups = {"PVInstance", "BasePart"}, isa = {"BasePart", "PVInstance", "FormFactorPart"}},
    MeshPart = {groups = {"PVInstance", "BasePart", "MeshPart"}, isa = {"BasePart", "PVInstance", "TriangleMeshPart"}},
    Humanoid = {groups = {"Humanoid"}, isa = {}},
    HumanoidDescription = {groups = {"HumanoidDescription"}, isa = {}},
    Accessory = {groups = {"Accessory"}, isa = {"Accoutrement"}},
    Attachment = {groups = {"Attachment"}, isa = {}},
    Bone = {groups = {"Attachment"}, isa = {"Attachment"}},
    Motor6D = {groups = {"JointInstance", "Motor6D"}, isa = {"JointInstance"}},
    Weld = {groups = {"JointInstance"}, isa = {"JointInstance"}},
    WeldConstraint = {groups = {"WeldConstraint"}, isa = {}},
    AnimationConstraint = {groups = {"Constraint", "AnimationConstraint"}, isa = {"Constraint"}},
    RigidConstraint = {groups = {"Constraint"}, isa = {"Constraint"}},
    Shirt = {groups = {"Shirt"}, isa = {"Clothing", "CharacterAppearance"}},
    Pants = {groups = {"Pants"}, isa = {"Clothing", "CharacterAppearance"}},
    ShirtGraphic = {groups = {"ShirtGraphic"}, isa = {"CharacterAppearance"}},
    BodyColors = {groups = {"BodyColors"}, isa = {"CharacterAppearance"}},
    Decal = {groups = {"Decal"}, isa = {"FaceInstance"}},
    Texture = {groups = {"Decal", "Texture"}, isa = {"Decal", "FaceInstance"}},
    SpecialMesh = {groups = {"DataModelMesh", "SpecialMesh"}, isa = {"FileMesh", "DataModelMesh"}},
    BlockMesh = {groups = {"DataModelMesh"}, isa = {"BevelMesh", "DataModelMesh"}},
    CylinderMesh = {groups = {"DataModelMesh"}, isa = {"BevelMesh", "DataModelMesh"}},
    SurfaceAppearance = {groups = {"SurfaceAppearance"}, isa = {}},
    WrapTarget = {groups = {"WrapTarget"}, isa = {"BaseWrap"}},
    WrapLayer = {groups = {"WrapLayer"}, isa = {"BaseWrap"}},
    FaceControls = {groups = {"FaceControls"}, isa = {}},
    ParticleEmitter = {groups = {"Effect", "ParticleEmitter"}, isa = {}},
    Fire = {groups = {"Effect", "Fire"}, isa = {}},
    Sparkles = {groups = {"Effect", "Sparkles"}, isa = {}},
    Smoke = {groups = {"Effect", "Smoke"}, isa = {}},
    PointLight = {groups = {"Effect", "Light"}, isa = {"Light"}},
    SpotLight = {groups = {"Effect", "Light"}, isa = {"Light"}},
    SurfaceLight = {groups = {"Effect", "Light"}, isa = {"Light"}},
    Trail = {groups = {"Effect", "Trail"}, isa = {}},
    Beam = {groups = {"Effect", "Beam"}, isa = {}},
    Highlight = {groups = {"Highlight"}, isa = {}},
    NumberValue = {groups = {"ValueBase"}, isa = {"ValueBase"}},
    StringValue = {groups = {"ValueBase"}, isa = {"ValueBase"}},
    Vector3Value = {groups = {"ValueBase"}, isa = {"ValueBase"}},
    IntValue = {groups = {"ValueBase"}, isa = {"ValueBase"}},
    LocalScript = {groups = {"BaseScript"}, isa = {"Script", "BaseScript", "LuaSourceContainer"}},
    Script = {groups = {"BaseScript"}, isa = {"BaseScript", "LuaSourceContainer"}},
    ModuleScript = {groups = {}, isa = {"LuaSourceContainer"}},
    Animation = {groups = {"Animation"}, isa = {}},
    Animator = {groups = {"Animator"}, isa = {}},
    Tool = {groups = {"Tool"}, isa = {"BackpackItem"}},
    Player = {groups = {"Player"}, isa = {}, internal = true},
    PlayerGui = {groups = {}, isa = {"BasePlayerGui"}, internal = true},
    Backpack = {groups = {}, isa = {}, internal = true},
    Service = {groups = {}, isa = {}, internal = true},
}
local DEFAULTS = {
    Name = nil, Archivable = true, Visible = true, Active = false, AnchorPoint = Vector2.new(), AutomaticSize = Enum.AutomaticSize.None,
    BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, BorderSizePixel = 1, ClipsDescendants = false, LayoutOrder = 0,
    Position = UDim2.new(), Rotation = 0, Selectable = false, Size = UDim2.new(), ZIndex = 1, Interactable = true,
    Font = Enum.Font.SourceSans, RichText = false, Text = "", TextColor3 = Color3.new(0, 0, 0), TextScaled = false, TextSize = 14, TextTransparency = 0,
    TextTruncate = Enum.TextTruncate.None, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
    ClearTextOnFocus = true, CursorPosition = -1, MultiLine = false, PlaceholderColor3 = Color3.new(0.7, 0.7, 0.7), PlaceholderText = "", SelectionStart = -1, TextEditable = true,
    AutoButtonColor = true, Image = "", ImageColor3 = Color3.new(1, 1, 1), ImageRectOffset = Vector2.new(), ImageRectSize = Vector2.new(), ImageTransparency = 0, ScaleType = Enum.ScaleType.Stretch,
    AutomaticCanvasSize = Enum.AutomaticSize.None, CanvasPosition = Vector2.new(), CanvasSize = UDim2.new(0, 0, 2, 0), ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
    ScrollBarImageColor3 = Color3.new(1, 1, 1), ScrollBarThickness = 12, ScrollingDirection = Enum.ScrollingDirection.XY, ScrollingEnabled = true,
    GroupTransparency = 0, DisplayOrder = 0, Enabled = true, IgnoreGuiInset = false, ResetOnSpawn = true, ZIndexBehavior = Enum.ZIndexBehavior.Global,
    CornerRadius = UDim.new(0, 8), Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0, Scale = 1, Padding = UDim.new(), FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.Name, CellSize = UDim2.fromOffset(100, 100), CellPadding = UDim2.fromOffset(5, 5), FillDirectionMaxCells = 0,
    PaddingTop = UDim.new(), PaddingBottom = UDim.new(), PaddingLeft = UDim.new(), PaddingRight = UDim.new(), FieldOfView = 70, CFrame = CFrame.new(),
    CameraType = Enum.CameraType.Custom, Anchored = false, PrimaryAlias = "", SecondaryAlias = "",
    CanCollide = true, CanTouch = true, CanQuery = true, Massless = false, LocalTransparencyModifier = 0, Material = Enum.Material.Plastic, Reflectance = 0,
    RootPriority = 0, CollisionGroup = "Default", MeshId = "", TextureID = "", TextureId = "",
    RigType = Enum.HumanoidRigType.R15, Health = 100, MaxHealth = 100, HipHeight = 2, AutomaticScalingEnabled = true, RequiresNeck = true, DisplayName = "",
    EvaluateStateMachine = true, BreakJointsOnDeath = true, CameraOffset = Vector3.new(), WalkSpeed = 16,
    AccessoryType = Enum.AccessoryType.Unknown, AttachmentPoint = CFrame.new(), C0 = CFrame.new(), C1 = CFrame.new(), Transform = CFrame.new(),
    ShirtTemplate = "", PantsTemplate = "", Graphic = "", AnimationId = "",
    Face = Enum.NormalId.Front, Color3 = Color3.new(1, 1, 1),
    MeshType = Enum.MeshType.Head, Offset = Vector3.new(), VertexColor = Vector3.new(1, 1, 1),
    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, FillColor = Color3.new(1, 0, 0), OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.5, OutlineTransparency = 0,
}
local DESCRIPTION_DEFAULTS = {BodyTypeScale = 0.3, DepthScale = 1, HeadScale = 1, HeightScale = 1, ProportionScale = 1, WidthScale = 1}
local DESCRIPTION_COLORS = {HeadColor = true, LeftArmColor = true, RightArmColor = true, LeftLegColor = true, RightLegColor = true, TorsoColor = true}
local DESCRIPTION_STRINGS = {HatAccessory = true, HairAccessory = true, FaceAccessory = true, NeckAccessory = true, ShouldersAccessory = true,
    FrontAccessory = true, BackAccessory = true, WaistAccessory = true}

local Data = setmetatable({}, {__mode = "k"})
local InstanceMeta = {__type = "Instance"}
local SCREEN = Vector2.new(1280, 720)
Mock.Screen = SCREEN
local Methods = {}
local function info(instance) return Data[instance] end
local function groupsOf(className) local list = {"Instance"}; for _, name in ipairs(CLASSES[className].groups) do table.insert(list, name) end; return list end
local function memberOf(className, key)
    for _, groupName in ipairs(groupsOf(className)) do
        local group = GROUPS[groupName]
        if group.methods and group.methods[key] then return "method", group end
        if group.props then for _, prop in ipairs(group.props) do if prop == key then return "prop", group end end end
        if group.events then for _, event in ipairs(group.events) do if event == key then return "event", group end end end
    end
    return nil
end
local function isA(instance, className)
    local data = info(instance)
    if data.ClassName == className or className == "Instance" then return true end
    return table.find(CLASSES[data.ClassName].isa, className) ~= nil
end
local function isGui(instance) return instance ~= nil and info(instance) ~= nil and isA(instance, "GuiBase2d") end
local absoluteSize, absolutePosition
local function scaleOf(instance)
    local data = info(instance)
    for _, child in ipairs(data.Children) do if info(child).ClassName == "UIScale" then return info(child).Props.Scale end end
    return 1
end
function absoluteSize(instance)
    local data = info(instance)
    if data.ClassName == "ScreenGui" then return SCREEN end
    local parent = data.Parent
    if not isGui(parent) or not data.Props.Size then return Vector2.new() end
    local base = absoluteSize(parent)
    local size = data.Props.Size
    local result = Vector2.new(size.X.Scale * base.X + size.X.Offset, size.Y.Scale * base.Y + size.Y.Offset)
    return result * scaleOf(instance)
end
function absolutePosition(instance)
    local data = info(instance)
    if data.ClassName == "ScreenGui" then return Vector2.new() end
    local parent = data.Parent
    if not isGui(parent) or not data.Props.Position then return Vector2.new() end
    local base, size = absolutePosition(parent), absoluteSize(parent)
    local position = data.Props.Position
    local anchor = data.Props.AnchorPoint or Vector2.new()
    local own = absoluteSize(instance)
    return base + Vector2.new(position.X.Scale * size.X + position.X.Offset, position.Y.Scale * size.Y + position.Y.Offset) - Vector2.new(anchor.X * own.X, anchor.Y * own.Y)
end

local newInstance
function newInstance(className, internal)
    local class = CLASSES[className]
    if not class or (class.internal and not internal) then fail("Unable to create an Instance of type \"" .. tostring(className) .. "\"") end
    local instance = setmetatable({}, InstanceMeta)
    local props = {}
    for _, groupName in ipairs(groupsOf(className)) do
        for _, prop in ipairs(GROUPS[groupName].props or {}) do
            local default = DEFAULTS[prop]
            if default ~= nil then props[prop] = default end
        end
    end
    if className == "BlurEffect" then props.Size = 24 end
    if className == "UIStroke" then props.Color = Color3.new(0, 0, 0) end
    if CLASSES[className].groups[#CLASSES[className].groups] == "GuiButton" then props.Active = true end
    if className == "Part" or className == "MeshPart" then props.Size = Vector3.new(4, 1, 2); props.Color = Color3.new(0.64, 0.64, 0.64) end
    if className == "HumanoidDescription" then
        for _, prop in ipairs(GROUPS.HumanoidDescription.props) do
            props[prop] = DESCRIPTION_DEFAULTS[prop] or (DESCRIPTION_COLORS[prop] and Color3.new(1, 1, 1)) or (DESCRIPTION_STRINGS[prop] and "") or 0
        end
    end
    if className == "ParticleEmitter" then
        props.Color = ColorSequence.new(Color3.new(1, 1, 1)); props.Size = NumberSequence.new(1); props.Transparency = NumberSequence.new(0)
        props.Lifetime = NumberRange.new(5, 10); props.Speed = NumberRange.new(5); props.Rotation = NumberRange.new(0); props.RotSpeed = NumberRange.new(0)
        props.Rate = 20; props.SpreadAngle = Vector2.new(); props.LightEmission = 0; props.LightInfluence = 0; props.Drag = 0; props.Acceleration = Vector3.new()
        props.EmissionDirection = Enum.NormalId.Top; props.Shape = Enum.ParticleEmitterShape.Box; props.ZOffset = 0; props.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    end
    if className == "NumberValue" or className == "IntValue" then props.Value = 0 elseif className == "StringValue" then props.Value = "" elseif className == "Vector3Value" then props.Value = Vector3.new() end
    props.Name = className
    Data[instance] = {ClassName = className, Props = props, Children = {}, Signals = {}, PropSignals = {}, Parent = nil, Destroyed = false, Attributes = {}, Extra = {}}
    if className == "HumanoidDescription" then Data[instance].Accessories = {}; Data[instance].Emotes = {}; Data[instance].Equipped = {} end
    return instance
end
local function signalFor(instance, name)
    local data = info(instance)
    data.Signals[name] = data.Signals[name] or signal(name)
    return data.Signals[name]
end
local function setParent(instance, parent)
    local data = info(instance)
    if data.Destroyed then fail("The Parent property of " .. data.Props.Name .. " is locked, current parent: NULL, new parent " .. tostring(parent and info(parent).Props.Name)) end
    if parent ~= nil and typeof(parent) ~= "Instance" then fail("Parent expects an Instance, got " .. typeof(parent)) end
    if parent == instance then fail("Attempt to set " .. data.Props.Name .. " as its own parent") end
    if parent and info(parent).Destroyed then fail("Attempt to parent to a destroyed instance") end
    local cursor = parent
    while cursor do if cursor == instance then fail("Attempt to set parent of " .. data.Props.Name .. " to one of its descendants") end; cursor = info(cursor).Parent end
    local old = data.Parent
    if old == parent then return end
    data.Parent = parent
    if old then
        local siblings = info(old).Children
        local index = table.find(siblings, instance)
        if index then table.remove(siblings, index) end
        signalFor(old, "ChildRemoved"):Fire(instance)
    end
    if parent then
        table.insert(info(parent).Children, instance)
        signalFor(parent, "ChildAdded"):Fire(instance)
        local ancestor = parent
        while ancestor do
            local ancestorData = info(ancestor)
            if ancestorData.Signals.DescendantAdded then
                ancestorData.Signals.DescendantAdded:Fire(instance)
                for _, item in ipairs(Methods.GetDescendants(instance)) do ancestorData.Signals.DescendantAdded:Fire(item) end
            end
            ancestor = ancestorData.Parent
        end
    end
    signalFor(instance, "AncestryChanged"):Fire(instance, parent)
end

-- Position follows CFrame on parts and attachments, as in Roblox.
local function getProp(instance, data, key)
    if key == "Position" and (isA(instance, "BasePart") or isA(instance, "Attachment")) then return data.Props.CFrame.Position end
    if key == "WorldCFrame" or key == "WorldPosition" then
        local parent = data.Parent
        local world = (parent and isA(parent, "BasePart")) and parent.CFrame * data.Props.CFrame or data.Props.CFrame
        return key == "WorldCFrame" and world or world.Position
    end
    return data.Props[key]
end

InstanceMeta.__index = function(instance, key)
    local data = info(instance)
    if Methods[key] then return Methods[key] end
    if key == "Parent" then return data.Parent end
    if key == "ClassName" then return data.ClassName end
    if key == "AbsoluteSize" or key == "AbsoluteWindowSize" or key == "AbsoluteCanvasSize" then
        if not isA(instance, "GuiBase2d") then fail(key .. " is not a valid member of " .. data.ClassName) end
        return absoluteSize(instance)
    end
    if key == "AbsolutePosition" then return absolutePosition(instance) end
    if data.ClassName == "Service" or data.ClassName == "Player" or data.ClassName == "PlayerGui" or data.ClassName == "Backpack" then
        if data.Props[key] ~= nil then return data.Props[key] end
        if data.Extra[key] ~= nil then return data.Extra[key] end
        if data.Signals[key] then return data.Signals[key] end
    end
    local kind, group = memberOf(data.ClassName, key)
    if kind == "method" then return group.methods[key] end
    if kind == "prop" then return getProp(instance, data, key) end
    if kind == "event" then return signalFor(instance, key) end
    for _, child in ipairs(data.Children) do if info(child).Props.Name == key then return child end end
    fail(tostring(key) .. " is not a valid member of " .. data.ClassName .. " \"" .. tostring(data.Props.Name) .. "\"")
end
local SETTERS = {}
InstanceMeta.__newindex = function(instance, key, value)
    local data = info(instance)
    if key == "Parent" then setParent(instance, value); return end
    if data.ClassName == "Player" and key == "Character" then data.Props.Character = value; return end
    local kind, group = memberOf(data.ClassName, key)
    if kind ~= "prop" then fail(tostring(key) .. " is not a valid member of " .. data.ClassName) end
    if group.readonly and group.readonly[key] then fail("Unable to assign property " .. key .. ". Property is read only") end
    local expected = group.types and group.types[key]
    if expected == "Instance" and value == nil then expected = nil end
    if expected and typeof(value) ~= expected and not (expected == "string" and type(value) == "number") then
        fail("Unable to assign property " .. key .. ". " .. expected .. " expected, got " .. typeof(value))
    end
    if expected == "string" and type(value) == "number" then value = tostring(value) end
    if key == "Font" and value.EnumType ~= "Font" then fail("Font expects Enum.Font") end
    if group == GROUPS.HumanoidDescription then
        if DESCRIPTION_COLORS[key] then expect(value, "Color3", "HumanoidDescription." .. key)
        elseif DESCRIPTION_STRINGS[key] then if type(value) ~= "string" then fail("HumanoidDescription." .. key .. " expects a string") end
        elseif type(value) ~= "number" then fail("HumanoidDescription." .. key .. " expects a number") end
    end
    if key == "Position" and (isA(instance, "BasePart") or isA(instance, "Attachment")) then
        key = "CFrame"; value = data.Props.CFrame.Rotation + value
    end
    local setter = SETTERS[key]
    if setter then value = setter(instance, data, value) end
    local old = data.Props[key]
    data.Props[key] = value
    if old ~= value then
        local propSignal = data.PropSignals[key]
        if propSignal then propSignal:Fire() end
        local changed = data.Signals.Changed
        if changed then changed:Fire(key) end
    end
end
InstanceMeta.__tostring = function(instance) return tostring(info(instance).Props.Name) end

-- Humanoid.Health at 0 fires Died once, like a real death.
function SETTERS.Health(instance, data, value)
    if data.ClassName == "Humanoid" then
        value = math.clamp(value, 0, data.Props.MaxHealth)
        if value <= 0 and not data.Dead then data.Dead = true; task.defer(function() signalFor(instance, "Died"):Fire() end) end
    end
    return value
end

function Methods.IsA(instance, className) return isA(instance, className) end
function Methods.FindFirstChild(instance, name, recursive)
    for _, child in ipairs(info(instance).Children) do if info(child).Props.Name == name then return child end end
    if recursive then
        for _, child in ipairs(info(instance).Children) do local found = Methods.FindFirstChild(child, name, true); if found then return found end end
    end
    return nil
end
function Methods.FindFirstChildOfClass(instance, className)
    for _, child in ipairs(info(instance).Children) do if info(child).ClassName == className then return child end end
    return nil
end
function Methods.FindFirstChildWhichIsA(instance, className, recursive)
    for _, child in ipairs(info(instance).Children) do if isA(child, className) then return child end end
    if recursive then
        for _, child in ipairs(info(instance).Children) do local found = Methods.FindFirstChildWhichIsA(child, className, true); if found then return found end end
    end
    return nil
end
function Methods.FindFirstAncestorOfClass(instance, className)
    local parent = info(instance).Parent
    while parent do if info(parent).ClassName == className then return parent end; parent = info(parent).Parent end
    return nil
end
function Methods.FindFirstAncestorWhichIsA(instance, className)
    local parent = info(instance).Parent
    while parent do if isA(parent, className) then return parent end; parent = info(parent).Parent end
    return nil
end
function Methods.WaitForChild(instance, name) return Methods.FindFirstChild(instance, name) end
function Methods.GetChildren(instance) return table.clone(info(instance).Children) end
function Methods.GetDescendants(instance)
    local result = {}
    local function walk(item) for _, child in ipairs(info(item).Children) do table.insert(result, child); walk(child) end end
    walk(instance)
    return result
end
function Methods.IsDescendantOf(instance, ancestor)
    local parent = info(instance).Parent
    while parent do if parent == ancestor then return true end; parent = info(parent).Parent end
    return false
end
function Methods.IsAncestorOf(instance, descendant) return Methods.IsDescendantOf(descendant, instance) end
function Methods.GetPropertyChangedSignal(instance, prop)
    local data = info(instance)
    local known = prop == "AbsoluteSize" or prop == "AbsolutePosition" or memberOf(data.ClassName, prop) == "prop"
    if not known then fail(tostring(prop) .. " is not a valid property name.") end
    data.PropSignals[prop] = data.PropSignals[prop] or signal(prop)
    return data.PropSignals[prop]
end
function Methods.Destroy(instance)
    local data = info(instance)
    if data.Destroyed then return end
    signalFor(instance, "Destroying"):Fire()
    for _, child in ipairs(table.clone(data.Children)) do Methods.Destroy(child) end
    local parent = data.Parent
    data.Parent = nil
    data.Destroyed = true
    if parent then
        local siblings = info(parent).Children
        local index = table.find(siblings, instance)
        if index then table.remove(siblings, index) end
        signalFor(parent, "ChildRemoved"):Fire(instance)
    end
    for _, item in pairs(data.Signals) do item:DisconnectAll() end
    for _, item in pairs(data.PropSignals) do item:DisconnectAll() end
end
function Methods.ClearAllChildren(instance) for _, child in ipairs(table.clone(info(instance).Children)) do Methods.Destroy(child) end end
function Methods.GetAttribute(instance, name) return info(instance).Attributes[name] end
function Methods.SetAttribute(instance, name, value)
    local kind = typeof(value)
    if value ~= nil and kind ~= "string" and kind ~= "number" and kind ~= "boolean" and kind ~= "Vector3" and kind ~= "Color3" and kind ~= "CFrame" and kind ~= "UDim2" then
        fail("SetAttribute: " .. kind .. " is not a supported attribute type")
    end
    info(instance).Attributes[name] = value
end
function Methods.GetFullName(instance)
    local names, item = {}, instance
    while item do table.insert(names, 1, tostring(info(item).Props.Name)); item = info(item).Parent end
    return table.concat(names, ".")
end
function Methods.CaptureFocus(instance)
    if info(instance).ClassName ~= "TextBox" then fail("CaptureFocus is not a valid member") end
    Mock.Focused = instance
    signalFor(instance, "Focused"):Fire()
end
function Methods.ReleaseFocus(instance, submitted)
    if Mock.Focused == instance then Mock.Focused = nil end
    signalFor(instance, "FocusLost"):Fire(submitted == true)
end
-- Clone follows Archivable: a non-archivable instance clones to nil and its children are skipped.
-- References between instances inside the copy (joint parts, attachments) point at the copies.
local function cloneTree(instance, map)
    local data = info(instance)
    if not data.Props.Archivable then return nil end
    local copy = newInstance(data.ClassName, true)
    local copyData = info(copy)
    for key, value in pairs(data.Props) do copyData.Props[key] = value end
    for key, value in pairs(data.Attributes) do copyData.Attributes[key] = value end
    if data.Accessories then copyData.Accessories = table.clone(data.Accessories); copyData.Emotes = table.clone(data.Emotes); copyData.Equipped = table.clone(data.Equipped) end
    map[instance] = copy
    for _, child in ipairs(data.Children) do
        local childCopy = cloneTree(child, map)
        if childCopy then info(childCopy).Parent = copy; table.insert(copyData.Children, childCopy) end
    end
    return copy
end
function Methods.Clone(instance)
    local map = {}
    local copy = cloneTree(instance, map)
    for _, target in pairs(map) do
        local props = info(target).Props
        for key, value in pairs(props) do
            if typeof(value) == "Instance" and map[value] then props[key] = map[value] end
        end
    end
    return copy
end

local Instance = {new = function(className, parent)
    local instance = newInstance(className)
    if parent ~= nil then instance.Parent = parent end
    return instance
end}
Mock.newInstance = newInstance
Mock.info = info
Mock.signalFor = signalFor

-- Model, part and character methods -----------------------------------------------------------
local function bodyParts(model)
    local list = {}
    for _, item in ipairs(Methods.GetDescendants(model)) do if isA(item, "BasePart") then table.insert(list, item) end end
    return list
end
GROUPS.Model.methods = {
    GetBoundingBox = function(model)
        local parts = bodyParts(model)
        if #parts == 0 then return CFrame.new(), Vector3.new() end
        local low, high
        for _, part in ipairs(parts) do
            local p, half = part.CFrame.Position, part.Size / 2
            local a, b = p - half, p + half
            low = low and Vector3.new(math.min(low.X, a.X), math.min(low.Y, a.Y), math.min(low.Z, a.Z)) or a
            high = high and Vector3.new(math.max(high.X, b.X), math.max(high.Y, b.Y), math.max(high.Z, b.Z)) or b
        end
        return CFrame.new((low + high) / 2), high - low
    end,
    GetPivot = function(model) local root = model:FindFirstChild("HumanoidRootPart"); return root and root.CFrame or CFrame.new() end,
    PivotTo = function(model, target)
        expect(target, "CFrame", "Model:PivotTo")
        local offset = target * Methods.FindFirstChild(model, "HumanoidRootPart").CFrame:Inverse()
        for _, part in ipairs(bodyParts(model)) do part.CFrame = offset * part.CFrame end
    end,
}
GROUPS.MeshPart.methods = {
    ApplyMesh = function(target, source)
        expect(source, "Instance", "MeshPart:ApplyMesh")
        if info(source).ClassName ~= "MeshPart" then fail("ApplyMesh expects a MeshPart") end
        if info(target).Props.Name == "RejectsApplyMesh" or info(target).Attributes.MockRejectApplyMesh then fail("ApplyMesh is not allowed on this part") end
        info(target).Props.MeshId = info(source).Props.MeshId
        target.Size = source.Size
    end,
}

-- HumanoidDescription: accessories and emotes are stored next to the instance data.
GROUPS.HumanoidDescription.methods = {
    GetAccessories = function(desc, includeRigid)
        if type(includeRigid) ~= "boolean" then fail("GetAccessories expects includeRigidAccessories") end
        local list = {}
        for _, row in ipairs(info(desc).Accessories) do table.insert(list, table.clone(row)) end
        return list
    end,
    SetAccessories = function(desc, list, includeRigid)
        if type(includeRigid) ~= "boolean" then fail("SetAccessories expects includeRigidAccessories") end
        local stored = {}
        for _, row in ipairs(list) do
            if type(row.AssetId) ~= "number" then fail("SetAccessories: AssetId must be a number") end
            expect(row.AccessoryType, "EnumItem", "SetAccessories AccessoryType")
            if row.IsLayered and type(row.Order) ~= "number" then fail("SetAccessories: layered accessories need an Order") end
            table.insert(stored, table.clone(row))
        end
        info(desc).Accessories = stored
    end,
    GetEmotes = function(desc) local copy = {}; for name, ids in pairs(info(desc).Emotes) do copy[name] = table.clone(ids) end; return copy end,
    SetEmotes = function(desc, emotes)
        if type(emotes) ~= "table" then fail("SetEmotes expects a table") end
        local copy = {}
        for name, ids in pairs(emotes) do
            if type(name) ~= "string" or type(ids) ~= "table" then fail("SetEmotes: invalid entry") end
            copy[name] = table.clone(ids)
        end
        info(desc).Emotes = copy
    end,
    GetEquippedEmotes = function(desc) local copy = {}; for _, row in ipairs(info(desc).Equipped) do table.insert(copy, table.clone(row)) end; return copy end,
    SetEquippedEmotes = function(desc, list)
        local emotes = info(desc).Emotes
        for _, row in ipairs(list) do
            if type(row.Name) ~= "string" or type(row.Slot) ~= "number" then fail("SetEquippedEmotes: invalid entry") end
            if not emotes[row.Name] then fail("SetEquippedEmotes: " .. row.Name .. " is not one of the description's emotes") end
        end
        local copy = {}
        for _, row in ipairs(list) do table.insert(copy, table.clone(row)) end
        info(desc).Equipped = copy
    end,
}

GROUPS.Humanoid.methods = {
    GetAppliedDescription = function(hum)
        local current = Methods.FindFirstChildOfClass(hum, "HumanoidDescription")
        return current and Methods.Clone(current) or newInstance("HumanoidDescription", true)
    end,
    -- Welds the Handle's attachment to the body attachment of the same name, as Roblox does.
    AddAccessory = function(hum, accessory)
        expect(accessory, "Instance", "Humanoid:AddAccessory")
        local character = info(hum).Parent
        if accessory.Parent ~= nil and accessory.Parent ~= character then Mock.Warnings[#Mock.Warnings + 1] = "AddAccessory: already being worn by another character" end
        accessory.Parent = character
        local handle = Methods.FindFirstChild(accessory, "Handle")
        local at = handle and Methods.FindFirstChildOfClass(handle, "Attachment")
        if not at then return end
        for _, part in ipairs(Methods.GetChildren(character)) do
            local target = isA(part, "BasePart") and Methods.FindFirstChild(part, at.Name)
            if target and isA(target, "Attachment") then
                local weld = newInstance("Weld", true); weld.Name = "AccessoryWeld"
                weld.Part0 = handle; weld.Part1 = part; weld.C0 = at.CFrame; weld.C1 = target.CFrame; weld.Parent = handle
                handle.CFrame = part.CFrame * target.CFrame * at.CFrame:Inverse()
                return
            end
        end
    end,
    PlayEmote = function(hum, name)
        local desc = Methods.FindFirstChildOfClass(hum, "HumanoidDescription")
        Mock.PlayedEmote = name
        return desc ~= nil and info(desc).Emotes[name] ~= nil
    end,
}

-- Animations: tracks report a length right away, as if the asset loaded instantly.
local function newTrack(animator, animation)
    local track = {Animation = animation, Length = 1, IsPlaying = false, Stopped = signal("Stopped")}
    function track.Play(self) self.IsPlaying = true; table.insert(info(animator).Tracks, self) end
    function track.Stop(self) self.IsPlaying = false; local tracks = info(animator).Tracks; local i = table.find(tracks, self); if i then table.remove(tracks, i) end end
    function track.Destroy(self) self:Stop() end
    function track.AdjustSpeed() end
    return setmetatable(track, {__type = "Instance"})
end
GROUPS.Animator.methods = {
    LoadAnimation = function(animator, animation)
        expect(animation, "Instance", "Animator:LoadAnimation")
        if info(animation).ClassName ~= "Animation" then fail("LoadAnimation expects an Animation") end
        info(animator).Tracks = info(animator).Tracks or {}
        return newTrack(animator, animation)
    end,
    GetPlayingAnimationTracks = function(animator) return table.clone(info(animator).Tracks or {}) end,
}

-- -----------------------------------------------------------------------------
-- Fake Roblox web: users, avatars and catalog.
-- -----------------------------------------------------------------------------
Mock.Users = {
    {Id = 1, Name = "LyraTester", DisplayName = "Lyra Tester", Avatar = {Head = 0, Face = 0, Shirt = 0, Pants = 0, Accessories = {}}},
    {Id = 156, Name = "Builderman", DisplayName = "Builderman", Avatar = {Head = 0, Face = 7699174, Shirt = 1, Pants = 2,
        IdleAnimation = 2510235063, WalkAnimation = 2510202577,
        Accessories = {{AssetId = 1028606, AccessoryType = "Hat"}, {AssetId = 6340213, AccessoryType = "Hair"}}, Emotes = {Wave = {3576686446}}}},
    {Id = 2207291, Name = "Korbloxian", DisplayName = "Korb", Avatar = {RightLeg = 139607718, Face = 0, Accessories = {{AssetId = 48474313, AccessoryType = "Back"}}}},
}
Mock.Catalog = {
    [1028606] = {Name = "Red Baseball Cap", AssetTypeId = 8, Price = 75, Creator = "Roblox"},
    [6340213] = {Name = "Messy Hair", AssetTypeId = 41, Price = 50, Creator = "Roblox"},
    [48474313] = {Name = "Red Sparkle Time Fedora", AssetTypeId = 8, Price = nil, OffSale = true, Limited = true, Creator = "Roblox"},
    [139607718] = {Name = "Korblox Deathspeaker Right Leg", AssetTypeId = 31, Price = 17000, Creator = "Roblox"},
    [3576686446] = {Name = "Wave", AssetTypeId = 61, Price = 0, Creator = "Roblox"},
    [3360689775] = {Name = "Hello", AssetTypeId = 61, Price = 0, Creator = "Roblox"},
    [11111] = {Name = "Sword", AssetTypeId = 19, Price = 100, Creator = "Roblox"},
}
Mock.Bundles = {
    [192] = {Name = "Korblox Deathspeaker", BundleType = "BodyParts", Items = {
        {Id = 139607718, Name = "Korblox Deathspeaker Right Leg", Type = "Asset"}, {Id = 139607673, Name = "Korblox Deathspeaker Left Arm", Type = "Asset"},
        {Id = 192, Name = "Korblox Deathspeaker", Type = "UserOutfit"}}},
}
local function userById(id) for _, user in ipairs(Mock.Users) do if user.Id == id then return user end end end
local function userByName(name) for _, user in ipairs(Mock.Users) do if user.Name:lower() == tostring(name):lower() then return user end end end
local function describe(user)
    local desc = newInstance("HumanoidDescription", true)
    local avatar = user.Avatar or {}
    for key, value in pairs(avatar) do
        if key ~= "Accessories" and key ~= "Emotes" then desc[key] = value end
    end
    local rows = {}
    for _, row in ipairs(avatar.Accessories or {}) do table.insert(rows, {AssetId = row.AssetId, AccessoryType = Enum.AccessoryType[row.AccessoryType], IsLayered = false}) end
    desc:SetAccessories(rows, true)
    desc:SetEmotes(avatar.Emotes or {})
    local equipped, slot = {}, 0
    for name in pairs(avatar.Emotes or {}) do slot = slot + 1; table.insert(equipped, {Name = name, Slot = slot}) end
    desc:SetEquippedEmotes(equipped)
    return desc
end
Mock.describe = describe

-- R15 and R6 rigs built from a description, with Motor6Ds placed on matching rig attachments.
local R15 = {
    parts = {HumanoidRootPart = {2, 2, 1}, LowerTorso = {2, 0.4, 1}, UpperTorso = {2, 1.6, 1}, Head = {1.2, 1.2, 1.2},
        LeftUpperArm = {1, 1.2, 1}, LeftLowerArm = {1, 1, 1}, LeftHand = {1, 0.3, 1}, RightUpperArm = {1, 1.2, 1}, RightLowerArm = {1, 1, 1}, RightHand = {1, 0.3, 1},
        LeftUpperLeg = {1, 1.2, 1}, LeftLowerLeg = {1, 1.2, 1}, LeftFoot = {1, 0.3, 1}, RightUpperLeg = {1, 1.2, 1}, RightLowerLeg = {1, 1.2, 1}, RightFoot = {1, 0.3, 1}},
    joints = {
        {"Root", "HumanoidRootPart", "LowerTorso", {0, -0.8, 0}, {0, -0.2, 0}},
        {"Waist", "LowerTorso", "UpperTorso", {0, 0.2, 0}, {0, -0.8, 0}},
        {"Neck", "UpperTorso", "Head", {0, 0.8, 0}, {0, -0.6, 0}},
        {"LeftShoulder", "UpperTorso", "LeftUpperArm", {-1, 0.6, 0}, {0.5, 0.6, 0}},
        {"LeftElbow", "LeftUpperArm", "LeftLowerArm", {0, -0.6, 0}, {0, 0.5, 0}},
        {"LeftWrist", "LeftLowerArm", "LeftHand", {0, -0.5, 0}, {0, 0.15, 0}},
        {"RightShoulder", "UpperTorso", "RightUpperArm", {1, 0.6, 0}, {-0.5, 0.6, 0}},
        {"RightElbow", "RightUpperArm", "RightLowerArm", {0, -0.6, 0}, {0, 0.5, 0}},
        {"RightWrist", "RightLowerArm", "RightHand", {0, -0.5, 0}, {0, 0.15, 0}},
        {"LeftHip", "LowerTorso", "LeftUpperLeg", {-0.5, -0.2, 0}, {0, 0.6, 0}},
        {"LeftKnee", "LeftUpperLeg", "LeftLowerLeg", {0, -0.6, 0}, {0, 0.6, 0}},
        {"LeftAnkle", "LeftLowerLeg", "LeftFoot", {0, -0.6, 0}, {0, 0.15, 0}},
        {"RightHip", "LowerTorso", "RightUpperLeg", {0.5, -0.2, 0}, {0, 0.6, 0}},
        {"RightKnee", "RightUpperLeg", "RightLowerLeg", {0, -0.6, 0}, {0, 0.6, 0}},
        {"RightAnkle", "RightLowerLeg", "RightFoot", {0, -0.6, 0}, {0, 0.15, 0}},
    },
    accessories = {Head = {HatAttachment = {0, 0.6, 0}, HairAttachment = {0, 0.6, 0}, FaceFrontAttachment = {0, 0, -0.6}},
        UpperTorso = {NeckAttachment = {0, 0.8, 0}, BodyFrontAttachment = {0, 0, -0.5}, BodyBackAttachment = {0, 0, 0.5}},
        LowerTorso = {WaistCenterAttachment = {0, -0.2, 0}, WaistFrontAttachment = {0, -0.2, -0.5}, WaistBackAttachment = {0, -0.2, 0.5}}},
    hipHeight = 2,
}
local R6 = {
    parts = {HumanoidRootPart = {2, 2, 1}, Torso = {2, 2, 1}, Head = {2, 1, 1}, ["Left Arm"] = {1, 2, 1}, ["Right Arm"] = {1, 2, 1}, ["Left Leg"] = {1, 2, 1}, ["Right Leg"] = {1, 2, 1}},
    joints = {
        {"RootJoint", "HumanoidRootPart", "Torso", {0, 0, 0}, {0, 0, 0}},
        {"Neck", "Torso", "Head", {0, 1, 0}, {0, -0.5, 0}},
        {"Left Shoulder", "Torso", "Left Arm", {-1, 0.5, 0}, {0.5, 0.5, 0}},
        {"Right Shoulder", "Torso", "Right Arm", {1, 0.5, 0}, {-0.5, 0.5, 0}},
        {"Left Hip", "Torso", "Left Leg", {-1, -1, 0}, {-0.5, 1, 0}},
        {"Right Hip", "Torso", "Right Leg", {1, -1, 0}, {0.5, 1, 0}},
    },
    accessories = {Head = {HatAttachment = {0, 0.5, 0}, HairAttachment = {0, 0.6, 0}, FaceFrontAttachment = {0, 0, -0.5}},
        Torso = {NeckAttachment = {0, 1, 0}, BodyFrontAttachment = {0, 0, -0.5}, BodyBackAttachment = {0, 0, 0.5}, WaistCenterAttachment = {0, -1, 0},
            WaistFrontAttachment = {0, -1, -0.5}, WaistBackAttachment = {0, -1, 0.5}}},
    hipHeight = 0,
}
local ACCESSORY_ATTACHMENT = {Hat = "HatAttachment", Hair = "HairAttachment", Face = "FaceFrontAttachment", Neck = "NeckAttachment",
    Front = "BodyFrontAttachment", Back = "BodyBackAttachment", Waist = "WaistBackAttachment", Shoulder = "NeckAttachment"}
local function vec(t) return Vector3.new(t[1], t[2], t[3]) end
local function buildRig(desc, rigType)
    local layout = rigType == Enum.HumanoidRigType.R6 and R6 or R15
    local model = newInstance("Model", true)
    model.Name = "Avatar"
    local hum = newInstance("Humanoid", true)
    hum.RigType = rigType; hum.HipHeight = layout.hipHeight; hum.Parent = model
    newInstance("Animator", true).Parent = hum
    for _, name in ipairs({"BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale", "BodyProportionScale", "BodyTypeScale"}) do
        local value = newInstance("NumberValue", true); value.Name = name; value.Value = 1; value.Parent = hum
    end
    local parts = {}
    for name, size in pairs(layout.parts) do
        local part = newInstance(rigType == Enum.HumanoidRigType.R6 and "Part" or (name == "HumanoidRootPart" and "Part" or "MeshPart"), true)
        part.Name = name; part.Size = vec(size)
        if name == "HumanoidRootPart" then part.Transparency = 1 end
        if part:IsA("MeshPart") then
            local field = name:match("Arm") and (name:find("Left") and "LeftArm" or "RightArm") or name:match("Hand") and (name:find("Left") and "LeftArm" or "RightArm")
                or (name:match("Leg") or name:match("Foot")) and (name:find("Left") and "LeftLeg" or "RightLeg") or name:match("Torso") and "Torso" or "Head"
            info(part).Props.MeshId = "rbxassetid://" .. tostring(desc[field] ~= 0 and desc[field] or 1000 + #name)
        end
        part.Parent = model
        parts[name] = part
    end
    model.PrimaryPart = parts.HumanoidRootPart
    for _, joint in ipairs(layout.joints) do
        local name, p0, p1, c0, c1 = joint[1], parts[joint[2]], parts[joint[3]], CFrame.new(vec(joint[4])), CFrame.new(vec(joint[5]))
        if rigType == Enum.HumanoidRigType.R15 then
            for _, pair in ipairs({{p0, c0}, {p1, c1}}) do
                local at = newInstance("Attachment", true); at.Name = name .. "RigAttachment"; at.CFrame = pair[2]; at.Parent = pair[1]
            end
        end
        local motor = newInstance("Motor6D", true)
        motor.Name = name; motor.Part0 = p0; motor.Part1 = p1; motor.C0 = c0; motor.C1 = c1
        motor.Parent = rigType == Enum.HumanoidRigType.R6 and parts.Torso or p1
        p1.CFrame = p0.CFrame * c0 * c1:Inverse()
    end
    for partName, list in pairs(layout.accessories) do
        for name, offset in pairs(list) do local at = newInstance("Attachment", true); at.Name = name; at.CFrame = CFrame.new(vec(offset)); at.Parent = parts[partName] end
    end
    local face = newInstance("Decal", true); face.Name = "face"; face.Texture = "rbxasset://textures/face.png"; face.Parent = parts.Head
    for _, row in ipairs(desc:GetAccessories(true)) do
        local accessory = newInstance("Accessory", true)
        accessory.Name = "Accessory" .. tostring(row.AssetId); accessory.AccessoryType = row.AccessoryType
        local handle = newInstance("Part", true); handle.Name = "Handle"; handle.Size = Vector3.new(1, 1, 1); handle.CanCollide = false; handle.Parent = accessory
        local attachmentName = ACCESSORY_ATTACHMENT[row.AccessoryType.Name] or "HatAttachment"
        local at = newInstance("Attachment", true); at.Name = attachmentName; at.Parent = handle
        for _, part in pairs(parts) do
            local target = part:FindFirstChild(attachmentName)
            if target then
                local weld = newInstance("Weld", true); weld.Name = "AccessoryWeld"; weld.Part0 = handle; weld.Part1 = part; weld.C0 = at.CFrame; weld.C1 = target.CFrame; weld.Parent = handle
                handle.CFrame = part.CFrame * target.CFrame * at.CFrame:Inverse()
                break
            end
        end
        accessory.Parent = model
    end
    if desc.Shirt ~= 0 then local shirt = newInstance("Shirt", true); shirt.Name = "Shirt"; shirt.ShirtTemplate = "rbxassetid://" .. desc.Shirt; shirt.Parent = model end
    if desc.Pants ~= 0 then local pants = newInstance("Pants", true); pants.Name = "Pants"; pants.PantsTemplate = "rbxassetid://" .. desc.Pants; pants.Parent = model end
    local colors = newInstance("BodyColors", true); colors.Parent = model
    for _, name in ipairs({"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do colors[name .. "Color3"] = desc[name .. "Color"] end
    local animate = newInstance("LocalScript", true); animate.Name = "Animate"; animate.Parent = model
    for _, state in ipairs({"idle", "walk", "run", "jump", "fall", "climb", "swim"}) do
        local folder = newInstance("StringValue", true); folder.Name = state; folder.Parent = animate
        local animation = newInstance("Animation", true); animation.Name = state:gsub("^%l", string.upper) .. "Anim"; animation.AnimationId = "rbxassetid://50" .. #state; animation.Parent = folder
    end
    local attached = Methods.Clone(desc); attached.Name = "HumanoidDescription"; attached.Parent = hum
    return model
end
Mock.buildRig = buildRig

-- -----------------------------------------------------------------------------
-- Services, player and executor functions
-- -----------------------------------------------------------------------------
local services = {}
local function service(name, extra, signals)
    local instance = newInstance("Service", true)
    local data = info(instance)
    data.Props.Name = name
    data.Extra = extra or {}
    for _, signalName in ipairs(signals or {}) do data.Signals[signalName] = signal(signalName) end
    services[name] = instance
    return instance
end

local function jsonEncode(value)
    local kind = type(value)
    if kind == "nil" then return "null" end
    if kind == "boolean" then return tostring(value) end
    if kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then error("JSON cannot encode NaN or infinity") end
        if math.floor(value) == value and math.abs(value) < 1e15 then return string.format("%d", value) end
        return string.format("%.17g", value)
    end
    if kind == "string" then
        local map = {['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t"}
        return '"' .. value:gsub('[%c"\\]', function(c) return map[c] or string.format("\\u%04x", c:byte()) end) .. '"'
    end
    if kind == "table" then
        if next(value) == nil then return "[]" end
        if #value > 0 then
            local parts = {}
            for _, item in ipairs(value) do table.insert(parts, jsonEncode(item)) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local keys = {}
        for key in pairs(value) do
            if type(key) ~= "string" then error("JSON object keys must be strings") end
            table.insert(keys, key)
        end
        table.sort(keys)
        local parts = {}
        for _, key in ipairs(keys) do table.insert(parts, jsonEncode(key) .. ":" .. jsonEncode(value[key])) end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    error("JSON cannot encode a " .. typeof(value))
end
local function jsonDecode(text)
    local position = 1
    local function skip() position = text:find("[^%s]", position) or #text + 1 end
    local parseValue
    local function parseString()
        local result, i = {}, position + 1
        while true do
            local c = text:sub(i, i)
            if c == "" then error("unterminated string") end
            if c == '"' then position = i + 1; return table.concat(result) end
            if c == "\\" then
                local n = text:sub(i + 1, i + 1)
                local map = {n = "\n", r = "\r", t = "\t", ['"'] = '"', ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f"}
                if n == "u" then table.insert(result, utf8.char(tonumber(text:sub(i + 2, i + 5), 16))); i = i + 6
                else table.insert(result, map[n] or n); i = i + 2 end
            else
                table.insert(result, c); i = i + 1
            end
        end
    end
    function parseValue()
        skip()
        local c = text:sub(position, position)
        if c == "{" then
            local result = {}
            position = position + 1; skip()
            if text:sub(position, position) == "}" then position = position + 1; return result end
            while true do
                skip()
                local key = parseString()
                skip()
                if text:sub(position, position) ~= ":" then error("expected ':' at " .. position) end
                position = position + 1
                result[key] = parseValue()
                skip()
                local d = text:sub(position, position)
                position = position + 1
                if d == "}" then return result end
                if d ~= "," then error("expected ',' or '}' at " .. position) end
            end
        elseif c == "[" then
            local result = {}
            position = position + 1; skip()
            if text:sub(position, position) == "]" then position = position + 1; return result end
            while true do
                table.insert(result, parseValue())
                skip()
                local d = text:sub(position, position)
                position = position + 1
                if d == "]" then return result end
                if d ~= "," then error("expected ',' or ']' at " .. position) end
            end
        elseif c == '"' then return parseString()
        elseif text:sub(position, position + 3) == "true" then position = position + 4; return true
        elseif text:sub(position, position + 4) == "false" then position = position + 5; return false
        elseif text:sub(position, position + 3) == "null" then position = position + 4; return nil
        else
            local literal = text:match("^-?%d+%.?%d*[eE]?[-+]?%d*", position)
            if not literal or literal == "" then error("unexpected character at " .. position) end
            position = position + #literal
            return tonumber(literal)
        end
    end
    local result = parseValue()
    skip()
    if position <= #text then error("trailing characters in JSON") end
    return result
end
Mock.jsonEncode = jsonEncode
Mock.jsonDecode = jsonDecode

local playerGui = newInstance("PlayerGui", true)
info(playerGui).Props.Name = "PlayerGui"
local player = newInstance("Player", true)
info(player).Props.Name = "LyraTester"
info(player).Props.UserId = 1
info(player).Props.DisplayName = "Lyra Tester"
info(player).Extra.HasAppearanceLoaded = function() return true end
playerGui.Parent = player
local camera = newInstance("Camera", true)
camera.Name = "Camera"
local workspaceService = service("Workspace", {CurrentCamera = camera,
    BulkMoveTo = function(_, parts, frames, mode)
        if type(parts) ~= "table" or type(frames) ~= "table" or #parts ~= #frames then fail("BulkMoveTo expects matching part and CFrame lists") end
        expect(mode, "EnumItem", "BulkMoveTo mode")
        for i, part in ipairs(parts) do expect(frames[i], "CFrame", "BulkMoveTo"); part.CFrame = frames[i] end
    end}, {"DescendantAdded"})
camera.Parent = workspaceService
local otherPlayers = {}
Mock.OtherPlayers = otherPlayers

local playersService = service("Players", {LocalPlayer = player,
    GetPlayers = function() local list = {player}; for _, other in ipairs(otherPlayers) do table.insert(list, other) end; return list end,
    GetPlayerByUserId = function(_, id) if id == player.UserId then return player end; for _, other in ipairs(otherPlayers) do if other.UserId == id then return other end end; return nil end,
    GetPlayerFromCharacter = function(_, character)
        if character == nil then return nil end
        if player.Character == character then return player end
        for _, other in ipairs(otherPlayers) do if other.Character == character then return other end end
        return nil
    end,
    GetUserIdFromNameAsync = function(_, name) task.wait(0.1); local user = userByName(name); if not user then error("HTTP 400 (Bad Request)") end; return user.Id end,
    GetNameFromUserIdAsync = function(_, id) task.wait(0.1); local user = userById(id); if not user then error("HTTP 400 (Bad Request)") end; return user.Name end,
    GetHumanoidDescriptionFromUserIdAsync = function(_, id)
        number(id, "GetHumanoidDescriptionFromUserIdAsync")
        task.wait(0.1)
        local user = userById(id); if not user then error("HTTP 400 (Bad Request)") end
        return describe(user)
    end,
    CreateHumanoidModelFromDescriptionAsync = function(_, desc, rigType)
        expect(desc, "Instance", "CreateHumanoidModelFromDescriptionAsync")
        expect(rigType, "EnumItem", "CreateHumanoidModelFromDescriptionAsync")
        task.wait(0.1)
        return buildRig(desc, rigType)
    end,
}, {"PlayerAdded", "PlayerRemoving"})
service("RunService", {
    BindToRenderStep = function(_, name, priority, fn) if type(name) ~= "string" or type(priority) ~= "number" or type(fn) ~= "function" then fail("BindToRenderStep: bad arguments") end; Mock.RenderSteps[name] = fn end,
    UnbindFromRenderStep = function(_, name) Mock.RenderSteps[name] = nil end,
}, {"RenderStepped", "Heartbeat", "Stepped"})
Mock.RenderSteps = {}
local inputService = service("UserInputService", {KeyboardEnabled = true, TouchEnabled = false, MouseEnabled = true, MouseBehavior = Enum.MouseBehavior.Default,
    GetFocusedTextBox = function() return Mock.Focused end}, {"InputBegan", "InputChanged", "InputEnded"})
service("GuiService", nil, {"MenuOpened", "MenuClosed"})
service("Lighting")
service("ReplicatedStorage"); service("ReplicatedFirst"); service("StarterPack"); service("Debris")
service("ContentProvider", {PreloadAsync = function(_, list) if type(list) ~= "table" then fail("PreloadAsync expects a list") end; task.wait(0.2) end})
service("TextService", {GetTextSize = function(_, text, size, font, frame)
    expect(font, "EnumItem", "TextService:GetTextSize font")
    expect(frame, "Vector2", "TextService:GetTextSize frameSize")
    local width = #tostring(text) * size * 0.52
    local lines = math.max(1, math.ceil(width / math.max(1, frame.X)))
    return Vector2.new(math.min(width, frame.X), lines * size * 1.2)
end})
service("HttpService", {
    JSONEncode = function(_, value) return jsonEncode(value) end,
    JSONDecode = function(_, text) return jsonDecode(text) end,
    GenerateGUID = function() sequence = sequence + 1; return "GUID-" .. sequence end,
    UrlEncode = function(_, text) return (tostring(text):gsub("[^%w%-_%.~]", function(c) return string.format("%%%02X", c:byte()) end)) end,
})
service("TweenService", {Create = function(_, instance, tweenInfo, goal)
    expect(instance, "Instance", "TweenService:Create")
    expect(tweenInfo, "TweenInfo", "TweenService:Create")
    for key, value in pairs(goal) do
        local current = instance[key]
        if typeof(current) ~= typeof(value) then fail("TweenService:Create property " .. key .. " expects " .. typeof(current) .. ", got " .. typeof(value)) end
    end
    local tween = {Completed = signal("Completed"), PlaybackState = Enum.PlaybackState.Begin}
    local thread
    function tween.Play(self)
        self.PlaybackState = Enum.PlaybackState.Playing
        thread = task.delay(tweenInfo.Time, function()
            if info(instance).Destroyed then return end
            for key, value in pairs(goal) do instance[key] = value end
            self.PlaybackState = Enum.PlaybackState.Completed
            self.Completed:Fire(Enum.PlaybackState.Completed)
        end)
    end
    function tween.Cancel(self)
        if thread then task.cancel(thread); thread = nil end
        if self.PlaybackState == Enum.PlaybackState.Playing then
            self.PlaybackState = Enum.PlaybackState.Cancelled
            self.Completed:Fire(Enum.PlaybackState.Cancelled)
        end
    end
    return setmetatable(tween, {__type = "Instance"})
end})
local chatService = service("TextChatService", {
    CanUserChatAsync = function() task.wait(0.2); return true end,
}, {"MessageReceived"})
local commands = newInstance("Folder", true)
commands.Name = "TextChatCommands"
info(commands).Parent = chatService
table.insert(info(chatService).Children, commands)
local emote = newInstance("TextChatCommand", true)
emote.Name = "RBXEmoteCommand"
emote.Parent = commands
service("CoreGui")
local coreStates = {}
service("StarterGui", {
    SetCore = function(_, name, value) Mock.CoreCalls = Mock.CoreCalls or {}; table.insert(Mock.CoreCalls, {Name = name, Value = value}) end,
    SetCoreGuiEnabled = function(_, kind, enabled) expect(kind, "EnumItem", "SetCoreGuiEnabled"); coreStates[kind.Name] = enabled end,
    GetCoreGuiEnabled = function(_, kind) expect(kind, "EnumItem", "GetCoreGuiEnabled"); if coreStates[kind.Name] == nil then return true end; return coreStates[kind.Name] end,
})
service("UserService", {GetUserInfosByUserIdsAsync = function(_, ids)
    if type(ids) ~= "table" then fail("GetUserInfosByUserIdsAsync expects a list") end
    task.wait(0.05)
    local result = {}
    for _, id in ipairs(ids) do local user = userById(id); if user then table.insert(result, {Id = user.Id, Username = user.Name, DisplayName = user.DisplayName}) end end
    return result
end})
service("MarketplaceService", {GetProductInfo = function(_, id, infoType)
    number(id, "GetProductInfo"); expect(infoType, "EnumItem", "GetProductInfo")
    task.wait(0.05)
    local item = Mock.Catalog[id]
    if not item then error("HTTP 400 (Bad Request)") end
    return {Name = item.Name, AssetTypeId = item.AssetTypeId, IsForSale = not item.OffSale, PriceInRobux = item.Price, IsLimited = item.Limited == true,
        IsLimitedUnique = false, Creator = {Name = item.Creator}}
end})
local function catalogRow(id, item)
    local kind
    for _, enumItem in ipairs(Enum.AvatarAssetType:GetEnumItems()) do
        local ids = {TShirt = 2, Hat = 8, Shirt = 11, Pants = 12, Head = 17, Face = 18, Gear = 19, Torso = 27, RightArm = 28, LeftArm = 29, LeftLeg = 30, RightLeg = 31,
            HairAccessory = 41, EmoteAnimation = 61}
        if ids[enumItem.Name] == item.AssetTypeId then kind = enumItem end
    end
    return {Id = id, Name = item.Name, ItemType = "Asset", AssetType = kind and kind.Name or item.AssetTypeId, Price = item.Price, CreatorName = item.Creator,
        IsOffSale = item.OffSale == true, ItemRestrictions = item.Limited and {"Limited"} or {}}
end
service("AvatarEditorService", {SearchCatalog = function(_, params)
    expect(params, "CatalogSearchParams", "SearchCatalog")
    task.wait(0.1)
    if Mock.CatalogSearchFails then error("SearchCatalog is unavailable in this game") end
    local results = {}
    local keyword = tostring(params.SearchKeyword or ""):lower()
    local ids = {}
    for id in pairs(Mock.Catalog) do table.insert(ids, id) end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local item = Mock.Catalog[id]
        if keyword == "" or item.Name:lower():find(keyword, 1, true) then table.insert(results, catalogRow(id, item)) end
    end
    for id, bundle in pairs(Mock.Bundles) do
        if keyword == "" or bundle.Name:lower():find(keyword, 1, true) then table.insert(results, {Id = id, Name = bundle.Name, ItemType = "Bundle", BundleType = bundle.BundleType, Price = 0}) end
    end
    local pages = {IsFinished = true}
    function pages.GetCurrentPage() return results end
    function pages.AdvanceToNextPageAsync() fail("No more pages") end
    return setmetatable(pages, {__type = "Instance"})
end})
service("AssetService", {
    GetBundleDetailsAsync = function(_, id)
        number(id, "GetBundleDetailsAsync"); task.wait(0.05)
        local bundle = Mock.Bundles[id]; if not bundle then error("HTTP 400 (Bad Request)") end
        return {Id = id, Name = bundle.Name, BundleType = bundle.BundleType, Items = bundle.Items}
    end,
    CreateMeshPartAsync = function(_, content)
        expect(content, "Content", "AssetService:CreateMeshPartAsync")
        task.wait(0.05)
        local part = newInstance("MeshPart", true); info(part).Props.MeshId = content.Uri
        return part
    end,
})
service("InsertService")

local CatalogSearchParamsMeta = {__type = "CatalogSearchParams"}
local SEARCH_FIELDS = {SearchKeyword = "string", AssetTypes = "table", BundleTypes = "table", SortType = "EnumItem", SortAggregation = "EnumItem",
    SalesTypeFilter = "EnumItem", IncludeOffSale = "boolean", MinPrice = "number", MaxPrice = "number", CategoryFilter = "EnumItem", Limit = "number"}
CatalogSearchParamsMeta.__index = function(self, key) if SEARCH_FIELDS[key] then return rawget(self, "_" .. key) end; fail(tostring(key) .. " is not a valid member of CatalogSearchParams") end
CatalogSearchParamsMeta.__newindex = function(self, key, value)
    if not SEARCH_FIELDS[key] then fail(tostring(key) .. " is not a valid member of CatalogSearchParams") end
    if typeof(value) ~= SEARCH_FIELDS[key] then fail("CatalogSearchParams." .. key .. " expects " .. SEARCH_FIELDS[key]) end
    rawset(self, "_" .. key, value)
end
local CatalogSearchParams = {new = function() return setmetatable({}, CatalogSearchParamsMeta) end}

local game = setmetatable({}, {__index = function(_, key)
    if key == "GetService" then
        return function(_, name)
            local found = services[name]
            if not found then fail("'" .. tostring(name) .. "' is not a valid Service name") end
            return found
        end
    end
    if key == "HttpGet" then return function(_, url) table.insert(Mock.HttpGets, url); if Mock.HttpGet then return Mock.HttpGet(url) end; error("HTTP 404 (Not Found)") end end
    if key == "GetObjects" then return function() error("GetObjects is not available in this test") end end
    if key == "PlaceId" then return 1818 end
    if key == "GameId" then return Mock.GameId or 99 end
    if key == "JobId" then return Mock.JobId or "" end
    fail(tostring(key) .. " is not a valid member of DataModel")
end, __type = "Instance"})
local workspace = workspaceService

local function warn(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
    table.insert(Mock.Warnings, table.concat(parts, " "))
end
local function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
    table.insert(Mock.Prints, table.concat(parts, " "))
end
-- Roblox's _G is a plain shared table; the CLI's own is read-only.
local _G = {}
Mock.G = _G
Mock.Writes = {}
local function writefile(path, data) assert(type(data) == "string", "writefile expects a string"); Mock.Files[path] = data; Mock.Writes[path] = (Mock.Writes[path] or 0) + 1 end
local function readfile(path) local data = Mock.Files[path]; if not data then error("file not found: " .. path) end; return data end
local function isfile(path) return Mock.Files[path] ~= nil end
local function getcustomasset(path) assert(Mock.Files[path], "getcustomasset: no file " .. path); return "rbxasset://custom/" .. path end
local function setclipboard(text) Mock.Clipboard = text end
-- Executor HTTP. Mock.RequestHandler answers; every call is logged in Mock.Requests.
local function request(options)
    if type(options) ~= "table" or type(options.Url) ~= "string" then fail("request expects {Url = string}") end
    table.insert(Mock.Requests, options)
    task.wait(0.05)
    if Mock.RequestHandler then return Mock.RequestHandler(options) end
    return {StatusCode = 404, Body = ""}
end

-- -----------------------------------------------------------------------------
-- Test helpers: frames, input simulation and queries.
-- -----------------------------------------------------------------------------
function Mock.frame(dt)
    dt = dt or 1 / 60
    for _, fn in pairs(Mock.RenderSteps) do task.spawn(fn, dt) end
    services.RunService.RenderStepped:Fire(dt)
    services.RunService.Heartbeat:Fire(dt)
end
local function inputObject(kind, position, keyCode)
    return setmetatable({UserInputType = Enum.UserInputType[kind], Position = position or Vector3.new(), KeyCode = keyCode or Enum.KeyCode.Unknown,
        UserInputState = Enum.UserInputState.Begin, Delta = Vector3.new()}, {__type = "Instance"})
end
Mock.input = inputObject
function Mock.click(button)
    local data = info(button)
    assert(isA(button, "GuiButton"), "Mock.click needs a GuiButton, got " .. data.ClassName)
    assert(not data.Destroyed, "Mock.click on a destroyed button")
    local center = button.AbsolutePosition + button.AbsoluteSize / 2
    local input = inputObject("MouseButton1", Vector3.new(center.X, center.Y, 0))
    signalFor(button, "MouseEnter"):Fire()
    signalFor(button, "InputBegan"):Fire(input)
    signalFor(button, "InputEnded"):Fire(input)
    signalFor(button, "Activated"):Fire(input, 1)
    signalFor(button, "MouseLeave"):Fire()
end
function Mock.key(name, processed)
    local input = inputObject("Keyboard", nil, Enum.KeyCode[name])
    inputService.InputBegan:Fire(input, processed == true)
    inputService.InputEnded:Fire(input, processed == true)
end
function Mock.type(box, text, enter)
    Methods.CaptureFocus(box)
    box.Text = text
    Methods.ReleaseFocus(box, enter)
end
-- First TextLabel/TextButton/TextBox under root whose Text matches (plain or as a Lua pattern).
function Mock.findText(root, text, plain)
    for _, item in ipairs(Methods.GetDescendants(root)) do
        local data = info(item)
        if (data.ClassName == "TextLabel" or data.ClassName == "TextButton" or data.ClassName == "TextBox") then
            local value = data.Props.Text
            if value == text or (not plain and type(value) == "string" and value:find(text)) then return item end
        end
    end
    return nil
end
-- The clickable button that holds a label with this text (the label's parent button, or the label itself).
function Mock.button(root, text)
    local label = Mock.findText(root, text, true)
    assert(label, "No element with text \"" .. tostring(text) .. "\"")
    if isA(label, "GuiButton") then return label end
    local parent = info(label).Parent
    while parent and not isA(parent, "GuiButton") do parent = info(parent).Parent end
    assert(parent, "Text \"" .. tostring(text) .. "\" is not inside a button")
    return parent
end
function Mock.count(root, className)
    local count = 0
    for _, item in ipairs(Methods.GetDescendants(root)) do if info(item).ClassName == className then count = count + 1 end end
    return count
end
-- Spawns a fresh character for the local player from its avatar, like LoadCharacter.
function Mock.spawnCharacter(rigType, extra)
    local old = player.Character
    if old then signalFor(player, "CharacterRemoving"):Fire(old); Methods.Destroy(old) end
    local character = buildRig(describe(userById(player.UserId)), rigType or Enum.HumanoidRigType.R15)
    character.Name = player.Name
    if extra then extra(character) end
    player.Character = character
    character.Parent = workspaceService
    signalFor(player, "CharacterAdded"):Fire(character)
    return character
end
Mock.Services = services
Mock.InputService = inputService
Mock.ChatService = chatService
Mock.EmoteCommand = emote
Mock.Player = player
Mock.PlayerGui = playerGui
Mock.Camera = camera
Mock.Workspace = workspaceService
