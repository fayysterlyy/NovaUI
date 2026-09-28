-- Nova UI - Dropdown Element
-- Concat-build: require YOK. Ust scope Nova, Util, Theme, Anim hazir.
-- Uretir: Nova._AddDropdown(section, flag, opts)
-- opts = { Text="Dropdown", Desc="", Values={"A","B"}, Default=1 veya "A", Multi=false, MaxVisible=8, Callback }

Nova._AddDropdown = function(section, flag, opts)
	opts = opts or {}
	local title = opts.Text or "Dropdown"
	local desc = opts.Desc or ""
	local callback = opts.Callback
	local multi = opts.Multi or false
	local maxVisible = opts.MaxVisible or 8
	if type(maxVisible) ~= "number" or maxVisible < 1 then
		maxVisible = 8
	end
	if maxVisible > 12 then
		maxVisible = 12
	end

	local values = {}
	if type(opts.Values) == "table" then
		for _, v in ipairs(opts.Values) do
			table.insert(values, tostring(v))
		end
	end
	if #values == 0 then
		values = { "Empty" }
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

	-- Secim state: single -> string, multi -> {A=true}
	local selectedLUT = {}
	local singleValue = nil

	local function defaultResolve(def)
		if multi then
			if type(def) == "table" then
				for _, v in ipairs(def) do
					local s = tostring(v)
					for _, opt in ipairs(values) do
						if opt == s then
							selectedLUT[s] = true
							break
						end
					end
				end
				if #def == 0 then
					-- Set formu: {A=true}
					for k, on in pairs(def) do
						if on then
							local s = tostring(k)
							for _, opt in ipairs(values) do
								if opt == s then
									selectedLUT[s] = true
									break
								end
							end
						end
					end
				end
			elseif def ~= nil then
				local s = tostring(def)
				for _, opt in ipairs(values) do
					if opt == s then
						selectedLUT[s] = true
						break
					end
				end
			end
		else
			if type(def) == "number" then
				singleValue = values[math.clamp(math.floor(def), 1, #values)] or values[1]
			elseif def ~= nil then
				local s = tostring(def)
				singleValue = values[1]
				for _, opt in ipairs(values) do
					if opt == s then
						singleValue = opt
						break
					end
				end
			else
				singleValue = values[1]
			end
		end
	end
	defaultResolve(opts.Default)

	local function getValue()
		if multi then
			local copy = {}
			for k, v in pairs(selectedLUT) do
				if v then
					copy[k] = true
				end
			end
			return copy
		end
		return singleValue
	end

	local function countSelected()
		local n = 0
		for _, v in pairs(selectedLUT) do
			if v then
				n = n + 1
			end
		end
		return n
	end

	-- Alt satir: sagda 160x30 kutu
	local row = Util.Create("Frame", {
		Name = "DropdownRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Parent = card,
	})

	local box = Util.Create("TextButton", {
		Name = "Box",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 160, 0, 30),
		BackgroundColor3 = Theme.Get("Background"),
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		Parent = row,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = box })
	Util.Create("UIStroke", {
		Color = Theme.Get("ElementBorder"),
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = box,
	})

	local boxLabel = Util.Create("TextLabel", {
		Name = "Label",
		Font = fontR(),
		TextSize = 13,
		TextColor3 = Theme.Get("Text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Parent = box,
	})

	local chevron = Util.Create("TextLabel", {
		Name = "Chevron",
		Text = "v",
		Font = fontR(),
		TextSize = 14,
		TextColor3 = Theme.Get("SubText"),
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Rotation = 0,
		Parent = box,
	})

	-- Overlay parent cozumu: Window.Root varsa o, yoksa ScreenGui
	local function getOverlayParent()
		if Nova._OverlayLayer ~= nil and typeof(Nova._OverlayLayer) == "Instance" and Nova._OverlayLayer.Parent ~= nil then
			return Nova._OverlayLayer
		end
		if section ~= nil and type(section) == "table" then
			local w = section._Window or section.Window
			if w ~= nil and type(w) == "table" and w.Root ~= nil and typeof(w.Root) == "Instance" then
				return w.Root
			end
			if section.Root ~= nil and typeof(section.Root) == "Instance" then
				local okGui, gui = pcall(function()
					return section.Root:FindFirstAncestorOfClass("ScreenGui")
				end)
				if okGui and gui ~= nil then
					return gui
				end
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

	-- Liste layer (kapali baslar)
	local ITEM_H = 28
	local GAP = 3

	local listFrame = Util.Create("Frame", {
		Name = "DropdownList",
		Visible = false,
		BackgroundColor3 = Theme.Get("Dialog"),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(170, 100),
		ZIndex = 100,
		ClipsDescendants = true,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = listFrame })
	Util.Create("UIStroke", {
		Color = Theme.Get("ElementBorder"),
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = listFrame,
	})
	Util.Create("UIPadding", {
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5),
		Parent = listFrame,
	})
	local listScale = Util.Create("UIScale", { Scale = 0.95, Parent = listFrame })

	local scroll = Util.Create("ScrollingFrame", {
		Name = "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Get("ElementBorder"),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 101,
		Parent = listFrame,
	})
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroll,
	})

	local obj = {}
	local open = false

	-- TEK global disari-tiklama: ilk dropdown'da kurulur
	Nova._DropdownRegistry = Nova._DropdownRegistry or {}
	if Nova._DropdownGlobalConn == nil then
		local ok, conn = pcall(function()
			return UIS.InputBegan:Connect(function(input, _gpe)
				local cur = Nova._OpenDropdown
				if cur ~= nil and cur.CloseIfOutside ~= nil then
					pcall(cur.CloseIfOutside, input)
				end
			end)
		end)
		if ok then
			Nova._DropdownGlobalConn = conn
		end
	end

	local function paintBoxLabel()
		if multi then
			local n = countSelected()
			if n == 0 then
				boxLabel.Text = "Select..."
			elseif n == 1 then
				for k, v in pairs(selectedLUT) do
					if v then
						boxLabel.Text = k
						break
					end
				end
			else
				boxLabel.Text = tostring(n) .. " selected"
			end
		else
			boxLabel.Text = singleValue or "Select..."
		end
	end

	local function paintItems()
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("TextButton") then
				local name = child.Name
				local sel = false
				if multi then
					sel = selectedLUT[name] == true
				else
					sel = (name == singleValue)
				end
				if sel then
					child.BackgroundColor3 = Theme.Get("Accent")
					child.BackgroundTransparency = 0.85
					local bar = child:FindFirstChild("Bar")
					if bar then
						bar.Visible = true
					end
				else
					child.BackgroundColor3 = Theme.Get("Card")
					child.BackgroundTransparency = 1
					local bar = child:FindFirstChild("Bar")
					if bar then
						bar.Visible = false
					end
				end
			end
		end
	end

	local function fire()
		local v = getValue()
		for _, fn in ipairs(listeners) do
			Util.SafeCallback(fn, v)
		end
		Util.SafeCallback(callback, v)
		if flag ~= nil and flag ~= "" then
			local rec = Nova.Flags[flag]
			if rec then
				rec.CurrentValue = v
			end
		end
	end

	local function listHeight()
		local n = #values
		local vis = math.min(n, maxVisible)
		if vis < 1 then
			vis = 1
		end
		local h = vis * ITEM_H + (vis - 1) * GAP + 10
		if h > 250 then
			h = 250
		end
		return h
	end

	local function placeList()
		local overlay = listFrame.Parent
		if overlay == nil or typeof(overlay) ~= "Instance" then
			return
		end
		local h = listHeight()
		listFrame.Size = UDim2.fromOffset(170, h)
		local okCam, cam = pcall(function()
			return workspace.CurrentCamera
		end)
		local vpX, vpY = 1024, 768
		if okCam and cam ~= nil then
			local vs = cam.ViewportSize
			vpX, vpY = vs.X, vs.Y
		end
		local oAbs = overlay.AbsolutePosition
		local bAbs = box.AbsolutePosition
		local bSize = box.AbsoluteSize
		local lx = (bAbs.X - oAbs.X) + bSize.X - 170
		local overW = overlay.AbsoluteSize.X
		if overW <= 0 then
			overW = vpX
		end
		if lx + 170 > overW - 4 then
			lx = overW - 174
		end
		if lx < 4 then
			lx = 4
		end
		local belowAbsY = bAbs.Y + bSize.Y + 4
		local ly
		if belowAbsY + h > vpY - 8 then
			ly = (bAbs.Y - oAbs.Y) - h - 4
		else
			ly = (bAbs.Y - oAbs.Y) + bSize.Y + 4
		end
		if ly < 4 then
			ly = 4
		end
		listFrame.Position = UDim2.fromOffset(lx, ly)
	end

	local function close(instant)
		if not open then
			return
		end
		open = false
		if Nova._OpenDropdown == obj then
			Nova._OpenDropdown = nil
		end
		Anim.Tween(chevron, { Rotation = 0 }, 0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
		if instant then
			Anim.Cancel(listFrame)
			Anim.Cancel(listScale)
			listFrame.Visible = false
		else
			Anim.Tween(listScale, { Scale = 0.95 }, 0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
			Anim.Tween(listFrame, { BackgroundTransparency = 1 }, 0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
			task.delay(0.15, function()
				if alive and not open and listFrame.Parent ~= nil then
					listFrame.Visible = false
				end
			end)
		end
	end

	local function openList()
		if open then
			close()
			return
		end
		if Nova._OpenDropdown ~= nil and Nova._OpenDropdown ~= obj and Nova._OpenDropdown.Close ~= nil then
			pcall(Nova._OpenDropdown.Close)
		end
		local overlay = getOverlayParent()
		if overlay == nil then
			return
		end
		if listFrame.Parent ~= overlay then
			listFrame.Parent = overlay
		end
		placeList()
		listFrame.Visible = true
		open = true
		Nova._OpenDropdown = obj
		listScale.Scale = 0.95
		listFrame.BackgroundTransparency = 1
		Anim.Tween(listScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
		Anim.Tween(listFrame, { BackgroundTransparency = 0 }, 0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
		Anim.Tween(chevron, { Rotation = 180 }, 0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	end

	-- Item havuzu: gizli template + Clone (yoksa Instance.new)
	local itemTemplate = nil
	local function ensureTemplate()
		if itemTemplate ~= nil and itemTemplate.Parent ~= nil then
			return true
		end
		local ok, proto = pcall(function()
			local b = Util.Create("TextButton", {
				Name = "__Template",
				Text = "",
				AutoButtonColor = false,
				Visible = false,
				Size = UDim2.new(1, 0, 0, ITEM_H),
				BackgroundColor3 = Theme.Get("Card"),
				BackgroundTransparency = 1,
				ZIndex = 102,
				Parent = scroll,
			})
			Util.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = b })
			local bar = Util.Create("Frame", {
				Name = "Bar",
				BackgroundColor3 = Theme.Get("Accent"),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(0, 4, 0, 16),
				Visible = false,
				Parent = b,
			})
			Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
			Util.Create("TextLabel", {
				Name = "T",
				Font = fontR(),
				TextSize = 13,
				TextColor3 = Theme.Get("Text"),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -16, 1, 0),
				Text = "",
				ZIndex = 103,
				Parent = b,
			})
			return b
		end)
		if ok and proto ~= nil then
			itemTemplate = proto
			return true
		end
		return false
	end
	local function makeItem(nameVal, index)
		local btn = nil
		if ensureTemplate() then
			btn = itemTemplate:Clone()
			btn.Name = nameVal
			btn.Visible = true
			btn.LayoutOrder = index
			btn.BackgroundTransparency = 1
			btn.Parent = scroll
		else
			btn = Util.Create("TextButton", {
				Name = nameVal,
				Text = "",
				AutoButtonColor = false,
				Size = UDim2.new(1, 0, 0, ITEM_H),
				BackgroundColor3 = Theme.Get("Card"),
				BackgroundTransparency = 1,
				LayoutOrder = index,
				ZIndex = 102,
				Parent = scroll,
			})
			Util.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
			local bar = Util.Create("Frame", {
				Name = "Bar",
				BackgroundColor3 = Theme.Get("Accent"),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(0, 4, 0, 16),
				Visible = false,
				Parent = btn,
			})
			Util.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
			Util.Create("TextLabel", {
				Name = "T",
				Font = fontR(),
				TextSize = 13,
				TextColor3 = Theme.Get("Text"),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -16, 1, 0),
				Text = nameVal,
				ZIndex = 103,
				Parent = btn,
			})
		end
		btn.LayoutOrder = index
		if btn.Parent ~= scroll then
			btn.Parent = scroll
		end
		local lbl = btn:FindFirstChild("T")
		if lbl then
			lbl.Text = nameVal
		end
		maid:Give(btn.MouseButton1Click:Connect(function()
			if not alive then
				return
			end
			if multi then
				if selectedLUT[nameVal] then
					selectedLUT[nameVal] = nil
				else
					selectedLUT[nameVal] = true
				end
			else
				singleValue = nameVal
				close()
			end
			paintBoxLabel()
			paintItems()
			fire()
		end))
		maid:Give(btn.MouseEnter:Connect(function()
			local selNow
			if multi then
				selNow = selectedLUT[nameVal] == true
			else
				selNow = (nameVal == singleValue)
			end
			if not selNow then
				Anim.Tween(btn, { BackgroundTransparency = 0.9 }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			end
		end))
		maid:Give(btn.MouseLeave:Connect(function()
			paintItems()
		end))
		return btn
	end

	local function rebuild()
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("TextButton") and child ~= itemTemplate then
				child:Destroy()
			end
		end
		ensureTemplate()
		for i, v in ipairs(values) do
			makeItem(v, i)
		end
		paintBoxLabel()
		paintItems()
	end

	obj.CloseIfOutside = function(input)
		if not open or not alive then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local pos = input.Position
		local function inside(gui)
			if gui == nil or not gui.Visible then
				return false
			end
			local ap = gui.AbsolutePosition
			local as = gui.AbsoluteSize
			return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
		end
		if not inside(listFrame) and not inside(box) then
			close()
		end
	end
	obj.Close = function()
		close()
	end

	maid:Give(box.MouseButton1Click:Connect(function()
		if alive then
			openList()
		end
	end))

	-- Kart hover 0.12 Quad
	maid:Give(card.MouseEnter:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = math.clamp(baseTrans - hoverChange, 0, 1) }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))
	maid:Give(card.MouseLeave:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = baseTrans }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))

	local function setSelection(v, silent)
		if multi then
			selectedLUT = {}
			if type(v) == "table" then
				-- Dizi mi ({A,B}) yoksa set mi ({A=true}) ayirt et
				local isArray = #v > 0
				if isArray then
					for _, item in ipairs(v) do
						local s = tostring(item)
						for _, opt in ipairs(values) do
							if opt == s then
								selectedLUT[s] = true
								break
							end
						end
					end
				else
					for k, on in pairs(v) do
						if on then
							local s = tostring(k)
							for _, opt in ipairs(values) do
								if opt == s then
									selectedLUT[s] = true
									break
								end
							end
						end
					end
				end
			elseif v ~= nil then
				local s = tostring(v)
				for _, opt in ipairs(values) do
					if opt == s then
						selectedLUT[s] = true
						break
					end
				end
			end
		else
			if v ~= nil then
				local s = tostring(v)
				for _, opt in ipairs(values) do
					if opt == s then
						singleValue = opt
						break
					end
				end
			end
		end
		paintBoxLabel()
		paintItems()
		if not silent then
			fire()
		else
			if flag ~= nil and flag ~= "" then
				local rec = Nova.Flags[flag]
				if rec then
					rec.CurrentValue = getValue()
				end
			end
		end
	end

	obj.Set = function(a, b, c)
		local v, silent
		if a == obj then
			v, silent = b, c
		else
			v, silent = a, b
		end
		setSelection(v, silent)
	end
	obj.Get = function()
		return getValue()
	end
	obj.Refresh = function(a, b)
		local newVals
		if a == obj then
			newVals = b
		else
			newVals = a
		end
		if type(newVals) ~= "table" then
			return obj
		end
		values = {}
		for _, v in ipairs(newVals) do
			table.insert(values, tostring(v))
		end
		if #values == 0 then
			values = { "Empty" }
		end
		-- Secimi buda
		if multi then
			for k, _ in pairs(selectedLUT) do
				local found = false
				for _, opt in ipairs(values) do
					if opt == k then
						found = true
						break
					end
				end
				if not found then
					selectedLUT[k] = nil
				end
			end
		else
			local found = false
			for _, opt in ipairs(values) do
				if opt == singleValue then
					found = true
					break
				end
			end
			if not found then
				singleValue = values[1]
			end
		end
		itemTemplate = nil
		rebuild()
		if open then
			placeList()
		end
		return obj
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
		if Nova._OpenDropdown == obj then
			Nova._OpenDropdown = nil
		end
		Nova._DropdownRegistry[obj] = nil
		maid:Cleanup()
		Anim.Cancel(card)
		Anim.Cancel(listFrame)
		Anim.Cancel(listScale)
		Anim.Cancel(chevron)
		if Nova.SearchIndex then
			Nova.SearchIndex[card] = nil
		end
		pcall(function()
			listFrame:Destroy()
		end)
		if card then
			card:Destroy()
		end
	end

	Nova._DropdownRegistry[obj] = true

	if flag ~= nil and flag ~= "" then
		Nova.Flags[flag] = {
			Type = "Dropdown",
			CurrentValue = getValue(),
			Get = function()
				return getValue()
			end,
			Set = function(v)
				setSelection(v)
			end,
		}
	end

	rebuild()
	return obj
end
