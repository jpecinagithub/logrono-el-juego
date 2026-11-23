# Fase 14 — Carreras (diseño)

## Qué se construye

Carreras por las calles reales de Logroño, sobre el grafo viario que ya
usa el juego. Dos modos por circuito: **contrarreloj** (con fantasma de
tu mejor vuelta) y **contra rivales** (3 coches con piloto automático).
Panel «Carreras» en el teléfono, con los circuitos, tu mejor tiempo y
las medallas. Todo inventado (nombres de circuitos propios).

## Circuitos (puntos de control sobre lugares reales)

| # | Circuito | Puntos de control | Clase sugerida |
|---|---|---|---|
| 1 | Sprint del centro | Garaje → Portales → Ayuntamiento → Espolón → Garaje | cualquiera |
| 2 | Los tres puentes | Puente de Piedra → Puente de Hierro → Puente de Sagasta → Parque del Ebro → Puente de Piedra | cualquiera |
| 3 | Varea Express | Garaje → Varea → Hospital → Garaje | Familiar |
| 4 | El anillo de Logroño | Espolón → Estación → Plaza de Toros → Ayuntamiento → La Redonda → Espolón | Deportivo |

- El punto de control se supera pasando a menos de 15 m con el coche.
- La ruta entre puntos es libre; el minimapa dibuja la ruta A* hasta el
  siguiente punto (el sistema que ya usan los encargos) y la banda
  muestra «Carrera · CP 3/5 · 01:23».
- Tiempos objetivo (oro/plata/bronce) por circuito, ajustados con los
  tiempos que mida la prueba automática.

## Flujo

1. Teléfono → «Carreras» → eliges circuito y modo. Sin encargos,
   trabajos, historia ni encuentros activos (y al revés: durante la
   carrera no se puede aceptar otra cosa).
2. Tu coche y tú aparecéis en la salida. Cuenta atrás 3-2-1 con pitidos
   (el coche no se mueve) y «¡Ya!».
3. Pasas los puntos en orden (ding en cada uno). Al cruzar la meta:
   panel de resultados con tu tiempo, medalla o posición y el premio.
4. La × de la pastilla abandona la carrera sin premio.

## Rivales

- 3 coches del catálogo (mallas fundidas, colores propios) que siguen
  la polilínea A* entre puntos con el mismo piloto de arco que el
  autobús (mirada adelantada, frenada en curva). Cada rival corre a un
  porcentaje distinto del ritmo de su clase (82–95 %): ganables con un
  coche de la clase del circuito, duros con uno inferior.
- Sin colisión coche-coche (como el resto del juego); son competencia
  visual y de tiempos. Su tiempo de llegada se registra al cruzar meta.

## Fantasma

- En contrarreloj se graba tu mejor vuelta (posición y rumbo cada
  0,5 s) y se guarda con la partida. En las siguientes contrarreloj de
  ese circuito, un coche translúcido cian repite tu mejor vuelta.
- Premios contrarreloj por medalla: oro 50 €, plata 30 €, bronce 15 €.
  Rivales: 1.º 60 €, 2.º 30 €, 3.º 15 €, 4.º 5 €.

## Guardado

`carreras` en partida.cfg (JSON): por circuito, mejor tiempo y la
grabación del fantasma. Los récords sobreviven entre sesiones.

## Verificación

- `probar_carreras`: contrarreloj del circuito 1 con piloto automático
  (el mismo seguidor de ruta que los rivales, aplicado a tu coche) y
  carrera de rivales del circuito 1: exige que la carrera termine, que
  se guarde el récord y CARRERAS_PRUEBA_OK.
- Capturas: `capturar_carrera` (parrilla de salida con los rivales) y
  `capturar_carrera2` (en marcha, con un rival delante).
- Regresiones, censo (los rivales solo existen durante la carrera:
  3 coches fundidos = 3 objetos), prueba ácida web y URL pública.
