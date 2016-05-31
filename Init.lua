local addon, data = ...

--- GLOBAL FUNCTIONS ---

hexcolor2table = hexcolor2table or function(h)
	return { math.floor(h / 65536) / 255, math.fmod(math.floor(h / 256), 256) / 255, math.fmod(h, 256) / 255 }
end

isnumber = isnumber or function(v)
	return type(v) == "number"
end

isstring = isstring or function(v)
	return type(v) == "string"
end

istable = istable or function(v)
	return type(v) == "table"
end

printf = printf or function(...)
	print(string.format(...))
end

--- DATA HELPERS ---

AdditionalCache = {}
data.Cache = {}
setmetatable(data.Cache, { __index = {
	Register = function(self, module, load, save)
		data.Events:Register("Cache.Load", function(h, cache)
			if not cache[module] then
				load({}, {})
			elseif cache.Version ~= data.VERSION then
				load(cache[module].Static or {}, {}, true)
			else
				load(cache[module].Static or {}, cache[module].Versioned or {}, false)
			end
		end)
		data.Events:Register("Cache.Save", function(h, cache)
			local static, versioned = save()
			if static or versioned then
				cache[module] = { Static = static, Versioned = versioned }
			end
		end)
	end
}})

data.Commands = {}
setmetatable(data.Commands, { __index = {
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
	ParseArguments = function(argument)
		local t = {}
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
	Register = function(self, abbrev, spec, description, callback)
		if not self[abbrev] then
			self[abbrev] = {}
			Command.Event.Attach(Command.Slash.Register("add." .. abbrev), function(h, argument)
				local argv = self.ParseArguments(argument)
				local command = table.remove(argv, 1)
				self:Call(abbrev, command, argv)
			end, "Additional.Init:/add. " .. abbrev)
		end
		local command = spec:match("[^%s]+")
		if not self[abbrev][command] then
			self[abbrev][command] = { Callback = callback, Description = description, Spec = spec }
		end
	end,
	ShowHelp = function(self, module)
		for abbrev, commands in pairs(self) do
			if not module or abbrev == module then
				for command, info in pairs(commands) do
					printf("/add.%s %s - %s", abbrev, info.Spec, info.Description)
				end
			end
		end
	end
}})

AdditionalConfig = {}
data.Config = {}
setmetatable(data.Config, { __index = {
	Register = function(self, module, load, save)
		data.Events:Register("Config.Load", function(h, config)
			load(config[module] or {})
		end)
		data.Events:Register("Config.Save", function(h, config)
			config[module] = save()
		end)
	end
}})

data.Events = {}
setmetatable(data.Events, { __index = {
	AttachWhile = function(event, callback, name)
		local handler
		handler = function(...)
			if not callback(...) then
				Command.Event.Detach(event, handler, name .. "<While>")
			end
		end
		return Command.Event.Attach(event, handler, name .. "<While>")
	end,
	Invoke = function(self, key, ...)
		if self[key] then
			self[key].Invoke(...)
		end
	end,
	Register = function(self, key, callback)
		if not self[key] then
			self[key] = { Count = 0 }
			self[key].Invoke, self[key].Handle = Utility.Event.Create(addon.identifier, key)
		end
		self[key].Count = self[key].Count + 1
		Command.Event.Attach(self[key].Handle, callback, string.format("%s.Event.%s:%d", addon.identifier, key, self[key].Count))
	end
}})

data.Modules = {}
local modulesmt = { __index = {
	Error = function(self, message)
		Command.Console.Display("general", false, "<font color=\"#FF0000\">" .. self.name .. ": " .. message .. "</font>", true)
	end,
	RegisterCache = function(self, load, save)
		data.Cache:Register(self.name, load, save)
	end,
	RegisterCommand = function(self, spec, description, callback)
		data.Commands:Register(self.abbrev, spec, description, callback)
	end,
	RegisterConfig = function(self, load, save)
		data.Config:Register(self.name, load, save)
	end
}}
setmetatable(data.Modules, { __index = {
	Register = function(self, name, abbrev)
		self[abbrev] = {
			abbrev = abbrev,
			name = name
		}
		return setmetatable(self[abbrev], modulesmt)
	end
}})

-- DATA INITIALIZATION ---

data.UIContext = UI.CreateContext(addon.identifier)

--- EVENT REGISTRATION ---

Command.Event.Attach(Command.Slash.Register("add"), function(h, arguments)
	local argv = data.Commands.ParseArguments(arguments)
	if #argv == 0 or #argv >= 1 and argv[1] == "help" then
		data.Commands:ShowHelp(argv[2])
	end
end, "Additional.Init:/add")

Command.Event.Attach(Event.Addon.Load.End, function(h, identifier)
	if identifier == addon.identifier then
		print(addon.name .. " v" .. addon.toc.Version .. " loaded.")
	end
end, "Additional.Init:Addon.Load.End")

Command.Event.Attach(Event.Addon.SavedVariables.Load.End, function(h, identifier)
	if identifier == addon.identifier then
		data.Events:Invoke("Cache.Load", AdditionalCache)
		data.Events:Invoke("Config.Load", AdditionalConfig)
	end
end, "Additional.Init:Addon.SavedVariables.Load.End")

Command.Event.Attach(Event.Addon.SavedVariables.Save.Begin, function(h, identifier)
	if identifier == addon.identifier then
		AdditionalCache = { Version = data.VERSION }
		data.Events:Invoke("Cache.Save", AdditionalCache)
		AdditionalConfig = {}
		data.Events:Invoke("Config.Save", AdditionalConfig)
	end
end, "Additional.Init:Addon.SavedVariables.Save.Begin")
