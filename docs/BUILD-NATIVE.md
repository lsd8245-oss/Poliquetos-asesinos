# Construcción y comprobación nativa

Herramientas: Godot 4.6.3 estable, sus plantillas oficiales, Python3 con requirements-dev.txt y NSIS 3.11+ para generar los instaladores.

```sh
python3 scripts/build-native.py --templates-dir /ruta/a/plantillas --linux-check --makensis /ruta/a/makensis
```

La carpeta de plantillas debe contener `windows_release_x86_64.exe` y, para `--linux-check`, `linux_release.x86_64`. Proceden de `Godot_v4.6.3-stable_export_templates.tpz` publicado por godotengine/godot-builds. El script copia las plantillas al caché del proyecto, importa recursos, exporta ambos juegos con PCK incorporado y genera instaladores `.exe` en `entregas/`. No utiliza HTML ni una envoltura de navegador. No hace falta entregar un ZIP ni instalar el motor al jugador.

Las ediciones difieren mediante la feature `pruebas`; comparten motor y datos. El instalador crea un acceso directo y un desinstalador para el usuario actual. Conserva los guardados y contiene el aviso de licencia de Godot.

No se comprimen las plantillas con UPX: elimina la secciónPE `pck` que Godot necesita al exportar. Los instaladores comprimen el juego ya exportado con LZMA de NSIS.

## Editar contenido

- Cambia precios, HP, patrones y oleadas en `data/*.json` y `data/waves/`.
- En una instalación puedes colocar `data/` y `assets/` junto al ejecutable para sustituir contenido sin compilar código. Si no existen esos archivos, se usan los incorporados.
- Reemplaza los PNG individuales manteniendo nombres y dimensiones; tienen prioridad sobre el atlas. La fuente y todos los assets están registrados en el manifiesto.
- `scripts/generate-assets-v2.py` crea solo los PNG que faltan y conserva los de artista. **No usar `--force-placeholders` sobre arte definitivo**, porque esa opción lo reemplaza expresamente.
- Los generadores de campaña, balance y SFX son herramientas editoriales: ejecutarlos puede reemplazar sus JSON/WAV generados. No se ejecutan al construir el juego.
- `scripts/balance-bosses-v2.py` conserva la vida original como `vida_base`, ajusta `vida` y genera un informe del presupuesto nominal. Esas HP siguen siendo editables.

## Pruebas

```sh
python3 scripts/test-native.py
# Con un servidor X real o de prueba:
DISPLAY=:99 python3 scripts/test-native.py --render
```

La opción de render captura portada, partida, tienda y jefes; mide 220 frames con 50 enemigos, 200 balas y disparo máximo del jugador. Los registros quedan en `build/test-reports`. El sistemaWindows y el hardware real deben comprobarse aparte de las mediciones Linux. `--verify-export` comprueba datos incorporados, assets, estadísticas iniciales y escritura en el directorio del usuario sin tocar ranuras; `--smoke-test` abre cinco frames y sale. Son herramientas de desarrollo por línea de comandos.

La reproducción automatizada de 05A comprueba 14 descansos, 12 mundos principales y el escape. Aísla la puntería/supervivencia y elimina rivales regulares sintéticamente, pero exige muertes reales de jefes mediante proyectiles de producción. No sustituye las grabaciones de los PE exportados sin esas ayudas ni el playtest humano. El catálogo activo y sus alias se migran con `scripts/migrate-campaign-12.py` desde el archivo inmutable `data/archive/04a`; no ejecutar el generador histórico de 14 mundos sobre los datos activos.
