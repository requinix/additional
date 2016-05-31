local addon, data = ...
local source = "currency"

local ProcessCurrencies

Command.Event.Attach(Event.Currency, function(h, currencies)
	data.Events:Invoke("Tracking.SourceUpdate", source, ProcessCurrencies(currencies))
end, "Additional.Tracking.Currency:Currency")

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

-- {Color and/or DefaultColors} Data Description IdIndex [MaxIndex] NameIndex [Tier] ValueFormat ValueIndex
data.Events:Invoke("Tracking.SourceRegistration", source, {
	Color = function(currency, value, goal) return currency.rarity and data.COLORS.Item[currency.rarity] or data.COLORS.Item.Common end,
	Data = ProcessCurrencies(Inspect.Currency.List()),
	DefaultColors = {
		Goal = { 0.75, 0.5, 0.0 },
		Max = { 1.0, 0.0, 0.0 }
	},
	Description = "Currencies",
	IdIndex = "id",
	MaxIndex = "max",
	NameIndex = "name",
	ValueFormat = "%d",
	ValueIndex = "amount"
})
