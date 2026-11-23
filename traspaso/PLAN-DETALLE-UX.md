# Plan de detalle y experiencia de usuario — «Logroño: El Juego»

**Fecha:** 22 de noviembre de 2026 · **Encargo:** Jon («quiero alcanzar el grado
de detalle del juego de Badajoz antes de añadir más capas, más datos y más
complicación; las Fases 15, 16 y el multijugador quedan para más tarde»).

**Punto de partida honesto.** En sistemas ya estamos cerca del modelo:
ciudad entera con baldosas, tráfico, sonido, interiores, historia,
carreras, autobús, recetas de calles, radares, encuentros. La distancia que
queda no es de *sistemas* sino de **acabado dentro de cada sistema**: el
original viste calle a calle con recetas escritas, sus edificios tienen
puerta y datos, sus personas tienen clips con la pisada sincronizada, su
banco de sonidos tiene 106 eventos. Lo nuestro funciona todo, pero se ve y
se siente más «maqueta». Este plan ataca eso, bloque a bloque, sin añadir
ningún sistema nuevo.

**Regla que manda en todos los bloques** (lección de la Fase 14): en la
versión web, todo lo que se repita en masa va fundido en mallas de colores
de vértice o limitado por proximidad, con censo de objetos antes de
publicar y partida larga en la URL pública. El detalle que no quepa en
ese presupuesto no entra, por bonito que sea en escritorio.

---

## Bloque G — Guía y llegada (la frustración nº 1)

**Qué:** que la ruta de un encargo termine en la puerta de verdad: los
últimos ~100 m se calculan caminando por el espacio transitable (no en
línea recta a través de la manzana), con marcador de llegada visible
desde lejos (columna de luz suave) y, cuando la entrada sea por otra
calle, aviso en la banda («entrada por Calle X»). Incluye lo aprendido
hoy: portales encerrados fuera de los encargos (432 excluidos) y el
minimapa que sigue al vehículo.

- **Pro:** elimina el peor momento del juego actual —estar a 15 m del
  objetivo y no poder llegar—, que Jon vivió hoy en San Bernabé.
- **Pro:** beneficia a *todos* los encargos, historias y repartos, no a
  un rincón.
- **Contra:** hay que calcular un camino fino a pie al aceptar cada
  encargo (coste puntual, asumible) y mantenerlo si el jugador se desvía.
- **Tamaño:** M. **Es el bloque que más «experiencia de usuario» compra.**

## Bloque A — Fachadas con vida

**Qué:** los edificios dejan de ser cajas con textura: ventanas con marco
y cristal (algunas encendidas al anochecer), balcones con barandilla,
persianas, aparatos de aire acondicionado, cornisa y zócalo, tejados
inclinados en el casco antiguo y planos fuera, y puerta de portal visible
con su número en los edificios con portal jugable. Todo fundido en la
malla de cada baldosa, por colores de vértice, como ya hacemos.

- **Pro:** es el 70 % de lo que la vista toca en una calle; es donde el
  original más se separa hoy de nosotros («edificios herméticos» fue la
  queja de Jon el 21-nov).
- **Pro:** no toca jugabilidad: cero riesgo de romper encargos o carreras.
- **Contra:** más triángulos por edificio en las 76 baldosas; el censo
  web puede obligar a bajar densidad en zonas cargadas.
- **Contra:** rehacer el generador de edificios toca *toda* la ciudad:
  la verificación visual es larga.
- **Tamaño:** L.

## Bloque B — La calle al detalle (recetas v2)

**Qué:** llevar las recetas de las 26 calles actuales a las calles con
nombre de toda la ciudad, con lo que distingue al original: especie de
árbol con paleta propia por calle (plátano, magnolio, tilo…), bancos de
hierro o de madera según la calle, farolas de época en el casco y
modernas fuera, papeleras, bolardos, jardineras, marquesina en las
paradas reales del autobús, placa con el nombre en las esquinas y pasos
de cebra con su rebaje de acera.

- **Pro:** es la firma del original: cada calle se reconoce sin mirar el
  nombre; cada barrio gana identidad.
- **Pro:** se genera por reglas desde los datos que ya tenemos (OSM trae
  especies en parte de los árboles y todas las paradas).
- **Contra:** trabajo calle a calle en los datos; las calles secundarias
  seguirán con vestido genérico (como en el original: sus recetas
  detalladas también son las calles con nombre).
- **Contra:** más mobiliario = más presión sobre el presupuesto web;
  todo fundido por baldosa, sin excepciones.
- **Tamaño:** L.

## Bloque F — Sonido con cuerpo

**Qué:** del banco procedural de 24 eventos a uno con presencia: motor
con marchas y tono por coche, ambiente por zonas (pájaros en los parques,
agua en el Ebro, bullicio en Gran Vía y el Espolón, campanas de la
Concatedral e San Bartolomé a su hora), pasos que suenan distinto sobre
adoquín, asfalto y hierba, y la pisada sincronizada con el paso al andar.

- **Pro:** el análisis de brecha ya lo decía: el oído perdona gráficos
  modestos; es el mayor salto de «sensación de juego acabado» por
  esfuerzo invertido.
- **Pro:** independiente de todo lo demás; se puede hacer en cualquier
  momento sin tocar la ciudad.
