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

local smallIconSize = 32
local smallIconMargin = 10
local smallIconOutline = 2
local smallIconGlow = 16
local largeIconSize = 64
local largeIconMargin = 20
local largeIconOutline = 4
local largeIconGlow = 32
local groupDividerWidth = 4
local groupMargin = 10

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
    local width = (#draftOrder.order * (smallIconSize + smallIconMargin)) - smallIconMargin
    local x = (ScrW() - width) / 2
    return {["x"] = x, ["width"] = width, ["order"] = draftOrder.order}
end

local topPositions = {}
local bottomPositions = {}
local function BeginRolePackDraft(draftOrder)
    topPositions = CalculateTopIconPositions()
    bottomPositions = CalculateBottomIconPositions(draftOrder)
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

    print(dataJson)

    local dataTable = util.JSONToTable(dataJson)
    if dataTable == nil then
        ErrorNoHalt("Role pack draft table conversion failed!\n")
        return
    end

    BeginRolePackDraft(dataTable)
end)

local smallOutline = Material("rolepackdraft/outline_small.png")
local smallGlow = Material("rolepackdraft/glow_small.png")
local largeOutline = Material("rolepackdraft/outline_large.png")
local largeGlow = Material("rolepackdraft/glow_large.png")
local pickIcon = Material("rolepackdraft/pick.png")
local banIcon = Material("rolepackdraft/ban.png")
local randomIcon = Material("rolepackdraft/random.png")

local frames = {}

hook.Add("HUDDrawScoreBoard", "TTTDraft_HUDDrawScoreBoard", function()
    if topPositions.groups then
        for team, group in pairs(topPositions.groups) do
            local x = group.picks.x
            local y = smallIconMargin
            for _ = 1, group.picks.count do
                draw.NoTexture()
                surface.SetDrawColor(COLOR_BLACK)
                surface.DrawRect(x, y, smallIconSize, smallIconSize)
                surface.SetDrawColor(GetRoleTeamColor(team), "radar")
                surface.SetMaterial(smallOutline)
                surface.DrawTexturedRect(x - smallIconOutline, y - smallIconOutline, smallIconSize + (2 * smallIconOutline), smallIconSize + (2 * smallIconOutline))
                surface.SetDrawColor(COLOR_WHITE)
                surface.SetMaterial(pickIcon)
                surface.DrawTexturedRect(x, y, smallIconSize, smallIconSize)
                x = x + smallIconSize + smallIconMargin
            end
            x = group.bans.x
            y = smallIconSize + (2 * smallIconMargin)
            for _ = 1, group.bans.count do
                draw.NoTexture()
                surface.SetDrawColor(COLOR_BLACK)
                surface.DrawRect(x, y, smallIconSize, smallIconSize)
                surface.SetDrawColor(GetRoleTeamColor(team), "radar")
                surface.SetMaterial(smallOutline)
                surface.DrawTexturedRect(x - smallIconOutline, y - smallIconOutline, smallIconSize + (2 * smallIconOutline), smallIconSize + (2 * smallIconOutline))
                surface.SetDrawColor(COLOR_WHITE)
                surface.SetMaterial(banIcon)
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
    end

    if bottomPositions.order then
        local x = bottomPositions.x
        local y = ScrH() - smallIconSize - smallIconMargin
        draw.NoTexture()
        surface.SetDrawColor(COLOR_WHITE)
        surface.DrawRect(x + (0.5 * smallIconSize), y + (0.5 * (smallIconSize - groupDividerWidth)), bottomPositions.width - smallIconSize, groupDividerWidth)

        local createFrames = #frames == 0

        for _, turn in ipairs(bottomPositions.order) do
            if turn.player and createFrames then
                local frame = vgui.Create("DFrame")
                frame:SetPos(x, y)
                frame:SetSize(smallIconSize, smallIconSize)
                frame:ShowCloseButton(false)
                frame.Paint = function() end
                table.insert(frames, frame)
                local avatar = vgui.Create("SimpleIconAvatar", frame)
                avatar:SetPlayer(player.GetBySteamID64(turn.player))
                avatar:SetAvatarSize(32)
                avatar:SetPos(-16, -16)
            else
                draw.NoTexture()
                surface.SetDrawColor(COLOR_BLACK)
                surface.DrawRect(x, y, smallIconSize, smallIconSize)
                surface.SetDrawColor(COLOR_WHITE)
                surface.SetMaterial(randomIcon)
                surface.DrawTexturedRect(x, y, smallIconSize, smallIconSize)
            end
            surface.SetDrawColor(GetRoleTeamColor(turn.team), "radar")
            surface.SetMaterial(smallOutline)
            surface.DrawTexturedRect(x - smallIconOutline, y - smallIconOutline, smallIconSize + (2 * smallIconOutline), smallIconSize + (2 * smallIconOutline))
            surface.SetDrawColor(COLOR_WHITE)
            if turn.action == "pick" then
                surface.SetMaterial(pickIcon)
            else
                surface.SetMaterial(banIcon)
            end
            surface.DrawTexturedRect(x, y - smallIconSize, smallIconSize, smallIconSize)
            x = x + smallIconSize + smallIconMargin
        end
    else
        for _, frame in ipairs(frames) do
            frame:Close()
        end
        frames = {}
    end
end)