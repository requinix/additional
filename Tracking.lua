local addon, data = ...
local module = data.Modules:Register("Tracking", "track")

local bars = {}
local barroot
local config = {}
local framecounter = 1
local pending = {}
local reusable = {}
local sources = { --[[
	source = {
		-- {Color and/or DefaultColors} Data Description IdField [MaxIndex] NameIndex [Tier] ValueFormat ValueIndex
		Color = function(data, value, goal, max)
			return { R, G, B }
		end,
		Data = { key = { ... } },
		DefaultColors = {
			Normal = { R, G, B },
			Goal = { R, G, B },
			Max = { R, G, B }
		},
		Description = "string",
		IdField = "index",
		MaxIndex = "index",
		NameIndex = "index",
		Tier = function(value)
			return "tier", adjusted value, tier max
		end,
		ValueFormat = "index",
		ValueIndex = "index"
	}
]] }

local AddBar
local Find
local HideBar
local Refresh
local RemoveBar
local ShowBar
local Track

--- COMMANDS ---

module.RegisterCommand("add <type> <name> [<goal>]", "Add or update a value to track", function(type, name, goal)
	if type and not sources[type] then
		module.Error("Invalid source: " .. type)
	elseif type and name and not Track(type, name, goal) then
		module.Error("No " .. type .. " named '" .. name .. "'")
	end
end)

module.RegisterCommand("pending", "Show pending status", function()
	for k, v in pairs(pending) do
		printf("Pending: %s '%s' (%s goal)", v.type, v.name, v.goal or "no")
	end
end)

module.RegisterCommand("refresh", "Refresh", function()
	Refresh()
end)

module.RegisterCommand("remove <type> <name>", "Stop tracking a value", function(type, name)
	local source = Find(type, name)
	local id = source and source[sources[type].IdField]
	if type and not sources[type] then
		module.Error("Invalid source: " .. type)
	elseif source and bars[id] then
		RemoveBar(id)
	else
		local lname = name:lower()
		for k, v in pairs(pending) do
			if v.name:lower() == lname then
				pending[k] = nil
				break
			end
		end
	end
end)

module.RegisterCommand("sources", "List tracking sources", function()
	for k, v in pairs(sources) do
		print(k .. " - " .. v.Description)
	end
end)

--- CONFIGURATION ---

module.RegisterConfig(function(saved)
	config.Colors = {}
	for k, v in pairs(sources) do
		if v.DefaultColors then
			config.Colors[k] = {}
			config.Colors[k].Normal = saved.Colors and saved.Colors[k] and saved.Colors[k].NormalZ or v.DefaultColors.Normal
			config.Colors[k].Goal = saved.Colors and saved.Colors[k] and saved.Colors[k].GoalZ or v.DefaultColors.Goal
			config.Colors[k].Max = saved.Colors and saved.Colors[k] and saved.Colors[k].MaxZ or v.DefaultColors.Max
		end
	end

	config.Tracking = {}
	for k, v in pairs(saved.Tracking or {}) do
		if sources[v.type] then
			if sources[v.type].Data[v.id] then
				Track(v.type, v.id, v.goal)
			elseif not Track(v.type, v.name, v.goal) then
				pending[k] = v
			end
		end
	end
end, function()
	local c = { Colors = config.Colors, Tracking = {} }
	for k, v in pairs(config.Tracking) do
		c.Tracking[k] = v
	end
	for k, v in pairs(pending) do
		c.Tracking[k] = v
	end
	return c
end)

--- EVENTS ---

data.Events:Register("Tracking.SourceRegistration", function(h, source, data)
	sources[source] = data
end)

data.Events:Register("Tracking.SourceUpdate", function(h, source, data)
	for k, v in pairs(data) do
		sources[source].Data[k] = v
		if bars[k] then
			ShowBar(bars[k])
		elseif pending[k] and Track(source, k, pending[k].goal) then
			pending[k] = nil
		end
	end
end)

--- FUNCTIONS ---

