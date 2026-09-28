-- Nova UI :: Window layer (concat-build: Nova/Util/Theme/Anim ust scope, require YOK)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local ACCENT = Color3.fromRGB(124, 108, 255)
local MIN_W, MIN_H = 470, 380

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

local function GetColors(themeName)
	local base = {
		Card = Color3.fromRGB(40, 40, 48),
		Element = Color3.fromRGB(52, 52, 63),
		ElementBorder = Color3.fromRGB(255, 255, 255),
		SubText = Color3.fromRGB(160, 160, 175),
		Text = Color3.fromRGB(235, 235, 242),
	}
	local src = nil
	if type(Theme) == "table" then
		-- Gercek sema: Theme.Tokens.Dark / Theme.Get(key)
		if type(themeName) == "string" and type(Theme.Tokens) == "table" and type(Theme.Tokens[themeName]) == "table" then
			src = Theme.Tokens[themeName]
		elseif type(Theme.Get) == "function" then
			for k, _ in pairs(base) do
				local ok, v = pcall(Theme.Get, k)
				if ok and typeof(v) == "Color3" then
					base[k] = v
				end
			end
			return base
		elseif type(themeName) == "string" and type(Theme[themeName]) == "table" then
			src = Theme[themeName]
		elseif type(Theme.Current) == "table" then
			src = Theme.Current
		elseif Theme.Card ~= nil then
			src = Theme
		end
	end
	if type(src) == "table" then
		for k, v in pairs(base) do
			if typeof(src[k]) == "Color3" then
				base[k] = src[k]
			end
		end
	end
	return base
end

local function FrostColor(card)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, card),
		ColorSequenceKeypoint.new(1, card:Lerp(Color3.new(0, 0, 0), 0.15)),
	})
end

local function Tween(inst, info, props)
	-- info: TweenInfo, props: table. Once Anim.Tween(obj, props, time, style, dir) imzali.
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

local function Notify(title, msg)
	pcall(function()
		Nova.Notify(title, msg)
	end)
end

local function Corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
	return c
end

