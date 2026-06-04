/************************************************************************
 * @description Automatiza la pesca mediante deteccion de pixeles.
 * @author Joseleelsuper, Haru
 * @date 2026/06/04
 * @version 4.0.0
 ***********************************************************************/

#Requires AutoHotkey v2.0
#SingleInstance Force

class AutoFishingConfig {
    static Environment := {
        SendMode: "Input",
        WorkingDir: A_ScriptDir,
        CoordModeTarget: "Screen"
    }

    static Screen := {
        BaseWidth: 1920,
        BaseHeight: 1080
    }

    static Scale := {
        FactorFormat: "{:.4f}"
    }

    static Window := {
        Executables: ["BPSR.exe", "BPSR_EPIC.exe", "BPSR_Steam.exe"]
    }

    static Keys := {
        Toggle: "F9",
        Exit: "F10",
        BaitMenu: "n",
        RodMenu: "m",
        Left: "a",
        Right: "d"
    }

    static Input := {
        MouseDown: "Down",
        MouseUp: "Up",
        LeftDown: "{a down}",
        LeftUp: "{a up}",
        RightDown: "{d down}",
        RightUp: "{d up}"
    }

    static Text := {
        Empty: "",
        ListSeparator: ", "
    }

    static LogLevels := {
        Debug: "DEBUG",
        Info: "INFO",
        Warning: "WARNING",
        Error: "ERROR"
    }

    static Log := {
        FilePath: A_ScriptDir "\BPSR-AutoFishing.log",
        TimeFormat: "HH:mm:ss",
        Encoding: "UTF-8"
    }

    static Messages := {
        ScriptStarted: "Script activado",
        ScriptStopped: "Script desactivado",
        ExitRequested: "F10 pulsado; cerrando script",
        ExitHandler: "Cierre detectado por AutoHotkey",
        Summary: "Resumen final | Peces ganados: {1} | Peces perdidos: {2} | Cañas rotas/perdidas: {3}",
        GameWindowFound: "Ventana del juego detectada | Exe: {1} | Cliente: {2},{3} | Tamaño: {4}x{5}",
        GameWindowInvalid: "Ventana del juego inválida | Exe: {1} | Cliente: {2},{3} | Tamaño: {4}x{5}",
        GameWindowMissing: "No se detectó la ventana del juego. Ejecutables revisados: {1}",
        GameWindowLost: "Ventana del juego no disponible; deteniendo bot",
        ScaleApplied: "Escala aplicada | Base: {1}x{2} | Ventana: {3}x{4} | Factor: {5}x{6}",
        ResourceCheck: "Comprobando cañas y cebos",
        BaitNeeded: "Selección de cebo necesaria",
        RodNeeded: "Caña rota/perdida detectada; intentando seleccionar otra",
        Cast: "Lanzando anzuelo",
        WaitingFish: "Esperando pez",
        FishDetected: "Pez detectado; iniciando minijuego",
        ContinueCheck: "Comprobando pantalla de continuación",
        ContinueClicked: "Pantalla de continuación detectada; continuando",
        ContinueMissing: "No se detectó pantalla de continuación tras el minijuego",
        CycleComplete: "Ciclo completado",
        MinigameClickHeld: "Click mantenido para minijuego",
        MinigameMissing: "Pantalla de minijuego no detectada tras iniciar",
        MinigameStarted: "Minijuego iniciado",
        MinigameFinished: "Minijuego terminado",
        FishLost: "Pez perdido detectado",
        TensionHigh: "Tensión peligrosa; soltando click temporalmente",
        TensionRecovered: "Tensión estabilizada; manteniendo click",
        TensionDisabledByProgress: "Comprobación de tensión desactivada; pez por encima del 50%",
        TensionDisabledByTimeout: "Comprobación de tensión desactivada; tiempo máximo de tensión alcanzado",
        ArrowLeft: "Flecha izquierda detectada",
        ArrowRight: "Flecha derecha detectada",
        ArrowBoth: "Ambos puntos de flecha coinciden; no se cambia dirección",
        ArrowOpposite: "Flecha contraria detectada; cancelando bloqueo",
        ArrowRepeatLock: "Misma flecha detectada dos veces en la ventana configurada; manteniendo dirección",
        RodCentered: "Sin flecha activa; centrando caña"
    }

