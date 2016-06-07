local addon, util = ...

util.Data = {}

-- http://forums.riftgame.com/technical-discussions/addon-api-development/333518-official-addon-information-station.html#post4175070
util.Data.Colors = {
	Calling = {
		cleric  = { 0.4667, 0.9373, 0.0000 }, -- #77EF00 green
		mage    = { 0.7843, 0.3686, 1.0000 }, -- #C85EFF purple
		rogue   = { 1.0000, 0.8588, 0.0000 }, -- #FFDB00 yellow
		warrior = { 1.0000, 0.1569, 0.1569 }  -- #FF2828 red
	},
	Item = {
		trash    = { 0.5333, 0.5333, 0.5333 }, -- #888888 gray
		sellable = { 0.5333, 0.5333, 0.5333 }, -- #888888 gray
		common   = { 1.0000, 1.0000, 1.0000 }, -- #FFFFFF white
		uncommon = { 0.0000, 0.8000, 0.0000 }, -- #00CC00 green
		rare     = { 0.1490, 0.5059, 0.9961 }, -- #2681FE dark blue
		epic     = { 0.6902, 0.2863, 1.0000 }, -- #B049FF purple
		relic    = { 1.0000, 0.6000, 0.0000 }, -- #FF9900 orange
		quest    = { 1.0000, 0.9647, 0.0000 }, -- #FFF600 yellow

		bound = { 1.0000, 0.9647, 0.5647 }, -- #FFF690 gold
		set   = { 0.4627, 0.9412, 0.8941 }  -- #76F0E4 green
	},
	Monster = {
		trivial    = { 0.7059, 0.7059, 0.7059 }, -- #B4B4B4 gray
		easy       = { 0.3176, 0.7686, 0.0706 }, -- #51C412 green
		medium     = { 0.8353, 0.7647, 0.0000 }, -- #D5C300 yellow
		hard       = { 0.8706, 0.5569, 0.0118 }, -- #DE8E03 orange
		impossible = { 0.8118, 0.0745, 0.0745 }, -- #CF1313 red

		neutral  = { 0.9922, 0.9059, 0.1686 }, -- #FDE72B yellow
		friendly = { 0.3961, 0.8863, 0.0000 }, -- #65E200 green
		hostile  = { 0.9529, 0.0000, 0.0000 }  -- #F30000 red
	}
}

util.Data.Version = Inspect.System.Version().internal
