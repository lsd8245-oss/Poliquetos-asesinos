# Evaluación técnica posterior a05A — sin implementación

La reorganización estructural no resuelve por sí sola los defectos jugables de las tres capturas adjuntas. La corrección explícita mantiene a Nereidae y retira temporalmente Pisionidae gigante; no se aprovecha05A para rehacer su combate. Mundo1 sigue pendiente de aprobación y bloques05B/C/D.

## 05B: terreno y anclajes

El scroll existente y el compositor PNG se conservan. M5 sigue sin un objeto soporte; fijarY32/304 no acredita anclaje. Se necesitan piezas sólidas del suelo/techo/casco con máscaras o polígonos revisados contra el borde PNG, superficies con IDs estables y anclajes locales/normal/pivote del tubo. Posición del organismo=soporte mundial+anclaje local−scroll. No derivar colisión de las transparencias de los fondos decorativos. Hydroides/Fabriciidae y Sabellaria incorporada requieren soporte antes del spawn; la asignación sin soporte falla y reintenta, no genera un animal flotante.

Diseño a revisar: tres tramos0–55/55–120/120–180, tres desvíos verticales obligados y una bifurcación con salida verificable. Pasos iniciales72–88px y aviso0,8s son propuestas de playtest, no cambios del núcleo de colisión10×6. Resolver primero qué sucede al contactar/ser empujado por terreno y al destruir soporte. La arena debe despejarse antes del jefe sin borrar suelos debajo de criaturas vivas. La alerta configurada170 y el tiempo nominal180 requieren distinguir relojes; no desplazar oleadas ni alargar etapa de forma implícita.

Arte necesario: PNG originales de roca/suelo/techo/pared/esquina, casco con borde jugable, caras para tubos, compuertas de aviso/apertura, orientaciones/pivotes de Hydroides/Fabriciidae/Sabellaria y máscara revisada. Reusar las ilustraciones B1 como decoración. Ningún asset nuevo se considera final por importarlo.

Pruebas: barrido30/60/120Hz; colisión ascenso/descenso/diagonal/esquina, contacto prolongado y retroceso sin daño cadaframe; evitar atrapamiento por scroll; rutas superior/inferior; 100% de tubícolas con soporte visible/físico; pausa/reintento/guardar-cerrar-recargar. Video de ambos PE, con/sinF3; tres colisiones inevitables siguiendo soloX y esquiva correcta cambiandoY. No basta un dibujo de un corredor.

## 05C: densidad y Nereidae

05A conserva90 individuos y composición de las oleadas originales deW01; solo elimina el hueco artificial de la ventana del minijefe. El presupuesto160 provisional, los diez tipos7+3 y su distribución pertenecen a05C. Antes de programar, completar los recursos pendientes del catálogo y adaptar cada locomoción a05B. No activar una ficha de datos sin PNG ni comportamiento propios. Medir individuos totales, activos, TTL, segundos sin amenaza y ocupación de terreno/proyectiles, no confundirlos.

Objetivos de playtest del encargo:150–170 normales/~180s,6–12 activos con picos12–16 pequeños, sin vacíos prolongados fuera de apertura/transición/arena. Una nave quieta en arriba/medio/abajo se prueba20–30s; comparar con piloto móvil y documentar rutas esquivables. Guardar CSV de cada spawn,vida/tiempo en pantalla/causa de salida/monedas y frame times. Recalcular economía porque más individuos no debe multiplicar moneda total (la implementación reparte un presupuesto por ordinal, no moneda fija por nuevaespecie).

Conservar Nereidae y sus fases/piezas existentes. Auditar primero patrones/HP/DPS reales; diseñar carga serpenteante, barrido por carriles y ataques a posición anterior/división con telegráficos y salida. No solucionar con multiplicarHP. Objetivo60–100s humanoNormal, medido con arma inicial razonable y aciertos imperfectos, sin trasladarHP del minijefe. Pisionidae gigante y los demás minis siguen inactivos y archivados.

Arte: poses de preparación/carga/recuperación, apéndices/mandíbula por piezas, señales PNG y proyectiles propios si los actuales no bastan. Se conserva lo integrado; no crear versiones indistinguibles de Eulalia/Phyllodocidae ni robots de laboratorio por simples recolores. Probar justicia contra terreno05B y transición de fases; muerte real del jefe→premio único→tienda/guardado. Un bot perfecto no certifica la duración humana.

## 05D: sonar táctico

La implementación04A responde aQ/Y con12s/4s/radio320; eso no acredita ventaja táctica. Necesita peligros ocultos/anticipados con coordenadas mundiales de05B y eventos de05C, no adivinar del color del fondo. Seleccionar una zona de aproximación: cavador con aviso2–3s, compuerta/roca móvil o corredor parcial oculto. Destacar bordes navegables próximos y tiempo de emergencia con PNG legibles, no radar de toda la etapa ni daño.

Si nada entra en rango, informar «Sin amenazas detectadas». Mantener CTD separado, remapeo y Reducir destellos. No modificar pistas ni muestras musicales; sonido de barrido requerirá respetar la decisión vigente sobre audio. Prueba humana A/B con/sinQ: anticipación en segundos, colisiones evitadas, ruta elegida y legibilidad; video de ambas variantes, cooldown real, pausa y control reasignado. Si hace falta una función ofensiva nueva, requiere otra aprobación explícita.

## Orden y límites

Revisar05A antes de autorizar05B. Después aprobar terreno/anclajes, densidad/jefe y sonar por separado. Ninguna captura de05A ni los tests de numeración validan corredores, jefes reequilibrados o sonar útil. No avanzar al desarrollo artístico/jugable del mundo2 ni declarar mundo1 completo.
