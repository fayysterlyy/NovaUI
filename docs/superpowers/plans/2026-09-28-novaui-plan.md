# Nova UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Roblox Luau için Fluent hissi veren ama özgün Nova UI library'sini hatasız, tek dosya release ile üretmek.

**Architecture:** Concat-build mimarisi. `src/*.lua` dosyaları `require` KULLANMAZ, hepsi tek `Nova` tablosuna yazar. `build/build.py` dosyaları sırayla birleştirip `NovaUI.lua` üretir. Merkezi `Anim` (tween manager + cancel), `Theme` (registry), `Util` (Maid + SafeCallback + GetParent).

**Tech Stack:** Luau (Roblox), TweenService, UIScale + UIListLayout, HttpService JSON, Python build script.

## Global Constraints

- Luau / Roblox executor uyumlu: `gethui/get_hidden_gui/CoreGui/PlayerGui` fallback zinciri, `writefile` yoksa sessiz geç.
- Hiçbir kullanıcı callback'i library'yi öldürmez: her callback `pcall` içinde.
- Her element `:Destroy()` ile tüm connection + tween'i temizler (Maid).
- `require(script.X)` YASAK. Dosyalar concat ile birleşir. Sadece `Nova`, `Util`, `Theme`, `Anim` globallerine (aslında üst scope local'lerine) erişilir.
- Renk default accent: `Color3.fromRGB(124,108,255)` (#7C6CFF). Radius kart 10px, iç kontrol 7px.
- Font: `Enum.Font.MontserratBold` / `Enum.Font.Montserrat` (yoksa Gotham fallback - Util.GetFont ile).
- Anim süreleri: hover 0.12 Quad Out, toggle 0.2 Quad Out, dropdown 0.2 Cubic Out, tab 0.25 Cubic Out, pencere aç 0.35 Back Out, kapa 0.2 Quad In, notify 0.3 Cubic Out.

---

### Task 1: Core (Util + Theme + Anim)

**Files:**
- Create: `src/Util.lua`
- Create: `src/Theme.lua`
- Create: `src/Anim.lua`

**Interfaces:**
- Consumes: hiçbir şey (en alt katman).
- Produces:
  - `Util.Create(className, props, parent) -> Instance`
  - `Util.MaidNew() -> Maid` (`Maid:Give(task)`, `Maid:Cleanup()`)
  - `Util.GetParent() -> Instance` (gethui zinciri)
  - `Util.SafeCallback(fn, ...) -> ok, result`
  - `Util.Drag(frame, handle)` , `Util.Ripple(button, color)`
  - `Util.GetFont(bold:boolean) -> Enum.Font`
  - `Theme.Tokens.Dark/Light tabloları`, `Theme.Register(inst, map)`, `Theme.Apply(name)`, `Theme.Get(key)`
  - `Anim.Tween(obj, props, time, style, dir)`, `Anim.Cancel(obj)`

- [ ] **Step 1: src/Util.lua yaz** (Maid, Create, GetParent, SafeCallback, Drag touch destekli, Ripple, GetFont fallback, Clamp, Debounce)
- [ ] **Step 2: src/Theme.lua yaz** (Dark/Light tokenlar: Accent 124,108,255 / Text 240,240,240 / SubText 170,170,170 / Background 28,28,32 / Sidebar 34,34,40 / Element 120,120,120+transparency / ElementBorder 55,55,65 / Card 40,40,48 / Dialog 45,45,52 / Radius 10/7, Registry + Apply loop)
- [ ] **Step 3: src/Anim.lua yaz** (Active tablosu + Cancel, ReducedMotion check, Completed:Once cleanup)
- [ ] **Step 4: Sözdizimi kontrol** `luac -p` veya python paren check ile.

### Task 2: Window + Tab + Section + Search

**Files:**
- Create: `src/Components/Window.lua`
- Create: `src/Components/Tab.lua`
- Create: `src/Components/Section.lua`

**Interfaces:**
- Consumes: Util, Theme, Anim, Nova.
- Produces:
  - `Nova.CreateWindow(config) -> Window` (config: Title, SubTitle, Size, TabWidth=170, Theme="Dark", MinimizeKey)
  - `Window:AddTab(name, icon) -> Tab`
  - `Tab:AddSection(title) -> Section` (Linoria Groupbox karşılığı, tek kolon + section kartları)
  - `Tab`, `Section` her biri `AddToggle/AddButton/...` için `ElementRoot` frame verir.
  - Search bar: Window üstünde TextBox, yazınca tüm element kartlarının Title'ına göre filtreler (Visible toggle).

- [ ] **Step 1: Window.lua** (ScreenGui + UIScale responsive + CanvasGroup fade + TitleBar 44px + Sidebar 170px + SearchBox + TabHolder Scrolling + Container + Drag + Resize tutamaç + MinimizeKey + :Destroy)
- [ ] **Step 2: Tab.lua** (Tab butonu 34px + selector 4px accent bar animasyonu + ContainerCanvas sayfa + geçiş fade+5px slide)
- [ ] **Step 3: Section.lua** (Kart: radius 10, padding 12, başlık 13 bold + çizgi, UIListLayout 6px, element ekleme helper `AddElementCard(title, desc) -> cardFrame`)
- [ ] **Step 4: Search filtresi** (her element kartına `Nova.SearchIndex` kaydı, TextBox:GetPropertyChangedSignal Text ile filtre)

### Task 3: Elementler Part 1 (Toggle, Button, Label, Slider, Input)

**Files:**
- Create: `src/Elements/Toggle.lua`
- Create: `src/Elements/Button.lua`
- Create: `src/Elements/Label.lua`
- Create: `src/Elements/Slider.lua`
- Create: `src/Elements/Input.lua`

**Interfaces:**
- Consumes: Util, Theme, Anim, Nova (Flags kaydı).
- Produces (hepsi `Section:AddX` olarak bağlanır):
  - `Section:AddToggle(flag, opts) -> ToggleObj` (opts: Text, Desc, Default, Callback) + `OnChanged/Set/Get/Destroy`
  - `Section:AddButton(opts)` (Text, Desc, Callback, DoubleClick) + Ripple + UIScale press
  - `Section:AddLabel(text, wrap)` + `SetText`
  - `Section:AddSlider(flag, opts)` (Text, Min, Max, Default, Rounding, Suffix, Callback) drag RenderStepped yok, InputChanged ile
  - `Section:AddInput(flag, opts)` (Text, Default, Placeholder, Numeric, Finished, Callback) debounce

- [ ] **Step 1-5:** Her element: kart (radius 7 iç) + hover 0.12 tween + pcall callback + Flags kaydı + Destroy.
- [ ] **Step 6:** Toggle hap 36x18 radius 9 + dot kayma 0.2 Quad; Slider rail 4px hap + fill + dot, anlık set (tween yok); Button press scale 0.97.

### Task 4: Elementler Part 2 (Dropdown, ColorPicker, Keybind)

**Files:**
- Create: `src/Elements/Dropdown.lua`
- Create: `src/Elements/ColorPicker.lua`
- Create: `src/Elements/Keybind.lua`

**Interfaces:**
- Consumes: aynı.
- Produces:
  - `Section:AddDropdown(flag, opts)` (Text, Values, Default, Multi, Callback) + liste layer ayrı, açma 0.2 Cubic scale, scroll, seçili satırda accent bar
  - `Section:AddColorPicker(flag, opts)` (Default Color3, Transparency, Callback) + dialog 380x300: SV harita + Hue bar + Hex/RGB input + önizleme
  - `Section:AddKeybind(flag, opts)` (Default EnumItem/string, Mode Always/Toggle/Hold, Callback) + `...` picking + InputBegan dinleme

- [ ] **Step 1:** Dropdown (havuzlu item Clone, viewport taşma clamp, Multi table value)
- [ ] **Step 2:** ColorPicker (HSV hesapları saf Luau, dialog UIScale 1.05->1 spring yerine 0.25 Back tween)
- [ ] **Step 3:** Keybind (mouse MB1/MB2 dahil, Mode döngüsü, leak yok - tek global InputBegan + per-element filtre)

### Task 5: Sistemler (Notify + Config + Init + Build + Demo)

**Files:**
- Create: `src/Components/Notify.lua`
- Create: `src/Components/Config.lua`
- Create: `src/Init.lua`
- Create: `build/build.py`
- Create: `examples/Demo.lua`

**Interfaces:**
- Consumes: tüm üsttekiler.
- Produces:
  - `Nova.Notify(text, duration, accent)` kuyruklu, sağ alt, slide 0.3 Cubic, max 5 aynı anda
  - `Nova.SaveConfig(name)`, `Nova.LoadConfig(name)` (Flags üzerinden, HttpService JSON, makefolder/isfile pcall)
  - `Nova.CreateWindow`, `Nova.SetTheme`, `Nova.Unload`, `Nova.Flags/Toggles/Options`
  - `build/build.py` çalışınca `NovaUI.lua` üretir (sıra: header + Util + Theme + Anim + Window + Tab + Section + Elements + Notify + Config + Init)
  - `examples/Demo.lua` tüm elementleri gösterir

- [ ] **Step 1:** Notify.lua (pool 5, progress bar, icon yok - accent çizgi)
- [ ] **Step 2:** Config.lua (PackColor/Unpack, debounce 1sn autosave hook `Nova.AttemptSave`)
- [ ] **Step 3:** Init.lua (Nova tablosu init + Section metodlarına Element bağlama + Unload cleanup + return Nova)
- [ ] **Step 4:** build.py (concat + `-- NovaUI built` header, dosya yoksa hata vermez)
- [ ] **Step 5:** Demo.lua (Window + 2 tab + tüm elementler + search test + tema değişimi)
