# Poliquetos Asesinos v2 — Propuesta de lista actualizada: 12 mundos

> **ESTADO: PROPUESTA — NO IMPLEMENTADO.** Basada en la rama `pulido/w01-combate-vfx-b1` (catálogos `data/worlds.json`, `data/enemies.json` y `data/bosses.json`). Este documento NO modifica automáticamente el videojuego. Las nuevas entradas deben diseñarse, equilibrarse, testearse y aprobarse por fases.

**Corrección de alcance:** los **minijefes quedan inactivos** en la campaña por ahora; los **jefes finales permanecen activos** (salvo Epitoka, retirado del diseño activo del laboratorio). Los IDs antiguos se conservan únicamente para migración y archivo.

## Reglas de esta actualización

- Se eliminan como **escenarios** los antiguos mundos 3 «Costa rocosa» y 6 «Praderas de pastos marinos». Se conservan los cuatro actos; el laboratorio pasa a ser el mundo 12.
- Cada mundo restante mantiene sus enemigos normales y recurrentes existentes, y recibe **exactamente 2 nuevos enemigos normales** y **1 tipo recurrente adicional**. Aquí «normal» significa enemigo común (no jefe), no necesariamente individuo frecuente en la naturaleza.
- Los IDs de los jefes finales activos y de los minijefes archivados se muestran **sin renombrar** como referencias de migración. Codex deberá actualizar todas las rutas, asset keys, datos, eventos y pruebas de forma transaccional.
- No se incrementan automáticamente los conteos de enemigos por mundo ni las duraciones: los tipos nuevos se distribuyen dentro del presupuesto de oleadas existente.
- El nivel de escape original `world=15` queda fuera de los 12 mundos y deberá reasignarse a `world=13` cuando se migre el motor.
- Los dos jefes y los dos minijefes de los mundos eliminados siguen preservados en el inventario histórico, sin aparecer en la campaña de 12 mundos hasta decidir dónde reutilizarlos.

## Tabla rápida

| Nuevo | Antiguo | Acto | Mundo | +2 enemigos normales | +1 recurrente | Normales totales (tipos) | Recurrentes totales (tipos) | Cantidad de enemigos de etapa |
|---:|---:|---:|---|---|---|---:|---:|---:|
| 1 | 1 | 1 | Superficie marina | Sabellaria; Eulalia (Phyllodocidae) | Spionidae | 7 | 3 | 90 |
| 2 | 2 | 1 | Playas arenosas | Pectinaria; Diopatra (Onuphidae) | Pisionidae | 7 | 4 | 125 |
| 3 | 4 | 1 | Bosques de kelp | Dodecaceria (Cirratulidae); Sphaerodoridae | Hesionidae | 7 | 4 | 135 |
| 4 | 5 | 2 | Arrecifes tropicales | Oenone (Oenonidae); Chaetopterus | Serpulidae | 7 | 4 | 135 |
| 5 | 7 | 2 | Estuarios y fango | Arabella (Arabellidae); Hediste diversicolor | Magelona (Magelonidae) | 7 | 4 | 150 |
| 6 | 8 | 2 | Sedimentos contaminados | Capitella capitata (complejo); Polydora ciliata | Spionidae | 7 | 3 | 162 |
| 7 | 9 | 3 | Zona planctónica | Vanadis antarctica; Pelagobia longicirrata | Swima (Acrocirridae) | 7 | 3 | 162 |
| 8 | 10 | 3 | Zona antártica | Laetmonice producta; Austrolaenilla antarctica | Aphroditidae | 7 | 4 | 200 |
| 9 | 11 | 3 | Restos de ballena | Glycera (Glyceridae); Neanthes visicete | Sphaerodoridae | 7 | 3 | 200 |
| 10 | 12 | 3 | Campos hidrotermales | Branchipolynoe; Thermopolynoe | Ophryotrocha | 7 | 4 | 245 |
| 11 | 13 | 3 | Zona hadal | Macellicephala tricornis; Bathykermadeca hadalis | Bathykurila | 7 | 6 | 285 |
| 12 | 14 | 4 | El laboratorio | Centinela Oenone (robot original); Artillería Diopatra (robot original) | Capitella capitata (complejo) | 8 | 78 | 250 |

