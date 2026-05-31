#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================
;  AutoFishing
; ----------------------------------------------
;   @description: Automatiza la pesca mediante deteccion de pixeles
;   @author: Haru, Joseleelsuper
;   @controls: F9 = Toggle ON/OFF | F10 = Salir
; ==============================================

SendMode("Input")
SetWorkingDir(A_ScriptDir)
CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

global Config := BuildConfig()
global State := BuildState()

OnExit(OnExitHandler)

try {
    Initialize()
} catch as err {
    FatalStop("No se pudo inicializar AutoFishing: " err.Message)
}

F9:: ToggleScript()
F10:: ExitScript()

BuildConfig() {
    cfg := {}

    cfg.Base := { w: 1920, h: 1080 }
    cfg.TimerInterval := 50
    cfg.WatchdogTimeout := 60000
    cfg.NoArrowTimeout := 30000
    cfg.ResourceCheckDelay := 3000
    cfg.ContinueCheckInterval := 2000
    cfg.GameExes := ["BPSR_STEAM.exe", "BPSR_EPIC.exe", "BPSR.exe"]

    cfg.LogEnabled := true
    cfg.LogPath := A_ScriptDir "\AutoFishing.log"

    cfg.Tolerance := {}
    cfg.Tolerance.primary := 20
    cfg.Tolerance.event := 25
    cfg.Tolerance.resource := 20
    cfg.Tolerance.button := 20
    cfg.Tolerance.arrow := 25
    cfg.Tolerance.fish := 35
    cfg.Tolerance.tension := 30

    cfg.Timings := {}
    cfg.Timings.clickDelay := 50
    cfg.Timings.afterFail := 3000
    cfg.Timings.afterFinish := 900
    cfg.Timings.afterContinue := 1000
    cfg.Timings.tensionRelease := 800
    cfg.Timings.arrowHold := 1500
    cfg.Timings.fishTrackHold := 1000
    cfg.Timings.fishTrackCooldown := 120
    cfg.Timings.resourceMenuWait := 1000
    cfg.Timings.afterResourceSelect := 700
    cfg.Timings.afterResourceRecovery := 700
    cfg.Timings.afterCast := 150
    cfg.CaughtTextSampleStep := 4
    cfg.CaughtTextMinOrange := 40
    cfg.CaughtTextMinLight := 25

    cfg.Colors := {}
    cfg.Colors.resourceMissing := 0xDE6432
    cfg.Colors.resourceUse := 0xE8E8E8
    cfg.Colors.fish := 0xF2F7F1
    cfg.Colors.fishSpottedYellow := 0xFFC414
    cfg.Colors.fishSpottedOrange := 0xFF4100
    cfg.Colors.fishLost := 0xD2E6FF
    cfg.Colors.fishCaughtOrange := 0xE09B16
    cfg.Colors.fishCaughtLight := 0xFCEE8D
    cfg.Colors.continueButton := 0xE8E8E8
    cfg.Colors.tensionCritical := 0xFFFFFF
    cfg.Colors.tensionDanger := 0xDC0200
    cfg.Colors.arrowA := [0xFE6C06, 0xFAB916, 0xFF5601, 0xDA932B]
    cfg.Colors.arrowD := [0xFF5A01, 0xFAB916, 0xFF5601]

    cfg.PointsBase := Map()
    cfg.PointsBase["cast"] := { x: 954, y: 562 }
    cfg.PointsBase["fishSpottedYellow"] := { x: 970, y: 475 }
    cfg.PointsBase["fishSpottedOrange"] := { x: 955, y: 560 }
    cfg.PointsBase["fishLost"] := { x: 1123, y: 680 }
    cfg.PointsBase["continueButton"] := { x: 1605, y: 970 }
    cfg.PointsBase["baitMissingIndicator"] := { x: 1425, y: 983 }
    cfg.PointsBase["rodMissingIndicator"] := { x: 1693, y: 983 }
    cfg.PointsBase["baitUse"] := { x: 1395, y: 620 }
    cfg.PointsBase["rodUse"] := { x: 1655, y: 620 }
    cfg.PointsBase["tensionCritical"] := { x: 1248, y: 897 }
    cfg.PointsBase["tensionDanger"] := { x: 1200, y: 897 }
    cfg.PointsBase["arrowA"] := { x: 851, y: 528 }
    cfg.PointsBase["arrowD"] := { x: 1054, y: 536 }

    cfg.AreasBase := Map()
    cfg.AreasBase["fish"] := { x1: 0, y1: 400, x2: 1920, y2: 710 }
    cfg.AreasBase["caughtText"] := { x1: 740, y1: 620, x2: 1080, y2: 735 }

    cfg.RodRefBase := { x: 820, y: 700 }
    cfg.FishDeadzone := 75

    return cfg
}