    static Colors := {
        Button: 0xE8E8E8,
        ScreenMain: 0x207584,
        NoRods: 0x889098,
        NoBaits: 0xD3D3D3,
        FishSpotted: 0xF7B916,
        ArrowLeft: 0xFF9908,
        ArrowRight: 0xFF9A0C,
        FishingScreen: 0xFBFDFD,
        TensionRed: 0xDB0002,
        TensionCritical: 0xFFFFFF,
        TensionDanger: 0xDC0200,
        FishProgressCheckpoint: 0xFDFDEE,
        FishLost: 0xD2E6FF
    }

    static Points := {
        ContinueButton: { x: 1575, y: 960, color: 0xE8E8E8 },
        ScreenMain: { x: 1215, y: 1000, color: 0x207584 },
        SelectRods: { x: 1660, y: 605, color: 0xE8E8E8 },
        SelectBaits: { x: 1390, y: 615, color: 0xE8E8E8 },
        NoRods: { x: 1645, y: 1035, color: 0x889098 },
        NoBaits: { x: 1395, y: 1015, color: 0xD3D3D3 },
        FishSpotted: { x: 955, y: 470, color: 0xF7B916 },
        LeftArrow: { x: 820, y: 540, color: 0xFF9908 },
        RightArrow: { x: 1070, y: 540, color: 0xFF9A0C },
        FishingScreen: { x: 675, y: 905, color: 0xFBFDFD },
        RedTensionBar: { x: 1250, y: 895, color: 0xDB0002 },
        TensionCritical: { x: 1250, y: 895, color: 0xFFFFFF },
        TensionDanger: { x: 1200, y: 895, color: 0xDC0200 },
        FishProgressCheckpoint: { x: 985, y: 895, color: 0xFDFDEE },
        FishLost: { x: 1125, y: 680, color: 0xD2E6FF }
    }

    static Tolerances := {
        Default: 20,
        Resource: 20,
        Button: 20,
        FishSpotted: 20,
        Arrow: 35,
        FishingScreen: 35,
        Tension: 30,
        FishProgress: 20,
        FishLost: 25
    }

    static Timings := {
        WaitForFishLoop: 10,
        ResourceMenuDelay: 500,
        ResourceSelectDelay: 500,
        AfterMinigame: 4000,
        AfterCycle: 1000,
        ContinueRetryDelay: 500,
        MinigameStartTimeout: 3000,
        MinigameLoop: 10,
        ArrowHold: 1500,
        RepeatArrowWindow: 5000,
        TensionRelease: 400,
        TensionDisableTimeout: 60000,
        ScreenLost: 350
    }

    static Attempts := {
        ContinueScreen: 3
    }

    static Counters := {
        Initial: 0,
        Increment: 1
    }

    static ColorMath := {
        RedShift: 16,
        GreenShift: 8,
        ChannelMask: 0xFF
    }

    static Results := {
        Caught: "caught",
        Lost: "lost",
        Unknown: "unknown"
    }
}

class AutoFishingBot {
    __New(config) {
        this.cfg := config
        this.active := false
        this.summaryLogged := false
        this.rodMissingActive := false
        this.fishLostActive := false
        this.currentKey := this.cfg.Text.Empty
        this.gameWindow := false
        this.scale := false
        this.stats := {
            fishCaught: this.cfg.Counters.Initial,
            fishLost: this.cfg.Counters.Initial,
            rodsLost: this.cfg.Counters.Initial
        }
    }

    ConfigureEnvironment() {
        SendMode(this.cfg.Environment.SendMode)
        SetWorkingDir(this.cfg.Environment.WorkingDir)
        CoordMode("Pixel", this.cfg.Environment.CoordModeTarget)
        CoordMode("Mouse", this.cfg.Environment.CoordModeTarget)
    }

    Toggle(*) {
        if (this.active) {
            this.active := false
            this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.ScriptStopped)
            this.ReleaseAll()
            return
        }

        if (!this.RefreshGameWindow()) {
            return
        }