## Inventario completo por mundo

### Mundo 1: Superficie marina (antiguo 1; acto 1)

- **Normales que conserva (base):** Hydroides (Serpulidae) (`hydroides`), Euphrosine (Euphrosinidae) (`euphrosine`), Fabriciidae (`fabric`), Pisionidae (`pision`), Lacydoniidae (`lacy`).
- **Normales agregados:** Sabellaria (`sabellaria`), Eulalia (Phyllodocidae) (`eulalia`).
- **Recurrentes que conserva:** Syllidae (`syll`), Phyllodocidae (`phyll`).
- **Recurrente añadido:** Spionidae (`spio`).
- **Minijefe INACTIVO (referencia histórica):** `mini_w01_pision` (ID antiguo, pendiente de migración).
- **Jefe(s) final(es) ACTIVO(S):** `boss_w01_nereis`.
- **Presupuesto de enemigos normales:** 90 (sin aumento automático).

### Mundo 2: Playas arenosas (antiguo 2; acto 1)

- **Normales que conserva (base):** Arenicola (Arenicolidae) (`arenicola`), Magelona (Magelonidae) (`magelona`), Sthenelais (Sigalionidae) (`sthenelais`), Saccocirrus (`sacco`), Goniada (`goniada`).
- **Normales agregados:** Pectinaria (`pectinaria`), Diopatra (Onuphidae) (`diopatra`).
- **Recurrentes que conserva:** Spionidae (`spio`), Nephtyidae (`nepht`), Glyceridae (`glycer`).
- **Recurrente añadido:** Pisionidae (`pision`).
- **Minijefe INACTIVO (referencia histórica):** `mini_w02_arenicola` (ID antiguo, pendiente de migración).
- **Jefe(s) final(es) ACTIVO(S):** `boss_w02_capit`.
- **Presupuesto de enemigos normales:** 125 (sin aumento automático).

### Mundo 3: Bosques de kelp (antiguo 4; acto 1)

- **Normales que conserva (base):** Spirorbis (Serpulidae) (`spirorbis`), Myxicola (Sabellidae) (`myxicola`), Spintheridae (`spinther`), Trochochaeta (`trocho`), Ctenodrilidae (`cteno`).
- **Normales agregados:** Dodecaceria (Cirratulidae) (`dodeca`), Sphaerodoridae (`spha`).
- **Recurrentes que conserva:** Syllidae (`syll`), Phyllodocidae (`phyll`), Cirratulidae (`cirrat`).
- **Recurrente añadido:** Hesionidae (`hesio`).
- **Minijefe INACTIVO (referencia histórica):** `mini_w04_myxicola` (ID antiguo, pendiente de migración).
- **Jefe(s) final(es) ACTIVO(S):** `boss_w04_tere`.
- **Presupuesto de enemigos normales:** 135 (sin aumento automático).

### Mundo 4: Arrecifes tropicales (antiguo 5; acto 2)

- **Normales que conserva (base):** Spirobranchus giganteus (`spirobranchus`), Sabellastarte (`sabellastarte`), Eulepethidae (`eulepeth`), Acoetidae (`acoet`), Pholoe (`pholoe`).
- **Normales agregados:** Oenone (Oenonidae) (`oenone`), Chaetopterus (`chaetopterus`).
- **Recurrentes que conserva:** Syllidae (`syll`), Phyllodocidae (`phyll`), Hesionidae (`hesio`).
- **Recurrente añadido:** Serpulidae (`serp`).
- **Minijefe INACTIVO (referencia histórica):** `mini_w05_spirobranchus` (ID antiguo, pendiente de migración).
- **Jefe(s) final(es) ACTIVO(S):** `boss_w05_hermo`.
- **Presupuesto de enemigos normales:** 135 (sin aumento automático).

### Mundo 5: Estuarios y fango (antiguo 7; acto 2)

