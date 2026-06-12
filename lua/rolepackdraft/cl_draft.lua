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

surface.CreateFont("DraftName", {
    font = "Tahoma",
    size = 16,
    weight = 1000
})

surface.CreateFont("DraftTimer", {
    font = "Tahoma",
    size = 32,
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
        innocentGroupSize = math.max(innocentPicks, innocentBans)
    end
    local traitorGroupSize = 0
    if traitorPicks > 0 or traitorBans > 0 then
        groups = groups + 1
        traitorGroupSize = math.max(traitorPicks, traitorBans)
    end
    local jesterGroupSize = 0
    if jesterPicks > 0 or jesterBans > 0 then
        groups = groups + 1
        jesterGroupSize = math.max(jesterPicks, jesterBans)
    end
    local independentGroupSize = 0
    if independentPicks > 0 or independentBans > 0 then
        groups = groups + 1
        independentGroupSize = math.max(independentPicks, independentBans)
    end
    local monsterGroupSize = 0
    if monsterPicks > 0 or monsterBans > 0 then
        groups = groups + 1
        monsterGroupSize = math.max(monsterPicks, monsterBans)
    end
    local detectiveGroupSize = 0
    if detectivePicks > 0 or detectiveBans > 0 then
        groups = groups + 1
        detectiveGroupSize = math.max(detectivePicks, detectiveBans)
    end

    local totalSize = innocentGroupSize + traitorGroupSize + jesterGroupSize + independentGroupSize + monsterGroupSize + detectiveGroupSize
    local width = ((groups - 1) * (groupDividerWidth + (2 * groupMargin))) + (totalSize * smallIconSize) + ((totalSize + groups - 2) * smallIconMargin)
    local x = (ScrW() - width) / 2

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
        table.insert(dividerPositions, x + ((smallIconSize + smallIconMargin) * detectiveGroupSize) + groupMargin)
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
        table.insert(dividerPositions, x + ((smallIconSize + smallIconMargin) * innocentGroupSize) + groupMargin)
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
        table.insert(dividerPositions, x + ((smallIconSize + smallIconMargin) * traitorGroupSize) + groupMargin)
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
        table.insert(dividerPositions, x + ((smallIconSize + smallIconMargin) * jesterGroupSize) + groupMargin)
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
        table.insert(dividerPositions, x + ((smallIconSize + smallIconMargin) * independentGroupSize) + groupMargin)
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
        table.insert(dividerPositions, x + ((smallIconSize + smallIconMargin) * monsterGroupSize) + groupMargin)
        if monsterPicks >= monsterBans then
            groupPositions[ROLE_TEAM_MONSTER]["picks"]["x"] = x
            groupPositions[ROLE_TEAM_MONSTER]["bans"]["x"] = x + ((monsterPicks - monsterBans) / 2) * (smallIconSize + smallIconMargin)
        else
            groupPositions[ROLE_TEAM_MONSTER]["bans"]["x"] = x
            groupPositions[ROLE_TEAM_MONSTER]["picks"]["x"] = x + ((monsterBans - monsterPicks) / 2) * (smallIconSize + smallIconMargin)
        end
    end

    table.remove(dividerPositions)

    return {["groups"] = groupPositions, ["dividers"] = dividerPositions}
end

local function CalculateBottomIconPositions(draftOrder)
    local width = (#draftOrder * (smallIconSize + (2 * smallIconMargin))) - (2 * smallIconMargin)
    local x = (ScrW() - width) / 2
    return {["x"] = x, ["width"] = width, ["order"] = draftOrder}
end

local function CalculateCentreIconPositions(roles)
    local positions = {}
    for team = ROLE_TEAM_INNOCENT, ROLE_TEAM_DETECTIVE do
        local width = #roles[team] * (largeIconSize + largeIconMargin) - largeIconMargin
        local x = (ScrW() - width) / 2
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

    for _, frame in ipairs(frames) do
        frame:Close()
    end
    frames = {}
end)

net.Receive("TTT_NextRolePackDraft", function()
    randomSelection = net.ReadBool()
    previousSelection = net.ReadInt(util.RoleBits())
    if draftPhase > 0 then
        if bottomPositions.order[draftPhase].action == "pick" then
            table.insert(pickedRoles[bottomPositions.order[draftPhase].team], previousSelection)
        else
            table.insert(bannedRoles[bottomPositions.order[draftPhase].team], previousSelection)
        end
    end
    draftPhase = draftPhase + 1
    if draftPhase > #bottomPositions.order then
        nextPhaseTime = CurTime() + draft_end_time:GetInt()
    else
        nextPhaseTime = CurTime() + draft_turn_time:GetInt()
    end
    selectedRole = nil

    if draftPhase > #bottomPositions.order or player.GetBySteamID64(bottomPositions.order[draftPhase].player) ~= LocalPlayer() then
        if vgui.CursorVisible() then
            gui.EnableScreenClicker(false)
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
local randomIcon = Material("rolepackdraft/random.png")

hook.Add("HUDShouldDraw", "TTTDraft_HUDShouldDraw", function(name)
    if draftPhase >= 0 and name ~= "CHudGMod" then return false end
end)

local teamNames = {
    [ROLE_TEAM_INNOCENT] = "an innocent",
    [ROLE_TEAM_TRAITOR] = "a traitor",
    [ROLE_TEAM_JESTER] = "a jester",
    [ROLE_TEAM_INDEPENDENT] = "an independent",
    [ROLE_TEAM_MONSTER] = "a monster",
    [ROLE_TEAM_DETECTIVE] = "a detective"
}
local mouseDown = false
local lastRandomSelect = 0
hook.Add("HUDDrawScoreBoard", "TTTDraft_HUDDrawScoreBoard", function()
    if draftPhase >= 0 then
        draw.NoTexture()
        surface.SetDrawColor(0, 0, 0, 220)
        surface.DrawRect(0, 0, ScrW(), ScrH())

        for team, group in pairs(topPositions.groups) do
            local x = group.picks.x
            local y = smallIconMargin
            for slot = 1, group.picks.count do
                local bright = false
                if draftPhase >= 1 and draftPhase <= #bottomPositions.order then
                    if bottomPositions.order[draftPhase].action == "pick" and bottomPositions.order[draftPhase].team == team then
                        if slot == #pickedRoles[team] + 1 then
                            bright = true
                            surface.SetDrawColor(GetRoleTeamColor(team, "highlight"))
                            surface.SetMaterial(smallGlow)
                            surface.DrawTexturedRect(x - smallIconGlow, y - smallIconGlow, smallIconSize + (2 * smallIconGlow), smallIconSize + (2 * smallIconGlow))
                        end
                    end
                end
                draw.NoTexture()
                surface.SetDrawColor(COLOR_BLACK)
                surface.DrawRect(x, y, smallIconSize, smallIconSize)
                surface.SetDrawColor(GetRoleTeamColor(team, "highlight"))
                surface.SetMaterial(smallOutline)
                surface.DrawTexturedRect(x - smallIconOutline, y - smallIconOutline, smallIconSize + (2 * smallIconOutline), smallIconSize + (2 * smallIconOutline))
                if slot > #pickedRoles[team] then
                    if bright then
                        surface.SetDrawColor(COLOR_WHITE)
                    else
                        surface.SetDrawColor(255, 255, 255, 127)
                    end
                    surface.SetMaterial(pickIcon)
                else
                    surface.SetDrawColor(COLOR_WHITE)
                    surface.SetMaterial(Material(util.GetRoleIconPath(ROLE_STRINGS_SHORT[pickedRoles[team][slot]], "score", "png")))
                end
                surface.DrawTexturedRect(x, y, smallIconSize, smallIconSize)
                x = x + smallIconSize + smallIconMargin
            end
            x = group.bans.x
            y = smallIconSize + (2 * smallIconMargin)
            for slot = 1, group.bans.count do
                local bright = false
                if draftPhase >= 1 and draftPhase <= #bottomPositions.order then
                    if bottomPositions.order[draftPhase].action == "ban" and bottomPositions.order[draftPhase].team == team then
                        if slot == #bannedRoles[team] + 1 then
                            bright = true
                            surface.SetDrawColor(GetRoleTeamColor(team, "highlight"))
                            surface.SetMaterial(smallGlow)
                            surface.DrawTexturedRect(x - smallIconGlow, y - smallIconGlow, smallIconSize + (2 * smallIconGlow), smallIconSize + (2 * smallIconGlow))
                        end
                    end
                end
                draw.NoTexture()
                surface.SetDrawColor(COLOR_BLACK)
                surface.DrawRect(x, y, smallIconSize, smallIconSize)
                surface.SetDrawColor(GetRoleTeamColor(team, "highlight"))
                surface.SetMaterial(smallOutline)
                surface.DrawTexturedRect(x - smallIconOutline, y - smallIconOutline, smallIconSize + (2 * smallIconOutline), smallIconSize + (2 * smallIconOutline))
                if slot > #bannedRoles[team] then
                    if bright then
                        surface.SetDrawColor(COLOR_WHITE)
                    else
                        surface.SetDrawColor(255, 255, 255, 127)
                    end
                    surface.SetMaterial(banIcon)
                else
                    surface.SetDrawColor(255, 255, 255, 127)
                    surface.SetMaterial(Material(util.GetRoleIconPath(ROLE_STRINGS_SHORT[bannedRoles[team][slot]], "score", "png")))
                end
                surface.DrawTexturedRect(x, y, smallIconSize, smallIconSize)
                x = x + smallIconSize + smallIconMargin
            end
        end

        draw.NoTexture()
        local y = (1.5 * smallIconMargin) + (0.5 * smallIconSize)
        for _, divider in pairs(topPositions.dividers) do
            surface.SetDrawColor(COLOR_WHITE)
            surface.DrawRect(divider, y, groupDividerWidth, smallIconSize)
        end

        y = (2 * smallIconSize) + (3 * smallIconMargin)
        local time = math.max(0, nextPhaseTime - CurTime())
        local progress
        if draftPhase == 0 then
            progress = time / draft_prep_time:GetInt()
        elseif draftPhase > #bottomPositions.order then
            progress = time / draft_end_time:GetInt()
        else
            progress = time / draft_turn_time:GetInt()
        end
        draw.SimpleText(string.format("%05.2f", time), "DraftTimer", ScrW() / 2, y, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        surface.DrawRect((ScrW() - (timerWidth * progress)) / 2, y + smallIconSize + smallIconMargin, (timerWidth * progress), groupDividerWidth)

        local x = bottomPositions.x
        y = ScrH() - smallIconSize - smallIconMargin
        draw.NoTexture()
        surface.SetDrawColor(COLOR_WHITE)
        surface.DrawRect(x + (0.5 * smallIconSize), y + (0.5 * (smallIconSize - groupDividerWidth)), bottomPositions.width - smallIconSize, groupDividerWidth)

        if draftPhase >= 1 and draftPhase <= #bottomPositions.order then
            surface.SetDrawColor(GetRoleTeamColor(bottomPositions.order[draftPhase].team, "highlight"))
            surface.SetMaterial(smallGlow)
            surface.DrawTexturedRect(x - smallIconGlow + ((draftPhase - 1) * (smallIconSize + (2 * smallIconMargin))), y - smallIconGlow, smallIconSize + (2 * smallIconGlow), smallIconSize + (2 * smallIconGlow))
        end

        local createFrames = #frames == 0

        for order, turn in ipairs(bottomPositions.order) do
            if turn.player then
                if createFrames then
                    local frame = vgui.Create("DFrame")
                    frame:SetPos(x, y)
                    frame:SetSize(smallIconSize, smallIconSize)
                    frame:ShowCloseButton(false)
                    frame.Paint = function() end
                    table.insert(frames, frame)
                    local avatar = vgui.Create("AvatarImage", frame)
                    avatar:SetPlayer(player.GetBySteamID64(turn.player))
                    avatar:SetSize(smallIconSize, smallIconSize)
                    frame.avatar = avatar
                    local panel = vgui.Create("DPanel", frame)
                    panel:SetSize(smallIconSize, smallIconSize)
                    frame.panel = panel
                end
            else
                draw.NoTexture()
                surface.SetDrawColor(COLOR_BLACK)
                surface.DrawRect(x, y, smallIconSize, smallIconSize)
                if order < draftPhase then
                    surface.SetDrawColor(255, 255, 255, 32)
                elseif order > draftPhase then
                    surface.SetDrawColor(255, 255, 255, 127)
                else
                    surface.SetDrawColor(COLOR_WHITE)
                end
                surface.SetMaterial(randomIcon)
                surface.DrawTexturedRect(x, y, smallIconSize, smallIconSize)
            end

            surface.SetDrawColor(GetRoleTeamColor(turn.team, "highlight"))
            surface.SetMaterial(smallOutline)
            surface.DrawTexturedRect(x - smallIconOutline, y - smallIconOutline, smallIconSize + (2 * smallIconOutline), smallIconSize + (2 * smallIconOutline))
            if order < draftPhase then
                surface.SetDrawColor(255, 255, 255, 32)
                frames[order].panel:SetBackgroundColor(Color(0, 0, 0, 223))
                frames[order].panel:SetDrawBackground(true)
            elseif order > draftPhase then
                surface.SetDrawColor(255, 255, 255, 127)
                frames[order].panel:SetBackgroundColor(Color(0, 0, 0, 127))
                frames[order].panel:SetDrawBackground(true)
            else
                surface.SetDrawColor(COLOR_WHITE)
                frames[order].panel:SetDrawBackground(false)
            end
            if turn.action == "pick" then
                surface.SetMaterial(pickIcon)
            else
                surface.SetMaterial(banIcon)
            end
            surface.DrawTexturedRect(x, y - smallIconSize, smallIconSize, smallIconSize)
            x = x + smallIconSize + (2 * smallIconMargin)
        end

        if draftPhase >= 1 and draftPhase <= #bottomPositions.order then
            local turn = bottomPositions.order[draftPhase]
            x = centrePositions[turn.team].x
            y = (ScrH() - largeIconSize) / 2

            local cursorX, cursorY = -1, -1
            if player.GetBySteamID64(turn.player) == LocalPlayer() then
                if not vgui.CursorVisible() then
                    gui.EnableScreenClicker(true)
                end

                cursorX, cursorY = input.GetCursorPos()
            elseif turn.player == nil then
                if CurTime() - lastRandomSelect > 0.5 then
                    lastRandomSelect = CurTime()
                    selectedRole = math.random(1, #availableRoles[turn.team])
                    while table.HasValue(pickedRoles[turn.team], selectedRole) or table.HasValue(bannedRoles[turn.team], selectedRole) do
                        selectedRole = selectedRole + 1
                        if selectedRole > #availableRoles[turn.team] then
                            selectedRole = 1
                        end
                    end
                end
            end

            for _, role in ipairs(availableRoles[turn.team]) do
                local hover = false
                local selected = selectedRole == role
                if cursorX >= x and cursorX <= x + largeIconSize and cursorY >= y and cursorY <= y + largeIconSize then
                    if not table.HasValue(pickedRoles[turn.team], role) and not table.HasValue(bannedRoles[turn.team], role) then
                        hover = true
                        if input.IsMouseDown(MOUSE_LEFT) then
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
                    surface.SetDrawColor(GetRoleTeamColor(turn.team, "highlight"))
                    surface.SetMaterial(largeGlow)
                    surface.DrawTexturedRect(x - largeIconGlow, y - largeIconGlow, largeIconSize + (2 * largeIconGlow), largeIconSize + (2 * largeIconGlow))
                elseif hover then
                    surface.SetDrawColor(ColorAlpha(GetRoleTeamColor(turn.team, "highlight"), 128))
                    surface.SetMaterial(largeGlow)
                    surface.DrawTexturedRect(x - largeIconGlow, y - largeIconGlow, largeIconSize + (2 * largeIconGlow), largeIconSize + (2 * largeIconGlow))
                end

                draw.NoTexture()
                surface.SetDrawColor(COLOR_BLACK)
                surface.DrawRect(x, y, largeIconSize, largeIconSize)
                if table.HasValue(pickedRoles[turn.team], role) or table.HasValue(bannedRoles[turn.team], role) then
                    surface.SetDrawColor(255, 255, 255, 32)
                    draw.SimpleText(ROLE_STRINGS[role], "DraftName", x + (0.5 * largeIconSize), y + largeIconSize + (0.25 * largeIconMargin), Color(255, 255, 255, 32), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                elseif selected or hover then
                    surface.SetDrawColor(COLOR_WHITE)
                    draw.SimpleText(ROLE_STRINGS[role], "DraftName", x + (0.5 * largeIconSize), y + largeIconSize + (0.25 * largeIconMargin), COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                else
                    surface.SetDrawColor(255, 255, 255, 191)
                    draw.SimpleText(ROLE_STRINGS[role], "DraftName", x + (0.5 * largeIconSize), y + largeIconSize + (0.25 * largeIconMargin), Color(255, 255, 255, 191), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
                surface.SetMaterial(ROLE_SPRITE_ICON_MATERIALS[ROLE_STRINGS_SHORT[role]])
                surface.DrawTexturedRect(x, y, largeIconSize, largeIconSize)
                surface.SetDrawColor(GetRoleTeamColor(turn.team, "highlight"))
                surface.SetMaterial(largeOutline)
                surface.DrawTexturedRect(x - largeIconOutline, y - largeIconOutline, largeIconSize + (2 * largeIconOutline), largeIconSize + (2 * largeIconOutline))
                x = x + largeIconSize + largeIconMargin
            end
        end

        x = ScrW() / 2
        if draftPhase == 0 then
            draw.SimpleText("Role pack draft starting soon", "DraftLarge", x, ScrH() / 2, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            local nextTurn = bottomPositions.order[1]
            local nextPly = player.GetBySteamID64(nextTurn.player)

            local action
            if nextTurn.action == "pick" then
                action = "picking"
            else
                action = "banning"
            end

            local message
            local color = Color(255, 255, 255, 128)
            if nextPly == LocalPlayer() then
                color = COLOR_WHITE
                message = "You are " .. action .. "ing first"
            elseif nextTurn.player == nil then
                message = "Randomly " .. action .. "ing first"
            else
                message = nextPly:Nick() .. " is " .. action .. "ing first"
            end
            draw.SimpleText(message, "DraftRegular", x, (ScrH() / 2) + largeIconSize, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif draftPhase > #bottomPositions.order then
            draw.SimpleText("Role pack draft finished", "DraftLarge", x, ScrH() / 2, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            local lastTurn = bottomPositions.order[#bottomPositions.order]
            local lastPly = player.GetBySteamID64(lastTurn.player)

            local action
            if lastTurn.action == "pick" then
                action = "picked"
            else
                action = "banned"
            end

            if lastPly == LocalPlayer() then
                if randomSelection then
                    message = "You ran out of time and randomly " .. action .. " " .. ROLE_STRINGS[previousSelection]
                else
                    message = "You " .. action .. " " .. ROLE_STRINGS[previousSelection]
                end
            elseif lastTurn.player == nil then
                message = "Randomly " .. action .. " " .. ROLE_STRINGS[previousSelection]
            else
                if randomSelection then
                    message = lastPly:Nick() .. " ran out of time and randomly " .. action .. " " .. ROLE_STRINGS[previousSelection]
                else
                    message = lastPly:Nick() .. " " .. action .. " " .. ROLE_STRINGS[previousSelection]
                end
            end
            draw.SimpleText(message, "DraftRegular", x, (ScrH() / 2) + largeIconSize, Color(255, 255, 255, 128), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            local turn = bottomPositions.order[draftPhase]
            local ply = player.GetBySteamID64(turn.player)

            local action
            if turn.action == "pick" then
                action = "picking"
            else
                action = "banning"
            end

            local message
            local color = Color(255, 255, 255, 128)
            if ply == LocalPlayer() then
                color = COLOR_WHITE
                message = "Your turn to " .. action .. " " .. teamNames[turn.team]
            elseif turn.player == nil then
                message = "Randomly " .. action .. "ing " .. teamNames[turn.team]
            else
                message = ply:Nick() .. " is " .. action .. "ing " .. teamNames[turn.team]
            end
            draw.SimpleText(message, "DraftLarge", x, (ScrH() - largeIconSize) / 2 - (0.5 * largeIconMargin), color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

            y = (ScrH() + largeIconSize) / 2 + largeIconMargin
            if draftPhase > 1 then
                local lastTurn = bottomPositions.order[draftPhase - 1]
                local lastPly = player.GetBySteamID64(lastTurn.player)

                if lastTurn.action == "pick" then
                    action = "picked"
                else
                    action = "banned"
                end

                if lastPly == LocalPlayer() then
                    if randomSelection then
                        message = "You ran out of time and randomly " .. action .. " " .. ROLE_STRINGS[previousSelection]
                    else
                        message = "You " .. action .. " " .. ROLE_STRINGS[previousSelection]
                    end
                elseif lastTurn.player == nil then
                    message = "Randomly " .. action .. " " .. ROLE_STRINGS[previousSelection]
                else
                    if randomSelection then
                        message = lastPly:Nick() .. " ran out of time and randomly " .. action .. " " .. ROLE_STRINGS[previousSelection]
                    else
                        message = lastPly:Nick() .. " " .. action .. " " .. ROLE_STRINGS[previousSelection]
                    end
                end
                draw.SimpleText(message, "DraftRegular", x, y, Color(255, 255, 255, 128), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

                y = y + (0.75 * largeIconSize)
            end

            if draftPhase < #bottomPositions.order then
                local nextTurn = bottomPositions.order[draftPhase + 1]
                local nextPly = player.GetBySteamID64(nextTurn.player)

                if nextTurn.action == "pick" then
                    action = "picking"
                else
                    action = "banning"
                end

                color = Color(255, 255, 255, 128)
                if nextPly == LocalPlayer() then
                    color = COLOR_WHITE
                    message = "You are " .. action .. "ing next"
                elseif nextTurn.player == nil then
                    message = "Randomly " .. action .. "ing next"
                else
                    message = nextPly:Nick() .. " is " .. action .. "ing next"
                end
                draw.SimpleText(message, "DraftRegular", x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end
    end
end)