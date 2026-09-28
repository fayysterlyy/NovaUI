-- Nova UI - ColorPicker Element
-- Concat-build: require YOK. Ust scope Nova, Util, Theme, Anim hazir.
-- Uretir: Nova._AddColorPicker(section, flag, opts)
-- opts = { Default=Color3.fromRGB(124,108,255), Transparency=0, Callback }

Nova._AddColorPicker = function(section, flag, opts)
	opts = opts or {}
	local title = opts.Text or "Color Picker"
	local desc = opts.Desc or ""
	local callback = opts.Callback
	local transpDefault = opts.Transparency or 0
	if type(transpDefault) ~= "number" then
		transpDefault = 0
	end
	transpDefault = math.clamp(transpDefault, 0, 1)

	local defColor = opts.Default
	if typeof(defColor) ~= "Color3" then
		defColor = Color3.fromRGB(124, 108, 255)
	end

	local card = section:AddElementCard(title, desc)
	Nova.Flags = Nova.Flags or {}

	local maid = Util.MaidNew()
	local listeners = {}
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

	-- Saf Luau HSV (built-in'e bagimli degil)
	local function rgbToHsv(color)
		local r, g, b = color.R, color.G, color.B
		local mx = math.max(r, math.max(g, b))
		local mn = math.min(r, math.min(g, b))
		local d = mx - mn
		local h = 0
		local s = 0
		local v = mx
		if mx == 0 then
			return 0, 0, 0
		end
		s = d / mx
		if d == 0 then
			h = 0
		elseif mx == r then
			h = ((g - b) / d) % 6
		elseif mx == g then
			h = (b - r) / d + 2
		else
			h = (r - g) / d + 4
		end
		h = h / 6
		if h < 0 then
			h = h + 1
		end
		if h >= 1 then
			h = h - math.floor(h)
		end
		return h, s, v
	end

	local function hsvToRgb(h, s, v)
		h = h - math.floor(h)
		if h < 0 then
			h = h + 1
		end
		s = math.clamp(s, 0, 1)
		v = math.clamp(v, 0, 1)
		local c = v * s
		local hh = h * 6
		local x = c * (1 - math.abs((hh % 2) - 1))
		local m = v - c
		local r, g, b
		local seg = math.floor(hh)
		if seg == 0 then
			r, g, b = c, x, 0
		elseif seg == 1 then
			r, g, b = x, c, 0
		elseif seg == 2 then
			r, g, b = 0, c, x
		elseif seg == 3 then
			r, g, b = 0, x, c
		elseif seg == 4 then
			r, g, b = x, 0, c
		else
			r, g, b = c, 0, x
		end
		return Color3.new(r + m, g + m, b + m)
	end

	local ch, cs, cv = rgbToHsv(defColor)
	local value = defColor
	local transp = transpDefault
	-- Dialog acikken duzenlenen aday renk
	local ph, ps, pv = ch, cs, cv
	local pTransp = transp

	-- Alt satir: sagda 26x26 renk kutusu
	local row = Util.Create("Frame", {
		Name = "ColorRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Parent = card,
	})

	local swatch = Util.Create("TextButton", {
		Name = "Swatch",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = value,
		BackgroundTransparency = transp,
		Parent = row,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = swatch })
	Util.Create("UIStroke", {
		Color = Theme.Get("ElementBorder"),
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = swatch,
	})

	local function getOverlayParent()
		if Nova._OverlayLayer ~= nil and typeof(Nova._OverlayLayer) == "Instance" and Nova._OverlayLayer.Parent ~= nil then
			return Nova._OverlayLayer
		end
		if section ~= nil and type(section) == "table" then
			local w = section._Window or section.Window
			if w ~= nil and type(w) == "table" and w.Root ~= nil and typeof(w.Root) == "Instance" then
				return w.Root
			end
		end
		local ok, gui = pcall(function()
			return card:FindFirstAncestorOfClass("ScreenGui")
		end)
		if ok and gui ~= nil then
			return gui
		end
		if Util.GetParent then
			return Util.GetParent()
		end
		return nil
	end

	local obj = {}
	local dialogMaid = nil
	local dialogOpen = false
	-- Dialog widget referanslari (canli guncelleme icin)
	local W = {}

	local function fire(c, t)
		for _, fn in ipairs(listeners) do
			Util.SafeCallback(fn, c, t)
		end
		Util.SafeCallback(callback, c, t)
		if flag ~= nil and flag ~= "" then
			local rec = Nova.Flags[flag]
			if rec then
				rec.CurrentValue = c
				rec.Transparency = t
			end
		end
	end

	local function pendingColor()
		return hsvToRgb(ph, ps, pv)
	end

	local function paintDialog()
		if W.svBase == nil then
			return
		end
		local hueCol = hsvToRgb(ph, 1, 1)
		local pend = pendingColor()
		W.svBase.BackgroundColor3 = hueCol
		-- SV cursor: x=s, y=1-v
		local sPos = ps
		local vPos = 1 - pv
		W.svCursor.Position = UDim2.new(sPos, -6, vPos, -6)
		W.hueCursor.Position = UDim2.new(0, -2, ph, -6)
		W.transpBar.BackgroundColor3 = pend
		W.transpCursor.Position = UDim2.new(0, -2, pTransp, -6)
		W.newPrev.BackgroundColor3 = pend
		W.newPrev.BackgroundTransparency = pTransp
		-- Hex + RGB kutulari (odakli degillerse yaz)
		local r = math.floor(pend.R * 255 + 0.5)
		local g = math.floor(pend.G * 255 + 0.5)
		local b = math.floor(pend.B * 255 + 0.5)
		if W.hexBox ~= nil and not W.hexBox:IsFocused() then
			W.hexBox.Text = string.format("#%02X%02X%02X", r, g, b)
		end
		if W.rBox ~= nil and not W.rBox:IsFocused() then
			W.rBox.Text = tostring(r)
		end
		if W.gBox ~= nil and not W.gBox:IsFocused() then
			W.gBox.Text = tostring(g)
		end
		if W.bBox ~= nil and not W.bBox:IsFocused() then
			W.bBox.Text = tostring(b)
		end
	end

	local function makeDrag(gui, onFrac)
		dialogMaid:Give(gui.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				local as = gui.AbsoluteSize
				local ap = gui.AbsolutePosition
				if as.X > 0 and as.Y > 0 then
					local fx = math.clamp((input.Position.X - ap.X) / as.X, 0, 1)
					local fy = math.clamp((input.Position.Y - ap.Y) / as.Y, 0, 1)
					onFrac(fx, fy)
				end
				local dragging = true
				local connMove
				local connEnd
				connMove = UIS.InputChanged:Connect(function(inp)
					if not dragging then
						return
					end
					if inp.UserInputType == Enum.UserInputType.MouseMovement
						or inp.UserInputType == Enum.UserInputType.Touch then
						local as2 = gui.AbsoluteSize
						local ap2 = gui.AbsolutePosition
						if as2.X > 0 and as2.Y > 0 then
							local fx = math.clamp((inp.Position.X - ap2.X) / as2.X, 0, 1)
							local fy = math.clamp((inp.Position.Y - ap2.Y) / as2.Y, 0, 1)
							onFrac(fx, fy)
						end
					end
				end)
				connEnd = UIS.InputEnded:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1
						or inp.UserInputType == Enum.UserInputType.Touch then
						dragging = false
						pcall(function()
							connMove:Disconnect()
						end)
						pcall(function()
							connEnd:Disconnect()
						end)
					end
				end)
				dialogMaid:Give(connMove)
				dialogMaid:Give(connEnd)
			end
		end))
	end

	local function closeDialog(commit)
		if not dialogOpen then
			return
		end
		dialogOpen = false
		if commit then
			value = pendingColor()
			transp = pTransp
			ch, cs, cv = ph, ps, pv
			swatch.BackgroundColor3 = value
			swatch.BackgroundTransparency = transp
			fire(value, transp)
		end
		if dialogMaid ~= nil then
			dialogMaid:Cleanup()
			dialogMaid = nil
		end
		for k, _ in pairs(W) do
			W[k] = nil
		end
		if Nova._ColorDim ~= nil then
			pcall(function()
				Nova._ColorDim:Destroy()
			end)
			Nova._ColorDim = nil
		end
		if Nova._ColorDialog ~= nil then
			pcall(function()
				Nova._ColorDialog:Destroy()
			end)
			Nova._ColorDialog = nil
		end
	end

	local function openDialog()
		if dialogOpen then
			return
		end
		if not alive then
			return
		end
		closeDialog(false)
		local overlay = getOverlayParent()
		if overlay == nil then
			return
		end
		ph, ps, pv = ch, cs, cv
		pTransp = transp

		dialogMaid = Util.MaidNew()
		dialogOpen = true

		local dim = Util.Create("TextButton", {
			Name = "NovaColorDim",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 198,
			Parent = overlay,
		})
		Nova._ColorDim = dim

		local dlg = Util.Create("Frame", {
			Name = "NovaColorDialog",
			BackgroundColor3 = Theme.Get("Dialog"),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.fromOffset(380, 300),
			ZIndex = 199,
			ClipsDescendants = true,
			Parent = overlay,
		})
		Util.Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = dlg })
		Util.Create("UIStroke", {
			Color = Theme.Get("ElementBorder"),
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = dlg,
		})
		local dlgScale = Util.Create("UIScale", { Scale = 0.9, Parent = dlg })
		Nova._ColorDialog = dlg

		Anim.Tween(dlgScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

		-- Baslik
		Util.Create("TextLabel", {
			Name = "Title",
			Text = "Color Picker",
			Font = fontB(),
			TextSize = 14,
			TextColor3 = Theme.Get("Text"),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 8),
			Size = UDim2.new(1, -60, 0, 22),
			ZIndex = 200,
			Parent = dlg,
		})
		local xBtn = Util.Create("TextButton", {
			Name = "X",
			Text = "X",
			Font = fontB(),
			TextSize = 13,
			TextColor3 = Theme.Get("SubText"),
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 8),
			Size = UDim2.fromOffset(24, 22),
			ZIndex = 200,
			Parent = dlg,
		})

		-- SV kare 180x160
		local svBase = Util.Create("TextButton", {
			Name = "SV",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = hsvToRgb(ph, 1, 1),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(14, 40),
			Size = UDim2.fromOffset(180, 160),
			ZIndex = 200,
			ClipsDescendants = true,
			Parent = dlg,
		})
		Util.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = svBase })
		local satOverlay = Util.Create("Frame", {
			Name = "Sat",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 201,
			Parent = svBase,
		})
		Util.Create("UIGradient", {
			Rotation = 0,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = satOverlay,
		})
		local valOverlay = Util.Create("Frame", {
			Name = "Val",
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 202,
			Parent = svBase,
		})
		Util.Create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Parent = valOverlay,
		})
		local svCursor = Util.Create("Frame", {
			Name = "Cursor",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0),
			Size = UDim2.fromOffset(12, 12),
			ZIndex = 203,
			Parent = svBase,
		})
		Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = svCursor })
		Util.Create("UIStroke", {
			Color = Color3.fromRGB(0, 0, 0),
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = svCursor,
		})

		-- Hue bar 12x160 (sagda)
		local hueBar = Util.Create("TextButton", {
			Name = "Hue",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(204, 40),
			Size = UDim2.fromOffset(12, 160),
			ZIndex = 200,
			ClipsDescendants = true,
			Parent = dlg,
		})
		Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueBar })
		local hueSeq = {}
		for i = 0, 6 do
			table.insert(hueSeq, ColorSequenceKeypoint.new(i / 6, hsvToRgb(i / 6, 1, 1)))
		end
		Util.Create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(hueSeq),
			Parent = hueBar,
		})
		local hueCursor = Util.Create("Frame", {
			Name = "Dot",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 4, 0, 6),
			ZIndex = 201,
			Parent = hueBar,
		})
		Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueCursor })
		Util.Create("UIStroke", {
			Color = Color3.fromRGB(0, 0, 0),
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = hueCursor,
		})

		-- Transparency bar 12x160 (opsiyonel, her zaman goster)
		local transpBar = Util.Create("TextButton", {
			Name = "Transp",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = pendingColor(),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(226, 40),
			Size = UDim2.fromOffset(12, 160),
			ZIndex = 200,
			ClipsDescendants = true,
			Parent = dlg,
		})
		Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = transpBar })
		Util.Create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = transpBar,
		})
		local transpCursor = Util.Create("Frame", {
			Name = "Dot",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 4, 0, 6),
			ZIndex = 201,
			Parent = transpBar,
		})
		Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = transpCursor })
		Util.Create("UIStroke", {
			Color = Color3.fromRGB(0, 0, 0),
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = transpCursor,
		})

		-- Sag panel: eski/yeni onizleme 2x 40x24
		local oldPrev = Util.Create("Frame", {
			Name = "Old",
			BackgroundColor3 = value,
			BackgroundTransparency = transp,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(250, 40),
			Size = UDim2.fromOffset(40, 24),
			ZIndex = 200,
			Parent = dlg,
		})
		Util.Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = oldPrev })
		Util.Create("UIStroke", {
			Color = Theme.Get("ElementBorder"),
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = oldPrev,
		})
		local newPrev = Util.Create("Frame", {
			Name = "New",
			BackgroundColor3 = pendingColor(),
			BackgroundTransparency = pTransp,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(296, 40),
			Size = UDim2.fromOffset(40, 24),
			ZIndex = 200,
			Parent = dlg,
		})
		Util.Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = newPrev })
		Util.Create("UIStroke", {
			Color = Theme.Get("ElementBorder"),
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = newPrev,
		})

		-- Hex + RGB
		Util.Create("TextLabel", {
			Name = "HexL",
			Text = "Hex",
			Font = fontR(),
			TextSize = 11,
			TextColor3 = Theme.Get("SubText"),
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(250, 72),
			Size = UDim2.fromOffset(86, 14),
			ZIndex = 200,
			Parent = dlg,
		})
		local hexBox = Util.Create("TextBox", {
			Name = "Hex",
			Font = fontR(),
			TextSize = 12,
			TextColor3 = Theme.Get("Text"),
			PlaceholderColor3 = Theme.Get("SubText"),
			Text = "",
			ClearTextOnFocus = false,
			BackgroundColor3 = Theme.Get("Background"),
			Position = UDim2.fromOffset(250, 88),
			Size = UDim2.fromOffset(86, 24),
			ZIndex = 200,
			Parent = dlg,
		})
		Util.Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = hexBox })

		local rgbTitles = { "R", "G", "B" }
		local rgbBoxes = {}
		for i = 1, 3 do
			local bx = 250 + (i - 1) * 44
			Util.Create("TextLabel", {
				Name = rgbTitles[i] .. "L",
				Text = rgbTitles[i],
				Font = fontR(),
				TextSize = 11,
				TextColor3 = Theme.Get("SubText"),
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(bx, 118),
				Size = UDim2.fromOffset(40, 14),
				ZIndex = 200,
				Parent = dlg,
			})
			rgbBoxes[i] = Util.Create("TextBox", {
				Name = rgbTitles[i],
				Font = fontR(),
				TextSize = 12,
				TextColor3 = Theme.Get("Text"),
				PlaceholderColor3 = Theme.Get("SubText"),
				Text = "",
				ClearTextOnFocus = false,
				BackgroundColor3 = Theme.Get("Background"),
				Position = UDim2.fromOffset(bx, 134),
				Size = UDim2.fromOffset(40, 24),
				ZIndex = 200,
				Parent = dlg,
			})
			Util.Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = rgbBoxes[i] })
		end

		-- Apply / Cancel
		local applyBtn = Util.Create("TextButton", {
			Name = "Apply",
			Text = "Apply",
			Font = fontB(),
			TextSize = 13,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			AutoButtonColor = false,
			BackgroundColor3 = Theme.Get("Accent"),
			BackgroundTransparency = 0.1,
			Position = UDim2.fromOffset(14, 258),
			Size = UDim2.new(1, -28, 0, 30),
			ZIndex = 200,
			Parent = dlg,
		})
		Util.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = applyBtn })

		local cancelBtn = Util.Create("TextButton", {
			Name = "Cancel",
			Text = "Cancel",
			Font = fontR(),
			TextSize = 12,
			TextColor3 = Theme.Get("SubText"),
			AutoButtonColor = false,
			BackgroundColor3 = Theme.Get("Card"),
			BackgroundTransparency = 0,
			Position = UDim2.fromOffset(14, 222),
			Size = UDim2.new(1, -28, 0, 28),
			ZIndex = 200,
			Parent = dlg,
		})
		Util.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = cancelBtn })

		W.svBase = svBase
		W.svCursor = svCursor
		W.hueCursor = hueCursor
		W.transpBar = transpBar
		W.transpCursor = transpCursor
		W.newPrev = newPrev
		W.hexBox = hexBox
		W.rBox = rgbBoxes[1]
		W.gBox = rgbBoxes[2]
		W.bBox = rgbBoxes[3]

		makeDrag(svBase, function(fx, fy)
			ps = math.clamp(fx, 0, 1)
			pv = math.clamp(1 - fy, 0, 1)
			paintDialog()
		end)
		makeDrag(hueBar, function(_fx, fy)
			ph = math.clamp(fy, 0, 0.999)
			paintDialog()
		end)
		makeDrag(transpBar, function(_fx, fy)
			pTransp = math.clamp(fy, 0, 1)
			paintDialog()
		end)

		dialogMaid:Give(xBtn.MouseButton1Click:Connect(function()
			closeDialog(false)
		end))
		dialogMaid:Give(cancelBtn.MouseButton1Click:Connect(function()
			closeDialog(false)
		end))
		dialogMaid:Give(dim.MouseButton1Click:Connect(function()
			closeDialog(false)
		end))
		dialogMaid:Give(applyBtn.MouseButton1Click:Connect(function()
			closeDialog(true)
		end))

		local function parseHex(t)
			t = tostring(t):gsub("#", ""):gsub("%s+", "")
			if #t == 6 and t:match("^[0-9a-fA-F]+$") then
				local r = tonumber(t:sub(1, 2), 16)
				local g = tonumber(t:sub(3, 4), 16)
				local b = tonumber(t:sub(5, 6), 16)
				if r and g and b then
					return Color3.fromRGB(r, g, b)
				end
			end
			return nil
		end
		dialogMaid:Give(hexBox.FocusLost:Connect(function(enter)
			if not enter then
				paintDialog()
				return
			end
			local c = parseHex(hexBox.Text)
			if c ~= nil then
				ph, ps, pv = rgbToHsv(c)
				paintDialog()
			else
				paintDialog()
			end
		end))
		for i = 1, 3 do
			local rbox = rgbBoxes[i]
			dialogMaid:Give(rbox.FocusLost:Connect(function(enter)
				if not enter then
					paintDialog()
					return
				end
				local r = math.clamp(math.floor(tonumber(W.rBox.Text) or 0), 0, 255)
				local g = math.clamp(math.floor(tonumber(W.gBox.Text) or 0), 0, 255)
				local b = math.clamp(math.floor(tonumber(W.bBox.Text) or 0), 0, 255)
				ph, ps, pv = rgbToHsv(Color3.fromRGB(r, g, b))
				paintDialog()
			end))
		end

		paintDialog()
	end

	maid:Give(swatch.MouseButton1Click:Connect(function()
		if alive then
			openDialog()
		end
	end))

	-- Kart hover 0.12 Quad
	maid:Give(card.MouseEnter:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = math.clamp(baseTrans - hoverChange, 0, 1) }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))
	maid:Give(card.MouseLeave:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = baseTrans }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))

	local function setColor(c, t, silent)
		if typeof(c) == "Color3" then
			value = c
			ch, cs, cv = rgbToHsv(c)
		end
		if type(t) == "number" then
			transp = math.clamp(t, 0, 1)
		end
		ph, ps, pv = ch, cs, cv
		pTransp = transp
		swatch.BackgroundColor3 = value
		swatch.BackgroundTransparency = transp
		if not silent then
			fire(value, transp)
		else
			if flag ~= nil and flag ~= "" then
				local rec = Nova.Flags[flag]
				if rec then
					rec.CurrentValue = value
					rec.Transparency = transp
				end
			end
		end
	end

	obj.Set = function(a, b, c, d)
		local col, tr, silent
		if a == obj then
			col, tr, silent = b, c, d
		else
			col, tr, silent = a, b, c
		end
		setColor(col, tr, silent)
	end
	obj.Get = function()
		return value, transp
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
		closeDialog(false)
		maid:Cleanup()
		Anim.Cancel(card)
		if Nova.SearchIndex then
			Nova.SearchIndex[card] = nil
		end
		if card then
			card:Destroy()
		end
	end

	if flag ~= nil and flag ~= "" then
		Nova.Flags[flag] = {
			Type = "ColorPicker",
			CurrentValue = value,
			Transparency = transp,
			Get = function()
				return value, transp
			end,
			Set = function(c, t)
				setColor(c, t)
			end,
		}
	end

	return obj
end
