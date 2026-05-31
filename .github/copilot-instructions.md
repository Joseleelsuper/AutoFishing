## Guia para agentes de IA en este repo (AutoFishing)

Este proyecto es un script de AutoHotkey v2.0.19 para automatizar la pesca del juego mediante deteccion de pixeles y control de raton/teclado.

### Vision general y arquitectura

- Runtime: AutoHotkey v2.0.19. No introducir sintaxis v1.
- Archivo principal: `AutoFishing.ahk`.
- Estructura:
  - `BuildConfig()`: define colores, puntos base `1920x1080`, areas de busqueda, tolerancias, timings, ejecutables del juego y logging.
  - `Initialize()`: detecta la ventana del juego, calcula escala y falla con aviso si la ventana no existe.
  - `State.status`: estados explicitos `idle`, `waitingBite`, `fishing`, `tensionRelease`, `recoveringResource`, `stopped`.
  - `ProcessFishing()`: timer v2 con funcion, no labels.
  - Helpers de entrada/salida: `SafeReleaseAll()`, `ReleaseKey()`, `ClickPoint()`, `MoveToPoint()`.
  - Helpers visuales: `CheckPointColor()`, `CheckPointAnyColor()`, `SearchAreaForColor()`, `ColorMatch()`.

### Atajos y controles

- `F9`: activa/desactiva la automatizacion.
- `F10`: libera click/teclas, detiene timer y cierra.
- Cualquier salida fatal debe llamar a `FatalStop()` para liberar controles, registrar en `AutoFishing.log`, mostrar `MsgBox` y terminar.

### Flujo principal

- `StartCycle()` valida recursos y lanza la cana.
- Si falta bait, `RecoverResource("bait")` abre menu con `N`, verifica el boton `Use` y selecciona cebo.
- Si falta rod, `RecoverResource("rod")` abre menu con `M`, verifica el boton `Use` y selecciona cana.
- Si no hay boton `Use`, el script termina con aviso; no debe hacer clicks ciegos.
- En `waitingBite`, el script espera el indicador compuesto de pez encontrado.
- Comprobar cada 3s si el boton `Continue fishing` esta visible por color blanco en su punto; si aparece, pulsarlo y relanzar.
- En `fishing`, el orden de prioridad restante es: pez perdido, texto `Caught it!`, tension peligrosa, flechas A/D, seguimiento del pez.
- La tension peligrosa suelta click temporalmente y reanuda despues de `Config.Timings.tensionRelease`.

### Convenciones

- Mantener coordenadas en `Config.PointsBase` o `Config.AreasBase` usando referencia `1920x1080`; no usar coordenadas absolutas directas en la logica.
- Mantener colores como enteros RGB `0xRRGGBB`.
- Mantener tolerancias centralizadas en `Config.Tolerance`.
- Mantener sleeps centralizados en `Config.Timings`.
- Usar `SetTimer(ProcessFishing, intervalo)` y `SetTimer(ProcessFishing, 0)`.
- Usar `PixelGetColor(x, y)`, `PixelSearch(&x, &y, ...)`, `Click("Down"/"Up"/"Left")`, `Send("{a down}")` y `Buffer()`/`NumGet()` para llamadas Win32.

### Validacion

- Ejecutar con AutoHotkey v2.0.19:
  - `AutoHotkey.exe /ErrorStdOut AutoFishing.ahk`
- Revisar que no haya restos v1:
  - `rg "SetTimer,|PixelSearch,|PixelGetColor,|ErrorLevel|MainLoop:|WinGet|VarSetCapacity" AutoFishing.ahk`
- Probar manualmente F9/F10, captura, perdida, tension, cambio de bait, cambio de cana y finalizacion sin recursos.

### Precauciones

- Si el juego corre como administrador, AutoHotkey tambien debe ejecutarse como administrador para que pixeles y entradas funcionen correctamente.
- HDR, filtros graficos o cambios de UI pueden requerir ajustar tolerancias o puntos.
- Los assets en `Assets/` son referencia de calibracion; no convertir el flujo a `ImageSearch` salvo que se decida explicitamente.