BuildState() {
    st := {}
    st.active := false
    st.status := "idle"
    st.lastCast := 0
    st.fishStart := 0
    st.tensionStart := 0
    st.lastArrowSeen := 0
    st.lastContinueCheck := 0
    st.currentKey := ""
    st.keySource := ""
    st.keyStart := 0
    st.arrowKey := ""
    st.fishTrackCooldownUntil := 0
    st.holdingClick := false
    st.inTimer := false
    return st
}

Initialize() {
    global Config, State

    if !DetectGameWindow() {
        FatalStop("No se detecto la ventana del juego. Abre el juego antes de ejecutar el script.")
    }

    if (Config.Game.w < 100 || Config.Game.h < 100) {
        FatalStop("La ventana del juego detectada no tiene un area cliente valida.")
    }

    ScaleConfig()
    State.status := "idle"
    Log("INIT", "Juego detectado: " Config.Game.exe " | Ventana: " Config.Game.w "x" Config.Game.h " @ (" Config.Game.x "," Config
        .Game.y ") | Escala: " Round(Config.Scale.x, 2) "x" Round(Config.Scale.y, 2))
}

DetectGameWindow() {
    global Config

    for _, exe in Config.GameExes {
        hwnd := WinExist("ahk_exe " exe)
        if !hwnd {
            continue
        }

        rect := Buffer(16, 0)
        pt := Buffer(8, 0)

        if !DllCall("GetClientRect", "Ptr", hwnd, "Ptr", rect.Ptr, "Int") {
            throw Error("GetClientRect fallo para " exe)
        }

        if !DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", pt.Ptr, "Int") {
            throw Error("ClientToScreen fallo para " exe)
        }

        Config.Game := {}
        Config.Game.hwnd := hwnd
        Config.Game.exe := exe
        Config.Game.x := NumGet(pt, 0, "Int")
        Config.Game.y := NumGet(pt, 4, "Int")
        Config.Game.w := NumGet(rect, 8, "Int")
        Config.Game.h := NumGet(rect, 12, "Int")
        return true
    }

    return false
}

ScaleConfig() {
    global Config

    Config.Scale := { x: Config.Game.w / Config.Base.w, y: Config.Game.h / Config.Base.h }
    Config.Points := Map()
    Config.Areas := Map()

    for name, pt in Config.PointsBase {
        Config.Points[name] := ScalePoint(pt)
    }

    for name, area in Config.AreasBase {
        Config.Areas[name] := ScaleArea(area)
    }

    Config.RodRef := ScalePoint(Config.RodRefBase)
}

ScalePoint(pt) {
    global Config
    return { x: Round(pt.x * Config.Scale.x) + Config.Game.x, y: Round(pt.y * Config.Scale.y) + Config.Game.y }
}

ScaleArea(area) {
    global Config
    return { x1: Round(area.x1 * Config.Scale.x) + Config.Game.x, y1: Round(area.y1 * Config.Scale.y) + Config.Game.y,
        x2: Round(area.x2 * Config.Scale.x) + Config.Game.x, y2: Round(area.y2 * Config.Scale.y) + Config.Game.y }
}