- **Normales que conserva (base):** Aricidea (Paraonidae) (`aricidea`), Terebellides (`terebellides`), Questa (`questa`), Fauveliopsidae (`fauvel`), Protodrilus (`protod`).
- **Normales agregados:** Arabella (Arabellidae) (`arabella`), Hediste diversicolor (`hediste_diversicolor`).
- **Recurrentes que conserva:** Spionidae (`spio`), Nephtyidae (`nepht`), Glyceridae (`glycer`).
- **Recurrente añadido:** Magelona (Magelonidae) (`magelona`).
- **Minijefe INACTIVO (referencia histórica):** `mini_w07_terebellides` (ID antiguo, pendiente de migración).
- **Jefe(s) final(es) ACTIVO(S):** `boss_w07_orbin`.
- **Presupuesto de enemigos normales:** 150 (sin aumento automático).

### Mundo 6: Sedimentos contaminados (antiguo 8; acto 2)

- **Normales que conserva (base):** Ophelia (`ophelia`), Cossura (`cossura`), Sigambra (Pilargidae) (`pilarg`), Lumbrineris (`lumbrineris`), Owenia (`owenia`).
- **Normales agregados:** Capitella capitata (complejo) (`capitella_capitata`), Polydora ciliata (`polydora_ciliata`).
- **Recurrentes que conserva:** Glyceridae (`glycer`), Dorvilleidae (`dorville`).
- **Recurrente añadido:** Spionidae (`spio`).
- **Minijefe INACTIVO (referencia histórica):** `mini_w08_lumbrineris` (ID antiguo, pendiente de migración).
- **Jefe(s) final(es) ACTIVO(S):** `boss_w08_pollution_capit`, `boss_w08_pollution_spio`, `boss_w08_pollution_cirrat`.
- **Presupuesto de enemigos normales:** 162 (sin aumento automático).

### Mundo 7: Zona planctónica (antiguo 9; acto 3)

- **Normales que conserva (base):** Pontodora (`pontod`), Lopadorrhynchidae (`lopado`), Typhloscolecidae (`typhlo`), Poeobius (`poeo`), Iospilidae (`iospil`).
- **Normales agregados:** Vanadis antarctica (`vanadis_antarctica`), Pelagobia longicirrata (`pelagobia_longicirrata`).
- **Recurrentes que conserva:** Estolones de Syllidae (`syll_stolon`), Alciopidae (`alciop`).
- **Recurrente añadido:** Swima (Acrocirridae) (`swima`).
- **Minijefe INACTIVO (referencia histórica):** `mini_w09_lopado` (ID antiguo, pendiente de migración).
- **Jefe(s) final(es) ACTIVO(S):** `boss_w09_tomo`.
- **Presupuesto de enemigos normales:** 162 (sin aumento automático).

### Mundo 8: Zona antártica (antiguo 10; acto 3)

- **Normales que conserva (base):** Flabegraviera (`flabegraviera`), Aphelochaeta (`aphelochaeta`), Maldanidae (`mald`), Perkinsiana (Sabellidae) (`perkinsiana`), Ampharetidae (`amphar`).
- **Normales agregados:** Laetmonice producta (`laetmonice_producta`), Austrolaenilla antarctica (`austrolaenilla_antarctica`).
- **Recurrentes que conserva:** Spionidae (`spio`), Serpulidae (`serp`), Alciopidae (`alciop`).
- **Recurrente añadido:** Aphroditidae (`aphro`).
- **Minijefe INACTIVO (referencia histórica):** `mini_w10_flabegraviera` (ID antiguo, pendiente de migración).
- **Jefe(s) final(es) ACTIVO(S):** `boss_w10_eulagisca`.
- **Presupuesto de enemigos normales:** 200 (sin aumento automático).

### Mundo 9: Restos de ballena (antiguo 11; acto 3)

