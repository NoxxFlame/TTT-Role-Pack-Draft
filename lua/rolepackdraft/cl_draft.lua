-- Cached global lookups
local DrawNoTexture = draw.NoTexture
local DrawSimpleText = draw.SimpleText
local GUIEnableScreenClicker = gui.EnableScreenClicker
local InputGetCursorPos = input.GetCursorPos
local InputIsMouseDown = input.IsMouseDown
local MathCeil = math.ceil
local MathMax = math.max
local MathRandom = math.random
local PlayerGetBySteamID64 = player.GetBySteamID64
local StringFormat = string.format
local StringUpper = string.upper
local SurfaceDrawRect = surface.DrawRect
local SurfaceDrawText = surface.DrawText
local SurfaceDrawTexturedRect = surface.DrawTexturedRect
local SurfaceGetTextSize = surface.GetTextSize
local SurfacePlaySound = surface.PlaySound
local SurfaceSetDrawColor = surface.SetDrawColor
local SurfaceSetFont = surface.SetFont
local SurfaceSetMaterial = surface.SetMaterial
local SurfaceSetTextColor = surface.SetTextColor
local SurfaceSetTextPos = surface.SetTextPos
local TableHasValue = table.HasValue
local TableInsert = table.insert
local TableRemove = table.remove
local VGUICreate = vgui.Create
local VGUICursorVisible = vgui.CursorVisible

local scrH = ScrH()
local scrW = ScrW()

local maxStreamLength = 65528

local draft_innocent_picks = GetConVar("ttt_draft_innocent_picks")
local draft_innocent_bans = GetConVar("ttt_draft_innocent_bans")
local draft_traitor_picks = GetConVar("ttt_draft_traitor_picks")
local draft_traitor_bans = GetConVar("ttt_draft_traitor_bans")
local draft_jester_picks = GetConVar("ttt_draft_jester_picks")
local draft_jester_bans = GetConVar("ttt_draft_jester_bans")
local draft_independent_picks = GetConVar("ttt_draft_independent_picks")
local draft_independent_bans = GetConVar("ttt_draft_independent_bans")
local draft_monster_picks = GetConVar("ttt_draft_monster_picks")
local draft_monster_bans = GetConVar("ttt_draft_monster_bans")
local draft_detective_picks = GetConVar("ttt_draft_detective_picks")
local draft_detective_bans = GetConVar("ttt_draft_detective_bans")

local draft_prep_time = GetConVar("ttt_draft_prep_time")
local draft_turn_time = GetConVar("ttt_draft_turn_time")
local draft_end_time = GetConVar("ttt_draft_end_time")

local showNext = GetConVar("ttt_draft_show_next"):GetInt()

local smallIconSize = 32
local smallIconMargin = 10
local smallIconOutline = 2
local smallIconGlow = 16
local largeIconSize = 64
local largeIconMargin = 40
local largeIconOutline = 4
local largeIconGlow = 32
local groupDividerWidth = 4
local groupMargin = 10
local timerWidth = 256

-- Cached colours
local colours = {
    bottomIconLight  = Color(0, 0, 0, 223),
    bottomIconDark   = Color(0, 0, 0, 127),
    choiceNameLight  = Color(255, 255, 255, 191),
    choiceNameDark   = Color(255, 255, 255, 32),
    previewNameLight = Color(255, 255, 255, 180),
    roleDescription  = Color(220, 220, 220, 230)
}

surface.CreateFont("DraftName", {
    font = "Tahoma",
    size = 16,
    weight = 1000
})

surface.CreateFont("DraftDescription", {
    font = "Tahoma",
    size = 24,
    weight = 400,
    italic = true
})

surface.CreateFont("DraftTimer", {
    font = "Tahoma",
    size = 32,
    weight = 1000
})

surface.CreateFont("DraftSmall", {
    font = "Tahoma",
    size = 38,
    weight = 1000
})

surface.CreateFont("DraftRegular", {
    font = "Tahoma",
    size = 48,
    weight = 1000
})

surface.CreateFont("DraftLarge", {
    font = "Tahoma",
    size = 64,
    weight = 1000
})

