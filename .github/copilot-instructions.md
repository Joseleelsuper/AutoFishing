## Guía para agentes de IA en este repo (AutoFishing)

Este proyecto es un script de AutoHotkey v1 para automatizar la pesca de un juego (Blue Protocol) vía detección de píxeles y control de ratón/teclado. Mantén estas pautas para ser productivo desde el primer minuto y no romper el flujo actual.

### Visión general y arquitectura
- **Lenguaje/Runtime**: AutoHotkey v1 (no v2). El código usa comandos legacy (`SetTimer` con etiqueta, `Click`, `Send`), objetos AHK v1 y hotkeys F9/F10.
- **Archivo principal**: `AutoFishing.ahk`.
- **Estructura de datos**:
	- `Config` (global): parámetros base (resolución 1920x1080), tolerancias, colores, puntos, escala, timings, logging, detección de ventana del juego.
	- `Config.Timings`: todos los `Sleep` centralizados (`afterFail`, `afterFinish`, `tensionRelease`, `arrowHold`, `fishTrackHold`, etc.).
	- `Config.GameExes`: lista de ejecutables del juego (`BPSR_STEAM.exe`, `BPSR_EPIC.exe`, `BPSR.exe`).
	- `State` (global): flags (`active`, `fishing`, `tensionPause`), timestamps (`fishStart`, `lastCast`, `keyStart`, `fishTrackEnd`), tecla activa (`currentKey`, `keySource`, `arrowKey`).
- **Flujo de inicialización**: `Init()` → `DetectGameWindow()` → calcula `Config.Scale` y `Config.Points` escalados → configura estado inicial.
- **Bucle principal**: `SetTimer, MainLoop` llama a `ProcessFishing()` cada 50ms.
- **Flujo en `ProcessFishing()` (prioridades)**:
	1. Pez escapado (detectar `fishEscaped`)
	2. Flechas del minijuego (A/D) - siempre verificar durante pesca
	3. Caña rota (solo si han pasado 3s desde lanzamiento)
	4. Pausa por tensión 100%
	5. Si pescando: tensión → pesca completada → flechas → seguimiento de pez
	6. Esperando pez: detectar color `start`
	7. Watchdog: relanzar tras 30s sin actividad
- **Logging**: `Log(type, msg)` a `AutoFishing.log`, activable con `Config.LogEnabled`.

### Atajos y controles
- **F9**: activar/desactivar automatización (inicia/detiene timer, lanza caña al activar).
- **F10**: salida segura (libera estado, apaga timer y cierra con `ExitApp`).

### Flujos y patrones clave del proyecto
- **Detección por color**: usa `CheckColor(pointName, targetColor)` con `ColorMatch()` para comparar RGB con tolerancia por canal.
	- `Config.Tolerance.primary` (20): para start/finish/reset/tensionMax/fishEscaped.
	- `Config.Tolerance.arrow` (15): para flechas A/D (arrays de colores).
	- `Config.Tolerance.fish` (30): para seguimiento del pez (más tolerante).
- **Coordenadas escaladas**: declara en `Config.PointsBase` (1920x1080), `Init()` genera `Config.Points` escalados con offset de ventana del juego.
- **Detección de pez escapado**: verifica `fishEscaped` constantemente durante pesca para reaccionar inmediatamente.
- **Gestión de tensión 100%**: detecta blanco puro (`0xFFFFFF`) en `tensionBar`. Suelta click temporalmente (`PauseTension()`) y reanuda con `ResumeAfterTension()`.
- **Minijuego de flechas**: `ProcessArrows()` detecta colores múltiples con `CheckColorMulti()`. Usa `SetKeyArrow()` y `ReleaseKey()` para garantizar solo una tecla activa.
- **Seguimiento del pez**: `TrackFish()` busca color del pez con `PixelSearch` en área definida (`Config.FishArea`). Calcula delta respecto a `Config.RodRef` y presiona A/D según dirección. Incluye zona muerta (`FishDeadzone`) y cooldown entre detecciones.
- **Prioridad flechas > pez**: las flechas interrumpen inmediatamente el seguimiento de pez (`State.keySource = "arrow"` vs `"fish"`).
- **Timings centralizados**: todos los `Sleep` refieren a `Config.Timings.*` para fácil ajuste.

### Ejemplos concretos (cómo extender sin romper)

**Añadir un nuevo punto/color a detectar:**
1. En `Init()`:
   ```ahk
   Config.Colors.miEvento := 0xRRGGBB
   Config.PointsBase.miEvento := { x: 100, y: 200 }  ; en base 1920x1080
   ```
2. El punto se escalará automáticamente a `Config.Points.miEvento`.
3. Usar en `ProcessFishing()`:
   ```ahk
   if (CheckColor("miEvento", Config.Colors.miEvento)) {
       ; acción...
   }
   ```

**Añadir detección con múltiples colores (como flechas):**
```ahk
Config.Colors.miArray := [0xFF0000, 0x00FF00, 0x0000FF]
if (CheckColorMulti("miPunto", Config.Colors.miArray)) { ... }
```

**Ajustar tolerancias**: incrementa/decrementa `Config.Tolerance.*` en pasos de 2-5 cuando haya falsos positivos/negativos.

### Funciones clave (API interna)
| Función | Descripción |
|---------|-------------|
| `CheckColor(pointName, color)` | Verifica color en punto con tolerancia `primary` |
| `CheckColorMulti(pointName, colorArray)` | Verifica contra array de colores con tolerancia `arrow` |
| `ColorMatch(c1, c2, tol)` | Compara dos colores RGB con tolerancia por canal |
| `ClickPoint(name)` | Mueve ratón al punto y hace click |
| `SetKeyArrow(key)` / `SetKeyFish(key, ...)` | Activa tecla con fuente identificada |
| `ReleaseKey()` | Suelta tecla activa y limpia estado |
| `CleanupState()` | Libera todo (click, teclas) al desactivar |
| `Log(type, msg)` | Escribe al log si está habilitado |

### Workflows de desarrollo
- **Ejecutar**: Abre `AutoFishing.ahk` con AutoHotkey v1.1.37.02. Usa F9/F10 para controlar.
- **Depurar**: Habilita `Config.LogEnabled := true` y revisa `AutoFishing.log`.
- **Compilar a EXE**: Usa Ahk2Exe → ejecuta `generateHash.ps1` para actualizar `hash.txt`.

### Convenciones importantes
- **Mantener v1**: No migrar a AHK v2 ni mezclar estilos.
- **Escalado automático**: Define puntos en `PointsBase` (1920x1080), nunca uses coordenadas absolutas.
- **No bloquear el timer**: Evita bucles largos en `ProcessFishing()`. Usa estados (`State.*`) y retorna.
- **Timings centralizados**: NUNCA usar `Sleep` con valores literales; usa `Config.Timings.*`.
- **Limpieza de estado**: Llama `CleanupState()` antes de desactivar o salir.
- **Detección de ventana**: El script detecta automáticamente la ventana del juego por ejecutable.

### Precauciones (errores comunes)
- **Permisos**: Si el juego corre elevado, ejecuta AHK como administrador.
- **Colores incorrectos**: HDR/post-procesado puede alterar colores. Ajusta tolerancias o desactiva filtros.
- **DPI/escala Windows**: El escalado interno minimiza problemas, pero puede requerir reajuste de puntos.

### Archivos del proyecto
| Archivo | Descripción |
|---------|-------------|
| `AutoFishing.ahk` | Script principal con toda la lógica |
| `generateHash.ps1` | Genera SHA-256 del EXE compilado |
| `hash.txt` | Hash publicado para verificación |