- **Normales que conserva (base):** Hesiocaeca (`hesiocaeca`), Nautiliniellidae (`nautil`), Chrysopetalidae (`chryso`), Brada (Flabelligeridae) (`brada`), Bathykurila (`bathykurila`).
- **Normales agregados:** Glycera (Glyceridae) (`glycera`), Neanthes visicete (`neanthes_visicete`).
- **Recurrentes que conserva:** Cirratulidae (`cirrat`), Ophryotrocha (`ophryotrocha`).
- **Recurrente añadido:** Sphaerodoridae (`spha`).
- **Minijefe INACTIVO (referencia histórica):** `mini_w11_chryso` (ID antiguo, pendiente de migración).
- **Jefe(s) final(es) ACTIVO(S):** `boss_w11_osedax`.
- **Presupuesto de enemigos normales:** 200 (sin aumento automático).

### Mundo 10: Campos hidrotermales (antiguo 12; acto 3)

- **Normales que conserva (base):** Riftia pachyptila (`riftia`), Paralvinella (`paralvinella`), Branchinotogluma (`branchinotogluma`), Amphisamytha (`amphisamytha`), Hesiolyra (`hesiolyra`).
- **Normales agregados:** Branchipolynoe (`branchipolynoe`), Thermopolynoe (`thermopolynoe`).
- **Recurrentes que conserva:** Serpulidae (`serp`), Cirratulidae (`cirrat`), Dorvilleidae (`dorville`).
- **Recurrente añadido:** Ophryotrocha (`ophryotrocha`).
- **Minijefe INACTIVO (referencia histórica):** `mini_w12_paralvinella` (ID antiguo, pendiente de migración).
- **Jefe(s) final(es) ACTIVO(S):** `boss_w12_alvinella`.
- **Presupuesto de enemigos normales:** 245 (sin aumento automático).

### Mundo 11: Zona hadal (antiguo 13; acto 3)

- **Normales que conserva (base):** Swima (Acrocirridae) (`swima`), Aphroditidae (`aphro`), Scalibregmatidae (`scali`), Sternaspidae (`stern`), Macellicephaloides (`macellicephaloides`).
- **Normales agregados:** Macellicephala tricornis (`macellicephala_tricornis`), Bathykermadeca hadalis (`bathykermadeca_hadalis`).
- **Recurrentes que conserva:** Nephtyidae (`nepht`), Glyceridae (`glycer`), Dorvilleidae (`dorville`), Alciopidae (`alciop`), Cirratulidae (`cirrat`).
- **Recurrente añadido:** Bathykurila (`bathykurila`).
- **Minijefe INACTIVO (referencia histórica):** `mini_w13_aphro` (ID antiguo, pendiente de migración).
- **Jefe(s) final(es) ACTIVO(S):** `boss_w13_hadalsovereign`, `boss_w13_riftia`.
- **Presupuesto de enemigos normales:** 285 (sin aumento automático).

### Mundo 12: El laboratorio (antiguo 14; acto 4)

