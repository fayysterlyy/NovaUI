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