ToggleScript() {
    global Config, State

    if State.active {
        Log("TOGGLE", "Script DESACTIVADO")
        StopTimer()
        State.active := false
        State.status := "idle"
        SafeReleaseAll()
        return
    }

    Log("TOGGLE", "Script ACTIVADO")
    StopTimer()
    State.active := true
    State.status := "idle"

    try {
        StartCycle()
    } catch as err {
        FatalStop("Error al iniciar ciclo: " err.Message)
    }

    if State.active {
        SetTimer(ProcessFishing, Config.TimerInterval)
    }
}

ExitScript() {
    global State

    Log("EXIT", "Cerrando script con F10")
    StopTimer()
    State.active := false
    State.status := "stopped"
    SafeReleaseAll()
    ExitApp()
}

StopTimer() {
    try {
        SetTimer(ProcessFishing, 0)
    }
}

ProcessFishing() {
    global State

    if State.inTimer || !State.active || State.status = "stopped" {
        return
    }

    State.inTimer := true
    try {
        ProcessFishingTick()
    } catch as err {
        FatalStop("Error durante la ejecucion: " err.Message)
    } finally {
        State.inTimer := false
    }
}

ProcessFishingTick() {
    global Config, State

    if ShouldCheckContinueButton() && IsContinueButtonVisible() {
        HandleContinueButton()
        return
    }

    if State.status = "tensionRelease" {
        if IsFishLost() {
            HandleFishLost()
            return
        }

        if IsFishCaught() {
            HandleFishCaught()
            return
        }

        arrowHandled := ProcessArrows()

        if HasNoArrowTimedOut() {
            Log("WATCHDOG", "30s sin detectar flechas; suponiendo pez perdido")
            HandleFishLost()
            return
        }

        if !arrowHandled {
            TrackFish()
        }

        if (A_TickCount - State.tensionStart >= Config.Timings.tensionRelease) {
            ResumeAfterTension()
        }
        return
    }

    if State.status = "fishing" {
        if IsFishLost() {
            HandleFishLost()
            return
        }

        if IsFishCaught() {
            HandleFishCaught()
            return
        }

        if IsTensionDanger() {
            PauseForTension()
            return
        }

        if ProcessArrows() {
            return
        }

        if HasNoArrowTimedOut() {
            Log("WATCHDOG", "30s sin detectar flechas; suponiendo pez perdido")
            HandleFishLost()
            return
        }

        TrackFish()
        return
    }

    if State.status = "waitingBite" {
        if IsFishSpotted() {
            StartFishing()
            return
        }

        if (A_TickCount - State.lastCast > Config.ResourceCheckDelay) {
            if IsResourceEmpty("bait") || IsResourceEmpty("rod") {
                StartCycle()
                return
            }
        }

        if (State.lastCast && A_TickCount - State.lastCast > Config.WatchdogTimeout) {
            Log("WATCHDOG", "60s sin iniciar minijuego tras lanzar; relanzando")
            StartCycle()
        }
    }
}

StartCycle() {
    global State

    if !State.active || State.status = "stopped" {
        return false
    }

    State.status := "idle"

    if !EnsureResourcesReady() {
        return false
    }

    if !State.active || State.status = "stopped" {
        return false
    }

    CastRod()
    return true
}

EnsureResourcesReady() {
    if IsResourceEmpty("bait") {
        if !RecoverResource("bait") {
            return false
        }
    }

    if IsResourceEmpty("rod") {
        if !RecoverResource("rod") {
            return false
        }
    }

    return true
}

