-- Nova UI :: Tab layer (concat-build: Nova/Util/Theme/Anim ust scope, require YOK)

local TweenService = game:GetService("TweenService")

local ACCENT = Color3.fromRGB(124, 108, 255)

local function GetFont(weight)
	local ok, res = pcall(function()
		return Util.GetFont(weight)
	end)
	if ok and res ~= nil then
		return res
	end
	if weight == "Bold" then
		return Enum.Font.GothamBold
	elseif weight == "Medium" then
		return Enum.Font.GothamMedium
	end
	return Enum.Font.Gotham
end

local function Tween(inst, info, props)
	-- info: TweenInfo, props: table. Anim.Tween(obj, props, time, style, dir) imzali.
	local time, style, dir = 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out
	pcall(function()
		time = info.Time
		style = info.EasingStyle
		dir = info.EasingDirection
	end)
	local ok, res = pcall(function()
		return Anim.Tween(inst, props, time, style, dir)
	end)
	if ok and res ~= nil then
		return res
	end
	local tw = TweenService:Create(inst, info, props)
	tw:Play()
	return tw
end

local function MoveSelector(window, button, animate)
	local sidebar = window.Sidebar
	local sel = window._Selector
	if not sidebar or not sel or not button then
		return
	end
	local ok, by, sy = pcall(function()
		return button.AbsolutePosition.Y, sidebar.AbsolutePosition.Y
	end)
	if not ok then
		return
	end
	local pos = UDim2.new(0, 2, 0, (by - sy) + 6)
	if animate then
		Tween(sel, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Position = pos })
	else
		sel.Position = pos
	end
end

local function CreateTab(window, name, icon)
	name = name or "Tab"
	local colors = window._Colors

	local Tab = {
		Window = window,
		Name = name,
		Sections = {},
		Selected = false,
	}

	-- Tab butonu: tam genislik x 34, radius 7
	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. name
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = colors.Element
	btn.BackgroundTransparency = 1
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.BorderSizePixel = 0
	btn.LayoutOrder = #window.Tabs + 1
	btn.Parent = window.TabHolder
	Tab.Button = btn
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 7)
	btnCorner.Parent = btn

	-- Icon: rbxassetid ise ImageLabel, yoksa ilk harf TextLabel (16px)
	local iconObj
	if type(icon) == "string" and string.find(icon, "rbxassetid", 1, true) then
		iconObj = Instance.new("ImageLabel")
		iconObj.Image = icon
		iconObj.ImageColor3 = colors.Text
	else
		iconObj = Instance.new("TextLabel")
		iconObj.BackgroundTransparency = 1
		iconObj.Text = (name ~= "" and string.upper(string.sub(name, 1, 1))) or "?"
		iconObj.TextSize = 12
		iconObj.Font = GetFont("Bold")
		iconObj.TextColor3 = ACCENT
	end
	iconObj.Name = "Icon"
	iconObj.Size = UDim2.new(0, 16, 0, 16)
	iconObj.Position = UDim2.new(0, 8, 0.5, -8)
	iconObj.BackgroundTransparency = 1
	iconObj.Parent = btn
	Tab.Icon = iconObj

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 30, 0, 0)
	label.Size = UDim2.new(1, -36, 1, 0)
	label.Text = name
	label.TextSize = 12
	label.Font = GetFont("Medium")
	label.TextColor3 = colors.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = btn
	Tab.Label = label

	-- Page: Container icinde duz ScrollingFrame
	local page = Instance.new("ScrollingFrame")
	page.Name = "Page_" .. name
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.Visible = false
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.ScrollBarThickness = 2
	page.ClipsDescendants = true
	page.Parent = window.Container
	Tab.Page = page
	local pagePad = Instance.new("UIPadding")
	pagePad.PaddingLeft = UDim.new(0, 8)
	pagePad.PaddingRight = UDim.new(0, 8)
	pagePad.PaddingTop = UDim.new(0, 8)
	pagePad.PaddingBottom = UDim.new(0, 8)
	pagePad.Parent = page
	local pageLayout = Instance.new("UIListLayout")
	pageLayout.FillDirection = Enum.FillDirection.Vertical
	pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pageLayout.Padding = UDim.new(0, 8)
	pageLayout.Parent = page

	function Tab:_ApplySelected(selected)
		self.Selected = selected
		local c = self.Window._Colors
		if selected then
			self.Button.BackgroundColor3 = ACCENT
			Tween(self.Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.85 })
		else
			self.Button.BackgroundColor3 = c.Element
			Tween(self.Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
		end
	end

	function Tab:Select()
		local win = self.Window
		for _, other in ipairs(win.Tabs) do
			if other ~= self and other.Selected then
				other:_ApplySelected(false)
			end
		end
		self:_ApplySelected(true)
		local prev = win._CurrentTab
		if prev ~= self then
			if prev and prev.Page then
				local oldPage = prev.Page
				Tween(oldPage, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, 6, 0, 0) })
				task.delay(0.15, function()
					if win._CurrentTab ~= prev then
						oldPage.Visible = false
						oldPage.Position = UDim2.new(0, 0, 0, 0)
					end
				end)
			end
			self.Page.Visible = true
			self.Page.Position = UDim2.new(0, -6, 0, 0)
			Tween(self.Page, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) })
			win._CurrentTab = self
		end
		win._Selector.Visible = true
		MoveSelector(win, self.Button, prev ~= nil)
		if prev == nil then
			task.defer(function()
				if win._CurrentTab == self then
					MoveSelector(win, self.Button, false)
				end
			end)
		end
	end

	function Tab:AddSection(sectionTitle)
		return Nova._CreateSection(self, sectionTitle)
	end

	function Tab:Refresh()
		local c = self.Window._Colors
		self.Button.BackgroundColor3 = self.Selected and ACCENT or c.Element
		self.Label.TextColor3 = c.Text
		if self.Icon:IsA("ImageLabel") then
			self.Icon.ImageColor3 = c.Text
		end
	end

	table.insert(window._RefreshFns, function()
		Tab:Refresh()
	end)

	table.insert(window._Conns, btn.MouseEnter:Connect(function()
		if not Tab.Selected then
			Tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.88 })
		end
	end))
	table.insert(window._Conns, btn.MouseLeave:Connect(function()
		if not Tab.Selected then
			Tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
		end
	end))
	table.insert(window._Conns, btn.MouseButton1Click:Connect(function()
		Tab:Select()
	end))

	if not window._ScrollTracked then
		window._ScrollTracked = true
		table.insert(window._Conns, window.TabHolder:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if window._CurrentTab then
				MoveSelector(window, window._CurrentTab.Button, false)
			end
		end))
	end

	return Tab
end

Nova._CreateTab = CreateTab
Nova._Tab = CreateTab
