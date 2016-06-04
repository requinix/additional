local addon, data = ...
local source = "item"

--- TESTING: FIND ITEM ---
do

data.Modules:Named("Testing"):RegisterCommand("find-item <name>", "Find item on the player", function(name)
	local lname = name:lower()
	for k, v in pairs(Inspect.Item.Detail(Utility.Item.Slot.All())) do
		if v.name:lower() == lname then
			local t = table.pack(Utility.Item.Slot.Parse(k))
			table.insert(t, v)
			dump(unpack(t))
		end
	end
end)

end
--- TRACKING ---
do

local history = {}
local items = {}

Command.Event.Attach(Event.Addon.Startup.End, function()
	local bags = Inspect.Item.Detail(Utility.Item.Slot.Inventory("bag"))
	local framestart = Inspect.Time.Frame()
	data.Events.AttachWhile(Event.System.Update.Begin, function()
		-- pick a bag
		local k, v = next(bags)
		if not k then
			-- no more bags. stop
			return false
		elseif Inspect.Time.Frame() - framestart > 10 then
			-- too much time has passed (!?)
			data.Modules:Named("Tracking"):Error("Failed to load inventory items")
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
		data.Events:Invoke("Tracking.SourceUpdate", source, ProcessSlots(Utility.Item.Slot.Inventory(b)))
		return true
	end, "Additional.Tracking.Item:System.Update.Begin")
end, "Additional.Plugins.Item:Tracking:Addon.Startup.End")

Command.Event.Attach(Event.Item.Slot, function(h, updates)
	data.Events:Invoke("Tracking.SourceUpdate", source, ProcessSlots(updates))
end, "Additional.Plugins.Item:Tracking:Item.Slot")

Command.Event.Attach(Event.Item.Update, function(h, updates)
	data.Events:Invoke("Tracking.SourceUpdate", source, ProcessSlots(updates))
end, "Additional.Plugins.Item:Tracking:Item.Update")

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

data.Events:Invoke("Tracking.SourceRegistration", source, {
	Color = function(item, value, goal) return item.rarity and data.COLORS.Item[item.rarity] or data.COLORS.Item.Common end,
	Data = {},
	DefaultColors = {
		Goal = { 0.75, 0.5, 0.0 }
	},
	Description = "Inventory items",
	Icon = function(data) return "Rift", items[data.id].icon end,
	IdIndex = "type",
	NameIndex = "name",
	ValueFormat = "%d",
	ValueIndex = "count"
})

end
