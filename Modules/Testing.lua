local addon, data = ...
local module = data.Modules:Register("Testing", "test")

--- DIST TO TARGET ---
do

module:RegisterCommand("dist-to-target", "Show the distance between the player and target", function()
	local player = Inspect.Unit.Detail("player")
	if not player or player.availability ~= "full" then
		module:Error("Player not available")
		return
	end
	local target = Inspect.Unit.Detail("player.target")
	if not target or target.availability ~= "full" then
		module:Error("Target not available")
		return
	end
	dump(math.sqrt(math.pow(player.coordX - target.coordX, 2) + math.pow(player.coordY - target.coordY, 2) + math.pow(player.coordZ - target.coordZ, 2)))
end)

end
--- DUMP KEYS ---
do

module:RegisterCommand("dumpkeys <value>", "Dump keys from a table", function(arg)
	local value = assert(loadstring("return " .. arg))()
	if not value then
		module:Error("Invalid value")
		return
	elseif not istable(value) then
		module:Error("Value is a " .. type(value))
		return
	end

	local keys = {}
	for k in pairs(value) do
		table.insert(keys, k)
	end
	table.sort(keys)
	dump(keys)
end)

end
--- INSPECT ---
do

module:RegisterCommand("inspect [<identifier>]", "Inspect the target or an identifier", function(id)
	dump(Inspect.Unit.Detail(id ~= "" and id or "player.target"))
end)

end
--- OVERLAY ---
do

local overlay = UI.CreateFrame("Frame", "Additional.Testing.overlay", data.UI.Context)
OVERLAY = overlay
overlay:SetBackgroundColor(1.0, 1.0, 1.0, 0.5)
overlay:SetVisible(false)

local overlaytext = UI.CreateFrame("Text", "Additional.Testing.overlaytext", overlay)
overlaytext:SetFontColor(1.0, 1.0, 1.0, 1.0)
overlaytext:SetFontSize(18)
overlaytext:SetEffectGlow({ strength = 3 })
overlaytext:SetPoint("CENTER", overlay, "CENTER")

module:RegisterCommand("overlay-copy <element>", "Create a testing overlay using a copy of an element", function(element)
	local e = assert(loadstring("return " .. element))()
	if not e then
		module:Error("Invalid element")
		return
	end

	overlay:SetAllPoints(e)
	overlay:SetVisible(true)
end)
module:RegisterCommand("overlay-remove", "Remove a testing overlay", function()
	overlay:SetVisible(false)
end)

overlay:EventAttach(Event.UI.Layout.Move, function(h)
	if h == overlay then
		local left, top, right, bottom = overlay:GetBounds()
		overlaytext:SetText(string.format("(%d, %d) - (%d, %d)", left, top, right, bottom))
	end
end, "Additional.Testing:overlay:UI.Layout.Move")
overlay:EventAttach(Event.UI.Layout.Size, function(h)
	if h == overlay then
		local left, top, right, bottom = overlay:GetBounds()
		overlaytext:SetText(string.format("(%d, %d) - (%d, %d)", left, top, right, bottom))
	end
end, "Additional.Testing:overlay:UI.Layout.Size")

end
