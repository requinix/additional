local addon, util = ...
local module = util.Module:Register("MiniMap", "mm")

local cache = {}
local config = {}
local framecounter = 1
local learning = 0
local maxx, maxz
local minimap = UI.Native.MapMini
local nodes = {}
local overlay = UI.CreateFrame("Frame", "Additional.MiniMap.overlay", util.UI.Context)
local player
local playerlast = { false, false, false }
local reusable = {}

local AddNode
local GetLabel
local HideNode
local Refresh
local RefreshNodes
local RefreshOverlay
local RemoveNode
local ShowNode
local TestNode
local UpdateNodes

overlay:SetVisible(false)

module:RegisterCache(function(static, versioned)
	cache.NodeTypes = static.NodeTypes or {}
	cache.NodeTypeMap = versioned.NodeTypeMap or { Fish = false, Ore = false, Plant = false, Wood = false }

	for k, v in pairs(cache.NodeTypeMap) do
		if not v then
			learning = learning + 1
		end
	end
end, function()
	return {
		NodeTypes = cache.NodeTypes
	}, {
		NodeTypeMap = cache.NodeTypeMap
	}
end)

module:RegisterCommand("debug [<mode>]", "Enable/disable/toggle debug mode", function(mode)
	local enable = not config.Debug and (not mode or mode == "toggle") or mode and (mode == "on" or mode == "enable")
	if enable and not config.Debug then
		overlay:SetBackgroundColor(1.0, 1.0, 1.0, 0.5)
		print("Debug mode enabled")
	elseif not enable and config.Debug then
		overlay:SetBackgroundColor(0.0, 0.0, 0.0, 0.0)
		print("Debug mode disabled")
	end
	config.Debug = enable
end)

module:RegisterCommand("refresh", "Refresh", function()
	Refresh()
end)

module:RegisterCommand("zoom {in|out}", "Zoom in or out", function(dir)
	if dir == "in" and config.ZoomLevel < 9 then
		config.ZoomLevel = config.ZoomLevel + 1
		UpdateNodes()
	elseif dir == "out" and config.ZoomLevel > 1 then
		config.ZoomLevel = config.ZoomLevel - 1
		UpdateNodes()
	end
end)

module:RegisterConfig(function(saved)
	config.Debug = saved.Debug or false
	config.IconSize = saved.IconSize or 10
	config.LabelFontSize = saved.LabelFontSize or 12
	config.LabelShortNames = saved.LabelShortNames == nil or saved.LabelShortNames
	config.OverlayHeightMultiplier = saved.OverlayHeightMultiplier or 0.82
	config.OverlayScaling = saved.OverlayScaling or 1.3
	config.OverlayWidthMultiplier = saved.OverlayWidthMultiplier or 0.785
	config.OverlayXOffset = saved.OverlayXOffset or -11
	config.OverlayYOffset = saved.OverlayYOffset or -11
	config.ShowIcon = saved.ShowIcon == nil or saved.ShowIcon
	config.ShowLabel = saved.ShowLabel == nil or saved.ShowLabel
	config.ZoomLevel = saved.ZoomLevel or 1
	return config
end, function()
	return config
end)

AddNode = function(node)
	nodes[node.id] = nodes[node.id] or table.remove(reusable) or {}
	local n = nodes[node.id]

	n.Node = node

	n.Frame = n.Frame or UI.CreateFrame("Frame", "Additional.MiniMap.nodes#" .. framecounter .. ".Frame", overlay)
	n.Frame:SetVisible(false)

	if not n.Icon then
		n.Icon = UI.CreateFrame("Frame", "Additional.MiniMap.nodes#" .. framecounter .. ".Icon", n.Frame)
		n.Icon:SetPoint("CENTER", n.Frame, "CENTER")
	end
	n.Icon:SetHeight(config.IconSize)
	n.Icon:SetWidth(config.IconSize)
	n.Icon:SetVisible(config.ShowIcon)

	n.Labels = n.Labels or {}
	local l = 1
	for line in GetLabel(node):gmatch("[^\n]+") do
		if not n.Labels[l] then
			n.Labels[l] = UI.CreateFrame("Text", "Additional.MiniMap.nodes#" .. framecounter .. ".Labels#" .. l, n.Frame)
			n.Labels[l]:SetEffectGlow({ strength = 3 })
			n.Labels[l]:SetPoint("TOPCENTER", n.Labels[l - 1] or n.Icon, n.Labels[l - 1] and "CENTER" or "BOTTOMCENTER")
		end
		n.Labels[l]:SetFontSize(config.LabelFontSize)
		n.Labels[l]:SetText(line)
		n.Labels[l]:SetVisible(true)
		l = l + 1
	end
	for l2 = l, #n.Labels do
		n.Labels[l2]:SetVisible(false)
	end

	if player then
		ShowNode(n)
	end
