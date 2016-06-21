local addon, util = ...

--[=[

class util.Commands

	any util.Commands:Call(string abbrev, string command [, mixed arg [, string args... ] ])
	Call a registered command
		Parameters
			string abbrev  - module abbreviation
			string command - command
			mixed arg      - a table containing all arguments, or a string for the first argument
			string args... - additional arguments
		Returns
			any            - returns what the command itself returns, if anything
		Errors
			"Module not found: <abbrev>" if there are no commands registered for that module
			"Command not found: <command>" if there is no such command registered for that module

	table util.Commands.ParseArguments(string argument)
	Parse an argument string
		Parameters
			string argument - full argument as provided by Rift; does not include slash command
		Returns
			table           - table of parsed arguments; [0] is the full string, [1]+ are the individual arguments

	void util.Commands:Register(string abbrev, string spec, string description, function callback)
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

	void util.Commands:ShowHelp([string abbrev])
	Show help for all commands or commands for the given module
		Parameters
			string abbrev - restrict output to commands for the given module

]=]

local commandkeys = {}

local function commandCall(self, abbrev, command, ...)
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
end

local function commandParseArguments(argument)
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
end

local function commandRegister(self, abbrev, spec, description, callback)
	if not self[abbrev] then
		self[abbrev] = {}
		Command.Event.Attach(Command.Slash.Register("add." .. abbrev), function(h, argument)
			local argv = self.ParseArguments(argument)
			local command = table.remove(argv, 1)
			self:Call(abbrev, command, argv)
		end, "Additional.Init:/add." .. abbrev)

		commandkeys[#commandkeys + 1] = abbrev
		commandkeys[abbrev] = {}
		table.sort(commandkeys)
	end
	local command = spec:match("[^%s]+")
	if not self[abbrev][command] then
		self[abbrev][command] = { Callback = callback, Description = description, Spec = spec }
		table.insert(commandkeys[abbrev], command)
		table.sort(commandkeys[abbrev])
	end
end

local function commandShowHelp(self, abbrev)
	print("Commands:")
	for i, v in ipairs(commandkeys) do
		if not abbrev or self[v] == abbrev then
			for i2, v2 in ipairs(commandkeys[v]) do
				printf("/add.%s %s - %s", v, self[v][v2].Spec, self[v][v2].Description)
			end
		end
	end
end

util.Commands = setmetatable({}, { __index = {
	Call = commandCall,
	ParseArguments = commandParseArguments,
	Register = commandRegister,
	ShowHelp = commandShowHelp
}})

Command.Event.Attach(Command.Slash.Register("add"), function(h, arguments)
	local argv = util.Commands.ParseArguments(arguments)
	if #argv == 0 or #argv >= 1 and argv[1] == "help" then
		util.Commands:ShowHelp(argv[2])
	end
end, "Additional.Commands:/add")
