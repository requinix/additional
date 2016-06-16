local addon, util = ...

--[=[

Plugins.Disabled.Begin(string module, string plugin), Modules_module.Plugins_plugin.Disabled.Begin()
Signals a plugin is going to be disabled
	Parameters
		string module - plugin's module name
		string plugin - plugin name

Plugins.Disabled.End(string module, string plugin), Modules_module.Plugins_plugin.Disabled.End()
Signals a plugin has been disabled
	Parameters
		string module - plugin's module name
		string plugin - plugin name

Plugins.Enabled.Begin(string module, string plugin), Modules_module.Plugins_plugin.Enabled.Begin()
Signals a plugin is going to be enabled; abortable
	Parameters
		string module - plugin's module name
		string plugin - plugin name

Plugins.Enabled.End(string module, string plugin), Modules_module.Plugins_plugin.Enabled.End()
Signals a plugin has been enabled
	Parameters
		string module - plugin's module name
		string plugin - plugin name

class plugin

	Disable()
	Disable a plugin

	Enable()
	Enable a plugin

	void Error(string message, mixed arg...)
	Display an error message, optionally formatted with string.format, prefixed by the module and plugin names
		Parameters
			string message - error message, or format string when used with additional arguments
			mixed arg...   - additional arguments to pass to string.format

	void EventAttach(table event, function callback, string name)
	Wraps Command.Event.Attach when the plugin is enabled and Command.Event.Detach with the plugin is disabled

	module Module()
	Get the plugin's module
		Returns
			module - plugin module

	void OnDisable(function callback)
	Register a function for when this plugin becomes disabled
		Parameters
			function callback - callback

	void OnEnable(function callback)
	Register a function for when this plugin becomes enabled
		Parameters
			function callback - callback

	void RegisterEvent(string key, function callback)
	Wrapper for util.Events:Register that only executes if the plugin is enabled

]=]

local function cpluginDisable(self)
	if self.enabled then
		util.Events:Invoke("Module_" .. self.module.name .. ".Plugins_" .. self.name .. ".Disabled.Begin")
		util.Events:Invoke("Plugins.Disabled.Begin", self.module.name, self.name)
		self.enabled = false
		util.Events:Invoke("Plugins.Disabled.End", self.module.name, self.name)
		util.Events:Invoke("Module_" .. self.module.name .. ".Plugins_" .. self.name .. ".Enabled.Begin")
	end
end

local function cpluginEnable(self)
	if
		not self.enabled and
		util.Events:Invoke("Modules_" .. self.module.name .. ".Plugins_" .. self.name .. ".Enabled.Begin") and
		util.Events:Invoke("Plugins.Enabled.Begin", self.module.name, self.name)
	then
		self.enabled = true
		util.Events:Invoke("Plugins.Enabled.End", self.module.name, self.name)
		util.Events:Invoke("Modules_" .. self.module.name .. ".Plugins_" .. self.name .. ".Enabled.End")
	end
end

local function cpluginError(self, message, ...)
	util.Error("%s.%s: " .. message, self.module.name, self.name, ...)
end

local function cpluginEventAttach(self, event, callback, name)
	local fqname = self.module.name .. "." .. self.name .. ":" .. name
	self:OnEnable(function()
		Command.Event.Attach(event, callback, fqname)
	end)
	self:OnDisable(function()
		Command.Event.Detach(event, callback, fqname)
	end)
end

local function cpluginModule(self)
	return self.module
end

local function cpluginOnDisable(self, callback)
	util.Events:Register("Modules_" .. self.module.name .. ".Plugins_" .. self.name .. ".Disabled.End", callback)
end

local function cpluginOnEnable(self, callback)
	util.Events:Register("Modules_" .. self.module.name .. ".Plugins_" .. self.name .. ".Enabled.Begin", callback)
end

local function cpluginRegisterEvent(self, key, callback)
	util.Events:Register(key, function(...)
		if self.enabled then
			callback(...)
		end
	end)
end

local class_plugin = { __index = {
	Disable = cpluginDisable,
	Enable = cpluginEnable,
	Error = cpluginError,
	EventAttach = cpluginEventAttach,
	Module = cpluginModule,
	OnDisable = cpluginOnDisable,
	OnEnable = cpluginOnEnable,
	RegisterEvent = cpluginRegisterEvent
}}

--[=[

class util.Plugins

	int, int, int util.Plugins:Count([string module])
	Get a count of the number of registered, enabled, and disabled plugins, optionally filtered to a specific module
		Parameters
			string module - module name
		Returns
			int           - total number of plugins
			int           - number of enabled plugins
			int           - number of disabled plugins

	plugin[] util.Plugins:Module(string module)
	Get plugins for a module
		Parameters
			string module - module name
		Returns
			plugin[]      - plugins

	plugin util.Plugins:Named(string module, string name)
	Get a plugin entry by module and name
		Parameters
			string module - module name
			string name   - plugin name
		Returns
			plugin        - plugin

	plugin util.Plugins:Register(string module, string name)
	Register a module plugin
		Parameters
			string module - module name
			string name   - plugin name
		Returns
			plugin        - plugin

]=]

local function pluginsCount(self, module)
	local n, e, d = 0, 0, 0
	for k, v in pairs(self) do
		if not module or v.module.name == module then
			n = n + 1
			e = e + (v.enabled and 1 or 0)
			d = d + (v.enabled and 0 or 1)
		end
	end
	return n, e, d
end

local function pluginsModule(self, module)
	local t = {}
	for k, v in pairs(self) do
		if v.module.name == module then
			table.insert(t, v)
		end
	end
	return t
end

local function pluginsNamed(self, module, name)
	for k, v in pairs(self) do
		if v.module.name == module and v.name == name then
			return v
		end
	end
	return nil
end

local function pluginsRegister(self, module, name)
	local plugin = setmetatable({
		enabled = false,
		module = util.Modules:Named(module),
		name = name
	}, class_plugin)
	self[module .. ";" .. name] = plugin
	return plugin
end

util.Plugins = setmetatable({}, { __index = {
	Count = pluginsCount,
	Module = pluginsModule,
	Named = pluginsNamed,
	Register = pluginsRegister
}})

util.Events:Register("Modules.Enabled.End", function(h, module)
	for k, v in pairs(util.Plugins:Module(module)) do
		v:Enable()
	end
end)

util.Events:Register("Modules.Disabled.Begin", function(h, module)
	for k, v in pairs(util.Plugins:Module(module)) do
		v:Disable()
	end
end)
