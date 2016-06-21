local addon, util = ...
local plugin = util.Plugins:Register("Testing", "Item")

plugin:RegisterCommand("find-item <name>", "Find item on the player", function(name)
	local lname = name:lower()
	for k, v in pairs(Inspect.Item.Detail(Utility.Item.Slot.All())) do
		if v.name:lower() == lname then
			local t = table.pack(Utility.Item.Slot.Parse(k))
			table.insert(t, v)
			dump(unpack(t))
		end
	end
end)
