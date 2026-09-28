-- Init: Nova tablosu init + Section metod baglama + tema/unload. En son yuklenir.
-- Bagimlilik: Util, Theme, Anim (ust scope, concat-build; require YOK).

Nova = Nova or { Flags = {}, Toggles = {}, Options = {}, SearchIndex = {}, _KeybindInput = nil }
Nova.Flags = Nova.Flags or {}
Nova.SearchIndex = Nova.SearchIndex or {}
Nova._UnloadCallbacks = Nova._UnloadCallbacks or {}
Nova._Guis = Nova._Guis or {}
Nova.Version = "1.0.0"

Nova.Toggles = Nova.Flags
Nova.Options = Nova.Flags

do
	local SECTION_METHODS = {
		AddToggle = "_AddToggle",
		AddButton = "_AddButton",
		AddLabel = "_AddLabel",
		AddSlider = "_AddSlider",
		AddInput = "_AddInput",
		AddDropdown = "_AddDropdown",
		AddColorPicker = "_AddColorPicker",
		AddKeybind = "_AddKeybind",
	}

	function Nova._BindSection(section)
		if type(section) ~= "table" then
			return section
		end
		for methodName, implName in pairs(SECTION_METHODS) do
			if type(section[methodName]) ~= "function" then
				section[methodName] = function(self, ...)
					local impl = Nova[implName]
					if type(impl) ~= "function" then
						error("[NovaUI] " .. methodName .. " kullanilamiyor (" .. implName .. " yuklenmemis).", 2)
					end
					local first = ...
					if type(first) == "string" and Nova.Flags[first] ~= nil then
						warn("[NovaUI] flag '" .. first .. "' zaten kayitli, uzerine yaziliyor.")
					end
					return impl(self, ...)
				end
			end
		end
		return section
	end
end

function Nova.SetTheme(name)
	Theme.Apply(name)
end

function Nova.OnUnload(fn)
	if type(fn) == "function" then
		table.insert(Nova._UnloadCallbacks, fn)
	end
end

function Nova.Unload()
	for _, fn in ipairs(Nova._UnloadCallbacks) do
		pcall(fn)
	end
	table.clear(Nova._UnloadCallbacks)

	if type(Anim.CancelAll) == "function" then
		pcall(Anim.CancelAll)
	end

	for _, gui in ipairs(Nova._Guis) do
		pcall(function()
			gui:Destroy()
		end)
	end
	table.clear(Nova._Guis)

	local ok, parent = pcall(Util.GetParent)
	if ok and parent then
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("ScreenGui") and child.Name == "NovaUI" then
				pcall(function()
					child:Destroy()
				end)
			end
		end
	end

	if Nova._NotifyHolder then
		pcall(function()
			Nova._NotifyHolder:Destroy()
		end)
		Nova._NotifyHolder = nil
	end

	table.clear(Nova.Flags)
	table.clear(Nova.SearchIndex)
	Nova._KeybindInput = nil
	Nova._NotifyCount = 0
	Nova._NotifyCards = nil
	Nova._AutoSaveName = nil

	Nova._Unloaded = true
end

return Nova
