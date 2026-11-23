# Análisis de brecha — «Logroño: El Juego» frente a «Badajoz: El Juego»

**Fecha:** 21 de noviembre de 2026 · **Encargo:** Jon («qué le falta al proyecto de Logroño para ser como el de Badajoz, al nivel del detalle de las calles»)

**Método.** Todo lo que se afirma del original sale de sus propios ficheros, excavados en la Fase 0 y en esta pasada: su `game.json` (la ciudad en datos), las recetas de vestido de calles (`detalle/recetas/badajoz.json`), los JSON de trabajos, carreras, historia, coches y colecciones, el meta de los NPC y su banco de sonidos. Lo nuestro sale del inventario real del proyecto (datos y código de las Fases 1–4). Nada es de memoria ni de la ficha de la tienda.

---

## 0. La foto en una frase

El original no es «nuestro prototipo con mejor aspecto»: es **otra escala de producto en casi todo** — la ciudad entera frente a un barrio, y dentro de cada calle, un nivel de acabado que viene de *recetas escritas calle a calle*, no de reglas uniformes. Nuestro esqueleto de juego (encargos, dinero, mapa, guardado) ya es comparable en miniatura; la brecha grande está en **escala, detalle por calle, tráfico, interiores, historia y sonido**.

| Área | Badajoz (evidencia en sus ficheros) | Logroño hoy | Brecha |
|---|---|---|---|
| Ciudad jugable | Entera: radio 6.624 m, 28 barrios, ~34 km² | Un barrio: 1,78 × 1,21 km (~2,2 km²) | **Enorme** |
| Edificios | 12.007 viviendas con 14 datos cada una (puerta, m², plantas, año…) | 10.257 piezas de un barrio, solo planta y plantas | Grande |
| Calles | 1.214 con nombre + recetas de vestido por calle | 1.452 tramos de un barrio, vestido uniforme por clase | Grande (ver §2) |
| Lugares (POI) | 761 en ~120 tipos (102 fuentes, 79 restaurantes, 38 bancos…) | 28 lugares elegidos a mano | Grande |
| Locales | 619 locales con puerta y tipo; interiores jugables | 0 interiores | **Total** |
| Vehículos | Catálogo de 15 coches en 5 clases, compraventa y taller | 1 coche genérico | Grande |
| Tráfico | Coches circulando (sistema `traffic`) | Solo 110 aparcados estáticos | **Total** |
| Personas | 2 modelos con 9 comportamientos, multitudes, perros, pájaros | 12 peatones con balanceo | Grande |
| Historia | 9 capítulos, 42 misiones, 12 personajes con retrato | No hay | **Total** |
| Trabajos | Autobús, reparto con furgoneta, camalote, gimnasio, recados | Recados y repartos generados | Media |
| Carreras | 75 circuitos, 4 modos, rivales, liga | No hay | **Total** |
| Coleccionables | 48 cromos en 6 páginas, nidos, fotos | No hay | Media |
| Sonido | 106 eventos: motor, pasos, ambiente, música | Silencio | **Total** |
| Mapa | Filtros por categorías, buscador de calles, menú completo | Mapa básico con ruta y recorrido | Media |
| Controles | Táctil completo + cámara giroscópica | Solo teclado | Grande (en móvil) |
| Online | Modo en vivo con liga, chat y avisos | No hay | **Total** (fuera de alcance acordado) |

---

## 1. La ciudad y su escala

**Ellos.** La ciudad entera viene generada de fábrica en 525 baldosas (149 MB) que el juego carga y descarga por proximidad (`stream/city_stream.gd`): 28 barrios con su polígono, su «tier» y su pilar de luz propio; el descriptor de ciudad incluye spawn, miradores («views») y una ruta «tour». El rendimiento está medido por zonas (`detalle/medidas_q0.json`: triángulos, draw calls y milisegundos en puntos concretos, p. ej. Plaza de España, con y sin vestido).

