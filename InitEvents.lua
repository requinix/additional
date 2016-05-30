local addon, data = ...

data.PlayerAvailable = false

Command.Event.Attach(Event.Unit.Availability.Full, function(h, units)
	for k, v in pairs(units) do
		if v == "player" then
			data.PlayerAvailable = true
			data.Events:Invoke("PlayerAvailabilityChange", true, k)
			break
		end
	end
end, "Additional.InitEvents:Unit.Availability.Full")

Command.Event.Attach(Event.Unit.Availability.Partial, function(h, units)
	for k, v in pairs(units) do
		if v == "player" then
			if data.PlayerAvailable then
				data.PlayerAvailable = false
				data.Events:Invoke("PlayerAvailabilityChange", false, k)
			end
			break
		end
	end
end, "Additional.InitEvents:Unit.Availability.Partial")
