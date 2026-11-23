# Traspaso — «Logroño: el juego»

Documento para que otro asistente (u otra cuenta) continúe el proyecto sin perder nada. Fecha: 23-nov-2026.

## Qué es

Juego de mundo abierto ambientado en Logroño, en Godot 4.3, construido **clean-room**: código, arte y textos nuevos, desde las mismas fuentes de datos abiertos que cualquiera puede usar (OpenStreetMap, Catastro INSPIRE e IGN PNOA/MDT). Del juego original «Badajoz: El Juego» solo se tomó el *cómo está hecho* (ingeniería inversa de su estructura), nunca assets, textos, código ni datos. Los nombres y sitios de tiendas reales vienen de los datos abiertos: son hechos, no creación del original. **Regla de oro: ninguna tienda inventada; solo OSM o verificables a mano (anotadas como manuales).**

## Dónde está cada cosa

- **Código y datos**: este paquete (carpetas `juego/`, `pipeline/`, `banco/`, `datos/`, `docs/`).
- **Repo GitHub (privado)**: https://github.com/jpecinagithub/logrono-el-juego — commit inicial con estos mismos 449 archivos.
- **Juego publicado (web)**: https://jpecina.duckdns.org/logrono/ — en el servidor Oracle de Jon, carpeta `/var/www/projects/logrono/`.
- **APK Android firmado**: `logrono-prototipo.apk` en la raíz del paquete (build del Bloque 6, sha 7734586c42ff03a9…; la web ya lleva el Bloque 7).
- **Clave de firma del APK**: `tools/debug.keystore` (alias `androiddebugkey`, contraseña `android`) — incluida en el paquete porque sin ella no se puede firmar una actualización instalable encima de la anterior.
- **Herramientas NO incluidas** (2,5 GB, se descargan): Godot 4.3 stable (binario en `tools/`), JDK y Android SDK (rutas esperadas: `tools/jdk` y `tools/android-sdk`).

## Estado (23-nov-2026)

- Fases 0–14 completas y publicadas: ciudad entera con streaming por baldosas (5,4×4,0 km), encargos, mapa, tráfico, peatones, interiores, trabajos especiales, historia propia (12 misiones) y carreras.
- Plan «Logroño calle a calle»: **Bloques 4 Ribera, 3 Superficies, 5 Gaunas, 1 Pinchos, 2 Ejes, 6 Barrios y 7 Transversales — cerrados y publicados. Plan calle a calle COMPLETO.**
- **Bloque 7 (23-nov, PUB18 BOOT_OK)**: placas extendidas a toda la ciudad (1.071 con dedupe, PLACAS_OK), 203 paradas con marquesina y nombre por proximidad, y 84 contenedores, todo fundido en una sola malla (`_crear_bloque7()` + horneado `banco/bake_bloque7.py`; datos en `juego/datos/ciudad/placas_ciudad.json`, `paradas.json`, `contenedores.json`). Detalle en `GOAL.md`. **Ojo: el APK publicado sigue siendo el build del Bloque 6** — la web va por delante; reexportar el APK cuando esté el keystore a mano.
- **Tanda 2 · Vida y arreglos (23-nov, PUB19 BOOT_OK; commit 013871f)**: paradas/contenedores/placas fuera de la calzada (0 en asfalto); Parque Gallarza con verde, columpios, abuelos y balón; el mapa ya no dibuja la recta de los interiores; República Argentina sigue su curva real con 21 tramos; bici de montaña «Grajera» (id 13); 141 personas, 22 coches y **25 autobuses urbanos** que paran en las paradas; **Decathlon entrable** con 10 productos comprables (la Grajera entra en el garaje). Copia previa: `~/logrono-bak-b7-20261123.tar.gz`. El APK sigue en el Bloque 6. **OJO: la primera PUB19 rompió el dibujo web** (censo 972 mallas vs 441 del Bloque 7: el fallo del 21-nov); arreglado el mismo día con visibilidad por proximidad y republicado (commit 116cf03, verificado con captura real de la URL pública).
- Decisiones de Jon pendientes (no perseguir): historia larga 13B (9 capítulos o entera con 3), multijugador como Fase 17, ortofoto PNOA generalizada, tamaño de la «g» de Glera en la espalda del personaje.

## Cómo se trabaja

- Script principal: `juego/generar_barrio.gd` (~11.500 líneas, todo el juego). Datos de la ciudad: `juego/datos/ciudad/` (baldosas `tiles/t_<x>_<y>.json`, locales, frentes, calles, pois…).
- **Los argumentos de modo van tras `--`**: `Godot --headless --path juego -- verificar`. Sin el `--`, el juego arranca en modo libre y nunca sale.
- Verificaciones: `verificar` (carga completa con marcas \*_OK), `probar_historia`, `probar_berceo`, `probar_agua`, `probar_bici`, `probar_carreras` (esta tarda ~10 min).
- Capturas: SIN `--headless`, con `xvfb-run -a Godot --path juego -- capturar_<nombre>`.
- **Nunca importar módulos de `pipeline/` en Python**: se ejecutan al importarlos y regeneran la ciudad (ya borraron una vez los locales de las baldosas). Para auditar, copiar las funciones de proyección en el script propio.
- Proyección OSM→juego: UTM con lon0=−3°, origen = centro del bbox lon −2.4535..−2.4320, lat 42.4615..42.4725; norte = z menor.

## Publicar (web + APK)

1. Web: exportar preset «Web» (escribe en `juego/web/`), copiar a una carpeta limpia, `chmod -R a+rX`, rsync al servidor: `/var/www/projects/logrono/`.
2. APK: exportar preset «Android» (sale sin firmar, es normal), `zipalign` y firmar a mano con `apksigner` usando `tools/debug.keystore`; verificar con `apksigner verify`.
3. **Verificación obligatoria por el camino real del usuario**: sesión en un navegador real sobre la URL pública hasta que el banco de pruebas diga BOOT_OK. Las capturas del motor de escritorio NO cazan los fallos de WebGL.
4. **Presupuesto web (lección dura)**: la build web de Godot 4.3 deja de dibujar el mundo al pasar de ~1.000 objetos sueltos. Todo lo que se repita en masa va fundido en mallas de colores de vértice o limitado por proximidad, y antes de publicar se hace censo de objetos y una partida larga en la web.

## Reglas de Jon para este proyecto

- «Sigue directo»: encadenar los bloques aprobados sin pedir su visto bueno en cada cierre; avisar solo cuando cada bloque esté publicado, con fotos.
- Los arreglos se anuncian solo cuando están publicados y visibles para él, con capturas.
- Español llano, sin jerga. Nada se publica ni se despliega sin que la tanda esté terminada y verificada.
- Su partida guardada (en su navegador) no se toca: las pruebas usan partidas separadas.

## Planes y notas (carpeta `traspaso/`)

- `PLAN-CALLES-Y-ZONAS.md` — el plan vigente calle a calle (bloques 1–7).
- `PLAN-DETALLE-UX.md`, `PLAN-IGUALAR-MODELO.md`, `PLAN-HITOS-50.md`, `ANALISIS-BRECHA-BADAJOZ.md` — planes anteriores ya ejecutados en su mayor parte.
- `GOAL.md` — el diario técnico completo del proyecto: cada fase, cada publicación (con hashes) y cada lección. Es la fuente de verdad del detalle.
