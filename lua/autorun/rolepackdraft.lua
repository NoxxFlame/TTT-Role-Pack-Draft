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

if SERVER then
    resource.AddSingleFile("materials/rolepackdraft/ban.png")
    resource.AddSingleFile("materials/rolepackdraft/ban_large.png")
    resource.AddSingleFile("materials/rolepackdraft/glow_large.png")
    resource.AddSingleFile("materials/rolepackdraft/glow_small.png")
    resource.AddSingleFile("materials/rolepackdraft/outline_large.png")
    resource.AddSingleFile("materials/rolepackdraft/outline_small.png")
    resource.AddSingleFile("materials/rolepackdraft/pick.png")
    resource.AddSingleFile("materials/rolepackdraft/random.png")
    resource.AddSingleFile("sound/rolepackdraft/alert.wav")
end