**Nosotros.** Un solo barrio (Centro/Casco Antiguo) generado al arrancar desde JSON compactos y entero en memoria: 10.257 piezas de edificios, 1.452 tramos de calle, 2.224 portales. Funciona porque son 2,2 km²; **no escalaría a la ciudad entera sin el sistema de baldosas**. La materia prima sí la tenemos: en la Fase 1 ya extrajimos Logroño completo (6.327 edificios, 36.977 piezas, 10.099 portales, 557 calles con nombre) — falta el troceado y la carga por proximidad.

**Brecha:** arquitectura de streaming + generar los demás barrios. Es la obra de base de la que cuelga todo lo demás.

---

## 2. Las calles, al detalle (el corazón de este análisis)

Aquí es donde el original se separa de verdad, y no es por los gráficos: es porque **cada calle con nombre tiene una receta escrita**.

### 2.1 Los datos que ellos guardan de cada calle y cada casa

- `streets`: 1.214 calles con nombre, los barrios que cruza y su geometría.
- `homes`: 12.007 viviendas, cada una con **14 campos**: referencia catastral, posición, **posición exacta de la puerta** (`door_x`, `door_z`), metros de planta, **plantas, número de viviendas, año de construcción**, barrio, **calle y número**, tipo y número «real». Es decir: el juego sabe dónde está la puerta de cada casa, de qué año es y cuánta gente vive en el edificio.
- `roads`: la red viaria como grafo propio para rutas y tráfico.
- Suelo con **ortofoto real del PNOA** en zonas: el suelo que pisas es la foto aérea de tu calle.

**Nosotros:** de cada portal guardamos calle, número y posición (2.224 en el barrio); de los edificios, planta y plantas. **No guardamos la puerta como punto jugable distinto, ni año, ni viviendas, ni metros** — aunque el Catastro que ya descargamos en la Fase 1 trae varios de esos datos y no los estamos usando.

### 2.2 Las recetas de vestido: calle a calle, con nombre y apellidos

El fichero `detalle/recetas/badajoz.json` es, literalmente, un libro de recetas por calle. Ejemplo real, la Avenida de Colón:

- **Árboles**: cada **8,0 m**, a **1,9 m del bordillo**, alternando especies con nombre — *magnolio, plátano de sombra, copa ancha, palmera* — cada especie con su paleta de verdes propia (el magnolio tiene tres verdes suyos).
- **Césped**: franja de **2,4 m** de ancho a 2,0 m del bordillo, con su color.
- **Bancos**: cada **24 m**, en **ambos lados**, una pieza concreta («banco_hierro»).
- Y así calle por calle: paseos con su paso de peatones, pirámides, fuentes…

Y un detalle que dice mucho del nivel: hay **receta de Navidad** — guirnaldas cada 22 m a 6,4 m de alto en seis calles concretas (Menacho, San Juan, Muñoz Torrero…), ristras cruzando el Paseo de San Francisco y la Plaza de España, y un cono luminoso de 13,5 m en la Plaza de España. El vestido cambia con la temporada y con la calle.

**Nosotros (Fase 4):** vestido *uniforme por clase de vía* — farola cada ~30 m con un 30 % de huecos al azar, papelera cada cuarta farola, bancos junto a los 28 lugares, líneas discontinuas en avenidas anchas. Son 457 farolas y se nota, pero **una avenida y una calleja reciben el mismo trato**, y ningún árbol sabe qué especie es: los 648 árboles son los que OSM marca, todos con la misma copa.

**Brecha, en concreto:**
1. Recetas por nombre de calle (aunque sean 15–20 calles principales de Logroño: Gran Vía, Avenida de La Rioja, Calle Portales, San Antón, el Espolón…) con especie, distancia y mobiliario propios.
2. Aceras y bordillos como geometría: ellos los tienen (la física de sus coches distingue el bordillo: «el ligero bota en los bordillos», con un parámetro `kerb` por coche). Nosotros: cinta de asfalto plana a ras de suelo, sin acera.
3. Pasos de cebra y marcas viales completas (nosotros solo línea central discontinua en avenidas).
4. Ortofoto PNOA de suelo al menos en plazas y paseos (la tenemos localizada desde la Fase 1; no descargada).

