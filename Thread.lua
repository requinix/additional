local addon, util = ...

local thread = {}

--[=[

class util.Thread

	void util.Thread:Create(function f)
	Create a thread that will run during System.Update.End events
		Parameters
			function f - backing function to execute
				Parameters
					function - heartbeat function to be used in a loop
						Returns
							bool - always true

]=]

function thread.listen(self)
	if not self.listening then
		self.listening = true
		util.Event.AttachWhile(Event.System.Update.End, function()
			if #self > 0 then
				thread.run(self)
				return true
			else
				self.listening = false
				return false
			end
		end, "Thread:listen")
	end
end

function thread.run(self)
	local t
	for i = #self, 1, -1 do
		t = self[i]
		t.breakpoint = Inspect.Time.Real() + Inspect.System.Watchdog() / (i + 1)
		coroutine.resume(t.thread)
		if coroutine.status(t.thread) == "dead" then
			table.remove(self, i)
		end
	end
end

local function threadCreate(self, f)
	local t = {
		breakpoint = 0,
		thread = coroutine.create(f)
	}
	self[#self + 1] = t
	coroutine.resume(t.thread, function()
		if Inspect.Time.Real() >= t.breakpoint then
			coroutine.yield()
		end
		return true
	end)
	thread.listen(self)
end

util.Thread = setmetatable({}, { __index = {
	Create = threadCreate
}})
