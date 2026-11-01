# Revisión independiente de la corrección

Revisor: agente independiente `review_export_fix`, revisión del diff acotado contra9ea435b, sin modificar código.

Hallazgo P2: las pruebas de empaquetado ejecutadas con cwd en el repositorio podían acceder a scripts fuente y ocultar precisamente el fallo exportado. Confirmó que el mismo EXE informa FileAccess=true desde el checkout y false desde /tmp. Corregido: ambos probes de build-native usan TemporaryDirectory; el control inicial de distribución también usa la carpeta extraída. La regresión de etapas ya estaba aislada. Se repitieron ambos checks aislados de cada edición y la verificación completa de distribución.

No detectó bloqueos en los preloads, ciclos de dependencias ni cambios en las fórmulas de Shop. Comprobó independientemente el probe fuente y el PCK Normal aislado:10s primera oleada,20s/1200px, movimiento, ataques y cinco bajas. La validación Wine se declara aparte de Windows real.
