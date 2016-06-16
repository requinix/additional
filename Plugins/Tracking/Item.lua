local addon, util = ...
local plugin = util.Plugins:Register("Tracking", "Item")

local history = {}
local items = {}

local source = {
	Color = function(item, value, goal) return item.rarity and util.Data.RiftColors.Item[item.rarity] or util.Data.RiftColors.Item.common end,
	Data = {},
	DefaultColors = {
		Goal = { 0.75, 0.5, 0.0 }
	},
	Description = "Inventory items",
	IconIndex = "icon",
	IdIndex = "type",
	NameIndex = "name",
	ValueFormat = "%d",
	ValueIndex = "count"
}

ProcessSlots = function(slots)
	if isstring(slots) then
		slots = Inspect.Item.List(slots)
	end

	local update = {}
	local deltas = {}

	local count
	local details = Inspect.Item.Detail(slots)
	local type
	for k, v in pairs(slots) do
		if history[k] then
			type = history[k].type
			items[type].count = items[type].count - history[k].count
			update[type] = items[type]
			deltas[type] = (deltas[type] or 0) - history[k].count
			history[k] = nil
		end
		if details[k] then
			count = details[k].stack or 1
			type = details[k].type:match("[^,]+")
			history[k] = {
				type = type,
				count = count
			}
			if items[type] then
				items[type].count = items[type].count + count
			else
				items[type] = {
					count = count,
					name = details[k].name,
					icon = details[k].icon,
					rarity = details[k].rarity,
					type = type
				}
			end
			update[type] = items[type]
			deltas[type] = (deltas[type] or 0) + count
		end
	end

	for k, v in pairs(deltas) do
		if v == 0 then
			update[k] = nil
		end
	end

	return update
end

plugin:OnEnable(function()
	util.Events:Invoke("Tracking.SourceRegistration", "item", source)

	local bags = {}
	local framestart = Inspect.Time.Frame()
	util.Events.AttachWhile(Event.System.Update.Begin, function()
		if not bags or not next(bags) then
			bags = Inspect.Item.Detail(Utility.Item.Slot.Inventory("bag"))
			return true
		end

		-- pick a bag
		local k, v = next(bags)
		if Inspect.Time.Frame() - framestart > 10 then
			-- too much time has passed (!?)
			plugin:Error("Failed to load inventory items")
			return false
		elseif not Inspect.Item.List(k) then
			-- bag does not exist (!?)
			bags[k] = nil
			return true
		end

		local inventory, bag, b = Utility.Item.Slot.Parse(k)
		local first = Utility.Item.Slot.Inventory(b, 1)
		-- check first slot
		if Inspect.Item.List(first) == nil then
			-- first slot not ready
			return true
		end

		-- ready. dequeue bag and process slots
		bags[k] = nil
		util.Events:Invoke("Tracking.SourceUpdate", "item", ProcessSlots({ [k] = true }))
		util.Events:Invoke("Tracking.SourceUpdate", "item", ProcessSlots(Utility.Item.Slot.Inventory(b)))
		return next(bags) ~= nil
	end, "Additional.Tracking.Item:System.Update.Begin")
end)

plugin:EventAttach(Event.Item.Slot, function(h, updates)
	util.Events:Invoke("Tracking.SourceUpdate", "item", ProcessSlots(updates))
end, "Item.Slot")

plugin:EventAttach(Event.Item.Update, function(h, updates)
	util.Events:Invoke("Tracking.SourceUpdate", "item", ProcessSlots(updates))
end, "Item.Update")
