local addon, util = ...
local plugin = util.Plugin:Register("Dimension", "Clipboard")

local clipboard
local selectioncount

local function paste(t)
	for k, v in pairs(plugin:Module().GetSelection()) do
		Command.Dimension.Layout.Place(v.Dimension.id, t)
	end
end

plugin:RegisterCommand("copy", "Copy the selection", function()
	local selection, count = plugin:Module().GetSelection()
	if count == 0 then
		plugin:Error("No selection")
	elseif count > 1 then
		plugin:Error("Cannot copy multiple items")
	else
		clipboard = selection[next(selection)]
		print("Copied " .. clipboard.Item.name)
	end
end)

plugin:RegisterCommand("paste <field>", "Paste information", function(field)
	if not field then
		plugin:Error("Field required")
	elseif not clipboard then
		plugin:Error("Clipboard is empty")
	elseif not clipboard.Dimension[field] then
		plugin:Error("Invalid field")
	else
		paste({ [field] = clipboard.Dimension[field] })
	end
end)

plugin:RegisterCommand("paste-location", "Paste location", function()
	if not clipboard then
		plugin:Error("Clipboard is empty")
	else
		paste({ coordX = clipboard.Dimension.coordX, coordY = clipboard.Dimension.coordY, coordZ = clipboard.Dimension.coordZ })
	end
end)

plugin:RegisterCommand("paste-orientation", "Paste orientation", function()
	if not clipboard then
		plugin:Error("Clipboard is empty")
	else
		paste({ pitch = clipboard.Dimension.pitch, roll = clipboard.Dimension.roll, yaw = clipboard.Dimension.yaw })
	end
end)

plugin:RegisterCommand("paste-plane", "Paste plane (XZ) coordinates", function()
	if not clipboard then
		plugin:Error("Clipboard is empty")
	else
		paste({ coordX = clipboard.Dimension.coordX, coordZ = clipboard.Dimension.coordZ })
	end
end)

plugin:OnDisable(function()
	clipboard = nil
end)
