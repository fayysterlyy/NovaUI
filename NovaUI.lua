-- NovaUI v1.0.0 | built 2026-09-28 | loadstring ile kullan
-- Concat-build tek dosya: require() YOK. Dosyalar ust scope'taki
-- Nova / Util / Theme / Anim lokallerine yazar.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Nova = { Flags = {}, Toggles = {}, Options = {}, SearchIndex = {}, _KeybindInput = nil }
local Util, Theme, Anim


-- Module: src/Util.lua
-- Nova UI | Util (CORE): instance, maid, parent, callback, drag, ripple, font.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

-- Instance.new + pcall set; Parent en son atanir (duz property, helper yok).
local function Create(className, props, parent)
	local inst = Instance.new(className)
	if props ~= nil then
		for key, value in pairs(props) do
			if key ~= "Parent" then
				pcall(function() inst[key] = value end)
			end
		end
	end
	local target = parent or (props and props.Parent)
	if target ~= nil then
		pcall(function() inst.Parent = target end)
	end
	return inst
end

-- Mini Maid: connection / instance / function / thread toplar.
local function MaidNew()
	local self = { Tasks = {} }
	function self:Give(task)
		table.insert(self.Tasks, task)
		return task
	end
	function self:Cleanup()
		for _, task in ipairs(self.Tasks) do
			pcall(function()
				local kind = typeof(task)
				if kind == "RBXScriptConnection" then task:Disconnect()
				elseif kind == "Instance" then task:Destroy()
				elseif kind == "function" then task()
				elseif kind == "thread" then coroutine.close(task)
				elseif kind == "table" then
					if typeof(task.Disconnect) == "function" then task:Disconnect()
					elseif typeof(task.Destroy) == "function" then task:Destroy()
					elseif typeof(task.Cancel) == "function" then task:Cancel() end
				end
			end)
		end
		table.clear(self.Tasks)
	end
	return self
end

-- gethui -> get_hidden_gui -> CoreGui -> PlayerGui (hepsi pcall'li).
local function GetParent()
	for _, fn in ipairs({ gethui, get_hidden_gui }) do
		local ok, gui = pcall(function()
			if typeof(fn) == "function" then return fn() end
			return nil
		end)
		if ok and gui ~= nil then return gui end
	end
	local ok, core = pcall(function() return game:GetService("CoreGui") end)
	if ok and core ~= nil then return core end
	local fallback = nil -- son care: PlayerGui
	pcall(function()
		local lp = Players.LocalPlayer
		if lp then fallback = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5) end
	end)
	return fallback
end

-- Standart Nova ScreenGui'si; parent otomatik cozulur.
local function MakeScreenGui(name)
	local gui = Create("ScreenGui", {
		Name = name or "NovaUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	pcall(function() gui.Parent = GetParent() end)
	return gui
end

-- pcall wrapper: hata varsa warn + false, yoksa true (+ donus degerleri).
local function SafeCallback(fn, ...)
	if typeof(fn) ~= "function" then return false end
	local packed = table.pack(pcall(fn, ...))
	if packed[1] ~= true then
		warn("[Nova] callback error:", packed[2])
		return false
	end
	return true, table.unpack(packed, 2, packed.n)
end

-- Mouse + touch surukleme; baglantilar Maid'de tutulur, maid doner.
local function Drag(frame, handle)
	local maid = MaidNew()
	local target = handle or frame
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
	maid:Give(target.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, input.Position, frame.Position
		end
	end))
	maid:Give(UserInputService.InputChanged:Connect(function(input)
		local t = input.UserInputType
		if dragging and (t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch) then dragInput = input end
		if dragging and input == dragInput and dragStart ~= nil and startPos ~= nil then
			local d = input.Position - dragStart
			pcall(function()
				frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end)
		end
	end))
	maid:Give(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, dragInput = false, nil
		end
	end))
	return maid
end

-- Tiklanan noktadan buyuyen daire (0.35sn); asset yok, UICorner(1,0) + Background.
local function Ripple(button, color)
	if typeof(button) ~= "Instance" or not button:IsA("GuiObject") then return end
	pcall(function() button.ClipsDescendants = true end)
	local absPos, absSize = button.AbsolutePosition, button.AbsoluteSize
	local mouse = UserInputService:GetMouseLocation()
	local origin = Vector2.new(mouse.X - absPos.X, mouse.Y - absPos.Y)
	if origin.X < 0 or origin.Y < 0 or origin.X > absSize.X or origin.Y > absSize.Y then
		origin = absSize * 0.5 -- touch -> merkez
	end
	local circle = Create("ImageLabel", {
		Name = "NovaRipple", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(math.floor(origin.X), math.floor(origin.Y)),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = color or Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.75,
		BorderSizePixel = 0, Image = "", ImageTransparency = 1, ZIndex = button.ZIndex + 1,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0) }, circle)
	pcall(function() circle.Parent = button end)
	local diameter = math.max(absSize.X, absSize.Y)
	local ok, tween = pcall(function()
		return TweenService:Create(circle, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(diameter * 2.5, diameter * 2.5), BackgroundTransparency = 1,
		})
	end)
	if ok and tween ~= nil then
		tween.Completed:Once(function()
			pcall(function() circle:Destroy() end)
			pcall(function() tween:Destroy() end)
		end)
		tween:Play()
	else
		pcall(function() circle:Destroy() end)
	end
