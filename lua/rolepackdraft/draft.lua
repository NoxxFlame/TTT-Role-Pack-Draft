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

util.AddNetworkString("TTT_BeginRolePackDraft")
util.AddNetworkString("TTT_BeginRolePackDraft_Part")

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
        if not ply:IsSpec() or not ply:GetForceSpec() then
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
    table.Shuffle(picks)

    local remainingPicks = {
        [ROLE_TEAM_INNOCENT] = innocentPicks,
        [ROLE_TEAM_TRAITOR] = traitorPicks,
        [ROLE_TEAM_JESTER] = jesterPicks,
        [ROLE_TEAM_INDEPENDENT] = independentPicks,
        [ROLE_TEAM_MONSTER] = monsterPicks,
        [ROLE_TEAM_DETECTIVE] = detectivePicks
    }
    local playerPicks = #picks // playerCount
    local randomPicks = #picks % playerCount

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
    local playerBans = #bans // playerCount
    local randomBans = #bans % playerCount

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

local function ReadAvailableRoles()
    return {}
end

function BeginRolePackDraft()
    local order = RandomisePickBanOrder()
    local roles = ReadAvailableRoles()

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
        local curpos = 0

        repeat
            net.Start("TTT_BeginRolePackDraft_Part")
            net.WriteData(string.sub(dataComp, curpos + 1, curpos + maxStreamLength + 1), maxStreamLength)
            net.Broadcast()

            curpos = curpos + maxStreamLength + 1
        until (len - curpos <= maxStreamLength)

        net.Start("TTT_BeginRolePackDraft")
        net.WriteUInt(len, 16)
        net.WriteData(string.sub(dataComp, curpos + 1, len), len - curpos)
        net.Broadcast()
    end
end

concommand.Add("ttt_draft_begin", BeginRolePackDraft, nil, "Starts a role pack draft", FCVAR_SERVER_CAN_EXECUTE)