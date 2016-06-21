local addon, util = ...
local plugin = util.Plugins:Register("Testing", "DumpKeys")

plugin:RegisterCommand("dumpkeys <value>", "Dump keys from a table", function(arg)
	local value = assert(loadstring("return " .. arg))()
	if not value then
		plugin:Error("Invalid value")
		return
	elseif not istable(value) then
		plugin:Error("Value is a " .. type(value))
		return
	end

	local keys = {}
	for k in pairs(value) do
		table.insert(keys, k)
	end
	table.sort(keys)
	dump(keys)
end)