end

-- Montserrat varsa onu, yoksa Gotham ailesini doner.
-- bold: true/false veya "Bold"/"Medium"/"Regular" string kabul eder.
local function GetFont(bold)
	local wantBold = bold == true or bold == "Bold"
	local ok, result = pcall(function()
		return wantBold and Enum.Font.MontserratBold or Enum.Font.Montserrat
	end)
	if ok and result ~= nil then return result end
	return wantBold and Enum.Font.GothamBold or Enum.Font.Gotham
end

local function Clamp(value, minValue, maxValue)
	return math.clamp(value, minValue, maxValue)
end

-- Cagrilari aralikla kisitlayan wrapper (spam koruma).
local function Debounce(fn, waitTime)
	waitTime = waitTime or 0.5
	local lastCall = 0
	return function(...)
		local now = os.clock()
		if now - lastCall >= waitTime then
			lastCall = now
			return fn(...)
		end
	end
end

Util = {
	Create = Create, MaidNew = MaidNew, GetParent = GetParent,
	MakeScreenGui = MakeScreenGui, SafeCallback = SafeCallback,
	Drag = Drag, Ripple = Ripple, GetFont = GetFont,
	Clamp = Clamp, Debounce = Debounce,
}


-- Module: src/Theme.lua
-- Nova UI | Theme (CORE)
-- Token tablosu + registry ile anlik tema degisimi (renk tweenlenmez, direkt set).

local Tokens = {
	Dark = {
		Accent = Color3.fromRGB(124, 108, 255),
		AccentDark = Color3.fromRGB(96, 80, 220),
		Text = Color3.fromRGB(240, 240, 240),
		SubText = Color3.fromRGB(170, 170, 170),
		Background = Color3.fromRGB(28, 28, 32),
		Sidebar = Color3.fromRGB(34, 34, 40),
		Card = Color3.fromRGB(40, 40, 48),
		Dialog = Color3.fromRGB(45, 45, 52),
		Element = Color3.fromRGB(120, 120, 120),
		ElementTrans = 0.87,
		ElementBorder = Color3.fromRGB(55, 55, 65),
		InBorder = Color3.fromRGB(90, 90, 90),
		HoverChange = 0.07,
		RadiusCard = 10,
		RadiusInner = 7,
	},
	Light = {
		Accent = Color3.fromRGB(124, 108, 255),
		AccentDark = Color3.fromRGB(96, 80, 220),
		Text = Color3.fromRGB(20, 20, 20),
		SubText = Color3.fromRGB(110, 110, 115),
		Background = Color3.fromRGB(245, 245, 247),
		Sidebar = Color3.fromRGB(235, 235, 240),
		Card = Color3.fromRGB(255, 255, 255),
		Dialog = Color3.fromRGB(250, 250, 252),
		Element = Color3.fromRGB(120, 120, 120),
		ElementTrans = 0.87,
		ElementBorder = Color3.fromRGB(220, 220, 228),
		InBorder = Color3.fromRGB(200, 200, 205),
		HoverChange = 0.07,
		RadiusCard = 10,
		RadiusInner = 7,
	},
}

local Current = "Dark" -- aktif tema adi
local Registry = {} -- { { inst=..., prop="BackgroundColor3", key="Card" } }
local OnChanged = {} -- tema degisince cagrilan callback listesi

-- Aktif temadan tek token okur.
local function Get(key)
	local set = Tokens[Current]
	if set == nil then
		return nil
	end
	return set[key]
end

-- map ornegi: { BackgroundColor3 = "Card", TextColor3 = "Text" }
local function Register(inst, map)
	if typeof(inst) ~= "Instance" or typeof(map) ~= "table" then
		return
	end
	for prop, key in pairs(map) do
		table.insert(Registry, { inst = inst, prop = prop, key = key })
		local value = Get(key) -- yeni kaydi mevcut temayla anlik boya
		if value ~= nil then
			pcall(function()
				inst[prop] = value
			end)
		end
	end
end

-- Bir instance'in tum kayitlarini dusur (Maid cleanup ile cagir).
local function Unregister(inst)
	for i = #Registry, 1, -1 do
		if Registry[i].inst == inst then
			table.remove(Registry, i)
		end
	end
end

-- Tum registry'yi yeni temaya anlik cevirir + dinleyicilere haber verir.
local function Apply(name)
	if Tokens[name] == nil then
		warn("[Nova] unknown theme:", tostring(name))
		return
	end
	Current = name
	Theme.Current = name -- public tabloyu senkron tut
	for i = #Registry, 1, -1 do
		local entry = Registry[i]
		if typeof(entry.inst) ~= "Instance" then
			table.remove(Registry, i) -- olu kayitlari temizle
		else
			local value = Tokens[name][entry.key]
			if value ~= nil then
				pcall(function()
					entry.inst[entry.prop] = value
				end)
			end
		end
	end
	for _, cb in ipairs(OnChanged) do
		pcall(cb, name) -- dinleyici hatasi temayi bozmaz
	end
