local addon, data = ...
local module = data.Modules:Register("Proximity", "p")

local overlay = UI.CreateFrame("Text", "Additional.Proximity.overlay", data.UIContext)
local player
local playerlast = { 0, 0, 0 }
local target
local targetlast = { 0, 0, 0 }

local DoUpdate

overlay:SetFontSize(12)
overlay:SetEffectGlow({ strength = 3 })
overlay:SetPoint("TOPCENTER", UI.Native.PortraitTarget, "TOPRIGHT", UI.Native.PortraitTarget:GetWidth() * -0.25, 0)
overlay:SetVisible(false)

DoUpdate = function()
	if player and target then
		local d = math.sqrt(math.pow(playerlast[1] - targetlast[1], 2) + math.pow(playerlast[2] - targetlast[2], 2) + math.pow(playerlast[3] - targetlast[3], 2))
		if d > 10 then
			overlay:SetText(string.format("%dm", math.floor(d)))
		else
			overlay:SetText(string.format("%.1fm", math.floor(d * 10) / 10))
		end
		overlay:SetVisible(true)
	else
		overlay:SetVisible(false)
	end
end

data.Events:Register("PlayerAvailabilityChange", function(h, available, id)
	if available then
		player = Inspect.Unit.Detail(id)
		playerlast[1], playerlast[2], playerlast[3] = player.coordX, player.coordY, player.coordZ
	else
		player = nil
	end
	DoUpdate()
end)

Command.Event.Attach(Library.LibUnitChange.Register("player.target"), function()
	target = Inspect.Unit.Detail("player.target")
	if target then
		targetlast[1], targetlast[2], targetlast[3] = target.coordX, target.coordY, target.coordZ
	end
	DoUpdate()
end, "Additional.Proximity:player.target")

Command.Event.Attach(Event.Unit.Detail.Coord, function(h, xs, ys, zs)
	local update = false
	if player and xs[player.id] then
		playerlast[1], playerlast[2], playerlast[3] = xs[player.id], ys[player.id], zs[player.id]
		update = true
	end
	if target and xs[target.id] then
		targetlast[1], targetlast[2], targetlast[3] = xs[target.id], ys[target.id], zs[target.id]
		update = true
	end
	if update then
		DoUpdate()
	end
end, "Additional.Proximity:Unit.Detail.Coord")
