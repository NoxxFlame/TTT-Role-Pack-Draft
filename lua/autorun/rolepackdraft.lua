local function AddServer(file)
    if SERVER then include(file) end
end

local function AddClient(file)
    if SERVER then AddCSLuaFile(file) end
    if CLIENT then include(file) end
end

AddServer("rolepackdraft/shared.lua")
AddClient("rolepackdraft/shared.lua")
AddServer("rolepackdraft/draft.lua")
AddClient("rolepackdraft/cl_draft.lua")