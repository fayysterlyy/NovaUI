-- NovaUI Demo: tek dosya release'in kullanim ornegi.
-- Executor'da calistir (NovaUI.lua ayni klasorde olmali).

local Nova = loadstring(game:HttpGet("https://raw.githubusercontent.com/fayysterlyy/NovaUI/main/NovaUI.lua"))()

-- Pencere
local Window = Nova.CreateWindow({
	Title = "NovaUI",
	SubTitle = "Demo v1.0.0",
	Size = UDim2.fromOffset(560, 420),
	TabWidth = 170,
	Theme = "Dark",
})

local Main = Window:AddTab("Main")
local Settings = Window:AddTab("Settings")

-- Main > Karakter: tum element tipleri
local Play = Main:AddSection("Karakter")

Play:AddToggle("SpeedOn", {
	Text = "Hizli Yurume",
	Desc = "WalkSpeed 32 yapar",
	Default = false,
	Callback = function(v) print("Speed:", v) end,
})

Play:AddSlider("WalkSpeed", {
	Text = "Yurume Hizi",
	Min = 16, Max = 100, Default = 16,
	Suffix = " st",
	Callback = function(v) print("WS:", v) end,
})

Play:AddDropdown("Weapon", {
	Text = "Silah",
	Values = { "Kilic", "Yay", "Asa" },
	Default = "Kilic",
	Callback = function(v) print("Silah:", v) end,
})

Play:AddColorPicker("Aura", {
	Default = Color3.fromRGB(124, 108, 255),
	Callback = function(c) print("Aura:", c) end,
})

Play:AddKeybind("Dash", {
	Default = "Q",
	Mode = "Toggle",
	Callback = function(k) print("Dash:", k) end,
})

Play:AddInput("Nick", {
	Text = "Takma Ad",
	Default = "",
	Placeholder = "adini yaz...",
	Callback = function(v) print("Nick:", v) end,
})

Play:AddButton({
	Text = "Bildirimi Dene",
	Callback = function() Nova.Notify("NovaUI hazir kral!", 4) end,
})

Play:AddLabel("Iste bu kadar: toggle, slider, dropdown, renk, tus, yazi.")

-- Settings > Sistem: tema + config + unload
local Sys = Settings:AddSection("Sistem")

Sys:AddDropdown("Theme", {
	Text = "Tema",
	Values = { "Dark", "Light" },
	Default = "Dark",
	Callback = function(v) Nova.SetTheme(v) end,
})

Sys:AddInput("CfgName", {
	Text = "Config Adi",
	Default = "default",
	Placeholder = "config adi...",
})

local function cfgName()
	local rec = Nova.Flags.CfgName
	if type(rec) == "table" and type(rec.CurrentValue) == "string" and rec.CurrentValue ~= "" then
		return rec.CurrentValue
	end
	return "default"
end

Sys:AddButton({ Text = "Config Kaydet", Callback = function() Nova.SaveConfig(cfgName()) end })
Sys:AddButton({ Text = "Config Yukle", Callback = function() Nova.LoadConfig(cfgName()) end })
Sys:AddButton({ Text = "Arayuzu Kapat (Unload)", Callback = function() Nova.Unload() end })

-- Acilis bildirimi + autosave'i silahlandir + kapanis logu
Nova.Notify("NovaUI yuklendi, iyi eglenceler!", 4)
Nova.AttemptSave("default")
Nova.OnUnload(function() print("NovaUI kapatildi.") end)
