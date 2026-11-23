# Plan de trabajo — Logroño calle a calle: detalle de tiendas y particularidades por calle y zona

**Encargo de Jon, 22-nov-2026:** «desarrolla un plan de trabajo serio para analizar todas las calles de Logroño y añadir detalles a nivel de tiendas, y cosas particulares de cada calle. No he visto la plaza de toros. No he visto tampoco nada en la zona de la Ribera: el Riojaforum, los parques que puedes ver ahí. No he visto nada en la zona del Estadio de Las Gaunas, tampoco he visto el Alcampo, el Decathlon.»

**Relación con los planes anteriores:** este plan desarrolla y sustituye al Bloque B («Calles al detalle») del PLAN-DETALLE-UX, y absorbe la Tanda 5 de los 50 símbolos (los parques) dentro de su Bloque 4 (la Ribera completa). El resto del plan de detalle (F sonido, D coches, C suelo, E personas, H luz, I interiores) sigue vigente detrás de este.

---

## 1. Diagnóstico — auditoría de datos hecha el 22-nov-2026

Cifras reales del juego hoy (medidas sobre los datos, no de memoria):

- **962 locales** repartidos en las baldosas (388 tiendas, 376 bares, 62 oficinas, 46 bancos, 28 hoteles, 28 cultura, 23 farmacias, 11 gasolineras).
- **2.059 calles con nombre**; solo **195 tienen algún local**. OpenStreetMap nombra **1.449 sitios** con clase (tienda, bar, equipamiento…) dentro del mapa: hay margen de sitios reales que el juego aún no recoge.
- **21 calles concentran 441 locales** (casi la mitad). El resto es una cola larga: 36 calles con 5–9 locales y 138 calles con 1–4.
- **47 locales no caen en ninguna calle** (a menos de 30 m): son los interiores de centros comerciales y parques de tiendas — el síntoma del problema de los centros comerciales.

### Los grandes ejes comerciales (locales por calle, medido)

| Calle | Locales | Carácter real |
|---|---|---|
| Gran Vía Juan Carlos I | 52 (39 tiendas) | El eje comercial nº 1 |
| Avenida de Portugal | 40 | Eje comercial y de bares |
| Avenida Gonzalo de Berceo | 36 (29 tiendas) | La calle del Centro Comercial Berceo |
| Calle de Laurel | 28 (28 bares) | La calle de pinchos por excelencia |
| Avenida República Argentina | 24 | Eje comercial |
| Calle San Agustín | 22 (22 bares) | Zona de pinchos |
| Avenida Pérez Galdós | 22 | Eje comercial |
| Calle San Juan | 22 (19 bares) | Zona de pinchos |
| Calle Chile | 21 | Mixta |
| Avenida Juan XXIII | 20 | Eje comercial |
| Calle Portales | 18 | Casco histórico (soportales ya hechos) |
| Calvo Sotelo | 18 | Eje comercial |
| Avenida Club Deportivo | 15 | Mixta, camino de Las Gaunas |
| Avenida de La Paz | 14 | Eje comercial |
| Travesía del Laurel | 11 (11 bares) | Zona de pinchos |
| Calle Huesca | 11 | Barrio con bares |
| Marqués de Murrieta | 11 | Eje con bancos y hoteles |
| General Vara de Rey | 11 | Eje comercial |
| Calle San Antón | 9 en los datos | **Infrarrepresentada**: en la realidad es de las calles más comerciales; OSM solo trae 9 y 4 se añadieron a mano |

**El clúster de pinchos Laurel + San Juan + San Agustín + Travesía del Laurel suma ~80 bares en cuatro callejuelas.** Hoy reciben el tratamiento genérico de bar (toldo y terraza si OSM la marca); nada las distingue como el corazón gastronómico de la ciudad.

### Las zonas que Jon no ha visto — qué hay hoy en el juego (medido)

**Parque Rioja (Alcampo, Decathlon…)** — Las naves EXISTEN como geometría (losas de 22.771 m², 14.595 m², 8.101 m², todas de 1 planta), pero **mudas**: sin marca, sin entrada, sin frente. OSM nombra **32 sitios** en la zona; el juego solo tiene 6 locales (Decathlon, Norauto, la gasolinera y poco más). Faltan como frentes: **Alcampo, Leroy Merlin, ALDI, Lupa, Burger King, El Corte Inglés Outlet, MercaRioja, Delicatto**. Un aparcamiento enorme sin coches ni tótems.

