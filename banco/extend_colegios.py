#!/usr/bin/env python3
# Añade a colegios.json los colegios e institutos con parcela en
# OSM que faltaban (auditoría del 2026-11-23: Marianistas, Sagasta,
# Cosme García, D'Elhúyar, Duques de Nájera, Batalla de Clavijo,
# Escuela de Arte, Chispita, Montessori y Los Boscos). Replica la
# proyección UTM de la pipeline (copiada, sin importar pipeline/).
# No toca las entradas existentes.
import json
import math
import os

BASE = os.path.join(os.path.dirname(__file__), "..")
SAL = os.path.join(BASE, "juego", "datos", "ciudad")


def utm(lon, lat):
    a = 6378137.0
    f = 1 / 298.257223563
    e2 = f * (2 - f)
    ep2 = e2 / (1 - e2)
    k0 = 0.9996
    lon0 = math.radians(-3)
    phi = math.radians(lat)
    lam = math.radians(lon)
    N = a / math.sqrt(1 - e2 * math.sin(phi) ** 2)
    T = math.tan(phi) ** 2
    C = ep2 * math.cos(phi) ** 2
    A = (lam - lon0) * math.cos(phi)
    M = a * ((1 - e2 / 4 - 3 * e2**2 / 64 - 5 * e2**3 / 256) * phi
             - (3 * e2 / 8 + 3 * e2**2 / 32 + 45 * e2**3 / 1024) * math.sin(2 * phi)
             + (15 * e2**2 / 256 + 45 * e2**3 / 1024) * math.sin(4 * phi)
             - (35 * e2**3 / 3072) * math.sin(6 * phi))
    x = k0 * N * (A + (1 - T + C) * A**3 / 6 + (5 - 18 * T + T**2 + 72 * C - 58 * ep2) * A**5 / 120) + 500000
    y = k0 * (M + N * math.tan(phi) * (A**2 / 2 + (5 - T + 9 * C + 4 * C**2) * A**4 / 24
              + (61 - 58 * T + T**2 + 600 * C - 330 * ep2) * A**6 / 720))
    return x, y


LON0, LON1, LAT0, LAT1 = -2.4535, -2.4320, 42.4615, 42.4725
X0, Y1 = utm(LON0, LAT1)
X1, Y0 = utm(LON1, LAT0)
OX, OY = (X0 + X1) / 2, (Y0 + Y1) / 2


def a_local(lon, lat):
    x, y = utm(lon, lat)
    return [round(x - OX, 1), round(-(y - OY), 1)]


# nombre en OSM -> nombre que se verá en el juego
NUEVOS = {
    "Instituto de Educación Secundaria Inventor Cosme García": "IES Inventor Cosme García",
    "Instituto de Educación Secundaria Hermanos D'Elhúyar": "IES Hermanos D'Elhúyar",
    "Escuela de arte y superior de diseño": "Escuela de Arte y Diseño",
    "Instituto de Educación Secundaria Duques de Nájera": "IES Duques de Nájera",
    "CEIPS Santa María - Marianistas Logroño": "CEIPS Santa María - Marianistas",
    "Instituto de Educación Secundaria Batalla de Clavijo": "IES Batalla de Clavijo",
    "Instituto Práxedes Mateo Sagasta": "IES Práxedes Mateo Sagasta",
    "Escuela Infantil de Primer Ciclo Chispita": "Escuela Infantil Chispita",
    "Montessori Schoolhouse": "Montessori Schoolhouse",
    "Los Boscos": "Colegio Los Boscos",
}

geo = json.load(open(os.path.join(BASE, "datos", "procesado", "logrono_osm.geojson"), encoding="utf-8"))
encontrados = {}
for feat in geo["features"]:
    p = feat.get("properties", {})
    nombre = p.get("name", "")
    if nombre not in NUEVOS:
        continue
    g = feat.get("geometry") or {}
    if g.get("type") == "Polygon":
        ring = g["coordinates"][0]
    elif g.get("type") == "MultiPolygon":
        ring = g["coordinates"][0][0]
    else:
        continue
    poly = [a_local(c[0], c[1]) for c in ring]
    # Quitar el punto de cierre duplicado si lo hay
    if len(poly) > 1 and poly[0] == poly[-1]:
        poly = poly[:-1]
    if len(poly) < 3:
        continue
    # Si hay varias geometrías con el mismo nombre (vía + relación),
    # quedarse con la de más vértices (la más completa).
    if nombre in encontrados and len(encontrados[nombre]) >= len(poly):
        continue
    encontrados[nombre] = poly

ruta = os.path.join(SAL, "colegios.json")
datos = json.load(open(ruta, encoding="utf-8"))
existentes = {c["n"] for c in datos["colegios"]}
anadidos = 0
for osm_nombre, poly in encontrados.items():
    visible = NUEVOS[osm_nombre]
    if visible in existentes:
        print("ya estaba:", visible)
        continue
    cen = [round(sum(p[0] for p in poly) / len(poly), 1),
           round(sum(p[1] for p in poly) / len(poly), 1)]
    datos["colegios"].append({"n": visible, "poly": poly, "c": cen})
    anadidos += 1
    print(f"añadido: {visible} centro={cen} verts={len(poly)}")

faltan = [NUEVOS[n] for n in NUEVOS if n not in encontrados]
if faltan:
    print("SIN GEOMETRIA EN OSM:", faltan)
json.dump(datos, open(ruta, "w", encoding="utf-8"), ensure_ascii=False)
print("total colegios:", len(datos["colegios"]), "| añadidos:", anadidos)
