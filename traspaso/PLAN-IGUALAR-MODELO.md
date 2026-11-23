# Plan para igualar el modelo — «Logroño: El Juego» frente a «Badajoz: El Juego»

**Fecha:** 21 de noviembre de 2026 · **Encargo:** Jon («hazme un plan de todo esto que nos falta»)
**Base:** el análisis de brecha del mismo día (`ANALISIS-BRECHA-BADAJOZ.md`), actualizado con lo ya cerrado en la Fase 5.

---

## 0. Qué significa «igualar»

Paridad de **sistemas y escala de contenido**, con contenido propio: su *cómo* es la referencia; los textos, personajes, coches, circuitos y cromos serán nuestros, creados para Logroño desde las mismas fuentes abiertas (OSM, Catastro, IGN) y de nuestra cosecha. Nada de ficheros, textos ni gráficos del original.

**Ya cerrado (no forma parte de este plan):** ciudad entera con baldosas y streaming (5.5), bucle de encargos con dinero/reloj/guardado, mapa con ruta y recorrido, etiqueta de calle, atardecer y Puente de Piedra, sonido básico de 5 eventos (5.1), controles táctiles (5.2), aceras y recetas de 10 calles (5.3), tráfico circulante básico (5.4).

**Queda fuera, por decisión expresa desde el plan de viabilidad:** el modo **online** (liga, chat, avisos entre jugadores). Es un XL con servidor propio y no se incluye salvo nueva orden. La «Tarjeta VIP» tampoco: es su modelo de negocio, no un sistema de juego.

**Reglas de trabajo (las de siempre):** una fase no empieza hasta cerrar la anterior; cada fase se verifica por el camino real del usuario (capturas, prueba automática y, en web, **navegador real sobre la URL pública** antes de darla por buena) y se cierra con informe y APK nuevo.

**Tamaños:** S = días sueltos · M = una fase normal · L = fase grande · XL = varias fases. Igualar todo es un **programa de meses**, no una fase: este plan lo ordena para que cada cierre deje el juego visiblemente más cerca del modelo.

---

## Fase 6 — El layout del modelo · EN CURSO

La interfaz de la captura que envió Jon: minimapa circular arriba a la derecha (ruta azul, destino naranja, norte arriba; tocarlo abre el mapa grande), pastilla azul con la calle centrada arriba, botón de teléfono con su menú (Encargos, Mapa, Ayuda, Sonido) y bocadillo de pista, píldora blanca de distancia con su X, botón azul de Subir/Bajar, banner oscuro del encargo abajo en el centro y, al conducir en el móvil, volante con flechas y pedales. Iconos dibujados por código.

- **Estado:** código completo; verificación de escritorio 13/13 OK.
- **Cierre:** captura visual del layout a pie y conduciendo, prueba en la web pública en navegador real, republicación y APK.

## Fase 7 — Datos ricos y detalle fino de la ciudad · L

Lo que el Catastro ya descargado en la Fase 1 da y aún no usamos, más el vestido completo.

1. **Viviendas con datos**: puerta exacta (`door_x/door_z` equivalente), año de construcción, m² y número de viviendas por edificio, en el pipeline de ciudad.
2. **Aparcados que respetan puertas**: ningún coche tapando un portal (su regla, con nuestros datos).
3. **Recetas ampliadas**: las ~40 calles con más entidad de Logroño con receta propia (especie, distancia, mobiliario) y plantilla mejorada por clase para el resto de las 557 con nombre.
4. **Marcas viales**: pasos de cebra en cruces, líneas de detención y bordillos con altura (la física distingue la acera).
5. **Ortofoto PNOA como suelo** en plazas y paseos (Espolón, Redonda, Gran Vía…).
6. **Radares**: cabinas reales de Logroño (listados públicos DGT/Ayuntamiento) con aviso al pasar y multa si vas rápido: correr tiene consecuencias.

- **Verificación:** conteos del pipeline contra el Catastro, captura en 3 calles con receta, un aparcado nunca sobre una puerta (muestreo), radar que multa en la prueba automática.

## Fase 8 — Sonido completo · L

De 5 eventos a un banco con cuerpo, todo sintetizado o de fuentes libres:

