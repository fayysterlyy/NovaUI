-- Nova UI - Input Element
-- Concat-build: require YOK. Ust scope Nova, Util, Theme, Anim hazir.
-- Uretir: Nova._AddInput(section, flag, opts)

Nova._AddInput = function(section, flag, opts)
	opts = opts or {}
	local title = opts.Text or "Input"
	local desc = opts.Desc or ""
	local default = opts.Default or ""
	local placeholder = opts.Placeholder or "..."
	local numeric = opts.Numeric or false
	local finished = opts.Finished or false
	local maxLength = 32
	if opts.MaxLength ~= nil then
		maxLength = opts.MaxLength
	end
	local callback = opts.Callback

	local value = tostring(default)

	local card = section:AddElementCard(title, desc)
	Nova.Flags = Nova.Flags or {}

	local maid = Util.MaidNew()
	local listeners = {}
	local hoverChange = 0.08
	local baseTrans = card.BackgroundTransparency
	local alive = true
	local strokeBase = Theme.Get("ElementBorder")
	local strokeFocus = Theme.Get("Accent")

	local function fontR()
		if Util.GetFont then
			return Util.GetFont(false)
		end
		return Enum.Font.Gotham
	end

	-- Alt satir: sagda 160x30 TextBox
	local row = Util.Create("Frame", {
		Name = "InputRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Parent = card,
	})

	local box = Util.Create("TextBox", {
		Name = "Box",
		Text = value,
		PlaceholderText = tostring(placeholder),
		PlaceholderColor3 = Theme.Get("SubText"),
		Font = fontR(),
		TextSize = 13,
		TextColor3 = Theme.Get("Text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 160, 0, 30),
		BackgroundColor3 = Theme.Get("Background"),
		BackgroundTransparency = 0,
		Parent = row,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = box })
	Util.Create("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = box,
	})
	local stroke = Util.Create("UIStroke", {
		Color = strokeBase,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = box,
	})

	local obj = {}

	local function fire()
		for _, fn in ipairs(listeners) do
			Util.SafeCallback(fn, value)
		end
		Util.SafeCallback(callback, value)
	end

	local function commit(t)
		if not alive then
			return
		end
		value = tostring(t)
		if flag ~= nil and flag ~= "" then
			local rec = Nova.Flags[flag]
			if rec then
				rec.CurrentValue = value
			end
		end
		fire()
	end

	local function filter(t)
		t = tostring(t)
		if numeric then
			t = t:gsub("[^%d]", "")
		end
		if maxLength >= 0 and #t > maxLength then
			t = string.sub(t, 1, maxLength)
		end
		return t
	end

	-- Focus: stroke Accent'e 0.12 tween, blur'da geri
	maid:Give(box.Focused:Connect(function()
		Anim.Tween(stroke, { Color = strokeFocus }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))
	maid:Give(box.FocusLost:Connect(function(enterPressed)
		Anim.Tween(stroke, { Color = strokeBase }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if finished then
			if enterPressed then
				local t = filter(box.Text)
				if t ~= box.Text then
					box.Text = t
				end
				if t ~= value then
					commit(t)
				end
			end
		end
	end))

	-- Finished=false ise debounce 0.3sn ile anlik commit
	if not finished then
		maid:Give(box:GetPropertyChangedSignal("Text"):Connect(function()
			if not alive then
				return
			end
			local t = filter(box.Text)
			if t ~= box.Text then
				box.Text = t
				pcall(function()
					box.CursorPosition = #t + 1
				end)
			end
			local captured = t
			task.delay(0.3, function()
				if alive and box.Parent ~= nil and box.Text == captured and captured ~= value then
					commit(captured)
				end
			end)
		end))
	else
		-- Finished=true: sadece filtre uygula, callback yok
		maid:Give(box:GetPropertyChangedSignal("Text"):Connect(function()
			if not alive then
				return
			end
			local t = filter(box.Text)
			if t ~= box.Text then
				box.Text = t
				pcall(function()
					box.CursorPosition = #t + 1
				end)
			end
		end))
	end

	-- Kart hover 0.12 Quad
	maid:Give(card.MouseEnter:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = math.clamp(baseTrans - hoverChange, 0, 1) }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))
	maid:Give(card.MouseLeave:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = baseTrans }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))

	local function set(v, silent)
		local t = filter(v)
		value = t
		if box.Text ~= t then
			box.Text = t
		end
		if flag ~= nil and flag ~= "" then
			local rec = Nova.Flags[flag]
			if rec then
				rec.CurrentValue = value
			end
		end
		if not silent then
			fire()
		end
	end

	obj.Set = function(a, b, c)
		local v, silent
		if a == obj then
			v, silent = b, c
		else
			v, silent = a, b
		end
		set(v, silent)
	end
	obj.Get = function()
		return value
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
	obj.Destroy = function()
		alive = false
		maid:Cleanup()
		Anim.Cancel(card)
		Anim.Cancel(stroke)
		if Nova.SearchIndex then
			Nova.SearchIndex[card] = nil
		end
		if card then
			card:Destroy()
		end
	end

	-- Flags kaydi (flag yoksa yazma)
	if flag ~= nil and flag ~= "" then
		Nova.Flags[flag] = {
			Type = "Input",
			CurrentValue = value,
			Get = function()
				return value
			end,
			Set = function(v)
				set(v)
			end,
		}
	end

	return obj
end