AddBar = function(bardata)
	bars[bardata.id] = bars[bardata.id] or table.remove(reusable) or {}
	local b = bars[bardata.id]

	b.data = bardata
	b.sortable = bardata.type .. "," .. bardata.name:gsub("^[Tt]he%s+", ""):gsub("^[Aa]n?%s+", "")

	if not barroot then
		barroot = b
	elseif barroot.sortable < b.sortable then
		barroot.below = b
		b.above = barroot
		barroot = b
	else
		local above = barroot
		while above.above and above.above.sortable > b.sortable do
			above = above.above
		end
		if above.above then
			above.above.below = b
		end
		b.above = above.above
		b.below = above
		above.above = b
	end

	if not b.Frame then
		b.Frame = UI.CreateFrame("Frame", "Additional.Tracking.bars#" .. framecounter .. ".Frame", data.UIContext)
		b.Frame:SetBackgroundColor(0.75, 0.75, 0.0)
		b.Frame:SetHeight(22)
	end
	b.Frame:SetVisible(true)

	if not b.BarContainer then
		b.BarContainer = UI.CreateFrame("Frame", "Additional.Tracking.bars#" .. framecounter .. ".BarContainer", b.Frame)
		b.BarContainer:SetBackgroundColor(0.0, 0.0, 0.0)
		b.BarContainer:SetLayer(1)
		b.BarContainer:SetPoint("TOPLEFT", b.Frame, "TOPLEFT", 1, 1)
		b.BarContainer:SetPoint("BOTTOMRIGHT", b.Frame, "BOTTOMRIGHT", -1, -1)
	end

	if not b.Bar then
		b.Bar = UI.CreateFrame("Frame", "Additional.Tracking.bars#" .. framecounter .. ".Bar", b.BarContainer)
		b.Bar:SetLayer(1)
		b.Bar:SetPoint("TOPLEFT", b.BarContainer, "TOPLEFT", 1, 1)
	end

	if not b.Label then
		b.Label = UI.CreateFrame("Text", "Additional.Tracking.bars#" .. framecounter .. ".Label", b.Frame)
		b.Label:SetEffectGlow({ strength = 4 })
		b.Label:SetFontColor(1.0, 1.0, 1.0)
		b.Label:SetFontSize(12)
		b.Label:SetPoint("CENTERRIGHT", b.Frame, "CENTERLEFT", -2, 0)
	end
	b.Label:SetText(bardata.name)

	if not b.Progress then
		b.Progress = UI.CreateFrame("Text", "Additional.Tracking.bars#" .. framecounter .. ".Progress", b.BarContainer)
		b.Progress:SetEffectGlow({ strength = 4 })
		b.Progress:SetFontColor(1.0, 1.0, 1.0)
		b.Progress:SetFontSize(12)
		b.Progress:SetLayer(2)
	end
	b.Progress:ClearAll()
	if sources[bardata.type].Tier then
		b.Progress:SetPoint("CENTERRIGHT", b.BarContainer, "CENTERRIGHT", -2, 0)
	else
		b.Progress:SetPoint("CENTER", b.BarContainer, "CENTER", -2, 0)
	end

	if not b.Tier then
		b.Tier = UI.CreateFrame("Text", "Additional.Tracking.bars#" .. framecounter .. ".Tier", b.Frame)
		b.Tier:SetEffectGlow({ strength = 4 })
		b.Tier:SetFontColor(1.0, 1.0, 1.0)
		b.Tier:SetFontSize(12)
		b.Tier:SetLayer(2)
	end

	framecounter = framecounter + 1

	barroot.Frame:SetPoint("BOTTOMRIGHT", UI.Native.Bag, 0.91, 0.0)
	barroot.Frame:SetPoint("BOTTOMLEFT", UI.Native.Bag, 0.04, 0.0)
	if b.below then
		b.Frame:SetPoint("BOTTOMRIGHT", b.below.Frame, "TOPRIGHT", 0, -3)
		b.Frame:SetPoint("BOTTOMLEFT", b.below.Frame, "TOPLEFT", 0, -3)
	end
	if b.above then
		b.above.Frame:SetPoint("BOTTOMRIGHT", b.Frame, "TOPRIGHT", 0, -3)
		b.above.Frame:SetPoint("BOTTOMLEFT", b.Frame, "TOPLEFT", 0, -3)
	end

	ShowBar(b)
end

Find = function(type, key)
	if not sources[type] then
		return nil
	elseif sources[type].Data[key] then
		return sources[type].Data[key]
	end

	local lkey = key:lower()
	for k, v in pairs(sources[type].Data) do
		if v[sources[type].NameIndex]:lower() == lkey then
			return v
		end
	end
	return nil
