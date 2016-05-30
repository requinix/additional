local addon, data = ...
local source = "currency"

data.Events:Invoke("Tracking.SourceRegistration", source, {
	Data = Inspect.Currency.Detail(Inspect.Currency.List()),
	DefaultColors = {
		Normal = { 0.66, 0.66, 0.66 },
		Goal = { 0.75, 0.5, 0.0 },
		Max = { 1.0, 0.0, 0.0 }
	},
	Description = "Currencies",
	IdField = "id",
	MaxIndex = "stackMax",
	NameIndex = "name",
	ValueFormat = "%d",
	ValueIndex = "stack"
})

Command.Event.Attach(Event.Currency, function(h, currencies)
	data.Events:Invoke("Tracking.SourceUpdate", source, Inspect.Currency.Detail(currencies))
end, "Additional.Tracking.Currency:Currency")
