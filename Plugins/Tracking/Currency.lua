local addon, util = ...
local plugin = util.Plugins:Register("Tracking", "Currency")

local icons = {
	coin = "icons/currency.coin.png",
	credit = "icons/currency.credit.png"
}

local source = {
	AutoTracking = true,
	Color = function(currency, value, goal)
		return currency.rarity and util.Data.RiftColors.Item[currency.rarity] or util.Data.RiftColors.Item.common
	end,
	Data = {},
	DefaultColors = {
		Goal = { 0.75, 0.5, 0.0 },
		Max = { 1.0, 0.0, 0.0 }
	},
	Description = "Currencies",
	Icon = function(data)
		if icons[data.id] then
			return addon.identifier, icons[data.id]
		else
			return "Rift", Inspect.Currency.Detail(data.id).icon or Inspect.Item.Detail(data.id).icon
		end
	end,
	IdIndex = "id",
	MaxIndex = "max",
	NameIndex = "name",
	ValueFormat = "%d",
	ValueIndex = "amount"
}

local function ProcessCurrencies(currencies)
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

plugin:EventAttach(Event.Currency, function(h, currencies)
	util.Events:Invoke("Tracking.SourceUpdate", "currency", ProcessCurrencies(currencies))
end, "Tracking:Currency")

plugin:OnEnable(function()
	util.Events:Invoke("Tracking.SourceRegistration", "currency", source)
	util.Events:Invoke("Tracking.SourceUpdate", "currency", ProcessCurrencies(Inspect.Currency.List()))
end)
