local addon, util = ...
local plugin = util.Plugin:Register("Tracking", "Notoriety")

local tiers = {
	{    0,     23000,      26000,       36000,     56000,     91000,      151000,      241000 },
	{ "???", "Neutral", "Friendly", "Decorated", "Honored", "Revered", "Glorified", "Venerated" }
}

local source = {
	Data = {},
	DefaultColors = {
		Normal = util.Data.PaletteColors.Green,
		Goal = { 0.25, 0.25, 0.75 },
		Max = { 0.0, 0.75, 0.25 }
	},
	Description = "Faction notoriety",
	IdIndex = "id",
	NameIndex = "name",
	ValueFormat = "%d",
	ValueIndex = "notoriety",
	Tier = function(value)
		for i, v in ipairs(tiers[1]) do
			if value < v then
				return tiers[2][i - 1], value - tiers[1][i - 1], v - tiers[1][i - 1]
			elseif value == v then
				return tiers[2][i], value - tiers[1][i - 1], value - tiers[1][i - 1]
			end
		end
		return "???", value, nil
	end
}

plugin:OnEnable(function()
	util.Event:Invoke("Tracking.SourceRegistration", "notoriety", source)
	util.Event:Invoke("Tracking.SourceUpdate", "notoriety", Inspect.Faction.Detail(Inspect.Faction.List()))
end)

plugin:EventAttach(Event.Faction.Notoriety, function(h, notoriety)
	util.Event:Invoke("Tracking.SourceUpdate", "notoriety", Inspect.Faction.Detail(notoriety))
end, "Faction.Notoriety")
