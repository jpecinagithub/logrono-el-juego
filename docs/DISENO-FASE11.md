# Diseño Fase 11 — Interiores (2026-11-21)

Plan aprobado (PLAN-IGUALAR-MODELO.md): tu piso, Ayuntamiento (desbloquea la
bolsa de trabajos especiales de la Fase 12), gimnasio, peluquería, tienda de
ropa y panadería; puertas sin pantallas de carga; escenas ligeras.

## Técnica

- Los interiores viven FUERA de la ventana de la ciudad, en una fila de
  salas en x = 4000 + i·40, z = 5000, suelo plano a y = 0. Así sus muros
  (colisión 2D global) nunca bloquean calles reales.
- `_en_interior` (id de la sala o ""): mientras esté activo, `_altura()`
  devuelve la altura del suelo interior (0) y el jugador se mueve con las
  reglas normales (`_mover`, `_choca`) contra los muros registrados.
- Cada sala: suelo propio, paredes de cajas con hueco de puerta, muebles de
  cajas, todo fundido en UNA malla por sala (lección web: nada de nodos en
  masa). Sin techo: entra la luz del sol y se ve el cielo.
- Puertas: punto exterior (portal/pilar + rótulo, como los lugares de la
  Fase 10) y punto interior de salida. El botón de acción gana los modos
  `puerta:<id>` (fuera) y `salir` (dentro), más interacciones de sala
  (`dormir`, `pelo`, `ropa`, `pan`) cuando el jugador está junto al mueble.
- Al entrar se guarda el punto exterior exacto para salir al mismo sitio.
  El coche se queda fuera. El minimapa muestra el ancla exterior mientras
  se está dentro (datos congelados en la puerta).

## Las seis salas

1. **Tu piso** (Miguel Villanueva 1, junto al garaje): salón con sofá, tele
   y mesa; cocina con encimera; dormitorio con **cama: dormir** lleva el
   reloj a las 08:00 del día siguiente (día + 1) y guarda la partida.
2. **Ayuntamiento** (POI real en (261, 64)): vestíbulo con mostrador. La
   primera entrada pone `_empleo_desbloqueado = true` (se guarda) y avisa
   «Ya puedes aceptar trabajos especiales». Sin esto, la Fase 12 no
   ofrecerá autobús/furgoneta/camalote/gimnasio.
3. **Gimnasio** (Av. de la Paz): máquinas y colchonetas. Será el lugar del
   trabajo de la Fase 12; en la 11 basta entrar y salir.
4. **Peluquería** (Calle Portales): sillones y espejos. Interacción
   «Cambiar de pelo»: cicla el color de pelo (como en el teléfono).
5. **Tienda de ropa** (Gran Vía): percheros. Interacción «Cambiar
   camiseta»: cicla el color de camiseta (como en el teléfono).
6. **Panadería** (Calle San Antón): mostrador con pan. Interacción
   «Comprar pan»: −2 € y aviso. Será destino de encargos con interior.

## Verificación

- Modo `probar_interiores`: con la bandera de empleo a falso, entra y sale
  de las 6 salas por las funciones reales de puerta; comprueba el
  desbloqueo del Ayuntamiento, que dormir avanza día y reloj a las 08:00,
  y que pelo/ropa cambian. Imprime INTERIORES_PRUEBA_OK.
- Capturas: el piso (salón), el Ayuntamiento y la peluquería.
- verificar gana INTERIORES_OK salas=6; prueba de encargos sin regresión;
  web en la URL pública y APK nuevos al cerrar.
