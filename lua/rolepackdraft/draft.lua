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
local draft_random_time = GetConVar("ttt_draft_random_time")
local draft_end_time = GetConVar("ttt_draft_end_time")

local draft_pick_ends_turn = CreateConVar("ttt_draft_pick_ends_turn", "0", FCVAR_NONE, "Whether selecting a role immediately ends the turn", 0, 1)
local draft_persist_maps = CreateConVar("ttt_draft_persist_maps", "0", FCVAR_NONE, "Number of map switches to persist the drafted role pack", 0)
local draft_allow_bots = CreateConVar("ttt_draft_allow_bots", "0", FCVAR_NONE, "Whether bots are allowed to be included in the draft (used for debugging)", 0, 1)

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
    local allowBots = draft_allow_bots:GetBool()

    local validPlayers = {}
    for _, ply in player.Iterator() do
        if (not ply:IsSpec() or not ply:GetForceSpec()) and not (ply:IsBot() and not allowBots) then
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

    local passes = 0
    while passes < 50 do
        ordered = true
        for i = 1, #order - 1 do
            if order[i].player == order[i+1].player then
                -- If two turns in a row belong to the same player
                if i < #order - 1 then
                    -- If we are not at the end of the table, use the next element as a potential swap
                    if order[i].player ~= order[i+2].player then
                        -- Don't swap if the potential swap belongs to the same player
                        if order[i+1].action == "pick" then
                            -- One of four scenarios:
                            -- PPP (We can safely swap consecutive picks)
                            -- PPB (We can safely swap bans before picks)
                            -- BPP (We can safely swap consecutive picks)
                            -- BPB (We can safely swap bans before picks)
                            -- In any case, we can swap i+1 and i+2
                            ordered = false
                            order[i+1], order[i+2] = order[i+2], order[i+1]
                        else
                            if order[i+2].action == "ban" then
                                -- One of two scenarios:
                                -- PBB (We can safely swap consecutive bans)
                                -- BBB (We can safely swap consecutive bans)
                                -- In either case, we can swap i+1 and i+2
                                ordered = false
                                order[i+1], order[i+2] = order[i+2], order[i+1]
                            else
                                -- One of two scenarios:
                                -- PBP (We can't safely swap picks before bans)
                                -- BBP (We can't safely swap picks before bans)
                                -- In either case, we need to check that i+1 and i+2 aren't the same team
                                if order[i+1].team ~= order[i+2].team then
                                    -- If they aren't the same team, we can safely swap i+1 and i+2
                                    ordered = false
                                    order[i+1], order[i+2] = order[i+2], order[i+1]
                                end
                                -- Otherwise we can't safely swap and are stuck for now
                            end
                        end
                    end
                else
                    -- If we are at the end of the table we have no next element we can swap with. Instead find one earlier in the table
                    if order[i].action == "pick" and order[i+1].action == "pick" then
                        -- If our two turns are both picks, we cannot safely swap a pick before a ban so we need to look at more information
                        -- We do not want to swap the with turn immediately beforehand as this could undo a swap from the previous iteration
                        -- Instead we look at the past two turns
                        if order[i-1].action == "pick" then
                            if order[i-2].action == "pick" then
                                -- One possible scenario
                                -- PPPP (We can safely swap among consecutive picks)
                                -- In this case, we can swap i and i-2
                                ordered = false
                                order[i], order[i-2] = order[i-2], order[i]
                            else
                                -- One possible scenario
                                -- BPPP (We can't safely swap picks before bans)
                                -- In this case, we need to check that i and i-2 as well as i-1 and i-2 aren't the same team
                                if order[i].team ~= order[i-2].team and order[i-1].team ~= order[i-2].team then
                                    -- If they aren't the same team, we can safely swap i and i-2
                                    ordered = false
                                    order[i], order[i-2] = order[i-2], order[i]
                                end
                                -- Otherwise we can't safely swap and are stuck for now
                            end
                        else
                            if order[i-2].action == "pick" then
                                -- One possible scenario
                                -- PBPP (We can't safely swap picks before bans)
                                -- In this case, we need to check that i and i-1 aren't the same team
                                if order[i].team ~= order[i-1].team then
                                    -- If they aren't the same team, we can safely swap i and i-2
                                    ordered = false
                                    order[i], order[i-2] = order[i-2], order[i]
                                end
                                -- Otherwise we can't safely swap and are stuck for now
                            else
                                -- One possible scenario
                                -- BBPP (We can't safely swap picks before bans)
                                -- In this case, we need to check that i and i-2 as well as i and i-1 aren't the same team
                                if order[i].team ~= order[i-2].team and order[i].team ~= order[i-1].team then
                                    -- If they aren't the same team, we can safely swap i and i-2
                                    ordered = false
                                    order[i], order[i-2] = order[i-2], order[i]
                                end
                                -- Otherwise we can't safely swap and are stuck for now
                            end
                        end
                    else
                        -- We know we have at least one ban we can swap earlier and that we can always swap a bans before picks, so find the earliest pick that belongs to a different player
                        for j = 1, #order - 2 do
                            if order[i].player ~= order[j].player and order[j].action == "pick" then
                                -- Don't swap if the potential swap belongs to the same player or if the potential swap is a ban
                                if order[i].action == "ban" then
                                    -- One of two scenarios
                                    -- P...BP (We can safely swap bans before picks)
                                    -- P...BB (We can safely swap bans before picks)
                                    -- In either case, we can swap i and j
                                    ordered = false
                                    order[i], order[j] = order[j], order[i]
                                    break
                                else
                                    if order[i+1].action == "ban" then
                                        -- One possible scenario
                                        -- P...PB (We can safely swap bans before picks)
                                        -- In this case, we can swap i+1 and j
                                        ordered = false
                                        order[i+1], order[j] = order[j], order[i+1]
                                        break
                                    end
                                end
                            end
                        end
                        -- If there are somehow no earlier picks that belong to a different player, we can't safely swap and are stuck for now
                    end
                end
            end
        end
        if ordered then break end
        passes = passes + 1
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
                    if not ROLE_SELECTION_PREDICATE[role] or ROLE_SELECTION_PREDICATE[role]() then
                        table.insert(roles[team], role)
                    end
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

-- Reading picked roles for slotsbyplayercount to update slots on the player count changing
local pickedJson = file.Read("rolepackdraft/picked.json", "DATA")

if pickedJson then
    picked = util.JSONToTable(pickedJson)
end

function EndRolePackDraft()
    RunConsoleCommand("ttt_roundrestart")

    timer.Remove("TTT_Draft_NextTurn")

    net.Start("TTT_EndRolePackDraft")
    net.Broadcast()
end

local function UpdateAndSetDraftRolePack()
    -- Don't write a pack if nothing has been drafted yet (e.g. no picked.json on a fresh install)
    local anyPicked = false
    for _, teamPicks in pairs(picked) do
        if not table.IsEmpty(teamPicks) then
            anyPicked = true
            break
        end
    end
    if not anyPicked then return end

    local dataJson = file.Read("rolepackdraft.json", "DATA")

    if not dataJson or #dataJson == 0 then
        ErrorNoHalt("Role pack draft roles list read failed!\n")
        return
    end

    local dataTable = util.JSONToTable(dataJson)

    if not dataTable then
        ErrorNoHalt("Role pack draft roles list table conversion failed!\n")
        return
    end

    -- First see if there's a slots configuration for the current number of players, else use the default configuration
    local slotList = dataTable.slotsbyplayercount and dataTable.slotsbyplayercount[player.GetCount()] or dataTable.slots
    if not slotList then
        ErrorNoHalt("Role pack draft roles list has no slots!\n")
        return
    end

    -- Building slots list
    -- Build a lua table and let util.TableToJSON serialise it, rather than concatenating JSON by hand
    --[[ Example input:
        "slots": [
            {"groups": ["innocents"], "constants": []},
            {"groups": ["innocents", "jesters"], "constants": []},
            {"groups": ["traitors"], "constants": []},
            {"groups": [], "constants": ["detective"]}
        ],
        Example output:
        "slots": [
            [{"weight": 1, "role": "innocent"}, {"weight": 1, "role": "deputy"}],
            [{"weight": 1, "role": "innocent"}, {"weight": 1, "role": "jester"}],
            [{"weight": 1, "role": "traitor"}, {"weight": 1, "role": "impersonator"}, {"weight": 1, "role": "assassin"}],
            [{"weight": 1, "role": "detective"}]
        ],
    --]]
    local groupToTeam = {
        innocents = ROLE_TEAM_INNOCENT,
        traitors = ROLE_TEAM_TRAITOR,
        jesters = ROLE_TEAM_JESTER,
        independents = ROLE_TEAM_INDEPENDENT,
        monsters = ROLE_TEAM_MONSTER,
        detectives = ROLE_TEAM_DETECTIVE
    }
    local slots = {}
    for i, slot in ipairs(slotList) do
        local entries = {}
        for _, group in ipairs(slot.groups or {}) do
            local team = groupToTeam[group]
            if not team then
                ErrorNoHalt("Role pack draft json config contains unknown role team: '" .. group .."' at slot " .. i .."! Skipping...\n")
                continue
            end
            for _, role in ipairs(picked[team] or {}) do
                local roleString = ROLE_STRINGS_RAW[role]
                if roleString then
                    table.insert(entries, {weight = 1, role = roleString})
                end
            end
        end
        for _, constant in ipairs(slot.constants or {}) do
            table.insert(entries, {weight = 1, role = constant})
        end

        -- If a slot didn't specify any valid role teams nor constant roles, skip this slot
        if table.IsEmpty(entries) then
            ErrorNoHalt("Role pack draft json config contains invalid/empty slot at slot ".. i .."! Skipping...\n")
        else
            table.insert(slots, entries)
        end
    end

    if table.IsEmpty(slots) then
        ErrorNoHalt("Role pack draft json config produced no slots, aborting draft role pack creation\n")
        return
    end

    local rolePackJson = util.TableToJSON({
        slots = slots,
        name = "draft",
        config = {allowduplicates = (dataTable.config and dataTable.config.allowduplicates) and true or false}
    })

    if not rolePackJson or #rolePackJson == 0 then
        ErrorNoHalt("Role pack draft roles.json conversion failed!\n")
        return
    end

    local convars = {}
    for role = ROLE_INNOCENT, ROLE_MAX do
        if not DEFAULT_ROLES[role] and not ROLE_BLOCK_SPAWN_CONVARS[role] and ROLE_STRINGS_RAW[role] then
            table.insert(convars, {invalid = false, cvar = "ttt_" .. ROLE_STRINGS_RAW[role] .. "_enabled", value = "0"})
        end
    end

    local convarsJson = util.TableToJSON({name = "draft", convars = convars})
    if not convarsJson or #convarsJson == 0  then
        ErrorNoHalt("Role pack draft convars.json conversion failed!\n")
        return
    end

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
    file.Write("rolepacks/draft/convars.json", convarsJson)

    GetConVar("ttt_role_pack"):SetString("draft")
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
        local isRandomTurn = order[draftPhase].player == nil
        timer.Create("TTT_Draft_NextTurn", isRandomTurn and draft_random_time:GetInt() or draft_turn_time:GetInt(), 0, NextRolePackDraft)
    elseif draftPhase == #order + 1 then
        timer.Create("TTT_Draft_NextTurn", draft_end_time:GetInt(), 1, function() EndRolePackDraft() end)

        UpdateAndSetDraftRolePack()

        -- Saving picked roles for slotsbyplayercount to update slots on the player count changing
        if not file.IsDir("rolepackdraft", "DATA") then
            file.CreateDir("rolepackdraft")
        end
        file.Write("rolepackdraft/picked.json", util.TableToJSON(picked))
    end
end

local currentDate = os.date("%Y-%m-%d")

function BeginRolePackDraft()
    -- Stats tracking for auto-draft, we want stats to be accurate even if a draft is manually triggered
    SetAutoRoleDraftStat("lastDraftDate", currentDate)
    SetAutoRoleDraftStat("mapLoadsSinceServerStartOrLastDraft", 0)

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

    RunConsoleCommand("ttt_roundrestart")

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

    draftPhase = 0
    local isRandomTurn = order[draftPhase] and order[draftPhase].player == nil
    local turnTime = isRandomTurn and draft_random_time:GetInt() or draft_turn_time:GetInt()
    local time = draft_prep_time:GetInt() + (turnTime * #order) + draft_end_time:GetInt() + 1
    timer.Simple(0, function()
        SetRoundEnd(CurTime() + time)
        timer.Remove("prep2begin")
        timer.Remove("selectmute")
        timer.Create("prep2begin", time, 1, BeginRound)
        timer.Create("selectmute", time - 1, 1, function() MuteForRestart(true) end)
    end)

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

    if draft_pick_ends_turn:GetBool() then
        NextRolePackDraft()
    end
end)

local addedRolePackCallback = false

hook.Add("TTTPrepareRound", "TTTDraft_TTTPrepareRound", function()
    timer.Simple(1, function()
        local rolePackCvar = GetConVar("ttt_role_pack")

        -- Restore the draft pack after a map change if:
        -- we're still within the number of map switches allowed,
        -- it's the same day,
        -- the draft role pack was active,
        -- and it isn't already set
        local lastDraftDate = GetAutoRoleDraftStat("lastDraftDate")
        local mapLoads = GetAutoRoleDraftStat("mapLoadsSinceServerStartOrLastDraft")
        local draftPackActive = GetAutoRoleDraftStat("isDraftRolePackActive")

        if mapLoads <= draft_persist_maps:GetInt() and lastDraftDate and lastDraftDate == currentDate and draftPackActive and rolePackCvar:GetString() ~= "draft" then
            rolePackCvar:SetString("draft")
        end

        -- If the active role pack is manually switched away from the draft role pack by an admin or otherwise, don't restore it
        if not addedRolePackCallback then
            addedRolePackCallback = true
            cvars.AddChangeCallback("ttt_role_pack", function(_, _, newValue)
                SetAutoRoleDraftStat("isDraftRolePackActive", newValue == "draft")
            end, "TTTDraft_RolePackChanged")
        end

        local isDraft = rolePackCvar:GetString() == "draft"
        SetAutoRoleDraftStat("isDraftRolePackActive", isDraft)

        -- Otherwise, update and set the draft role pack for a potentially new player count this round
        -- Yes, this doesn't work with players joining/leaving during round prep, but TTTSelectRoles was too late, so we use TTTPrepareRound instead
        if isDraft then
            UpdateAndSetDraftRolePack()
        end
    end)
end)