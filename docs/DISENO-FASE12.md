# Fase 12 — Trabajos especiales (diseño)

Datos: `pipeline/linea_bus.py 1` extrae del PBF la línea 1 real (AULOSA)
con la conversión de `pipeline/ciudad.py` → `juego/datos/linea1.json`:
2 sentidos, 22/21 paradas con nombre real; dentro de la ventana del
juego quedan 15 (Hospital → Clínica Valvanera) y 14 (vuelta).

## Puerta de acceso
Todos los trabajos especiales exigen `_empleo_desbloqueado` (primera
visita al Ayuntamiento, Fase 11). Nuevo botón del teléfono: «Trabajos
especiales». Sin desbloquear, el panel lo dice («Pásate por el
Ayuntamiento») y no deja aceptar nada.

## 1. Autobús — Línea 1
- Al aceptar, eliges sentido (Hospital→Lardero o Lardero→Hospital);
  solo se sirven las paradas dentro de la ciudad (15 o 14).
- El autobús aparece en la primera parada: modelo propio de piezas
  (es UN vehículo: carrocería de 11 m, banda de ventanillas, ruedas,
  rótulo «1»); tu coche queda aparcado donde estaba.
- Conduces tú. El banner muestra: «Línea 1 · Parada k/N: <nombre> ·
  a XXX m · Pasajeros: P». Al llegar a menos de 14 m de la parada y
  parar del todo: timbre, 2,5 s de puertas, suben 0–4 y bajan los que
  toquen (azar con semilla por parada), sonido de puerta.
- Si te pasas una parada más de 25 m sin parar, cuenta como saltada.
- Al completar la última: cobro = 25 € + 2 €/parada servida +
  0,5 €/pasajero transportado; el autobús se queda aparcado y tú a pie.
- Prueba automática `probar_bus`: recorre un sentido entero con el
  piloto automático siguiendo la polilínea de la ruta real y exige
  BUS_OK (todas las paradas servidas y cobro > 0).

## 2. Reparto con furgoneta
- Exige que tu coche activo sea de clase Furgoneta (si no, aviso:
  cómprala en AutoRioja o cámbiala en el garaje).
- Carga: 5 paquetes en tu garaje (casa). Entregas en 5 destinos
  (portales/lugares) en el orden que quieras; al llegar a menos de
  6 m en la furgoneta, entrega automática con sonido de papel.
- Cobro: 10 € + 4 €/paquete + 1 €/100 m de ruta. Banner con
  «Paquetes: quedan k · siguiente a XXX m» (el más cercano).
- Prueba `probar_furgo`: carga y entrega los 5 con piloto automático.

## 3. Camalote en el Ebro
- Al aceptar, aparecen 12 masas flotantes (mallas fundidas, una por
  masa) derivando despacio (0,4 m/s) por el cauce urbano siguiendo
  `rio.json`, con balanceo; al salir por el este reaparecen al oeste.
- Se retiran a pie: acercarse a menos de 3,5 m y pulsar E (o el botón
  de acción): sonido de chapoteo (paso_hierba) y +1.
- Meta: retirar 8 → cobro 30 €. Solo existen durante el trabajo
  (presupuesto de objetos web).
- Prueba `probar_camalote`: teletransporte de test a cada masa y
  retirada por la función real hasta completar.

## 4. Gimnasio
- Usa el interior del gimnasio (Fase 11). Al aceptar y entrar, hay
  4 estaciones en orden (cinta, banco de press, pesas, esterilla) con
  un cliente en cada una: quédate dentro del círculo marcado 4 s
  «supervisando» (el banner lleva la cuenta) y pasa a la siguiente.
- Las posiciones de las estaciones se guardan al crear el interior
  (`_interiores["gimnasio"]["estaciones"]`).
- Cobro: 20 € al completar las 4. Prueba `probar_gimnasio` por las
  funciones reales de estación.

## Común
- Un solo trabajo especial a la vez; convive con los encargos normales
  (si hay encargo activo, el panel avisa y no deja mezclar).
- Botón «×» del banner cancela también el trabajo especial.
- Todo lo nuevo que se repita va fundido (masas del río) y el censo de
  objetos se repite antes de publicar.
