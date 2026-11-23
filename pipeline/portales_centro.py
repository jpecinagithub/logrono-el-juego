#!/usr/bin/env python3
"""Portales del barrio piloto: unión completa dirección↔calle del Catastro
(AD GML de 26900 trae las ThoroughfareName en el mismo fichero).
Salida: datos/procesado/barrio_centro/portales.json + copia en juego/datos/,
en coordenadas locales del barrio, y elección de portales A/B para la
misión de prueba (A = Miguel Villanueva 1).
"""
import json, math, re
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
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

X0, Y1 = utm(LON0, LAT1)
X1, Y0 = utm(LON1, LAT0)
OX, OY = (X0 + X1) / 2, (Y0 + Y1) / 2

t = (BASE / "datos/catastro/direcciones/A.ES.SDGC.AD.26900.gml").read_bytes().decode("iso-8859-1")

# 1) Nombres de vía: id TN -> nombre
nombres = {}
for m in re.finditer(r'<AD:ThoroughfareName gml:id="ES\.SDGC\.TN\.([\d.]+)">(.*?)</AD:ThoroughfareName>', t, re.S):
    txt = re.search(r"<GN:text>([^<]+)</GN:text>", m.group(2))
    if txt:
        nombres[m.group(1)] = txt.group(1).strip()

# 2) Direcciones dentro de la ventana
portales = []
for m in re.finditer(r"<AD:Address .*?</AD:Address>", t, re.S):
    b = m.group(0)
    pos = re.search(r"<gml:pos>([\d.]+) ([\d.]+)</gml:pos>", b)
    tn = re.search(r'xlink:href="#ES\.SDGC\.TN\.([\d.]+)"', b)
    des = re.search(r"<AD:designator>([^<]+)</AD:designator>", b)
    if not (pos and tn):
        continue
    ux, uy = float(pos.group(1)), float(pos.group(2))
    if not (X0 <= ux <= X1 and Y0 <= uy <= Y1):
        continue
    portales.append({
        "calle": nombres.get(tn.group(1), "TN " + tn.group(1)),
        "numero": des.group(1).strip() if des else "S-N",
        "x": round(ux - OX, 2), "z": round(-(uy - OY), 2),
    })

salida = BASE / "datos/procesado/barrio_centro/portales.json"
salida.write_text(json.dumps({"portales": portales}, ensure_ascii=False), encoding="utf-8")
(BASE / "juego/datos/portales.json").write_text(salida.read_text(encoding="utf-8"), encoding="utf-8")
print("portales en la ventana:", len(portales), "| calles distintas:", len(set(p['calle'] for p in portales)))

a = next((p for p in portales if "VILLANUEVA" in p["calle"] and p["numero"] == "1"), None)
print("A (Miguel Villanueva 1):", a)
if a:
    cands = []
    for p in portales:
        d = math.dist((a["x"], a["z"]), (p["x"], p["z"]))
        if 300 <= d <= 700 and p["calle"] != a["calle"]:
            cands.append((round(d), p))
    cands.sort(key=lambda c: c[0])
    for d, p in cands[:8]:
        print(f"  candidato B a {d} m:", p)
