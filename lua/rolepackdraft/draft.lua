local maxIterations = 10
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

util.AddNetworkString("TTT_BeginRolePackDraft")
util.AddNetworkString("TTT_BeginRolePackDraft_Part")
util.AddNetworkString("TTT_NextRolePackDraft")
util.AddNetworkString("TTT_SelectRolePackDraft")
util.AddNetworkString("TTT_UpdateRolePackDraft")
util.AddNetworkString("TTT_EndRolePackDraft")

local function RandomisePickBanOrder(iteration)
    if not iteration then iteration = 0 end

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

    local validPlayers = {}
    for _, ply in player.Iterator() do
        if (not ply:IsSpec() or not ply:GetForceSpec()) and not ply:IsBot() then
            table.insert(validPlayers, ply)
        end
    end
    local playerCount = #validPlayers

    local picks = {}
    for _ = 1, innocentPicks do table.insert(picks, ROLE_TEAM_INNOCENT) end
    for _ = 1, traitorPicks do table.insert(picks, ROLE_TEAM_TRAITOR) end
    for _ = 1, jesterPicks do table.insert(picks, ROLE_TEAM_JESTER) end
    for _ = 1, independentPicks do table.insert(picks, ROLE_TEAM_INDEPENDENT) end
    for _ = 1, monsterPicks do table.insert(picks, ROLE_TEAM_MONSTER) end
    for _ = 1, detectivePicks do table.insert(picks, ROLE_TEAM_DETECTIVE) end

    local remainingPicks = {
        [ROLE_TEAM_INNOCENT] = innocentPicks,
        [ROLE_TEAM_TRAITOR] = traitorPicks,
        [ROLE_TEAM_JESTER] = jesterPicks,
        [ROLE_TEAM_INDEPENDENT] = independentPicks,
        [ROLE_TEAM_MONSTER] = monsterPicks,
        [ROLE_TEAM_DETECTIVE] = detectivePicks
    }
    local playerPicks = math.floor((#picks) / playerCount)
    local randomPicks = math.fmod(#picks, playerCount)

    local bans = {}
    for _ = 1, innocentBans do table.insert(bans, ROLE_TEAM_INNOCENT) end
    for _ = 1, traitorBans do table.insert(bans, ROLE_TEAM_TRAITOR) end
    for _ = 1, jesterBans do table.insert(bans, ROLE_TEAM_JESTER) end
    for _ = 1, independentBans do table.insert(bans, ROLE_TEAM_INDEPENDENT) end
    for _ = 1, monsterBans do table.insert(bans, ROLE_TEAM_MONSTER) end
    for _ = 1, detectiveBans do table.insert(bans, ROLE_TEAM_DETECTIVE) end
    table.Shuffle(bans)

    local remainingBans = {
        [ROLE_TEAM_INNOCENT] = innocentBans,
        [ROLE_TEAM_TRAITOR] = traitorBans,
        [ROLE_TEAM_JESTER] = jesterBans,
        [ROLE_TEAM_INDEPENDENT] = independentBans,
        [ROLE_TEAM_MONSTER] = monsterBans,
        [ROLE_TEAM_DETECTIVE] = detectiveBans
    }
    local playerBans = math.floor((#bans) / playerCount)
    local randomBans = math.fmod(#bans, playerCount)

    local function checkPossible(neededTeams, chosenTeams)
        if iteration >= maxIterations then return true end

        local remainingTeams = 0
        for team = ROLE_TEAM_INNOCENT, ROLE_TEAM_DETECTIVE do
            if not chosenTeams[team] and remainingPicks[team] + remainingBans[team] > 0 then
                remainingTeams = remainingTeams + 1
            end
        end
        return remainingTeams >= neededTeams
    end

    local players = {}
    for _, ply in ipairs(validPlayers) do
        local hasTeam = {
            [ROLE_TEAM_INNOCENT] = false,
            [ROLE_TEAM_TRAITOR] = false,
            [ROLE_TEAM_JESTER] = false,
            [ROLE_TEAM_INDEPENDENT] = false,
            [ROLE_TEAM_MONSTER] = false,
            [ROLE_TEAM_DETECTIVE] = false
        }

        local pickRoles = {}
        for i = 1, playerPicks do
            if not checkPossible(playerPicks + playerBans - (i-1), hasTeam) then
                return RandomisePickBanOrder(iteration + 1)
            end

            local found = false
            local count = #picks
            while not found do
                local pick = table.remove(picks, 1)
                if hasTeam[pick] and iteration < maxIterations and count > 0 then
                    table.insert(picks, pick)
                    count = count - 1
                elseif iteration < maxIterations and count <= 0 then
                    return RandomisePickBanOrder(iteration + 1)
                else
                    table.insert(pickRoles, pick)
                    hasTeam[pick] = true
                    remainingPicks[pick] = remainingPicks[pick] - 1
                    found = true
                end
            end
        end
        local banRoles = {}
        for i = 1, playerBans do
            if not checkPossible(playerBans - (i-1), hasTeam) then
                return RandomisePickBanOrder(iteration + 1)
            end

            local found = false
            local count = #bans
            while not found do
                local ban = table.remove(bans, 1)
                if hasTeam[ban] and iteration < maxIterations and count > 0 then
                    table.insert(bans, ban)
                    count = count - 1
                elseif iteration < maxIterations and count <= 0 then
                    return RandomisePickBanOrder(iteration + 1)
                else
                    table.insert(banRoles, ban)
                    hasTeam[ban] = true
                    remainingBans[ban] = remainingBans[ban] - 1
                    found = true
                end
            end
        end
        table.insert(players, {["sid64"] = ply:SteamID64(), ["picks"] = pickRoles, ["bans"] = banRoles})
    end

    local order = {}
    for _, ply in ipairs(players) do
        for _, pick in ipairs(ply["picks"]) do
            table.insert(order, { ["player"] = ply.sid64, ["action"] = "pick", ["team"] = pick})
        end
        for _, ban in ipairs(ply["bans"]) do
            table.insert(order, { ["player"] = ply.sid64, ["action"] = "ban", ["team"] = ban})
        end
    end
    for _ = 1, randomPicks do
        table.insert(order, {["player"] = nil, ["action"] = "pick", ["team"] = table.remove(picks)})
    end
    for _ = 1, randomBans do
        table.insert(order, {["player"] = nil, ["action"] = "ban", ["team"] = table.remove(bans)})
    end
    table.Shuffle(order)

    local ordered = false
    while not ordered do
        ordered = true
        local lastPick = {
            [ROLE_TEAM_INNOCENT] = -1,
            [ROLE_TEAM_TRAITOR] = -1,
            [ROLE_TEAM_JESTER] = -1,
            [ROLE_TEAM_INDEPENDENT] = -1,
            [ROLE_TEAM_MONSTER] = -1,
            [ROLE_TEAM_DETECTIVE] = -1
        }
        local lastBan = {
            [ROLE_TEAM_INNOCENT] = -1,
            [ROLE_TEAM_TRAITOR] = -1,
            [ROLE_TEAM_JESTER] = -1,
            [ROLE_TEAM_INDEPENDENT] = -1,
            [ROLE_TEAM_MONSTER] = -1,
            [ROLE_TEAM_DETECTIVE] = -1
        }
        for k, v in ipairs(order) do
            if v.action == "pick" then
                lastPick[v.team] = k
            else
                lastBan[v.team] = k
            end
        end
        for team, position in pairs(lastBan) do
            if position > lastPick[team] then
                order[position], order[lastPick[team]] = order[lastPick[team]], order[position]
                ordered = false
            end
        end
    end

    return order
end

local teamNames = {
    [ROLE_TEAM_INNOCENT] = "innocents",
    [ROLE_TEAM_TRAITOR] = "traitors",
    [ROLE_TEAM_JESTER] = "jesters",
    [ROLE_TEAM_INDEPENDENT] = "independents",
    [ROLE_TEAM_MONSTER] = "monsters",
    [ROLE_TEAM_DETECTIVE] = "detectives"
}

local function ReadAvailableRoles()
    local dataJson = file.Read("rolepackdraft.json", "DATA")
    if #dataJson == 0 then
        ErrorNoHalt("Role pack draft roles list read failed!\n")
        return
    end

    local dataTable = util.JSONToTable(dataJson)
    if dataTable == nil then
        ErrorNoHalt("Role pack draft roles list table conversion failed!\n")
        return
    end

    local roles = {
        [ROLE_TEAM_INNOCENT] = {},
        [ROLE_TEAM_TRAITOR] = {},
        [ROLE_TEAM_JESTER] = {},
        [ROLE_TEAM_INDEPENDENT] = {},
        [ROLE_TEAM_MONSTER] = {},
        [ROLE_TEAM_DETECTIVE] = {}
    }

    for team = ROLE_TEAM_INNOCENT, ROLE_TEAM_DETECTIVE do
        local teamRoles = dataTable.roles[teamNames[team]]
        for _, roleStr in ipairs(teamRoles) do
            for role = ROLE_INNOCENT, ROLE_MAX do
                if ROLE_STRINGS_RAW[role] == roleStr then
                    table.insert(roles[team], role)
                end
            end
        end
    end

    return roles
end

local draftPhase = -1
local selected
local order = {}
local roles = {}
local picked = {
    [ROLE_TEAM_INNOCENT] = {},
    [ROLE_TEAM_TRAITOR] = {},
    [ROLE_TEAM_JESTER] = {},
    [ROLE_TEAM_INDEPENDENT] = {},
    [ROLE_TEAM_MONSTER] = {},
    [ROLE_TEAM_DETECTIVE] = {}
}
local banned = {
    [ROLE_TEAM_INNOCENT] = {},
    [ROLE_TEAM_TRAITOR] = {},
    [ROLE_TEAM_JESTER] = {},
    [ROLE_TEAM_INDEPENDENT] = {},
    [ROLE_TEAM_MONSTER] = {},
    [ROLE_TEAM_DETECTIVE] = {}
}

function EndRolePackDraft()
    RunConsoleCommand("ttt_roundrestart")

    timer.Remove("TTT_Draft_NextTurn")

    draftPhase = -1
    selected = nil
    order = {}
    roles = {}
    picked = {
        [ROLE_TEAM_INNOCENT] = {},
        [ROLE_TEAM_TRAITOR] = {},
        [ROLE_TEAM_JESTER] = {},
        [ROLE_TEAM_INDEPENDENT] = {},
        [ROLE_TEAM_MONSTER] = {},
        [ROLE_TEAM_DETECTIVE] = {}
    }
    banned = {
        [ROLE_TEAM_INNOCENT] = {},
        [ROLE_TEAM_TRAITOR] = {},
        [ROLE_TEAM_JESTER] = {},
        [ROLE_TEAM_INDEPENDENT] = {},
        [ROLE_TEAM_MONSTER] = {},
        [ROLE_TEAM_DETECTIVE] = {}
    }

    net.Start("TTT_EndRolePackDraft")
    net.Broadcast()
end

local function NextRolePackDraft()
    net.Start("TTT_NextRolePackDraft")
    if draftPhase == 0 then
        net.WriteBool(false)
        net.WriteInt(0, util.RoleBits())
    else
        local team = order[draftPhase].team
        if not selected then
            net.WriteBool(true)
            local roleIndex = math.random(1, #roles[team])
            while table.HasValue(picked[team], roles[team][roleIndex]) or table.HasValue(banned[team], roles[team][roleIndex]) do
                roleIndex = roleIndex + 1
                if roleIndex > #roles[team] then roleIndex = 1 end
            end
            selected = roles[team][roleIndex]
        else
            net.WriteBool(false)
        end

        if order[draftPhase].action == "pick" then
            table.insert(picked[team], selected)
        else
            table.insert(banned[team], selected)
        end
        net.WriteInt(selected, util.RoleBits())
    end
    net.Broadcast()

    selected = nil
    draftPhase = draftPhase + 1

    if draftPhase >= 1 and draftPhase <= #order then
        timer.Create("TTT_Draft_NextTurn", draft_turn_time:GetInt(), 0, NextRolePackDraft)
    elseif draftPhase == #order + 1 then
        timer.Create("TTT_Draft_NextTurn", draft_end_time:GetInt(), 1, function() EndRolePackDraft() end)

        local dataJson = file.Read("rolepackdraft.json", "DATA")
        if #dataJson == 0 then
            ErrorNoHalt("Role pack draft roles list read failed!\n")
            return
        end

        local dataTable = util.JSONToTable(dataJson)
        if dataTable == nil then
            ErrorNoHalt("Role pack draft roles list table conversion failed!\n")
            return
        end

        local rolePackJson = "{\"slots\":["
        for _, slot in ipairs(dataTable.slots) do
            rolePackJson = rolePackJson .. "["
            for _, group in ipairs(slot.groups) do
                local team = ROLE_TEAM_INNOCENT
                if group == "traitors" then team = ROLE_TEAM_TRAITOR end
                if group == "jesters" then team = ROLE_TEAM_JESTER end
                if group == "independents" then team = ROLE_TEAM_INDEPENDENT end
                if group == "monsters" then team = ROLE_TEAM_MONSTER end
                if group == "detectives" then team = ROLE_TEAM_DETECTIVE end
                for _, role in ipairs(picked[team]) do
                    rolePackJson = rolePackJson .. "{\"weight\":1,\"role\":\"" .. ROLE_STRINGS_RAW[role] .. "\"},"
                end
            end
            for _, constant in ipairs(slot.constants) do
                rolePackJson = rolePackJson .. "{\"weight\":1,\"role\":\"" .. constant .. "\"},"
            end
            rolePackJson = string.sub(rolePackJson, 1, -2) .. "],"
        end
        rolePackJson = string.sub(rolePackJson, 1, -2) .. "],\"name\":\"draft\",\"config\":{\"allowduplicates\":"
        if dataTable.config.allowduplicates then
            rolePackJson = rolePackJson .. "true"
        else
            rolePackJson = rolePackJson .. "false"
        end
        rolePackJson = rolePackJson .. "}}"

        if not file.IsDir("rolepacks", "DATA") then
            if file.Exists("rolepacks", "DATA") then
                ErrorNoHalt("Item named 'rolepacks' already exists in garrysmod/data but it is not a directory\n")
                return
            end

            file.CreateDir("rolepacks")
        end
        file.CreateDir("rolepacks/draft")
        file.Write("rolepacks/draft/roles.json", rolePackJson)
        file.CreateDir("rolepacks/draft/weapons")
        file.Write("rolepacks/draft/convars.json", "{}")

        GetConVar("ttt_role_pack"):SetString("draft")
    end
end

function BeginRolePackDraft()
    order = RandomisePickBanOrder()
    roles = ReadAvailableRoles()

    local dataJson = util.TableToJSON({["order"] = order, ["roles"] = roles})
    if not dataJson or #dataJson == 0 then
        ErrorNoHalt("Role pack draft table conversion failed!\n")
        return
    end

    local dataComp = util.Compress(dataJson)
    if #dataComp == 0 then
        ErrorNoHalt("Role pack draft table compression failed!\n")
        return
    end

    local len = #dataComp

    if len <= maxStreamLength then
        net.Start("TTT_BeginRolePackDraft")
        net.WriteUInt(len, 16)
        net.WriteData(dataComp, len)
        net.Broadcast()
    else
        local curPos = 0

        repeat
            net.Start("TTT_BeginRolePackDraft_Part")
            net.WriteData(string.sub(dataComp, curPos + 1, curPos + maxStreamLength + 1), maxStreamLength)
            net.Broadcast()

            curPos = curPos + maxStreamLength + 1
        until (len - curPos <= maxStreamLength)

        net.Start("TTT_BeginRolePackDraft")
        net.WriteUInt(len, 16)
        net.WriteData(string.sub(dataComp, curPos + 1, len), len - curPos)
        net.Broadcast()
    end

    local time = draft_prep_time:GetInt() + (draft_turn_time:GetInt() * #order) + draft_end_time:GetInt() + 1
    RunConsoleCommand("ttt_roundrestart")
    timer.Simple(0, function()
        SetRoundEnd(CurTime() + time)
        timer.Remove("prep2begin")
        timer.Remove("selectmute")
        timer.Create("prep2begin", time, 1, BeginRound)
        timer.Create("selectmute", time - 1, 1, function() MuteForRestart(true) end)
    end)

    draftPhase = 0
    timer.Create("TTT_Draft_NextTurn", draft_prep_time:GetInt(), 0, NextRolePackDraft)
end
concommand.Add("ttt_draft_begin", BeginRolePackDraft, nil, "Starts a role pack draft", FCVAR_SERVER_CAN_EXECUTE)
concommand.Add("ttt_draft_cancel", function() EndRolePackDraft() end, nil, "Cancels a role pack draft", FCVAR_SERVER_CAN_EXECUTE)

net.Receive("TTT_SelectRolePackDraft", function(_, ply)
    local role = net.ReadInt(util.RoleBits())
    local turn = net.ReadUInt(8)

    if turn ~= draftPhase then return end
    if ply:SteamID64() ~= order[draftPhase].player then return end

    selected = role

    net.Start("TTT_UpdateRolePackDraft")
    net.WriteInt(role, util.RoleBits())
    net.Broadcast()
end)