local addon, util = ...
local plugin = util.Plugin:Register("Testing", "Inspect")

plugin:RegisterCommand("inspect [<identifier>]", "Inspect the target or an identifier", function(id)
	dump(Inspect.Unit.Detail(id ~= "" and id or "player.target"))
end)

