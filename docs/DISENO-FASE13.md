# Fase 13 — Historia y encuentros (diseño)

Cierre 13A (el plan prevé dos cierres: 13A con 3 capítulos y 13B hasta 9;
la decisión de Jon sobre si la historia va en dos cierres o entera sigue
pendiente, así que este cierre deja la puerta abierta a continuar).

## Sistema de diálogos

- Panel inferior ancho (estilo de los demás paneles): nombre del personaje
  en ámbar, texto de la línea, botón «Seguir» (y en su caso dos opciones).
- Una conversación = lista de líneas {quién, texto}; al agotarla se cierra
  y se ejecuta la acción asociada (fijar objetivo, cobrar, avanzar misión).
- El mundo se congela mientras el panel está abierto (como los demás
  paneles). Se abre con E o con el botón azul («Hablar con …») cerca del
  personaje, y se avanza con el botón, con E o con Espacio/Intro.
- Textos propios, inventados para Logroño (clean-room: ni nombres ni
  frases del juego original).

## Personajes fijos (5)

Cada uno: figura propia (colores fijos, sin detalle facial), rótulo fijo
con su nombre sobre la cabeza (5 Label3D: asumible en el presupuesto web),
punto fijo en la ciudad y rol en la historia.

| Personaje | Dónde | Rol |
|---|---|---|
| Carmen, la casera | Miguel Villanueva, junto a tu piso | Te recibe, te encarga recados del barrio |
| Paco, el mecánico | Taller Ebro (centro) | Coches, piezas y un favor con la furgoneta |
| Lucía, la librera | Calle Portales | Libros, encargos culturales, la fiesta |
| Elías, el jubilado | Paseo del Espolón (banco) | Memoria del barrio, paseos y el río |
| Marta, la conductora | Estación de Autobuses | La línea 1 y el día grande de San Mateo |

## Estructura

- Progresión lineal guardada en partida.cfg: `historia_idx` (siguiente
  misión, 0..12) — al completar las 12, la historia 13A queda «hecha» y
  los personajes siguen en su sitio con una línea de saludo.
- Una misión = hablar con el personaje (diálogo) → objetivo con pilar y
  banda (ir a un lugar, llevar algo, recoger y traer, acompañar) →
  volver/hablar o llegar → diálogo de cierre → cobro → siguiente misión.
- Estado propio `_hist` (misión activa y paso); no se mezcla con encargos
  ni con trabajos especiales: si llevas algo entre manos, el personaje te
  dice que lo termines primero (y al revés: con misión de historia activa,
  el panel de encargos avisa).
- La banda usa el mismo sistema de objetivo (`_fijar_objetivo`,
  `_objetivo_texto`) con prefijo «Historia ·».

## Capítulos 13A (12 misiones)

**Capítulo 1 · Recién llegado** (Carmen y el barrio)
1. «La casera» — Carmen te da la bienvenida en tu portal y te pide bajar
   a la panadería a por pan (usa la panadería real). Recompensa 10 €.
2. «El banco del Espolón» — Elías te espera en su banco: acompáñale
   (llega con él al Parque del Ebro charlando). 12 €.
3. «Un libro para Carmen» — Lucía te vende el libro en Portales y se lo
   llevas a Carmen. 15 €.
4. «El coche suena raro» — Paco revisa tu Rioja en el Taller Ebro
   (llega en coche). 0 €, pero repara el daño del coche activo a 0.

**Capítulo 2 · Gente de Logroño**
5. «La conductora» — Marta, en la Estación de Autobuses, te cuenta la
   línea 1 y te pide que le lleves un termo a la terminal del Hospital
   (en coche o en bus). 18 €.
6. «Fotos del Ebro» — Elías quiere ver el Puente de Sagasta: llévale en
   coche (llega al puente con el coche). 20 €.
7. «La furgoneta de Paco» — Paco te presta el encargo: recoge un paquete
   en el taller y entrégalo en Varea (portal). 25 €.
8. «Cierre de la librería» — Ayuda a Lucía a llevar cajas de Portales al
   Mercado de San Blas. 22 €.

**Capítulo 3 · San Mateo**
9. «Pregón» — Carmen te manda a la Plaza del Ayuntamiento a la hora del
   pregón (llega a la plaza). 20 €.
10. «Vino para la fiesta» — Compra en la tienda de Gran Vía (acción ropa
    no: se simula recogida en la puerta) y llévalo al Espolón. 26 €.
11. «El día grande de Marta» — Completa la recogida: lleva a Marta desde
    la Estación hasta la Plaza de Toros. 30 €.
12. «Fuegos en el Ebro» — Cierre: llega al Parque del Ebro al anochecer
    (llegar basta; diálogo final con todos en el banco de Elías). 40 €.

(Total historia 13A: 238 € + reparación. Los objetivos «llevar a alguien»
se resuelven como llegar al destino tras hablar: el acompañante «va
contigo» sin física propia — decisión consciente para no arriesgar el
presupuesto web ni la estabilidad; el diálogo lo cubre.)

## Encuentros por la calle

- Cada 150–260 s de juego libre a pie (sin objetivo de historia/trabajo),
  un peatón cercano puede pararte: suena `aviso`, aparece el diálogo de
  encuentro con un desconocido (nombre inventado al azar de una lista) y
  DOS opciones: ayudar (cuesta 20–40 s de juego o 0 €, paga 5–15 € o las
  gracias) o pasar de largo (sin efecto). Sin castigos.
- 6 textos de encuentro rotativos (turista perdido → la Redonda; señora
  con bolsas → portal cercano; niño que perdió el balón → parque; etc.).
  En la práctica: la opción «ayudar» fija un objetivo corto (100–400 m) y
  al llegar paga; «pasar» cierra sin más.
- Solo a pie y fuera de interiores; enfriamiento tras cada encuentro.

## Verificación

- `probar_historia`: recorre las 12 misiones con las funciones reales
  (hablar → teletransporte al objetivo → llegada → cierre) y exige
  HISTORIA_OK misiones=12 cobro=238.
- Regresiones: verificar, prueba, probar_bus, probar_coches,
  probar_interiores.
- Capturas: `capturar_historia` (diálogo con Carmen abierto),
  `capturar_encuentro` (diálogo de encuentro con opciones).
- Censo antes de publicar (los 5 personajes son 6 piezas fundidas cada
  uno + 5 rótulos: +35 objetos aprox., dentro de presupuesto).
- Prueba ácida web larga + publicación + sesión larga en URL pública.
