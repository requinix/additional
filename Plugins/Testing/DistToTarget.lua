local addon, util = ...
local plugin = util.Plugins:Register("Testing", "DistToTarget")

plugin:Module():RegisterCommand("dist-to-target", "Show the distance between the player and target", function()
	local player = Inspect.Unit.Detail("player")
	if not player or player.availability ~= "full" then
		plugin:Error("Player not available")
		return
	end
	local target = Inspect.Unit.Detail("player.target")
	if not target or target.availability ~= "full" then
		plugin:Error("Target not available")
		return
	end

	local d = math.sqrt(math.pow(player.coordX - target.coordX, 2) + math.pow(player.coordY - target.coordY, 2) + math.pow(player.coordZ - target.coordZ, 2))
	local h = target.coordY - player.coordY
	printf("%.4gm, %.3gm %s", d, math.abs(h), h >= 0 and "above" or "below")
end)