- **Normales que conserva (base):** Cablelarva (robot) (`mech_syll`), Nereis Mk1 (robot) (`mech_nereis`), Torreta Sabélida (robot) (`mech_sabel`), Taladro Arenicola (robot) (`mech_chaet`), Pinza Glicera (robot) (`mech_riftia`), Escudo Afrodita (robot) (`mech_polyn`).
- **Normales agregados:** Centinela Oenone (robot original) (`mech_oenone`), Artillería Diopatra (robot original) (`mech_diopatra`).
- **Recurrentes que conserva:** Hydroides (Serpulidae) (`hydroides`), Euphrosine (Euphrosinidae) (`euphrosine`), Fabriciidae (`fabric`), Pisionidae (`pision`), Lacydoniidae (`lacy`), Syllidae (`syll`), Phyllodocidae (`phyll`), Arenicola (Arenicolidae) (`arenicola`), Magelona (Magelonidae) (`magelona`), Sthenelais (Sigalionidae) (`sthenelais`), Saccocirrus (`sacco`), Goniada (`goniada`), Spionidae (`spio`), Nephtyidae (`nepht`), Glyceridae (`glycer`), Dodecaceria (Cirratulidae) (`dodeca`), Oenone (Oenonidae) (`oenone`), Arabella (Arabellidae) (`arabella`), Sphaerodoridae (`spha`), Histriobdellidae (`histrio`), Serpulidae (`serp`), Hesionidae (`hesio`), Spirorbis (Serpulidae) (`spirorbis`), Myxicola (Sabellidae) (`myxicola`), Spintheridae (`spinther`), Trochochaeta (`trocho`), Ctenodrilidae (`cteno`), Cirratulidae (`cirrat`), Spirobranchus giganteus (`spirobranchus`), Sabellastarte (`sabellastarte`), Eulepethidae (`eulepeth`), Acoetidae (`acoet`), Pholoe (`pholoe`), Glycera (Glyceridae) (`glycera`), Diopatra (Onuphidae) (`diopatra`), Chaetopterus (`chaetopterus`), Sabellaria (`sabellaria`), Pectinaria (`pectinaria`), Aricidea (Paraonidae) (`aricidea`), Terebellides (`terebellides`), Questa (`questa`), Fauveliopsidae (`fauvel`), Protodrilus (`protod`), Ophelia (`ophelia`), Cossura (`cossura`), Sigambra (Pilargidae) (`pilarg`), Lumbrineris (`lumbrineris`), Owenia (`owenia`), Dorvilleidae (`dorville`), Pontodora (`pontod`), Lopadorrhynchidae (`lopado`), Typhloscolecidae (`typhlo`), Poeobius (`poeo`), Iospilidae (`iospil`), Estolones de Syllidae (`syll_stolon`), Alciopidae (`alciop`), Flabegraviera (`flabegraviera`), Aphelochaeta (`aphelochaeta`), Maldanidae (`mald`), Perkinsiana (Sabellidae) (`perkinsiana`), Ampharetidae (`amphar`), Hesiocaeca (`hesiocaeca`), Nautiliniellidae (`nautil`), Chrysopetalidae (`chryso`), Brada (Flabelligeridae) (`brada`), Bathykurila (`bathykurila`), Ophryotrocha (`ophryotrocha`), Riftia pachyptila (`riftia`), Paralvinella (`paralvinella`), Branchinotogluma (`branchinotogluma`), Amphisamytha (`amphisamytha`), Hesiolyra (`hesiolyra`), Swima (Acrocirridae) (`swima`), Aphroditidae (`aphro`), Scalibregmatidae (`scali`), Sternaspidae (`stern`), Macellicephaloides (`macellicephaloides`).
- **Recurrente añadido:** Capitella capitata (complejo) (`capitella_capitata`).
- **Minijefe INACTIVO (referencia histórica):** `mini_w14_mech_nereis` (ID antiguo, pendiente de migración).
- **Jefe(s) final(es) ACTIVO(S):** `boss_w14_robot_pinza`, `boss_w14_robot_torreta`, `boss_w14_robot_taladro`, `boss_w14_epitoke`, `boss_w14_scientist`, `boss_w14_eunice_titan`.
- **Presupuesto de enemigos normales:** 250 (sin aumento automático).

## Relocalización del contenido de los mundos eliminados

| Enemigo exclusivo antiguo | Antes | Nueva asignación |
|---|---|---|
| Dodecaceria (Cirratulidae) (`dodeca`) | W03 o W06 | Nuevo mundo 3, kelp |
| Oenone (Oenonidae) (`oenone`) | W03 o W06 | Nuevo mundo 4, arrecifes |
| Arabella (Arabellidae) (`arabella`) | W03 o W06 | Nuevo mundo 5, estuarios |
| Sphaerodoridae (`spha`) | W03 o W06 | Nuevo mundo 3, kelp (también recurrente en W09) |
| Histriobdellidae (`histrio`) | W03 o W06 | Solo como recurrente de laboratorio, ya incluido en datos previos |
| Glycera (Glyceridae) (`glycera`) | W03 o W06 | Nuevo mundo 9, restos de ballena |
| Diopatra (Onuphidae) (`diopatra`) | W03 o W06 | Nuevo mundo 2, playas |
| Chaetopterus (`chaetopterus`) | W03 o W06 | Nuevo mundo 4, arrecifes (en tubos de sedimento del arrecife) |
| Sabellaria (`sabellaria`) | W03 o W06 | Nuevo mundo 1, superficie costera (anclado al sustrato) |
| Pectinaria (`pectinaria`) | W03 o W06 | Nuevo mundo 2, playas (semienterrado) |

