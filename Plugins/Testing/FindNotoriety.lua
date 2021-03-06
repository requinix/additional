local addon, util = ...
local plugin = util.Plugin:Register("Testing", "FindNotoriety")

plugin:RegisterCommand("find-notoriety <name>", "Find faction notoriety on the player", function(name)
	local lname = name:lower()
	for k, v in pairs(Inspect.Faction.Detail(Inspect.Faction.List())) do
		if v.name:lower() == lname then
			dump(v)
		end
	end
end)
