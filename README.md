# Nova UI v1.0.0

Fluent hissi veren ama özgün Roblox Luau UI library. Tek dosya release, executor uyumlu.

## Kullanım

`NovaUI.lua` build artifact'tır. Executor'da:

```lua
local Nova = loadstring(game:HttpGet("https://raw.githubusercontent.com/fayysterlyy/NovaUI/main/NovaUI.lua"))()
-- ya da local test:
local Nova = loadstring(readfile("NovaUI.lua"))()

local Window = Nova.CreateWindow({ Title = "Nova", SubTitle = "v1.0", Theme = "Dark" })
local Tab = Window:AddTab("Main")
local Sec = Tab:AddSection("Karakter")

Sec:AddToggle("SpeedOn", { Text = "Hizli Yurume", Default = false,
  Callback = function(v) print(v) end })
Sec:AddSlider("WS", { Text = "Hiz", Min = 16, Max = 100, Default = 16, Suffix = " st" })
Sec:AddDropdown("Weapon", { Text = "Silah", Values = { "Kilic", "Yay" }, Default = "Kilic" })
Sec:AddColorPicker("Aura", { Default = Color3.fromRGB(124, 108, 255) })
Sec:AddKeybind("Dash", { Default = "Q", Mode = "Toggle" })
Sec:AddInput("Nick", { Placeholder = "adini yaz..." })
Sec:AddButton({ Text = "Selam", Callback = function() Nova.Notify("hazir!", 3) end })
Sec:AddLabel("Aciklama yazisi")

Nova.Flags.SpeedOn:OnChanged(function(v) print("degisti:", v) end)
Nova.SaveConfig("default")  -- NovaUI/<GameId>/default.json
Nova.LoadConfig("default")
Nova.SetTheme("Light")
-- Nova.Unload()
```

Detaylı örnek: `examples/Demo.lua`

## API

- `Nova.CreateWindow({Title, SubTitle, Size, TabWidth=170, Theme="Dark", MinimizeKey})`
- `Window:AddTab(name, icon)`, `Tab:AddSection(title)`
- `Section:AddToggle(flag, {Text,Desc,Default,Callback})` → `Set/Get/OnChanged/Destroy`
- `AddSlider(flag, {Min,Max,Default,Rounding,Suffix})`, `AddInput(flag, {Placeholder,Numeric,Finished,MaxLength})`
- `AddDropdown(flag, {Values,Default,Multi})` → `Set/Refresh`, `AddColorPicker(flag, {Default,Transparency})`
- `AddKeybind(flag, {Default,Mode})` → `GetState/OnClick`, `AddButton({Text,DoubleClick})`, `AddLabel(text)`
- `Nova.Notify(text, duration)`, `Nova.SaveConfig/LoadConfig/AttemptSave(name)`, `Nova.SetTheme`, `Nova.Unload/OnUnload`
- Hepsi: `Nova.Flags[flag]` = `{Type, CurrentValue, Get, Set}`

## Geliştirme

Dev: `src/` (concat, `require` YOK). Build: `python build/build.py` → `NovaUI.lua` (17 modül).
Sözdizimi: `luaparser` ile 17/17 + build OK.

## Kimlik

Accent `#7C6CFF` (124,108,255), kart radius 10 / iç 7, Montserrat→Gotham fallback,
acrylic yok (frosted gradient), search bar + kuyruklu notify dahili.
Anim: hover 0.12 Quad, toggle 0.2 Quad, dropdown 0.2 Cubic, pencere 0.35 Back.
