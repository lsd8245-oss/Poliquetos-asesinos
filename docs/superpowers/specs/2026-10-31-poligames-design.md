# PoliGames: revisión de campaña y experiencia

Fuente: PoliGames.pdf, 12 páginas, adjuntado por el usuario. La indicación directa de ignorar música/canciones prevalece sobre el documento. El usuario delegó previamente las decisiones de diseño e implementación; se conserva ese margen para decisiones rutinarias.

## Objetivo y alcance

Aplicar todos los requisitos del PDF salvo composiciones, canciones y versiones OST. Conservar HTML único, juego individual offline, cooperativo con autoridad del anfitrión, guardados existentes y preferencias de accesibilidad. Base: c581170, rama mejoras-musica-graficos.

## Enfoques

Se adapta el motor y la interfaz existentes, con módulos delimitados dentro de sus cierres, reutilizando los atlas de criaturas y los servicios de guardado y compra. Reconstruir el juego introduciría incompatibilidades y perdería contenido. Añadir un juego paralelo dejaría dos campañas divergentes. La adaptación es la decisión técnica del implementador dentro de la autonomía concedida.

## Campaña

14 mundos: superficie, playas, costa rocosa, kelp, arrecife tropical, pastos marinos, estuarios, contaminación, plancton, Antártica, restos de ballena, hidrotermales, hadal, laboratorio. Actos 1–4: mundos 1–4, 5–8, 9–13, 14. Primeros 13 mundos: nueve oleadas con cantidades exactas del PDF y décimo nivel de jefe exclusivamente. Laboratorio: nueve oleadas, cuatro jefes mecánicos en sector 10, epítoke 11, científico 12, Eunice 13 y rescate 14. Total 144 sectores. «Acto 14» de la tabla se interpreta como mundo 14.

Se registran las familias y géneros únicos/recurrentes indicados, con anatomías y conductas acordes a los renderizadores existentes. Los tres jefes de contaminación y los dos hadales son encuentros de grupo; el mecánico es una secuencia de cuatro. Eunice se ancla a la derecha, ocupa aproximadamente media pantalla y solo anima cabeza/mandíbulas. Escape: 180 segundos de oleadas ilimitadas, fuego, alertas y cuenta regresiva, detenida al pausar; gana al cumplirse el tiempo, sin exigir limpiar supervivientes.

## Progreso y economía

Reintentar tras derrota restaura el comienzo del sector actual y su equipamiento/monedas, sin duplicar recompensas. Migración por identidad de mundo desde campaña 7. Recompensas y precios permiten comprar equipos en su acto: draga/arrastre 1; Niskin/box/CTD 2; multi/ROV/lander 3; deflector 4. Sonar inicial. Skins cosméticas comprables y astillero accesible desde descanso, con retorno al mismo descanso y sin avanzar simulación. Compras validadas por motor; coop no confía en créditos enviados por cliente.

## Presentación e interacción

Ampliar arena y trasladar evasión/consumibles a los bordes. Iconos distintos para cada mejora, pantalla de derrota con calavera y reintento claro. Portada y menús animados, tienda con identidad cromática, animaciones moderadas y movimiento reducido. Hábitats claramente diferenciados en geometría y luminosidad: no una recoloración de mares oscuros. Equipos con efectos legibles. Opciones de audio solo música y FX, conservando las canciones actuales; reasignación persistente de teclas de equipos con prevención de conflictos.

## Verificación

Pruebas de motor con reloj simulado para conteos, jefes, actos, economía, migraciones, derrota/reintento y escape180s. Chromium real para navegación, astillero en descanso, compras, atajos, HUD, audio previo y movimiento reducido. Revisar capturas de hábitats y ventanas pequeñas; probar flujo cooperativo a nivel de autoridad del motor. Entregar una nueva rama de GitHub usando la autorización de publicación ya concedida en la conversación.