### 2.3 Los coches aparcados tienen lógica, no azar

Su `parked_off.json` + `stream/tile_life.gd` colocan los aparcados **comprobando que no tapen las puertas de las casas** (para eso sirve el `door_x/door_z` de cada vivienda) y contrastándolo con la ortofoto. **Nosotros:** aparcados a lo largo de los tramos con salto aleatorio del 30 % y comprobación de colisión con edificios — pueden caer frente a un portal sin que lo sepamos.

### 2.4 Señalización y radares

- Ellos muestran el **nombre de la calle en una pastilla superior** al entrar en ella (visto en tus capturas) — nosotros tenemos el equivalente («Estás en…») ✔.
- **Radares**: fichero propio con las cabinas en avenidas concretas **y las fuentes documentadas** (noticias y listados de radares reales). Es un sistema de juego: correr tiene consecuencias. Nosotros: ninguno.

---

## 3. Edificios e interiores

**Ellos.** Además de los datos de §2.1, cada baldosa trae `.int.json.gz` (interiores) y `.shops.json.gz` (tiendas). Hay **619 locales** con puerta, calle, número, m² y edificio. Interiores jugables: **tu casa** (con su mobiliario), **gimnasios** (6, con actividad propia y su trabajo de +75 €), **peluquería** y **tiendas de ropa** ligadas a la personalización del personaje (`interiors/clothes`, `interiors/hair`, `interiors/home`), y un atlas de tiendas por categorías. El Ayuntamiento es un lugar con puerta, coche oficial y función de juego: **desbloquea la bolsa de empleo**.

**Nosotros.** Fachadas extrudidas con 3 texturas procedurales y 8 tonos; **cero interiores**: no se puede entrar en ningún sitio, ni siquiera en tu casa (que ni existe como concepto: apareces en la calle Miguel Villanueva 1 porque es tu dirección real, no porque vivas ahí dentro).

**Brecha:** total en interiores. Lo mínimo comparable: tu piso (una habitación sencilla), el Ayuntamiento como desbloqueo y 3–4 locales con interior simple.

---

## 4. Vehículos y tráfico

**Ellos.**
- **Catálogo de 15 coches inventados en 5 clases** (pequeño, familiar, clásico, deportivo, furgoneta), cada uno con física propia: velocidad punta, aceleración, frenada, agarre, giro, **peso** (sube peor las cuestas), **sensibilidad al bordillo**, comodidad (afecta a los pasajeros del bus) y capacidad de carga (afecta a los repartos). Con precio, reventa, **concesionario, taller y garaje** (la plaza extra es del VIP).
- **Tráfico circulante**: sistema `traffic.gd` con sus sonidos (bocinas, ruido de tráfico). Las calles tienen coches que *van a sitios*.
- **Autobús conducible** con modelo propio: pasajeros que suben y bajan, puertas con su sonido, timbre, puntuación del servicio.
- **Furgoneta de reparto** de 4,9 m para el trabajo de repartidor.
- En carreras: **coche fantasma** (el tuyo y el de la medalla) y rivales con nombre y manías.

**Nosotros.** Un único coche (caja roja con cabina y ruedas), sin física más allá de acelerar/frenar/girar; 110 aparcados decorativos; **tráfico cero**. El autobús ni existe — y eso que en la Fase 1 ya extrajimos las 10 líneas diurnas y 3 búho de Logroño con sus 254 paradas desde OSM: el dato está listo desde el primer día.

**Brecha:** tráfico circulante (la ciudad se mueve) y un segundo vehículo con sentido (la furgoneta de los repartos). El catálogo de 15 es pulido posterior.

---

## 5. Personas y vida de la calle

