# Poliquetos Asesinos v2 — Encargo 02: rescatar la simulación de Windows y validar el mundo 1

**Tipo:** corrección crítica de ejecución exportada + plan del mundo 1.  
**Base que debes inspeccionar primero:** `arte/integracion-godot-w01`, commit `9ea435b692b437deb202519076823d6fae47aac4` (verifica que siga siendo correcto).  
**Producto:** Godot 4.6.x, instaladores para Windows `Poliquetos-Normal-Instalar.exe` y `Poliquetos-Pruebas-Instalar.exe`. **No es HTML**.  
**Fuente de verdad de diseño:** `docs/specs/poliquetos-asesinos-v2.md`. Lee además `AGENTS.md`, `docs/procedimientos-v2.md`, `docs/decisiones.md`, `docs/v2-progreso.md` y el informe artístico `docs/arte/integracion-w01/README.md` si está presente.

## A. Evidencia y diagnóstico que deben reproducirse

El video del usuario (15,7 s) muestra un escenario nuevo del mundo 1, la nave moviéndose y disparos amarillos. Sin embargo, el HUD permanece en `M1 00:00` y la barra de progreso parece inmóvil entre aproximadamente los segundos 4 y 14 del video. No se observan poliquetos ni ataques enemigos. **El video no demuestra qué ocurre después de 15,7 s**, pero sí es compatible con una simulación de etapa detenida.

**Hipótesis técnica prioritaria:** en `src/core/game.gd` se condiciona la creación de `stage_system`, `weapon_system` y `boss_system` a `FileAccess.file_exists("res://src/.../*.gd")`. Al exportar a Windows, la ubicación/formato del recurso puede cambiar: `FileAccess` no es un detector fiable de scripts importados en un PCK. El movimiento y disparo básico pueden funcionar sin `stage_system`, pero sin él `game.world_time` y `game.scroll` no avanzan y no se generan las oleadas. Godot recomienda usar mecanismos de `ResourceLoader` para recursos exportados.

No asumas que la hipótesis está demostrada: **instrumenta y confirma** mediante un build exportado, registrando el estado y resultado de carga de cada módulo. Si es la causa, reemplaza las comprobaciones por `preload(...)` o `ResourceLoader.load/exists(...)`, con error explícito si falla. Un módulo requerido no debe poder quedar `null` silenciosamente. Revisa también guardas `FileAccess.file_exists` relacionadas con `.gd` en otros scripts; **no sustituyas a ciegas la lectura de archivos JSON externos con FileAccess**, pues tienen otro propósito.

### Primera entrega obligatoria (una sola corrección, sin construir aún todo el mundo)

1. Confirma rama, commit, dos modos de juego y que los PNG ya integrados siguen intactos.
2. Reproduce el fallo **en una exportación/instalador equivalente al que juega el usuario**, no solo en `godot --headless` desde el directorio fuente.
3. Registra `game.state`, `world_time`, `scroll`, número de enemigos, `stage_system != null`, `weapon_system != null`, `boss_system != null` al comenzar y a los 5, 12 y 20 segundos de tiempo efectivo.
4. Corrige la causa; no alteres artificialmente el contador del HUD para aparentar progreso.
5. Comprueba que en el juego instalado: el contador llega a `00:20`; el fondo avanza con parallax; a los 10 s de juego aparece la primera oleada `Hydroides` (`data/waves/world_01.json`); los enemigos entran desde el lado derecho, se mueven, pueden atacar, recibir disparos y morir.
6. Verifica en edición Normal **y** Pruebas, con vídeo o capturas reales y logs del PCK/EXE ejecutado.
7. Ejecuta pruebas nativas y de datos existentes; agrega al menos una **prueba de integración de exportación** que falle si cualquiera de los tres controladores requeridos está ausente o el contador no avanza. Las pruebas en editor no sustituyen la prueba exportada.
8. Entrega una rama dedicada (`fix/w01-export-stage-runtime` o equivalente), commit, informe de causa, archivos cambiados, pruebas aprobadas/fallidas, capturas y los dos instaladores verificables. No declares corregido lo que no probaste.

**Criterio de salida:** el usuario puede iniciar el instalador Windows, mover la nave, disparar y observar el avance del cronómetro y una oleada real. **Solicita aprobación del usuario antes de pasar al siguiente bloque**.

## B. Plan secuencial posterior: terminar mundo 1 sin rehacer el proyecto

Una vez aprobado el arreglo de exportación, trabaja **por bloques acotados**; ninguno autoriza desarrollar mundos 2–14.

### Bloque B1 — Sensación de juego (*shoot 'em up* lateral)
- Scroll horizontal automático de **60 px/s** y 3–4 capas de fondo desplazándose a distintas velocidades; el escenario no debe parecer una fotografía fija.
- Nave movible en ocho direcciones con WASD/flechas y mando; velocidad inicial **160 px/s** sin inercia; límites dentro de **640×336**. Disparo mantenido **Z/Espacio**, bomba **X**, pausa **Esc/P**.
- Diferenciar visualmente nave, disparos, balas enemigas y fondos con sprites PNG (sin geometrías finales de código); sin perder legibilidad por brillos o fondos muy saturados.
- Animación de nave/estela/explosiones, sensación de impacto, hitbox de nave **10×6** y F3 solo para depuración; movimiento/ataques sin tartamudeos evidentes.
- Imagen interna **640×360**, HUD **24 px**; probar escala ×1, ×2, ×3 y pantalla completa, evitando que la zona jugable se vea diminuta en un monitor de 1080p.

