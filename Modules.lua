local addon, util = ...

--[=[

Modules.Disabled.Begin(string module), Modules_module.Disabled.Begin()
Signals a module is going to be disabled
	Parameters
		string module - module name

Modules.Disabled.End(string module), Modules_module.Disabled.End()
Signals a module has been disabled
	Parameters
		string module - module name

Modules.Enabled.Begin(string module), Modules_module.Enabled.Begin()
Signals a module is going to be enabled; abortable
	Parameters
		string module - module name

Modules.Enabled.End(string module), Modules_module.Enabled.End()
Signals a module has been enabled
	Parameters
		string module - module name

class module

	void Disable()
	Disable a module

	void Enable()
	Enable a module

	void Error(string message, mixed arg...)
	Display an error message, optionally formatted with string.format, prefixed by the module name
		Parameters
			string message - error message, or format string when used with additional arguments
			mixed arg...   - additional arguments to pass to string.format

	void EventAttach(table event, function callback, string name)
	Wraps Command.Event.Attach when the module is enabled and Command.Event.Detach when the module is disabled

	void OnDisable(function callback)
	Register a function for when this module becomes disabled
		Parameters
			function callback - callback

	void OnEnable(function callback)
	Register a function for when this module becomes enabled
		Parameters
			function callback - callback

	void RegisterCache(function load, function save)
	Wrapper for Cache:Register(module name, load, save)

	void RegisterCommand(string spec, string description, function callback)
	Wrapper for Commands:Register(module abbreviation, spec, description, callback)

	void RegisterConfig(function load, function save)
	Wrapper for Config:Register(module name, load, save)

	void RegisterEvent(string key, function callback)
	Wrapper for util.Events:Register that only executes if the module is enabled

]=]

local function cmoduleDisable(self)
	if self.enabled then
		util.Events:Invoke("Modules_" .. self.name .. ".Disabled.Begin")
		util.Events:Invoke("Modules.Disabled.Begin", self.name)
		self.enabled = false
		util.Events:Invoke("Modules.Disabled.End", self.name)
		util.Events:Invoke("Modules_" .. self.name .. ".Disabled.End")
	end
end

local function cmoduleEnable(self)
	if not self.enabled and util.Events:Invoke("Modules_" .. self.name .. ".Enabled.Begin") and util.Events:Invoke("Modules.Enabled.Begin", self.name) then
		self.enabled = true
		util.Events:Invoke("Modules.Enabled.End", self.name)
		util.Events:Invoke("Modules_" .. self.name .. ".Enabled.End")
	end
end

local function cmoduleError(self, message, ...)
	util.Error("%s: " .. message, self.name, ...)
end

local function cmoduleEventAttach(self, event, callback, name)
	local fqname = self.name .. ":" .. name
	self:OnEnable(function()
		Command.Event.Attach(event, callback, fqname)
	end)
	self:OnDisable(function()
		Command.Event.Detach(event, callback, fqname)
	end)
end

local function cmoduleOnDisable(self, callback)
	util.Events:Register("Modules_" .. self.name .. ".Disabled.End", callback)
end

local function cmoduleOnEnable(self, callback)
	util.Events:Register("Modules_" .. self.name .. ".Enabled.Begin", callback)
end

local function cmoduleRegisterCache(self, load, save)
	util.Cache:Register(self.name, load, save)
end

local function cmoduleRegisterCommand(self, spec, description, callback)
	util.Commands:Register(self.abbrev, spec, description, function(...)
		if self.enabled then
			callback(...)
		else
			self:Error("Module is disabled")
		end
	end)
end

local function cmoduleRegisterConfig(self, load, save)
	util.Config:Register(self.name, load, save)
end

local function cmoduleRegisterEvent(self, key, callback)
	util.Events:Register(key, function(...)
		if self.enabled then
			callback(...)
		end
	end)
end

local class_module = { __index = {
	Disable = cmoduleDisable,
	Enable = cmoduleEnable,
	Error = cmoduleError,
	EventAttach = cmoduleEventAttach,
	OnDisable = cmoduleOnDisable,
	OnEnable = cmoduleOnEnable,
	RegisterCache = cmoduleRegisterCache,
	RegisterCommand = cmoduleRegisterCommand,
	RegisterConfig = cmoduleRegisterConfig,
	RegisterEvent = cmoduleRegisterEvent
}}

--[=[

class util.Modules

	int, int, int util.Modules:Count()
	Get a count of the number of registered, enabled, and disabled modules
		Returns
			int - total number of modules
			int - number of enabled modules
			int - number of disabled modules

	module util.Modules:Named(string name)
	Get a module entry by name
		Parameters
			string name - module name
		Returns
			module      - module

	module util.Modules:Register(string name, string abbrev)
	Register a module
		Parameters
			string name   - module name
			string abbrev - module abbreviation
		Returns
			module        - module

]=]

local function modulesCount(self)
	local n, e, d = 0, 0, 0
	for k, v in pairs(self) do
		n = n + 1
		e = e + (v.enabled and 1 or 0)
		d = d + (v.enabled and 0 or 1)
	end
	return n, e, d
end

local function modulesNamed(self, name)
	for k, v in pairs(self) do
		if v.name == name then
			return v
		end
	end
	return nil
end

local function modulesRegister(self, name, abbrev)
	local module = setmetatable({
		abbrev = abbrev,
		enabled = false,
		name = name
	}, class_module)
	self[name] = module
	return module
end

util.Modules = setmetatable({}, { __index = {
	Count = modulesCount,
	Named = modulesNamed,
	Register = modulesRegister
}})


