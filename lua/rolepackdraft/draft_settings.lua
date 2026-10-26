util.AddNetworkString("TTT_RequestRolePackDraftSettings")
util.AddNetworkString("TTT_SendRolePackDraftSettings")
util.AddNetworkString("TTT_SaveRolePackDraftSettings")
util.AddNetworkString("TTT_SavedRolePackDraftSettings")

local jsonFile = "rolepackdraft.json"

local function CreateBlankSettings()
    local blankSettings = {
        roles = {
            detectives   = {},
            innocents    = {},
            traitors     = {},
            jesters      = {},
            independents = {},
            monsters     = {}
        },
        slots = {
            {groups = {}, constants = {}}
        },
        config = {
            allowduplicates = false
        }
    }

    file.Write(jsonFile, util.TableToJSON(blankSettings, true))
end

exampleStructure = {
    roles = {
        detectives   = {},
        innocents    = {},
        traitors     = {},
        jesters      = {},
        independents = {},
        monsters     = {}
    },
    slots = {
        {groups = {}, constants = {}}
    },
    config = {
        allowduplicates = false
    }
}

local function LoadSettings()
    if not file.Exists(jsonFile, "DATA") then
        CreateBlankSettings()
    end

    local settings = util.JSONToTable(file.Read(jsonFile, "DATA"))

    return settings
end

-- Send current settings
net.Receive("TTT_RequestRolePackDraftSettings", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    net.Start("TTT_SendRolePackDraftSettings")
        net.WriteTable(LoadSettings())
    net.Send(ply)
end)

-- Save changes received
net.Receive("TTT_SaveRolePackDraftSettings", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local settings = net.ReadTable()
    local success = false

    -- Safety checks
    if settings then
        settings.slots = settings.slots or {}
        settings.roles = settings.roles or {}

        local validSlots = {}
        for _, slot in ipairs(settings.slots) do
            slot.groups = slot.groups or {}
            slot.constants = slot.constants or {}

            local hasConstants = #slot.constants > 0
            local hasActiveGroups = false

            -- Things break if a slot's only entry is a group and that group has no roles in it
            if #slot.groups > 0 then
                for _, groupKey in ipairs(slot.groups) do
                    if settings.roles[groupKey] and #settings.roles[groupKey] > 0 then
                        hasActiveGroups = true
                        break
                    end
                end
            end

            -- Only keep slots that have constants AND/OR have a group with roles in
            if hasConstants or hasActiveGroups then
                table.insert(validSlots, slot)
            end
        end

        settings.slots = validSlots

        -- If there are no valid slots then create one with the default roles
        if #settings.slots == 0 then
            table.insert(settings.slots, {
                groups = {},
                constants = {"detective", "innocent", "traitor"}
            })
        end

        file.Write(jsonFile, util.TableToJSON(settings, true))
        success = true
    end

    net.Start("TTT_SavedRolePackDraftSettings")
        net.WriteBool(success)
    net.Send(ply)
end)