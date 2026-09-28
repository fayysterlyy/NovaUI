-- Notify: sag alt kose bildirimleri (max 5, slide + fade, progress bar).
-- Bagimlilik: Nova, Util, Theme, Anim (ust scope, concat-build; require YOK).

do
	local MAX_VISIBLE = 5
	local CARD_WIDTH = 260

	local function getScreenGui()
		local parent = Util.GetParent()
		local gui = parent:FindFirstChild("NovaUI")
		if not gui then
			gui = Util.Create("ScreenGui", {
				Name = "NovaUI",
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				ResetOnSpawn = false,
			}, parent)
		end
		return gui
	end

	local function getHolder()
		local holder = Nova._NotifyHolder
		if holder and holder.Parent then
			return holder
		end
		local gui = getScreenGui()
		holder = gui:FindFirstChild("NotifyHolder")
		if not holder then
			holder = Util.Create("Frame", {
				Name = "NotifyHolder",
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -16, 1, -16),
				Size = UDim2.new(0, CARD_WIDTH + 16, 0.6, 0),
				BackgroundTransparency = 1,
			}, gui)
			Util.Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
			}, holder)
		end
		Nova._NotifyHolder = holder
		return holder
	end

	function Nova.Notify(text, duration, accentColor)
		if type(duration) ~= "number" or duration <= 0 then
			duration = 4
		end
		local accent = accentColor
		if typeof(accent) ~= "Color3" then
			accent = Theme.Get("Accent")
		end

		Nova._NotifyCards = Nova._NotifyCards or {}
		Nova._NotifyCount = (Nova._NotifyCount or 0) + 1

		local holder = getHolder()
		local maid = Util.MaidNew()

		local card = Util.Create("CanvasGroup", {
			Name = "Notify",
			Size = UDim2.new(0, CARD_WIDTH, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.Get("Card"),
			BorderSizePixel = 0,
			GroupTransparency = 1,
			LayoutOrder = Nova._NotifyCount,
		}, holder)
		Theme.Register(card, { BackgroundColor3 = "Card" })
		Util.Create("UICorner", { CornerRadius = UDim.new(0, 10) }, card)
		local stroke = Util.Create("UIStroke", {
			Color = Theme.Get("ElementBorder"),
			Thickness = 1,
			Transparency = 0.4,
		}, card)
		Theme.Register(stroke, { Color = "ElementBorder" })

		local bar = Util.Create("Frame", {
			Name = "Accent",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Size = UDim2.new(0, 4, 1, -20),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
		}, card)
		Util.Create("UICorner", { CornerRadius = UDim.new(0, 2) }, bar)

		local content = Util.Create("Frame", {
			Name = "Content",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, card)
		Util.Create("UIPadding", {
			PaddingLeft = UDim.new(0, 18),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}, content)
		Util.Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}, content)

		local title = Util.Create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Util.GetFont(true),
			TextSize = 13,
			TextColor3 = Theme.Get("Text"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Text = tostring(text),
			LayoutOrder = 0,
		}, content)
		Theme.Register(title, { TextColor3 = "Text" })

		local track = Util.Create("Frame", {
			Name = "Progress",
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = Theme.Get("Element"),
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			LayoutOrder = 1,
		}, content)
		Util.Create("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
		local fill = Util.Create("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
		}, track)
		Util.Create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

		maid:Give(function()
			Anim.Cancel(card)
			Anim.Cancel(fill)
		end)

		local entry = {}
		local dismissed = false

		local function removeFromList()
			local list = Nova._NotifyCards
			if list then
				for i, item in ipairs(list) do
					if item == entry then
						table.remove(list, i)
						break
					end
				end
			end
		end

		local function dismiss()
			if dismissed then
				return
			end
			dismissed = true
			removeFromList()
			if not card.Parent then
				pcall(function() maid:Cleanup() end)
				return
			end
			Anim.Tween(card, { GroupTransparency = 1 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			task.delay(0.22, function()
				pcall(function() maid:Cleanup() end)
				pcall(function() card:Destroy() end)
			end)
		end

		entry.Dismiss = dismiss
		table.insert(Nova._NotifyCards, entry)

		while #Nova._NotifyCards > MAX_VISIBLE do
			local oldest = table.remove(Nova._NotifyCards, 1)
			if oldest and oldest ~= entry and type(oldest.Dismiss) == "function" then
				pcall(oldest.Dismiss)
			end
		end

		Anim.Tween(fill, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		task.spawn(function()
			task.wait()
			if dismissed or not card.Parent then
				return
			end
			local target = card.Position
			card.Position = target + UDim2.fromOffset(48, 0)
			Anim.Tween(card, {
				Position = target,
				GroupTransparency = 0,
			}, 0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
		end)

		maid:Give(task.delay(duration, dismiss))

		return entry
	end
end