RecoverResource(kind) {
    global Config, State

    State.status := "recoveringResource"
    SafeReleaseAll()

    menuKey := kind = "bait" ? "n" : "m"
    usePoint := kind = "bait" ? "baitUse" : "rodUse"
    resourceName := kind = "bait" ? "cebo" : "cana"
    if kind = "bait" {
        missingMessage := "No hay cebos disponibles. AutoFishing se detendra."
    } else {
        missingMessage := "No hay cañas disponibles. AutoFishing se detendra."
    }

    Log("RESOURCE", "Intentando seleccionar " resourceName)
    Send(menuKey)
    Sleep(Config.Timings.resourceMenuWait)

    if !CheckPointColor(usePoint, Config.Colors.resourceUse, Config.Tolerance.button) {
        FatalStop(missingMessage)
        return false
    }

    ClickPoint(usePoint)
    Sleep(Config.Timings.afterResourceSelect)
    Sleep(Config.Timings.afterResourceRecovery)

    Log("RESOURCE", "Recurso seleccionado: " resourceName)
    State.status := "idle"
    return true
}

CastRod() {
    global Config, State

    SafeReleaseAll()
    ClickPoint("cast")
    Sleep(Config.Timings.afterCast)

    State.status := "waitingBite"
    State.lastCast := A_TickCount
    State.fishStart := 0
    State.tensionStart := 0
    State.lastArrowSeen := 0
    Log("CAST", "Caña lanzada")
}

StartFishing() {
    global Config, State

    ReleaseKey()
    MoveToPoint("cast")
    Sleep(Config.Timings.clickDelay)
    Click("Down")

    State.holdingClick := true
    State.status := "fishing"
    State.fishStart := A_TickCount
    State.lastArrowSeen := A_TickCount
    State.fishTrackCooldownUntil := 0
    Log("FISH", "Pez detectado; manteniendo click")
}

HandleFishLost() {
    global Config, State

    SafeReleaseAll()
    State.status := "idle"
    Log("ESCAPED", "Pez perdido; relanzando tras espera")
    Sleep(Config.Timings.afterFail)

    if State.active {
        StartCycle()
    }
}

HandleFishCaught() {
    global Config, State

    elapsed := State.fishStart ? Round((A_TickCount - State.fishStart) / 1000, 1) : 0
    SafeReleaseAll()
    State.status := "idle"
    Log("SUCCESS", "Pez capturado en " elapsed "s; esperando continuar")

    Sleep(Config.Timings.afterFinish)

    HandleContinueButton()
}

HandleContinueButton() {
    global Config, State

    SafeReleaseAll()
    State.status := "idle"
    ClickPoint("continueButton")
    State.lastContinueCheck := A_TickCount
    Log("ACTION", "Boton continuar pulsado")
    Sleep(Config.Timings.afterContinue)

    if State.active {
        StartCycle()
    }
}

PauseForTension() {
    global State

    Click("Up")
    State.holdingClick := false
    State.status := "tensionRelease"
    State.tensionStart := A_TickCount
    Log("TENSION", "Tension peligrosa; soltando click temporalmente")
}

ResumeAfterTension() {
    global Config, State

    if !State.active {
        return
    }

    MoveToPoint("cast")
    Sleep(Config.Timings.clickDelay)
    Click("Down")

    State.holdingClick := true
    State.status := "fishing"
    State.tensionStart := 0
    Log("TENSION", "Reanudando pesca tras liberar tension")
}

ProcessArrows() {
    global Config, State

    detectedArrow := DetectArrow()
    if detectedArrow != "" {
        State.lastArrowSeen := A_TickCount
    }

    if State.keySource = "arrow" && State.keyStart > 0 {
        elapsed := A_TickCount - State.keyStart

        if detectedArrow != "" && detectedArrow = State.arrowKey {
            State.keyStart := A_TickCount
            return true
        }

        if detectedArrow != "" && detectedArrow != State.arrowKey {
            SetMovementKey(detectedArrow, "arrow")
            return true
        }

        if elapsed < Config.Timings.arrowHold {
            return true
        }

        ReleaseKey()
        State.keySource := ""
        State.arrowKey := ""
        return false
    }

    if detectedArrow != "" {
        if State.keySource = "fish" {
            Log("ARROW", "Flecha detectada; interrumpiendo seguimiento del pez")
        }

        SetMovementKey(detectedArrow, "arrow")
        return true
    }

    return false
}

