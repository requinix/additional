local addon, util = ...

--[=[

class event

	void event:Abort()
	Abort this event and prevent subsequent event handlers from executing

	bool event:Fire(function invoker, any...)
	Fire this event using an invoker and event arguments
		Parameters
			function invoker - function to invoke the event through Rift's event system
			any...           - event arguments
		Return
			bool             - whether the event completed without being aborted

	function event:GetDispatcher(function f)
	Get a dispatch function that will invoke f if the event has not been aborted
		Parameters
			function f - callback function
		Returns
			function   - dispatch function
				Parameters
					any... - event data

]=]

local function ceventAbort(self)
	self.aborted = true
end

local function ceventFire(self, invoker, ...)
	self.aborted = false
	invoker(...)
	return self.aborted == false
end

local function ceventGetDispatcher(self, f)
	return function(...)
		if not self.aborted then
			f(...)
		end
	end
end

local class_event = { __index = {
	Abort = ceventAbort,
	Fire = ceventFire,
	GetDispatcher = ceventGetDispatcher
}}

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

	bool util.Events:Invoke(string key [, any... ])
	Invoke an event, wrapping the function returned by Utility.Event.Create
		Parameters
			string key - event name
			any        - event arguments, passed to registered listeners after the event handle
		Returns
			bool       - whether the event completed without being aborted

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
	return self[key] and self[key].Event:Fire(self[key].Invoke, ...) or self[key] == nil
end

local function eventsRegister(self, key, callback)
	if not self[key] then
		self[key] = { Count = 0 }
		self[key].Invoke, self[key].Event = Utility.Event.Create(addon.identifier, key)
		setmetatable(self[key].Event, class_event)
	end
	self[key].Count = self[key].Count + 1
	Command.Event.Attach(self[key].Event, self[key].Event:GetDispatcher(callback), string.format("%s.Event.%s#%d", addon.identifier, key, self[key].Count))
end

util.Events = setmetatable({}, { __index = {
	AttachWhile = eventsAttachWhile,
	Invoke = eventsInvoke,
	Register = eventsRegister
}})