El jefe final archivado `boss_w03_polyn` y minijefe archivado `mini_w03_oenone`, así como el jefe `boss_w06_leafqueen` y minijefe `mini_w06_glycera`, se preservan sin destino de campaña hasta aprobación explícita. **No eliminarlos del repositorio sin autorización.**

## Mecánicas ecológicas sugeridas para las incorporaciones

- Organismos tubícolas (Sabellaria, Pectinaria, Diopatra, Chaetopterus, etc.): adheridos al terreno, a sedimento o sustrato; no flotan como peces.
- Cavadores y oportunistas (Capitella, Polydora, Hediste): emergen desde sedimento, emboscan o forman colonias; movimientos cortos y con telegráficos.
- Pelágicos (Vanadis, Pelagobia): nado activo, ondulación y ataques en columna de agua.
- Polinoideos hadales (Macellicephala, Bathykermadeca): movimiento bentónico de profundidad; escala y animación diferenciables del jefe Macellicephaloides.
- Robots del laboratorio: dos especies mecánicas nuevas, con diseños originales coherentes con el laboratorio y comportamiento distinto de los 6 robots anteriores.

## Migración técnica para Codex

1. Elaborar una matriz de `old_id -> new_id` (1→1, 2→2, 4→3, 5→4, 7→5, 8→6, 9→7, 10→8, 11→9, 12→10, 13→11, 14→12, escape 15→13). No aplicar sustituciones globales a ciegas.
2. Actualizar `data/worlds.json`, `data/waves/world_*.json`, `data/enemies.json`, `data/bosses.json`, `data/shop.json`, catálogos de assets y sus atlas, pruebas, menús, desbloqueos de actos, selector de Pruebas y escala de dificultad. Mantener los cuatro actos.
3. Los nuevos enemigos requieren IDs nuevos, sprites PNG y atlas, audio si corresponde, configuración de comportamiento y patrones de disparo, registro de drops y casos de prueba. No crear simples recolores que no se distingan.
4. Mantener copias recuperables de guardados previos y crear migración explícita para perfiles con mundo antiguo 3 o 6; no sobrescribir la partida del usuario ni asignar automáticamente un progreso posterior sin revisión.
5. Revisar los tramos y recompensas de la campaña, que ahora dura menos; los presupuestos de compra siguen requiriendo análisis de economía.
6. No comenzar los 12 mundos juntos. Primero aprobar la actualización del spec y la matriz de migración, después modificar el mundo 1, probar instaladores Normal y Pruebas, y continuar mundo a mundo.

## Referencias para taxones propuestos

- World Register of Deep-Sea Species: https://www.marinespecies.org/deepsea/
- Sobre sedimentos enriquecidos, Capitella y Polydora: https://www.marlin.ac.uk/habitats/detail/106
- Estuarios y Hediste: https://invasions.si.edu/nemesis/species_summary/-673
- Pelágicos del océano austral, Vanadis y Pelagobia: https://data.aad.gov.au/metadata/records/fulldisplay/AADC-00020
- Fauna antártica y Laetmonice producta: https://webstatic.niwa.co.nz/library/Memoir%20108_Marine%20Fauna%20of%20Ross%20Sea_Polychaeta%20-%201998.pdf
- Baleas y Neanthes visicete: https://journals.australian.museum/georgieva-2023-rec-aust-mus-753-167213/
- Polinoideos de fuentes hidrotermales: https://academic.oup.com/zoolinnean/article/185/3/555/5181329
- Especies profundas/hadales Macellicephala tricornis y Bathykermadeca hadalis: https://www.sciencedirect.com/science/article/pii/S0967063725000494

> **Cautela científica:** La inclusión en un mundo responde a una propuesta de diseño plausible; la presencia de un género en otro océano o profundidad no garantiza que todas sus especies vivan allí. Antes de presentar fichas con distribución exacta, confirmar taxón y región.