end

Theme = {
	Tokens = Tokens,
	Current = Current,
	Registry = Registry,
	OnChanged = OnChanged,
	Register = Register,
	Unregister = Unregister,
	Apply = Apply,
	Get = Get,
}


-- Module: src/Anim.lua
-- Nova UI | Anim (CORE)
-- Tek merkezden tween yonetimi: cakisma onleme + reduced-motion destegi.

local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Active = {} -- [guiObject] = tween

-- Kullanicinin "hareket azalt" tercihi aciksa animasyonlar kapatilir.
local function ReducedMotion()
	local ok, value = pcall(function()
		return GuiService.ReducedMotionEnabled
	end)
	return ok and value == true
end

-- Obje uzerindeki aktif tween'i durdurup yok eder.
local function Cancel(obj)
	local old = Active[obj]
	if old ~= nil then
		Active[obj] = nil
		pcall(function() old:Cancel() end)
		pcall(function() old:Destroy() end)
	end
end

-- Tum aktif tween'leri durdurur (pencere kapanirken cagir).
local function CancelAll()
	for obj, _ in pairs(Active) do
		Cancel(obj)
	end
end

-- string ("Quad") veya Enum kabul eder, gecersizse varsayilana duser.
local function NormStyle(style)
	if typeof(style) == "string" then
		return Enum.EasingStyle[style] or Enum.EasingStyle.Quad
	end
	return style or Enum.EasingStyle.Quad
end

local function NormDir(dir)
	if typeof(dir) == "string" then
		return Enum.EasingDirection[dir] or Enum.EasingDirection.Out
	end
	return dir or Enum.EasingDirection.Out
end

-- Eski tween varsa Cancel eder, yenisini baslatir, bitince Destroy eder.
local function Tween(obj, props, time, style, dir)
	if typeof(obj) ~= "Instance" or typeof(props) ~= "table" then
		return nil
	end
	Cancel(obj)
	time = time or 0.2
	if ReducedMotion() then
		time = 0
	end
	local info = TweenInfo.new(time, NormStyle(style), NormDir(dir))
	local tween = nil
	local ok = pcall(function()
		tween = TweenService:Create(obj, info, props)
	end)
	if not ok or tween == nil then
		pcall(function() -- fallback: degerleri anlik yaz
			for key, value in pairs(props) do
				obj[key] = value
			end
		end)
		return nil
	end
	Active[obj] = tween
	tween.Completed:Once(function()
		if Active[obj] == tween then
			Active[obj] = nil
		end
		pcall(function() tween:Destroy() end)
	end)
	tween:Play()
	return tween
end

Anim = {
	Active = Active,
	Tween = Tween,
	Cancel = Cancel,
	CancelAll = CancelAll,
}


-- Module: src/Components/Window.lua
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


-- Module: src/Components/Tab.lua
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


-- Module: src/Components/Section.lua
-- Nova UI :: Section layer (concat-build: Nova/Util/Theme/Anim ust scope, require YOK)
-- AddToggle/AddButton/... burada TANIMLANMAZ (Init.lua baglar); AddElementCard ElementRoot dondurur.

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

