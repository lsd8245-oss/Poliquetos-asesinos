# Entregas del videojuego

Preferencia permanente del usuario: entregar siempre dos HTML autocontenidos:

- Normal: progresión, créditos y compras habituales.
- Pruebas: mundos/niveles, armas y skins abiertos; selector de mundo y nivel; dinero ilimitado para comprar habilidades/equipos y mejoras. Estas compras empiezan pendientes (salvo el sonar inicial). No aumentar estadísticas ni dar invulnerabilidad automáticamente.

El HTML de la raíz es la fuente canónica. Tras cambiarlo, ejecutar `python3 scripts/build-editions.py` para actualizar `versiones/poliquetos-normal.html` y `versiones/poliquetos-pruebas.html`; no editar las copias generadas manualmente. Ejecutar `node --test`. Mantener separados los guardados y preferencias de ambas ediciones.

Preferir enlaces directos a cada HTML en GitHub, en lugar de ZIP. En repositorios privados los enlaces requieren una sesión con acceso; no prometer descargas públicas o verificadas sin haberlas comprobado.

No sustituir composiciones, canciones ni muestras hasta que el usuario reabra expresamente ese trabajo musical.
