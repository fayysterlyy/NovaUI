-- Nova UI - Label Element
-- Concat-build: require YOK. Ust scope Nova, Util, Theme, Anim hazir.
-- Uretir: Nova._AddLabel(section, text, wrap)

Nova._AddLabel = function(section, text, wrap)
	if wrap == nil then
		wrap = true
	end
	text = text or ""

	local card = section:AddElementCard("", "")

	local maid = Util.MaidNew()
	local listeners = {}
	local hoverChange = 0.08
	local baseTrans = card.BackgroundTransparency

	local function fontR()
		if Util.GetFont then
			return Util.GetFont(false)
		end
		return Enum.Font.Gotham
	end

	local lbl = Util.Create("TextLabel", {
		Name = "Label",
		Text = tostring(text),
		Font = fontR(),
		TextSize = 13,
		TextColor3 = Theme.Get("Text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = wrap,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = card,
	})
	if not wrap then
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
	end

	-- Kart hover 0.12 Quad
	maid:Give(card.MouseEnter:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = math.clamp(baseTrans - hoverChange, 0, 1) }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))
	maid:Give(card.MouseLeave:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = baseTrans }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))

	local obj = {}
	local function fire(t)
		for _, fn in ipairs(listeners) do
			Util.SafeCallback(fn, t)
		end
	end

	obj.SetText = function(a, b)
		local t
		if a == obj then
			t = b
		else
			t = a
		end
		t = tostring(t)
		lbl.Text = t
		fire(t)
	end
	obj.GetText = function()
		return lbl.Text
	end
	-- Ortak sozlesme alias'lari
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