### Bloque B2 — Oleadas, ataques y dificultad
- Preservar la composición real del mundo 1 definida en `data/waves/world_01.json`: **90 enemigos regulares**. Únicos: Hydroides (Serpulidae), Euphrosine, Fabriciidae, Pisionidae, Lacydoniidae. Recurrentes: Syllidae y Phyllodocidae. Cada tipo debe mostrar sprite y comportamiento identificables.
- Implementar y demostrar patrones de movimiento M1–M8 y disparo F0–F5 **según sus datos reales**; no exigir que todos se usen artificialmente en W01. Balas dirigidas, abanicos y formaciones deben ser visibles, justas y esquivables.
- Comprobar daño, colisiones, parpadeo de invulnerabilidad, escudo, muerte/reintento y que los enemigos desaparezcan al morir. Evitar oleadas invisibles o nunca creadas.
- No aumentar enemigos, vida ni cadencia por capricho: el balance procede de la especificación y los JSON.

### Bloque B3 — Etapa completa y jefe
- Introducción inicial, primera oleada a `00:10`, **minijefe gigante Pisionidae a `01:00`**, checkpoint tras vencerlo, oleadas intensas desde `02:00` y **alerta de jefe hacia `02:50`**; su inicio está condicionado a derrotar al minijefe.
- **Nereidae**, jefe final del mundo 1: sprite compuesto por piezas, puntos débiles, **3 fases**, ataques telegrafiados, barra de vida y animación de derrota. Respetar sus datos actuales y la especificación; no usar un jefe genérico indistinto.
- La pelea de jefe funciona completa y se puede ganar o perder. No ocultar el problema con un botón de 'pasar nivel'.
- El HUD debe indicar avance real y reflejar de forma correcta escudo, armas, bombas y monedas.

### Bloque B4 — Recompensa, tienda y persistencia
- Derrotar Nereidae conduce a pantalla de resultados: enemigos derrotados, monedas recogidas, recompensa, bono sin morir, tiempo y muertes. Luego pantalla de descanso.
- Desde el descanso, **Tienda** abre realmente y permite comprar mejoras permanentes y equipo desbloqueado del acto 1. Las compras cobran el costo indicado en `data/shop.json`, aplican efectos reales, y solo pueden reembolsarse durante la misma visita; jamás crean monedas por error. La interfaz debe permitir volver.
- **Guardar y salir** debe preservar el estado y volver al menú; **Continuar** debe restaurar la partida; separar ranuras Normal/Pruebas. Probar también cancelación y salida sin bloquear controles.
- Completar un mundo desbloquea el siguiente sin modificar partidas de otros modos; la edición Pruebas conserva su selector y dinero de pruebas.
- No crear música ni sustituir canciones existentes; mantener audio en pausa hasta nueva autorización. Probar efectos ya disponibles y sus controles de volumen.

## C. Pruebas de aceptación para mundo 1

- [ ] En Windows instalado: simulación activa, cronómetro y desplazamiento normal durante **al menos 60 s**.
- [ ] La primera oleada entra después del inicio del gameplay, a los 10 s, y sus enemigos son vulnerables y capaces de disparar donde corresponda.
- [ ] Los **90 enemigos** del plan se generan durante la etapa completa y el contador es coherente (sin sumar minijefe/escoltas/jefe a los 90).
- [ ] Minijefe Pisionidae, punto de control y reaparición funcionando.
- [ ] Se alcanza y se derrota Nereidae; transiciones de sus tres fases y ataques verificadas.
- [ ] Resultados → descanso → tienda → compra → guardar y salir → continuar; toda la secuencia se prueba de principio a fin.
- [ ] Ediciones Normal y Pruebas probadas con nuevos instaladores, no solo `--headless`.
- [ ] Capturas/vídeo y logs de pantalla de inicio, oleada, minijefe, jefe, tienda, cierre y recarga.
- [ ] FPS medidos en equipo real; no declarar **60 FPS estables** si las mediciones indican menos.
- [ ] `python scripts/test-native.py` y otras pruebas pertinentes pasan; los fallos se documentan explícitamente.
- [ ] No hubo cambio involuntario en gráficos aprobados, economía, especies ni música.

## D. Lo que NO hay que hacer

- No empezar mundo 2 sin que el usuario haya probado y aprobado el mundo 1.
- No rehacer el proyecto en HTML, cambiar de motor o crear otra campaña separada.
- No declarar “el juego está terminado” por pasar tests de datos o ver una imagen bonita.
- No reemplazar arte ya integrado por polígonos/figuras de código ni sprites de otros juegos.
- No modificar la música sin autorización.
- No modificar sistemas ajenos al arreglo hasta documentar y aprobar su alcance.
- No reutilizar instaladores obsoletos; indicar hash, commit y rama exactos de cada entrega.

## E. Formato del reporte de Codex

1. Rama / commit inicial y final.
2. Síntoma observado y causa confirmada (o hipótesis pendiente).
3. Lista de archivos cambiados con justificación.
4. Captura y vídeo de **la versión instalada**; duración de prueba y modo.
5. Tabla de pruebas aprobadas/no aprobadas.
6. Problemas pendientes y siguiente bloque recomendado.
7. Instaladores Normal/Pruebas o instrucciones de reproducción verificables.

**Importante:** el código ya presenta clases `PoliStages`, `PoliGame`, `PoliShop` y patrones de enemigos. El encargo consiste en comprobarlos, corregir su ejecución empaquetada y validar su experiencia visible, **no duplicarlos**.
