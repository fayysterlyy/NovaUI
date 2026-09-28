#!/usr/bin/env python3
"""NovaUI concat-build: src/*.lua dosyalarini sirayla birlestirip NovaUI.lua uretir.

Kullanim:  python build/build.py
Cikti:     NovaUI.lua (repo koku) -> loadstring ile kullanilir.
Kurallar:  require() YOK; eksik dosya uyarilip atlanir (crash yok).
"""

import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
OUT = ROOT / "NovaUI.lua"

ORDER = [
    "src/Util.lua",
    "src/Theme.lua",
    "src/Anim.lua",
    "src/Components/Window.lua",
    "src/Components/Tab.lua",
    "src/Components/Section.lua",
    "src/Elements/Toggle.lua",
    "src/Elements/Button.lua",
    "src/Elements/Label.lua",
    "src/Elements/Slider.lua",
    "src/Elements/Input.lua",
    "src/Elements/Dropdown.lua",
    "src/Elements/ColorPicker.lua",
    "src/Elements/Keybind.lua",
    "src/Components/Notify.lua",
    "src/Components/Config.lua",
    "src/Init.lua",
]


def build_header() -> str:
    date = datetime.date.today().isoformat()
    return (
        f"-- NovaUI v1.0.0 | built {date} | loadstring ile kullan\n"
        "-- Concat-build tek dosya: require() YOK. Dosyalar ust scope'taki\n"
        "-- Nova / Util / Theme / Anim lokallerine yazar.\n\n"
        'local TweenService = game:GetService("TweenService")\n'
        'local UserInputService = game:GetService("UserInputService")\n'
        'local HttpService = game:GetService("HttpService")\n'
        'local RunService = game:GetService("RunService")\n\n'
        "local Nova = { Flags = {}, Toggles = {}, Options = {}, SearchIndex = {}, _KeybindInput = nil }\n"
        "local Util, Theme, Anim\n"
    )


def main() -> None:
    parts = [build_header()]
    missing = []
    included = []

    for rel in ORDER:
        path = ROOT / rel
        if not path.is_file():
            missing.append(rel)
            print(f"[WARN] eksik dosya, atlaniyor: {rel}")
            continue
        content = path.read_text(encoding="utf-8")
        parts.append(f"\n-- Module: {rel}\n{content.rstrip()}\n")
        included.append(rel)

    OUT.write_text("\n".join(parts), encoding="utf-8")

    total_lines = OUT.read_text(encoding="utf-8").count("\n") + 1
    print(f"[OK] {len(included)}/{len(ORDER)} modul birlestirildi -> {OUT.name} ({total_lines} satir)")
    if missing:
        print(f"[WARN] atlananlar ({len(missing)}): {', '.join(missing)}")


if __name__ == "__main__":
    main()