**Centro Comercial Berceo** — El edificio existe (losas de 19.068 m² y 11.523 m²) y la calle Gonzalo de Berceo tiene 36 locales, pero del centro solo hay 8 de los **24 sitios que nombra OSM**: faltan **MediaMarkt, Yelmo Cines, Game, Forum Sport, Burger King, ALE-HOP, El Corte Inglés**… Un centro comercial entero reducido a una losa con un Foster's.

**Riojaforum** — Hay geometría (bloques de 2.379 m²/3 plantas, 2.124 m²/1, 1.589 m²/4) pero como bloques anónimos: no se reconoce el palacio de congresos, no tiene rótulo (su POI está sin señalar), ni explanada, ni relación con el Parque de La Ribera que tiene delante.

**Plaza de Toros de La Ribera** — Su huella es UNA losa plana de 8.799 m² y 1 planta: vista desde el suelo es un mazacote, no una plaza de toros. Sin anillo, sin gradas, sin albero, sin puerta grande. Su POI sí está señalado, pero el modelo no dice «plaza de toros» por ningún lado.

**Estadio Municipal Las Gaunas** — La huella está troceada en bloques genéricos (3.644 m², 3.024 m², 2.862 m²…): no hay campo, ni gradas en anillo, ni focos, ni rótulo. Su POI ni siquiera está señalado. Alrededor (polideportivo, Parque de Las Gaunas, Club Deportivo con 15 locales) tampoco hay ambiente de zona deportiva.

**La Ribera en conjunto** — Ya están hechos a medida: Puente de Piedra y de Hierro, Casa de las Ciencias, Franco-Españolas, Puerta del Ebro y el Bosque de la Danza (aproximado). Faltan: Riojaforum, Plaza de Toros, Parque del Ebro, Parque de La Ribera y Paseo de la Florida (estos tres son la Tanda 5 de los 50 símbolos, que este plan absorbe), y el paseo fluvial como continuo (hoy el río tiene orillas genéricas).

### Problemas de fondo que el plan debe resolver

1. **Las losas mudas**: todo edificio grande de 1 planta (naves, centros comerciales, estadio, plaza de toros) se renderiza como un bloque sin identidad. Hace falta un sistema de «edificio singular» para superficies grandes: marca, entrada, aparcamiento, rótulo en la fachada.
2. **Los inquilinos invisibles**: los sitios que OSM pone DENTRO de un centro comercial no llegaron a locales porque el cálculo de frentes buscaba la pared de un edificio y dentro de otro edificio no hay frente. Hay que darles frente sobre la fachada del centro o sobre su galería exterior.
3. **Calles sin carácter**: fuera de los hitos, todas las calles se visten igual (escaparate + cartel + toldo si es bar). Cada eje tiene su realidad: soportales en Portales (hecho), pinchos en Laurel, bancos en Miguel Villanueva (hecho), soportales comerciales en Gran Vía… el plan asigna a cada calle su «ficha» y su tratamiento.

---

## 2. Método de trabajo

1. **Auditoría automática previa a cada bloque**: script que, para las calles del bloque, genera la ficha real (locales con nombre y tipo, frentes, terrazas OSM, sitios OSM sin local) y la lista de huecos. Nada se construye de memoria: la ficha manda. (La auditoría de hoy — locales por calle y sitios OSM por zona — es la plantilla.)
2. **Reglas de construcción ya aprendidas** (no negociables): todo lo repetido en masa va fundido en mallas por colores de vértice o limitado por proximidad; censo de objetos antes de publicar; presupuesto web ~1.000 objetos dibujables.
3. **Verificación por el camino real**: cada tanda se cierra con verificar completo + capturas de las calles/zonas tocadas + sesión larga en la URL pública + APK firmado. Los arreglos se anuncian solo cuando Jon puede verlos.
4. **Datos siempre de fuentes abiertas**: OSM para sitios y nombres (hechos del mundo real), Catastro para huellas. Nada de inventar tiendas: si una calle tiene un hueco que OSM no cubre (caso San Antón), se completa a mano solo con nombres verificables y se anota como añadido manual.

