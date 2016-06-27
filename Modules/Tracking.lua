local addon, util = ...
local module = util.Module:Register("Tracking", "track")

local bars = {}
local barroot
local config = {}
local framecounter = 1
local pending = {}
local reusable = {}
local sources = { --[[
	source = {
		-- [AutoTracking] [Color and/or DefaultColors] Data Description [Icon and/or IconIndex] IdIndex [Load] [Max and/or MaxIndex] NameIndex [Tier] {Value and/or ValueIndex} ValueFormat
		AutoTracking = bool,
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
		Icon = function(data)
			return texturesource, textureid
		},
		IconIndex = "index",
		IdIndex = "index",
		Load = function(key)
			return data
		end,
		Max = function(data)
			return value
		end,
		MaxIndex = "index",
		NameIndex = "index",
		Tier = function(value)
			return "tier", adjusted value, tier max
		end,
		Value = function(data)
			return value
		end,
		ValueFormat = "string",
		ValueIndex = "index"
	}
]] }

local AddBar
local Find
local HideBar
local ProcessSource
local Refresh
local RemoveBar
local ShowBar
local Track
local Untrack

--- COMMANDS ---

module:RegisterCommand("add <type> <name> [<goal>]", "Add or update a value to track", function(type, name, goal)
	if type and not sources[type] then
		module:Error("Invalid source: " .. type)
	elseif type and name and not Track(type, name, goal) then
		module:Error("No " .. type .. " named '" .. name .. "'")
	end
end)

module:RegisterCommand("pending", "Show pending status", function()
	for k, v in pairs(pending) do
		printf("Pending %s: %s (%s goal)", v.type, v.name, v.goal or "no")
	end
end)

module:RegisterCommand("refresh", "Refresh", function()
	Refresh()
end)

