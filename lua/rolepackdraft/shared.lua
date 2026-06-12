CreateConVar("ttt_draft_innocent_picks", "5", FCVAR_REPLICATED)
CreateConVar("ttt_draft_innocent_bans", "2", FCVAR_REPLICATED)
CreateConVar("ttt_draft_traitor_picks", "4", FCVAR_REPLICATED)
CreateConVar("ttt_draft_traitor_bans", "2", FCVAR_REPLICATED)
CreateConVar("ttt_draft_jester_picks", "3", FCVAR_REPLICATED)
CreateConVar("ttt_draft_jester_bans", "2", FCVAR_REPLICATED)
CreateConVar("ttt_draft_independent_picks", "3", FCVAR_REPLICATED)
CreateConVar("ttt_draft_independent_bans", "2", FCVAR_REPLICATED)
CreateConVar("ttt_draft_monster_picks", "0", FCVAR_REPLICATED)
CreateConVar("ttt_draft_monster_bans", "0", FCVAR_REPLICATED)
CreateConVar("ttt_draft_detective_picks", "3", FCVAR_REPLICATED)
CreateConVar("ttt_draft_detective_bans", "1", FCVAR_REPLICATED)

CreateConVar("ttt_draft_prep_time", "10", FCVAR_REPLICATED)
CreateConVar("ttt_draft_turn_time", "5", FCVAR_REPLICATED)
CreateConVar("ttt_draft_end_time", "10", FCVAR_REPLICATED)

ROLE_TEAM_INNOCENT = ROLE_TEAM_INNOCENT or 0
ROLE_TEAM_TRAITOR = ROLE_TEAM_TRAITOR or 1
ROLE_TEAM_JESTER = ROLE_TEAM_JESTER or 2
ROLE_TEAM_INDEPENDENT = ROLE_TEAM_INDEPENDENT or 3
ROLE_TEAM_MONSTER = ROLE_TEAM_MONSTER or 4
ROLE_TEAM_DETECTIVE = ROLE_TEAM_DETECTIVE or 5