        this.active := true
        this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.ScriptStarted)
        this.Run()
    }

    Exit(*) {
        this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.ExitRequested)
        this.active := false
        this.ReleaseAll()
        this.LogSummary()
        ExitApp()
    }

    HandleExit(reason, exitCode) {
        this.active := false
        this.ReleaseAll()
        if (!this.summaryLogged) {
            this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.ExitHandler ": " reason)
            this.LogSummary()
        }
    }

    Run() {
        while (this.active) {
            if (!this.RefreshGameWindow()) {
                this.active := false
                this.ReleaseAll()
                this.Log(this.cfg.LogLevels.Error, this.cfg.Messages.GameWindowLost)
                break
            }

            this.Log(this.cfg.LogLevels.Debug, this.cfg.Messages.ResourceCheck)
            this.CheckBaitsAndRods()

            if (!this.active) {
                break
            }

            this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.Cast)
            this.fishLostActive := false
            Click()

            this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.WaitingFish)
            if (!this.WaitForFish()) {
                break
            }

            this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.FishDetected)
            result := this.StartMinigame()

            Sleep(this.cfg.Timings.AfterMinigame)

            if (!this.active) {
                break
            }

            this.Log(this.cfg.LogLevels.Debug, this.cfg.Messages.ContinueCheck)
            if (!this.CheckContinueScreen() && result != this.cfg.Results.Lost) {
                if (this.IsFishLost()) {
                    this.RecordFishLost()
                } else {
                    this.Log(this.cfg.LogLevels.Warning, this.cfg.Messages.ContinueMissing)
                }
            }

            this.Log(this.cfg.LogLevels.Debug, this.cfg.Messages.CycleComplete)
            Sleep(this.cfg.Timings.AfterCycle)
        }

        this.ReleaseAll()
    }

    CheckBaitsAndRods() {
        if (this.PointMatches(this.cfg.Points.NoBaits, this.cfg.Tolerances.Resource)) {
            this.Log(this.cfg.LogLevels.Warning, this.cfg.Messages.BaitNeeded)
            Send(this.cfg.Keys.BaitMenu)
            Sleep(this.cfg.Timings.ResourceMenuDelay)
            this.ClickPoint(this.cfg.Points.SelectBaits)
            Sleep(this.cfg.Timings.ResourceSelectDelay)
        }

        if (this.PointMatches(this.cfg.Points.NoRods, this.cfg.Tolerances.Resource)) {
            if (!this.rodMissingActive) {
                this.stats.rodsLost += this.cfg.Counters.Increment
                this.Log(this.cfg.LogLevels.Warning, this.cfg.Messages.RodNeeded)
            }

            this.rodMissingActive := true
            Send(this.cfg.Keys.RodMenu)
            Sleep(this.cfg.Timings.ResourceMenuDelay)
            this.ClickPoint(this.cfg.Points.SelectRods)
            Sleep(this.cfg.Timings.ResourceSelectDelay)
        } else {
            this.rodMissingActive := false
        }
    }

    WaitForFish() {
        while (this.active) {
            if (this.PointMatches(this.cfg.Points.FishSpotted, this.cfg.Tolerances.FishSpotted)) {
                Click()
                return true
            }

            if (this.PointMatches(this.cfg.Points.ScreenMain, this.cfg.Tolerances.Default)) {
                Click()
            }

            Sleep(this.cfg.Timings.WaitForFishLoop)
        }

        return false
    }

    CheckContinueScreen() {
        attempts := this.cfg.Counters.Initial

        while (attempts < this.cfg.Attempts.ContinueScreen) {
            if (this.PointMatches(this.cfg.Points.ContinueButton, this.cfg.Tolerances.Button)) {
                this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.ContinueClicked)
                this.ClickPoint(this.cfg.Points.ContinueButton)
                this.stats.fishCaught += this.cfg.Counters.Increment
                this.fishLostActive := false
                return true
            }

            Sleep(this.cfg.Timings.ContinueRetryDelay)
            attempts += this.cfg.Counters.Increment
        }

        return false
    }

    StartMinigame() {
        releaseClickUntil := this.cfg.Counters.Initial
        arrowHoldUntil := this.cfg.Counters.Initial
        lastArrowKey := this.cfg.Text.Empty
        lastArrowTick := this.cfg.Counters.Initial
        activeArrowKey := this.cfg.Text.Empty
        lockedKey := this.cfg.Text.Empty
        screenMissingSince := this.cfg.Counters.Initial
        minigameStartedAt := this.cfg.Counters.Initial
        enteredMinigame := false
        tensionPaused := false
        tensionCheckDisabled := false
        startDeadline := A_TickCount + this.cfg.Timings.MinigameStartTimeout

        try {
            this.Log(this.cfg.LogLevels.Debug, this.cfg.Messages.MinigameClickHeld)
            Click(this.cfg.Input.MouseDown)

            while (this.active && A_TickCount < startDeadline) {
                if (this.PointMatches(this.cfg.Points.FishingScreen, this.cfg.Tolerances.FishingScreen)) {
                    enteredMinigame := true
                    break
                }
                Sleep(this.cfg.Timings.MinigameLoop)
            }

            if (!enteredMinigame) {
                this.Log(this.cfg.LogLevels.Warning, this.cfg.Messages.MinigameMissing)
                return this.cfg.Results.Unknown
            }

            this.Log(this.cfg.LogLevels.Debug, this.cfg.Messages.MinigameStarted)
            minigameStartedAt := A_TickCount

            while (this.active) {
                if (this.IsFishLost()) {
                    this.RecordFishLost()
                    return this.cfg.Results.Lost
                }

                if (!this.PointMatches(this.cfg.Points.FishingScreen, this.cfg.Tolerances.FishingScreen)) {
                    if (screenMissingSince = this.cfg.Counters.Initial) {
                        screenMissingSince := A_TickCount
                    } else if (A_TickCount - screenMissingSince >= this.cfg.Timings.ScreenLost) {
                        this.Log(this.cfg.LogLevels.Debug, this.cfg.Messages.MinigameFinished)
                        return this.cfg.Results.Unknown
                    }
                } else {
                    screenMissingSince := this.cfg.Counters.Initial
                }

                if (!tensionCheckDisabled) {
                    tensionDisableMessage := this.GetTensionDisableMessage(minigameStartedAt)
                    if (tensionDisableMessage != this.cfg.Text.Empty) {
                        tensionCheckDisabled := true
                        this.Log(this.cfg.LogLevels.Info, tensionDisableMessage)
                        if (tensionPaused) {
                            Click(this.cfg.Input.MouseDown)
                            tensionPaused := false
                        }
                    }
                }

                if (!tensionCheckDisabled && this.IsTensionDanger()) {
                    releaseClickUntil := A_TickCount + this.cfg.Timings.TensionRelease
                    if (!tensionPaused) {
                        this.Log(this.cfg.LogLevels.Warning, this.cfg.Messages.TensionHigh)
                        Click(this.cfg.Input.MouseUp)
                        tensionPaused := true
                    }
                } else if (tensionPaused && A_TickCount >= releaseClickUntil) {
                    this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.TensionRecovered)
                    Click(this.cfg.Input.MouseDown)
                    tensionPaused := false
                }

                detectedKey := this.DetectArrow()
                if (detectedKey != this.cfg.Text.Empty) {
                    isNewArrow := detectedKey != activeArrowKey
                    activeArrowKey := detectedKey
                    arrowHoldUntil := A_TickCount + this.cfg.Timings.ArrowHold

                    if (isNewArrow) {
                        if (lockedKey != this.cfg.Text.Empty && detectedKey != lockedKey) {
                            this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.ArrowOpposite)
                            lockedKey := this.cfg.Text.Empty
                        }

                        if (lockedKey = this.cfg.Text.Empty && detectedKey = lastArrowKey && A_TickCount -
                            lastArrowTick <= this.cfg.Timings.RepeatArrowWindow) {
                            lockedKey := detectedKey
                            this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.ArrowRepeatLock)
                        }

                        lastArrowKey := detectedKey
                        lastArrowTick := A_TickCount
                    }

                    this.HoldDirection(detectedKey)
                } else {
                    activeArrowKey := this.cfg.Text.Empty
                    if (lockedKey = this.cfg.Text.Empty && this.currentKey != this.cfg.Text.Empty && A_TickCount >=
                        arrowHoldUntil) {
                        this.Log(this.cfg.LogLevels.Debug, this.cfg.Messages.RodCentered)
                        this.ReleaseDirection()
                    }
                }

                Sleep(this.cfg.Timings.MinigameLoop)
            }
        } finally {
            this.ReleaseAll()
        }

        return this.cfg.Results.Unknown
    }

    DetectArrow() {
        leftDetected := this.PointMatches(this.cfg.Points.LeftArrow, this.cfg.Tolerances.Arrow)
        rightDetected := this.PointMatches(this.cfg.Points.RightArrow, this.cfg.Tolerances.Arrow)

        if (leftDetected && !rightDetected) {
            return this.cfg.Keys.Left
        }

        if (rightDetected && !leftDetected) {
            return this.cfg.Keys.Right
        }

        if (leftDetected && rightDetected) {
            this.Log(this.cfg.LogLevels.Warning, this.cfg.Messages.ArrowBoth)
        }

        return this.cfg.Text.Empty
    }

    HoldDirection(key) {
        if (this.currentKey = key) {
            return
        }

        this.ReleaseDirection()

        if (key = this.cfg.Keys.Left) {
            Send(this.cfg.Input.LeftDown)
            this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.ArrowLeft)
        } else if (key = this.cfg.Keys.Right) {
            Send(this.cfg.Input.RightDown)
            this.Log(this.cfg.LogLevels.Info, this.cfg.Messages.ArrowRight)
        }

        this.currentKey := key
    }

    ReleaseDirection() {
        Send(this.cfg.Input.LeftUp)
        Send(this.cfg.Input.RightUp)
        this.currentKey := this.cfg.Text.Empty
    }

    ReleaseAll() {
        this.ReleaseDirection()
        Click(this.cfg.Input.MouseUp)
    }

    IsTensionDanger() {
        return (this.PointMatches(this.cfg.Points.RedTensionBar, this.cfg.Tolerances.Tension)
        || this.PointMatches(this.cfg.Points.TensionCritical, this.cfg.Tolerances.Tension)
        || this.PointMatches(this.cfg.Points.TensionDanger, this.cfg.Tolerances.Tension))
    }

    GetTensionDisableMessage(minigameStartedAt) {
        if (!this.PointMatches(this.cfg.Points.FishProgressCheckpoint, this.cfg.Tolerances.FishProgress)) {
            return this.cfg.Messages.TensionDisabledByProgress
        }

        if (A_TickCount - minigameStartedAt >= this.cfg.Timings.TensionDisableTimeout) {
            return this.cfg.Messages.TensionDisabledByTimeout
        }

        return this.cfg.Text.Empty
    }

    IsFishLost() {
        return this.PointMatches(this.cfg.Points.FishLost, this.cfg.Tolerances.FishLost)
    }

    RecordFishLost() {
        if (this.fishLostActive) {
            return
        }

        this.stats.fishLost += this.cfg.Counters.Increment
        this.fishLostActive := true
        this.Log(this.cfg.LogLevels.Warning, this.cfg.Messages.FishLost)
    }

    PointMatches(point, tolerance) {
        scaledPoint := this.ScalePoint(point)
        return this.ColorTolerance(PixelGetColor(scaledPoint.x, scaledPoint.y), point.color, tolerance)
    }

    ClickPoint(point) {
        scaledPoint := this.ScalePoint(point)
        Click(scaledPoint.x, scaledPoint.y)
    }

    ScalePoint(point) {
        return {
            x: this.gameWindow.x + this.ScaleX(point.x),
            y: this.gameWindow.y + this.ScaleY(point.y)
        }
    }

    ScaleX(value) {
        return Round(value * this.scale.x)
    }

    ScaleY(value) {
        return Round(value * this.scale.y)
    }

    FormatScale(value) {
        return Format(this.cfg.Scale.FactorFormat, value)
    }

    RefreshGameWindow() {
        for exeName in this.cfg.Window.Executables {
            windowTitle := "ahk_exe " exeName

            if (!WinExist(windowTitle)) {
                continue
            }

            clientX := this.cfg.Counters.Initial
            clientY := this.cfg.Counters.Initial
            clientWidth := this.cfg.Counters.Initial
            clientHeight := this.cfg.Counters.Initial
            WinGetClientPos(&clientX, &clientY, &clientWidth, &clientHeight, windowTitle)

            if (clientWidth <= this.cfg.Counters.Initial || clientHeight <= this.cfg.Counters.Initial) {
                this.Log(this.cfg.LogLevels.Error, Format(this.cfg.Messages.GameWindowInvalid, exeName, clientX,
                    clientY,
                    clientWidth, clientHeight))
                continue
            }

            previousWindow := this.gameWindow
            this.gameWindow := {
                exe: exeName,
                x: clientX,
                y: clientY,
                width: clientWidth,
                height: clientHeight
            }
            this.scale := {
                x: clientWidth / this.cfg.Screen.BaseWidth,
                y: clientHeight / this.cfg.Screen.BaseHeight
            }

            windowChanged := (!previousWindow || previousWindow.exe != exeName || previousWindow.x != clientX ||
                previousWindow.y != clientY || previousWindow.width != clientWidth || previousWindow.height !=
                clientHeight)

            if (windowChanged) {
                this.Log(this.cfg.LogLevels.Info, Format(this.cfg.Messages.GameWindowFound, exeName, clientX, clientY,
                    clientWidth, clientHeight))
                this.Log(this.cfg.LogLevels.Info, Format(this.cfg.Messages.ScaleApplied, this.cfg.Screen.BaseWidth,
                    this.cfg.Screen.BaseHeight, clientWidth, clientHeight, this.FormatScale(this.scale.x),
                    this.FormatScale(this.scale.y)))
            }

            return true
        }

        this.Log(this.cfg.LogLevels.Error, Format(this.cfg.Messages.GameWindowMissing, this.FormatExecutableList()))
        return false
    }

    FormatExecutableList() {
        executableList := this.cfg.Text.Empty
        separator := this.cfg.Text.Empty

        for exeName in this.cfg.Window.Executables {
            executableList .= separator exeName
            separator := this.cfg.Text.ListSeparator
        }

        return executableList
    }

    ColorTolerance(pixelColor, targetColor, tolerance) {
        redA := (pixelColor >> this.cfg.ColorMath.RedShift) & this.cfg.ColorMath.ChannelMask
        greenA := (pixelColor >> this.cfg.ColorMath.GreenShift) & this.cfg.ColorMath.ChannelMask
        blueA := pixelColor & this.cfg.ColorMath.ChannelMask

        redB := (targetColor >> this.cfg.ColorMath.RedShift) & this.cfg.ColorMath.ChannelMask
        greenB := (targetColor >> this.cfg.ColorMath.GreenShift) & this.cfg.ColorMath.ChannelMask
        blueB := targetColor & this.cfg.ColorMath.ChannelMask

        return (Abs(redA - redB) <= tolerance && Abs(greenA - greenB) <= tolerance && Abs(blueA - blueB) <= tolerance)
    }

    LogSummary() {
        if (this.summaryLogged) {
            return
        }

        this.summaryLogged := true
        this.Log(this.cfg.LogLevels.Info, Format(this.cfg.Messages.Summary, this.stats.fishCaught, this.stats.fishLost,
            this.stats.rodsLost))
    }

    Log(level, message) {
        timestamp := FormatTime(A_Now, this.cfg.Log.TimeFormat)
        FileAppend("[" timestamp "] [" level "] " message "`r`n", this.cfg.Log.FilePath, this.cfg.Log.Encoding)
    }
}

Bot := AutoFishingBot(AutoFishingConfig)
Bot.ConfigureEnvironment()

Hotkey(AutoFishingConfig.Keys.Toggle, ToggleHotkey)
Hotkey(AutoFishingConfig.Keys.Exit, ExitHotkey)
OnExit(ExitHandler)

ToggleHotkey(*) {
    global Bot
    Bot.Toggle()
}

ExitHotkey(*) {
    global Bot
    Bot.Exit()
}

ExitHandler(reason, exitCode) {
    global Bot
    Bot.HandleExit(reason, exitCode)
}
