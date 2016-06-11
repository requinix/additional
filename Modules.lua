local addon, util = ...

--[=[

class module

	Disable()
	Disable a module

	Error(string message, mixed arg...)
	Display an error message, optionally formatted with string.format, prefixed by the module name
		Parameters
			string message - error message, or format string when used with additional arguments
			mixed arg...   - additional arguments to pass to string.format

	RegisterCache(function load, function save)
	Wrapper for Cache:Register(module name, load, save)

	RegisterCommand(string spec, string description, function callback)
	Wrapper for Commands:Register(module abbreviation, spec, description, callback)

	RegisterConfig(function load, function save)
	Wrapper for Config:Register(module name, load, save)

]=]

local function cmoduleDisable(self)
	if self.enabled then
		self.enabled = false
		util.Events:Invoke(self.name .. ".Disabled")
	end
end

local function cmoduleError(self, message, ...)
	util.Error("%s: " .. message, self.name, ...)
end

local function cmoduleRegisterCache(self, load, save)
	util.Cache:Register(self.name, load, save)
end

local function cmoduleRegisterCommand(self, spec, description, callback)
	util.Commands:Register(self.abbrev, spec, description, callback)
end

local function cmoduleRegisterConfig(self, load, save)
	util.Config:Register(self.name, load, save)
end

local class_module = { __index = {
	Disable = cmoduleDisable,
	Error = cmoduleError,
	RegisterCache = cmoduleRegisterCache,
	RegisterCommand = cmoduleRegisterCommand,
	RegisterConfig = cmoduleRegisterConfig
}}

--[=[

class util.Modules

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

local function modulesNamed(self, name)
	for k, v in pairs(self) do
		if v.name == name then
			return v
		end
	end
	return nil
end

local function modulesRegister(self, name, abbrev)
	self[name] = setmetatable({
		abbrev = abbrev,
		enabled = true,
		name = name
	}, class_module)
	return self[name]
end

util.Modules = setmetatable({}, { __index = {
	Named = modulesNamed,
	Register = modulesRegister
}})


