local addon, data = ...

local setdata
setdata = function(source, table)
	setmetatable(source, { __index = function(self, name) return rawget(self, name:upper()) end })
	for k, v in pairs(table) do
		if istable(v) then
			local t = {}
			setdata(t, v)
			source[isstring(k) and k:upper() or k] = t
		else
			source[isstring(k) and k:upper() or k] = v
		end
	end
end

data.COLORS = {}
setdata(data.COLORS, {
	Calling = {
		Cleric  = hexcolor2table(0x77EF00), -- green
		Mage    = hexcolor2table(0xC85EFF), -- purple
		Rogue   = hexcolor2table(0xFFDB00), -- yellow
		Warrior = hexcolor2table(0xFF2828)  -- red
	},
	Item = {
		Trash    = hexcolor2table(0x888888), -- gray
		Sellable = hexcolor2table(0x888888), -- gray
		Common   = hexcolor2table(0xFFFFFF), -- white
		Uncommon = hexcolor2table(0x00CC00), -- green
		Rare     = hexcolor2table(0x2681FE), -- dark blue
		Epic     = hexcolor2table(0xB049FF), -- purple
		Relic    = hexcolor2table(0xFF9900), -- orange
		Quest    = hexcolor2table(0xFFF600), -- yellow

		Bound = hexcolor2table(0xFFF690), -- gold
		Set   = hexcolor2table(0x76F0E4)  -- green
	},
	Monster = {
		Trivial    = hexcolor2table(0xB4B4B4), -- gray
		Easy       = hexcolor2table(0x51C412), -- green
		Medium     = hexcolor2table(0xD5C300), -- yellow
		Hard       = hexcolor2table(0xDe8E03), -- orange
		Impossible = hexcolor2table(0xCF1313), -- red

		Neutral    = hexcolor2table(0xFDE72B), -- yellow
		Friendly   = hexcolor2table(0x65E200), -- green
		Hostile    = hexcolor2table(0xF30000)  -- red
	}
})

data.VERSION = Inspect.System.Version().internal