local function CalculateTopIconPositions()
    local innocentPicks = draft_innocent_picks:GetInt()
    local innocentBans = draft_innocent_bans:GetInt()
    local traitorPicks = draft_traitor_picks:GetInt()
    local traitorBans = draft_traitor_bans:GetInt()
    local jesterPicks = draft_jester_picks:GetInt()
    local jesterBans = draft_jester_bans:GetInt()
    local independentPicks = draft_independent_picks:GetInt()
    local independentBans = draft_independent_bans:GetInt()
    local monsterPicks = draft_monster_picks:GetInt()
    local monsterBans = draft_monster_bans:GetInt()
    local detectivePicks = draft_detective_picks:GetInt()
    local detectiveBans = draft_detective_bans:GetInt()

    local groups = 0
    local innocentGroupSize = 0
    if innocentPicks > 0 or innocentBans > 0 then
        groups = groups + 1
        innocentGroupSize = MathMax(innocentPicks, innocentBans)
    end
    local traitorGroupSize = 0
    if traitorPicks > 0 or traitorBans > 0 then
        groups = groups + 1
        traitorGroupSize = MathMax(traitorPicks, traitorBans)
    end
    local jesterGroupSize = 0
    if jesterPicks > 0 or jesterBans > 0 then
        groups = groups + 1
        jesterGroupSize = MathMax(jesterPicks, jesterBans)
    end
    local independentGroupSize = 0
    if independentPicks > 0 or independentBans > 0 then
        groups = groups + 1
        independentGroupSize = MathMax(independentPicks, independentBans)
    end
    local monsterGroupSize = 0
    if monsterPicks > 0 or monsterBans > 0 then
        groups = groups + 1
        monsterGroupSize = MathMax(monsterPicks, monsterBans)
    end
    local detectiveGroupSize = 0
    if detectivePicks > 0 or detectiveBans > 0 then
        groups = groups + 1
        detectiveGroupSize = MathMax(detectivePicks, detectiveBans)
    end

    local totalSize = innocentGroupSize + traitorGroupSize + jesterGroupSize + independentGroupSize + monsterGroupSize + detectiveGroupSize
    local width = ((groups - 1) * (groupDividerWidth + (2 * groupMargin))) + (totalSize * smallIconSize) + ((totalSize + groups - 2) * smallIconMargin)
    local x = (scrW - width) / 2

    local groupPositions = {
        [ROLE_TEAM_INNOCENT] = {["picks"] = {["count"] = innocentPicks, ["x"] = 0}, ["bans"] = {["count"] = innocentBans, ["x"] = 0}},
        [ROLE_TEAM_TRAITOR] = {["picks"] = {["count"] = traitorPicks, ["x"] = 0}, ["bans"] = {["count"] = traitorBans, ["x"] = 0}},
        [ROLE_TEAM_JESTER] = {["picks"] = {["count"] = jesterPicks, ["x"] = 0}, ["bans"] = {["count"] = jesterBans, ["x"] = 0}},
        [ROLE_TEAM_INDEPENDENT] = {["picks"] = {["count"] = independentPicks, ["x"] = 0}, ["bans"] = {["count"] = independentBans, ["x"] = 0}},
        [ROLE_TEAM_MONSTER] = {["picks"] = {["count"] = monsterPicks, ["x"] = 0}, ["bans"] = {["count"] = monsterBans, ["x"] = 0}},
        [ROLE_TEAM_DETECTIVE] = {["picks"] = {["count"] = detectivePicks, ["x"] = 0}, ["bans"] = {["count"] = detectiveBans, ["x"] = 0}}
    }

    local dividerPositions = {}

    -- Follow the same order as role packs (Det > Inn > Tra > Jes > Ind > Mon)
    if detectiveGroupSize > 0 then
        TableInsert(dividerPositions, x + ((smallIconSize + smallIconMargin) * detectiveGroupSize) + groupMargin)
        if detectivePicks >= detectiveBans then
            groupPositions[ROLE_TEAM_DETECTIVE]["picks"]["x"] = x
            groupPositions[ROLE_TEAM_DETECTIVE]["bans"]["x"] = x + ((detectivePicks - detectiveBans) / 2) * (smallIconSize + smallIconMargin)
        else
            groupPositions[ROLE_TEAM_DETECTIVE]["bans"]["x"] = x
            groupPositions[ROLE_TEAM_DETECTIVE]["picks"]["x"] = x + ((detectiveBans - detectivePicks) / 2) * (smallIconSize + smallIconMargin)
        end
        x = x + (detectiveGroupSize * (smallIconSize + smallIconMargin)) + groupDividerWidth + (2 * groupMargin) + smallIconMargin
    end
    if innocentGroupSize > 0 then
        TableInsert(dividerPositions, x + ((smallIconSize + smallIconMargin) * innocentGroupSize) + groupMargin)
        if innocentPicks >= innocentBans then
            groupPositions[ROLE_TEAM_INNOCENT]["picks"]["x"] = x
            groupPositions[ROLE_TEAM_INNOCENT]["bans"]["x"] = x + ((innocentPicks - innocentBans) / 2) * (smallIconSize + smallIconMargin)
        else
            groupPositions[ROLE_TEAM_INNOCENT]["bans"]["x"] = x
            groupPositions[ROLE_TEAM_INNOCENT]["picks"]["x"] = x + ((innocentBans - innocentPicks) / 2) * (smallIconSize + smallIconMargin)
        end
        x = x + (innocentGroupSize * (smallIconSize + smallIconMargin)) + groupDividerWidth + (2 * groupMargin) + smallIconMargin
    end
    if traitorGroupSize > 0 then
        TableInsert(dividerPositions, x + ((smallIconSize + smallIconMargin) * traitorGroupSize) + groupMargin)
        if traitorPicks >= traitorBans then
            groupPositions[ROLE_TEAM_TRAITOR]["picks"]["x"] = x
            groupPositions[ROLE_TEAM_TRAITOR]["bans"]["x"] = x + ((traitorPicks - traitorBans) / 2) * (smallIconSize + smallIconMargin)
        else
            groupPositions[ROLE_TEAM_TRAITOR]["bans"]["x"] = x
            groupPositions[ROLE_TEAM_TRAITOR]["picks"]["x"] = x + ((traitorBans - traitorPicks) / 2) * (smallIconSize + smallIconMargin)
        end
        x = x + (traitorGroupSize * (smallIconSize + smallIconMargin)) + groupDividerWidth + (2 * groupMargin) + smallIconMargin
    end
    if jesterGroupSize > 0 then
        TableInsert(dividerPositions, x + ((smallIconSize + smallIconMargin) * jesterGroupSize) + groupMargin)
        if jesterPicks >= jesterBans then
            groupPositions[ROLE_TEAM_JESTER]["picks"]["x"] = x
            groupPositions[ROLE_TEAM_JESTER]["bans"]["x"] = x + ((jesterPicks - jesterBans) / 2) * (smallIconSize + smallIconMargin)
        else
            groupPositions[ROLE_TEAM_JESTER]["bans"]["x"] = x
            groupPositions[ROLE_TEAM_JESTER]["picks"]["x"] = x + ((jesterBans - jesterPicks) / 2) * (smallIconSize + smallIconMargin)
        end
        x = x + (jesterGroupSize * (smallIconSize + smallIconMargin)) + groupDividerWidth + (2 * groupMargin) + smallIconMargin
    end
    if independentGroupSize > 0 then
        TableInsert(dividerPositions, x + ((smallIconSize + smallIconMargin) * independentGroupSize) + groupMargin)
        if independentPicks >= independentBans then
            groupPositions[ROLE_TEAM_INDEPENDENT]["picks"]["x"] = x
            groupPositions[ROLE_TEAM_INDEPENDENT]["bans"]["x"] = x + ((independentPicks - independentBans) / 2) * (smallIconSize + smallIconMargin)
        else
            groupPositions[ROLE_TEAM_INDEPENDENT]["bans"]["x"] = x
            groupPositions[ROLE_TEAM_INDEPENDENT]["picks"]["x"] = x + ((independentBans - independentPicks) / 2) * (smallIconSize + smallIconMargin)
        end
        x = x + (independentGroupSize * (smallIconSize + smallIconMargin)) + groupDividerWidth + (2 * groupMargin) + smallIconMargin
    end
    if monsterGroupSize > 0 then
        TableInsert(dividerPositions, x + ((smallIconSize + smallIconMargin) * monsterGroupSize) + groupMargin)
        if monsterPicks >= monsterBans then
            groupPositions[ROLE_TEAM_MONSTER]["picks"]["x"] = x
            groupPositions[ROLE_TEAM_MONSTER]["bans"]["x"] = x + ((monsterPicks - monsterBans) / 2) * (smallIconSize + smallIconMargin)
        else
            groupPositions[ROLE_TEAM_MONSTER]["bans"]["x"] = x
            groupPositions[ROLE_TEAM_MONSTER]["picks"]["x"] = x + ((monsterBans - monsterPicks) / 2) * (smallIconSize + smallIconMargin)
        end
    end

    TableRemove(dividerPositions)

    return {["groups"] = groupPositions, ["dividers"] = dividerPositions}
