local DrawNoTexture          = draw.NoTexture
local DrawRoundedBox         = draw.RoundedBox
local DrawSimpleText         = draw.SimpleText
local DrawSimpleTextOutlined = draw.SimpleTextOutlined

local MathCeil  = math.ceil
local MathFloor = math.floor
local MathMax   = math.max

local StringFind   = string.find
local StringFormat = string.format
local StringLower  = string.lower
local StringUpper  = string.upper

local SurfaceDrawPoly     = surface.DrawPoly
local SurfaceDrawRect     = surface.DrawRect
local SurfaceGetTextSize  = surface.GetTextSize
local SurfaceSetDrawColor = surface.SetDrawColor
local SurfaceSetFont      = surface.SetFont

local TableCopy          = table.Copy
local TableInsert        = table.insert
local TableKeyFromValue  = table.KeyFromValue
local TableRemoveByValue = table.RemoveByValue
local TableSort          = table.sort

local VGUICreate = vgui.Create

local colours = {
    black        = Color(0, 0, 0, 255),
    background   = Color(24, 24, 24),
    white        = Color(255, 255, 255),
    grey         = Color(150, 150, 150),
    darkGrey     = Color(110, 110, 110),
    green        = Color(70, 220, 90),
    tickgreen    = Color(0, 255, 0, 255),
    orange       = Color(255, 170, 60),
    red          = Color(230, 60, 60),
    titleBar     = Color(50, 50, 50),
    tile         = Color(38, 38, 38),
    tileSelected = Color(26, 50, 30),
    tileHover    = Color(130, 130, 130),
    slot         = Color(46, 46, 46),
    iconDim      = Color(255, 255, 255, 70),
    warn         = Color(255, 120, 0)
}

surface.CreateFont("DraftSettings_Tooltip", {
    font = "Tahoma",
    size = 20,
    weight = 800,
})

surface.CreateFont("DraftSettings_Cross", {
    font = "Tahoma",
    size = 25,
    weight = 700
})

surface.CreateFont("DraftSettings_Config", {
    font = "Tahoma",
    size = 16,
    weight = 600
})

surface.CreateFont("DraftSettings_Name", {
    font = "Tahoma",
    size = 13,
    weight = 700
})

surface.CreateFont("DraftSettings_NameSmall", {
    font = "Tahoma",
    size = 11,
    weight = 700
})

surface.CreateFont("DraftSettingsTick", {
    font = "Tahoma",
    size = 100,
    weight = 1000
})

surface.CreateFont("DraftSettingsExclamation", {
    font = "Tahoma",
    size = 120,
    weight = 1000
})

surface.CreateFont("DraftSettings_ConfigLabel", {
    font = "Tahoma",
    size = 14,
    weight = 500,
    italic = true,
})

-- Make tooltip font big enough to be readable
local CUSTOM_TOOLTIP = {}
function CUSTOM_TOOLTIP:Init()
    self:SetFont("DraftSettings_Tooltip")
    self:SetTextColor(colours.black)
end
vgui.Register("CustomLargeTooltip", CUSTOM_TOOLTIP, "DTooltip")

local draftGroups = {
    {jsonName = "detectives",   displayName = "Detective",   team = ROLE_TEAM_DETECTIVE},
    {jsonName = "innocents",    displayName = "Innocent",    team = ROLE_TEAM_INNOCENT},
    {jsonName = "traitors",     displayName = "Traitor",     team = ROLE_TEAM_TRAITOR},
    {jsonName = "jesters",      displayName = "Jester",      team = ROLE_TEAM_JESTER},
    {jsonName = "independents", displayName = "Independent", team = ROLE_TEAM_INDEPENDENT},
    {jsonName = "monsters",     displayName = "Monster",     team = ROLE_TEAM_MONSTER}
}

    local groupByName = {}
    for _, group in ipairs(draftGroups) do
        groupByName[group.jsonName] = group
    end

local tileW    = 88
local tileH    = 98
local iconSize = 76
local tileGap  = 6

local padding      = 6
local headerH      = 28
local slotTitleH   = 22
local slotButtonsW = 80
local slotButtonsH = 96

local draftData   = nil
local tabBase     = nil
local statusLabel = nil
local openPopups  = {}
local RebuildSlots

-- Saving/saved label
local function SetStatus(text, colour)
    if IsValid(statusLabel) then
        statusLabel:SetText(text)
        statusLabel:SetTextColor(colour or colours.grey)
    end
end

-- Delay saving so clicking lots quickly doesn't spam network?
local function QueueSave()
    SetStatus("Saving...", colours.grey)

    timer.Create("TTTDraft_SaveSettings", 0.5, 1, function()
        if not draftData then return end

        net.Start("TTT_SaveRolePackDraftSettings")
            net.WriteTable(draftData)
        net.SendToServer()
    end)
end

net.Receive("TTT_SavedRolePackDraftSettings", function()
    if net.ReadBool() then
        SetStatus("All changes saved", colours.green)
    else
        SetStatus("Saving failed!", colours.red)
    end
end)

-- No idea if caching these really saves any performance, but it feels fancy
local rolesByName = {}
local function GetRoleByName(roleStr)
    if rolesByName[roleStr] == nil then
        for role = ROLE_INNOCENT, ROLE_MAX do
            if ROLE_STRINGS_RAW[role] == roleStr then
                rolesByName[roleStr] = role
            end
        end
    end

    return rolesByName[roleStr]
end

local function GetRoleDescription(role)
    local description = LANG.GetRawTranslation("cheatsheet_desc_" .. ROLE_STRINGS_RAW[role]) or nil

    return description or "This role doesn't have a description :("
end

local iconPaths = {}
local function GetRoleIconFile(role)
    if iconPaths[role] == nil then
        local roleShort = ROLE_STRINGS_SHORT[role]
        iconPaths[role] = roleShort and util.GetRoleIconPath(roleShort, "icon", "vtf") or false
    end

    return iconPaths[role] or nil
end

local function GetRoleColour(role)
    if not DEFAULT_ROLES[role] then
        local team = player.GetRoleTeam(role)
        if team then return GetRoleTeamColor(team) end
    end

    return (ROLE_COLORS and ROLE_COLORS[role]) or Color(90, 90, 90)