end

HideBar = function(bar)
	bar.Frame:SetVisible(false)
end

Refresh = function()
	local olddata = {}
	for k, v in pairs(bars) do
		olddata[k] = v.data
		RemoveBar(k)
	end
	for k, v in pairs(olddata) do
		AddBar(v)
	end
end

RemoveBar = function(id)
	if bars[id] then
		HideBar(bars[id])

		local above, below = bars[id].above, bars[id].below
		if above then
			above.below = below
			if below then
				above.Frame:SetPoint("BOTTOMLEFT", below.Frame, "TOPLEFT", 0, -3)
				above.Frame:SetPoint("BOTTOMRIGHT", below.Frame, "TOPRIGHT", 0, -3)
			end
		end
		if below then
			below.above = above
		else
			barroot = above
			barroot.Frame:SetPoint("BOTTOMRIGHT", UI.Native.Bag, 0.91, 0.0)
			barroot.Frame:SetPoint("BOTTOMLEFT", UI.Native.Bag, 0.04, 0.0)
		end

		bars[id].data = nil
		bars[id].sortable = nil
		table.insert(reusable, bars[id])
		bars[id] = nil
		config.Tracking[id] = nil
	end
end

ShowBar = function(bar)
	local source = sources[bar.data.type]
	local sourcedata = source.Data[bar.data.id]

	local tier
	local value = type(source.ValueIndex) == "function" and source.ValueIndex(sourcedata) or sourcedata[source.ValueIndex]
	local max

	if source.Tier then
		tier, value, max = source.Tier(value)
	else
		max = source.MaxIndex and (type(source.MaxIndex) == "function" and source.MaxIndex(sourcedata) or sourcedata[source.MaxIndex])
	end

	local color
	local percent
	local progress

	if bar.data.goal then
		if value < bar.data.goal then
			color = config.Colors[bar.data.type].Normal or source.Color(sourcedata, value, bar.data.goal)
			percent = value / bar.data.goal
			progress = string.format(source.ValueFormat .. " / " .. source.ValueFormat .. " (goal)", value, bar.data.goal)
		elseif max then
			color = config.Colors[bar.data.type][value < max and "Goal" or "Max"] or source.Color(sourcedata, value, bar.data.goal, max)
			percent = value / max
			progress = string.format(source.ValueFormat .. " / " .. source.ValueFormat, value, max)
		else
			color = config.Colors[bar.data.type].Goal or source.Color(sourcedata, value, bar.data.goal)
			percent = 1.0
			progress = string.format(source.ValueFormat .. " / " .. source.ValueFormat .. " (goal)", value, bar.data.goal)
		end
	elseif max then
		color = config.Colors[bar.data.type][value >= max and "Max" or "Normal"] or source.Color(sourcedata, value, nil, max)
		percent = math.min(value / max, 1.0)
		progress = string.format(source.ValueFormat .. " / " .. source.ValueFormat, value, max)
	else
		color = config.Colors[bar.data.type].Normal or source.Color(sourcedata, value)
		percent = 1.0
		progress = string.format(source.ValueFormat, value)
	end

	bar.Bar:SetBackgroundColor(unpack(color))
	bar.Bar:SetPoint("BOTTOMRIGHT", bar.BarContainer, percent, 1.0, 0, -1)
	bar.Progress:SetText(progress)
	bar.Progress:SetVisible(not tier or value < max)

	bar.Tier:SetText(tier or "")
	if tier then
		if value == max then
			bar.Tier:SetPoint("CENTER", bar.BarContainer, "CENTER")
		else
			bar.Tier:SetPoint("CENTERLEFT", bar.BarContainer, "CENTERLEFT", 2, 0)
		end
	end
end

Track = function(type, key, goal)
	local source = Find(type, key)
	if not source then
		return false
	end

	local id = source[sources[type].IdField]
	config.Tracking[id] = config.Tracking[id] or {}
	config.Tracking[id].type = type
	config.Tracking[id].id = id
	config.Tracking[id].name = source[sources[type].NameIndex]
	config.Tracking[id].goal = goal and tonumber(goal)

	if bars[id] then
		ShowBar(bars[id])
	else
		AddBar(config.Tracking[id])
	end

	return true
end
