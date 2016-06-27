local addon, util = ...
local plugin = util.Plugin:Register("Testing", "FindAchievement")

plugin:RegisterCommand("find-achievement <name>", "Find an achievement", function(name)
	local key, achievement
	local lname = name:lower()
	local list = Inspect.Achievement.List()

	printf("Begin search: '%s'", name)
	util.Thread:Create(function(heartbeat)
		while(heartbeat()) do
			key = next(list, key)
			if not key then
				break
			end
			achievement = Inspect.Achievement.Detail(key)
			if achievement and achievement.name:lower():find(lname) then
				print(key, achievement.name, achievement.complete and "complete" or "incomplete")
			end
		end
		print("End search")
	end)
end)
