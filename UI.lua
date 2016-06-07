local addon, util = ...

local reusable = {}
local reusablestorage = {}

local path_outline = {
	{ xProportional = 0.0, yProportional = 0.0 },
	{ xProportional = 1.0, yProportional = 0.0 },
	{ xProportional = 1.0, yProportional = 1.0 },
	{ xProportional = 0.0, yProportional = 1.0 },
	{ xProportional = 0.0, yProportional = 0.0 }
}

util.UI = {}

util.UI.Context = UI.CreateContext(addon.identifier)

--[=[
	rgba BlendColor(rgba color1, rgba color2, number ratio)
	Blend two colors together

	Parameters
		rgba color1  - first RGBA color table
		rgba color2  - second RGBA color table
		number ratio - mixture ratio; 0.0 = fully color1, 0.5 = blend, 1.0 = fully color2 (default 0.5)

	Returns
		rgba         - RGBA color table using the same keys as color1 and including extra keys from color2
]=]
function util.UI.BlendColors(color1, color2, ratio)
	local blend = { "r", "g", "b", "a", r = 1, g = 2, b = 3, a = 4 }
	local t = {}
	for k, v in pairs(color1) do
		if blend[k] and color2[k] then
			t[k] = v + ratio * (color2[k] - v)
		elseif blend[k] and color2[blend[k]] then
			t[k] = v + ratio * (color2[blend[k]] - v)
		else
			t[k] = v
		end
	end
	for k, v in pairs(color2) do
		if not t[k] and not (blend[k] and t[blend[k]]) then
			t[k] = v
		end
	end
	return t
end

--[=[
	rgb DarkenColor(rgb color [, percent factor ])
	Darken a color by moving each component factor% towards black

	component = component - (component * factor)

	Parameters
		rgb color      - RGB color table, extra keys preserved
		percent factor - percentage to move towards black; 0.0 = unchanged, 1.0 = black (default 0.33)

	Returns
		rgb            - RGB color table using the same keys as the original table
]=]
function util.UI.DarkenColor(color, factor)
	local alter = { 1, 1, 1, r = 1, g = 1, b = 1 }
	local f = factor and (1 - factor) or 0.67

	local t = {}
	for k, v in pairs(color) do
		t[k] = alter[k] and v * f or v
	end
	return t
end

--[=[
	DrawOutline(canvas target [, rgba color [, number width [, rgba interior ] ] ])
	Draw an outline around a rectangular canvas

	Parameters
		canvas target - canvas to draw on
		rgba color    - RGBA color table (default black opaque)
		number width  - width of outline (default 1.0)
		rgba interior - RGBA color table (default black transparency)
]=]
function util.UI.DrawOutline(target, color, width, interior)
	local path = path_outline
	local fill = interior and {
		type = "solid",
		r = interior.r or interior[1] or 0.0,
		g = interior.g or interior[2] or 0.0,
		b = interior.b or interior[3] or 0.0,
		a = interior.a or interior[4] or 0.0
	} or nil
	local stroke = {
		r = color.r or color[1],
		g = color.g or color[2],
		b = color.b or color[3],
		a = color.a or color[4] or 1.0,
		cap = "square",
		thickness = width or 1.0
	}
	target:SetShape(path, fill, stroke)
end

--[=[
	FillGradientLinear(canvas target, table direction, table start, [ table position... ])
	Fill a rectangular canvas with a linear gradient fill

	direction can be indicated as:
	- a vector (table with x,y keys)

	Parameters
		canvas target     - canvas to draw on
		table direction   - direction of gradient
		table start       - rgba color table with optional alpha (default opaque) and position (default 0)
		table position... - rgba color tables with optional alpha (default previous alpha) and position (default previous position + 1)
]=]
function util.UI.FillGradientLinear(target, direction, start, ...)
	local path = path_outline

	local fill = {
		type = "gradientLinear",
		color = { {
			r = start.r or start[1],
			g = start.g or start[2],
			b = start.b or start[3],
			a = start.a or start[4] or 1.0,
			position = start.position or 0
		} },
		transform = nil
	}

	for i, v in ipairs({ ... }) do
		table.insert(fill.color, {
			r = v.r or v[1] or fill.color[#fill.color].r,
			g = v.g or v[2] or fill.color[#fill.color].g,
			b = v.b or v[3] or fill.color[#fill.color].b,
			a = v.a or v[4] or fill.color[#fill.color].a,
			position = v.position or fill.color[#fill.color].position + 1
		})
	end

	local w, h = target:GetWidth(), target:GetHeight()
	local neww, newh = w, h
	local rotation = 0.0
	local translatex, translatey = 0.0, 0.0

	if direction.x and direction.y then
		-- vector notation
		local sx, sy = (direction.x >= 0 and 1 or -1), (direction.y >= 0 and 1 or -1)
		rotation = math.atan2(direction.y, direction.x)
		neww = w * sx * math.cos(rotation) + h * sy * math.sin(rotation)
		newh = w * sx * math.sin(rotation) + h * sy * math.cos(rotation)

		if direction.x >= 0 and direction.y >= 0 then
			-- first quadrant, diameter is [0, w], starting rotation = 0
			translatex = w * (1 - math.cos(2 * rotation)) / 2
			translatey = w * -math.sin(2 * rotation) / 2
		elseif direction.x <=0 and direction.y >= 0 then
			-- second quadrant, diameter is [0, h], starting rotation = pi/2
			translatex = w - h * math.cos(2 * rotation - 0.5 * math.pi) / 2
			translatey = h * (1 - math.sin(2 * rotation - 0.5 * math.pi)) / 2
		elseif direction.x <= 0 and direction.y <= 0 then
			-- third quadrant, diameter is [w, 0], starting rotation = pi
			translatex = w * (1 - math.cos(2 * rotation - math.pi)) / 2
			translatey = h - w * math.sin(2 * rotation - math.pi) / 2
		else -- direction.x >= 0 and direction.y <= 0
			-- fourth quadrant, diameter is [h, 0], starting rotation = 3pi/2
			translatex = h * -math.cos(2 * rotation - 3 * math.pi / 2) / 2
			translatey = h * (1 - math.sin(2 * rotation - 3 * math.pi / 2)) / 2
		end

	end
	fill.transform = Utility.Matrix.Create(neww / 100, newh / 100, rotation, translatex, translatey)

	target:SetShape(path, fill, nil)
end

--[=[
	rgb LightenColor(rgb color [, percent factor ])
	Lighten a color by moving each component factor% closer to white

	component = component + factor * (1 - component)

	Parameters
		rgb color      - RGB color table, extra keys preserved
		percent factor - percentage to move closer to white; 0.0 = unchanged, 1.0 = white (default 0.33)

	Returns
		rgb            - RGB color table using the same keys as the original table
]=]
function util.UI.LightenColor(color, factor)
	local alter = { 1, 1, 1, r = 1, g = 1, b = 1 }
	local f = factor or 0.33

	local t = {}
	for k, v in pairs(color) do
		t[k] = alter[k] and v + f * (1 - v) or v
	end
	return t
end
