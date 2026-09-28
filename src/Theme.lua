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
