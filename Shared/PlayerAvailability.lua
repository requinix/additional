local addon, util = ...

util.Shared = util.Shared or {}
util.Shared.PlayerAvailability = {}

local available = false

--[=[

Shared.PlayerAvailability.Change(bool available, string id)
Signals a change in availability for the player
	Arguments
		bool available - whether the player is now fully available
		string id      - player unit ID (when available)

table util.Shared.PlayerAvailability.Test()
Return the player if it is available
	Returns
		table - player

]=]

function util.Shared.PlayerAvailability.Test()
	return available and Inspect.Unit.Detail("player") or nil
end

Command.Event.Attach(Event.Unit.Availability.Full, function(h, units)
	for k, v in pairs(units) do
		if v == "player" then
			available = true
			util.Event:Invoke("Shared.PlayerAvailability.Change", true, k)
			return
		end
	end
end, "Shared.PlayerAvailability:Unit.Availability.Full")

Command.Event.Attach(Event.Unit.Availability.Partial, function(h, units)
	for k, v in pairs(units) do
		if v == "player" then
			if available then
				available = false
				util.Event:Invoke("Shared.PlayerAvailability.Change", false, k)
			end
			return
		end
	end
end, "Shared.PlayerAvailability:Unit.Availability.Partial")
