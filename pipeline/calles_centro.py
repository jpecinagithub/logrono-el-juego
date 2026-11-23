#!/usr/bin/env python3
"""Calles del barrio piloto desde OSM, en las mismas coordenadas locales
(metros, origen = centro de la ventana) que edificios.json.
Salida: datos/procesado/barrio_centro/calles.json + copia en juego/datos/.
"""
import json, math
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
LON0, LON1, LAT0, LAT1 = -2.4535, -2.4320, 42.4615, 42.4725

ANCHOS = {  # metros según clase OSM
    "motorway": 13, "trunk": 12, "primary": 11, "secondary": 10,
    "tertiary": 9, "unclassified": 7, "residential": 7,
    "living_street": 6, "pedestrian": 6, "service": 4.5,
    "footway": 2.5, "path": 2.5, "cycleway": 2.5, "steps": 2.5,
}

def utm(lon, lat):
    a = 6378137.0; f = 1 / 298.257223563; e2 = f * (2 - f); ep2 = e2 / (1 - e2)
    k0 = 0.9996; lon0 = math.radians(-3)
    phi = math.radians(lat); lam = math.radians(lon)
    N = a / math.sqrt(1 - e2 * math.sin(phi) ** 2); T = math.tan(phi) ** 2
    C = ep2 * math.cos(phi) ** 2; A = (lam - lon0) * math.cos(phi)
    M = a * ((1 - e2/4 - 3*e2**2/64 - 5*e2**3/256) * phi
             - (3*e2/8 + 3*e2**2/32 + 45*e2**3/1024) * math.sin(2*phi)
             + (15*e2**2/256 + 45*e2**3/1024) * math.sin(4*phi)
             - (35*e2**3/3072) * math.sin(6*phi))
    x = k0 * N * (A + (1 - T + C) * A**3/6 + (5 - 18*T + T**2 + 72*C - 58*ep2) * A**5/120) + 500000
    y = k0 * (M + N * math.tan(phi) * (A**2/2 + (5 - T + 9*C + 4*C**2) * A**4/24
              + (61 - 58*T + T**2 + 600*C - 330*ep2) * A**6/720))
    return x, y

edif = json.loads((BASE / "datos/procesado/barrio_centro/edificios.json").read_text())
OX, OY = edif["origen_utm"]

gj = json.loads((BASE / "datos/procesado/logrono_osm.geojson").read_text())
calles = []
for f in gj["features"]:
    hw = f["properties"].get("highway")
    if not hw or hw not in ANCHOS:
        continue
    g = f["geometry"]
    lineas = []
    if g["type"] == "LineString":
        lineas = [g["coordinates"]]
    elif g["type"] == "MultiLineString":
        lineas = g["coordinates"]
    for lin in lineas:
        # Recorta la polilínea a la ventana: tramos de >=2 puntos dentro
        tramo = []
        for lon, lat in lin:
            if LON0 <= lon <= LON1 and LAT0 <= lat <= LAT1:
                x, y = utm(lon, lat)
                tramo.append([round(x - OX, 2), round(-(y - OY), 2)])
            else:
                if len(tramo) >= 2:
                    calles.append({"ancho": ANCHOS[hw], "clase": hw, "puntos": tramo})
                tramo = []
        if len(tramo) >= 2:
            calles.append({"ancho": ANCHOS[hw], "clase": hw, "puntos": tramo})

salida = BASE / "datos/procesado/barrio_centro/calles.json"
salida.write_text(json.dumps({"calles": calles}), encoding="utf-8")
(BASE / "juego/datos/calles.json").write_text(salida.read_text(), encoding="utf-8")
print("segmentos de calle:", len(calles))
print("longitud total aprox (km):", round(sum(
    math.dist(c["puntos"][i], c["puntos"][i + 1])
    for c in calles for i in range(len(c["puntos"]) - 1)) / 1000, 1))
print("OK ->", salida)
