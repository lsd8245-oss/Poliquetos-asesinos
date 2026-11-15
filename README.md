# Poliquetos Asesinos · Juego nativo para Windows

Nueva implementación en **Godot 4.6.3**, individual y sin conexión. Se instala y abre como aplicación de escritorio; no necesita navegador, Python ni Godot instalado para jugar.

## Descargar

- [Instalador Normal](https://github.com/lsd8245-oss/Poliquetos-asesinos/raw/refs/heads/migracion/05a-campana-12-mundos/entregas/Poliquetos-Normal-Instalar.exe).
- [Instalador Pruebas](https://github.com/lsd8245-oss/Poliquetos-asesinos/raw/refs/heads/migracion/05a-campana-12-mundos/entregas/Poliquetos-Pruebas-Instalar.exe).

Windows 10/11 de 64 bits y OpenGL 3.3. Abre el instalador, elige la carpeta y usa el acceso directo del escritorio. Cada edición se instala por separado para tu usuario. Si el repositorio es privado, inicia sesión en GitHub con acceso antes de descargar. Los hashes están en [entregas/SHA256.json](entregas/SHA256.json).

**Entrega 05A para revisión:** reorganización de campaña y guardados; no constituye el mundo 1 terminado. Se conservan los PNG integrados en B1/04A con su estado de revisión previo, sin añadir arte ni sustituir música. Las especies nuevas sin recursos quedan pendientes explícitas, fuera de las oleadas. [Informe y pruebas](docs/verificacion/05a/README.md).

## Campaña y controles

12 mundos principales con jefe final obligatorio; minijefes temporalmente desactivados. El laboratorio conserva sus 250 enemigos y tres encuentros: robots, científico y Eunice; después comienza el escape especial de cinco minutos. Ataques por fases, partes con colisiones propias, puntos débiles, portadoras de armas y peligros por hábitat.

| Acción | Teclado | Mando |
|---|---|---|
| Mover | WASD o flechas | Stick izquierdo/cruceta |
| Disparo | Z o Espacio | A |
| Bomba | X | B |
| Sonar informativo | Q | Y |
| Pausa | P o Esc | Start |
| Hitboxes de depuración | F3 | |

Los misiles son automáticos. En Opciones puedes reasignar teclado/mando, activar disparo automático, cambiar escala entera/pantalla completa, audio, temblor y destellos. El descanso contiene tienda, astillero de tres colores, skins, guardado y repetición de mundos superados.

Normal mantiene progreso y dinero habituales. Pruebas tiene acceso a todos los mundos, al escape y a los tres encuentros del laboratorio, elección explícita de niveles de arma, todas las skins y dinero ilimitado. Empieza sin comprar equipo/mejoras, salvo el sonar; conserva las mismas estadísticas base y las reglas de daño.

## Partidas

Tres ranuras JSON por edición, con copia `.bak` y recuperación si la principal está dañada. Se guardan automáticamente al descansar; también puedes guardar, exportar, importar y abrir la carpeta desde el juego. En Windows están bajo `%APPDATA%/Poliquetos Asesinos/normal` y `pruebas`, en el subdirectorio `campaign12`. Los archivos antiguos se conservan intactos: se solicita confirmar su migración y se crean respaldos verificables al guardar. Los antiguos mundos 3 y 6 regresan a una entrada segura anterior con aviso explícito. Las preferencias conservan su ruta anterior. Desinstalar conserva las partidas.

El juego HTML anterior permanece en el repositorio y sus guardados del navegador no se borran. La nueva campaña usa otro formato; no hay importación automática de sus 144 sectores al recorrido nativo. [Documentación del legado](docs/LEGADO-WEB.md).

## Desarrollo y verificación

Consulta [la especificación](docs/specs/poliquetos-asesinos-v2.md), [las decisiones](docs/decisiones.md), [el progreso y las limitaciones verificadas](docs/v2-progreso.md) y [la construcción nativa](docs/BUILD-NATIVE.md).

```sh
python3 -m pip install -r requirements-dev.txt
python3 scripts/test-native.py
node --test
```

La suite nativa comprueba datos, assets, armas, colisiones, jefes, economía, guardado, UI, reintento, repetición, final y arranque de ambas ediciones. Detecta errores de scripts aunque Godot devuelva código 0. El recorrido automatizado completo usa eliminación sintética de rivales regulares y aislamiento de puntería/supervivencia, pero exige derrotar a los jefes con los proyectiles de producción. Esto comprueba el flujo y no equivale a una partida humana ni a los vídeos exportados sin esas ayudas.

Los objetivos históricos de 90/70 min no están validados para esta campaña reorganizada; requieren partidas humanas y ajuste posterior. Los HP históricos se conservan sin reajuste; sus presupuestos antiguos están identificados como históricos. La migración reduce el subtotal Normal de rivales regulares y premios fijos de 27165 a 22680 créditos (16,51%); excluye monedas variables por conversión de proyectiles en cambios de fase y armas al máximo. No mide el ingreso total posible; no se afirma que permita comprar todos los equipos y rangos. [Análisis económico](docs/diseno/encargo05/economia.md).
