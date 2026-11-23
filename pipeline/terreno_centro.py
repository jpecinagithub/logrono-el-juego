#!/usr/bin/env python3
"""Rejilla de alturas del barrio piloto desde el MDT05 del IGN.
Muestreo cada 10 m sobre la ventana; alturas relativas a 365 m
(el Ebro está a ~372 m y el centro a ~382 m, así los valores son pequeños).
Salida: datos/procesado/barrio_centro/terreno.json + copia en juego/datos/.
"""
import json, math
from pathlib import Path
from PIL import Image
import numpy as np

BASE = Path(__file__).resolve().parent.parent
LON0, LON1, LAT0, LAT1 = -2.4535, -2.4320, 42.4615, 42.4725
PASO = 10.0
BASE_M = 365.0
# El TIFF cubre x 543000..562000, y 4693000..4704000 a 5 m/px
TIF_X0, TIF_Y1, TIF_PX = 543000.0, 4704000.0, 5.0

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

X0, Y1 = utm(LON0, LAT1)
X1, Y0 = utm(LON1, LAT0)
OX, OY = (X0 + X1) / 2, (Y0 + Y1) / 2

img = np.asarray(Image.open(BASE / "datos/ign/mdt05_logrono.tif")).astype("float32")
cols = int((X1 - X0) / PASO) + 1
rows = int((Y1 - Y0) / PASO) + 1
alturas = []
for j in range(rows):
    uy = Y1 - j * PASO
    py = int(round((TIF_Y1 - uy) / TIF_PX))
    for i in range(cols):
        ux = X0 + i * PASO
        px = int(round((ux - TIF_X0) / TIF_PX))
        alturas.append(round(float(img[py, px]) - BASE_M, 2))

datos = {
    "cols": cols, "rows": rows, "paso_m": PASO, "base_m": BASE_M,
    "x0_local": round(X0 - OX, 2), "z0_local": round(-(Y1 - OY), 2),
    "alturas": alturas,
}
salida = BASE / "datos/procesado/barrio_centro/terreno.json"
salida.write_text(json.dumps(datos), encoding="utf-8")
(BASE / "juego/datos/terreno.json").write_text(salida.read_text(), encoding="utf-8")
print(f"rejilla {cols}x{rows}; altura rel. min {min(alturas)} max {max(alturas)}")
print("OK ->", salida)
