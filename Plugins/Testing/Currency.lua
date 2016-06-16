local addon, util = ...
local plugin = util.Plugins:Register("Testing", "Currency")

plugin:Module():RegisterCommand("find-currency <name>", "Find a currency on the player", function(name)
	local lname = name:lower()
	if lname == "coin" then
		dump(Inspect.Currency.Detail("coin"))
		return
	end

	for k, v in pairs(Inspect.Currency.Detail(Inspect.Currency.List())) do
		if v.name:lower() == lname then
			dump(v)
		end
	end
end)
