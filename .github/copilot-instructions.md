# Copilot Instructions

## Project Shape
- This is a Windows AutoHotkey v2 project for automating fishing in BPSR via pixel detection plus mouse/keyboard input.
- The runtime is a single script: `BPSR-AutoFishing.ahk`. Keep behavior changes there unless updating documentation/assets.
- `README.md` documents user-facing usage: run the `.exe`, `F9` toggles automation, and `F10` exits/logs final counters.
- `Assets/` contains screenshots and `Assets/Coords y colores.txt` with historical/reference pixel positions and colors; use it to validate coordinate/color changes.

## Script Architecture
- `AutoFishingConfig` is the source of truth for constants: keys, executable names, pixel points/colors, tolerances, timings, messages, counters, and scaling settings.
- `AutoFishingBot` owns state and behavior: resource checks, casting, waiting for fish, minigame control, window scaling, stats, and logging.
- Do not introduce magic numbers in behavior methods. Add values under `AutoFishingConfig` first, then reference `this.cfg...`.
- Keep log text in `AutoFishingConfig.Messages`; methods should call `this.Log(level, this.cfg.Messages.X)` or `Format(...)`.

## Pixel and Window Handling
- Coordinates in `AutoFishingConfig.Points` are base `1920x1080` client-area coordinates.
- Runtime coordinates must go through `PointMatches()` or `ClickPoint()`, both of which call `ScalePoint()`.
- `RefreshGameWindow()` finds `BPSR.exe`, `BPSR_EPIC.exe`, or `BPSR_Steam.exe` via `WinExist("ahk_exe ...")`, then uses `WinGetClientPos()` to derive scale and window offset.
- Avoid direct `PixelGetColor(x, y)` or `Click(x, y)` calls; they bypass client-window scaling.
- Color matching uses `ColorTolerance()` with RGB channel math from `AutoFishingConfig.ColorMath`.

## Fishing Flow
- Main loop: `Run()` refreshes the game window, calls `CheckBaitsAndRods()`, casts, waits in `WaitForFish()`, runs `StartMinigame()`, then checks continue/lost state.
- `StartMinigame()` must always release mouse/direction state via its `finally { this.ReleaseAll() }` block.
- Direction control is stateful: `DetectArrow()` returns configured keys, `HoldDirection()` sends down events, and `ReleaseDirection()` sends both up events.
- Fish/rod counters are stored in `this.stats` and summarized by `LogSummary()` on `F10`/exit.

## Developer Workflow
- AutoHotkey is required to run or syntax-check the script; README references AutoHotkey `v2.0.19`.
- There is no discovered test suite or build config in this repo. Validate by running the `.ahk` locally in AutoHotkey and checking `BPSR-AutoFishing.log`.
- `generateHash.ps1` expects a built `BPSR-AutoFishing.exe` and writes its SHA256 hash to `hash.txt`.
- If changing release artifacts, regenerate the hash with PowerShell after the `.exe` exists.