**Ellos.** Dos modelos 3D reales (GLB) con un sistema de **clips de comportamiento**: andar, parado, hablar, mirar el móvil, teclear, sentarse, sentarse a hablar, coger algo, sujetar algo — cada clip con sus fotogramas y **los instantes exactos de cada pisada**, sincronizados con el sonido de pasos. Hay **multitudes** (`crowd`), **perros** (modelo propio), **pájaros** que echan a volar (`birds`, con sonido de aleteo) y ambiente sonoro de voces y agua. Y un sistema que a nosotros ni se nos había ocurrido: **encuentros por la calle** — un director que, según el barrio, la hora del reloj del juego y la temporada, te planta pequeñas escenas con vecinos (con sus tiempos de reutilización y caducidad medidos). El personaje además **se personaliza**: apariencia, pelo y ropa (`player/appearance.gd`).

**Nosotros.** 12 peatones-primo del protagonista (mismo muñeco de piezas, otra camisa) que pasean por el grafo balanceando brazos y piernas. Sin comportamientos (nadie se sienta en los bancos que pusimos, nadie mira el móvil), sin perros ni pájaros, sin encuentros y sin personalización.

**Brecha:** comportamientos (sentarse en bancos y plazas es el que más se ve) y encuentros. Los clips con pisada sincronizada son nivel de acabado profesional.

---

## 6. El juego: historia, trabajos, carreras, colecciones

**Ellos.**
- **Historia**: 9 capítulos, **42 misiones**, **12 personajes fijos** con retrato ilustrado, rol y «broma recurrente» escrita en su ficha (Doña Remedios, tu casera, abre el juego). El capítulo 1 es la vida misma: las llaves, la compra, **el padrón en el Ayuntamiento**. Los capítulos se desbloquean por zonas y títulos.
- **Trabajos** (tras pasar por el Ayuntamiento): autobús (**5 líneas reales** con sus paradas OSM y depósito en Plaza de España), reparto con furgoneta por barrios, **camalote** (limpiar el río: el trabajo trae la física del agua — nivel, corriente, eje, pilares), gimnasio y recados.
- **Carreras**: **75 circuitos** por los 28 barrios, **4 modos** (contrarreloj con fantasma, carrera contra vecinos «limpia: sin empujar», suavidad/eco, puntos de control), 5 clases de coche, rivales inventados con manías y **liga**.
- **Colecciones**: 48 cromos en 6 páginas (comunes, raras y brillantes «solo en sitios difíciles»), nidos, fotos y retos por la ciudad.
- **Buzón** propio, economía completa (precios, reventa, taller) y la Tarjeta VIP como único pago.

**Nosotros.** Recados y repartos **generados** con destinos reales y paga por distancia real — el bucle funciona y se guarda — pero no hay historia, ni un solo personaje con nombre, ni carreras, ni autobús, ni colecciones, ni desbloqueos: todo está abierto desde el minuto uno y nada tiene contexto.

**Brecha:** la historia es la mayor en horas de contenido (42 misiones escritas y programadas); las carreras son el sistema más reutilizable (los circuitos salen del grafo de calles que ya tenemos).

---

## 7. Mapa, interfaz y controles

**Ellos.** Mapa con **filtros por categoría** (sitios públicos, tiendas, locales, trabajos, carreras, encargos, gimnasios, radares) sobre 761 POIs de ~120 tipos, **buscador de calles**, menú lateral completo (Qué hacer / Mapa / Trabajo / Mis cosas / Ajustes), pastilla con la calle actual, teléfono con avisos. Controles **táctiles** completos (hay tests de UX de volante táctil y de dirección) y hasta **cámara con giroscopio** opcional. Es un juego de móvil pensado para el móvil.

**Nosotros.** Mapa con los 28 lugares, ruta y recorrido; HUD con objetivo, calle, día/hora/dinero; ayuda inicial. **Sin buscador, sin filtros y sin táctil**: en el teléfono solo se puede mirar. Para Jon esto es especialmente relevante: su forma natural de jugarlo es el móvil.

---

## 8. Sonido

**Ellos.** Banco con **106 eventos** organizado por categorías: motor de coche y de autobús (con puertas, timbre, aire), pasos (sincronizados con los clips), ambiente de ciudad (tráfico, voces, pájaros, agua), interiores, trabajos y **música**. 248 ficheros de audio en total.

