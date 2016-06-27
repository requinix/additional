local addon, util = ...
local plugin = util.Plugin:Register("Dimension", "Tooltip")

local changing = false

local tooltip = {
	background = nil,
	frame = UI.CreateFrame("Frame", "Dimension.Tooltip.frame", util.UI.Context),
	framebody = nil,
	text = nil
}

local SelectionChange

tooltip.background = UI.CreateFrame("Texture", "Dimension.Tooltip.background", tooltip.frame)
tooltip.background:SetAllPoints()
tooltip.background:SetLayer(1)
tooltip.background:SetTexture(addon.identifier, "textures/frame.small.black.png")

tooltip.frame:SetBackgroundColor(0.0, 0.0, 0.0)
tooltip.frame:SetPoint("BOTTOMRIGHT", UI.Native.TooltipAnchor, "BOTTOMRIGHT")
tooltip.frame:SetVisible(false)

tooltip.framebody = UI.CreateFrame("Frame", "Dimension.Tooltip.framebody", tooltip.frame)
tooltip.framebody:SetLayer(2)

tooltip.text = UI.CreateFrame("Text", "Dimension.Tooltip.text", tooltip.framebody)
tooltip.text:SetPoint("BOTTOMRIGHT", tooltip.background, "BOTTOMRIGHT", -5, -5)
tooltip.text:SetFontColor(1.0, 1.0, 1.0, 1.0)
tooltip.text:SetFontSize(14)

tooltip.framebody:SetPoint("TOPLEFT", tooltip.text, "TOPLEFT", -5, -5)
tooltip.frame:SetPoint("TOPLEFT", tooltip.framebody, "TOPLEFT")

SelectionChange = function(selection, count, oldcount)
	changing = true

	-- remove the current tooltip
	if count ~= 1 and oldcount == 1 then
		Command.Tooltip(nil)
	elseif count <= 1 and oldcount > 1 then
		tooltip.frame:SetVisible(false)
	end

	-- set the new tooltip
	if count == 1 then
		Command.Tooltip(selection[next(selection)].Type)
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
	end

	changing = false
end

plugin:OnDisable(function()
	local selection, count = plugin:Module().GetSelection()
	SelectionChange({}, 0, count)
end)

plugin:OnEnable(function()
	local selection, count = plugin:Module().GetSelection()
	SelectionChange(selection, count, 0)
end)

plugin:RegisterEvent("Dimension.SelectionChange", function(h, selection, added, removed, count, oldcount)
	SelectionChange(selection, count, oldcount)
end)
