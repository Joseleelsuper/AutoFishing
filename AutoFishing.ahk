#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance Force

; ==============================================
;  AutoFishing - Refactored
; ----------------------------------------------
;   @description: Automatiza la pesca mediante detección de píxeles
;   @author: Haru, Joseleelsuper
;   @controls: F9 = Toggle ON/OFF | F10 = Salir
; ==============================================

CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

global Config := {}
global State := {}

; ============================
;  Inicialización
; ============================
Init() {
    global Config, State

    ; -- Referencia base
    Config.Base := { w: 1920, h: 1080 }

    ; -- Intervalos
    Config.TimerInterval := 50
    Config.WatchdogTimeout := 30000            ; 30s sin pesca = relanzar

    ; -- Tolerancias de color
    Config.Tolerance := { primary: 20, arrow: 15 }

    ; -- Tiempos de espera (ms)
    Config.Timings := {}
    Config.Timings.afterFail := 3000           ; Espera tras fallo antes de relanzar
    Config.Timings.afterFinish := 2000         ; Espera tras éxito para botón continuar
    Config.Timings.afterContinue := 1000       ; Espera tras pulsar continuar antes de relanzar
    Config.Timings.tensionRelease := 800       ; Tiempo soltando por tensión 100%
    Config.Timings.clickDelay := 50            ; Delay entre acciones de click
    Config.Timings.resetMenuWait := 1000       ; Espera tras abrir menú reset

    ; -- Colores objetivo (0xRRGGBB)
    Config.Colors := {}
    Config.Colors.start := 0xFF5501            ; Pez picando (mantener click)
    Config.Colors.finish := 0xE8E8E8           ; Pesca completada
    Config.Colors.reset := 0x767C82            ; Caña rota (necesita reset)
    Config.Colors.tensionMax := 0xFFFFFF       ; Barra tensión al 100%
    Config.Colors.arrowA := [0xFE6C06, 0xFAB916, 0xFF5601]
    Config.Colors.arrowD := [0xFF5A01, 0xFAB916, 0xFF5601]

    ; -- Ejecutables del juego
    Config.GameExes := ["BPSR_STEAM.exe", "BPSR_EPIC.exe", "BPSR.exe"]

    ; -- Coordenadas base (1920x1080)
    Config.PointsBase := {}
    Config.PointsBase.center := { x: 954, y: 562 }       ; Centro (lanzar/mantener)
    Config.PointsBase.confirm := { x: 1463, y: 974 }     ; Botón confirmar/continuar
    Config.PointsBase.resetCheck := { x: 1650, y: 1029 } ; Detector caña rota
    Config.PointsBase.menuBtn := { x: 1788, y: 609 }     ; Botón menú reset
    Config.PointsBase.tensionBar := { x: 1248, y: 897 }  ; Barra tensión (extremo)
    Config.PointsBase.arrowA := { x: 851, y: 528 }
    Config.PointsBase.arrowD := { x: 1054, y: 536 }

    ; -- Detectar ventana del juego
    DetectGameWindow()
    if (Config.Game.w < 100 || Config.Game.h < 100) {
        MsgBox, 16, Error, No se detectó la ventana del juego.`nAbre el juego antes de ejecutar el script.
        ExitApp
    }

    ; -- Calcular escala y puntos
    Config.Scale := { x: Config.Game.w / Config.Base.w, y: Config.Game.h / Config.Base.h }
    Config.Points := {}
    for key, pt in Config.PointsBase {
        Config.Points[key] := { x: Round(pt.x * Config.Scale.x) + Config.Game.x
                              , y: Round(pt.y * Config.Scale.y) + Config.Game.y }
    }

    ; -- Logging
    Config.LogEnabled := true
    Config.LogPath := A_ScriptDir . "\AutoFishing.log"

    ; -- Estado inicial
    State.active := false
    State.fishing := false          ; ¿Pez en el anzuelo?
    State.fishStart := 0            ; Timestamp inicio pesca
    State.lastCast := 0             ; Timestamp último lanzamiento
    State.tensionPause := false     ; ¿Pausado por tensión?
    State.tensionStart := 0
    State.currentKey := ""          ; Tecla del minijuego activa

    Log("INIT", "Ventana: " . Config.Game.w . "x" . Config.Game.h . " @ (" . Config.Game.x . "," . Config.Game.y . ") | Escala: " . Round(Config.Scale.x, 2) . "x" . Round(Config.Scale.y, 2))
}

DetectGameWindow() {
    global Config
    for i, exe in Config.GameExes {
        WinGet, hwnd, ID, % "ahk_exe " . exe
        if (hwnd) {
            VarSetCapacity(rect, 16, 0)
            DllCall("GetClientRect", "Ptr", hwnd, "Ptr", &rect)
            VarSetCapacity(pt, 8, 0)
            DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", &pt)
            Config.Game := { x: NumGet(pt, 0, "Int"), y: NumGet(pt, 4, "Int")
                           , w: NumGet(rect, 8, "Int"), h: NumGet(rect, 12, "Int") }
            Log("INIT", "Juego detectado: " . exe)
            return
        }
    }
    Config.Game := { x: 0, y: 0, w: A_ScreenWidth, h: A_ScreenHeight }
    Log("WARN", "Juego no detectado, usando pantalla completa")
}

Init()
OnExit("OnExitHandler")

; ============================
;  Hotkeys
; ============================
F9::ToggleScript()
F10::ExitScript()

ToggleScript() {
    global Config, State
    State.active := !State.active
    if (State.active) {
        Log("TOGGLE", "Script ACTIVADO")
        CastRod()
        SetTimer, MainLoop, % Config.TimerInterval
    } else {
        Log("TOGGLE", "Script DESACTIVADO")
        SetTimer, MainLoop, Off
        CleanupState()
    }
}

ExitScript() {
    Log("EXIT", "Cerrando script (F10)")
    SetTimer, MainLoop, Off
    CleanupState()
    ExitApp
}

; ============================
;  Bucle Principal
; ============================
MainLoop:
    ProcessFishing()
return

ProcessFishing() {
    global Config, State

    ; 1) Verificar caña rota (prioridad máxima)
    if (CheckColor("resetCheck", Config.Colors.reset)) {
        HandleBrokenRod()
        return
    }

    ; 2) Si estamos pausados por tensión, esperar
    if (State.tensionPause) {
        if (A_TickCount - State.tensionStart >= Config.Timings.tensionRelease) {
            ResumeAfterTension()
        }
        return
    }

    ; 3) Si estamos pescando activamente
    if (State.fishing) {
        ; Verificar tensión al 100%
        if (CheckColor("tensionBar", Config.Colors.tensionMax)) {
            PauseTension()
            return
        }

        ; Verificar si completamos la pesca
        if (CheckColor("confirm", Config.Colors.finish)) {
            HandleFishCaught()
            return
        }

        ; Procesar minijuego de flechas
        ProcessArrows()
        return
    }

    ; 4) Esperando que pique un pez
    if (CheckColor("center", Config.Colors.start)) {
        StartFishing()
        return
    }

    ; 5) Watchdog: si pasa mucho tiempo sin actividad, relanzar
    if (State.lastCast && (A_TickCount - State.lastCast > Config.WatchdogTimeout)) {
        Log("WATCHDOG", "30s sin actividad -> Relanzando caña")
        CastRod()
    }
}

; ============================
;  Acciones de Pesca
; ============================
CastRod() {
    global Config, State
    ClickPoint("center")
    State.lastCast := A_TickCount
    State.fishing := false
    Log("CAST", "Caña lanzada")
}

StartFishing() {
    global Config, State
    MouseMove, % Config.Points.center.x, % Config.Points.center.y, 0
    Sleep, % Config.Timings.clickDelay
    Click, down, left
    State.fishing := true
    State.fishStart := A_TickCount
    Log("FISH", "¡Pez detectado! Manteniendo click...")
}

HandleFishCaught() {
    global Config, State
    elapsed := Round((A_TickCount - State.fishStart) / 1000, 1)

    ; Soltar click
    Click, up, left
    ReleaseKey()
    State.fishing := false

    Log("SUCCESS", "Pez capturado en " . elapsed . "s -> Esperando botón continuar...")

    ; Esperar y pulsar botón continuar
    Sleep, % Config.Timings.afterFinish
    ClickPoint("confirm")
    Log("ACTION", "Botón continuar pulsado")

    ; Esperar y relanzar
    Sleep, % Config.Timings.afterContinue
    CastRod()
}

HandleFishLost() {
    global Config, State
    Click, up, left
    ReleaseKey()
    State.fishing := false

    Log("FAIL", "Pesca fallida -> Esperando " . (Config.Timings.afterFail / 1000) . "s antes de relanzar")
    Sleep, % Config.Timings.afterFail
    CastRod()
}

HandleBrokenRod() {
    global Config, State

    ; Limpiar estado
    if (State.fishing) {
        Click, up, left
        ReleaseKey()
        State.fishing := false
    }

    Log("RESET", "Caña rota detectada -> Abriendo menú para cambiar")

    Sleep, 500
    Send, m
    Sleep, % Config.Timings.resetMenuWait
    ClickPoint("menuBtn")
    Sleep, 1500
    ClickPoint("menuBtn")
    Sleep, 500

    Log("RESET", "Caña cambiada -> Relanzando")
    CastRod()
}

; ============================
;  Gestión de Tensión
; ============================
PauseTension() {
    global Config, State
    Click, up, left
    State.tensionPause := true
    State.tensionStart := A_TickCount
    Log("TENSION", "Tensión al 100% -> Soltando click temporalmente")
}

ResumeAfterTension() {
    global Config, State
    MouseMove, % Config.Points.center.x, % Config.Points.center.y, 0
    Sleep, % Config.Timings.clickDelay
    Click, down, left
    State.tensionPause := false
    State.fishing := true
    Log("TENSION", "Tensión normalizada -> Reanudando pesca")
}

; ============================
;  Minijuego de Flechas
; ============================
ProcessArrows() {
    global Config, State

    ; Detectar flecha D
    if (CheckColorMulti("arrowD", Config.Colors.arrowD)) {
        SetKey("d")
        return
    }

    ; Detectar flecha A
    if (CheckColorMulti("arrowA", Config.Colors.arrowA)) {
        SetKey("a")
        return
    }
}

SetKey(key) {
    global State
    if (State.currentKey = key)
        return
    ReleaseKey()
    Send, {%key% down}
    State.currentKey := key
    Log("ARROW", "Flecha " . key . " detectada -> Manteniendo tecla")
}

ReleaseKey() {
    global State
    if (State.currentKey) {
        k := State.currentKey
        Send, {%k% up}
        State.currentKey := ""
    }
}

; ============================
;  Utilidades
; ============================
ClickPoint(name) {
    global Config
    pt := Config.Points[name]
    MouseMove, % pt.x, % pt.y, 0
    Sleep, % Config.Timings.clickDelay
    Click, left
}

CheckColor(pointName, targetColor) {
    global Config
    pt := Config.Points[pointName]
    PixelGetColor, c, % pt.x, % pt.y, RGB
    return ColorMatch(c, targetColor, Config.Tolerance.primary)
}

CheckColorMulti(pointName, colorArray) {
    global Config
    pt := Config.Points[pointName]
    PixelGetColor, c, % pt.x, % pt.y, RGB
    for i, target in colorArray {
        if (ColorMatch(c, target, Config.Tolerance.arrow))
            return true
    }
    return false
}

ColorMatch(c1, c2, tol) {
    return (Abs(((c1 >> 16) & 0xFF) - ((c2 >> 16) & 0xFF)) <= tol
         && Abs(((c1 >> 8) & 0xFF) - ((c2 >> 8) & 0xFF)) <= tol
         && Abs((c1 & 0xFF) - (c2 & 0xFF)) <= tol)
}

CleanupState() {
    global State
    if (State.fishing || State.tensionPause)
        Click, up, left
    ReleaseKey()
    State.fishing := false
    State.tensionPause := false
    Log("CLEANUP", "Estado limpiado")
}

; ============================
;  Sistema de Logs
; ============================
Log(type, msg) {
    global Config
    if (!Config.LogEnabled)
        return
    FormatTime, ts, , yyyy-MM-dd HH:mm:ss
    line := "[" . ts . "] [" . type . "] " . msg . "`r`n"
    FileAppend, % line, % Config.LogPath, UTF-8
}

OnExitHandler(reason) {
    Log("EXIT", "Script cerrado: " . reason)
}
