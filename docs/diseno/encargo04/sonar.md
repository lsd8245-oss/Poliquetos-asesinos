# Sonar 04A: contrato integrado

El usuario aprobó expresamente la propuesta del §2.2: Q configurable, mando configurable, 12 s de recarga y 4 s de revelado informativo, sin daño ni función CTD. Se usa Y como botón predeterminado de mando. No existía otro controlador activo de sonar: `equipment.sonar` era propiedad inicial y un icono. Se conecta una sola implementación en `src/equipment/sonar.gd`, coordinada por `main.gd` sin reescribir `game.gd`.

Los valores se añaden a `data/combat.json` y a su esquema: `cooldown_seconds=12`, `reveal_seconds=4`, `range_px=320`, `sweep_seconds=1.2`. Los dos últimos son decisiones de presentación/rango: medio ancho de la pantalla lógica desde el origen de activación, expansión legible durante 1,2 s y marcadores hasta completar 4 s. No son una alteración del daño/alcance de armas. No se compra ni mejora el sonar en esta entrega.

La activación almacena el origen en coordenadas de pantalla del combate actual. El pulso utiliza el PNG animado de burbuja B1, sin producir otro asset; alfa máximo0,4 normal/0,18 con Reducir destellos, descenso suave. Se dibuja detrás de criaturas y balas. La detección está limitada al círculo de320px y termina a4s. No pretende ser una onda física que colisione con terreno aún inexistente.

El HUD muestra la tecla asignada, LISTO, cuenta atrás con redondeo hacia arriba —por ejemplo08 s— o NO INST. Se añaden Controles y tutorial inicial; el primer uso muestra una frase. No cambia CTD: vida/puntos débiles siguen condicionados a comprarlo. Los otros dos equipos se identifican como pasivos o no instalados.

En W01 no hay anclajes físicos ni sólidos integrados. El sonar indica el organismo tubícola existente, **no un supuesto soporte creado para la demostración**; resalta zonas `game.hazards` cercanas cuando existen y señales de actores ocultos si el sistema las proporciona. No añade enemigos camuflados a W01 ni genera peligros para mostrar una función. El anclaje real y el contorno de sólidos quedan sujetos a04B. Véase [auditoría](ecologia-y-anclajes.md).

El reloj avanza únicamente con el delta efectivo de `game.total_time`; pausa, cuenta atrás de reanudación y presentación inicial no consumen recarga. No hay activación repetida durante cooldown. Reintentar, comenzar partida o pasar de mundo reinicia este estado transitorio. No se escribe cooldown en partidas ni se migran perfiles. Las preferencias de tecla/botón siguen el servicio de guardado separado por edición existente.

Verificación: tests de propiedad inicial y ausencia de equipo, activación, rango, pausa, expiración, repetición y comparación de20s de combate real contra control con RNG idéntico; integración de eventos Q/E/Y, persistencia de remapeo, HUD, reinicio y distribución de Controles. El vídeo del PE usa teclado del sistema y tiempo real, no la inyección de esos tests. Un evento sintético Y no certifica un mando físico.
