local addon, util = ...
local plugin = util.Plugins:Register("Testing", "Inspect")

plugin:Module():RegisterCommand("inspect [<identifier>]", "Inspect the target or an identifier", function(id)
	dump(Inspect.Unit.Detail(id ~= "" and id or "player.target"))
end)