end

local function CalculateBottomIconPositions(draftOrder)
    local width = (#draftOrder * (smallIconSize + (2 * smallIconMargin))) - (2 * smallIconMargin)
    local x = (scrW - width) / 2
    return {["x"] = x, ["width"] = width, ["order"] = draftOrder}
end

local function CalculateCentreIconPositions(roles)
    local positions = {}
    for team = ROLE_TEAM_INNOCENT, ROLE_TEAM_DETECTIVE do
        local width = #roles[team] * (largeIconSize + largeIconMargin) - largeIconMargin
        local x = (scrW - width) / 2
        positions[team] = {["x"] = x}
    end
    return positions
end

local topPositions = {}
local bottomPositions = {}
local centrePositions = {
    [ROLE_TEAM_INNOCENT] = {},
    [ROLE_TEAM_TRAITOR] = {},
    [ROLE_TEAM_JESTER] = {},
    [ROLE_TEAM_INDEPENDENT] = {},
    [ROLE_TEAM_MONSTER] = {},
    [ROLE_TEAM_DETECTIVE] = {}
}
local availableRoles = {
    [ROLE_TEAM_INNOCENT] = {},
    [ROLE_TEAM_TRAITOR] = {},
    [ROLE_TEAM_JESTER] = {},
    [ROLE_TEAM_INDEPENDENT] = {},
    [ROLE_TEAM_MONSTER] = {},
    [ROLE_TEAM_DETECTIVE] = {}
}
local pickedRoles = {
    [ROLE_TEAM_INNOCENT] = {},
    [ROLE_TEAM_TRAITOR] = {},
    [ROLE_TEAM_JESTER] = {},
    [ROLE_TEAM_INDEPENDENT] = {},
    [ROLE_TEAM_MONSTER] = {},
    [ROLE_TEAM_DETECTIVE] = {}
}
local bannedRoles = {
    [ROLE_TEAM_INNOCENT] = {},
    [ROLE_TEAM_TRAITOR] = {},
    [ROLE_TEAM_JESTER] = {},
    [ROLE_TEAM_INDEPENDENT] = {},
    [ROLE_TEAM_MONSTER] = {},
    [ROLE_TEAM_DETECTIVE] = {}
}
local draftPhase = -1
local nextPhaseTime = -1
local randomSelection = false
local previousSelection
local selectedRole
local frames = {}
local mouseAutoEnabled = false
local holdingTab = false

local function BeginRolePackDraft(draftData)
    topPositions = CalculateTopIconPositions()
    bottomPositions = CalculateBottomIconPositions(draftData.order)
    centrePositions = CalculateCentreIconPositions(draftData.roles)
    availableRoles = draftData.roles
    draftPhase = 0
    nextPhaseTime = CurTime() + draft_prep_time:GetInt()
end

local buff = ""
net.Receive("TTT_BeginRolePackDraft_Part", function()
    buff = buff .. net.ReadData(maxStreamLength)
end)

net.Receive("TTT_BeginRolePackDraft", function()
    local dataJson = util.Decompress(buff .. net.ReadData(net.ReadUInt(16)))
    buff = ""

    if #dataJson == 0 then
        ErrorNoHalt("Role pack draft table decompression failed!\n")
        return
    end

    local dataTable = util.JSONToTable(dataJson)
    if dataTable == nil then
        ErrorNoHalt("Role pack draft table conversion failed!\n")
        return
    end

    BeginRolePackDraft(dataTable)
end)

net.Receive("TTT_EndRolePackDraft", function()
    topPositions = {}
    bottomPositions = {}
    centrePositions = {
        [ROLE_TEAM_INNOCENT] = {},
        [ROLE_TEAM_TRAITOR] = {},
        [ROLE_TEAM_JESTER] = {},
        [ROLE_TEAM_INDEPENDENT] = {},
        [ROLE_TEAM_MONSTER] = {},
        [ROLE_TEAM_DETECTIVE] = {}
    }
    availableRoles = {
        [ROLE_TEAM_INNOCENT] = {},
        [ROLE_TEAM_TRAITOR] = {},
        [ROLE_TEAM_JESTER] = {},
        [ROLE_TEAM_INDEPENDENT] = {},
        [ROLE_TEAM_MONSTER] = {},
        [ROLE_TEAM_DETECTIVE] = {}
    }
    pickedRoles = {
        [ROLE_TEAM_INNOCENT] = {},
        [ROLE_TEAM_TRAITOR] = {},
        [ROLE_TEAM_JESTER] = {},
        [ROLE_TEAM_INDEPENDENT] = {},
        [ROLE_TEAM_MONSTER] = {},
        [ROLE_TEAM_DETECTIVE] = {}
    }
    bannedRoles = {
        [ROLE_TEAM_INNOCENT] = {},
        [ROLE_TEAM_TRAITOR] = {},
        [ROLE_TEAM_JESTER] = {},
        [ROLE_TEAM_INDEPENDENT] = {},
        [ROLE_TEAM_MONSTER] = {},
        [ROLE_TEAM_DETECTIVE] = {}
    }
    draftPhase = -1
    nextPhaseTime = -1
    randomSelection = false
    previousSelection = nil
    selectedRole = nil

    if VGUICursorVisible() then
        GUIEnableScreenClicker(false)
        mouseAutoEnabled = false
    end

    for _, frame in pairs(frames) do
        frame:Close()
    end
    frames = {}
end)

net.Receive("TTT_NextRolePackDraft", function()
    if draftPhase == -1 then return end

    randomSelection = net.ReadBool()
    previousSelection = net.ReadInt(util.RoleBits())
    if draftPhase > 0 then
        if bottomPositions.order[draftPhase].action == "pick" then
            TableInsert(pickedRoles[bottomPositions.order[draftPhase].team], previousSelection)
        else
            TableInsert(bannedRoles[bottomPositions.order[draftPhase].team], previousSelection)
        end
    end
    draftPhase = draftPhase + 1
    if draftPhase > #bottomPositions.order then
        nextPhaseTime = CurTime() + draft_end_time:GetInt()
    else
        nextPhaseTime = CurTime() + draft_turn_time:GetInt()
    end
    selectedRole = nil

    local currentPlayer
    if draftPhase > 0 and draftPhase <= #bottomPositions.order then
        currentPlayer = PlayerGetBySteamID64(bottomPositions.order[draftPhase].player)
    end
    if currentPlayer == LocalPlayer() then
        SurfacePlaySound("rolepackdraft/alert.wav")
    end

    if draftPhase > #bottomPositions.order or currentPlayer ~= LocalPlayer() then
        if VGUICursorVisible() and not holdingTab then
            GUIEnableScreenClicker(false)
            mouseAutoEnabled = false
        end
    end
end)

net.Receive("TTT_UpdateRolePackDraft", function()
    selectedRole = net.ReadInt(util.RoleBits())
end)

local smallOutline = Material("rolepackdraft/outline_small.png")
local smallGlow = Material("rolepackdraft/glow_small.png")
local largeOutline = Material("rolepackdraft/outline_large.png")
local largeGlow = Material("rolepackdraft/glow_large.png")
local pickIcon = Material("rolepackdraft/pick.png")
local banIcon = Material("rolepackdraft/ban.png")
local largeBan = Material("rolepackdraft/ban_large.png")
local randomIcon = Material("rolepackdraft/random.png")

hook.Add("HUDShouldDraw", "TTTDraft_HUDShouldDraw", function(name)
    if draftPhase >= 0 and name ~= "CHudGMod" then return false end
end)

local function DrawColoredText(textTable, font, x, y, xalign, yalign)
    SurfaceSetFont(font)

    local width = 0
    local height
    local widths = {}
    for _, text in ipairs(textTable) do
        local w, h = SurfaceGetTextSize(text.text)
        if not height then height = h end
        TableInsert(widths, w)
        width = width + w
    end

    if (xalign == TEXT_ALIGN_CENTER) then
        x = x - width / 2
    elseif (xalign == TEXT_ALIGN_RIGHT) then
        x = x - width
    end

    if (yalign == TEXT_ALIGN_CENTER) then
        y = y - height / 2
    elseif (yalign == TEXT_ALIGN_BOTTOM) then
        y = y - height
    end

    for i, text in ipairs(textTable) do
        SurfaceSetTextPos(MathCeil(x), MathCeil(y))

        if (text.color ~= nil) then
            SurfaceSetTextColor(text.color.r, text.color.g, text.color.b, text.color.a)
        else
            SurfaceSetTextColor(255, 255, 255, 255)
        end

        SurfaceDrawText(text.text)
        x = x + widths[i]
    end

    return width, height
end

local teamArticle = {
    [ROLE_TEAM_INNOCENT] = "AN",
    [ROLE_TEAM_TRAITOR] = "A",
    [ROLE_TEAM_JESTER] = "A",
    [ROLE_TEAM_INDEPENDENT] = "AN",
    [ROLE_TEAM_MONSTER] = "A",
    [ROLE_TEAM_DETECTIVE] = "A"
}
local teamNames = {
    [ROLE_TEAM_INNOCENT] = "INNOCENT",
    [ROLE_TEAM_TRAITOR] = "TRAITOR",
    [ROLE_TEAM_JESTER] = "JESTER",
    [ROLE_TEAM_INDEPENDENT] = "INDEPENDENT",
    [ROLE_TEAM_MONSTER] = "MONSTER",
    [ROLE_TEAM_DETECTIVE] = "DETECTIVE"
}
local mouseDown = false
local lastRandomSelect = 0
local lastRandomIndex = 0

local pickedY     = smallIconMargin
local bannedY     = smallIconSize + (2 * smallIconMargin)
local topDivY     = (1.5 * smallIconMargin) + (0.5 * smallIconSize)
local timerY      = (2 * smallIconSize) + (3 * smallIconMargin)
local bottomPosY  = scrH - smallIconSize - smallIconMargin
local centrePosY  = (scrH - largeIconSize) / 2
local centreDivY  = (scrH + largeIconSize) / 2 + largeIconMargin + smallIconMargin
local upNextY     = (3 * smallIconSize) + (4 * smallIconMargin)
local messageY    = centreDivY + (2 * smallIconMargin)
local previewY    = scrH * 4 / 5

-- Cache role icons (this was the main FPS killer)
local roleIconCache = {}
local function GetRoleIconMaterial(roleShort)
    local material = roleIconCache[roleShort]
    if not material then
        material = Material(util.GetRoleIconPath(roleShort, "score", "png"))
        roleIconCache[roleShort] = material
    end
    return material
end

local function DrawTopRow()
    for team, group in pairs(topPositions.groups) do
        local x = group.picks.x

        for slot = 1, group.picks.count do
            local bright = false

            if draftPhase >= 1 and draftPhase <= #bottomPositions.order then
                if bottomPositions.order[draftPhase].action == "pick" and bottomPositions.order[draftPhase].team == team then
                    if slot == #pickedRoles[team] + 1 then
                        bright = true
                        SurfaceSetDrawColor(GetRoleTeamColor(team, "highlight"))
                        SurfaceSetMaterial(smallGlow)
                        SurfaceDrawTexturedRect(x - smallIconGlow, pickedY - smallIconGlow, smallIconSize + (2 * smallIconGlow), smallIconSize + (2 * smallIconGlow))
                    end
                end
            end

            DrawNoTexture()
            SurfaceSetDrawColor(COLOR_BLACK)
            SurfaceDrawRect(x, pickedY, smallIconSize, smallIconSize)

            SurfaceSetDrawColor(GetRoleTeamColor(team, "highlight"))
            SurfaceSetMaterial(smallOutline)
            SurfaceDrawTexturedRect(x - smallIconOutline, pickedY - smallIconOutline, smallIconSize + (2 * smallIconOutline), smallIconSize + (2 * smallIconOutline))

            if slot > #pickedRoles[team] then
                if bright then
                    SurfaceSetDrawColor(COLOR_WHITE)
                else
                    SurfaceSetDrawColor(255, 255, 255, 127)
                end
                SurfaceSetMaterial(pickIcon)
            else
                SurfaceSetDrawColor(COLOR_WHITE)
                SurfaceSetMaterial(GetRoleIconMaterial(ROLE_STRINGS_SHORT[pickedRoles[team][slot]]))
            end
            SurfaceDrawTexturedRect(x, pickedY, smallIconSize, smallIconSize)
            x = x + smallIconSize + smallIconMargin
        end

        x = group.bans.x

        for slot = 1, group.bans.count do
            local bright = false
            if draftPhase >= 1 and draftPhase <= #bottomPositions.order then
                if bottomPositions.order[draftPhase].action == "ban" and bottomPositions.order[draftPhase].team == team then
                    if slot == #bannedRoles[team] + 1 then
                        bright = true
                        SurfaceSetDrawColor(GetRoleTeamColor(team, "highlight"))
                        SurfaceSetMaterial(smallGlow)
                        SurfaceDrawTexturedRect(x - smallIconGlow, bannedY - smallIconGlow, smallIconSize + (2 * smallIconGlow), smallIconSize + (2 * smallIconGlow))
                    end
                end
            end

            DrawNoTexture()
            SurfaceSetDrawColor(COLOR_BLACK)
            SurfaceDrawRect(x, bannedY, smallIconSize, smallIconSize)

            SurfaceSetDrawColor(GetRoleTeamColor(team, "highlight"))
            SurfaceSetMaterial(smallOutline)
            SurfaceDrawTexturedRect(x - smallIconOutline, bannedY - smallIconOutline, smallIconSize + (2 * smallIconOutline), smallIconSize + (2 * smallIconOutline))

            if slot > #bannedRoles[team] then
                if bright then
                    SurfaceSetDrawColor(COLOR_WHITE)
                else
                    SurfaceSetDrawColor(255, 255, 255, 127)
                end
                SurfaceSetMaterial(banIcon)
            else
                SurfaceSetDrawColor(255, 255, 255, 32)
                SurfaceSetMaterial(GetRoleIconMaterial(ROLE_STRINGS_SHORT[bannedRoles[team][slot]]))
            end

            SurfaceDrawTexturedRect(x, bannedY, smallIconSize, smallIconSize)
            x = x + smallIconSize + smallIconMargin
        end
    end

    DrawNoTexture()
    for _, divider in pairs(topPositions.dividers) do
        SurfaceSetDrawColor(COLOR_WHITE)
        SurfaceDrawRect(divider, topDivY, groupDividerWidth, smallIconSize)
    end
end

local function DrawTimerSection()
    local time = MathMax(0, nextPhaseTime - CurTime())
    local progress

    if draftPhase == 0 then
        progress = time / draft_prep_time:GetInt()
    elseif draftPhase > #bottomPositions.order then
        progress = time / draft_end_time:GetInt()
    else
        progress = time / draft_turn_time:GetInt()
    end

    DrawSimpleText(StringFormat("%05.2f", time), "DraftTimer", scrW / 2, timerY, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    SurfaceDrawRect((scrW - (timerWidth * progress)) / 2, timerY + smallIconSize + (0.5 * smallIconMargin), timerWidth * progress, groupDividerWidth)
end

local function DrawBottomRow()
    local x = bottomPositions.x

    DrawNoTexture()
    SurfaceSetDrawColor(COLOR_WHITE)
    SurfaceDrawRect(x + (0.5 * smallIconSize), bottomPosY + (0.5 * (smallIconSize - groupDividerWidth)), bottomPositions.width - smallIconSize, groupDividerWidth)

    if draftPhase >= 1 and draftPhase <= #bottomPositions.order then
        SurfaceSetDrawColor(GetRoleTeamColor(bottomPositions.order[draftPhase].team, "highlight"))
        SurfaceSetMaterial(smallGlow)
        SurfaceDrawTexturedRect(x - smallIconGlow + ((draftPhase - 1) * (smallIconSize + (2 * smallIconMargin))), bottomPosY - smallIconGlow, smallIconSize + (2 * smallIconGlow), smallIconSize + (2 * smallIconGlow))
    end

    local createFrames = #frames == 0

    for order, turn in ipairs(bottomPositions.order) do
        if turn.player then
            if createFrames then
                local frame = VGUICreate("DFrame")
                frame:SetPos(x, bottomPosY)
                frame:SetSize(smallIconSize, smallIconSize)
                frame:ShowCloseButton(false)
                frame.Paint = function() end
                frames[order] = frame
                local avatar = VGUICreate("AvatarImage", frame)
                avatar:SetPlayer(PlayerGetBySteamID64(turn.player))
                avatar:SetSize(smallIconSize, smallIconSize)
                frame.avatar = avatar
                local panel = VGUICreate("DPanel", frame)
                panel:SetSize(smallIconSize, smallIconSize)
                frame.panel = panel
            end
        else
            DrawNoTexture()
            SurfaceSetDrawColor(COLOR_BLACK)
            SurfaceDrawRect(x, bottomPosY, smallIconSize, smallIconSize)

            if order < draftPhase then
                SurfaceSetDrawColor(255, 255, 255, 32)
            elseif order > draftPhase then
                SurfaceSetDrawColor(255, 255, 255, 127)
            else
                SurfaceSetDrawColor(COLOR_WHITE)
            end

            SurfaceSetMaterial(randomIcon)
            SurfaceDrawTexturedRect(x, bottomPosY, smallIconSize, smallIconSize)
        end

        SurfaceSetDrawColor(GetRoleTeamColor(turn.team, "highlight"))
        SurfaceSetMaterial(smallOutline)
        SurfaceDrawTexturedRect(x - smallIconOutline, bottomPosY - smallIconOutline, smallIconSize + (2 * smallIconOutline), smallIconSize + (2 * smallIconOutline))

        if order < draftPhase then
            SurfaceSetDrawColor(255, 255, 255, 32)
            if turn.player then
                frames[order].panel:SetBackgroundColor(colours.bottomIconLight)
                frames[order].panel:SetPaintBackground(true)
            end
        elseif order > draftPhase then
            SurfaceSetDrawColor(255, 255, 255, 127)
            if turn.player then
                frames[order].panel:SetBackgroundColor(colours.bottomIconDark)
                frames[order].panel:SetPaintBackground(true)
            end
        else
            SurfaceSetDrawColor(COLOR_WHITE)
            if turn.player then
                frames[order].panel:SetPaintBackground(false)
            end
        end

        if turn.action == "pick" then
            SurfaceSetMaterial(pickIcon)
        else
            SurfaceSetMaterial(banIcon)
        end

        SurfaceDrawTexturedRect(x, bottomPosY - smallIconSize, smallIconSize, smallIconSize)
        x = x + smallIconSize + (2 * smallIconMargin)
    end
end

local function DrawMiddleChoices()
    if draftPhase >= 1 and draftPhase <= #bottomPositions.order then
        local turn = bottomPositions.order[draftPhase]
        local x = centrePositions[turn.team].x

        local cursorX, cursorY = -1, -1
        if PlayerGetBySteamID64(turn.player) == LocalPlayer() then
            if not VGUICursorVisible() then
                GUIEnableScreenClicker(true)
                mouseAutoEnabled = true
            end

            cursorX, cursorY = InputGetCursorPos()
        elseif turn.player == nil then
            if CurTime() - lastRandomSelect > 0.5 then
                lastRandomSelect = CurTime()
                lastRandomIndex = MathRandom(1, #availableRoles[turn.team])
                while TableHasValue(pickedRoles[turn.team], availableRoles[turn.team][lastRandomIndex]) or TableHasValue(bannedRoles[turn.team], availableRoles[turn.team][lastRandomIndex]) do
                    lastRandomIndex = lastRandomIndex + 1
                    if lastRandomIndex > #availableRoles[turn.team] then
                        lastRandomIndex = 1
                    end
                end
                selectedRole = availableRoles[turn.team][lastRandomIndex]
            end
        end

        for _, role in ipairs(availableRoles[turn.team]) do
            local hover = false
            local selected = selectedRole == role
            if cursorX >= x and cursorX <= x + largeIconSize and cursorY >= centrePosY and cursorY <= centrePosY + largeIconSize then
                if not TableHasValue(pickedRoles[turn.team], role) and not TableHasValue(bannedRoles[turn.team], role) then
                    hover = true

                    if InputIsMouseDown(MOUSE_LEFT) then
                        if not mouseDown then
                            net.Start("TTT_SelectRolePackDraft")
                            net.WriteInt(role, util.RoleBits())
                            net.WriteUInt(draftPhase, 8)
                            net.SendToServer()
                        end
                        mouseDown = true
                    else
                        mouseDown = false
                    end
                end
            end

            if selected then
                SurfaceSetDrawColor(GetRoleTeamColor(turn.team, "highlight"))
                SurfaceSetMaterial(largeGlow)
                SurfaceDrawTexturedRect(x - largeIconGlow, centrePosY - largeIconGlow, largeIconSize + (2 * largeIconGlow), largeIconSize + (2 * largeIconGlow))
            elseif hover then
                SurfaceSetDrawColor(ColorAlpha(GetRoleTeamColor(turn.team, "highlight"), 128))
                SurfaceSetMaterial(largeGlow)
                SurfaceDrawTexturedRect(x - largeIconGlow, centrePosY - largeIconGlow, largeIconSize + (2 * largeIconGlow), largeIconSize + (2 * largeIconGlow))
            end

            DrawNoTexture()
            SurfaceSetDrawColor(COLOR_BLACK)
            SurfaceDrawRect(x, centrePosY, largeIconSize, largeIconSize)

            if TableHasValue(pickedRoles[turn.team], role) or TableHasValue(bannedRoles[turn.team], role) then
                SurfaceSetDrawColor(255, 255, 255, 32)
                DrawSimpleText(ROLE_STRINGS[role], "DraftName", x + (0.5 * largeIconSize), centrePosY + largeIconSize + (0.25 * largeIconMargin), colours.choiceNameDark, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            elseif selected or hover then
                if turn.action == "ban" then
                    SurfaceSetDrawColor(255, 255, 255, 32)
                else
                    SurfaceSetDrawColor(COLOR_WHITE)
                end
                DrawSimpleText(ROLE_STRINGS[role], "DraftName", x + (0.5 * largeIconSize), centrePosY + largeIconSize + (0.25 * largeIconMargin), COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            else
                SurfaceSetDrawColor(255, 255, 255, 191)
                DrawSimpleText(ROLE_STRINGS[role], "DraftName", x + (0.5 * largeIconSize), centrePosY + largeIconSize + (0.25 * largeIconMargin), colours.choiceNameLight, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end

            SurfaceSetMaterial(ROLE_SPRITE_ICON_MATERIALS[ROLE_STRINGS_SHORT[role]])
            SurfaceDrawTexturedRect(x, centrePosY, largeIconSize, largeIconSize)

            if turn.action == "ban" then
                if selected then
                    SurfaceSetDrawColor(COLOR_WHITE)
                    SurfaceSetMaterial(largeBan)
                    SurfaceDrawTexturedRect(x, centrePosY, largeIconSize, largeIconSize)
                elseif hover then
                    SurfaceSetDrawColor(255, 255, 255, 191)
                    SurfaceSetMaterial(largeBan)
                    SurfaceDrawTexturedRect(x, centrePosY, largeIconSize, largeIconSize)
                end
            end

            SurfaceSetDrawColor(GetRoleTeamColor(turn.team, "highlight"))
            SurfaceSetMaterial(largeOutline)
            SurfaceDrawTexturedRect(x - largeIconOutline, centrePosY - largeIconOutline, largeIconSize + (2 * largeIconOutline), largeIconSize + (2 * largeIconOutline))
            x = x + largeIconSize + largeIconMargin
        end
    end
end

local function DrawNextPreviews()
    if showNext > 0 and draftPhase < #bottomPositions.order then
        local targetTurn     = nil
        local turnsUntilPick = 0

        if showNext == 1 then
            -- Show previews if player is up next
            local nextTurn = bottomPositions.order[draftPhase + 1]
            local nextPly = PlayerGetBySteamID64(nextTurn.player)

            if nextPly == LocalPlayer() then
                targetTurn = nextTurn
                turnsUntilPick = 1
            end
        elseif showNext == 2 then
            -- Find player's next choice
            for i = draftPhase + 1, #bottomPositions.order do
                local turn = bottomPositions.order[i]
                if turn.player and PlayerGetBySteamID64(turn.player) == LocalPlayer() then
                    targetTurn = turn
                    turnsUntilPick = i - draftPhase
                    break
                end
            end
        end

        if targetTurn then
            local nextX = centrePositions[targetTurn.team].x

            local previewSize   = 48
            local previewMargin = 40

            local previewWidth = #availableRoles[targetTurn.team] * (previewSize + previewMargin) - previewMargin
            nextX = (scrW - previewWidth) / 2

            -- Get cursor location for hover detection
            local cursorX, cursorY = InputGetCursorPos()
            local iconOffsetY = turnsUntilPick <= 1 and 70 or 0

            -- Draw "IN x TURNS" text
            if showNext == 2 and turnsUntilPick > 1 then
                local actionText  = targetTurn.action == "pick" and "PICKING" or "BANNING"
                local actionColor = targetTurn.action == "pick" and GetRoleTeamColor(ROLE_TEAM_DETECTIVE, "highlight") or GetRoleTeamColor(ROLE_TEAM_TRAITOR, "highlight")
                local teamColour  = GetRoleTeamColor(targetTurn.team, "highlight")

                local message = {}
                TableInsert(message, {["text"] = StringFormat("IN %d TURNS: ", turnsUntilPick), ["color"] = COLOR_WHITE})
                TableInsert(message, {["text"] = "YOU ARE ", ["color"] = COLOR_WHITE})
                TableInsert(message, {["text"] = actionText, ["color"] = actionColor})
                TableInsert(message, {["text"] = " " .. teamArticle[targetTurn.team], ["color"] = COLOR_WHITE})
                TableInsert(message, {["text"] = " " .. teamNames[targetTurn.team], ["color"] = teamColour})
                for _, text in ipairs(message) do
                    text.color = ColorAlpha(text.color, 220)
                end
                DrawColoredText(message, "DraftSmall", scrW / 2, previewY - previewSize / 2 - 35 - iconOffsetY, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            end

            local hoveredRole = nil

            -- Draw preview icons
            for _, role in ipairs(availableRoles[targetTurn.team]) do
                local iconY = previewY - previewSize / 2 - iconOffsetY
                local isHovered = (cursorX >= nextX and cursorX <= nextX + previewSize and cursorY >= iconY and cursorY <= iconY + previewSize)

                if isHovered then
                    hoveredRole = role
                end

                -- Draw glow if hovered
                if isHovered then
                    SurfaceSetDrawColor(ColorAlpha(GetRoleTeamColor(targetTurn.team, "highlight"), 180))
                    SurfaceSetMaterial(smallGlow)
                    SurfaceDrawTexturedRect(nextX - smallIconGlow, iconY - smallIconGlow, previewSize + (2 * smallIconGlow), previewSize + (2 * smallIconGlow))
                end

                DrawNoTexture()
                SurfaceSetDrawColor(0, 0, 0, 150)
                SurfaceDrawRect(nextX, iconY, previewSize, previewSize)

                local isPickedOrBanned = TableHasValue(pickedRoles[targetTurn.team], role) or TableHasValue(bannedRoles[targetTurn.team], role)

                if isPickedOrBanned then
                    SurfaceSetDrawColor(255, 255, 255, 30)
                elseif isHovered then
                    SurfaceSetDrawColor(255, 255, 255, 255)
                else
                    SurfaceSetDrawColor(255, 255, 255, 160)
                end

                -- Role icon
                local iconMat = ROLE_SPRITE_ICON_MATERIALS[ROLE_STRINGS_SHORT[role]]
                if iconMat then
                    SurfaceSetMaterial(iconMat)
                    SurfaceDrawTexturedRect(nextX, iconY, previewSize, previewSize)
                end

                -- Role name
                local nameColor = isPickedOrBanned and colours.choiceNameDark or (isHovered and COLOR_WHITE or colours.previewNameLight)
                DrawSimpleText(
                    ROLE_STRINGS[role],
                    "DraftName",
                    nextX + (0.5 * previewSize),
                    previewY + previewSize / 2 + 4 - iconOffsetY,
                    nameColor,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_TOP
                )

                -- Outline
                SurfaceSetDrawColor(ColorAlpha(GetRoleTeamColor(targetTurn.team, "highlight"), isHovered and 255 or 150))
                SurfaceSetMaterial(smallOutline)
                SurfaceDrawTexturedRect(nextX - smallIconOutline, iconY - smallIconOutline, previewSize + (2 * smallIconOutline), previewSize + (2 * smallIconOutline))

                nextX = nextX + previewSize + previewMargin
            end

            -- Draw role description underneath preview names if hovered
            if hoveredRole then
                local descText = "This role doesn't have a description :("
                if LANG and LANG.GetRawTranslation then
                    descText = LANG.GetRawTranslation("cheatsheet_desc_" .. ROLE_STRINGS_RAW[hoveredRole]) or descText
                end

                DrawSimpleText(
                    descText,
                    "DraftDescription",
                    scrW / 2,
                    previewY + previewSize + smallIconMargin - iconOffsetY,
                    colours.roleDescription,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_TOP
                )
            end
        end
    end
end

local function DrawStatusMessages()
    local x = scrW / 2
    if draftPhase == 0 then
        DrawSimpleText("ROLE PACK DRAFT STARTING SOON", "DraftLarge", x, scrH / 2, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local nextTurn = bottomPositions.order[1]
        local nextPly = PlayerGetBySteamID64(nextTurn.player)

        local action = {}
        if nextTurn.action == "pick" then
            action.text = "PICKING"
            action.color = GetRoleTeamColor(ROLE_TEAM_DETECTIVE, "highlight")
        else
            action.text = "BANNING"
            action.color = GetRoleTeamColor(ROLE_TEAM_TRAITOR, "highlight")
        end

        local message = {}
        TableInsert(message, {["text"] = "UP FIRST: ", ["color"] = COLOR_WHITE})
        if nextPly == LocalPlayer() then
            TableInsert(message, {["text"] = "YOU ARE ", ["color"] = COLOR_WHITE})
        elseif nextTurn.player == nil then
            TableInsert(message, {["text"] = "RANDOMLY ", ["color"] = COLOR_WHITE})
        else
            TableInsert(message, {["text"] = StringUpper(nextPly:Nick()) .. " IS ", ["color"] = COLOR_WHITE})
        end
        TableInsert(message, action)
        TableInsert(message, {["text"] = " " .. teamArticle[nextTurn.team], ["color"] = COLOR_WHITE})
        TableInsert(message, {["text"] = " " .. teamNames[nextTurn.team], ["color"] = GetRoleTeamColor(nextTurn.team, "highlight")})
        for _, text in ipairs(message) do
            text.color = ColorAlpha(text.color, 220)
        end
        DrawColoredText(message, "DraftRegular", x, (scrH / 2) + largeIconSize, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif draftPhase > #bottomPositions.order then
        DrawSimpleText("ROLE PACK DRAFT FINISHED", "DraftLarge", x, scrH / 2, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        DrawSimpleText("A NEW ROUND WILL BEGIN SOON", "DraftRegular", x, (scrH / 2) + largeIconSize, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        local turn = bottomPositions.order[draftPhase]
        local ply = PlayerGetBySteamID64(turn.player)

        local action = {}
        if turn.action == "pick" then
            action.text = "PICKING"
            action.color = GetRoleTeamColor(ROLE_TEAM_DETECTIVE, "highlight")
        else
            action.text = "BANNING"
            action.color = GetRoleTeamColor(ROLE_TEAM_TRAITOR, "highlight")
        end

        local actionShort = {}
        if turn.action == "pick" then
            actionShort.text = "PICK"
            actionShort.color = GetRoleTeamColor(ROLE_TEAM_DETECTIVE, "highlight")
        else
            actionShort.text = "BAN"
            actionShort.color = GetRoleTeamColor(ROLE_TEAM_TRAITOR, "highlight")
        end

        local message = {}
        if ply == LocalPlayer() then
            TableInsert(message, {["text"] = "YOUR TURN TO ", ["color"] = COLOR_WHITE})
            TableInsert(message, actionShort)
        elseif turn.player == nil then
            TableInsert(message, {["text"] = "RANDOMLY ", ["color"] = COLOR_WHITE})
            TableInsert(message, action)
        else
            TableInsert(message, {["text"] = StringUpper(ply:Nick()) .. " IS ", ["color"] = COLOR_WHITE})
            TableInsert(message, action)
        end

        TableInsert(message, {["text"] = " " .. teamArticle[turn.team], ["color"] = COLOR_WHITE})
        TableInsert(message, {["text"] = " " .. teamNames[turn.team], ["color"] = GetRoleTeamColor(turn.team, "highlight")})
        DrawColoredText(message, "DraftLarge", x, (scrH - largeIconSize) / 2 - (0.5 * largeIconMargin), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

        DrawNoTexture()
        SurfaceSetDrawColor(COLOR_WHITE)
        SurfaceDrawRect(centrePositions[turn.team].x - smallIconSize, centreDivY, scrW + (2 * smallIconSize) - (2 * centrePositions[turn.team].x), groupDividerWidth / 2)
        messageY = centreDivY + (2 * smallIconMargin)

        if draftPhase > 1 then
            local lastTurn = bottomPositions.order[draftPhase - 1]
            local lastPly = PlayerGetBySteamID64(lastTurn.player)

            action = {}
            if lastTurn.action == "pick" then
                action.text = "PICKED"
                action.color = GetRoleTeamColor(ROLE_TEAM_DETECTIVE, "highlight")
            else
                action.text = "BANNED"
                action.color = GetRoleTeamColor(ROLE_TEAM_TRAITOR, "highlight")
            end

            message = {}
            if lastPly == LocalPlayer() then
                TableInsert(message, {["text"] = "YOU ", ["color"] = COLOR_WHITE})
                if randomSelection then
                    TableInsert(message, {["text"] = "RAN OUT OF TIME AND RANDOMLY ", ["color"] = COLOR_WHITE})
                end
            elseif lastTurn.player == nil then
                TableInsert(message, {["text"] = "RANDOMLY ", ["color"] = COLOR_WHITE})
            else
                if randomSelection then
                    TableInsert(message, {["text"] = StringUpper(lastPly:Nick()) .. " RAN OUT OF TIME AND RANDOMLY ", ["color"] = COLOR_WHITE})
                else
                    TableInsert(message, {["text"] = StringUpper(lastPly:Nick()) .. " ", ["color"] = COLOR_WHITE})
                end
            end

            TableInsert(message, action)
            TableInsert(message, {["text"] = " " .. StringUpper(ROLE_STRINGS[previousSelection]), ["color"] = GetRoleTeamColor(lastTurn.team, "highlight")})

            for _, text in ipairs(message) do
                text.color = ColorAlpha(text.color, 220)
            end

            DrawColoredText(message, "DraftSmall", x, messageY, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

            messageY = messageY + (0.65 * largeIconSize)
        end

        if draftPhase < #bottomPositions.order then
            local nextTurn = bottomPositions.order[draftPhase + 1]
            local nextPly = PlayerGetBySteamID64(nextTurn.player)

            action = {}
            if nextTurn.action == "pick" then
                action.text = "PICKING"
                action.color = GetRoleTeamColor(ROLE_TEAM_DETECTIVE, "highlight")
            else
                action.text = "BANNING"
                action.color = GetRoleTeamColor(ROLE_TEAM_TRAITOR, "highlight")
            end

            message = {}
            TableInsert(message, {["text"] = "UP NEXT: ", ["color"] = COLOR_WHITE})

            if nextPly == LocalPlayer() then
                TableInsert(message, {["text"] = "YOU ARE ", ["color"] = COLOR_WHITE})
            elseif nextTurn.player == nil then
                TableInsert(message, {["text"] = "RANDOMLY ", ["color"] = COLOR_WHITE})
            else
                TableInsert(message, {["text"] = StringUpper(nextPly:Nick()) .. " IS ", ["color"] = COLOR_WHITE})
            end

            TableInsert(message, action)
            TableInsert(message, {["text"] = " " .. teamArticle[nextTurn.team], ["color"] = COLOR_WHITE})
            TableInsert(message, {["text"] = " " .. teamNames[nextTurn.team], ["color"] = GetRoleTeamColor(nextTurn.team, "highlight")})

            for _, text in ipairs(message) do
                text.color = ColorAlpha(text.color, 220)
            end

            DrawColoredText(message, "DraftSmall", x, messageY, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        -- Draw dividing line above preview row
        SurfaceDrawRect(centrePositions[turn.team].x, messageY + 38 + (2 * smallIconMargin), scrW - (2 * centrePositions[turn.team].x), groupDividerWidth / 2)
    end

    if draftPhase < #bottomPositions.order then
        local nextTurn = bottomPositions.order[draftPhase + 1]
        local nextPly = PlayerGetBySteamID64(nextTurn.player)

        if nextPly == LocalPlayer() then
            x = scrW / 2
            DrawSimpleText("YOU ARE UP NEXT", "DraftSmall", x, upNextY, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    end
end

hook.Add("HUDDrawScoreBoard", "TTTDraft_HUDDrawScoreBoard", function()
    if draftPhase >= 0 then
        DrawNoTexture()
        SurfaceSetDrawColor(0, 0, 0, 220)
        SurfaceDrawRect(0, 0, scrW, scrH)

        DrawTopRow()
        DrawTimerSection()
        DrawBottomRow()
        DrawMiddleChoices()
        DrawNextPreviews()
        DrawStatusMessages()
    end
end)

-- Block scoreboard if player holds tab to hover preview icons and see role descriptions
hook.Add("ScoreboardShow", "RoleDraft_BlockScoreboardShow", function()
    if draftPhase >= 0 then
        return true
    end
end)

-- Enable cursor if player holds tab (need to do this manually as we're blocking the scoreboard)
hook.Add("PlayerButtonDown", "RoleDraft_EnableMouseClicker", function(_, button)
    if button ~= KEY_TAB then return end
    if not holdingTab then holdingTab = true end
    if draftPhase < 0 then return end

    if not VGUICursorVisible() then
        GUIEnableScreenClicker(true)
    end
end)

-- Disable the cursor on tab release UNLESS it was auto-enabled because it's their turn to pick
hook.Add("PlayerButtonUp", "RoleDraft_DisableMouseClicker", function(_, button)
    if button ~= KEY_TAB then return end
    if holdingTab then holdingTab = false end
    if draftPhase < 0 or mouseAutoEnabled then return end

    if VGUICursorVisible() then
        GUIEnableScreenClicker(false)
    end
end)