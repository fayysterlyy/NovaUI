-- Config: Nova.Flags uzerinden JSON kayit/yukleme (executor file API, sessiz fallback).
-- Bagimlilik: Nova (ust scope, concat-build; require YOK).

do
	local HttpService = game:GetService("HttpService")

	local function configPath(name)
		return "NovaUI/" .. tostring(game.GameId) .. "/" .. tostring(name) .. ".json"
	end

	local function ensureFolder(folder)
		if typeof(makefolder) ~= "function" then
			return
		end
		local exists = false
		if typeof(isfolder) == "function" then
			local ok, res = pcall(isfolder, folder)
			exists = ok and res == true
		end
		if not exists then
			pcall(makefolder, folder)
		end
	end

	local function getValue(entry)
		if type(entry.Get) == "function" then
			local ok, v = pcall(entry.Get)
			if ok then
				return v
			end
		end
		return entry.CurrentValue
	end

	local function packColor(color, transp)
		return {
			r = math.floor(color.R * 255 + 0.5),
			g = math.floor(color.G * 255 + 0.5),
			b = math.floor(color.B * 255 + 0.5),
			t = tonumber(transp) or 0,
		}
	end

	local function unpackColor(data)
		if type(data) ~= "table" then
			return nil
		end
		local r, g, b = tonumber(data.r), tonumber(data.g), tonumber(data.b)
		if not (r and g and b) then
			return nil
		end
		local t = tonumber(data.t) or 0
		return Color3.fromRGB(
			math.clamp(math.floor(r + 0.5), 0, 255),
			math.clamp(math.floor(g + 0.5), 0, 255),
			math.clamp(math.floor(b + 0.5), 0, 255)
		), math.clamp(t, 0, 1)
	end

	local function packFlag(entry)
		local t = entry.Type
		if t == "Toggle" then
			local v = getValue(entry)
			if v == nil then
				v = entry.CurrentValue
			end
			return { t = "Toggle", v = (v == true) }
		elseif t == "Slider" then
			local v = tonumber(getValue(entry))
			if v == nil then
				v = tonumber(entry.CurrentValue)
			end
			if v == nil then
				return nil
			end
			return { t = "Slider", v = v }
		elseif t == "Dropdown" then
			local v = getValue(entry)
			if v == nil then
				v = entry.CurrentOption
			end
			if type(v) == "string" then
				return { t = "Dropdown", v = v }
			elseif type(v) == "table" then
				local arr = {}
				for key, item in pairs(v) do
					if type(item) == "string" then
						arr[#arr + 1] = item
					elseif item == true and type(key) == "string" then
						arr[#arr + 1] = key
					end
				end
				return { t = "Dropdown", v = arr }
			end
			return nil
		elseif t == "ColorPicker" then
			local color = entry.Color
			if type(entry.Get) == "function" then
				local ok, v = pcall(entry.Get)
				if ok and typeof(v) == "Color3" then
					color = v
				end
			end
			if typeof(color) ~= "Color3" then
				return nil
			end
			return { t = "ColorPicker", v = packColor(color, entry.Transp) }
		elseif t == "Keybind" then
			local key = entry.Key
			if typeof(key) == "EnumItem" then
				key = key.Name
			elseif type(key) ~= "string" then
				local gv = getValue(entry)
				if typeof(gv) == "EnumItem" then
					key = gv.Name
				elseif type(gv) == "string" then
					key = gv
				end
			end
			if type(key) ~= "string" then
				return nil
			end
			return { t = "Keybind", v = { key = key, mode = entry.Mode } }
		elseif t == "Input" then
			local v = getValue(entry)
			if v == nil then
				v = entry.CurrentValue
			end
			if type(v) ~= "string" then
				return nil
			end
			return { t = "Input", v = v }
		end
		return nil
	end

	local function applyFlag(entry, saved)
		local set = entry.Set
		local t, v = saved.t, saved.v
		if t == "Toggle" then
			if type(v) == "boolean" then
				pcall(function() set(v) end)
			end
		elseif t == "Slider" then
			if type(v) == "number" then
				pcall(function() set(v) end)
			end
		elseif t == "Dropdown" then
			if type(v) == "string" or type(v) == "table" then
				pcall(function() set(v) end)
			end
		elseif t == "ColorPicker" then
			local color, transp = unpackColor(v)
			if color then
				if not pcall(function() set(color, transp) end) then
					pcall(function() set(color) end)
				end
			end
		elseif t == "Keybind" then
			if type(v) == "table" and type(v.key) == "string" then
				if not pcall(function() set(v.key, v.mode) end) then
					pcall(function() set(v.key) end)
				end
			elseif type(v) == "string" then
				pcall(function() set(v) end)
			end
		elseif t == "Input" then
			if type(v) == "string" then
				pcall(function() set(v) end)
			end
		end
	end

	function Nova.SaveConfig(name)
		if type(name) ~= "string" or name == "" then
			return
		end
		if typeof(writefile) ~= "function" then
			return
		end
		local data = {}
		for flag, entry in pairs(Nova.Flags) do
			if type(entry) == "table" and type(entry.Type) == "string" then
				local ok, packed = pcall(packFlag, entry)
				if ok and packed ~= nil then
					data[flag] = packed
				end
			end
		end
		local okJson, json = pcall(HttpService.JSONEncode, HttpService, data)
		if not (okJson and type(json) == "string") then
			return
		end
		pcall(function()
			ensureFolder("NovaUI")
			ensureFolder("NovaUI/" .. tostring(game.GameId))
			writefile(configPath(name), json)
		end)
	end

	function Nova.LoadConfig(name)
		if type(name) ~= "string" or name == "" then
			return
		end
		if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then
			return
		end
		local path = configPath(name)
		local exists = false
		pcall(function()
			exists = isfile(path)
		end)
		if not exists then
			return
		end
		local content
		local okRead = pcall(function()
			content = readfile(path)
		end)
		if not (okRead and type(content) == "string") then
			return
		end
		local okJson, data = pcall(HttpService.JSONDecode, HttpService, content)
		if not (okJson and type(data) == "table") then
			return
		end
		for flag, saved in pairs(data) do
			if type(saved) == "table" then
				local entry = Nova.Flags[flag]
				if type(entry) == "table" and entry.Type == saved.t and type(entry.Set) == "function" then
					task.spawn(applyFlag, entry, saved)
				end
			end
		end
	end

	function Nova.AttemptSave(name)
		if type(name) == "string" and name ~= "" then
			Nova._AutoSaveName = name
		end
		local target = Nova._AutoSaveName
		if type(target) ~= "string" or target == "" then
			return
		end
		Nova._SaveToken = (Nova._SaveToken or 0) + 1
		local token = Nova._SaveToken
		task.delay(1, function()
			if token == Nova._SaveToken then
				pcall(Nova.SaveConfig, target)
			end
		end)
	end

	-- Autosave kancasi: sonradan kaydolacak her flag'in Set'i sarmalanir.
	-- AttemptSave(name) ile silahlandirilmissa her degisiklik 1sn debounce ile kaydedilir.
	local function armAutosave(flags)
		if type(flags) ~= "table" then
			return
		end
		local mt = getmetatable(flags)
		if mt and mt.__NovaAutoSave then
			return
		end
		setmetatable(flags, {
			__NovaAutoSave = true,
			__newindex = function(t, k, v)
				if type(v) == "table" and type(v.Set) == "function" and not v._NovaAutoWrapped then
					local rawSet = v.Set
					v._NovaAutoWrapped = true
					v.Set = function(a, b, c)
						rawSet(a, b, c)
						Nova.AttemptSave()
					end
				end
				rawset(t, k, v)
			end,
		})
	end

	Nova.Flags = Nova.Flags or {}
	armAutosave(Nova.Flags)
end