end


-- Draw tick or exclamation mark symbols
local function DrawSymbol(x, y, size, warn)
    local symbol = warn and "❗" or "✓"
    local colour = warn and colours.warn or colours.tickgreen

    local symbolFont = warn and "DraftSettingsExclamation" or "DraftSettingsTick"
    local symbolX = warn and x + size / 4 or x - size / 10
    local symbolY = warn and y - size * 0.45 or y - size / 4

    DrawSimpleTextOutlined(symbol, symbolFont, symbolX, symbolY, colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, colours.black)
end

----------------------------------------------------------------------------------------------------
-- Tiles
----------------------------------------------------------------------------------------------------

local function CreateTile(parent, roleOptions)
    local roleTile = VGUICreate("DButton", parent)
    roleTile:SetText("")
    roleTile:SetSize(tileW, tileH)

    roleTile.displayName   = roleOptions.displayName or "?"
    roleTile.baseColour    = roleOptions.colour or Color(90, 90, 90)
    roleTile.centreText    = roleOptions.centreText
    roleTile.dimOnUnselect = roleOptions.dimOnUnselect
    roleTile.onClick       = roleOptions.onClick
    roleTile.isSlot        = roleOptions.isSlot
    roleTile.warn          = roleOptions.warn

    if roleOptions.tooltip then
        roleTile:SetTooltip(roleOptions.tooltip)
        roleTile:SetTooltipPanelOverride("CustomLargeTooltip")
    end

    -- Smaller font for names that are too long with the normal font
    SurfaceSetFont("DraftSettings_Name")
    roleTile.nameFont = (SurfaceGetTextSize(roleTile.displayName) > tileW - 6) and "DraftSettings_NameSmall" or "DraftSettings_Name"

    if roleOptions.iconPath then
        local roleIcon = VGUICreate("DImage", roleTile)
        roleIcon:SetPos((tileW - iconSize) / 2, 6)
        roleIcon:SetSize(iconSize, iconSize)
        roleIcon:SetImage(roleOptions.iconPath)
        roleIcon:SetMouseInputEnabled(false)
        roleTile.icon = roleIcon
    end

    -- Set whether or not a role option tile is selected
    function roleTile:SetTileSelected(selected)
        self.selected = selected and true or false
        self.dim = self.dimOnUnselect and not self.selected or false

        local backgroundColour = self.baseColour
        if self.dim then
            self.iconBackground = Color(MathFloor(backgroundColour.r * 0.3), MathFloor(backgroundColour.g * 0.3), MathFloor(backgroundColour.b * 0.3))
        else
            self.iconBackground = backgroundColour
        end

        if IsValid(self.icon) then
            self.icon:SetImageColor(self.dim and colours.iconDim or colours.white)
        end
    end

    roleTile:SetTileSelected(roleOptions.selected)

    roleTile.Paint = function(self, w, h)
        if self.selected then
            DrawRoundedBox(6, 0, 0, w, h, colours.green)
            DrawRoundedBox(5, 2, 2, w - 4, h - 4, colours.tileSelected)
        elseif self:IsHovered() then
            local borderColour = self.isSlot and colours.red or colours.tileHover
            DrawRoundedBox(6, 0, 0, w, h, borderColour)
            DrawRoundedBox(5, 2, 2, w - 4, h - 4, colours.tile)
        else
            DrawRoundedBox(6, 0, 0, w, h, colours.tile)
        end

        DrawRoundedBox(4, (w - iconSize) / 2 + 2, 8, iconSize - 4, iconSize - 4, self.iconBackground)

        if self.centreText then
            DrawSimpleTextOutlined(self.centreText, "DraftSettings_NameSmall", w / 2, 6 + iconSize / 2, self.dim and colours.darkGrey or colours.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, colours.black)
        elseif not self.icon then
            -- If there's no icon it's probably because the role's in the json but its pack isn't installed/enabled
            DrawSimpleText("?", "Trebuchet24", w / 2, 6 + iconSize / 2, colours.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        DrawSimpleText(self.displayName, self.nameFont, w / 2, iconSize + 2 + (h - iconSize - 6) / 2, self.dim and colours.darkGrey or colours.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Maybe I could refactor to make the symbol/x draw on top, but this is easier
    roleTile.PaintOver = function(self, w, h)
        if self.selected then
            DrawSymbol((w - iconSize) / 2, 6, iconSize, self.warn)
        end

        if self.isSlot and self:IsHovered() then
            DrawRoundedBox(0, w - 24, 2, 22, 22, colours.red)
            DrawSimpleText("❌", "DraftSettings_Cross", w - 13, 10, colours.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    roleTile.DoClick = function(self)
        if self.onClick then
            self.onClick(self)
        end
    end

    return roleTile
end

----------------------------------------------------------------------------------------------------
-- Tile grid
----------------------------------------------------------------------------------------------------

local function GetGridBits(count, width)
    local columns = MathMax(1, MathFloor((width - padding + tileGap) / (tileW + tileGap)))
    local rows    = MathMax(0, MathCeil(count / columns))

    return columns, rows > 0 and padding * 2 + rows * tileH + (rows - 1) * tileGap or 28
end

-- Grid
local function CreateGrid(parent)
    local tileGrid = VGUICreate("DPanel", parent)
    tileGrid:SetPaintBackground(false)
    tileGrid.tiles = {}

    tileGrid.PerformLayout = function(self, w)
        -- Seems to break without this
        if w <= 0 and IsValid(self:GetParent()) then
            w = self:GetParent():GetWide()
        end

        local visibleTiles = {}
        for _, tile in ipairs(self.tiles) do
            local isVisible = not tile.hidden
            tile:SetVisible(isVisible)
            if isVisible then
                TableInsert(visibleTiles, tile)
            end
        end

        local columns, height = GetGridBits(#visibleTiles, w)

        for i, tile in ipairs(visibleTiles) do
            tile:SetPos(padding + ((i - 1) % columns) * (tileW + tileGap), padding + MathFloor((i - 1) / columns) * (tileH + tileGap))
        end

        if self:GetTall() ~= height then
            self:SetTall(height)

            if self.OnHeightChanged then
                self:OnHeightChanged()
            end
        end
    end

    return tileGrid
end

-- Role group sections
local function CreateSection(parent, colour)
    local groupSection = VGUICreate("DPanel", parent)
    groupSection:SetPaintBackground(true)
    groupSection:Dock(TOP)
    groupSection:DockMargin(0, 0, 0, 6)
    groupSection:SetTall(headerH)

    groupSection.expanded = false
    groupSection.title    = ""
    groupSection.colour   = colour
    groupSection.bgColour = Color(MathFloor(colour.r * 0.58), MathFloor(colour.g * 0.58), MathFloor(colour.b * 0.58))
    groupSection.bgHover  = Color(MathFloor(colour.r * 0.90), MathFloor(colour.g * 0.90), MathFloor(colour.b * 0.90))

    groupSection:SetBackgroundColor(groupSection.bgColour)

    -- Collapsible title bar
    local groupTitleBar = VGUICreate("DButton", groupSection)
    groupTitleBar:SetText("")
    groupTitleBar:Dock(TOP)
    groupTitleBar:SetTall(headerH)

    -- Remove all button
    local buttonRemoveAll = VGUICreate("DButton", groupTitleBar)
    buttonRemoveAll:SetText("Remove all")
    buttonRemoveAll:SetSize(75, 20)
    buttonRemoveAll:SetVisible(false)
    buttonRemoveAll.DoClick = function()
        if not groupSection.grid or not groupSection.grid.tiles then return end
        for _, tile in ipairs(groupSection.grid.tiles) do
            if tile.selected then
                tile:DoClick()
            end
        end
    end

    -- Add all button
    local buttonAddAll = VGUICreate("DButton", groupTitleBar)
    buttonAddAll:SetText("Add all")
    buttonAddAll:SetSize(65, 20)
    buttonAddAll:SetVisible(false)
    buttonAddAll.DoClick = function()
        if not groupSection.grid or not groupSection.grid.tiles then return end
        for _, tile in ipairs(groupSection.grid.tiles) do
            if not tile.selected then
                tile:DoClick()
            end
        end
    end

    groupTitleBar.PerformLayout = function(self, w, h)
        local buttonY = (h - 20) / 2
        buttonRemoveAll:SetPos(w - 75 - 8, buttonY)
        buttonAddAll:SetPos(w - 75 - 8 - 65 - 6, buttonY)
    end

    groupTitleBar.Paint = function(self, w, h)
        DrawRoundedBox(4, 0, 0, w, h, (self:IsHovered() or groupSection.expanded) and groupSection.bgHover or groupSection.bgColour)
        SurfaceSetDrawColor(groupSection.colour)
        SurfaceDrawRect(0, 0, 5, h)

        -- Triangles for the collapsible title bars
        DrawNoTexture()
        SurfaceSetDrawColor(255, 255, 255, 255)
        if groupSection.expanded then
            SurfaceDrawPoly({{x = 13, y = h / 2 - 3}, {x = 23, y = h / 2 - 3}, {x = 18, y = h / 2 + 4}})
        else
            SurfaceDrawPoly({{x = 15, y = h / 2 - 5}, {x = 21, y = h / 2}, {x = 15, y = h / 2 + 5}})
        end

        DrawSimpleText(groupSection.title, "TabLarge", 32, h / 2, colours.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local tileGrid = CreateGrid(groupSection)
    tileGrid:Dock(TOP)
    tileGrid:SetVisible(false)
    tileGrid:SetTall(0)
    groupSection.grid = tileGrid

    -- Set the section's height
    function groupSection:UpdateHeight()
        local height = headerH

        if self.expanded then
            height = height + tileGrid:GetTall()
        end

        if self:GetTall() ~= height then
            self:SetTall(height)
        end
    end

    tileGrid.OnHeightChanged = function()
        groupSection:UpdateHeight()
    end

    groupTitleBar.DoClick = function()
        groupSection.expanded = not groupSection.expanded
        tileGrid:SetVisible(groupSection.expanded)

        buttonAddAll:SetVisible(groupSection.expanded)
        buttonRemoveAll:SetVisible(groupSection.expanded)

        groupSection:UpdateHeight()
    end

    return groupSection
end

-- Add or remove a role
local function SetRoleIncluded(groupJsonName, roleStr, includedRoles)
    local list = draftData.roles[groupJsonName]

    TableRemoveByValue(list, roleStr)

    if includedRoles then
        TableInsert(list, roleStr)
    end

    QueueSave()
end

-- All roles on that team and also those already in the json for that team but probably shouldn't be (wrong team/not installed)
local function GetGroupEntries(group)
    local entries    = {}
    local addedRoles = {}

    -- Process installed roles
    for role = ROLE_INNOCENT, ROLE_MAX do
        local roleStr = ROLE_STRINGS_RAW[role]

        -- Don't include default roles
        if roleStr and not DEFAULT_ROLES[role] and player.GetRoleTeam(role) == group.team then
            addedRoles[roleStr] = true
            TableInsert(entries, {role = role, roleStr = roleStr, displayName = ROLE_STRINGS[role] or roleStr})
        end
    end

    -- Find roles in the json which aren't installed/aren't on the right team
    for _, roleStr in ipairs(draftData.roles[group.jsonName]) do
        if not addedRoles[roleStr] then
            addedRoles[roleStr] = true

            local role = GetRoleByName(roleStr)
            TableInsert(entries, {role = role, roleStr = roleStr, displayName = (role and ROLE_STRINGS[role]) or roleStr, warn = true})
        end
    end

    TableSort(entries, function(a, b) return StringLower(a.displayName) < StringLower(b.displayName) end)

    return entries
end

local function BuildRoleSections(scrollWindowCanvas)
    for _, group in ipairs(draftGroups) do
        local colour = GetRoleTeamColor(group.team)
        local groupSection = CreateSection(scrollWindowCanvas, colour)

        local includedRoles = {}
        for _, roleStr in ipairs(draftData.roles[group.jsonName]) do
            includedRoles[roleStr] = true
        end

        local entries = GetGroupEntries(group)
        local includedCount = 0

        local function UpdateTitle()
            groupSection.title = StringFormat("%s Roles   -   %d of %d included", group.displayName, includedCount, #entries)
        end

        for _, entry in ipairs(entries) do
            -- Hover text, name and description
            local tooltip
            if not entry.role then
                tooltip = "This role couldn't be found (is its addon missing?).\nIt's still in the config file - click to remove it."
            else
                tooltip = GetRoleDescription(entry.role)

                if entry.warn then
                    local team = player.GetRoleTeam(entry.role)
                    local teamName = "another team"

                    for _, g in ipairs(draftGroups) do
                        if g.team == team then
                            teamName = "the " .. g.displayName .. " team"
                        end
                    end

                    tooltip = tooltip .. "\n\nNote: this role is in the config file under this group, but it's currently on " .. teamName .. "."
                end
            end

            local isIncluded = includedRoles[entry.roleStr] == true
            if isIncluded then
                includedCount = includedCount + 1
            end

            local roleTile = CreateTile(groupSection.grid, {
                displayName   = entry.displayName,
                colour        = colour,
                iconPath      = entry.role and GetRoleIconFile(entry.role) or nil,
                tooltip       = tooltip,
                selected      = isIncluded,
                dimOnUnselect = true,
                warn          = entry.warn,
                onClick       = function(self)
                    local nowIncluded = not self.selected

                    self:SetTileSelected(nowIncluded)
                    includedCount = includedCount + (nowIncluded and 1 or -1)
                    UpdateTitle()
                    SetRoleIncluded(group.jsonName, entry.roleStr, nowIncluded)
                end
            })

            TableInsert(groupSection.grid.tiles, roleTile)
        end

        UpdateTitle()
    end
end

local function CreatePopup(title, width, height)
    local frame = VGUICreate("DFrame")
    frame:SetSize(width, height)
    frame:SetTitle(title)
    frame:Center()
    frame:MakePopup()

    frame.Paint = function(_, w, h)
        DrawRoundedBox(4, 0, 0, w, h, colours.background)
        DrawRoundedBox(4, 0, 0, w, 24, colours.titleBar)
    end

    TableInsert(openPopups, frame)

    return frame
end

local function OpenGroupsPopup(slot, slotNumber)
    local frame = CreatePopup("Add Groups to Slot " .. slotNumber, 340, 105 + #draftGroups * 26)

    local hint = VGUICreate("DLabel", frame)
    hint:SetPos(20, 35)
    hint:SetSize(340, 20)
    hint:SetTextColor(colours.white)
    hint:SetFont("DraftSettings_Tooltip")
    hint:SetText("Tick the groups you want in this slot:")

    local inSlot = {}
    for _, jsonName in ipairs(slot.groups) do
        inSlot[jsonName] = true
    end

    local checkboxes = {}
    for i, group in ipairs(draftGroups) do
        local checkbox = VGUICreate("DCheckBoxLabel", frame)
        checkbox:SetPos(25, 62 + (i - 1) * 26)
        checkbox:SetText(group.displayName .. "s")
        checkbox:SetTextColor(colours.white)
        checkbox:SetFont("DraftSettings_Tooltip")
        checkbox:SetValue(inSlot[group.jsonName] or false)
        checkbox:SizeToContents()
        checkboxes[group.jsonName] = checkbox
    end

    local buttonConfirm = VGUICreate("DButton", frame)
    buttonConfirm:SetSize(120, 26)
    buttonConfirm:SetPos(20, frame:GetTall() - 36)
    buttonConfirm:SetText("Confirm")
    buttonConfirm.DoClick = function()
        local newGroups = {}

        for _, jsonName in ipairs(slot.groups) do
            if checkboxes[jsonName]:GetChecked() then
                TableInsert(newGroups, jsonName)
            end
        end

        for _, group in ipairs(draftGroups) do
            if checkboxes[group.jsonName]:GetChecked() and not inSlot[group.jsonName] then
                TableInsert(newGroups, group.jsonName)
            end
        end

        slot.groups = newGroups

        QueueSave()
        RebuildSlots()
        frame:Close()
    end

    local buttonCancel = VGUICreate("DButton", frame)
    buttonCancel:SetSize(120, 26)
    buttonCancel:SetPos(frame:GetWide() - 140, frame:GetTall() - 36)
    buttonCancel:SetText("Cancel")
    buttonCancel.DoClick = function()
        frame:Close()
    end
end

local function OpenConstantsPopup(slot, slotNumber)
    local includedRoles = {}
    for _, roleStr in ipairs(slot.constants) do
        includedRoles[roleStr] = true
    end

    local defaultRolesList = {}
    local groupLists = {
        detectives   = {},
        innocents    = {},
        traitors     = {},
        jesters      = {},
        independents = {},
        monsters     = {}
    }

    for role = ROLE_INNOCENT, ROLE_MAX do
        local roleStr = ROLE_STRINGS_RAW[role]

        if roleStr and not includedRoles[roleStr] then
            local option = {
                role        = role,
                roleStr     = roleStr,
                displayName = ROLE_STRINGS[role] or roleStr
            }

            if DEFAULT_ROLES[role] then
                TableInsert(defaultRolesList, option)
            else
                local team = player.GetRoleTeam(role)
                if team == ROLE_TEAM_DETECTIVE then
                    TableInsert(groupLists.detectives, option)
                elseif team == ROLE_TEAM_INNOCENT then
                    TableInsert(groupLists.innocents, option)
                elseif team == ROLE_TEAM_TRAITOR then
                    TableInsert(groupLists.traitors, option)
                elseif team == ROLE_TEAM_JESTER then
                    TableInsert(groupLists.jesters, option)
                elseif team == ROLE_TEAM_INDEPENDENT then
                    TableInsert(groupLists.independents, option)
                elseif team == ROLE_TEAM_MONSTER then
                    TableInsert(groupLists.monsters, option)
                end
            end
        end
    end

    local function SortByName(a, b)
        return StringLower(a.displayName) < StringLower(b.displayName)
    end

    TableSort(defaultRolesList,        SortByName)
    TableSort(groupLists.detectives,   SortByName)
    TableSort(groupLists.innocents,    SortByName)
    TableSort(groupLists.traitors,     SortByName)
    TableSort(groupLists.jesters,      SortByName)
    TableSort(groupLists.independents, SortByName)
    TableSort(groupLists.monsters,     SortByName)

    local categories = {
        {title = "Default Roles",     roles = defaultRolesList},
        {title = "Detectives",        roles = groupLists.detectives},
        {title = "Special Innocents", roles = groupLists.innocents},
        {title = "Special Traitors",  roles = groupLists.traitors},
        {title = "Jesters",           roles = groupLists.jesters},
        {title = "Independents",      roles = groupLists.independents},
        {title = "Monsters",          roles = groupLists.monsters}
    }

    local frame = CreatePopup("Add roles to Slot " .. slotNumber, 600, 470)

    -- Search bar
    local searchBar = VGUICreate("DTextEntry", frame)
    searchBar:Dock(TOP)
    searchBar:DockMargin(0, 0, 0, 4)
    searchBar:SetPlaceholderText("Search roles...")
    searchBar:SetUpdateOnType(true)

    local bottomBar = VGUICreate("DPanel", frame)
    bottomBar:Dock(BOTTOM)
    bottomBar:SetTall(34)
    bottomBar:SetPaintBackground(false)

    -- Scroll bar
    local scroll = VGUICreate("DScrollPanel", frame)
    scroll:Dock(FILL)

    local buttonAdd = VGUICreate("DButton", bottomBar)
    buttonAdd:SetSize(160, 26)
    buttonAdd:SetPos(0, 4)
    buttonAdd:SetText("Add Selected (0)")
    buttonAdd:SetEnabled(false)

    local buttonCancel = VGUICreate("DButton", bottomBar)
    buttonCancel:SetSize(120, 26)
    buttonCancel:SetPos(170, 4)
    buttonCancel:SetText("Cancel")
    buttonCancel.DoClick = function()
        frame:Close()
    end

    local selectedCount = 0
    local selectedRoles = {}
    local categorySections = {}

    -- Headings/grids for each category
    for _, category in ipairs(categories) do
        if category.roles and #category.roles > 0 then
            local categorySection = VGUICreate("DPanel", scroll:GetCanvas())
            categorySection:Dock(TOP)
            categorySection:DockMargin(0, 0, 0, 8)
            categorySection:SetPaintBackground(false)

            local heading = VGUICreate("DLabel", categorySection)
            heading:Dock(TOP)
            heading:DockMargin(4, 8, 0, 4)
            heading:SetTall(24)
            heading:SetFont("Trebuchet24")
            heading:SetTextColor(colours.white)
            heading:SetText(category.title)

            local tileGrid = CreateGrid(categorySection)
            tileGrid:Dock(TOP)
            tileGrid:DockMargin(0, 0, 0, 0)

            local sectionTiles = {}

            for _, option in ipairs(category.roles) do
                local roleTile = CreateTile(tileGrid, {
                    displayName = option.displayName,
                    colour      = GetRoleColour(option.role),
                    iconPath    = GetRoleIconFile(option.role),
                    tooltip     = GetRoleDescription(option.role),
                    onClick     = function(self)
                        self:SetTileSelected(not self.selected)
                        selectedRoles[option.roleStr] = self.selected or nil
                        selectedCount = selectedCount + (self.selected and 1 or -1)

                        buttonAdd:SetText("Add Selected (" .. selectedCount .. ")")
                        buttonAdd:SetEnabled(selectedCount > 0)
                    end
                })

                roleTile.searchText = StringLower(option.displayName .. " " .. option.roleStr)
                TableInsert(tileGrid.tiles, roleTile)
                TableInsert(sectionTiles, roleTile)
            end

            categorySection.UpdatePanelHeight = function(self)
                if not self:IsVisible() then
                    self:SetTall(0)
                    return
                end

                local gridHeight = tileGrid:GetTall()
                local height = 24 + 12 + gridHeight
                self:SetTall(height)
            end

            tileGrid.OnHeightChanged = function()
                categorySection:UpdatePanelHeight()
            end

            categorySection:UpdatePanelHeight()

            TableInsert(categorySections, {section = categorySection, grid = tileGrid, tiles = sectionTiles})
        end
    end

    -- Hide roles that don't match the search
    searchBar.OnValueChange = function(_, value)
        local query = StringLower(value or "")

        for _, categorySection in ipairs(categorySections) do
            local visibleCount = 0
            for _, tile in ipairs(categorySection.tiles) do
                local matches = query == "" or StringFind(tile.searchText, query, 1, true)
                tile.hidden = not matches
                if matches then
                    visibleCount = visibleCount + 1
                end
            end

            local hasVisible = visibleCount > 0
            categorySection.section:SetVisible(hasVisible)
            categorySection.section:UpdatePanelHeight()
            if hasVisible then
                categorySection.grid:InvalidateLayout(true)
            end
        end

        if IsValid(scroll) and IsValid(scroll:GetCanvas()) then
            scroll:GetCanvas():InvalidateLayout(true)
        end
    end

    buttonAdd.DoClick = function()
        for _, category in ipairs(categories) do
            if category.roles then
                for _, option in ipairs(category.roles) do
                    if selectedRoles[option.roleStr] then
                        TableInsert(slot.constants, option.roleStr)
                    end
                end
            end
        end

        QueueSave()
        RebuildSlots()
        frame:Close()
    end
end

----------------------------------------------------------------------------------------------------
-- Slots section
----------------------------------------------------------------------------------------------------

local slotRows = {}
local slotsCanvas = nil

local function CreateSlotButton(parent, text, icon, tooltip, w, centreIcon, onClick)
    local button = VGUICreate("DButton", parent)
    button:SetSize(w, 24)
    button:SetText(text)

    if icon then
        button:SetIcon(icon)

        -- Centre the icons for the little square buttons without any text
        if centreIcon and IsValid(button.m_Image) then
            button.PerformLayout = function(self)
                local iconW, iconH = self.m_Image:GetSize()
                self.m_Image:SetPos((w - iconW) / 2, (24 - iconH) / 2)
            end
        end
    end

    if tooltip then
        button:SetTooltip(tooltip)
        button:SetTooltipPanelOverride("CustomLargeTooltip")
    end

    button.DoClick = onClick

    return button
end

local function CreateSlotRow(parent, index, slot)
    local slotRow = VGUICreate("DPanel", parent)
    slotRow:Dock(TOP)
    slotRow:DockMargin(0, 0, 0, 8)
    slotRow:SetTall(slotTitleH + slotButtonsH + padding)
    slotRow.tiles = {}

    local isEmpty = (#slot.groups + #slot.constants) == 0

    slotRow.Paint = function(_, w, h)
        DrawRoundedBox(6, 0, 0, w, h, colours.slot)

        if isEmpty then
            DrawRoundedBox(6, 0, 0, w, h, colours.orange)
            DrawRoundedBox(6, 2, 2, w - 4, h - 4, colours.slot)
            DrawSymbol((w - iconSize) * 0.835, (h - iconSize) / 2, iconSize, true)
            DrawSimpleText("Empty slot! Add a group or role, or delete this slot.", "DraftSettings_Tooltip", padding + 3, h * 0.4, colours.orange, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        DrawSimpleText("Slot " .. index, "TabLarge", padding + 3, 4, isEmpty and colours.orange or colours.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    -- Groups first
    for _, jsonName in ipairs(slot.groups) do
        local group = groupByName[jsonName]

        local roleTile = CreateTile(slotRow, {
            displayName = "Group",
            colour      = GetRoleTeamColor(group.team),
            centreText  = StringUpper(group.displayName),
            tooltip     = "The pool of " .. group.displayName .. " roles picked in the draft.",
            isSlot      = true,
            onClick     = function()
                TableRemoveByValue(slot.groups, jsonName)
                QueueSave()
                RebuildSlots()
            end
        })

        TableInsert(slotRow.tiles, roleTile)
    end

    -- Then constants
    for _, roleStr in ipairs(slot.constants) do
        local role = GetRoleByName(roleStr)
        local tooltip

        if role then
            tooltip = GetRoleDescription(role)
        else
            tooltip = "This role couldn't be found (is its addon missing?)"
        end

        local roleTile = CreateTile(slotRow, {
            displayName = (role and ROLE_STRINGS[role]) or roleStr,
            colour      = GetRoleColour(role),
            iconPath    = role and GetRoleIconFile(role) or nil,
            tooltip     = tooltip,
            isSlot      = true,
            onClick     = function()
                TableRemoveByValue(slot.constants, roleStr)
                QueueSave()
                RebuildSlots()
            end
        })

        TableInsert(slotRow.tiles, roleTile)
    end

    -- Buttons on the right
    slotRow.buttons = {}

    -- Add groups to slot
    slotRow.buttons[1] = CreateSlotButton(slotRow, "Add groups", "icon16/group_add.png", "Choose which role groups are in this slot", slotButtonsW, false, function()
        OpenGroupsPopup(slot, index)
    end)

    -- Add constants to slot
    slotRow.buttons[2] = CreateSlotButton(slotRow, "Add roles", "icon16/add.png", "Add one or more specific roles to this slot", slotButtonsW, false, function()
        OpenConstantsPopup(slot, index)
    end)

    -- Move slot up
    slotRow.buttons[3] = CreateSlotButton(slotRow, "", "icon16/arrow_up.png", "Move slot up", 38, true, function()
        local position = TableKeyFromValue(draftData.slots, slot)

        if position and position > 1 then
            draftData.slots[position], draftData.slots[position - 1] = draftData.slots[position - 1], draftData.slots[position]
            QueueSave()
            RebuildSlots()
        end
    end)

    -- Move slot down
    slotRow.buttons[4] = CreateSlotButton(slotRow, "", "icon16/arrow_down.png", "Move slot down", 38, true, function()
        local position = TableKeyFromValue(draftData.slots, slot)

        if position and position < #draftData.slots then
            draftData.slots[position], draftData.slots[position + 1] = draftData.slots[position + 1], draftData.slots[position]
            QueueSave()
            RebuildSlots()
        end
    end)

    -- Duplicate slot
    slotRow.buttons[5] = CreateSlotButton(slotRow, "", "icon16/page_copy.png", "Duplicate slot", 38, true, function()
        local position = TableKeyFromValue(draftData.slots, slot)

        if position then
            TableInsert(draftData.slots, position + 1, TableCopy(slot))
            QueueSave()
            RebuildSlots()
        end
    end)

    -- Delete slot
    slotRow.buttons[6] = CreateSlotButton(slotRow, "", "icon16/bin.png", "Delete slot", 38, true, function()
        TableRemoveByValue(draftData.slots, slot)
        QueueSave()
        RebuildSlots()
    end)

    -- Sort out the slot's layout
    slotRow.PerformLayout = function(self, w)
        local columns = MathMax(1, MathFloor((w - slotButtonsW - padding * 3 + tileGap) / (tileW + tileGap)))

        for i, tile in ipairs(self.tiles) do
            tile:SetPos(padding + ((i - 1) % columns) * (tileW + tileGap), slotTitleH + MathFloor((i - 1) / columns) * (tileH + tileGap))
        end

        local rows = MathCeil(#self.tiles / columns)
        local tilesHeight = rows * tileH + MathMax(0, rows - 1) * tileGap

        local buttonX = w - slotButtonsW - padding
        self.buttons[1]:SetPos(buttonX, slotTitleH - 12)
        self.buttons[2]:SetPos(buttonX, slotTitleH + 16)

        for i = 3, 4 do
            self.buttons[i]:SetPos(buttonX + (i - 3) * 42, slotTitleH + 44)
        end

        for i = 5, 6 do
            self.buttons[i]:SetPos(buttonX + (i - 5) * 42, slotTitleH + 44 + 28)
        end

        local height = slotTitleH + MathMax(tilesHeight, slotButtonsH) + padding
        if self:GetTall() ~= height then
            self:SetTall(height)
        end
    end

    return slotRow
end

RebuildSlots = function()
    if not IsValid(slotsCanvas) then return end

    for _, slotRow in ipairs(slotRows) do
        if IsValid(slotRow) then
            slotRow:SetVisible(false)
            slotRow:Remove()
        end
    end

    slotRows = {}

    if #draftData.slots == 0 then
        -- Show a warning if there aren't any slots
        local warningRow = VGUICreate("DPanel", slotsCanvas)
        warningRow:Dock(TOP)
        warningRow:DockMargin(0, 0, 0, 8)
        warningRow:SetTall(50)
        warningRow.Paint = function(_, w, h)
            DrawRoundedBox(6, 0, 0, w, h, colours.slot)
            DrawRoundedBox(6, 0, 0, w, h, colours.orange)
            DrawRoundedBox(6, 2, 2, w - 4, h - 4, colours.slot)
            DrawSimpleText("The Role Draft won't do anything without configured slots!", "DraftSettings_Tooltip", w / 2, h / 2, colours.orange, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        TableInsert(slotRows, warningRow)
    else
        -- Build the slots
        for i, slot in ipairs(draftData.slots) do
            TableInsert(slotRows, CreateSlotRow(slotsCanvas, i, slot))
        end
    end

    local buttonAddSlot = VGUICreate("DButton", slotsCanvas)
    buttonAddSlot:Dock(TOP)
    buttonAddSlot:SetTall(30)
    buttonAddSlot:SetText("Add Slot")
    buttonAddSlot:SetIcon("icon16/add.png")
    buttonAddSlot.DoClick = function()
        TableInsert(draftData.slots, {groups = {}, constants = {}})
        QueueSave()
        RebuildSlots()
    end

    TableInsert(slotRows, buttonAddSlot)
end

----------------------------------------------------------------------------------------------------
-- The actual tab
----------------------------------------------------------------------------------------------------

local function AddLabel(scrollWindowCanvas, text, font, colour, height, wrap)
    local label = VGUICreate("DLabel", scrollWindowCanvas)
    label:Dock(TOP)
    label:SetTall(height)
    label:SetFont(font)
    label:SetTextColor(colour)
    label:SetText(text)
    label:SetWrap(wrap or false)

    return label
end

-- Config section
local function AddSeparator(parent)
    local sep = VGUICreate("DPanel", parent)
    sep:Dock(TOP)
    sep:SetTall(16)
    sep:SetPaintBackground(false)
    sep.Paint = function(_, w, h)
        local lineW = w * (9 / 10)
        local lineX = (w - lineW) / 2
        SurfaceSetDrawColor(255, 255, 255, 255)
        SurfaceDrawRect(lineX, h / 2 - 1, lineW, 1)
    end
    return sep
end

local function AddConfigRow(parent, labelText, defaultValue, convar, itemType, tooltipText)
    local configRow = VGUICreate("DPanel", parent)
    configRow:Dock(TOP)
    configRow:DockMargin(0, 3, 0, 3)
    configRow:SetTall(24)
    configRow:SetPaintBackground(false)

    -- Convar name
    local convarName = VGUICreate("DLabel", configRow)
    convarName:Dock(LEFT)
    convarName:SetText(labelText .. " ")
    convarName:SetTextColor(colours.white)
    convarName:SetFont("DraftSettings_Config")
    convarName:SizeToContents()

    -- Default value
    local convarDefault = VGUICreate("DLabel", configRow)
    convarDefault:Dock(LEFT)
    convarDefault:SetText("(default: " .. defaultValue .. ")")
    convarDefault:SetTextColor(colours.grey)
    convarDefault:SetFont("DraftSettings_ConfigLabel")
    convarDefault:SizeToContents()

    local currentValue = ConVarExists(convar) and GetConVar(convar):GetString() or defaultValue

    if itemType == "dropDown" then
        convarDefault:SetText("(default: Always)")
        convarDefault:SizeToContents()

        local dropDown = VGUICreate("DComboBox", configRow)
        dropDown:Dock(RIGHT)
        dropDown:SetSize(160, 24)
        dropDown:AddChoice("Never", 0, currentValue == "0")
        dropDown:AddChoice("If player is up next", 1, currentValue == "1")
        dropDown:AddChoice("Always", 2, currentValue == "2")

        if tooltipText then
            dropDown:SetTooltip(tooltipText)
            dropDown:SetTooltipPanelOverride("CustomLargeTooltip")
        end

        dropDown.OnSelect = function(_, _, _, data)
            RunConsoleCommand(convar, tostring(data))
        end
    else
        local textEntry = VGUICreate("DTextEntry", configRow)
        textEntry:Dock(RIGHT)
        textEntry:SetSize(60, 24)
        textEntry:SetValue(currentValue)

        textEntry.OnChange = function(self)
            local val = self:GetValue()
            timer.Create("DraftConfig_" .. convar, 0.3, 1, function()
                if ConVarExists(convar) then
                    RunConsoleCommand(convar, val)
                end
            end)
        end
    end
end

local function CreateConfigSection(parent, titleText)
    local configSection = VGUICreate("DPanel", parent)
    configSection:SetPaintBackground(true)
    configSection:Dock(TOP)
    configSection:DockMargin(0, 8, 0, 8)
    configSection:SetTall(headerH)
    configSection:SetBackgroundColor(colours.titleBar)

    configSection.expanded = false

    local titleBar = VGUICreate("DButton", configSection)
    titleBar:SetText("")
    titleBar:Dock(TOP)
    titleBar:SetTall(headerH)

    titleBar.Paint = function(self, w, h)
        DrawRoundedBox(4, 0, 0, w, h, (self:IsHovered() or configSection.expanded) and colours.tileHover or colours.titleBar)

        -- Expand/collapse triangle
        DrawNoTexture()
        SurfaceSetDrawColor(255, 255, 255, 255)
        if configSection.expanded then
            SurfaceDrawPoly({{x = 13, y = h / 2 - 3}, {x = 23, y = h / 2 - 3}, {x = 18, y = h / 2 + 4}})
        else
            SurfaceDrawPoly({{x = 15, y = h / 2 - 5}, {x = 21, y = h / 2}, {x = 15, y = h / 2 + 5}})
        end

        DrawSimpleText(titleText, "TabLarge", 32, h / 2, colours.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local configBody = VGUICreate("DPanel", configSection)
    configBody:Dock(TOP)
    configBody:DockMargin(8, 8, 8, 8)
    configBody:SetPaintBackground(false)
    configBody:SetVisible(false)
    configBody:SetTall(0)
    configSection.content = configBody

    function configSection:UpdateHeight()
        local height = headerH
        if self.expanded then
            configBody:InvalidateLayout(true)
            configBody:SizeToChildren(false, true)
            height = height + configBody:GetTall() + 16
        end
        if self:GetTall() ~= height then
            self:SetTall(height)
        end
    end

    titleBar.DoClick = function()
        configSection.expanded = not configSection.expanded
        configBody:SetVisible(configSection.expanded)
        configSection:UpdateHeight()
    end

    return configSection
end

-- Fill tab when we get the data from the server
local function BuildTab(basePanel, data)
    basePanel:Clear()
    basePanel.loaded = true
    draftData = data

    if UpdateRoleColours then
        UpdateRoleColours()
    end

    -- Scroll panel
    local scrollWindow = VGUICreate("DScrollPanel", basePanel)
    scrollWindow:Dock(FILL)
    slotsScroll = scrollWindow

    local scrollWindowCanvas = scrollWindow:GetCanvas()
    slotsCanvas = scrollWindowCanvas

    -- Config section
    local configSection = CreateConfigSection(scrollWindowCanvas, "Role Draft Config")
    local configContent = configSection.content

    local showNextTooltip = [[Whether to show the roles for a player's upcoming turn so they can think about it in advance.

- Never: Players are not shown a preview.
- If player is up next: Players are only shown a preview if they are up next.
- Always: Each player is shown a preview of their next turn.]]

    AddConfigRow(configContent, "Prep Time", "10", "ttt_draft_prep_time", "int")
    AddConfigRow(configContent, "Turn Time", "5", "ttt_draft_turn_time", "int")
    AddConfigRow(configContent, "End Time", "10", "ttt_draft_end_time", "int")

    AddSeparator(configContent)

    AddConfigRow(configContent, "Show turn previews", "2", "ttt_draft_show_next", "dropDown", showNextTooltip)

    AddSeparator(configContent)

    AddConfigRow(configContent, "Detective Picks", "3", "ttt_draft_detective_picks", "int")
    AddConfigRow(configContent, "Detective Bans", "1", "ttt_draft_detective_bans", "int")
    AddConfigRow(configContent, "Innocent Picks", "5", "ttt_draft_innocent_picks", "int")
    AddConfigRow(configContent, "Innocent Bans", "2", "ttt_draft_innocent_bans", "int")
    AddConfigRow(configContent, "Traitor Picks", "4", "ttt_draft_traitor_picks", "int")
    AddConfigRow(configContent, "Traitor Bans", "2", "ttt_draft_traitor_bans", "int")
    AddConfigRow(configContent, "Independent Picks", "3", "ttt_draft_independent_picks", "int")
    AddConfigRow(configContent, "Independent Bans", "2", "ttt_draft_independent_bans", "int")
    AddConfigRow(configContent, "Monster Picks", "0", "ttt_draft_monster_picks", "int")
    AddConfigRow(configContent, "Monster Bans", "0", "ttt_draft_monster_bans", "int")

    -- Title text with 'Saved' message
    local titleRow = VGUICreate("DPanel", scrollWindowCanvas)
    titleRow:Dock(TOP)
    titleRow:SetTall(36)
    titleRow:SetPaintBackground(false)

    local draftRolesTitle = VGUICreate("DLabel", titleRow)
    draftRolesTitle:Dock(TOP)
    draftRolesTitle:SetTall(28)
    draftRolesTitle:SetFont("Trebuchet24")
    draftRolesTitle:SetTextColor(colours.white)
    draftRolesTitle:SetText("Select Draft Roles")

    statusLabel = VGUICreate("DLabel", draftRolesTitle)
    statusLabel:Dock(RIGHT)
    statusLabel:SetWide(190)
    statusLabel:SetContentAlignment(6)
    statusLabel:SetText("Changes save automatically")
    statusLabel:SetTextColor(colours.grey)

    BuildRoleSections(scrollWindowCanvas)

    -- Slots
    local slotsHeading = AddLabel(scrollWindowCanvas, "Role Pack Slots", "Trebuchet24", colours.white, 28)
    slotsHeading:DockMargin(0, 0, 0, 0)
    AddLabel(scrollWindowCanvas, "Add role groups (every role picked for that group in the draft) and/or constants (specific roles).", "DermaDefault", colours.grey, 34, true)

    -- 'Allow duplicates' tickbox
    local allowDuplicates = VGUICreate("DCheckBoxLabel", scrollWindowCanvas)
    allowDuplicates:Dock(TOP)
    allowDuplicates:DockMargin(0, 2, 0, 10)
    allowDuplicates:SetTall(20)
    allowDuplicates:SetText("Allow duplicate roles")
    allowDuplicates:SetTextColor(colours.white)
    allowDuplicates:SetValue(data.config.allowduplicates)
    allowDuplicates:SetTooltip("Whether the same role can be given to more than one player in the generated role pack")
    allowDuplicates:SetTooltipPanelOverride("CustomLargeTooltip")

    allowDuplicates.OnChange = function(_, value)
        draftData.config.allowduplicates = value and true or false
        QueueSave()
    end

    slotRows = {}
    RebuildSlots()
end

local function CreateTab()
    -- Base panel
    local basePanel = VGUICreate("DPanel")
    basePanel:Dock(FILL)
    basePanel:DockPadding(8, 8, 8, 8)
    basePanel.Paint = function(_, w, h)
        DrawRoundedBox(0, 0, 0, w, h, colours.background)
    end

    -- Close group/constants menu popups if F1 menu is closed while they're open
    basePanel.OnRemove = function()
        for _, popup in ipairs(openPopups) do
            if IsValid(popup) then
                popup:Remove()
            end
        end

        openPopups = {}
    end

    return basePanel
end

net.Receive("TTT_SendRolePackDraftSettings", function()
    local data = net.ReadTable()

    if data and IsValid(tabBase) then
        BuildTab(tabBase, data)
    end
end)

hook.Add("TTTSettingsTabs", "TTTDraft_SettingsTab", function(dtabs)
    local client = LocalPlayer()
    if not IsValid(client) or not client:IsSuperAdmin() then return end

    tabBase = CreateTab()
    dtabs:AddSheet("Draft", tabBase, "icon16/group_edit.png", false, false, "Configure the role pack draft")

    net.Start("TTT_RequestRolePackDraftSettings")
    net.SendToServer()
end)