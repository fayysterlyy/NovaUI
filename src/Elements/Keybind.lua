-- Nova UI - Keybind Element
-- Concat-build: require YOK. Ust scope Nova, Util, Theme, Anim hazir.
-- Uretir: Nova._AddKeybind(section, flag, opts)
-- opts = { Default=Enum.KeyCode.E veya "E", Mode="Toggle" (Always/Toggle/Hold), Callback=function(state), ChangedCallback }

Nova._AddKeybind = function(section, flag, opts)
	opts = opts or {}
	local title = opts.Text or "Keybind"
	local desc = opts.Desc or ""
	local callback = opts.Callback
	local changedCallback = opts.ChangedCallback

	local modeOrder = { "Always", "Toggle", "Hold" }
	local mode = opts.Mode or "Toggle"
	do
		local ok = false
		for _, m in ipairs(modeOrder) do
			if m == mode then
				ok = true
				break
			end
		end
		if not ok then
			mode = "Toggle"
		end
	end

	local card = section:AddElementCard(title, desc)
	Nova.Flags = Nova.Flags or {}

	local maid = Util.MaidNew()
	local listeners = {} -- state dinleyicileri (OnChanged)
	local clickListeners = {} -- OnClick: tusa basildiginda
	local hoverChange = 0.08
	local baseTrans = card.BackgroundTransparency
	local alive = true
	local UIS = game:GetService("UserInputService")

	local function fontR()
		if Util.GetFont then
			return Util.GetFont(false)
		end
		return Enum.Font.Gotham
	end
	local function fontB()
		if Util.GetFont then
			return Util.GetFont(true)
		end
		return Enum.Font.GothamBold
	end

	-- Key <-> isim donusumleri
	local function keyToName(key)
		if typeof(key) == "EnumItem" then
			local nm = key.Name
			if nm == "MouseButton1" then
				return "MB1"
			elseif nm == "MouseButton2" then
				return "MB2"
			elseif nm == "MouseButton3" then
				return "MB3"
			end
			return nm
		end
		return tostring(key)
	end

	local function nameToKey(name)
		if typeof(name) == "EnumItem" then
			return name
		end
		name = tostring(name)
		if name == "MB1" or name == "MouseButton1" then
			return Enum.UserInputType.MouseButton1
		elseif name == "MB2" or name == "MouseButton2" then
			return Enum.UserInputType.MouseButton2
		elseif name == "MB3" or name == "MouseButton3" then
			return Enum.UserInputType.MouseButton3
		end
		local ok, kc = pcall(function()
			return Enum.KeyCode[name]
		end)
		if ok and kc ~= nil and typeof(kc) == "EnumItem" then
			return kc
		end
		local ok2, ut = pcall(function()
			return Enum.UserInputType[name]
		end)
		if ok2 and ut ~= nil and typeof(ut) == "EnumItem" then
			return ut
		end
		return nil
	end

	local bound = nameToKey(opts.Default)
	if bound == nil then
		bound = Enum.KeyCode.E
	end
	local state = (mode == "Always")
	local picking = false

	-- Alt satir: sagda mode butonu + hap (otomatik genislik x 30)
	local row = Util.Create("Frame", {
		Name = "KeybindRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Parent = card,
	})

	local holder = Util.Create("Frame", {
		Name = "Holder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = row,
	})
	Util.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = holder,
	})

	local modeBtn = Util.Create("TextButton", {
		Name = "Mode",
		Text = mode,
		Font = fontR(),
		TextSize = 11,
		TextColor3 = Theme.Get("SubText"),
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Get("Background"),
		BackgroundTransparency = 0,
		Size = UDim2.fromOffset(56, 30),
		LayoutOrder = 1,
		Parent = holder,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = modeBtn })

	local hap = Util.Create("TextButton", {
		Name = "Hap",
		Text = keyToName(bound),
		Font = fontB(),
		TextSize = 13,
		TextColor3 = Theme.Get("Text"),
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Get("Background"),
		BackgroundTransparency = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 30),
		LayoutOrder = 2,
		Parent = holder,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = hap })
	Util.Create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = hap,
	})
	Util.Create("UIStroke", {
		Color = Theme.Get("ElementBorder"),
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = hap,
	})

	local obj = {}

	local function fireState()
		for _, fn in ipairs(listeners) do
			Util.SafeCallback(fn, state)
		end
		Util.SafeCallback(callback, state)
		if flag ~= nil and flag ~= "" then
			local rec = Nova.Flags[flag]
			if rec then
				rec.State = state
			end
		end
	end

	local function fireClick()
		for _, fn in ipairs(clickListeners) do
			Util.SafeCallback(fn, state)
		end
	end

	local function setState(v, silent)
		v = not not v
		local changed = (v ~= state)
		state = v
		if not silent and (changed or mode == "Always") then
			fireState()
		end
		if flag ~= nil and flag ~= "" then
			local rec = Nova.Flags[flag]
			if rec then
				rec.State = state
			end
		end
	end

	local function applyModeVisual()
		modeBtn.Text = mode
	end

	-- TEK global InputBegan/InputEnded: Nova._KeybindInput icinde (yoksa kur)
	Nova._KeybindRegistry = Nova._KeybindRegistry or {}
	if Nova._KeybindInput == nil then
		local okB, c1 = pcall(function()
			return UIS.InputBegan:Connect(function(input, _gpe)
				-- Yazarken klavye tuslarini yoksay
				local focused = nil
				pcall(function()
					focused = UIS:GetFocusedTextBox()
				end)
				local isKey = input.KeyCode ~= Enum.KeyCode.Unknown
				if focused ~= nil and isKey then
					return
				end
				for rec, _ in pairs(Nova._KeybindRegistry) do
					if rec ~= nil and rec._HandleBegan ~= nil then
						pcall(rec._HandleBegan, input)
					end
				end
			end)
		end)
		local okE, c2 = pcall(function()
			return UIS.InputEnded:Connect(function(input, _gpe)
				for rec, _ in pairs(Nova._KeybindRegistry) do
					if rec ~= nil and rec._HandleEnded ~= nil then
						pcall(rec._HandleEnded, input)
					end
				end
			end)
		end)
		if okB and okE then
			Nova._KeybindInput = { c1, c2 }
		end
	end

	local function matches(input)
		if bound == nil then
			return false
		end
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			return input.KeyCode == bound
		end
		return input.UserInputType == bound
	end

	obj._HandleBegan = function(input)
		if not alive then
			return
		end
		if picking then
			return
		end
		if not matches(input) then
			return
		end
		fireClick()
		if mode == "Always" then
			-- Sabit true, tiklamada tekrar bildir
			if not state then
				setState(true)
			else
				fireState()
			end
		elseif mode == "Toggle" then
			setState(not state)
		elseif mode == "Hold" then
			setState(true)
		end
	end

	obj._HandleEnded = function(input)
		if not alive then
			return
		end
		if picking then
			return
		end
		if mode ~= "Hold" then
			return
		end
		if not matches(input) then
			return
		end
		setState(false)
	end

	obj._IsPicking = function()
		return picking
	end

	local pickConn = nil
	local function stopPick()
		if pickConn ~= nil then
			pcall(function()
				pickConn:Disconnect()
			end)
			pickConn = nil
		end
		picking = false
		hap.Text = keyToName(bound)
	end

	local function startPick()
		if picking then
			stopPick()
			return
		end
		picking = true
		hap.Text = "..."
		if pickConn ~= nil then
			pcall(function()
				pickConn:Disconnect()
			end)
			pickConn = nil
		end
		-- Sonraki InputBegan key/mouse yakala (anlik, Esc iptal)
		local conn = nil
		conn = UIS.InputBegan:Connect(function(input, _gpe)
			if not picking or not alive then
				return
			end
			if input.KeyCode == Enum.KeyCode.Escape then
				stopPick()
				return
			end
			local nb = nil
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				nb = input.KeyCode
			elseif input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				nb = input.UserInputType
			else
				return
			end
			bound = nb
			stopPick()
			if mode == "Always" then
				setState(true)
			end
			Util.SafeCallback(changedCallback, keyToName(bound), mode)
			if flag ~= nil and flag ~= "" then
				local rec = Nova.Flags[flag]
				if rec then
					rec.CurrentValue = keyToName(bound)
				end
			end
		end)
		pickConn = conn
		maid:Give(conn)
	end

	-- Hap tiklama: picking baslat (down/up eslesmeli degil, direkt click)
	maid:Give(hap.MouseButton1Click:Connect(function()
		if alive then
			startPick()
		end
	end))

	local function cycleMode()
		local idx = 1
		for i, m in ipairs(modeOrder) do
			if m == mode then
				idx = i
				break
			end
		end
		idx = idx % #modeOrder + 1
		mode = modeOrder[idx]
		applyModeVisual()
		if mode == "Always" then
			setState(true)
		else
			setState(false)
		end
		Util.SafeCallback(changedCallback, keyToName(bound), mode)
		if flag ~= nil and flag ~= "" then
			local rec = Nova.Flags[flag]
			if rec then
				rec.Mode = mode
			end
		end
	end

	maid:Give(modeBtn.MouseButton1Click:Connect(function()
		if alive and not picking then
			cycleMode()
		end
	end))
	-- Karta sag tik ile de mode dongusu
	maid:Give(card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 and alive and not picking then
			cycleMode()
		end
	end))

	-- Kart hover 0.12 Quad
	maid:Give(card.MouseEnter:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = math.clamp(baseTrans - hoverChange, 0, 1) }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))
	maid:Give(card.MouseLeave:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = baseTrans }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))

	obj.GetState = function()
		return state
	end
	obj.Get = function()
		return keyToName(bound)
	end
	obj.Set = function(a, b, c)
		-- Set(key, mode) veya Set(obj, key, mode)
		local k, m
		if a == obj then
			k, m = b, c
		else
			k, m = a, b
		end
		if k ~= nil then
			local nb = nameToKey(k)
			if nb ~= nil then
				bound = nb
				hap.Text = keyToName(bound)
				Util.SafeCallback(changedCallback, keyToName(bound), mode)
			end
		end
		if m ~= nil then
			local ok = false
			for _, mm in ipairs(modeOrder) do
				if mm == m then
					ok = true
					break
				end
			end
			if ok then
				mode = m
				applyModeVisual()
			end
		end
		if mode == "Always" then
			setState(true, true)
		end
		if flag ~= nil and flag ~= "" then
			local rec = Nova.Flags[flag]
			if rec then
				rec.CurrentValue = keyToName(bound)
				rec.Mode = mode
			end
		end
	end
	obj.OnChanged = function(self, fn)
		if type(self) == "function" and fn == nil then
			fn = self
		end
		if type(fn) == "function" then
			table.insert(listeners, fn)
		end
		return obj
	end
	obj.OnClick = function(self, fn)
		if type(self) == "function" and fn == nil then
			fn = self
		end
		if type(fn) == "function" then
			table.insert(clickListeners, fn)
		end
		return obj
	end
	obj.Destroy = function()
		alive = false
		picking = false
		Nova._KeybindRegistry[obj] = nil
		maid:Cleanup()
		Anim.Cancel(card)
		if Nova.SearchIndex then
			Nova.SearchIndex[card] = nil
		end
		if card then
			card:Destroy()
		end
	end

	Nova._KeybindRegistry[obj] = true

	if flag ~= nil and flag ~= "" then
		Nova.Flags[flag] = {
			Type = "Keybind",
			CurrentValue = keyToName(bound),
			Mode = mode,
			State = state,
			Get = function()
				return keyToName(bound)
			end,
			GetState = function()
				return state
			end,
			Set = function(k, m)
				obj.Set(k, m)
			end,
		}
	end

	applyModeVisual()
	return obj
end
