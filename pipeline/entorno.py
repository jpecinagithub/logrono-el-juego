#!/usr/bin/env python3
"""Entorno identificable del barrio: señales de calle, lugares, árboles y río.

Fuentes: OSM (logrono_osm.geojson). Salida: entorno.json con coordenadas
locales del barrio (mismo sistema que el resto de paquetes: UTM 25830
relativo al centro de la ventana).
"""
import json, math
from collections import defaultdict
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
SALIDA = BASE / "datos" / "procesado" / "barrio_centro"
SALIDA.mkdir(parents=True, exist_ok=True)

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

def a_local(lon, lat):
    x, y = utm(lon, lat)
    return [round(x - OX, 1), round(-(y - OY), 1)]

def en_ventana(coords):
    if isinstance(coords[0], (int, float)):
        return LON0 <= coords[0] <= LON1 and LAT0 <= coords[1] <= LAT1
    return any(en_ventana(c) for c in coords)

def centroide(coords):
    pts = []
    def rec(c):
        if isinstance(c[0], (int, float)):
            pts.append(c)
        else:
            for s in c: rec(s)
    rec(coords)
    return [sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)]

def largo_local(coords):
    pts = [a_local(c[0], c[1]) for c in coords]
    return sum(math.hypot(pts[i+1][0]-pts[i][0], pts[i+1][1]-pts[i][1]) for i in range(len(pts)-1)), pts

geo = json.loads((BASE / "datos" / "procesado" / "logrono_osm.geojson").read_text())