DetectArrow() {
    global Config

    if CheckPointAnyColor("arrowD", Config.Colors.arrowD, Config.Tolerance.arrow) {
        return "d"
    }

    if CheckPointAnyColor("arrowA", Config.Colors.arrowA, Config.Tolerance.arrow) {
        return "a"
    }

    return ""
}

TrackFish() {
    global Config, State

    if State.fishTrackCooldownUntil > 0 && A_TickCount < State.fishTrackCooldownUntil {
        return false
    }

    if State.keySource = "fish" && State.keyStart > 0 {
        elapsed := A_TickCount - State.keyStart
        if elapsed < Config.Timings.fishTrackHold {
            return true
        }

        ReleaseKey()
        State.keySource := ""
        State.fishTrackCooldownUntil := A_TickCount + Config.Timings.fishTrackCooldown
        return false
    }

    area := Config.Areas["fish"]
    fishX := 0
    fishY := 0

    if !PixelSearch(&fishX, &fishY, area.x1, area.y1, area.x2, area.y2, Config.Colors.fish, Config.Tolerance.fish) {
        return false
    }

    deltaX := fishX - Config.RodRef.x
    if Abs(deltaX) < Config.FishDeadzone {
        return true
    }

    key := deltaX < 0 ? "a" : "d"
    SetMovementKey(key, "fish")
    Log("FISH_TRACK", "Pez en X=" fishX " | Delta=" deltaX " -> " key)
    return true
}

SetMovementKey(key, source) {
    global State

    if State.currentKey = key && State.keySource = source {
        State.keyStart := A_TickCount
        return
    }

    ReleaseKey()
    Send("{" key " down}")

    State.currentKey := key
    State.keySource := source
    State.keyStart := A_TickCount
    State.arrowKey := source = "arrow" ? key : ""
    Log("KEY", "Manteniendo " key " por " source)
}

ReleaseKey() {
    global State

    if State.currentKey != "" {
        key := State.currentKey
        Send("{" key " up}")
    }

    State.currentKey := ""
    State.keyStart := 0
}

SafeReleaseAll() {
    global State

    try {
        Click("Up")
    }

    State.holdingClick := false
    ReleaseKey()
    State.keySource := ""
    State.arrowKey := ""
    State.fishTrackCooldownUntil := 0
}

IsFishSpotted() {
    global Config
    return (CheckPointColor("fishSpottedYellow", Config.Colors.fishSpottedYellow, Config.Tolerance.event)
    && CheckPointColor("fishSpottedOrange", Config.Colors.fishSpottedOrange, Config.Tolerance.event))
}

IsFishLost() {
    global Config
    return CheckPointColor("fishLost", Config.Colors.fishLost, Config.Tolerance.event)
}

IsFishCaught() {
    global Config

    if !SearchAreaForColor("caughtText", Config.Colors.fishCaughtOrange, Config.Tolerance.event) {
        return false
    }

    if !SearchAreaForColor("caughtText", Config.Colors.fishCaughtLight, Config.Tolerance.event) {
        return false
    }

    orangeMatches := CountColorInArea("caughtText", Config.Colors.fishCaughtOrange, Config.Tolerance.event, Config.CaughtTextSampleStep,
        Config.CaughtTextMinOrange)
    if orangeMatches < Config.CaughtTextMinOrange {
        return false
    }

    lightMatches := CountColorInArea("caughtText", Config.Colors.fishCaughtLight, Config.Tolerance.event, Config.CaughtTextSampleStep,
        Config.CaughtTextMinLight)
    if lightMatches < Config.CaughtTextMinLight {
        return false
    }

    Log("DETECT", "Texto Caught it detectado | naranja>=" orangeMatches " claro>=" lightMatches)
    return true
}

