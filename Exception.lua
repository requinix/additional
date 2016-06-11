local addon, util = ...

--[=[
	bool status, table data, table[] errors = util.tpcall(function f)
	A reimplemented xpcall using Rift API commands that instead returns the additional data in a table as the second return value

	Exception data (- from Event.System.Error, + added by this function)
	- addon        The identifier of the responsible addon.
	- axis         The axis influenced by the error.
	- deprecation  Indicates that the error was caused by attempted use of deprecated functionality.
	- error	       The actual error message generated.
	- event        The name of the event responsible.
	- file         The name of the file responsible.
	- frame        The name of the frame that the event was generated on.
	- id           The internal ID of this error.
	- info         The info string provided as part of the event handler.
	- script       The exact script entered by the user.
	- stacktrace   The stacktrace at the point of the error.
	+ time         High-resolution realtime timer. (see Inspect.Time.Real)
	- type         Error type.

	type			addon	axis	deprec	error	event	file	frame	id	info	script	strace	time
	----			-----	----	------	-----	-----	----	-----	--	----	------	------	----
	callback						deprec									id							time	(unknown)
	dispatch		addon			deprec	error							id	info			strace	time	indicates an error within a Utility.Dispatch handler.
	event			addon			deprec	error	event					id	info			strace	time	indicates an error within a global event handler.
	fileLoad		addon					error			file			id							time	indicates a parse failure when attempting to load an addon.
	fileNotFound	addon									file			id							time	indicates a missing file when attempting to load an addon.
	fileRun			addon			deprec	error			file			id					strace	time	indicates an execution error when attempting to load an addon.
	frameEvent		addon			deprec	error	event			frame	id					strace	time	indicates an error within a frame event handler.
	internal										event					id							time	indicates an error within Rift's code (hopefully you'll never see this).
	layoutError				axis											id					strace	time	indicates an invalid position found when evaluating the layout.
	layoutLoop				axis											id					strace	time	indicates a dependency loop found when evaluating the layout.
	perfError		addon													id	info			strace	time	indicates a watchdog performance error, and that the Lua thread may have been interrupted.
	perfWarning		addon													id	info			strace	time	indicates a watchdog performance warning.
	queue							deprec									id							time	(unknown)
	requirement		addon													id	info			strace	time	indicates an error caused by not fulfilling function requirements.
	script							deprec	error							id			script	strace	time	indicates an error within a user-entered /script.
	text			addon					error							id					strace	time	indicates an error in Lua code embedded in HTML text.

	Parameters
		function f   - function to execute; all return values will be packaged into the data table

	Returns
		bool status    - whether the function was called without errors
		table data     - table containing all return values from the function (if any) or the exception data
		table[] errors - all errors caught during execution, even if they are not fatal
]=]
util.tpcall = function(f)
	local status, data, exceptions = false, {}, {}
	local handler = function(h, error)
		error.time = Inspect.Time.Real()
		data = error
		table.insert(exceptions, error)
	end

	Command.Event.Attach(Event.System.Error, handler, "tpcall.handler")
	Utility.Dispatch(function()
		data = { f() }
		status = true
	end, addon.identifier, "util.tpcall")
	Command.Event.Detach(Event.System.Error, handler, "tpcall.handler")

	return status, data, exceptions
end

-- supported order of operations:
-- try -> ( catch | finally )* -> ( success | failure)* -> unpack

local class_exception_ctor

--[=[

class exception

	exception exception:catch(function f)
	Provide "catch" functionality in case of an exception being thrown during a "try"; not available after calling success() or failure()
		Parameters
			function f     - callback function
				Parameters
					exception - exception being caught
				Returns
					any
		Returns
			exception      - current state of the exception in the chain

	exception exception:failure(function f)
	Provide a callback in case of failure during an Exception chain
		Parameters
			function f     - callback function
				Parameters
					exception - caught exception
				Returns
					any
		Returns
			exception      - current state of the exception in the chain

	exception exception:finally(function f)
	Provide "finally" functionality regardless whether or not an exception has been thrown; not available after calling success() or failure()
		Parameters
			function f     - callback function
				Parameters
					exception - exception state table
				Returns
					any
		Returns
			exception      - current state of the exception in the chain

	exception exception:success(function f)
	Execute a callback if the chain has not thrown an exception at this point
		Parameters
			function f     - callback function
				Parameters
					any - any values returned at this point
				Returns
					any
		Returns
			exception      - current state of the exception in the chain

	any... exception:unpack()
	Unpack any data returned by the callback used in try(), failure(), or success()
		Returns
			any... - data returned by the callback

]=]

local function cexceptionCatch(data, f)
	if data.result then
		return data
	end
	local caught = util.Exception.try(function()
		return f(data)
	end)
	return caught.result and data or caught
end

local function cexceptionFailure(data, f)
	return data.result and data or setmetatable({ f(data) }, class_exception_ctor(false, false))
end

local function cexceptionFinally(data, f)
	local finish = util.Exception.try(function()
		return f(data)
	end)
	return finish.result and data or finish
end

local function cexceptionSuccess(data, f)
	return data.result and setmetatable({ f(data:unpack()) }, class_exception_ctor(false, true)) or data
end

local function class_exception_ctor(full, result)
	return { __index = {
		catch = full and cexceptionCatch or nil,
		failure = cexceptionFailure,
		finally = full and cexceptionFinally or nil,
		result = result,
		success = cexceptionSuccess,
		unpack = unpack
	}}
end

--[=[

class util.Exception

	exception util.Exception.try(function f)
	Provide "try" functionality in case an exception/error may be thrown during execution
		Parameters
			function f - function to execute
				Returns
					any
		Returns
			exception  - exception table containing function return values (if successful) or "exception" containing the exception data

]=]

local function exceptionTry(f)
	local result, data = util.tpcall(f)
	return setmetatable(result and data or { exception = data }, class_exception_ctor(true, result))
end

util.Exception = setmetatable({}, { __index = {
	try = exceptionTry
}})
