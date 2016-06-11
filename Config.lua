local addon, util = ...

--[=[

class util.Config

	void util.Config:Register(string module, function load, function save)
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

local function configRegister(self, module, load, save)
	local oldconfig
	local m = util.Modules:Named(module)
	util.Events:Register("Config.Load", function(h, config)
		util.Exception.try(function()
			oldconfig = config[module]
			load(config[module] or {})
		end):catch(function()
			m:Disable()
			m:Error("Error loading configuration; module disabled")
		end)
	end)
	util.Events:Register("Config.Save", function(h, config)
		config[module] = oldconfig
		if m.enabled then
			util.Exception.try(function()
				config[module] = save()
			end):catch(function()
				m:Error("Error saving configuration")
			end)
		end
	end)
end

AdditionalConfig = {}
util.Config = setmetatable({}, { __index = {
	Register = configRegister
}})

Command.Event.Attach(Event.Addon.SavedVariables.Load.End, function(h, identifier)
	if identifier == addon.identifier then
		util.Events:Invoke("Config.Load", AdditionalConfig)
	end
end, "Additional.Config:Addon.SavedVariables.Load.End")

Command.Event.Attach(Event.Addon.SavedVariables.Save.Begin, function(h, identifier)
	if identifier == addon.identifier then
		AdditionalConfig = {}
		util.Events:Invoke("Config.Save", AdditionalConfig)
	end
end, "Additional.Config:Addon.SavedVariables.Save.Begin")