end

GetLabel = function(node)
	if config.LabelShortNames then
		local type = cache.NodeTypeMap[node.type]
		if type == "Fish" then
			return string.match(node.description .. " Fish", "School of (.*) Fish") or node.description
		elseif type == "Ore" then
			return node.description:match("[^%s]+")
		elseif type == "Plant" then
			return node.description:gsub("%s+", "\n")
		elseif type == "Wood" then
			return node.description:match("[^%s]+")
		end
	end
	return node.description
end

HideNode = function(node)
	node.Frame:SetVisible(false)
end

Refresh = function()
	RefreshOverlay()
	RefreshNodes()
end

RefreshNodes = function()
	local oldnodes = nodes
	local newnodes = {}
	nodes = {}

	for k, v in pairs(Inspect.Map.Detail(Inspect.Map.List())) do
		if TestNode(v) then
			if oldnodes[k] then
				nodes[k] = oldnodes[k]
				oldnodes[k] = nil
				ShowNode(nodes[k])
			else
				newnodes[k] = v
			end
		end
	end

	for k in pairs(oldnodes) do
		nodes[k] = oldnodes[k]
		RemoveNode(k)
	end
	for k, v in pairs(newnodes) do
		AddNode(v)
	end
end

RefreshOverlay = function()
	overlay:SetHeight(minimap:GetHeight() * config.OverlayHeightMultiplier)
	overlay:SetPoint("BOTTOMRIGHT", minimap, "BOTTOMRIGHT", config.OverlayXOffset, config.OverlayYOffset)
	overlay:SetWidth(minimap:GetWidth() * config.OverlayWidthMultiplier)

	maxx = overlay:GetWidth() / 2
	maxz = overlay:GetHeight() / 2
end

RemoveNode = function(id)
	if nodes[id] then
		HideNode(nodes[id])
		nodes[id].node = nil
		table.insert(reusable, nodes[id])
		nodes[id] = nil
	end
end

ShowNode = function(node)
	local dx = (node.Node.coordX - playerlast[1]) * config.OverlayScaling * math.pow(1.25, config.ZoomLevel - 1)
	local dz = (node.Node.coordZ - playerlast[3]) * config.OverlayScaling * math.pow(1.25, config.ZoomLevel - 1)
	if dx > -maxx and dx < maxx and dz > -maxz and dz < maxz then
		node.Frame:SetLayer(-dz)
		node.Frame:SetPoint("CENTER", overlay, "CENTER", dx, dz)
		node.Frame:SetVisible(true)
	else
		HideNode(node)
	end
end

TestNode = function(node)
	node.type = node.type or node.id:match("[^,]+")
	if learning > 0 and not cache.NodeTypeMap[node.type] and cache.NodeTypes[node.description] then
		local type = cache.NodeTypes[node.description]
		cache.NodeTypeMap[node.type] = type
		cache.NodeTypeMap[type] = node.type
		learning = learning - 1
		return true
	elseif cache.NodeTypeMap[node.type] and cache.NodeTypes[node.description] ~= cache.NodeTypeMap[node.type] then
		cache.NodeTypes[node.description] = cache.NodeTypeMap[node.type]
		return true
	else
		return cache.NodeTypeMap[node.type] ~= nil
	end
end

UpdateNodes = function()
	local fn = player and ShowNode or HideNode
	for k, v in pairs(nodes) do
		fn(v)
	end
end

module:EventAttach(Event.Map.Add, function(h, elements)
	for k, v in pairs(Inspect.Map.Detail(elements)) do
		if TestNode(v) then
			AddNode(v)
		end
	end
end, "Map.Add")

module:EventAttach(Event.Map.Remove, function(h, elements)
	for k in pairs(elements) do
		RemoveNode(k)
	end
end, "Map.Remove")

module:EventAttach(Event.Unit.Detail.Coord, function(h, x, y, z)
	if player and x[player.id] then
		playerlast[1], playerlast[2], playerlast[3] = x[player.id], y[player.id], z[player.id]
		UpdateNodes()
	end
end, "Unit.Detail.Coord")

module:OnDisable(function()
	overlay:SetVisible(false)

	for k in pairs(nodes) do
		RemoveNode(k)
	end
end)

module:OnEnable(function()
	overlay:SetVisible(true)
	Refresh()

	player = util.Shared.PlayerAvailability.Test()
	if player then
		playerlast[1], playerlast[2], playerlast[3] = player.coordX, player.coordY, player.coordZ
		Refresh()
	end
end)

module:RegisterEvent("Shared.PlayerAvailability.Change", function(h, available)
	if available then
		player = Inspect.Unit.Detail("player")
		playerlast[1], playerlast[2], playerlast[3] = player.coordX, player.coordY, player.coordZ
	end
	UpdateNodes()
end)