**Nosotros.** **Nada.** Ni un solo sonido: ni motor, ni pasos, ni ambiente. Es, probablemente, la brecha que más «sensación de juego acabado» da por euro invertido: el oído perdona gráficos modestos, pero el silencio absoluto delata el prototipo.

---

## 9. Tecnología (lo que no se ve)

- **Streaming por baldosas** frente a todo-en-memoria (ver §1).
- **Medición de rendimiento por zonas** con presupuesto de triángulos/draw calls: ellos saben cuánto cuesta cada plaza; nosotros no medimos (el barrio va sobrado; la ciudad entera no lo iría).
- **Motor**: Godot 4.4.1 con compilación propia; nosotros 4.3 estándar. Diferencia menor.
- **Online**: modo en vivo con liga postal, chat y avisos entre jugadores, con servidor propio. Nosotros: nada (y quedó fuera del alcance aprobado en el plan; se mantiene así salvo nueva orden).

---

## 10. Qué costaría cerrarla (orden de magnitud, no presupuesto)

Siendo claros: el original es el trabajo acumulado de un estudio unipersonal durante mucho tiempo (la ciudad se generó el 15-nov-2026 para la versión 1.2.0; hay sistemas — recetas por calle, encuentros, liga — que hablan de muchas iteraciones). **Igualarlo entero no es una fase: es un programa de meses.** Por bloques, con nuestro ritmo de fases verificadas:

| Bloque | Tamaño | Depende de |
|---|---|---|
| Ciudad entera con baldosas y streaming | XL | — (es la base) |
| Datos ricos por vivienda (puerta, año, tipo) en el pipeline | M | Catastro ya descargado |
| Recetas de vestido para ~20 calles principales + aceras/bordillos | L | Ciudad entera |
| Ortofoto PNOA de suelo en plazas/paseos | S | — |
| Aparcados que respetan puertas | S | Datos ricos |
| Tráfico circulante básico | L | Grafo viario (ya), ciudad entera |
| Furgoneta + segundo modelo de coche | M | — |
| Sonido: motor, pasos, ambiente, música libre | M | — (independiente) |
| Interiores: tu piso + Ayuntamiento + 3 locales | L | — |
| Historia corta: 3 capítulos, ~12 misiones, 4 personajes | L | Interiores (parcial) |
| Carreras: modo contrarreloj con fantasma en 10 circuitos | M | Grafo (ya) |
| Autobús jugable con 1 línea (la 1 de Logroño) | L | Datos ya extraídos en Fase 1 |
| Mapa con buscador y filtros por tipo de POI | M | POIs completos de OSM (sin hacer) |
| Controles táctiles | M | — (independiente) |
| Peatones con comportamientos (sentarse, móvil) | M | Mobiliario (ya) |
| Encuentros por la calle | M | Historia (personajes) |
| Online | XL | Fuera de alcance acordado |

**Mi recomendación de orden** (lo que más «sensación Badajoz» da por esfuerzo, sin esperar a la ciudad entera):
1. **Sonido** (independiente, transforma la sensación al instante).
2. **Controles táctiles** (para que puedas jugarlo en el móvil, que es donde está el original).
3. **Recetas para las ~20 calles principales del barrio actual** + aceras: el detalle que pedías, sobre el barrio que ya existe.
4. **Tráfico circulante** en el barrio.
5. **Ciudad entera con baldosas** (la obra grande) y, sobre ella, historia corta y carreras.

---

## 11. Lo que ya tenemos a su nivel (para no perderlo de vista)

- El **bucle de juego** (encargos con destinos reales y paga por distancia de calle, dinero, reloj, guardado) existe y está verificado de punta a punta.
- El **mapa con ruta por el grafo** y el recorrido de la sesión.
- La **etiqueta de calle** en pantalla, equivalente a su pastilla.
- El **Puente de Piedra** modelado y la luz de atardecer, que era gran parte de su firma visual.
- Y la ventaja estructural: **nuestros datos de Logroño ya están extraídos** (ciudad completa, líneas de autobús con paradas, portales) — varias fases «grandes» de ellos son, para nosotros, trabajo de montaje sobre datos que ya duermen en el disco.