- Motor con marchas y arranque, bocinas del tráfico, frenada.
- Ambiente por zonas: agua en el Ebro, pájaros en parques, voces y murmullo en el centro, viento.
- Pasos sobre acera y sobre asfalto, puerta del coche, timbre y «ding» de parada.
- **Música**: temas libres (o generados) en menús y al conducir, con volumen en ajustes.
- Mezcla por distancia: lo que suena es lo que tienes cerca.

- **Verificación:** lista de eventos cargados (objetivo ~40), prueba de escucha en captura de vídeo corta o registro de eventos disparados por zona.

## Fase 9 — Vida en la calle · L

1. **Peatones con comportamientos**: sentarse en los bancos y en las plazas, mirar el móvil, hablar en parejas, esperar en las marquesinas. Posturas y gestos procedurales sobre nuestro muñeco de piezas.
2. **Más gente con cabeza**: densidad por zonas (centro y estaciones con más, barrios con menos) con presupuesto de rendimiento.
3. **Perros y pájaros**: perros que pasean con su dueño; pájaros que echan a volar si te acercas (con aleteo en el banco de sonidos).
4. **Personalización del personaje**: elección de colores de ropa y pelo (y 2-3 modelos de camiseta) guardada en la partida.

- **Verificación:** capturas en la Redonda y en una marquesina con comportamientos visibles; conteo de peatones por zona.

## Fase 10 — Vehículos: catálogo, taller y garaje · L

1. **Catálogo propio**: 12 coches inventados en 5 clases (pequeño, familiar, clásico, deportivo, furgoneta), cada uno con velocidad, aceleración, frenada, agarre, peso y precio propios. Modelos por código, como el actual, con más detalle.
2. **Economía del coche**: concesionario (comprar), reventa, **taller** (reparar y mejorar frenos/motor), **garaje** con tus coches.
3. **La furgoneta** como vehículo de trabajo (la usa la Fase 12).
4. El tráfico y los aparcados usan también el catálogo (variedad en la calle).

- **Verificación:** comprar, vender y reparar en la prueba automática; dos coches con física distinta medidos en el mismo tramo.

## Fase 11 — Interiores · L

1. **Tu piso** en Miguel Villanueva 1: salón, cocina, dormitorio; tu cama guarda la partida durmiendo (salto de hora).
2. **Ayuntamiento**: entrar, y su función de juego: **desbloquea la bolsa de empleo** (los trabajos especiales de la Fase 12 no existen hasta pasar por él, como en el modelo).
3. **Tres locales con función**: gimnasio, peluquería (cambia el pelo de la Fase 9) y tienda de ropa (cambia la ropa), más la panadería como destino con interior simple.
4. Sistema de puertas: entrar/salir sin pantallas de carga, interior como escena ligera por local.

- **Verificación:** entrar y salir de los 4 interiores en captura; el desbloqueo del Ayuntamiento probado con partida nueva.

## Fase 12 — Trabajos especiales · L

Con los datos que ya extrajimos en la Fase 1 (10 líneas diurnas + 3 búho, 254 paradas):

1. **Autobús**: la línea 1 completa — recorrido real, paradas con pasajeros que suben y bajan, timbre, puntuación del servicio y paga por línea cumplida. Después, el resto de líneas es montaje.
2. **Reparto con furgoneta**: paquetes por barrios con la furgoneta de la Fase 10, capacidad de carga como límite.
3. **Camalote**: limpiar el Ebro en su tramo urbano — objetos flotantes que recoge tu barca/vehículo, con la corriente empujando.
4. **Gimnasio**: el trabajo del interior de la Fase 11 (sesiones con clientes).

- **Verificación:** una línea de autobús completa en la prueba automática (paradas y cobro), un reparto con furgoneta y una limpieza de camalote completadas.

## Fase 13 — Historia y encuentros · XL (en dos cierres)

Contenido propio, escrito para Logroño:

1. **Sistema de diálogos** con retratos dibujados por código y fichas de personaje.
2. **Cierre 13A — arranque**: 3 capítulos, ~12 misiones, 5 personajes fijos (tu casera, el del bar, un compañero de encargos…): llegar a la ciudad, el piso, el padrón en el Ayuntamiento, los primeros trabajos.
3. **Cierre 13B — historia completa**: hasta 9 capítulos y ~42 misiones, desbloqueo por zonas de la ciudad.
4. **Encuentros por la calle**: con los personajes ya creados, escenas breves según barrio, hora y temporada, con tiempos de reutilización (su sistema, con nuestras escenas).

