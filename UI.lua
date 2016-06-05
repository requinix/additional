local addon, data = ...

local reusable = {}
local reusablestorage = {}

local path_outline = {
	{ xProportional = 0.0, yProportional = 0.0 },
	{ xProportional = 1.0, yProportional = 0.0 },
	{ xProportional = 1.0, yProportional = 1.0 },
	{ xProportional = 0.0, yProportional = 1.0 },
	{ xProportional = 0.0, yProportional = 0.0 }
}

data.UI = {}
ADDUI = data.UI

data.UI.Context = UI.CreateContext(addon.identifier)

data.UI.DarkenColor = function(color, factor)
	local t = {}
	local f = factor or 0.5
	t.r = color.r and color.r * f or nil
	t[1] = color[1] and color[1] * f or nil
	t.g = color.g and color.g * f or nil
	t[2] = color[2] and color[2] * f or nil
	t.b = color.b and color.b * f or nil
	t[3] = color[3] and color[3] * f or nil
	return t
end

data.UI.DrawOutline = function(target, color, width, interior)
	local path = path_outline
	local fill = interior and {
		type = "solid",
		r = interior.r or interior[1] or 0.0,
		g = interior.g or interior[2] or 0.0,
		b = interior.b or interior[3] or 0.0,
		a = interior.a or interior[4] or 0.0
	} or nil
	local stroke = {
		r = color.r or color[1] or color.color and (color.color.r or color.color[1]),
		g = color.g or color[2] or color.color and (color.color.g or color.color[2]),
		b = color.b or color[3] or color.color and (color.color.r or color.color[3]),
		a = color.a or color[4] or 1.0,
		cap = "square",
		thickness = width or 1.0
	}
	target:SetShape(path, fill, stroke)
end

data.UI.FillGradientLinear = function(target, direction, start, ...)
	local path = path_outline

	local fill = {
		type = "gradientLinear",
		color = { {
			r = start.r or start[1] or start.color and (start.color.r or start.color[1]),
			g = start.g or start[2] or start.color and (start.color.g or start.color[2]),
			b = start.b or start[3] or start.color and (start.color.b or start.color[3]),
			a = start.a or start[4] or 1.0,
			position = start.position or 0
		} },
		transform = nil
	}

	for i, v in ipairs({ ... }) do
		table.insert(fill.color, {
			r = v.r or v[1] or v.color and (v.color.r or v.color[1]) or fill.color[#fill.color].r,
			g = v.g or v[2] or v.color and (v.color.g or v.color[2]) or fill.color[#fill.color].g,
			b = v.b or v[3] or v.color and (v.color.b or v.color[3]) or fill.color[#fill.color].b,
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

data.UI.LightenColor = function(color, factor)
	local t = {}
	local f = factor and 1 - factor or 0.5
	t.r = color.r and 1 - ((1 - color.r) * f) or nil
	t[1] = color[1] and 1 - ((1 - color[1]) * f) or nil
	t.g = color.g and 1 - ((1 - color.g) * f) or nil
	t[2] = color[2] and 1 - ((1 - color[2]) * f) or nil
	t.b = color.b and 1 - ((1 - color.b) * f) or nil
	t[3] = color[3] and 1 - ((1 - color[3]) * f) or nil
	return t
end

data.UI.ReusableCreate = function(type, identifier, parent)
	local frame = reusable[identifier] and table.remove(reusable[identifier].frames)
	if frame then
		return frame
	end

	reusable[identifier] = reusable[identifier] or { frames = {}, counter = 1 }
	frame = UI.CreateFrame(type, identifier .. "#" .. reusable[identifier].counter, parent or data.UI.Context)
	reusablestorage[frame] = identifier

	reusable[identifier].counter = reusable[identifier].counter + 1

	return frame
end

data.UI.ReusableDestroy = function(frame)
	if frame.SetVisible then
		frame:SetVisible(false)
	end
	if reusablestorage[frame] then
		table.insert(reusable[reusablestorage[frame]].frames, frame)
		reusablestorage[frame] = nil
	end
end
