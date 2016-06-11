local addon, util = ...
local source = "currency"

--- TESTING: FIND CURRENCY ---
do

util.Modules:Named("Testing"):RegisterCommand("find-currency <name>", "Find a currency on the player", function(name)
	local lname = name:lower()
	if lname == "coin" then
		dump(Inspect.Currency.Detail("coin"))
		return
	end

	for k, v in pairs(Inspect.Currency.Detail(Inspect.Currency.List())) do
		if v.name:lower() == lname then
			dump(v)
		end
	end
end)

end

--- TRACKING ---
do

local icons = {
	coin = "icons/currency.coin.png",
	credit = "icons/currency.credit.png"
}

local ProcessCurrencies

Command.Event.Attach(Event.Currency, function(h, currencies)
	util.Events:Invoke("Tracking.SourceUpdate", source, ProcessCurrencies(currencies))
end, "Additional.Plugins.Currency:Tracking:Currency")

ProcessCurrencies = function(currencies)
	local c = {}
	local items = Inspect.Item.Detail(currencies)
	for k, v in pairs(Inspect.Currency.Detail(currencies)) do
		c[k] = {
			amount = v.stack or 1,
			id = v.id,
			max = v.stackMax,
			name = v.name,
			rarity = items[k] and items[k].rarity
		}
	end
	return c
end

util.Events:Invoke("Tracking.SourceRegistration", source, {
	Color = function(currency, value, goal) return currency.rarity and util.Data.RiftColors.Item[currency.rarity] or util.RiftData.Colors.Item.common end,
	Data = ProcessCurrencies(Inspect.Currency.List()),
	DefaultColors = {
		Goal = { 0.75, 0.5, 0.0 },
		Max = { 1.0, 0.0, 0.0 }
	},
	Description = "Currencies",
	Icon = function(data) if icons[data.id] then return addon.identifier, icons[data.id] else return "Rift", Inspect.Currency.Detail(data.id).icon or Inspect.Item.Detail(data.id).icon end end,
	IdIndex = "id",
	MaxIndex = "max",
	NameIndex = "name",
	ValueFormat = "%d",
	ValueIndex = "amount"
})

end