- **Verificación:** cada capítulo jugable de principio a fin en la prueba automática por tramos; lista de misiones con su capítulo y personaje.

## Fase 14 — Carreras · L

1. **Circuitos desde nuestro grafo**: 15 circuitos al principio (por barrios), creciendo hasta ~75 con el generador de circuitos.
2. **Modos**: contrarreloj con **coche fantasma** (tu mejor vuelta y la de la medalla), carrera contra rivales con nombre y manías, puntos de control y suavidad/eco.
3. **Clases y liga**: por clase de coche (Fase 10), con clasificación guardada.

- **Verificación:** un circuito completo en cada modo en la prueba automática; el fantasma se graba y se reproduce.

## Fase 15 — Mapa avanzado, colecciones y buzón · M

1. **Lugares completos**: los POI de OSM por tipos (~120 categorías) en el pipeline de ciudad.
2. **Mapa con filtros y buscador**: filtrar por categoría (tiendas, trabajo, carreras, radares…) y buscar una calle por su nombre y volar a ella.
3. **Colecciones propias**: 48 cromos de Logroño en 6 páginas escondidos por la ciudad (algunos «solo en sitios difíciles»), nidos y fotos.
4. **Buzón**: mensajes del juego (avisos de historia, de trabajos y de colecciones) en el teléfono.

- **Verificación:** buscar «Calle Portales» en el mapa y filtrar por gimnasios; recoger 3 cromos y verlos en su página.

## Fase 16 — Presentación y pulido · M

1. **Pantallas de carga** con vistas de Logroño (nuestras capturas del juego: el Espolón, el Puente de Piedra, el Ebro).
2. **Menús completos**: Qué hacer / Mis cosas / Ajustes, en el teléfono y en pausa.
3. **Ajustes**: volúmenes por canal, cámara con giroscopio en el móvil (opcional), calidad gráfica.
4. **Recetas de temporada**: vestido de Navidad en las calles principales (nuestra receta, como la suya de concepto).
5. **Medición de rendimiento por zonas** con presupuestos (triángulos y llamadas por plaza), para que la ciudad entera siga yendo fluida en el móvil.

- **Verificación:** recorrido de menús completo en captura; tabla de rendimiento de 6 zonas dentro de presupuesto.

---

## Orden y dependencias (resumen)

| Orden | Fase | Tamaño | Depende de |
|---|---|---|---|
| 1 | 6 · Layout del modelo | En curso | — |
| 2 | 7 · Datos ricos y detalle de ciudad | L | — |
| 3 | 8 · Sonido completo | L | — (independiente) |
| 4 | 9 · Vida en la calle | L | Mobiliario (ya) |
| 5 | 10 · Vehículos y taller | L | Economía (ya) |
| 6 | 11 · Interiores | L | — |
| 7 | 12 · Trabajos especiales | L | 10 (furgoneta), 11 (Ayuntamiento y gimnasio) |
| 8 | 13 · Historia y encuentros | XL | 11 (parcial), 12 (parcial) |
| 9 | 14 · Carreras | L | 10 (clases de coche) |
| 10 | 15 · Mapa avanzado y colecciones | M | 7 (POI por tipos, parcial) |
| 11 | 16 · Presentación y pulido | M | Todo lo anterior |

El orden no es caprichoso: los datos ricos (7) alimentan encargos a puertas e interiores; los vehículos (10) alimentan carreras y reparto; los interiores (11) alimentan la historia y dos trabajos. El sonido (8) va pronto porque es independiente y es lo que más «sensación de juego acabado» da por esfuerzo.

## Decisiones que quedan en tu mano

1. **¿Este orden o otra prioridad?** (Por ejemplo: historia y carreras antes que detalle de ciudad.)
2. **Historia**: ¿arrancamos con 3 capítulos y luego completamos, o la escribimos entera de una vez en su fase?
3. **Online**: se mantiene fuera, como acordamos. Si algún día lo quieres, es un proyecto aparte.
