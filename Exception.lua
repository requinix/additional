local addon, util = ...

util.Exception = {}

-- supported order of operations:
-- try -> ( catch | finally )* -> ( success | failure)* -> unpack

--[=[
	bool status, table data = tpcall(function f, function err)
	Wrap xpcall but return the additional data in a table as the second return value

	Parameters
		function f   - function to execute; all return values will be packaged into a table
		function err - error handler as is used by xpcall

	Returns
		bool status  - whether the function was called without errors
		table data   - table containing all return values from the function (if any)
]=]
local tpcall = function(f, err)
	return (function(...)
		return (select(1, ...)), { select(2, ...) }
	end)(xpcall(f, err))
end

--[=[
	exception util.Exception.catch(exception data, function f)
	Provide "catch" functionality in case of an exception being thrown during a "try"

	Returned exception support: result, trace; catch, finally, success, failure, unpack

	Parameters
		exception data - exception returned through the Exception chain
		function f     - callback function
			Parameters
				exception - exception being caught
			Returns
				any

	Returns
		exception      - current state of the exception in the chain
]=]
function util.Exception.catch(data, f)
	if data.result then
		return data
	end
	local caught = util.Exception.try(function()
		return f(data)
	end)
	return caught.result and data or caught
end

--[=[
	exception util.Exception.failure(exception data, function f)
	Provide a callback in case of failure during an Exception chain

	Returned exception support: result, trace; success, failure, unpack

	Parameters
		exception data - exception returned through the Exception chain
		function f     - callback function
			Parameters
				exception - caught exception
			Returns
				any
	Returns
		exception      - current state of the exception in the chain
]=]
function util.Exception.failure(data, f)
	if data.result then
		return data
	else
		-- no error handling
		return setmetatable({ f(data) }, { __index = {
			failure = util.Exception.failure,
			result = false,
			success = function(data) return data end,
			trace = data.trace,
			unpack = unpack
		}})
	end
end

--[=[
	exception util.Exception.finally(exception data, function f)
	Provide "finally" functionality regardless whether or not an exception has been thrown

	Returned exception support: result, trace; catch, finally, success, failure, unpack

	Parameters
		exception data - state table returned through the Exception chain
		function f     - callback function
			Parameters
				exception - exception state table
			Returns
				any

	Returns
		exception      - current state of the exception in the chain
]=]
function util.Exception.finally(data, f)
	local finish = util.Exception.try(function()
		return f(data)
	end)
	return finish.result and data or finish
end

--[=[
	exception util.Exception.success(exception data, function f)
	Execute a callback if the chain has not thrown an exception at this point

	Returned exception support: result; success, failure, unpack

	Parameters
		exception data - state table returned through the Exception chain
		function f     - callback function
			Parameters
				any - any values returned at this point
			Returns
				any

	Returns
		exception      - current state of the exception in the chain
]=]
function util.Exception.success(data, f)
	if data.result then
		-- no error handling
		return setmetatable({ f(data:unpack()) }, { __index = {
			failure = function(data) return data end,
			result = true,
			success = util.Exception.success,
			unpack = unpack
		}})
	else
		return data
	end
end

--[=[
	exception util.Exception.try(function f)
	Provide "try" functionality in case an exception/error may be thrown during execution

	Returned exception support: result, trace; catch, finally, success, failure, unpack

	Parameters
		function f - function to execute
			Returns
				any

	Returns
		exception  - exception table; if successful then result=true and table may contain data, if failure then result=false and table is empty
]=]
function util.Exception.try(f)
	local trace
	local result, data = tpcall(f, function(err)
		trace = debug.traceback("", 2)
		return istable(err) and err or { message = err }
	end)
	return setmetatable(result and data or data[1], { __index = {
		catch = util.Exception.catch,
		failure = util.Exception.failure,
		finally = util.Exception.finally,
		result = result,
		success = util.Exception.success,
		trace = trace,
		unpack = result and unpack or function(data) return data end
	}})
end
