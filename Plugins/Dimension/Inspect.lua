local addon, util = ...
local plugin = util.Plugin:Register("Dimension", "Edit")

plugin:RegisterCommand("get [<field>]", "Get dimension item information", function(field)
	local selection, count = plugin:Module().GetSelection()
	for k, v in pairs(selection) do
		if not field then
			dump(v.Dimension)
		elseif count == 1 then
			dump(v.Dimension[field])
		else
			dump(v.Dimension.name, v.Dimension[field])
		end
	end
end)

plugin:RegisterCommand("get-item [<field>]", "Get item information", function(field)
	local selection, count = plugin:Module().GetSelection()
	for k, v in pairs(selection) do
		if not field then
			dump(v.Item)
		elseif count == 1 then
			dump(v.Item[field])
		else
			dump(v.Item.name, v.Item[field])
		end
	end
end)

plugin:RegisterCommand("set <field> <value>", "Set dimension item information", function(field, value)
	if not ({ coordX = 1, coordY = 1, coordZ = 1, pitch = 1, roll = 1, scale = 1, yaw = 1 })[field] then
		plugin:Error("Invalid field")
	else
		local update = { [field] = tonumber(value) }
		for k, v in pairs(plugin:Module().GetSelection()) do
			Command.Dimension.Layout.Place(v.Dimension.id, update)
		end
	end
end)
