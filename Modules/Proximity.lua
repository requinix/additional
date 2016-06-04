local addon, data = ...
local module = data.Modules:Register("Proximity", "p")

local player
local playerlast = { 0, 0, 0 }
local target
local targetlast = { 0, 0, 0 }
local targetoverlay = UI.CreateFrame("Text", "Additional.Proximity.targetoverlay", data.UI.Context)
local targettarget
local targettargetlast = { 0, 0, 0 }
local targettargetoverlay = UI.CreateFrame("Text", "Additional.Proximity.targettargetoverlay", data.UI.Context)

local DoUpdate

targetoverlay:SetFontSize(12)
targetoverlay:SetEffectGlow({ strength = 3 })
targetoverlay:SetPoint("TOPCENTER", UI.Native.PortraitTarget, "TOPRIGHT", UI.Native.PortraitTarget:GetWidth() * -0.25, 0)
targetoverlay:SetVisible(false)

targettargetoverlay:SetFontSize(12)
targettargetoverlay:SetEffectGlow({ strength = 3 })
targettargetoverlay:SetPoint("TOPCENTER", UI.Native.PortraitTargetTarget, "TOPRIGHT", UI.Native.PortraitTargetTarget:GetWidth() * -0.25, 0)
targettargetoverlay:SetVisible(false)

DoUpdate = function()
	if player and target then
		local dt = math.sqrt(math.pow(playerlast[1] - targetlast[1], 2) + math.pow(playerlast[2] - targetlast[2], 2) + math.pow(playerlast[3] - targetlast[3], 2))
		targetoverlay:SetText(dt < 10 and string.format("%.1fm", math.floor(dt * 10) / 10) or string.format("%dm", math.floor(dt)))
		targetoverlay:SetVisible(true)

		if targettarget and targettarget.id ~= player.id and targettarget.id ~= target.id then
			local dptt = math.sqrt(math.pow(playerlast[1] - targettargetlast[1], 2) + math.pow(playerlast[2] - targettargetlast[2], 2) + math.pow(playerlast[3] - targettargetlast[3], 2))
			local sptt = dptt < 10 and string.format("%.1fm", math.floor(dptt * 10) / 10) or string.format("%dm", math.floor(dptt))
			local dttt = math.sqrt(math.pow(targetlast[1] - targettargetlast[1], 2) + math.pow(targetlast[2] - targettargetlast[2], 2) + math.pow(targetlast[3] - targettargetlast[3], 2))
			local sttt = dttt < 10 and string.format("%.1fm", math.floor(dttt * 10) / 10) or string.format("%dm", math.floor(dttt))
			targettargetoverlay:SetText(sptt .. " (" .. sttt .. ")")
			targettargetoverlay:SetVisible(true)
		else
			targettargetoverlay:SetVisible(false)
		end
	else
		targetoverlay:SetVisible(false)
		targettargetoverlay:SetVisible(false)
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

Command.Event.Attach(Library.LibUnitChange.Register("player.target.target"), function()
	targettarget = Inspect.Unit.Detail("player.target.target")
	if targettarget then
		targettargetlast[1], targettargetlast[2], targettargetlast[3] = targettarget.coordX, targettarget.coordY, targettarget.coordZ
	end
	DoUpdate()
end, "Additional.Proximity:player.target.target")

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
	if targettarget and xs[targettarget.id] then
		targettargetlast[1], targettargetlast[2], targettargetlast[3] = xs[targettarget.id], ys[targettarget.id], zs[targettarget.id]
		update = true
	end
	if update then
		DoUpdate()
	end
end, "Additional.Proximity:Unit.Detail.Coord")
