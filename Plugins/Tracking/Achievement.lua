local addon, util = ...
local plugin = util.Plugin:Register("Tracking", "Achievement")

local tracking = {}
local tracknext = {}

local source = {
	Data = {},
	Description = "Achievements",
	IconIndex = "icon",
	IdIndex = "id",
	MaxIndex = "count",
	NameIndex = "name",
	ValueFormat = "%d",
	ValueIndex = "countDone"
}

local function ProcessAchievements(list, all)
	local a = {}
	local detail
	for k, v in pairs(list) do
		detail = istable(v) and v or Inspect.Achievement.Detail(k)
		if all or tracking[k] or detail.previous and tracking[detail.previous] then
			if detail.requirement and #detail.requirement == 1 and detail.requirement[1].count then
				a[k] = {
					complete = detail.complete,
					count = detail.requirement[1].count,
					countDone = detail.requirement[1].countDone or detail.requirement[1].count,
					icon = detail.icon,
					id = k,
					name = detail.name
				}
				if detail.previous then
					tracknext[detail.previous] = k
				end

				if detail.complete and tracknext[k] then
					plugin:Module().Untrack(k)
					plugin:Module().Track("achievement", tracknext[k])
					a[k] = nil
					tracking[k] = nil
				elseif detail.previous and tracking[detail.previous] and tracking[detail.previous].complete then
					plugin:Module().Untrack(detail.previous)
					plugin:Module().Track("achievement", k)
					a[detail.previous] = nil
					tracking[detail.previous] = nil
				end
			end
		end
	end
	return a
end

function source.Load(key)
	local p = ProcessAchievements({ [key] = true }, true)
	if p[key] then
		tracking[key] = p[key]
		util.Event:Invoke("Tracking.SourceUpdate", "achievement", { [key] = p[key] })
		return key
	else
		return nil
	end
end

plugin:EventAttach(Event.Achievement.Update, function(h, achievements)
	util.Event:Invoke("Tracking.SourceUpdate", "achievement", ProcessAchievements(achievements))
end, "Tracking.Achievement:Achievement.Update")

plugin:OnEnable(function()
	util.Event:Invoke("Tracking.SourceRegistration", "achievement", source)
end)
