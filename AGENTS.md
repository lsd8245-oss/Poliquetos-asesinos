# Poliquetos Asesinos: entregas nativas

El usuario cambió el destino a un juego nativo de **Windows**, sin navegador ni HTML. La fuente actual es `project.godot`, los scripts GDScript de `src/`, los JSON de `data/` y los PNG de `assets/`. Seguir `docs/specs/poliquetos-asesinos-v2.md` y las decisiones de `docs/decisiones.md`.

Entregar siempre dos ediciones:

- Normal: progresión y economía normales.
- Pruebas: mundos/etapas, armas y skins disponibles; selector de mundo y encuentro; dinero ilimitado para comprar equipo y mejoras. Las compras empiezan pendientes salvo sonar. No añadir estadísticas ni invulnerabilidad automáticas.

Mantener guardados y opciones separados. El usuario confirmó todas las propuestas de la sección14. Las canciones/música siguen pendientes; los efectos originales de juego están implementados. Los gráficos son PNG provisionales identificados hasta que se entregue arte final, según la sección2.10; no presentarlos como arte definitivo.

Validar `python3 scripts/test-native.py` y `python3 scripts/validate-v2-data.py --self-test`. Para una revisión con pantalla, `DISPLAY=:99 python3 scripts/test-native.py --render` requiere un servidor X disponible; no fingir que se ejecutó si no existe. Ejecutar `node --test` como regresión del legado HTML conservado.

Exportar ambas ediciones con `python3 scripts/build-native.py --templates-dir RUTA_PLANTILLAS --makensis RUTA_MAKENSIS`. No regenerar los datos ni los PNG de artista al construir. `entregas/` contiene instaladores Windows y sus hashes; `build/` es temporal y no se publica en git. Preferir enlaces directos a cada `.exe`, sin ZIP. En GitHub privado requieren una sesión con acceso.

El HTML anterior y `scripts/build-editions.py` se conservan como legado. Solo ejecutar ese generador si se modifica el legado; no es el motor ni el formato de la nueva entrega.
