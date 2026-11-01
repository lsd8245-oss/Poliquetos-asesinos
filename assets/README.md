# PNG provisionales del juego nativo

Todos los gráficos incluidos son **placeholders originales**, rectángulos planos rotulados, y la fuente bitmap provisional. No son arte final. El manifiesto `assets_manifest.json` contiene la lista de trabajo por mundo, tamaño de cada cuadro, cuadros, fps y estado. Los enemigos recurrentes tienen PNG propios en cada mundo.

Para sustituir un gráfico, cambiar sus archivos PNG individuales conservando nombre, tamaño y transparencia. Los nombres terminan en `_01.png`, `_02.png`, etc. La carga prefiere esos archivos al atlas, así que **no hace falta cambiar código ni regenerar el atlas para ver un reemplazo**. Reiniciar el juego para volver a cargar imágenes. En Windows, copiar esta carpeta `assets/` junto al ejecutable; los PNG y JSON externos tienen prioridad sobre los recursos empaquetados.

Después de sustituir imágenes se pueden actualizar los atlas y el manifiesto con:

```sh
python3 scripts/generate-assets-v2.py
```

Requiere Pillow solo durante desarrollo. El comando conserva todos los PNG existentes, comprueba tamaños y vuelve a empaquetar cada atlas en una imagen de hasta 2048×2048. Los PNG sin metadato `status=placeholder` pasan a estado `final` en el manifiesto. Si el editor conserva ese metadato, retirar el metadato o cambiarlo a `final`. `--force-placeholders` descarta intencionadamente los gráficos existentes y reconstruye los rectángulos provisionales.

Los fondos tienen cuatro capas de 640×336 por mundo (w01–w15); las capas 2–4 admiten transparencia. Deben conservar los extremos horizontales repetibles. Los pequeños proyectiles y el píxel de interfaz no tienen espacio para rótulos legibles; conservan el nombre completo y el estado provisional en los metadatos del PNG. Las etiquetas de sprites pequeños pueden quedar abreviadas por el tamaño; el manifiesto y los metadatos identifican cada asset completo.

`ui/bitmap_font.png` y `ui/bitmap_font.json` forman la fuente bitmap original provisional, sin dependencia de fuentes del sistema. ASCII imprimible, `áéíóúüñÁÉÍÓÚÜÑ¿¡`, avance 6 px y alto de línea 9 px; posición del texto en su esquina superior izquierda. Los caracteres en minúscula usan versalitas provisionales. Sustituir el PNG manteniendo las regiones o actualizar el JSON. El dibujo en ejecución usa únicamente texturas PNG y regiones de la fuente, con filtro nearest configurado por el juego.
