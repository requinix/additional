local addon, util = ...
local module = util.Module:Register("Dimension", "dim")

--[=[

Dimension.SelectionChange(selection[] selection, selection[] added, selection[] removed, int newselectedcount, int oldselectedcount)
Signals a change in the dimension items currently selected
	Arguments
		selection[] selection - all selected items
		selection[] added     - newly selected items, if any
		selection[] removed   - newly unselected items, if any
		int newselectedcount  - number of items selected
		int oldselectedcount  - previous number of items selected

selection[], int module.GetSelection()
Get all selected dimension items
	Returns
		selection[] - selected items
		int         - number of items selected

class selection

	table Dimension
	Dimension item information

	table Item
	Item information

	string Type
	Type ID

]=]

local scount = 0
local selected = {}

local function Process(items)
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
		util.Event:Invoke("Dimension.SelectionChange", selected, added, removed, scount, oldscount)
	end
end

local function Unselect(items)
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
		util.Event:Invoke("Dimension.SelectionChange", selected, {}, removed, scount, oldscount)
	end
end

function module.GetSelection()
	return selected, scount
end

module:EventAttach(Event.Dimension.Layout.Remove, function(h, items)
	Unselect(items)
end, "Layout.Remove")

module:EventAttach(Event.Dimension.Layout.Update, function(h, items)
	Process(items)
end, "Layout.Update")

module:OnDisable(function()
	Unselect(selected)
end)

module:OnEnable(function()
	Process(Inspect.Dimension.Layout.List())
end)
