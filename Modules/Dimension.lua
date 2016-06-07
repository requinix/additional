local addon, util = ...
local module = util.Modules:Register("Dimension", "dim")

local GetSelection

--- DIMENSION SELECTION CHANGE ---
do

local scount = 0
local selected = {}

GetSelection = function()
	return selected, scount
end

Command.Event.Attach(Event.Dimension.Layout.Remove, function(h, items)
	local oldscount = scount
	local removed = {}
	local changed = false

	for k in pairs(items) do
		if selected[k] then
			selected[k] = nil
			scount = scount - 1
			removed[k] = true
			changed = true
		end
	end

	if changed then
		util.Events:Invoke("Dimension.SelectionChanged", selected, {}, removed, scount, oldscount)
	end
end, "Additional.Dimension:Dimension.Layout.Remove")

Command.Event.Attach(Event.Dimension.Layout.Update, function(h, items)
	local oldscount = scount
	local added = {}
	local removed = {}
	local changed = false

	for k, v in pairs(Inspect.Dimension.Layout.Detail(items)) do
		if selected[k] and not v.selected then
			selected[k] = nil
			scount = scount - 1
			removed[k] = true
			changed = true
		elseif not selected[k] and v.selected then
			selected[k] = { Dimension = v, Item = Inspect.Item.Detail(v.type), Type = v.type }
			scount = scount + 1
			added[k] = true
			changed = true
		end
	end

	if changed then
		util.Events:Invoke("Dimension.SelectionChanged", selected, added, removed, scount, oldscount)
	end
end, "Additional.Dimension:Dimension.Layout.Update")

end
--- CLIPBOARD ---
do

local clipboard

module:RegisterCommand("copy", "Copy information about the selection", function()
	local s, count = GetSelection()
	if count == 0 then
		module:Error("No selection")
		return
	elseif count > 1 then
		module:Error("Cannot copy multiple items")
		return
	end

	clipboard = s[next(s)]
	print("Copied " .. clipboard.Item.name)
end)

module:RegisterCommand("paste <field>", "Paste a copied value onto the selection", function(field)
	if not field then
		module:Error("Field required")
		return
	elseif not clipboard then
		module:Error("Clipboard is empty")
		return
	elseif not clipboard.Dimension[field] then
		module:Error("Invalid field")
		return
	end

	local paste = { [field] = clipboard.Dimension[field] }
	for k, v in pairs(GetSelection()) do
		Command.Dimension.Layout.Place(v.Dimension.id, paste)
	end
end)

module:RegisterCommand("paste-orientation", "Paste copied orientation onto the selection", function()
	if not clipboard then
		module:Error("Clipboard is empty")
		return
	end

	local paste = { pitch = clipboard.Dimension.pitch, roll = clipboard.Dimension.roll, yaw = clipboard.Dimension.yaw }
	for k, v in pairs(GetSelection()) do
		Command.Dimension.Layout.Place(v.Dimension.id, paste)
	end
end)

end
--- EDIT ---
do

module:RegisterCommand("get [<field>]", "Get dimension information about the selection", function(field)
	local selection, count = GetSelection()
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

module:RegisterCommand("get-item [<field>]", "Get item information about the selection", function(field)
	local selection, count = GetSelection()
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

module:RegisterCommand("set <field> <value>", "Set dimension information about the selection", function(field, value)
	if not ({ coordX = true, coordY = true, coordZ = true, pitch = true, roll = true, scale = true, yaw = true })[field] then
		module:Error("Invalid field")
		return
	end
	local update = { [field] = tonumber(value) }
	for k, v in pairs((GetSelection())) do
		Command.Dimension.Layout.Place(v.Dimension.id, update)
	end
end)

end
--- TOOLTIP ---
do

local changing = false
local inuse = false

local tooltip = {
	frame = UI.CreateFrame("Frame", "Additional.Dimension.tooltip.frame", util.UI.Context)
}

tooltip.background = UI.CreateFrame("Texture", "Additional.Dimension.tooltip.background", tooltip.frame)
tooltip.background:SetAllPoints()
tooltip.background:SetLayer(1)
tooltip.background:SetTexture(addon.identifier, "textures/frame.small.black.png")

tooltip.frame:SetBackgroundColor(0.0, 0.0, 0.0)
tooltip.frame:SetPoint("BOTTOMRIGHT", UI.Native.TooltipAnchor, "BOTTOMRIGHT")
tooltip.frame:SetVisible(false)

tooltip.framebody = UI.CreateFrame("Frame", "Additional.Dimension.tooltip.framebody", tooltip.frame)
tooltip.framebody:SetLayer(2)

tooltip.text = UI.CreateFrame("Text", "Additional.Dimension.tooltip.text", tooltip.framebody)
tooltip.text:SetPoint("BOTTOMRIGHT", tooltip.background, "BOTTOMRIGHT", -5, -5)
tooltip.text:SetFontColor(1.0, 1.0, 1.0, 1.0)
tooltip.text:SetFontSize(14)

tooltip.framebody:SetPoint("TOPLEFT", tooltip.text, "TOPLEFT", -5, -5)
tooltip.frame:SetPoint("TOPLEFT", tooltip.framebody, "TOPLEFT")

util.Events:Register("Dimension.SelectionChanged", function(h, selection, added, removed, count, oldcount)
	changing = true

	if count ~= 1 and oldcount == 1 then
		Command.Tooltip(nil)
		inuse = false
	elseif count <= 1 and oldcount > 1 then
		tooltip.frame:SetVisible(false)
		inuse = false
	end

	if count == 1 then
		Command.Tooltip(selection[next(selection)].Type)
		inuse = true
	elseif count >= 1 then
		local counts = {}
		local names = {}
		for k, v in pairs(selection) do
			counts[v.Item.name] = (counts[v.Item.name] or 0) + 1
			table.insert(names, v.Item.name)
		end
		table.sort(names)

		local lines = {}
		for i, v in ipairs(names) do
			if counts[v] then
				table.insert(lines, v .. (counts[v] == 1 and "" or " (x" .. counts[v] .. ")"))
				counts[v] = nil
			end
		end

		tooltip.text:SetText(table.concat(lines, "\n"))
		tooltip.frame:SetVisible(true)
		inuse = true
	end

	changing = false
end)

end
