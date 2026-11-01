# Encargo02 — corrección de simulación exportada

Base verificada: `arte/integracion-godot-w01` / `9ea435b692b437deb202519076823d6fae47aac4`, árbol limpio. Rama `fix/w01-export-stage-runtime`.

Alcance autorizado: bloqueA del encargo02. Cargar obligatoriamente los controladores existentes y las estadísticas reales en PCK, y validar avance, scroll, primera oleada, movimiento, ataque y bajas en ambas exportaciones. No construir B1–B4, modificar contenido, gráficos, balance, guardado ni audio.

- [x] Incorporar literalmente el encargo en docs/encargos y registrar hashes de1764 archivos protegidos.
- [x] Reproducir antes de corregir usando el PCK del instalador anterior en carpeta limpia: FileAccess=false, ResourceLoader=true, controladores=null, tiempo/scroll/enemigos0 a0/5/12/20s; estadísticas de compras también caen en fallback.
- [x] Preload obligatorio de Stages, Weapons, Bosses y Shop; retirar solo guardas de scripts .gd, mantener lectura JSON/PNG externa.
- [x] Regresión en editor y exportación que exige controladores y20s de simulación real, oleada a10s, ataques, movimiento y bajas sin inyectar enemigos, daño ni invulnerabilidad. Fortalecer el control de arranque exportado.
- [x] Ejecutar la versión Windows exportada con instrumentación y capturas/vídeo si el entorno lo permite. Wine es una capa de compatibilidad, no Windows real; distinguirlo de PCK Windows ejecutado por Godot Linux.
- [x] Suite nativa/datos, exportar y reconstruir ambos instaladores, verificar CRC/payload/hashes, repetir prueba sobre payloads extraídos de instaladores nuevos.
- [x] Publicar rama/commit, evidencia e instaladores directos verificables. Pedir aceptación de esta corrección antes del bloqueB1.

Plan posterior, sin ejecución: B1 sensación/control; B2 oleadas/daño; B3 etapa90+Pisionidae+Nereidae; B4 resultados/tienda/guardado. Fuente: documento02 y specv2, no nuevas mecánicas.

Verificación:25 controles sin render y27 con render; distribución Normal/Pruebas aprobada desde carpetas vacías. Instalación NSIS bajo Wine no disponible (c0000135, ntdll PE32); pruebas reales del PE extraído bajo Wine, no Windows real. Evidencia en `docs/verificacion/rescate-w01/README.md`. La aprobación de A y todo B permanecen pendientes.
