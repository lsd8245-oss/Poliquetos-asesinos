# B1 — plan de ejecución

Base d31d3406f07868942bbd3f594bee78d0f12d63b7, árbol limpio; rama pulido/w01-combate-vfx-b1. Especificación aprobada para ejecución: docs/encargos/03-pulido-jugabilidad-vfx-escenario-w01.md. Se aplica la autorización vigente de cambios a elección del implementador, dentro de B1; revisión humana al entregar, no otra ronda previa de conceptos.

Arquitectura: conservar simulación y datos. Arte PNG original generado con imagegen y preparado en hojas animadas; el render compone esos recursos con nearest. No dibujos finales de criaturas mediante código. Mantener la nave y taxonomía existentes. Assets integrados para revisión; nunca marcar final antes de la aceptación visual del usuario.

- [x] Auditar cada placeholder de las capturas contra manifiesto, render y PNG. Registrar rutas, causa y sustitución.
- [x] Proyectiles, FX e iconos: PNG originales diferenciados, preparación de cuadros y manifiesto/atlas W01. Cambiar solo representación visual, no simulación. Reemplazar también portadoras, recogibles y riesgos con recursos funcionales sin texto técnico.
- [x] Ambiente W01: módulo visual aislado con cuatro profundidades, composición reproducible de tres sectores, vegetación/cadenas independientes, partículas y fauna. No cambiar oleadas ni duración. Probar variedad a0/15/30s y límites de tiles.
- [x] Render B1: orden de dibujo, giro de proyectiles, nave inclinada y propulsión, impactos/muerte, HUD24px y equipo por color. Respetar reducir destellos. Añadir eventos puramente visuales solo si los efectos existentes no bastan.
- [x] Pruebas de recursos y contratos; probar render/partida y fixtures etiquetados de armas, bomba, minijefe y jefe. Revisión independiente. Ningún cambio en data/, audio, tienda, guardados, etapas, armas ni patrones.
- [x] Suite nativa con render, mediciónFPS/percentiles, empaquetar dos NSIS, probar PCK aislados y EXE Windows bajo Wine. Grabar al menos30s efectivos reales sinF3; capturas640/1280/1920. Windows físico/mando e instalación real se declaran pendientes si no disponibles.
- [x] Entregar rama/commit, evidencia, instaladores directos con SHA; detenerse en B1. B2/B3/B4 planificados en el encargo, no ejecutados.

Revisión: cero rectángulos técnicos visibles en partida, distinguir proyectiles por silueta, no perder hitboxes ni DPS, no tapar HUD/ataques, no repetir boyas, PNG reales incluidos en exportación. Documentar limitaciones visuales/rechazos; los tests no constituyen aprobación artística.
