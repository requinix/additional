local addon, data = ...

local reusable = {}
local reusablestorage = {}

data.UI = {}

data.UI.Context = UI.CreateContext(addon.identifier)

data.UI.FillGradientLinear = function(target, direction, start, ...)
	local path = {
		{ xProportional = 0.0, yProportional = 0.0 },
		{ xProportional = 1.0, yProportional = 0.0 },
		{ xProportional = 1.0, yProportional = 1.0 },
		{ xProportional = 0.0, yProportional = 1.0 },
		{ xProportional = 0.0, yProportional = 0.0 }
	}
	local fill = {
		type = "gradientLinear",
		color = {
			{ r = start.r, g = start.g, b = start.b, position = start.position or 0 }
		},
		transform = nil
	}

	for i, v in ipairs({ ... }) do
		table.insert(fill.color, {
			r = v.r or fill.color[#fill.color].r,
			g = v.g or fill.color[#fill.color].g,
			b = v.b or fill.color[#fill.color].b,
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
		local newr, newrotation = math.sqrt(neww * neww + newh * newh) / 2, rotation + math.atan2(h, w)
		translatex = w / 2 - newr * math.cos(newrotation)
		translatey = h / 2 - newr * math.sin(newrotation)
	end
	fill.transform = Utility.Matrix.Create(neww / 100, newh / 100, rotation, translatex, translatey)

	target:SetShape(path, fill, nil)
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
