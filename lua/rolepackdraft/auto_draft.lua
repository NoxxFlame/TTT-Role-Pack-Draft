local draft_auto = CreateConVar("ttt_draft_auto", "0", FCVAR_NONE, "Whether the role draft should trigger automatically at the start of the first round of each map", 0, 1)
local draft_auto_once_per_day = CreateConVar("ttt_draft_auto_once_per_day", "0", FCVAR_NONE, "Whether auto-draft should trigger once per day", 0, 1)
local draft_auto_map_frequency = CreateConVar("ttt_draft_auto_map_frequency", "1", FCVAR_NONE, "How often to trigger auto-draft per map loads. E.g. every map = 1, every 2 maps = 2, every 3 maps = 3, etc.", 1)
local draft_auto_round_number = CreateConVar("ttt_draft_auto_round_number", "1", FCVAR_NONE, "After 'ttt_draft_auto_map_frequency' map loads, the round number that auto-draft triggers. E.g. 1st round = 1, 2nd round = 2, 3rd round = 3", 1)


-- Stats tracking needed to know when to trigger auto-draft
local currentDate = os.date("%Y-%m-%d")
-- SysTime() is the server's uptime, not reset by map changes, so if we minus it from epoch time,
-- this should stay (mostly) constant for a whole server session, since they both tick upwards once a second, and once SysTime() resets,
-- a server restart must have happened. Idk if this is the standard way to detect a server restart but oh well...
local bootTime = os.time() - math.floor(SysTime())
local statsFile = file.Read("rolepackdraft/stats.json", "DATA")
local stats

if statsFile then
    stats = util.JSONToTable(statsFile)
end
if not stats then
    stats = {
        lastDraftDate = nil,
        bootTime = bootTime,
        mapLoadsSinceServerStartOrLastDraft = 0,
        roundsSinceMapStart = 0,
    }
end

-- Setting stats needed on map start
stats.roundsSinceMapStart = 0

-- Give the server restart detection 10 seconds leeway
if stats.bootTime and math.abs(stats.bootTime - bootTime) <= 10 then
    -- The boot time "constant" held, therefore we're switching maps, increment the counter!
    stats.mapLoadsSinceServerStartOrLastDraft = (stats.mapLoadsSinceServerStartOrLastDraft or 0) + 1
else
    -- New server boot (or no/old stats file), this map is load #1
    stats.mapLoadsSinceServerStartOrLastDraft = 1
end
stats.bootTime = bootTime

hook.Add("TTTBeginRound", "TTTAutoDraft_TTTBeginRound", function()
    if not draft_auto:GetBool() then return end
    stats.roundsSinceMapStart = stats.roundsSinceMapStart + 1

    -- Check this is not the same day as another draft
    if draft_auto_once_per_day:GetBool() and stats.lastDraftDate and stats.lastDraftDate == currentDate then return end

    -- Check enough map loads have happened
    if draft_auto_map_frequency:GetInt() > stats.mapLoadsSinceServerStartOrLastDraft then return end

    -- Check we've reached the configured round number
    if draft_auto_round_number:GetInt() > stats.roundsSinceMapStart then return end

    -- Otherwise we're good to go!
    BeginRolePackDraft()

    -- We only want to trigger the role draft once per map, no matter how the convars are configured
    hook.Remove("TTTBeginRound", "TTTAutoDraft_TTTBeginRound")
end)

hook.Add("ShutDown", "TTTAutoDraft_ShutDown", function()
    if not file.IsDir("rolepackdraft", "DATA") then
        file.CreateDir("rolepackdraft")
    end
    file.Write("rolepackdraft/stats.json", util.TableToJSON(stats))
end)

function SetAutoRoleDraftStat(key, value)
    stats[key] = value
end

function GetAutoRoleDraftStat(key)
    return stats[key]
end