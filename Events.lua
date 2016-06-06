local addon, data = ...

--[=[ PLAYER AVAILABILITY ---

	bool data.PlayerAvailable - current state of player availability

	PlayerAvailabilityChange(bool available, string id)
	Signals a change in availability for the player

	Parameters
		bool available - whether the player is now fully available
		string id      - player unit ID

]=]

do

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

end
