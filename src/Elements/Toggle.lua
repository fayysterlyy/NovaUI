-- Nova UI - Toggle Element
-- Concat-build: require YOK. Ust scope Nova, Util, Theme, Anim hazir.
-- Uretir: Nova._AddToggle(section, flag, opts)

Nova._AddToggle = function(section, flag, opts)
	opts = opts or {}
	local title = opts.Text or "Toggle"
	local desc = opts.Desc or ""
	local callback = opts.Callback
	local value = not not opts.Default

	local card = section:AddElementCard(title, desc)
	Nova.Flags = Nova.Flags or {}

	local maid = Util.MaidNew()
	local listeners = {}
	local hoverChange = 0.08
	local baseTrans = card.BackgroundTransparency
	local alive = true

	local function fontB()
		if Util.GetFont then
			return Util.GetFont(true)
		end
		return Enum.Font.GothamBold
	end

	-- Alt satir: saga yasli hap icin row (card ici UIListLayout dikey dizer)
	local row = Util.Create("Frame", {
		Name = "ToggleRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Parent = card,
	})

	local pill = Util.Create("TextButton", {
		Name = "Pill",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(36, 18),
		BackgroundColor3 = Theme.Get("Element"),
		BackgroundTransparency = 0,
		Font = fontB(),
		Parent = row,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pill })

	local dot = Util.Create("Frame", {
		Name = "Dot",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Theme.Get("SubText"),
		BorderSizePixel = 0,
		Parent = pill,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

	local function applyVisual(animated)
		local pillColor = value and Theme.Get("Accent") or Theme.Get("Element")
		local dotColor = value and Color3.fromRGB(255, 255, 255) or Theme.Get("SubText")
		local dotPos = value and UDim2.new(0, 20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		if animated then
			Anim.Tween(pill, { BackgroundColor3 = pillColor }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			Anim.Tween(dot, { BackgroundColor3 = dotColor, Position = dotPos }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		else
			Anim.Cancel(pill)
			Anim.Cancel(dot)
			pill.BackgroundColor3 = pillColor
			dot.BackgroundColor3 = dotColor
			dot.Position = dotPos
		end
	end

	local obj = {}

	local function fire()
		for _, fn in ipairs(listeners) do
			Util.SafeCallback(fn, value)
		end
		Util.SafeCallback(callback, value)
	end

	local function set(v, silent)
		value = not not v
		applyVisual(true)
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

	-- Tiklama: tum kart (scroll sirasinda tetiklenmesin diye down/up eslesmeli, 10px tolerans)
	local function hookClick(gui)
		local downPos = nil
		maid:Give(gui.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				downPos = input.Position
			end
		end))
		maid:Give(gui.InputEnded:Connect(function(input)
			if downPos == nil then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				local delta = (input.Position - downPos).Magnitude
				downPos = nil
				if delta <= 10 then
					set(not value)
				end
			end
		end))
	end

	hookClick(card)
	for _, d in ipairs(card:GetDescendants()) do
		if d:IsA("GuiObject") then
			hookClick(d)
		end
	end
	maid:Give(card.DescendantAdded:Connect(function(d)
		if d:IsA("GuiObject") then
			hookClick(d)
		end
	end))

	-- Hover 0.12 Quad
	maid:Give(card.MouseEnter:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = math.clamp(baseTrans - hoverChange, 0, 1) }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))
	maid:Give(card.MouseLeave:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = baseTrans }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))

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
		Anim.Cancel(pill)
		Anim.Cancel(dot)
		Anim.Cancel(card)
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
			Type = "Toggle",
			CurrentValue = value,
			Get = function()
				return value
			end,
			Set = function(v)
				set(v)
			end,
		}
	end

	applyVisual(false)
	return obj
end
