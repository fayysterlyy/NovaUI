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
