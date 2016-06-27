local addon, util = ...
local plugin = util.Plugin:Register("Testing", "Overlay")

local overlay = UI.CreateFrame("Frame", "Testing.Overlay.overlay", util.UI.Context)
overlay:SetBackgroundColor(1.0, 1.0, 1.0, 0.5)
overlay:SetVisible(false)

local overlaytext = UI.CreateFrame("Text", "Testing.Overlay.text", overlay)
overlaytext:SetFontColor(1.0, 1.0, 1.0, 1.0)
overlaytext:SetFontSize(18)
overlaytext:SetEffectGlow({ strength = 3 })
overlaytext:SetPoint("CENTER", overlay, "CENTER")

local export

plugin:RegisterCommand("overlay-copy <element>", "Create an overlay of an element", function(element)
	local e = assert(loadstring("return " .. element))()
	if not e then
		plugin:Error("Invalid element")
		return
	end

	overlay:SetAllPoints(e)
	overlay:SetVisible(true)
end)

plugin:RegisterCommand("overlay-export <variable>", "Export the overlay to a global variable", function(variable)
	if export then
		_G[export] = nil
	end

	export = variable
	_G[variable] = overlay
end)

plugin:RegisterCommand("overlay-remove", "Remove the overlay", function()
	overlay:SetVisible(false)
end)

overlay:EventAttach(Event.UI.Layout.Move, function(h)
	if h == overlay then
		local left, top, right, bottom = overlay:GetBounds()
		overlaytext:SetText(string.format("(%d, %d) - (%d, %d)", left, top, right, bottom))
	end
end, "Testing.Overlay:UI.Layout.Move")

overlay:EventAttach(Event.UI.Layout.Size, function(h)
	if h == overlay then
		local left, top, right, bottom = overlay:GetBounds()
		overlaytext:SetText(string.format("(%d, %d) - (%d, %d)", left, top, right, bottom))
	end
end, "Testing.Overlay:UI.Layout.Size")
