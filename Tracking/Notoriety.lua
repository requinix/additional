local addon, data = ...
local source = "notoriety"

data.Events:Invoke("Tracking.SourceRegistration", source, {
	Data = Inspect.Faction.Detail(Inspect.Faction.List()),
	DefaultColors = {
		Normal = { 0.0, 0.66, 0.0 },
		Goal = { 0.25, 0.25, 0.75 },
		Max = { 0.0, 0.75, 0.25 }
	},
	Description = "Faction notoriety",
	IdField = "id",
	NameIndex = "name",
	ValueFormat = "%d",
	ValueIndex = "notoriety",
	Tier = function(value)
		if     value <  23000  then return "???",       value,          nil
		elseif value <= 26000  then return "Neutral",   value - 23000,  3000
		elseif value <= 36000  then return "Friendly",  value - 26000,  10000
		elseif value <= 56000  then return "Decorated", value - 36000,  20000
		elseif value <= 91000  then return "Honored",   value - 56000,  35000
		elseif value <= 151000 then return "Revered",   value - 91000,  60000
		elseif value <  241000 then return "Glorified", value - 151000, 90000
		else                        return "Venerated", value - 241000, nil
		end
	end
})

Command.Event.Attach(Event.Faction.Notoriety, function(h, notoriety)
	data.Events:Invoke("Tracking.SourceUpdate", source, Inspect.Faction.Detail(notoriety))
end, "Additional.Tracking.Notoriety:Faction.Notoriety")