- **Contra:** el sonido procedural convincente lleva iteración fina;
  un bucle malo se nota más que el silencio.
- **Tamaño:** M.

## Bloque D — Coches que se sienten distintos

**Qué:** física por coche del catálogo (peso que se nota en las cuestas,
agarre, frenada, giro), faros que iluminan de noche y pilotos, color y
modelo variados en los aparcados usando el propio catálogo, daño con
reflejo visual leve (abolladura = panel oscurecido) y sonido de motor
propio por clase.

- **Pro:** conducir es el verbo principal del juego; hoy los 12 coches
  se distinguen en la ficha y poco al volante.
- **Pro:** da sentido a ahorrar para un coche mejor: se *nota*.
- **Contra:** cambiar la física obliga a recalibrar las medallas de los
  4 circuitos y a repetir la prueba de carreras entera.
- **Contra:** los faros con luz real son luces dinámicas: en web hay que
  limitarlas al coche del jugador y a unos pocos cercanos.
- **Tamaño:** M.

## Bloque C — Suelo y aceras de verdad

**Qué:** bordillo con altura real que el coche nota al subir (el
parámetro `kerb` del original), pavimento por zonas —adoquín en el casco
antiguo, baldosa en el centro, asfalto fuera—, tapas de alcantarilla y
rejillas en la calzada, y la ortofoto del PNOA **solo** en plazas y
paseos (Espolón, Parque del Ebro, Plaza del Ayuntamiento) como prueba
acotada, no en toda la ciudad.

- **Pro:** el suelo es la otra mitad de lo que se ve conduciendo; el
  bordillo cambia la sensación al aparcar y al subir a la acera.
- **Pro:** la ortofoto en plazas da la foto «esto es Logroño» sin el
  riesgo de la doble imagen en calles con edificios.
- **Contra:** el bordillo físico toca la conducción (colisiones y
  alturas): hay que re-verificar puentes, pasos y el autobús.
- **Contra:** la ortofoto, incluso acotada, exige trocear y servir
  imágenes pesadas en web.
- **Tamaño:** M (L si la ortofoto se extiende).

## Bloque E — Personas con presencia

**Qué:** más variedad de cuerpos y ropa (paletas amplias, gorras,
bolsos, paraguas cuando el cielo está encapotado), andar con balanceo de
cadera y paso sonoro, y comportamientos con lo que ya existe: parejas que
hablan, gente esperando en la parada cuando el bus se acerca, pasear al
perro con correa, densidad por zona y hora (Espolón lleno un domingo a
mediodía, calles vacías a las 4 de la mañana).

- **Pro:** la ciudad pasa de decorada a habitada; es lo que más se
  agradece paseando a pie.
- **Contra:** las figuras seguirán siendo fundidas y de pocos polígonos:
  la mejora es de variedad y movimiento, no de realismo facial.
- **Contra:** más densidad en zonas de fiesta choca con el presupuesto
  web si no se limita por proximidad como los rótulos.
- **Tamaño:** M.

## Bloque H — Luz y atmósfera

**Qué:** ventanas que se van encendiendo al anochecer (segunda piel
nocturna ligera sobre las fachadas del Bloque A), farolas con halo,
reflejo del atardecer en el Ebro, niebla suave algunos amaneceres y
cielo con nubes que se mueven.

- **Pro:** Logroño se reconoce por su luz; el atardecer ya es nuestra
  firma y esto lo completa.
- **Contra:** depende del Bloque A (sin ventanas no hay nada que
  encender) y cualquier cambio de luz obliga a re-ver capturas de toda
  la ciudad.
- **Tamaño:** S–M.

## Bloque I — Interiores con detalle

**Qué:** los 6 interiores dejan de ser salas de cajas: muebles con forma
(sofá con cojines, encimera con fogones, cama con colcha), dependientas
y vecinos dentro con su frase, la tele del piso con el mapa de Logroño,
y escaparate con interior simplificado visible desde la calle en los
locales de las calles principales.

- **Pro:** entrar en sitios es de lo que más «mundo real» da; tu piso
  gana sentido como casa.
- **Contra:** es artesanía sitio a sitio: el beneficio se concentra en
  6 lugares y unas pocas calles.
- **Tamaño:** M.

---

## Orden recomendado

1. **G — Guía y llegada** (la frustración que Jon ya ha sufrido).
2. **A — Fachadas** (lo que más se ve).
3. **B — Calles al detalle** (la firma del original).
4. **F — Sonido** (sensación de acabado, independiente).
5. **D — Coches** (el verbo principal).
6. **C — Suelo y bordillos**.
7. **E — Personas**.
8. **H — Luz** (tras A).
9. **I — Interiores**.

Cada bloque se cierra como las fases anteriores: capturas por el camino
real, censo de objetos, partida larga en la URL pública y APK nuevo.

## Lo que este plan NO hace (a propósito)

- Ni Fases 15/16, ni multijugador, ni historia 13B: quedan aparcados por
  orden de Jon hasta que el detalle esté a la altura.
- Ni más encargos, ni más circuitos, ni más coches: contenido no falta;
  falta acabado.
- **Aviso honesto:** pulir no alarga el juego; lo hace mejor de jugar.
  Cuando el detalle esté, las capas aparcadas caerán sobre una base que
  ya se siente «de verdad».