---

## 3. Bloques de trabajo

### Bloque 1 — La zona de pinchos: Laurel, San Juan, San Agustín y sus travesías
*Las cuatro callejuelas y sus ~80 bares. Es la zona con más densidad de locales por metro de la ciudad y la más querida.*

- Tratamiento propio de callejuela de bares: toldos continuos en ambas aceras, terrazas estrechas pegadas a la fachada, toneles junto a las puertas (la primitiva `_tonel` ya existe del Calado), carteles pequeños de cada bar (ya corregidos a 0,50 m).
- Los bares con nombre propio de OSM quedan todos con su frente verificado (la ficha dirá cuáles fallan hoy).
- Ambiente: más paseantes en la zona en horas de aperitivo/cena (el sistema de NPC por zonas ya existe), sin pasar el presupuesto de objetos.
- Cierre: paseo en captura por Laurel entera y foto a pie de calle en San Juan.

### Bloque 2 — Los grandes ejes comerciales
*Gran Vía (52), Av. de Portugal (40), República Argentina (24), Pérez Galdós (22), Chile (21), Juan XXIII (20), Calvo Sotelo (18), Club Deportivo (15), La Paz (14), Vara de Rey (11), Marqués de Murrieta (11).*

- Pasada de frentes: verificar escaparate a escaparate que cada local cae en su pared (el error de frentes de locales ya se corrigió una vez; la ficha lo re-audita eje a eje).
- Carácter por eje: marquesinas corridas donde la calle las tiene, bancos-entidad con su color (ya), arbolado de alineación donde OSM lo marca, y **placas con el nombre de la calle en las esquinas** (sistema nuevo, transversal: placa pequeña sobre la fachada de la esquina, como las reales).
- San Antón se completa a mano en este bloque (es eje comercial aunque OSM la infrarrepresente): tiendas verificables una a una, anotadas como añadido manual como se hizo con las 4 primeras.
- Cierre: una captura por eje (11 fotos) + censo.

### Bloque 3 — Parque Rioja y Centro Comercial Berceo: las grandes superficies
*El problema de las losas mudas y los inquilinos invisibles.*