local function CreateSection(tab, title)
	title = title or "Section"
	local window = tab.Window
	local colors = window._Colors

	local Section = {
		Title = title,
		Tab = tab,
		Window = window,
		_Cards = 0,
	}

	-- Kart: radius 10, Card bg + stroke, padding 12
	local frame = Instance.new("Frame")
	frame.Name = "Section_" .. title
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundColor3 = colors.Card
	frame.BorderSizePixel = 0
	frame.LayoutOrder = #tab.Sections + 1
	frame.Parent = tab.Page
	Section.Frame = frame
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 10)
	frameCorner.Parent = frame
	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = colors.ElementBorder
	frameStroke.Transparency = 0.6
	frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	frameStroke.Parent = frame
	local framePad = Instance.new("UIPadding")
	framePad.PaddingLeft = UDim.new(0, 12)
	framePad.PaddingRight = UDim.new(0, 12)
	framePad.PaddingTop = UDim.new(0, 12)
	framePad.PaddingBottom = UDim.new(0, 12)
	framePad.Parent = frame
	local frameLayout = Instance.new("UIListLayout")
	frameLayout.FillDirection = Enum.FillDirection.Vertical
	frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
	frameLayout.Padding = UDim.new(0, 6)
	frameLayout.Parent = frame

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "SectionTitle"
	titleLbl.BackgroundTransparency = 1
	titleLbl.Size = UDim2.new(1, 0, 0, 18)
	titleLbl.LayoutOrder = 1
	titleLbl.Text = title
	titleLbl.TextSize = 13
	titleLbl.Font = GetFont("Bold")
	titleLbl.TextColor3 = colors.Text
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = frame

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.LayoutOrder = 2
	divider.BackgroundColor3 = colors.SubText
	divider.BackgroundTransparency = 0.8
	divider.BorderSizePixel = 0
	divider.Parent = frame

	function Section:AddElementCard(cardTitle, desc)
		cardTitle = cardTitle or ""
		desc = desc or ""
		self._Cards = self._Cards + 1

		local card = Instance.new("Frame")
		card.Name = "Card_" .. cardTitle
		card.Size = UDim2.new(1, 0, 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = window._Colors.Element
		card.BorderSizePixel = 0
		card.LayoutOrder = 2 + self._Cards
		card.Parent = frame
		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 7)
		cardCorner.Parent = card
		local cardPad = Instance.new("UIPadding")
		cardPad.PaddingLeft = UDim.new(0, 10)
		cardPad.PaddingRight = UDim.new(0, 10)
		cardPad.PaddingTop = UDim.new(0, 10)
		cardPad.PaddingBottom = UDim.new(0, 10)
		cardPad.Parent = card
		local cardLayout = Instance.new("UIListLayout")
		cardLayout.FillDirection = Enum.FillDirection.Vertical
		cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
		cardLayout.Padding = UDim.new(0, 6)
		cardLayout.Parent = card

		local cardTitleLbl = Instance.new("TextLabel")
		cardTitleLbl.Name = "CardTitle"
		cardTitleLbl.BackgroundTransparency = 1
		cardTitleLbl.Size = UDim2.new(1, 0, 0, 16)
		cardTitleLbl.LayoutOrder = 1
		cardTitleLbl.Text = cardTitle
		cardTitleLbl.TextSize = 13
		cardTitleLbl.Font = GetFont("Medium")
		cardTitleLbl.TextColor3 = window._Colors.Text
		cardTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
		cardTitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
		cardTitleLbl.Parent = card

		local descLbl = nil
		if desc ~= "" then
			descLbl = Instance.new("TextLabel")
			descLbl.Name = "CardDesc"
			descLbl.BackgroundTransparency = 1
			descLbl.Size = UDim2.new(1, 0, 0, 0)
			descLbl.AutomaticSize = Enum.AutomaticSize.Y
			descLbl.LayoutOrder = 2
			descLbl.Text = desc
			descLbl.TextSize = 12
			descLbl.Font = GetFont("Regular")
			descLbl.TextColor3 = window._Colors.SubText
			descLbl.TextXAlignment = Enum.TextXAlignment.Left
			descLbl.TextWrapped = true
			descLbl.Parent = card
		end

		table.insert(window.SearchIndex, { Frame = card, Title = string.lower(cardTitle) })
		table.insert(window._RefreshFns, function()
			local c = window._Colors
			card.BackgroundColor3 = c.Element
			cardTitleLbl.TextColor3 = c.Text
			if descLbl then
				descLbl.TextColor3 = c.SubText
			end
		end)

		return card
	end

	table.insert(tab.Sections, Section)
	table.insert(window._RefreshFns, function()
		local c = window._Colors
		frame.BackgroundColor3 = c.Card
		frameStroke.Color = c.ElementBorder
		titleLbl.TextColor3 = c.Text
		divider.BackgroundColor3 = c.SubText
	end)

	-- Element metodlarini bagla (Init.lua yuklendiyse; concat sirasi yuzunden pcall'li)
	pcall(function()
		if Nova._BindSection then
			Nova._BindSection(Section)
		end
	end)

	return Section
end

Nova._CreateSection = CreateSection
Nova._Section = CreateSection


-- Module: src/Elements/Toggle.lua
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


-- Module: src/Elements/Button.lua
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


-- Module: src/Elements/Label.lua
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


-- Module: src/Elements/Slider.lua
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


-- Module: src/Elements/Input.lua
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


-- Module: src/Elements/Dropdown.lua
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


-- Module: src/Elements/ColorPicker.lua
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


-- Module: src/Elements/Keybind.lua
-- Nova UI - Keybind Element
-- Concat-build: require YOK. Ust scope Nova, Util, Theme, Anim hazir.
-- Uretir: Nova._AddKeybind(section, flag, opts)
-- opts = { Default=Enum.KeyCode.E veya "E", Mode="Toggle" (Always/Toggle/Hold), Callback=function(state), ChangedCallback }

Nova._AddKeybind = function(section, flag, opts)
	opts = opts or {}
	local title = opts.Text or "Keybind"
	local desc = opts.Desc or ""
	local callback = opts.Callback
	local changedCallback = opts.ChangedCallback

	local modeOrder = { "Always", "Toggle", "Hold" }
	local mode = opts.Mode or "Toggle"
	do
		local ok = false
		for _, m in ipairs(modeOrder) do
			if m == mode then
				ok = true
				break
			end
		end
		if not ok then
			mode = "Toggle"
		end
	end

	local card = section:AddElementCard(title, desc)
	Nova.Flags = Nova.Flags or {}

	local maid = Util.MaidNew()
	local listeners = {} -- state dinleyicileri (OnChanged)
	local clickListeners = {} -- OnClick: tusa basildiginda
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

	-- Key <-> isim donusumleri
	local function keyToName(key)
		if typeof(key) == "EnumItem" then
			local nm = key.Name
			if nm == "MouseButton1" then
				return "MB1"
			elseif nm == "MouseButton2" then
				return "MB2"
			elseif nm == "MouseButton3" then
				return "MB3"
			end
			return nm
		end
		return tostring(key)
	end

	local function nameToKey(name)
		if typeof(name) == "EnumItem" then
			return name
		end
		name = tostring(name)
		if name == "MB1" or name == "MouseButton1" then
			return Enum.UserInputType.MouseButton1
		elseif name == "MB2" or name == "MouseButton2" then
			return Enum.UserInputType.MouseButton2
		elseif name == "MB3" or name == "MouseButton3" then
			return Enum.UserInputType.MouseButton3
		end
		local ok, kc = pcall(function()
			return Enum.KeyCode[name]
		end)
		if ok and kc ~= nil and typeof(kc) == "EnumItem" then
			return kc
		end
		local ok2, ut = pcall(function()
			return Enum.UserInputType[name]
		end)
		if ok2 and ut ~= nil and typeof(ut) == "EnumItem" then
			return ut
		end
		return nil
	end

	local bound = nameToKey(opts.Default)
	if bound == nil then
		bound = Enum.KeyCode.E
	end
	local state = (mode == "Always")
	local picking = false

	-- Alt satir: sagda mode butonu + hap (otomatik genislik x 30)
	local row = Util.Create("Frame", {
		Name = "KeybindRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Parent = card,
	})

	local holder = Util.Create("Frame", {
		Name = "Holder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = row,
	})
	Util.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = holder,
	})

	local modeBtn = Util.Create("TextButton", {
		Name = "Mode",
		Text = mode,
		Font = fontR(),
		TextSize = 11,
		TextColor3 = Theme.Get("SubText"),
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Get("Background"),
		BackgroundTransparency = 0,
		Size = UDim2.fromOffset(56, 30),
		LayoutOrder = 1,
		Parent = holder,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = modeBtn })

	local hap = Util.Create("TextButton", {
		Name = "Hap",
		Text = keyToName(bound),
		Font = fontB(),
		TextSize = 13,
		TextColor3 = Theme.Get("Text"),
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Get("Background"),
		BackgroundTransparency = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 30),
		LayoutOrder = 2,
		Parent = holder,
	})
	Util.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = hap })
	Util.Create("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = hap,
	})
	Util.Create("UIStroke", {
		Color = Theme.Get("ElementBorder"),
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = hap,
	})

	local obj = {}

	local function fireState()
		for _, fn in ipairs(listeners) do
			Util.SafeCallback(fn, state)
		end
		Util.SafeCallback(callback, state)
		if flag ~= nil and flag ~= "" then
			local rec = Nova.Flags[flag]
			if rec then
				rec.State = state
			end
		end
	end

	local function fireClick()
		for _, fn in ipairs(clickListeners) do
			Util.SafeCallback(fn, state)
		end
	end

	local function setState(v, silent)
		v = not not v
		local changed = (v ~= state)
		state = v
		if not silent and (changed or mode == "Always") then
			fireState()
		end
		if flag ~= nil and flag ~= "" then
			local rec = Nova.Flags[flag]
			if rec then
				rec.State = state
			end
		end
	end

	local function applyModeVisual()
		modeBtn.Text = mode
	end

	-- TEK global InputBegan/InputEnded: Nova._KeybindInput icinde (yoksa kur)
	Nova._KeybindRegistry = Nova._KeybindRegistry or {}
	if Nova._KeybindInput == nil then
		local okB, c1 = pcall(function()
			return UIS.InputBegan:Connect(function(input, _gpe)
				-- Yazarken klavye tuslarini yoksay
				local focused = nil
				pcall(function()
					focused = UIS:GetFocusedTextBox()
				end)
				local isKey = input.KeyCode ~= Enum.KeyCode.Unknown
				if focused ~= nil and isKey then
					return
				end
				for rec, _ in pairs(Nova._KeybindRegistry) do
					if rec ~= nil and rec._HandleBegan ~= nil then
						pcall(rec._HandleBegan, input)
					end
				end
			end)
		end)
		local okE, c2 = pcall(function()
			return UIS.InputEnded:Connect(function(input, _gpe)
				for rec, _ in pairs(Nova._KeybindRegistry) do
					if rec ~= nil and rec._HandleEnded ~= nil then
						pcall(rec._HandleEnded, input)
					end
				end
			end)
		end)
		if okB and okE then
			Nova._KeybindInput = { c1, c2 }
		end
	end

	local function matches(input)
		if bound == nil then
			return false
		end
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			return input.KeyCode == bound
		end
		return input.UserInputType == bound
	end

	obj._HandleBegan = function(input)
		if not alive then
			return
		end
		if picking then
			return
		end
		if not matches(input) then
			return
		end
		fireClick()
		if mode == "Always" then
			-- Sabit true, tiklamada tekrar bildir
			if not state then
				setState(true)
			else
				fireState()
			end
		elseif mode == "Toggle" then
			setState(not state)
		elseif mode == "Hold" then
			setState(true)
		end
	end

	obj._HandleEnded = function(input)
		if not alive then
			return
		end
		if picking then
			return
		end
		if mode ~= "Hold" then
			return
		end
		if not matches(input) then
			return
		end
		setState(false)
	end

	obj._IsPicking = function()
		return picking
	end

	local pickConn = nil
	local function stopPick()
		if pickConn ~= nil then
			pcall(function()
				pickConn:Disconnect()
			end)
			pickConn = nil
		end
		picking = false
		hap.Text = keyToName(bound)
	end

	local function startPick()
		if picking then
			stopPick()
			return
		end
		picking = true
		hap.Text = "..."
		if pickConn ~= nil then
			pcall(function()
				pickConn:Disconnect()
			end)
			pickConn = nil
		end
		-- Sonraki InputBegan key/mouse yakala (anlik, Esc iptal)
		local conn = nil
		conn = UIS.InputBegan:Connect(function(input, _gpe)
			if not picking or not alive then
				return
			end
			if input.KeyCode == Enum.KeyCode.Escape then
				stopPick()
				return
			end
			local nb = nil
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				nb = input.KeyCode
			elseif input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				nb = input.UserInputType
			else
				return
			end
			bound = nb
			stopPick()
			if mode == "Always" then
				setState(true)
			end
			Util.SafeCallback(changedCallback, keyToName(bound), mode)
			if flag ~= nil and flag ~= "" then
				local rec = Nova.Flags[flag]
				if rec then
					rec.CurrentValue = keyToName(bound)
				end
			end
		end)
		pickConn = conn
		maid:Give(conn)
	end

	-- Hap tiklama: picking baslat (down/up eslesmeli degil, direkt click)
	maid:Give(hap.MouseButton1Click:Connect(function()
		if alive then
			startPick()
		end
	end))

	local function cycleMode()
		local idx = 1
		for i, m in ipairs(modeOrder) do
			if m == mode then
				idx = i
				break
			end
		end
		idx = idx % #modeOrder + 1
		mode = modeOrder[idx]
		applyModeVisual()
		if mode == "Always" then
			setState(true)
		else
			setState(false)
		end
		Util.SafeCallback(changedCallback, keyToName(bound), mode)
		if flag ~= nil and flag ~= "" then
			local rec = Nova.Flags[flag]
			if rec then
				rec.Mode = mode
			end
		end
	end

	maid:Give(modeBtn.MouseButton1Click:Connect(function()
		if alive and not picking then
			cycleMode()
		end
	end))
	-- Karta sag tik ile de mode dongusu
	maid:Give(card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 and alive and not picking then
			cycleMode()
		end
	end))

	-- Kart hover 0.12 Quad
	maid:Give(card.MouseEnter:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = math.clamp(baseTrans - hoverChange, 0, 1) }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))
	maid:Give(card.MouseLeave:Connect(function()
		Anim.Tween(card, { BackgroundTransparency = baseTrans }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end))

	obj.GetState = function()
		return state
	end
	obj.Get = function()
		return keyToName(bound)
	end
	obj.Set = function(a, b, c)
		-- Set(key, mode) veya Set(obj, key, mode)
		local k, m
		if a == obj then
			k, m = b, c
		else
			k, m = a, b
		end
		if k ~= nil then
			local nb = nameToKey(k)
			if nb ~= nil then
				bound = nb
				hap.Text = keyToName(bound)
				Util.SafeCallback(changedCallback, keyToName(bound), mode)
			end
		end
		if m ~= nil then
			local ok = false
			for _, mm in ipairs(modeOrder) do
				if mm == m then
					ok = true
					break
				end
			end
			if ok then
				mode = m
				applyModeVisual()
			end
		end
		if mode == "Always" then
			setState(true, true)
		end
		if flag ~= nil and flag ~= "" then
			local rec = Nova.Flags[flag]
			if rec then
				rec.CurrentValue = keyToName(bound)
				rec.Mode = mode
			end
		end
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
	obj.OnClick = function(self, fn)
		if type(self) == "function" and fn == nil then
			fn = self
		end
		if type(fn) == "function" then
			table.insert(clickListeners, fn)
		end
		return obj
	end
	obj.Destroy = function()
		alive = false
		picking = false
		Nova._KeybindRegistry[obj] = nil
		maid:Cleanup()
		Anim.Cancel(card)
		if Nova.SearchIndex then
			Nova.SearchIndex[card] = nil
		end
		if card then
			card:Destroy()
		end
	end

	Nova._KeybindRegistry[obj] = true

	if flag ~= nil and flag ~= "" then
		Nova.Flags[flag] = {
			Type = "Keybind",
			CurrentValue = keyToName(bound),
			Mode = mode,
			State = state,
			Get = function()
				return keyToName(bound)
			end,
			GetState = function()
				return state
			end,
			Set = function(k, m)
				obj.Set(k, m)
			end,
		}
	end

	applyModeVisual()
	return obj
end


-- Module: src/Components/Notify.lua
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


-- Module: src/Components/Config.lua
-- Config: Nova.Flags uzerinden JSON kayit/yukleme (executor file API, sessiz fallback).
-- Bagimlilik: Nova (ust scope, concat-build; require YOK).

do
	local HttpService = game:GetService("HttpService")

	local function configPath(name)
		return "NovaUI/" .. tostring(game.GameId) .. "/" .. tostring(name) .. ".json"
	end

	local function ensureFolder(folder)
		if typeof(makefolder) ~= "function" then
			return
		end
		local exists = false
		if typeof(isfolder) == "function" then
			local ok, res = pcall(isfolder, folder)
			exists = ok and res == true
		end
		if not exists then
			pcall(makefolder, folder)
		end
	end

	local function getValue(entry)
		if type(entry.Get) == "function" then
			local ok, v = pcall(entry.Get)
			if ok then
				return v
			end
		end
		return entry.CurrentValue
	end

	local function packColor(color, transp)
		return {
			r = math.floor(color.R * 255 + 0.5),
			g = math.floor(color.G * 255 + 0.5),
			b = math.floor(color.B * 255 + 0.5),
			t = tonumber(transp) or 0,
		}
	end

	local function unpackColor(data)
		if type(data) ~= "table" then
			return nil
		end
		local r, g, b = tonumber(data.r), tonumber(data.g), tonumber(data.b)
		if not (r and g and b) then
			return nil
		end
		local t = tonumber(data.t) or 0
		return Color3.fromRGB(
			math.clamp(math.floor(r + 0.5), 0, 255),
			math.clamp(math.floor(g + 0.5), 0, 255),
			math.clamp(math.floor(b + 0.5), 0, 255)
		), math.clamp(t, 0, 1)
	end

	local function packFlag(entry)
		local t = entry.Type
		if t == "Toggle" then
			local v = getValue(entry)
			if v == nil then
				v = entry.CurrentValue
			end
			return { t = "Toggle", v = (v == true) }
		elseif t == "Slider" then
			local v = tonumber(getValue(entry))
			if v == nil then
				v = tonumber(entry.CurrentValue)
			end
			if v == nil then
				return nil
			end
			return { t = "Slider", v = v }
		elseif t == "Dropdown" then
			local v = getValue(entry)
			if v == nil then
				v = entry.CurrentOption
			end
			if type(v) == "string" then
				return { t = "Dropdown", v = v }
			elseif type(v) == "table" then
				local arr = {}
				for key, item in pairs(v) do
					if type(item) == "string" then
						arr[#arr + 1] = item
					elseif item == true and type(key) == "string" then
						arr[#arr + 1] = key
					end
				end
				return { t = "Dropdown", v = arr }
			end
			return nil
		elseif t == "ColorPicker" then
			local color = entry.Color
			if type(entry.Get) == "function" then
				local ok, v = pcall(entry.Get)
				if ok and typeof(v) == "Color3" then
					color = v
				end
			end
			if typeof(color) ~= "Color3" then
				return nil
			end
			return { t = "ColorPicker", v = packColor(color, entry.Transp) }
		elseif t == "Keybind" then
			local key = entry.Key
			if typeof(key) == "EnumItem" then
				key = key.Name
			elseif type(key) ~= "string" then
				local gv = getValue(entry)
				if typeof(gv) == "EnumItem" then
					key = gv.Name
				elseif type(gv) == "string" then
					key = gv
				end
			end
			if type(key) ~= "string" then
				return nil
			end
			return { t = "Keybind", v = { key = key, mode = entry.Mode } }
		elseif t == "Input" then
			local v = getValue(entry)
			if v == nil then
				v = entry.CurrentValue
			end
			if type(v) ~= "string" then
				return nil
			end
			return { t = "Input", v = v }
		end
		return nil
	end

	local function applyFlag(entry, saved)
		local set = entry.Set
		local t, v = saved.t, saved.v
		if t == "Toggle" then
			if type(v) == "boolean" then
				pcall(function() set(v) end)
			end
		elseif t == "Slider" then
			if type(v) == "number" then
				pcall(function() set(v) end)
			end
		elseif t == "Dropdown" then
			if type(v) == "string" or type(v) == "table" then
				pcall(function() set(v) end)
			end
		elseif t == "ColorPicker" then
			local color, transp = unpackColor(v)
			if color then
				if not pcall(function() set(color, transp) end) then
					pcall(function() set(color) end)
				end
			end
		elseif t == "Keybind" then
			if type(v) == "table" and type(v.key) == "string" then
				if not pcall(function() set(v.key, v.mode) end) then
					pcall(function() set(v.key) end)
				end
			elseif type(v) == "string" then
				pcall(function() set(v) end)
			end
		elseif t == "Input" then
			if type(v) == "string" then
				pcall(function() set(v) end)
			end
		end
	end

	function Nova.SaveConfig(name)
		if type(name) ~= "string" or name == "" then
			return
		end
		if typeof(writefile) ~= "function" then
			return
		end
		local data = {}
		for flag, entry in pairs(Nova.Flags) do
			if type(entry) == "table" and type(entry.Type) == "string" then
				local ok, packed = pcall(packFlag, entry)
				if ok and packed ~= nil then
					data[flag] = packed
				end
			end
		end
		local okJson, json = pcall(HttpService.JSONEncode, HttpService, data)
		if not (okJson and type(json) == "string") then
			return
		end
		pcall(function()
			ensureFolder("NovaUI")
			ensureFolder("NovaUI/" .. tostring(game.GameId))
			writefile(configPath(name), json)
		end)
	end

	function Nova.LoadConfig(name)
		if type(name) ~= "string" or name == "" then
			return
		end
		if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then
			return
		end
		local path = configPath(name)
		local exists = false
		pcall(function()
			exists = isfile(path)
		end)
		if not exists then
			return
		end
		local content
		local okRead = pcall(function()
			content = readfile(path)
		end)
		if not (okRead and type(content) == "string") then
			return
		end
		local okJson, data = pcall(HttpService.JSONDecode, HttpService, content)
		if not (okJson and type(data) == "table") then
			return
		end
		for flag, saved in pairs(data) do
			if type(saved) == "table" then
				local entry = Nova.Flags[flag]
				if type(entry) == "table" and entry.Type == saved.t and type(entry.Set) == "function" then
					task.spawn(applyFlag, entry, saved)
				end
			end
		end
	end

	function Nova.AttemptSave(name)
		if type(name) == "string" and name ~= "" then
			Nova._AutoSaveName = name
		end
		local target = Nova._AutoSaveName
		if type(target) ~= "string" or target == "" then
			return
		end
		Nova._SaveToken = (Nova._SaveToken or 0) + 1
		local token = Nova._SaveToken
		task.delay(1, function()
			if token == Nova._SaveToken then
				pcall(Nova.SaveConfig, target)
			end
		end)
	end

	-- Autosave kancasi: sonradan kaydolacak her flag'in Set'i sarmalanir.
	-- AttemptSave(name) ile silahlandirilmissa her degisiklik 1sn debounce ile kaydedilir.
	local function armAutosave(flags)
		if type(flags) ~= "table" then
			return
		end
		local mt = getmetatable(flags)
		if mt and mt.__NovaAutoSave then
			return
		end
		setmetatable(flags, {
			__NovaAutoSave = true,
			__newindex = function(t, k, v)
				if type(v) == "table" and type(v.Set) == "function" and not v._NovaAutoWrapped then
					local rawSet = v.Set
					v._NovaAutoWrapped = true
					v.Set = function(a, b, c)
						rawSet(a, b, c)
						Nova.AttemptSave()
					end
				end
				rawset(t, k, v)
			end,
		})
	end

	Nova.Flags = Nova.Flags or {}
	armAutosave(Nova.Flags)
end


-- Module: src/Init.lua
-- Init: Nova tablosu init + Section metod baglama + tema/unload. En son yuklenir.
-- Bagimlilik: Util, Theme, Anim (ust scope, concat-build; require YOK).

Nova = Nova or { Flags = {}, Toggles = {}, Options = {}, SearchIndex = {}, _KeybindInput = nil }
Nova.Flags = Nova.Flags or {}
Nova.SearchIndex = Nova.SearchIndex or {}
Nova._UnloadCallbacks = Nova._UnloadCallbacks or {}
Nova._Guis = Nova._Guis or {}
Nova.Version = "1.0.0"

Nova.Toggles = Nova.Flags
Nova.Options = Nova.Flags

do
	local SECTION_METHODS = {
		AddToggle = "_AddToggle",
		AddButton = "_AddButton",
		AddLabel = "_AddLabel",
		AddSlider = "_AddSlider",
		AddInput = "_AddInput",
		AddDropdown = "_AddDropdown",
		AddColorPicker = "_AddColorPicker",
		AddKeybind = "_AddKeybind",
	}

	function Nova._BindSection(section)
		if type(section) ~= "table" then
			return section
		end
		for methodName, implName in pairs(SECTION_METHODS) do
			if type(section[methodName]) ~= "function" then
				section[methodName] = function(self, ...)
					local impl = Nova[implName]
					if type(impl) ~= "function" then
						error("[NovaUI] " .. methodName .. " kullanilamiyor (" .. implName .. " yuklenmemis).", 2)
					end
					local first = ...
					if type(first) == "string" and Nova.Flags[first] ~= nil then
						warn("[NovaUI] flag '" .. first .. "' zaten kayitli, uzerine yaziliyor.")
					end
					return impl(self, ...)
				end
			end
		end
		return section
	end
end

function Nova.SetTheme(name)
	Theme.Apply(name)
end

function Nova.OnUnload(fn)
	if type(fn) == "function" then
		table.insert(Nova._UnloadCallbacks, fn)
	end
end

function Nova.Unload()
	for _, fn in ipairs(Nova._UnloadCallbacks) do
		pcall(fn)
	end
	table.clear(Nova._UnloadCallbacks)

	if type(Anim.CancelAll) == "function" then
		pcall(Anim.CancelAll)
	end

	for _, gui in ipairs(Nova._Guis) do
		pcall(function()
			gui:Destroy()
		end)
	end
	table.clear(Nova._Guis)

	local ok, parent = pcall(Util.GetParent)
	if ok and parent then
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("ScreenGui") and child.Name == "NovaUI" then
				pcall(function()
					child:Destroy()
				end)
			end
		end
	end

	if Nova._NotifyHolder then
		pcall(function()
			Nova._NotifyHolder:Destroy()
		end)
		Nova._NotifyHolder = nil
	end

	table.clear(Nova.Flags)
	table.clear(Nova.SearchIndex)
	Nova._KeybindInput = nil
	Nova._NotifyCount = 0
	Nova._NotifyCards = nil
	Nova._AutoSaveName = nil

	Nova._Unloaded = true
end

return Nova
