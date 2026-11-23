# Diseño Fase 10 — Vehículos: catálogo, taller y garaje

## Catálogo (12 coches inventados, 5 clases)
Cada entrada: nombre, clase, vmax (m/s), acel (m/s²), freno, giro, precio, color, dims, estilo.
- Pequeño: «Rioja» (el inicial, ya en propiedad), «Ebro»
- Familiar: «Cantabria», «San Mateo»
- Clásico: «Bretón», «Murallas»
- Deportivo: «Valbuena», «Fardachón»
- Furgoneta: «Portales» (la de trabajo de la Fase 12), «Logroño Cargo»
(12 = ajustar la lista final al escribir el código; nombres de calles/lugares de Logroño.)

## Física por coche (sustituye a las constantes de _conducir)
- acel 9.0 → coche.acel; tope 16 → coche.vmax; marcha atrás −vmax·0,35.
- Daño 0–100: un choque de frente (vel→0) suma daño; el rendimiento cae
  hasta −30 % con el daño al máximo. El motor suena peor con daño (pitch).
- Mejoras por coche: motor (3 niveles, +10 % vmax/acel) y frenos (3 niveles).

## Economía y lugares (paneles con el lenguaje visual del juego)
- Concesionario «AutoRioja»: catálogo con fichas y precios; comprar suma
  el coche al garaje.
- Garaje (en casa, Miguel Villanueva): Usar / Vender (70 %; nunca el último).
- Taller «Ebro»: reparar (precio por punto de daño), mejorar motor/frenos.
- Propiedad guardada en partida.cfg (JSON): lista de coches con color,
  daño y mejoras + índice del activo. Partidas viejas: se regala el «Rioja».

## Modelos con más detalle
_modelo_coche(color, estilo): proporciones por clase (la furgoneta alta y
larga, el deportivo bajo con alerón, el clásico con cabina corta) + faros,
parachoques y retrovisores en cajas. Los aparcados fundidos (_coche_en)
varían dims por clase; el tráfico elige modelo del catálogo al azar.

## Verificación (la del plan)
probar_coches: comprar, cambiar el activo, medir el mismo tramo con dos
coches (el deportivo llega antes), chocar y reparar, vender. COCHES_OK.