- **Sistema de frente de marca para naves**: sobre la huella real de cada nave, su nombre en letras grandes en la fachada (como los rótulos reales de las naves), puerta de entrada con marquesina, y franja de aparcamiento delante con coches aparcados fundidos (ya existe el sistema de coches fundidos).
- Parque Rioja: Alcampo, Decathlon (reforzar su frente), Leroy Merlin, ALDI, Lupa, Norauto, Burger King, El Corte Inglés Outlet, MercaRioja + tótem de entrada del parque comercial con las marcas (como el real).
- CC Berceo: entrada principal del centro con su nombre, y los inquilinos de OSM (MediaMarkt, Yelmo Cines, Game, Forum Sport, Burger King, ALE-HOP, Carrefour, Foster's…) como frentes sobre la fachada exterior del centro, cada uno con su cartel a la medida nueva.
- Solo frentes y exteriores: **no se modelan interiores de centros comerciales** (fuera de alcance, ver §5).
- Cierre: vista aérea + a pie de calle de ambos centros, censo (los aparcamientos con coches son el riesgo de objetos: todo fundido).

### Bloque 4 — La Ribera completa (absorbe la Tanda 5 de los 50 símbolos)
*El frente del Ebro de punta a punta, como un solo paseo.*

- **Riojaforum a medida**: el palacio con su volumen real (la huella ya está: se le da su piel — el edificio real es una caja singular junto al río), su nombre en la fachada, explanada delante y relación con el parque.
- **Plaza de Toros a medida**: anillo de verdad — muro circular con su altura real, tejado anular, puerta grande y el coso visible desde arriba (albero dentro si el presupuesto lo permite); el entorno con sus cafeterías (Las Huertas y Norte y Sur ya son locales).
- **Parque del Ebro, Parque de La Ribera y Paseo de la Florida** (la Tanda 5 pendiente): caminos, arbolado denso, bancos, el quiosco/elementos que OSM marque en la ficha.
- **Paseo fluvial continuo**: unir Casa de las Ciencias — Riojaforum — Plaza de Toros — Bosque de la Danza — Puerta del Ebro con un tratamiento de orilla coherente (paseo, barandilla donde la hay, arbolado de ribera).
- Cierre: recorrido en capturas de todo el frente del río + sesión pública larga (es la zona con más hitos por baldosa: censo obligado).

### Bloque 5 — Las Gaunas: el estadio y su zona — HECHO (22-nov 21:47)
- **Estadio a medida**: anillo de gradas sobre la huella real, el campo verde con sus franjas dentro, cuatro torres de focos, el nombre «Estadio Las Gaunas» en la fachada y su POI señalado. Desde fuera se tiene que reconocer sin rótulo.
- Entorno: Polideportivo de Las Gaunas con su frente, Parque de Las Gaunas (verde con caminos), aparcamientos de la zona y la Avenida Club Deportivo como calle de llegada (ya está en el Bloque 2 como eje).
- Cierre: foto aérea del estadio (se tiene que ver el campo dentro del anillo) + foto a pie de calle desde Club Deportivo.

### Bloque 6 — Las calles de barrio (el resto de las 195)
*La cola larga: 36 calles con 5–9 locales y 138 con 1–4. Sin este bloque, el juego solo brilla en el centro.*

- Pasada sistemática por tandas de barrios (Cascajos, El Cubo, Madre de Dios, Los Lirios, Yagüe, Valdegastea, La Estrella, Siete Infantes…): la ficha de cada calle y su mínimo de carácter — frente verificado de cada local, toldo/terraza si OSM la marca, y corrección de los huecos que la auditoría encuentre (sitios OSM sin local).
- Las calles sin locales reciben lo que ya existe (portales con número, farolas) y arbolado donde OSM lo marca.
- Cierre por tanda: 3–4 fotos de calles representativas de la tanda + censo.

### Bloque 7 — Detalles transversales de calle
*Lo que hace que una calle se sienta calle en cualquier barrio.*

- **Placas de nombre de calle** en las esquinas (sistema del Bloque 2, extendido a toda la ciudad por proximidad, como los rótulos de locales).
- Contenedores y papeleras donde OSM los marca; paradas de autobús reales con su marquesina en todas las líneas (hoy solo la línea 1 tiene trabajo especial).
- Densidad de coches aparcados y de paseantes por tipo de calle (eje comercial ≠ callejuela ≠ residencial), con los sistemas fundidos actuales.
- Este bloque se reparte: cada tanda de los bloques 1–6 aplica los transversales en sus calles; el Bloque 7 cierra lo que quede.

---

## 4. Orden y estimación

Orden propuesto (impacto para Jon primero: lo que ha pedido ver):

1. **Bloque 4 — La Ribera** (Riojaforum + Plaza de Toros + parques): es lo que Jon ha echado en falta dos veces y cierra los 50 símbolos. ~3 tandas.
2. **Bloque 3 — Grandes superficies** (Parque Rioja + Berceo): lo segundo que ha nombrado (Alcampo, Decathlon). ~2 tandas.
3. **Bloque 5 — Las Gaunas**: lo tercero nombrado. ~1–2 tandas.
4. **Bloque 1 — Zona de pinchos**: el corazón del casco. ~1–2 tandas.
5. **Bloque 2 — Grandes ejes**: el grueso comercial. ~3 tandas.
6. **Bloque 6 — Barrios** + **Bloque 7 — Transversales**: el fondo de armario. ~3–4 tandas.

**Total estimado: 13–16 tandas** publicadas (web + APK) con su verificación completa, al ritmo de las tandas de los 50 símbolos. Cada tanda se anuncia solo cuando está publicada y visible, con sus fotos.

## 5. Fuera de alcance y decisiones

- **Interiores de centros comerciales**: fuera. Solo frentes exteriores y entradas. (Si Jon lo quiere, sería un interior más como los 6 que ya hay — decisión suya.)
- **Escudos y marcas de equipo** en el estadio: el nombre del estadio y su forma, sí; escudos del club, no (no hacen falta para reconocerlo).
- **Nombres de tiendas**: solo los que trae OSM o los verificables a mano (anotados como manuales). Ninguna tienda inventada.
- El plan no toca lo ya cerrado: Fases 0–14, los 50 símbolos (salvo la Tanda 5 absorbida) y los bloques F–I del plan de detalle, que van detrás.
