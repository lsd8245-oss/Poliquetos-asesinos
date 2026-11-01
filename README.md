# Poliquetos Asesinos · Juego nativo para Windows

Nueva implementación en **Godot 4.6.3**, individual y sin conexión. Se instala y abre como aplicación de escritorio; no necesita navegador, Python ni Godot instalado para jugar.

## Descargar

- [Instalador Normal](https://github.com/lsd8245-oss/Poliquetos-asesinos/raw/refs/heads/juego-nativo-v2/entregas/Poliquetos-Normal-Instalar.exe).
- [Instalador Pruebas](https://github.com/lsd8245-oss/Poliquetos-asesinos/raw/refs/heads/juego-nativo-v2/entregas/Poliquetos-Pruebas-Instalar.exe).

Windows 10/11 de 64 bits y OpenGL 3.3. Abre el instalador, elige la carpeta y usa el acceso directo del escritorio. Cada edición se instala por separado para tu usuario. Si el repositorio es privado, inicia sesión en GitHub con acceso antes de descargar. Los hashes están en [entregas/SHA256.json](entregas/SHA256.json).

**Arte provisional:** los PNG son rectángulos identificados, como exige la sección2.10 de la especificación para trabajar mientras se produce el arte aparte. El juego todavía necesita esos diseños definitivos. Las canciones siguen pendientes; hay 39 efectos de juego originales.

## Campaña y controles

14 mundos con una etapa larga, minijefe y jefe; laboratorio con 250 enemigos y cuatro encuentros separados por tienda/guardado; escape final de cinco minutos. Ataques por fases, partes con colisiones propias, puntos débiles, portadoras de armas y peligros por hábitat.

| Acción | Teclado | Mando |
|---|---|---|
| Mover | WASD o flechas | Stick izquierdo/cruceta |
| Disparo | Z o Espacio | A |
| Bomba | X | B |
| Pausa | P o Esc | Start |
| Hitboxes de depuración | F3 | |

Los misiles son automáticos. En Opciones puedes reasignar teclado/mando, activar disparo automático, cambiar escala entera/pantalla completa, audio, temblor y destellos. El descanso contiene tienda, astillero de tres colores, skins, guardado y repetición de mundos superados.

Normal mantiene progreso y dinero habituales. Pruebas tiene acceso a todos los mundos, al escape y a los cuatro encuentros del laboratorio, elección explícita de niveles de arma, todas las skins y dinero ilimitado. Empieza sin comprar equipo/mejoras, salvo el sonar; conserva las mismas estadísticas base y las reglas de daño.

## Partidas

Tres ranuras JSON por edición, con copia `.bak` y recuperación si la principal está dañada. Se guardan automáticamente al descansar; también puedes guardar, exportar, importar y abrir la carpeta desde el juego. En Windows están bajo `%APPDATA%/Poliquetos Asesinos/normal` y `pruebas`. Desinstalar conserva las partidas.

El juego HTML anterior permanece en el repositorio y sus guardados del navegador no se borran. La nueva campaña usa otro formato; no hay importación automática de sus 144 sectores al recorrido nativo. [Documentación del legado](docs/LEGADO-WEB.md).

## Desarrollo y verificación

Consulta [la especificación](docs/specs/poliquetos-asesinos-v2.md), [las decisiones](docs/decisiones.md), [el progreso y las limitaciones verificadas](docs/v2-progreso.md) y [la construcción nativa](docs/BUILD-NATIVE.md).

```sh
python3 -m pip install -r requirements-dev.txt
python3 scripts/test-native.py
node --test
```

La suite nativa comprueba datos, assets, armas, colisiones, jefes, economía, guardado, UI, reintento, repetición, final y arranque de ambas ediciones. Detecta errores de scripts aunque Godot devuelva código 0. La campaña completa también se recorre con daño artificial de prueba; eso verifica el flujo, no el tiempo de una partida humana.

Los objetivos de 90/70 min siguen necesitando partidas reales de ajuste. La herramienta de balance verifica el mínimo del 40% con las builds máximas del presupuesto nominal; las monedas adicionales y la repetición pueden financiar builds superiores. No se presenta esa simulación como garantía para todas las rutas posibles.
