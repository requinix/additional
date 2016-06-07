local addon, util = ...

--- GLOBAL FUNCTIONS ---

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

--- DATA HELPERS ---

AdditionalCache = {}
util.Cache = {}
setmetatable(util.Cache, { __index = {
	--[=[
		Cache:Register(string module, function load, function save)
		Register a module with the cache manager; saved data is global

		Parameters
			string module - module name
			function load - cache load callback
				Parameters
					table static    - static cache data
					table versioned - versioned cache data; will be {} after a version change
			function save - cache save callback
				Returns
					table - static cache data
					table - versioned cache data
	]=]
	Register = function(self, module, load, save)
		util.Events:Register("Cache.Load", function(h, cache)
			if not cache[module] then
				load({}, {})
			elseif cache.Version ~= util.Data.Version then
				load(cache[module].Static or {}, {}, true)
			else
				load(cache[module].Static or {}, cache[module].Versioned or {}, false)
			end
		end)
		util.Events:Register("Cache.Save", function(h, cache)
			local static, versioned = save()
			if static or versioned then
				cache[module] = { Static = static, Versioned = versioned }
			end
		end)
	end
}})

util.Commands = {}
setmetatable(util.Commands, { __index = {
	--[=[
		any Commands:Call(string abbrev, string command [, mixed arg [, string args... ] ])
		Call a registered command

		Parameters
			string abbrev  - module abbreviation
			string command - command
			mixed arg      - a table containing all arguments, or a string for the first argument
			string args... - additional arguments

		Returns
			any            - returns what the command itself returns, if anything

		Errors
			- "Module not found: <abbrev>" if there are no commands registered for that module
			- "Command not found: <command>" if there is no such command registered for that module
	]=]
	Call = function(self, abbrev, command, ...)
		local first = (...)
		if not self[abbrev] then
			Command.Console.Display("general", false, "<font color=\"#FF0000\">Module not found: " .. abbrev .. "</font>", true)
		elseif not self[abbrev][command] then
			Command.Console.Display("general", false, "<font color=\"#FF0000\">Command not found: " .. command .. "</font>", true)
		elseif istable(first) then
			return self[abbrev][command].Callback(unpack(first))
		else
			return self[abbrev][command].Callback(...)
		end
	end,
	--[=[
		table Commands.ParseArguments(string argument)
		Parse an argument string

		Parameters
			string argument - full argument as provided by Rift; does not include slash command

		Returns
			table           - table of parsed arguments; [0] is the full string, [1]+ are the individual arguments
	]=]
	ParseArguments = function(argument)
		local t = { [0] = argument }
		local pos = 1
		for term, qterm, p in argument:gmatch("%s*([^\"]*)\"([^\"]*)\"()") do
			for w in term:gmatch("[^%s]+") do
				table.insert(t, w)
			end
			table.insert(t, (qterm:gsub("\\\"", "\"")))
			pos = p
		end
		for term in argument:sub(pos):gmatch("%s*([^%s]+)") do
			table.insert(t, term)
		end
		return t
	end,
	--[=[
		Commands:Register(string abbrev, string spec, string description, function callback)
		Register a slash command for a module

		Parameters
			string abbrev      - module abbreviation
			string spec        - string whose first word is used as the command; shown with the help command
			string description - shown with the help command
			function callback  - callback to handle the event
				Parameters
					mixed args... - any arguments that were given and as parsed by Commands.ParseArgument
				Return
					any           - any value to return through Commands.Call; meaningless for regular in-game slash commands
	]=]
	Register = function(self, abbrev, spec, description, callback)
		if not self[abbrev] then
			self[abbrev] = {}
			Command.Event.Attach(Command.Slash.Register("add." .. abbrev), function(h, argument)
				local argv = self.ParseArguments(argument)
				local command = table.remove(argv, 1)
				self:Call(abbrev, command, argv)
			end, "Additional.Init:/add." .. abbrev)
		end
		local command = spec:match("[^%s]+")
		if not self[abbrev][command] then
			self[abbrev][command] = { Callback = callback, Description = description, Spec = spec }
		end
	end,
	--[=[
		Commands:ShowHelp([string abbrev])
		Show help for all commands or commands for the given module

		Parameters
			string abbrev - restrict output to commands for the given module
	]=]
	ShowHelp = function(self, abbrev)
		for k, v in pairs(self) do
			if not abbrev or k == abbrev then
				for command, info in pairs(v) do
					printf("/add.%s %s - %s", k, info.Spec, info.Description)
				end
			end
		end
	end
}})

AdditionalConfig = {}
util.Config = {}
setmetatable(util.Config, { __index = {
	--[=[
		Config:Register(string module, function load, function save)
		Register a module with the configuration manager; saved data is per-account

		Parameters
			string module - module name
			function load - config load callback
				Parameters
					table config - configuration data
			function save - config save callback
				Returns
					table - configuration data
	]=]
	Register = function(self, module, load, save)
		util.Events:Register("Config.Load", function(h, config)
			load(config[module] or {})
		end)
		util.Events:Register("Config.Save", function(h, config)
			config[module] = save()
		end)
	end
}})

