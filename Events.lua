local addon, util = ...

--[=[

class util.Events

	void util.Events.AttachWhile(table event, function callback, string name)
	Attach a callback to an event and auotmatically detach if the callback ever returns false, wrapping Command.Event.Attach/Detach
		Parameters
			table event       - event table as seen in the Event hierarchy
			function callback - event handler
				Parameters
					table h - event handle
					any     - event arguments
				Returns
					bool    - true to continue watching the event, false to detach the handler
			string name       - event handler name

	void util.Events:Invoke(string key [, any... ])
	Invoke an event, wrapping the function returned by Utility.Event.Create
		Parameters
			string key - event name
			any        - event arguments, passed to registered listeners after the event handle

	void util.Events:Register(string key, function callback)
	Register an event listener, wrapping Utility.Event.Create and Command.Event.Attach
		Parameters
			string key        - event name
			function callback - event handler
				Parameters
					table h - event handle
					any     - event parameters

]=]

local function eventsAttachWhile(event, callback, name)
	local handler
	handler = function(...)
		if not callback(...) then
			Command.Event.Detach(event, handler, name .. "<While>")
		end
	end
	Command.Event.Attach(event, handler, name .. "<While>")
end

local function eventsInvoke(self, key, ...)
	if self[key] then
		self[key].Invoke(...)
	end
end

local function eventsRegister(self, key, callback)
	if not self[key] then
		self[key] = { Count = 0 }
		self[key].Invoke, self[key].Handle = Utility.Event.Create(addon.identifier, key)
	end
	self[key].Count = self[key].Count + 1
	Command.Event.Attach(self[key].Handle, callback, string.format("%s.Event.%s:%d", addon.identifier, key, self[key].Count))
end

util.Events = setmetatable({}, { __index = {
	AttachWhile = eventsAttachWhile,
	Invoke = eventsInvoke,
	Register = eventsRegister
}})
