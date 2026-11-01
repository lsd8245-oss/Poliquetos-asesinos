# Plan de ejecución del piloto gráfico W01

Base: `docs/instrucciones-redisenio-v2` / `f60abfb`, descendiente verificado de `juego-nativo-v2` / `ac29e23`. El encargo adjunto define y autoriza las cuatro propuestas; no se propone otra plataforma ni integración. Ejecución en esta sesión, sin modificar producto.

## A — Conciliación documental (commit independiente)

- [x] Leer encargo, AGENTS, especificación, procedimientos, decisiones, progreso y proyecto/pruebas/manifiesto.
- [x] Crear rama `arte/piloto-godot-w01` y registrar hashes de todos los archivos del juego protegidos.
- [x] Modificar solo cláusulas discordantes de AGENTS/procedimientos: Godot 4.6.3, dos instaladores Windows, perfiles `user://`, pruebas nativas; preservar normas de arte, música y legado.
- [x] Incorporar encargo original y registrar decisión/diferencia Hydroides: actor48×48 frente a PNG/manifiesto32×32.
- [x] Ejecutar suite nativa: 19 comprobaciones aprobadas; salida archivada y diff documental revisado antes de commit A.

## B — Conceptos revisables (commit independiente)

- [x] Imagegen: tres variantes de nave; Hydroides tubícola con retracción/extensión; cuatro capas W01; portada original sin letras integradas.
- [x] Conservar fuentes originales y trazabilidad. Pillow únicamente para recortes, alfa, nearest, paletas, hojas y composición; no generar criaturas con primitivas.
- [x] Revisar bocetos a48×24 y48×48, paleta máxima16, alfa binario, silueta, anclajes y ampliaciones×8. Dos cuadros blancos de daño.
- [x] Preparar capas640×336; revisar empalmes repetidos, composición con sprites y HUD reservado. Identificar maquetas como MOCKUP.
- [x] Crear portada640×360 y tipografía separada, comparativa con placeholders previos y README con límites/aprobaciones.
- [x] Repetir suite nativa; render solo si hay display disponible, nunca llamarlo Windows. Verificar hashes protegidos, dimensiones/paletas/alfa, revisar imágenes y commit B.
- Publicación posterior al commit B: comprobar enlaces PNG individuales con respuesta200 y contenido idéntico; resultado comunicado en la entrega para evitar un commit autorreferente.

Fuera de alcance: integración en assets/manifiesto de producción, código, datos, balance, audio, guardados, mundo2 y reconstrucción de instaladores. Las limitaciones de generación o Windows se declaran; conceptos no aprobados y cero assets finales nuevos.
