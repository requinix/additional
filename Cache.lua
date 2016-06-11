local addon, util = ...

--[=[

class util.Cache

	void util.Cache:Register(string module, function load, function save)
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

local function cacheRegister(self, module, load, save)
	local oldcache
	util.Events:Register("Cache.Load", function(h, cache)
		util.Exception.try(function()
			if not cache[module] then
				oldcache = nil
				load({}, {})
			elseif cache.Version ~= util.Data.Version then
				oldcache = { Static = cache[module].Static }
				load(cache[module].Static or {}, {}, true)
			else
				oldcache = cache[module]
				load(cache[module].Static or {}, cache[module].Versioned or {}, false)
			end
		end):catch(function()
			local m = util.Modules:Named(module)
			m:Disable()
			m:Error("Error loading cache data; module disabled")
		end)
	end)
	util.Events:Register("Cache.Save", function(h, cache)
		local m = util.Modules:Named(module)
		cache[module] = oldcache
		if m.enabled then
			util.Exception.try(function()
				local static, versioned = save()
				if static or versioned then
					cache[module] = { Static = static, Versioned = versioned }
				else
					cache[module] = nil
				end
			end):catch(function()
				m:Error("Error saving cache data")
			end)
		end
	end)
end

AdditionalCache = {}
util.Cache = setmetatable({}, { __index = {
	Register = cacheRegister
}})

Command.Event.Attach(Event.Addon.SavedVariables.Load.End, function(h, identifier)
	if identifier == addon.identifier then
		util.Events:Invoke("Cache.Load", AdditionalCache)
	end
end, "Additional.Cache:Addon.SavedVariables.Load.End")

Command.Event.Attach(Event.Addon.SavedVariables.Save.Begin, function(h, identifier)
	if identifier == addon.identifier then
		AdditionalCache = { Timestamp = os.date("!%FT%TZ"), Version = util.Data.Version }
		util.Events:Invoke("Cache.Save", AdditionalCache)
	end
end, "Additional.Cache:Addon.SavedVariables.Save.Begin")