ShouldCheckContinueButton() {
    global Config, State

    if State.status = "recoveringResource" || State.status = "stopped" {
        return false
    }

    if State.lastContinueCheck = 0 || A_TickCount - State.lastContinueCheck >= Config.ContinueCheckInterval {
        State.lastContinueCheck := A_TickCount
        return true
    }

    return false
}

IsContinueButtonVisible() {
    global Config
    return CheckPointColor("continueButton", Config.Colors.continueButton, Config.Tolerance.button)
}

IsTensionDanger() {
    global Config
    return (CheckPointColor("tensionCritical", Config.Colors.tensionCritical, Config.Tolerance.tension)
    || CheckPointColor("tensionDanger", Config.Colors.tensionDanger, Config.Tolerance.tension))
}

HasNoArrowTimedOut() {
    global Config, State
    return State.lastArrowSeen > 0 && A_TickCount - State.lastArrowSeen > Config.NoArrowTimeout
}

IsResourceEmpty(kind) {
    global Config
    pointName := kind = "bait" ? "baitMissingIndicator" : "rodMissingIndicator"
    return CheckPointColor(pointName, Config.Colors.resourceMissing, Config.Tolerance.resource)
}

ClickPoint(name) {
    global Config
    MoveToPoint(name)
    Sleep(Config.Timings.clickDelay)
    Click("Left")
}

MoveToPoint(name) {
    global Config
    pt := Config.Points[name]
    MouseMove(pt.x, pt.y, 0)
}

CheckPointColor(pointName, targetColor, tolerance) {
    global Config
    pt := Config.Points[pointName]
    color := PixelGetColor(pt.x, pt.y)
    return ColorMatch(color, targetColor, tolerance)
}

CheckPointAnyColor(pointName, colors, tolerance) {
    for _, targetColor in colors {
        if CheckPointColor(pointName, targetColor, tolerance) {
            return true
        }
    }

    return false
}

SearchAreaForColor(areaName, targetColor, tolerance) {
    global Config
    area := Config.Areas[areaName]
    foundX := 0
    foundY := 0
    return PixelSearch(&foundX, &foundY, area.x1, area.y1, area.x2, area.y2, targetColor, tolerance)
}

CountColorInArea(areaName, targetColor, tolerance, step, stopAt := 0) {
    global Config

    area := Config.Areas[areaName]
    matches := 0

    y := area.y1
    while y <= area.y2 {
        x := area.x1
        while x <= area.x2 {
            if ColorMatch(PixelGetColor(x, y), targetColor, tolerance) {
                matches += 1
                if stopAt > 0 && matches >= stopAt {
                    return matches
                }
            }
            x += step
        }
        y += step
    }

    return matches
}

ColorMatch(colorA, colorB, tolerance) {
    colorA := Integer(colorA)
    colorB := Integer(colorB)

    return (Abs(((colorA >> 16) & 0xFF) - ((colorB >> 16) & 0xFF)) <= tolerance
    && Abs(((colorA >> 8) & 0xFF) - ((colorB >> 8) & 0xFF)) <= tolerance
    && Abs((colorA & 0xFF) - (colorB & 0xFF)) <= tolerance)
}

FatalStop(message) {
    global State

    StopTimer()
    State.active := false
    State.status := "stopped"
    SafeReleaseAll()
    Log("ERROR", message)
    MsgBox(message, "AutoFishing", "Iconx")
    ExitApp(1)
}

Log(type, message) {
    global Config

    if !Config.LogEnabled {
        return
    }

    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    line := "[" timestamp "] [" type "] " message "`r`n"

    loop 3 {
        try {
            FileAppend(line, Config.LogPath, "UTF-8")
            return
        } catch {
            Sleep(20)
        }
    }
}

OnExitHandler(reason, exitCode) {
    try {
        SafeReleaseAll()
        Log("EXIT", "Script cerrado: " reason " | Codigo: " exitCode)
    }
}
