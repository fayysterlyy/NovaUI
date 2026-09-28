-- Nova UI - Button Element
-- Concat-build: require YOK. Ust scope Nova, Util, Theme, Anim hazir.
-- Uretir: Nova._AddButton(section, opts)
-- Flags'e yazilmaz.

Nova._AddButton = function(section, opts)
	opts = opts or {}
	local title = opts.Text or "Button"
	local desc = opts.Desc or ""
	local callback = opts.Callback
	local needDouble = opts.DoubleClick or false

	local card = section:AddElementCard(title, desc)

	local maid = Util.MaidNew()
	local listeners = {}
	local hoverChange = 0.08
	local baseTrans = card.BackgroundTransparency
	local lastClick = 0

	local function fontB()
		if Util.GetFont then
			return Util.GetFont(true)
		end
		return Enum.Font.GothamBold
	end

	local btn = Util.Create("TextButton", {
		Name = "Button",
		Text = title,
		Font = fontB(),
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Theme.Get("Accent"),
		BackgroundTransparency = 0.1,
		Parent = card,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = btn })
	local scale = Util.Create("UIScale", { Parent = btn })

	local function fire()
		for _, fn in ipairs(listeners) do
			Util.SafeCallback(fn)
		end
		Util.SafeCallback(callback)
	end

	-- Tiklama (DoubleClick ise 0.4sn icinde 2 tik bekle)
	maid:Give(btn.MouseButton1Click:Connect(function()
		if needDouble then
			local now = tick()
			if now - lastClick <= 0.4 then
				lastClick = 0
				fire()
			else
				lastClick = now
			end
		else
			fire()
		end
	end))

	-- Press: UIScale 0.97 (0.1sn) + Ripple
	maid:Give(btn.MouseButton1Down:Connect(function()
		Anim.Tween(scale, { Scale = 0.97 }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if Util.Ripple then
			Util.SafeCallback(Util.Ripple, btn)
		end
	end))
	maid:Give(btn.MouseButton1Up:Connect(function()
		Anim.Tween(scale, { Scale = 1 }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))
	maid:Give(btn.MouseLeave:Connect(function()
		Anim.Tween(scale, { Scale = 1 }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		Anim.Tween(btn, { BackgroundTransparency = 0.1 }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))
	maid:Give(btn.MouseEnter:Connect(function()
		Anim.Tween(btn, { BackgroundTransparency = 0.02 }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))

	-- Kart hover 0.12 Quad
	maid:Give(card.MouseEnter:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = math.clamp(baseTrans - hoverChange, 0, 1) }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))
	maid:Give(card.MouseLeave:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = baseTrans }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))

	local obj = {}
	obj.Click = function()
		fire()
	end
	obj.SetText = function(a, b)
		local t
		if a == obj then
			t = b
		else
			t = a
		end
		btn.Text = tostring(t)
	end
	obj.GetText = function()
		return btn.Text
	end
	-- Ortak sozlesme alias'lari (text uzerinden)
	obj.Set = obj.SetText
	obj.Get = obj.GetText
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
		maid:Cleanup()
		Anim.Cancel(btn)
		Anim.Cancel(scale)
		Anim.Cancel(card)
		if Nova.SearchIndex then
			Nova.SearchIndex[card] = nil
		end
		if card then
			card:Destroy()
		end
	end

	return obj
end
