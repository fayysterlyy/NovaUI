-- Nova UI - Slider Element
-- Concat-build: require YOK. Ust scope Nova, Util, Theme, Anim hazir.
-- Uretir: Nova._AddSlider(section, flag, opts)
-- Drag akiciligi icin tween YOK (direkt set). Bar tiklamasi jump yapar.

Nova._AddSlider = function(section, flag, opts)
	opts = opts or {}
	local title = opts.Text or "Slider"
	local desc = opts.Desc or ""
	local min = opts.Min or 0
	local max = opts.Max or 100
	local rounding = opts.Rounding or 0
	local suffix = "%"
	if opts.Suffix ~= nil then
		suffix = tostring(opts.Suffix)
	end
	local callback = opts.Callback

	if max <= min then
		max = min + 1
	end

	local mult = 10 ^ rounding
	local function roundV(v)
		return math.floor(v * mult + 0.5) / mult
	end

	local value = math.clamp(roundV(opts.Default or min), min, max)

	local card = section:AddElementCard(title, desc)
	Nova.Flags = Nova.Flags or {}

	local maid = Util.MaidNew()
	local listeners = {}
	local hoverChange = 0.08
	local baseTrans = card.BackgroundTransparency
	local UIS = game:GetService("UserInputService")

	local function fontR()
		if Util.GetFont then
			return Util.GetFont(false)
		end
		return Enum.Font.Gotham
	end

	-- Alt satir: solda deger etiketi (saga yasli), sagda 150px rail
	local row = Util.Create("Frame", {
		Name = "SliderRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Parent = card,
	})

	local valueLabel = Util.Create("TextLabel", {
		Name = "Value",
		Font = fontR(),
		TextSize = 12,
		TextColor3 = Theme.Get("SubText"),
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -158, 1, 0),
		Parent = row,
	})

	local rail = Util.Create("TextButton", {
		Name = "Rail",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 150, 0, 4),
		BackgroundColor3 = Theme.Get("ElementBorder"),
		BackgroundTransparency = 0,
		Parent = row,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = rail })

	local fill = Util.Create("Frame", {
		Name = "Fill",
		BackgroundColor3 = Theme.Get("Accent"),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = rail,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

	local dot = Util.Create("Frame", {
		Name = "Dot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = rail,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

	local function formatV(v)
		if rounding > 0 then
			return string.format("%." .. rounding .. "f", v)
		end
		return tostring(v)
	end

	local obj = {}

	local function fire()
		for _, fn in ipairs(listeners) do
			Util.SafeCallback(fn, value)
		end
		Util.SafeCallback(callback, value)
	end

	local function render()
		local range = max - min
		local pct = 0
		if range > 0 then
			pct = math.clamp((value - min) / range, 0, 1)
		end
		fill.Size = UDim2.new(pct, 0, 1, 0)
		dot.Position = UDim2.new(pct, 0, 0.5, 0)
		valueLabel.Text = formatV(value) .. suffix
	end

	local function set(v, silent)
		if type(v) ~= "number" then
			v = tonumber(v) or min
		end
		value = math.clamp(roundV(v), min, max)
		render()
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

	local dragging = false
	local function setFromPos(pos)
		local rw = rail.AbsoluteSize.X
		if rw <= 0 then
			return
		end
		local pct = math.clamp((pos.X - rail.AbsolutePosition.X) / rw, 0, 1)
		set(min + pct * (max - min))
	end

	local function hookPress(gui)
		maid:Give(gui.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				setFromPos(input.Position)
			end
		end))
	end
	hookPress(rail)
	hookPress(fill)
	hookPress(dot)

	maid:Give(UIS.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			setFromPos(input.Position)
		end
	end))
	maid:Give(UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	-- Kart hover 0.12 Quad
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
		dragging = false
		maid:Cleanup()
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
			Type = "Slider",
			CurrentValue = value,
			Get = function()
				return value
			end,
			Set = function(v)
				set(v)
			end,
		}
	end

	render()
	return obj
end
