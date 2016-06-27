local addon, util = ...

--[=[
	bool isnumber(mixed value)
	Check if a value is a number

	Parameters
		mixed value - value

	Returns
		bool        - whether type(value) == "number"
]=]
isnumber = isnumber or function(v)
	return type(v) == "number"
end

--[=[
	bool isstring(mixed value)
	Check if a value is a string

	Parameters
		mixed value - value

	Returns
		bool        - whether type(value) == "string"
]=]
isstring = isstring or function(v)
	return type(v) == "string"
end

--[=[
	bool istable(mixed value)
	Check if a value is a table

	Parameters
		mixed value - value

	Returns
		bool        - whether type(value) == "table"
]=]
istable = istable or function(v)
	return type(v) == "table"
end

--[=[
	printf(format, args...)
	Simple wrapper for print(string.format(...))
]=]
printf = printf or function(...)
	print(string.format(...))
end

--[=[
	util.Error(string message, mixed arg...)
	Display an error message, optionally formatted with string.format

	Parameters
		string message - error message, or format string when used with additional arguments
		mixed arg...   - additional arguments to pass to string.format
]=]
function util.Error(message, ...)
	local m = select("#", ...) > 0 and string.format(message, ...) or message
	Command.Console.Display("general", false, "<font color=\"#FF0000\">" .. m .. "</font>", true)
end

Command.Event.Attach(Event.Addon.Load.End, function(h, identifier)
	if identifier == addon.identifier then
		for k, v in pairs(util.Module) do
			v:Enable()
		end

		printf("%s v%s loaded (%d modules, %d plugins)", addon.name, addon.toc.Version, (util.Module:Count()), (util.Plugin:Count()))
	end
end, "Additional.Init:Addon.Load.End")