local function Stroke(parent, color, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Transparency = transparency == nil and 0.5 or transparency
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function CreateWindow(config)
	config = config or {}
	local title = config.Title or "Nova"
	local subTitle = config.SubTitle or "v1.0"
	-- Size: UDim2.fromOffset beklenir, Vector2 verilirse tolere et
	local size = config.Size or UDim2.fromOffset(580, 460)
	if typeof(size) == "Vector2" then
		size = UDim2.fromOffset(size.X, size.Y)
	elseif typeof(size) ~= "UDim" then
		size = UDim2.fromOffset(580, 460)
	end
	local tabWidth = config.TabWidth or 170
	local themeName = config.Theme or "Dark"
	local minimizeKey = config.MinimizeKey or Enum.KeyCode.LeftControl
	local colors = GetColors(themeName)

	local vw, vh = 1280, 720
	pcall(function()
		vw = workspace.CurrentCamera.ViewportSize.X
		vh = workspace.CurrentCamera.ViewportSize.Y
	end)
	local w = math.clamp(size.X.Offset, MIN_W, math.max(MIN_W, vw - 40))
	local h = math.clamp(size.Y.Offset, MIN_H, math.max(MIN_H, vh - 40))

	local gui = nil
	local okGui, guiRes = pcall(function()
		return Util.MakeScreenGui("Nova")
	end)
	if okGui and typeof(guiRes) == "Instance" then
		gui = guiRes
	else
		gui = Instance.new("ScreenGui")
		gui.Name = "Nova"
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.DisplayOrder = 10
		pcall(function()
			gui.Parent = game:GetService("CoreGui")
		end)
		if gui.Parent == nil then
			gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		end
	end

	local Window = {
		Title = title,
		SubTitle = subTitle,
		Theme = themeName,
		Tabs = {},
		SearchIndex = {},
		_Colors = colors,
		_RefreshFns = {},
		_Conns = {},
		_CurrentTab = nil,
		_TargetScale = 1,
		_Destroyed = false,
		Gui = gui,
	}
	local function Track(conn)
		table.insert(Window._Conns, conn)
		return conn
	end

	-- Root CanvasGroup (fade icin) -> Main (kart)
	local root = Instance.new("CanvasGroup")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.GroupTransparency = 1
	root.Parent = gui
	Window.Root = root

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(w, h)
	main.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
	main.BackgroundColor3 = colors.Card
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Parent = root
	Window.Main = main
	Corner(main, 10)
	local mainStroke = Stroke(main, colors.ElementBorder, 0.5)
	local frost = Instance.new("UIGradient")
	frost.Color = FrostColor(colors.Card)
	frost.Rotation = 90
	frost.Parent = main
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = main

	-- TitleBar 44px
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 44)
	titleBar.BackgroundTransparency = 1
	titleBar.Active = true
	titleBar.Parent = main

	local titleLeft = Instance.new("Frame")
	titleLeft.Size = UDim2.new(1, -170, 1, 0)
	titleLeft.Position = UDim2.fromOffset(14, 0)
	titleLeft.BackgroundTransparency = 1
	titleLeft.Parent = titleBar
	local titleLayout = Instance.new("UIListLayout")
	titleLayout.FillDirection = Enum.FillDirection.Horizontal
	titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	titleLayout.Padding = UDim.new(0, 6)
	titleLayout.Parent = titleLeft

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(0, 0, 0, 20)
	titleLabel.AutomaticSize = Enum.AutomaticSize.X
	titleLabel.Text = title
	titleLabel.TextSize = 13
	titleLabel.Font = GetFont("Bold")
	titleLabel.TextColor3 = colors.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleLeft

	local subLabel = Instance.new("TextLabel")
	subLabel.BackgroundTransparency = 1
	subLabel.Size = UDim2.new(0, 0, 0, 20)
	subLabel.AutomaticSize = Enum.AutomaticSize.X
	subLabel.Text = subTitle
	subLabel.TextSize = 12
	subLabel.Font = GetFont("Regular")
	subLabel.TextColor3 = colors.SubText
	subLabel.TextXAlignment = Enum.TextXAlignment.Left
	subLabel.Parent = titleLeft

	local btnBox = Instance.new("Frame")
	btnBox.Size = UDim2.new(0, 68, 0, 30)
	btnBox.Position = UDim2.new(1, -76, 0, 7)
	btnBox.BackgroundTransparency = 1
	btnBox.Parent = titleBar
	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnLayout.Padding = UDim.new(0, 4)
	btnLayout.Parent = btnBox

	local function TitleButton(text)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(30, 30)
		b.BackgroundColor3 = colors.Element
		b.BackgroundTransparency = 1
		b.AutoButtonColor = false
		b.Text = text
		b.TextSize = 13
		b.Font = GetFont("Bold")
		b.TextColor3 = colors.SubText
		b.Parent = btnBox
		Corner(b, 7)
		Track(b.MouseEnter:Connect(function()
			Tween(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.7 })
		end))
		Track(b.MouseLeave:Connect(function()
			Tween(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
		end))
		return b
	end
	local minBtn = TitleButton("-")
	local closeBtn = TitleButton("X")

	-- Icerik: Sidebar (sol) + Container (sag)
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.new(0, 0, 0, 44)
	content.Size = UDim2.new(1, 0, 1, -44)
	content.BackgroundTransparency = 1
	content.Parent = main

	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, tabWidth, 1, 0)
	sidebar.BackgroundTransparency = 1
	sidebar.ClipsDescendants = true
	sidebar.Parent = content
	Window.Sidebar = sidebar

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchBox"
	searchBox.Position = UDim2.new(0, 8, 0, 6)
	searchBox.Size = UDim2.new(1, -16, 0, 30)
	searchBox.BackgroundColor3 = colors.Element
	searchBox.Text = ""
	searchBox.PlaceholderText = "Search..."
	searchBox.PlaceholderColor3 = colors.SubText
	searchBox.TextSize = 12
	searchBox.Font = GetFont("Regular")
	searchBox.TextColor3 = colors.Text
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.BorderSizePixel = 0
	searchBox.Parent = sidebar
	Corner(searchBox, 7)
	local searchStroke = Stroke(searchBox, colors.ElementBorder, 0.7)
	local searchPad = Instance.new("UIPadding")
	searchPad.PaddingLeft = UDim.new(0, 10)
	searchPad.PaddingRight = UDim.new(0, 10)
	searchPad.Parent = searchBox
	Window.SearchBox = searchBox

	local tabHolder = Instance.new("ScrollingFrame")
	tabHolder.Name = "TabHolder"
	tabHolder.Position = UDim2.new(0, 8, 0, 42)
	tabHolder.Size = UDim2.new(1, -16, 1, -48)
	tabHolder.BackgroundTransparency = 1
	tabHolder.BorderSizePixel = 0
	tabHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tabHolder.ScrollingDirection = Enum.ScrollingDirection.Y
	tabHolder.ScrollBarThickness = 2
	tabHolder.Parent = sidebar
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Vertical
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 4)
	tabLayout.Parent = tabHolder
	Window.TabHolder = tabHolder

	local selector = Instance.new("Frame")
	selector.Name = "Selector"
	selector.Size = UDim2.new(0, 4, 0, 22)
	selector.Position = UDim2.new(0, 2, 0, 8)
	selector.BackgroundColor3 = ACCENT
	selector.BorderSizePixel = 0
	selector.Visible = false
	selector.Parent = sidebar
	Corner(selector, 2)
	Window._Selector = selector

	local vline = Instance.new("Frame")
	vline.Size = UDim2.new(0, 1, 1, -16)
	vline.Position = UDim2.new(0, tabWidth, 0, 8)
	vline.BackgroundColor3 = colors.SubText
	vline.BackgroundTransparency = 0.8
	vline.BorderSizePixel = 0
	vline.Parent = content

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Position = UDim2.new(0, tabWidth + 1, 0, 6)
	container.Size = UDim2.new(1, -tabWidth - 9, 1, -12)
	container.BackgroundTransparency = 1
	container.ClipsDescendants = true
	container.Parent = content
	Window.Container = container

	-- Resize tutamac (sag-alt, min 470x380 clamp)
	local mouse = Players.LocalPlayer:GetMouse()
	local grip = Instance.new("TextButton")
	grip.Name = "ResizeGrip"
	grip.Size = UDim2.fromOffset(20, 20)
	grip.Position = UDim2.new(1, -20, 1, -20)
	grip.BackgroundTransparency = 1
	grip.AutoButtonColor = false
	grip.Text = ""
	grip.Parent = main
	for i, len in ipairs({ 12, 8, 4 }) do
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(1, 1)
		line.Size = UDim2.new(0, len, 0, 1)
		line.Position = UDim2.new(1, -3, 1, -3 - (i - 1) * 4)
		line.Rotation = 45
		line.BackgroundColor3 = colors.SubText
		line.BackgroundTransparency = 0.3
		line.BorderSizePixel = 0
		line.Parent = grip
	end
	local resizing = false
	Track(grip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
		end
	end))
	Track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end))
	Track(UserInputService.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local nw = math.clamp(mouse.X - main.AbsolutePosition.X, MIN_W, 4096)
			local nh = math.clamp(mouse.Y - main.AbsolutePosition.Y, MIN_H, 4096)
			main.Size = UDim2.fromOffset(nw, nh)
		end
	end))

	-- Surukleme
	local dragOk = pcall(function()
		Util.Drag(main, titleBar)
	end)
	if not dragOk then
		local dragging = false
		local sx, sy, ox, oy = 0, 0, 0, 0
		Track(titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				sx, sy = mouse.X, mouse.Y
				ox, oy = main.Position.X.Offset, main.Position.Y.Offset
			end
		end))
		Track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end))
		Track(UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				main.Position = UDim2.new(0.5, ox + (mouse.X - sx), 0.5, oy + (mouse.Y - sy))
			end
		end))
	end

	-- Minimize / Close
	local function ToggleVisible()
		root.Visible = not root.Visible
		Notify(title, root.Visible and "Window restored" or "Window minimized")
	end
	Track(minBtn.MouseButton1Click:Connect(ToggleVisible))
	Track(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end
		if input.KeyCode == minimizeKey then
			ToggleVisible()
		end
	end))
	Track(closeBtn.MouseButton1Click:Connect(function()
		local ok = pcall(function()
			return Nova.Unload()
		end)
		if not ok then
			Window:Destroy()
		end
	end))

	-- Search: sadece filtre, otomatik tab gecisi YOK (olu kayitlara karsi pcall'li)
	Track(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = string.lower(searchBox.Text)
		for _, entry in ipairs(Window.SearchIndex) do
			pcall(function()
				if q == "" then
					entry.Frame.Visible = true
				else
					entry.Frame.Visible = string.find(entry.Title or "", q, 1, true) ~= nil
				end
			end)
		end
	end))

	-- Responsive UIScale
	local function UpdateScale()
		local cam = workspace.CurrentCamera
		local x = (cam and cam.ViewportSize.X) or 1280
		Window._TargetScale = math.clamp(x / 1280, 0.7, 1)
		uiScale.Scale = Window._TargetScale
	end
	UpdateScale()
	local camNow = workspace.CurrentCamera
	if camNow then
		Track(camNow:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale))
	end

	function Window:AddTab(name, icon)
		local tab = Nova._CreateTab(self, name, icon)
		table.insert(self.Tabs, tab)
		if #self.Tabs == 1 then
			tab:Select()
		end
		return tab
	end

	function Window:SetTheme(name)
		self.Theme = name
		self._Colors = GetColors(name)
		local c = self._Colors
		main.BackgroundColor3 = c.Card
		frost.Color = FrostColor(c.Card)
		mainStroke.Color = c.ElementBorder
		titleLabel.TextColor3 = c.Text
		subLabel.TextColor3 = c.SubText
		searchBox.BackgroundColor3 = c.Element
		searchBox.TextColor3 = c.Text
		searchBox.PlaceholderColor3 = c.SubText
		searchStroke.Color = c.ElementBorder
		vline.BackgroundColor3 = c.SubText
		if type(Theme) == "table" and type(Theme.Apply) == "function" then
			pcall(function()
				Theme.Apply(name)
			end)
		elseif type(Theme) == "table" and type(Theme.Set) == "function" then
			pcall(function()
				Theme.Set(name)
			end)
		end
		for _, fn in ipairs(self._RefreshFns) do
			pcall(fn)
		end
	end

	function Window:Destroy()
		if self._Destroyed then
			return
		end
		self._Destroyed = true
		Tween(root, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 1 })
		Tween(uiScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = (self._TargetScale or 1) * 0.95 })
		task.delay(0.2, function()
			for _, c in ipairs(self._Conns) do
				pcall(function()
					c:Disconnect()
				end)
			end
			pcall(function()
				gui:Destroy()
			end)
		end)
	end

	-- Acilis: 0.35 Back (fade + scale)
	local target = Window._TargetScale
	uiScale.Scale = target * 0.95
	Tween(root, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { GroupTransparency = 0 })
	Tween(uiScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = target })

	return Window
end

Nova.CreateWindow = CreateWindow
