#!/usr/bin/env python3
"""Paquete de datos del barrio piloto (Centro / Casco Antiguo) para la Fase 2.
Fuentes: Catastro BU (partes de edificio con plantas, coords UTM 25830) y OSM.
Salida: datos/procesado/barrio_centro/edificios.json  (polígonos en metros,
relativos al origen del barrio) + resumen por consola.
"""
import json, math, re
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
SALIDA = BASE / "datos" / "procesado" / "barrio_centro"
SALIDA.mkdir(parents=True, exist_ok=True)

# Ventana del barrio piloto en lon/lat (Casco Antiguo + Centro)
LON0, LON1, LAT0, LAT1 = -2.4535, -2.4320, 42.4615, 42.4725

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

X0, Y1 = utm(LON0, LAT1)   # esquina NO
X1, Y0 = utm(LON1, LAT0)   # esquina SE
OX, OY = (X0 + X1) / 2, (Y0 + Y1) / 2  # origen local (centro de la ventana)
print(f"ventana UTM: x {X0:.0f}..{X1:.0f}  y {Y0:.0f}..{Y1:.0f}  ({X1-X0:.0f} x {Y1-Y0:.0f} m)")

gml = (BASE / "datos" / "catastro" / "edificios" / "A.ES.SDGC.BU.26900.buildingpart.gml")
texto = gml.read_bytes().decode("iso-8859-1")

edificios = []
for m in re.finditer(r"<bu-ext2d:BuildingPart .*?</bu-ext2d:BuildingPart>", texto, re.S):
    bloque = m.group(0)
    pos = re.search(r"<gml:posList[^>]*>([^<]+)</gml:posList>", bloque)
    if not pos:
        continue
    nums = [float(v) for v in pos.group(1).split()]
    puntos = [(nums[i], nums[i + 1]) for i in range(0, len(nums) - 1, 2)]
    if len(puntos) < 4:
        continue
    cx = sum(p[0] for p in puntos) / len(puntos)
    cy = sum(p[1] for p in puntos) / len(puntos)
    if not (X0 <= cx <= X1 and Y0 <= cy <= Y1):
        continue
    f = re.search(r"<bu-ext2d:numberOfFloorsAboveGround>(\d+)</bu-ext2d:numberOfFloorsAboveGround>", bloque)
    plantas = int(f.group(1)) if f else 1
    # Godot: x = este, z = -norte; relativo al origen. Se descarta el punto de cierre si repite el primero.
    if puntos[0] == puntos[-1]:
        puntos = puntos[:-1]
    poly = [[round(px - OX, 2), round(-(py - OY), 2)] for px, py in puntos]
    edificios.append({"plantas": plantas, "poligono": poly})

out = SALIDA / "edificios.json"
out.write_text(json.dumps({"origen_utm": [OX, OY], "ancho_m": X1 - X0, "alto_m": Y1 - Y0,
                           "edificios": edificios}), encoding="utf-8")
from collections import Counter
print("partes de edificio en la ventana:", len(edificios))
print("plantas:", dict(sorted(Counter(e["plantas"] for e in edificios).items())))
print("OK ->", out)