util.Events = {}
setmetatable(util.Events, { __index = {
	--[=[
		Events.AttachWhile(table event, function callback, string name)
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
	]=]
	AttachWhile = function(event, callback, name)
		local handler
		handler = function(...)
			if not callback(...) then
				Command.Event.Detach(event, handler, name .. "<While>")
			end
		end
		Command.Event.Attach(event, handler, name .. "<While>")
	end,
	--[=[
		Events:Invoke(string key [, any ])
		Invoke an event, wrapping the function returned by Utility.Event.Create

		Parameters
			string key - event name
			any        - event arguments, passed to registered listeners after the event handle
	]=]
	Invoke = function(self, key, ...)
		if self[key] then
			self[key].Invoke(...)
		end
	end,
	--[=[
		Events:Register(string key, function callback)
		Register an event listener, wrapping Utility.Event.Create and Command.Event.Attach

		Parameters
			string key        - event name
			function callback - event handler
				Parameters
					table h - event handle
					any     - event parameters
	]=]
	Register = function(self, key, callback)
		if not self[key] then
			self[key] = { Count = 0 }
			self[key].Invoke, self[key].Handle = Utility.Event.Create(addon.identifier, key)
		end
		self[key].Count = self[key].Count + 1
		Command.Event.Attach(self[key].Handle, callback, string.format("%s.Event.%s:%d", addon.identifier, key, self[key].Count))
	end
}})

util.Modules = {}
local modulesmt = { __index = {
	--[=[
		module:Error(string message)
		Display an error message, prefixed by the module name

		Parameters
			string message - error message
	]=]
	Error = function(self, message)
		Command.Console.Display("general", false, "<font color=\"#FF0000\">" .. self.name .. ": " .. message .. "</font>", true)
	end,
	--[=[
		module:RegisterCache(function load, function save)
		Wrapper for Cache:Register(module name, load, save)
	]=]
	RegisterCache = function(self, load, save)
		util.Cache:Register(self.name, load, save)
	end,
	--[=[
		module:RegisterCommand(string spec, string description, function callback)
		Wrapper for Commands:Register(module abbreviation, spec, description, callback)
	--]=]
	RegisterCommand = function(self, spec, description, callback)
		util.Commands:Register(self.abbrev, spec, description, callback)
	end,
	--[=[
		module:RegisterConfig(function load, function save)
		Wrapper for Config:Register(module name, load, save)
	]=]
	RegisterConfig = function(self, load, save)
		util.Config:Register(self.name, load, save)
	end
}}
setmetatable(util.Modules, { __index = {
	--[=[
		table Modules:Named(string name)
		Get a module entry by name

		Parameters
			string name - module name

		Returns
			table       - module table
	]=]
	Named = function(self, name)
		for k, v in pairs(self) do
			if v.name == name then
				return v
			end
		end
		return nil
	end,
	--[=[
		table Modules:Register(string name, string abbrev)
		Register a module

		Parameters
			string name   - module name
			string abbrev - module abbreviation

		Returns
			table         - module table
	]=]
	Register = function(self, name, abbrev)
		self[abbrev] = {
			abbrev = abbrev,
			name = name
		}
		return setmetatable(self[abbrev], modulesmt)
	end
}})

--- EVENT REGISTRATION ---

Command.Event.Attach(Command.Slash.Register("add"), function(h, arguments)
	local argv = util.Commands.ParseArguments(arguments)
	if #argv == 0 or #argv >= 1 and argv[1] == "help" then
		util.Commands:ShowHelp(argv[2])
	end
end, "Additional.Init:/add")

Command.Event.Attach(Event.Addon.Load.End, function(h, identifier)
	if identifier == addon.identifier then
		print(addon.name .. " v" .. addon.toc.Version .. " loaded.")
	end
end, "Additional.Init:Addon.Load.End")

Command.Event.Attach(Event.Addon.SavedVariables.Load.End, function(h, identifier)
	if identifier == addon.identifier then
		util.Events:Invoke("Cache.Load", AdditionalCache)
		util.Events:Invoke("Config.Load", AdditionalConfig)
	end
end, "Additional.Init:Addon.SavedVariables.Load.End")

Command.Event.Attach(Event.Addon.SavedVariables.Save.Begin, function(h, identifier)
	if identifier == addon.identifier then
		AdditionalCache = { Version = util.Data.Version }
		util.Events:Invoke("Cache.Save", AdditionalCache)
		AdditionalConfig = {}
		util.Events:Invoke("Config.Save", AdditionalConfig)
	end
end, "Additional.Init:Addon.SavedVariables.Save.Begin")