# --- Señales de calle: la de mayor longitud total, en su tramo más largo ---
por_nombre = defaultdict(lambda: {"total": 0.0, "mejor": None, "mejor_largo": 0.0})
for f in geo["features"]:
    p, g = f["properties"], f["geometry"]
    if g is None or not p.get("highway") or not p.get("name") or g["type"] != "LineString":
        continue
    if not en_ventana(g["coordinates"]):
        continue
    l, pts = largo_local(g["coordinates"])
    e = por_nombre[p["name"]]
    e["total"] += l
    if l > e["mejor_largo"]:
        e["mejor_largo"] = l
        e["mejor"] = pts[len(pts) // 2]
senales = []
for nombre, e in sorted(por_nombre.items(), key=lambda kv: -kv[1]["total"]):
    if e["total"] >= 120.0 and len(senales) < 70:
        senales.append({"n": nombre, "x": e["mejor"][0], "z": e["mejor"][1]})
print("señales de calle:", len(senales))

# --- Lugares con nombre (lista curada de sitios identificables) ---
QUERIDOS = {
    "Concatedral de Santa María de la Redonda", "Iglesia de San Bartolomé",
    "Iglesia de Santa María de Palacio", "Iglesia de Santiago",
    "Ermita de San Gregorio", "Ayuntamiento de Logroño",
    "Teatro Bretón de los Herreros", "Auditorio Municipal",
    "Museo de la Rioja", "Casa de las Ciencias", "CCR Centro de Cultura del Rioja",
    "Espacio Lagares", "Biblioteca de La Rioja",
    "Plaza de Abastos - Mercado de San Blas", "Puente de Piedra",
    "Puente de Hierro", "Espolón", "Monumento a Espartero",
    "Monumento al labrador", "Plaza del Mercado", "Plaza del Ayuntamiento",
    "Plaza de Toros de La Ribera", "Cines Moderno", "Ateneo Riojano", "UNED",
    "Fuente de los Riojanos Ilustres", "Parque del Ebro", "Plaza de la Redonda",
}
pois, vistos = [], set()
for f in geo["features"]:
    p, g = f["properties"], f["geometry"]
    if g is None or p.get("name") not in QUERIDOS or not en_ventana(g["coordinates"]):
        continue
    nombre = p["name"]
    if nombre in vistos:
        continue
    vistos.add(nombre)
    c = centroide(g["coordinates"])
    x, z = a_local(c[0], c[1])
    pois.append({"n": "Paseo del Espolón" if nombre == "Espolón" else nombre, "x": x, "z": z})
print("lugares:", len(pois), "de", len(QUERIDOS), "buscados")
faltan = QUERIDOS - vistos
if faltan:
    print("  no encontrados en la ventana:", sorted(faltan))

# --- Árboles ---
arboles = []
for f in geo["features"]:
    p, g = f["properties"], f["geometry"]
    if g is None or p.get("natural") != "tree" or g["type"] != "Point":
        continue
    lon, lat = g["coordinates"]
    if LON0 <= lon <= LON1 and LAT0 <= lat <= LAT1:
        arboles.append(a_local(lon, lat))
print("árboles:", len(arboles))

# --- Río Ebro: OSM lo parte en vías sueltas y con huecos; se toma la
# nube de puntos del cauce en una caja amplia, se ordena caminando al
# vecino más cercano y se recorta la polilínea contra el rectángulo de
# la ventana (con intersecciones en los bordes), para que el río llegue
# de borde a borde como en la realidad. ---
nube = []
for f in geo["features"]:
    p, g = f["properties"], f["geometry"]
    if g is None or g["type"] not in ("LineString", "MultiLineString"):
        continue
    if p.get("name") != "Río Ebro" and p.get("waterway") != "river":
        continue
    partes = [g["coordinates"]] if g["type"] == "LineString" else g["coordinates"]
    for parte in partes:
        for c in parte:
            pt = a_local(c[0], c[1])
            if abs(pt[0]) <= 1500 and abs(pt[1]) <= 950 and pt not in nube:
                nube.append(pt)
# Ordenar: empezar en el punto más al oeste y saltar al vecino más cercano
camino = []
if nube:
    resto = list(nube)
    actual = min(resto, key=lambda p: p[0])
    camino.append(actual)
    resto.remove(actual)
    while resto:
        sig = min(resto, key=lambda p: (p[0] - actual[0]) ** 2 + (p[1] - actual[1]) ** 2)
        if (sig[0] - actual[0]) ** 2 + (sig[1] - actual[1]) ** 2 > 450 ** 2:
            break
        camino.append(sig)
        resto.remove(sig)
        actual = sig

def recortar_segmento(a, b, rect):
    """Liang–Barsky: devuelve el tramo de a->b dentro del rect o None."""
    x0, z0, x1, z1 = rect
    dx, dz = b[0] - a[0], b[1] - a[1]
    t0, t1 = 0.0, 1.0
    for p, q in ((-dx, a[0] - x0), (dx, x1 - a[0]), (-dz, a[1] - z0), (dz, z1 - a[1])):
        if p == 0:
            if q < 0:
                return None
        else:
            r = q / p
            if p < 0:
                t0 = max(t0, r)
            else:
                t1 = min(t1, r)
            if t0 > t1:
                return None
    return ([round(a[0] + dx * t0, 1), round(a[1] + dz * t0, 1)],
            [round(a[0] + dx * t1, 1), round(a[1] + dz * t1, 1)])

RECT = (-918, -635, 918, 635)  # ventana (888 x 605) + 30 m de margen
tramos, actual = [], []
for i in range(len(camino) - 1):
    seg = recortar_segmento(camino[i], camino[i + 1], RECT)
    if seg is None:
        if actual: tramos.append(actual)
        actual = []
        continue
    p, q = seg
    if not actual or actual[-1] != p:
        if actual: tramos.append(actual)
        actual = [p]
    if q != p:
        actual.append(q)
if actual: tramos.append(actual)
mejor_rio = max(tramos, key=len) if tramos else []
# Estirar los extremos 25 m más allá del borde: la cinta cubre el filo
if len(mejor_rio) >= 2:
    for idx, ref in ((0, 1), (-1, -2)):
        e, r = mejor_rio[idx], mejor_rio[ref]
        dx, dz = e[0] - r[0], e[1] - r[1]
        n = math.hypot(dx, dz)
        if n > 0:
            mejor_rio[idx] = [round(e[0] + dx / n * 25, 1), round(e[1] + dz / n * 25, 1)]
print("río: cauce de", len(mejor_rio), "puntos, de",
      mejor_rio[0] if mejor_rio else None, "a", mejor_rio[-1] if mejor_rio else None)

# --- Calles con nombre: polilíneas para la etiqueta «estás en…» ---
calles_nom = []
for f in geo["features"]:
    p, g = f["properties"], f["geometry"]
    if g is None or not p.get("highway") or not p.get("name") or g["type"] != "LineString":
        continue
    if not en_ventana(g["coordinates"]):
        continue
    calles_nom.append({"n": p["name"], "p": [a_local(c[0], c[1]) for c in g["coordinates"]]})
print("calles con nombre:", len(calles_nom))

salida = {"senales": senales, "pois": pois, "arboles": arboles, "rio": mejor_rio, "calles": calles_nom}
ruta = SALIDA / "entorno.json"
ruta.write_text(json.dumps(salida, ensure_ascii=False))
print("escrito", ruta, ruta.stat().st_size, "bytes")
