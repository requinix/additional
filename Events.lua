local addon, util = ...

--[=[ PLAYER AVAILABILITY ---

	bool util.PlayerAvailable - current state of player availability

	event PlayerAvailabilityChange(bool available, string id)
	Signals a change in availability for the player

	Parameters
		bool available - whether the player is now fully available
		string id      - player unit ID

]=]

do

util.PlayerAvailable = false

Command.Event.Attach(Event.Unit.Availability.Full, function(h, units)
	for k, v in pairs(units) do
		if v == "player" then
			util.PlayerAvailable = true
			util.Events:Invoke("PlayerAvailabilityChange", true, k)
			break
		end
	end
end, "Additional.InitEvents:Unit.Availability.Full")

Command.Event.Attach(Event.Unit.Availability.Partial, function(h, units)
	for k, v in pairs(units) do
		if v == "player" then
			if util.PlayerAvailable then
				util.PlayerAvailable = false
				util.Events:Invoke("PlayerAvailabilityChange", false, k)
			end
			break
		end
	end
end, "Additional.InitEvents:Unit.Availability.Partial")

end