module:RegisterCommand("remove <type> <name>", "Stop tracking a value", function(type, name)
	local source = Find(type, name)
	local id = source and source[sources[type].IdIndex]
	if type and not sources[type] then
		module:Error("Invalid source: " .. type)
	elseif source and bars[id] then
		Untrack(id)
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

module:RegisterCommand("sources", "List tracking sources", function()
	for k, v in pairs(sources) do
		print(k .. " - " .. v.Description)
	end
end)

--- CONFIGURATION ---

module:RegisterConfig(function(saved)
	config.AutoTrack = saved.AutoTrack == nil and 0.95 or saved.AutoTrack
	config.Tracking = {}
	for k, v in pairs(saved.Tracking or {}) do
		pending[k] = v
	end
end, function()
	local c = {
		AutoTrack = config.AutoTrack,
		Tracking = {}
	}
	for k, v in pairs(config.Tracking) do
		c.Tracking[k] = v
	end
	for k, v in pairs(pending) do
		c.Tracking[k] = v
	end
	return c
end)

--- EVENTS ---

module:RegisterEvent("Tracking.SourceRegistration", function(h, source, data)
	sources[source] = data
	ProcessSource(source, data.Data or {})

	if data.Load then
		for k, v in pairs(pending) do
			if v.type == source then
				data.Load(k)
			end
		end
	end
end)

module:RegisterEvent("Tracking.SourceUpdate", function(h, source, data)
	ProcessSource(source, data)
end)

--- FUNCTIONS ---

AddBar = function(type, id, name, goal)
	bars[id] = bars[id] or table.remove(reusable) or {}
	local b = bars[id]
	local s = sources[type]

	b.data = {
		goal = goal,
		id = id,
		name = name,
		sortable = type .. "," .. name:gsub("^[Tt]he%s+", ""):gsub("^[Aa]n?%s+", ""),
		type = type
	}

	if not barroot then
		barroot = b
	elseif barroot.data.sortable < b.data.sortable then
		barroot.below = b
		b.above = barroot
		barroot = b
	else
		local above = barroot
		while above.above and above.above.data.sortable > b.data.sortable do
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
		b.Frame = UI.CreateFrame("Frame", "Additional.Tracking.bars#" .. framecounter .. ".Frame", util.UI.Context)
		b.Frame:SetBackgroundColor(0.0, 0.0, 0.0)
		b.Frame:SetHeight(22)

		b.Frame:EventAttach(Event.UI.Input.Mouse.Right.Click, function(h)
			if h == b.Frame then
				Untrack(b.data.id)
			end
		end, "Additional.Tracking.bars#" .. framecounter .. ".Frame:UI.Input.Mouse.Right.Click")
	end
	b.Frame:SetVisible(true)

	if not b.Bar then
		b.Bar = UI.CreateFrame("Canvas", "Additional.Tracking.bars#" .. framecounter .. ".Bar", b.Frame)
		b.Bar:SetBackgroundColor(0.0, 0.0, 0.0, 1.0)
		b.Bar:SetLayer(1)
		b.Bar:SetPoint("TOPLEFT", b.Frame, "TOPLEFT")
	end

	if not b.BarMask then
		b.BarMask = UI.CreateFrame("Canvas", "Additional.Tracking.bars#" .. framecounter .. ".BarMask", b.Frame)
		b.BarMask:SetAllPoints(b.Frame)
		b.BarMask:SetLayer(2)
	end

	if not b.Icon then
		b.Icon = UI.CreateFrame("Texture", "Additional.Tracking.bars#" .. framecounter .. ".Icon", b.Frame)
		b.Icon:SetPoint("TOPRIGHT", b.Frame, "TOPLEFT", -2, 0)
		b.Icon:SetPoint("BOTTOMRIGHT", b.Frame, "BOTTOMLEFT", -2, 0)
		b.Icon:SetWidth(b.Icon:GetHeight())
	end
	local iconsource, icon
	if s.Icon then
		iconsource, icon = s.Icon(s.Data[id])
	end
	if iconsource and icon then
		b.Icon:SetTexture(iconsource, icon)
		b.Icon:SetVisible(true)
	elseif s.IconIndex then
		b.Icon:SetTexture("Rift", s.Data[id][s.IconIndex])
		b.Icon:SetVisible(true)
	else
		b.Icon:SetVisible(false)
	end

	if not b.Label then
		b.Label = UI.CreateFrame("Text", "Additional.Tracking.bars#" .. framecounter .. ".Label", b.Frame)
		b.Label:SetEffectGlow({ strength = 4 })
		b.Label:SetFontSize(12)
	end
	b.Label:SetPoint("CENTERRIGHT", b.Icon:GetVisible() and b.Icon or b.Frame, "CENTERLEFT", -2, 0)
	b.Label:SetText(name)

	if not b.Progress then
		b.Progress = UI.CreateFrame("Text", "Additional.Tracking.bars#" .. framecounter .. ".Progress", b.Frame)
		b.Progress:SetEffectGlow({ strength = 4 })
		b.Progress:SetFontColor(1.0, 1.0, 1.0)
		b.Progress:SetFontSize(12)
		b.Progress:SetLayer(2)
	end
	b.Progress:ClearAll()
	if s.Tier then
		b.Progress:SetPoint("CENTERRIGHT", b.Frame, "CENTERRIGHT", -2, 0)
	else
		b.Progress:SetPoint("CENTER", b.Frame, "CENTER", -2, 0)
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

	if sources[type].Load then
		key = sources[type].Load(key)
		if key and sources[type].Data[key] then
			return sources[type].Data[key]
		end
	end

	return nil
end

HideBar = function(bar)
	bar.Frame:SetVisible(false)
end

ProcessSource = function(source, data)
	local s
	local value, max
	for k, v in pairs(data) do
		s = sources[source]
		s.Data[k] = v
		if bars[k] then
			ShowBar(bars[k])
		elseif pending[k] and Track(source, k, pending[k].goal) then
			pending[k] = nil
		elseif config.AutoTrack and s.AutoTracking and (s.Max or s.MaxIndex) then
			value = s.Value and s.Value(v) or v[s.ValueIndex]
			max = s.Max and s.Max(v) or v[s.MaxIndex]
			if value and max and value >= config.AutoTrack * max then
				AddBar(source, v[s.IdIndex], v[s.NameIndex])
			end
		end
	end
end

Refresh = function()
	local oldbars = {}
	for k, v in pairs(bars) do
		oldbars[k] = v
		RemoveBar(k)
	end
	for k, v in pairs(pending) do
		if Track(v.type, v.id, v.goal) then
			pending[k] = nil
		end
	end
	for k, v in pairs(config.Tracking) do
		if not Track(v.type, v.id, v.goal) then
			pending[k] = v
		end
	end
	for k, v in pairs(oldbars) do
		if not bars[k] and not pending[k] and sources[v.type] then
			AddBar(v.type, v.id, v.name, v.goal)
		end
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
		elseif above then
			barroot = above
			barroot.Frame:SetPoint("BOTTOMRIGHT", UI.Native.Bag, 0.91, 0.0)
			barroot.Frame:SetPoint("BOTTOMLEFT", UI.Native.Bag, 0.04, 0.0)
		else
			barroot = nil
		end

		bars[id].above = nil
		bars[id].below = nil
		bars[id].data = nil
		table.insert(reusable, bars[id])
		bars[id] = nil
	end
end

ShowBar = function(bar)
	local source = sources[bar.data.type]
	local sourcedata = source.Data[bar.data.id]

	local tier
	local value = source.Value and source.Value(sourcedata) or sourcedata[source.ValueIndex]
	local max

	if source.Tier then
		tier, value, max = source.Tier(value)
	else
		max = source.Max and source.Max(sourcedata) or source.MaxIndex and sourcedata[source.MaxIndex]
	end

	local color, colortype
	local percent
	local progress

	if bar.data.goal then
		if value < bar.data.goal then
			color = util.Data.PaletteColors.White
			colortype = "Normal"
			percent = value / bar.data.goal
			progress = string.format(source.ValueFormat .. " / " .. source.ValueFormat .. " (goal)", value, bar.data.goal)
		elseif max and max > 0 then
			color = util.Data.PaletteColors[value < max and "Orange" or "Red"]
			colortype = value < max and "Goal" or "Max"
			percent = math.min(value / max, 1.0)
			progress = string.format(source.ValueFormat .. " / " .. source.ValueFormat, value, max)
		else
			color = util.Data.PaletteColors.Orange
			colortype = "Goal"
			percent = 1.0
			progress = string.format(source.ValueFormat .. " / " .. source.ValueFormat .. " (goal)", value, bar.data.goal)
		end
	elseif max and max > 0 then
		color = util.Data.PaletteColors[value < max and "White" or "Red"]
		colortype = value < max and "Normal" or "Max"
		percent = math.min(value / max, 1.0)
		progress = string.format(source.ValueFormat .. " / " .. source.ValueFormat, value, max)
	else
		color = util.Data.PaletteColors.White
		colortype = "Normal"
		percent = value > 0 and 1.0 or 0.0
		progress = string.format(source.ValueFormat, value)
	end

	local barcolor = source.Color and source.Color(sourcedata, value, bar.data.goal, max) or source.DefaultColors and source.DefaultColors[colortype] or color
	bar.Bar:SetPoint("BOTTOMRIGHT", bar.Frame, percent, 1.0)
	bar.Bar:SetVisible(percent > 0.005)
	util.UI.FillGradientLinear(bar.Bar, { x = 0, y = 1 },
		util.UI.BlendColors(util.UI.DarkenColor(barcolor), { position = 0 }),
		util.UI.BlendColors(barcolor, { position = 33 } ),
		util.UI.BlendColors(barcolor, { position = 67 }),
		util.UI.BlendColors(util.UI.DarkenColor(barcolor), { position = 100 })
	)
	util.UI.DrawOutline(bar.BarMask, barcolor, 1, {})

	bar.Label:SetFontColor(unpack(color))

	bar.Progress:SetText(progress)
	bar.Progress:SetVisible(not tier or max and value < max)

	bar.Tier:SetText(tier or "")
	if tier then
		if value >= max then
			bar.Tier:SetPoint("CENTER", bar.Frame, "CENTER")
		else
			bar.Tier:SetPoint("CENTERLEFT", bar.Frame, "CENTERLEFT", 2, 0)
		end
	end
end

Track = function(type, key, goal)
	local source = Find(type, key)
	if not source then
		return false
	end

	local id = source[sources[type].IdIndex]
	config.Tracking[id] = config.Tracking[id] or {}
	config.Tracking[id].id = id
	config.Tracking[id].goal = goal and tonumber(goal)
	config.Tracking[id].name = source[sources[type].NameIndex]
	config.Tracking[id].type = type

	if bars[id] then
		bars[id].data.goal = config.Tracking[id].goal
		ShowBar(bars[id])
	else
		AddBar(type, id, config.Tracking[id].name, config.Tracking[id].goal)
	end

	return true
end

Untrack = function(id)
	if bars[id] then
		RemoveBar(id)
		config.Tracking[id] = nil
	end
end

module.Track = Track
module.Untrack = Untrack

module:OnDisable(function()
	for k in pairs(bars) do
		RemoveBar(k)
	end
	for k in pairs(sources) do
		sources[k] = nil
	end
end)

module:OnEnable(function()
	Refresh()
end)
