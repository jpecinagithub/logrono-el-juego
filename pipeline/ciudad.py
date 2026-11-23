#!/usr/bin/env python3
"""Ciudad entera de Logroño (Fase 5.5): paquetes globales + baldosas.

Mismo origen local que el barrio (centro de la ventana piloto) para no
mover ni el spawn ni las coordenadas ya publicadas. Ventana urbana:
x -2700..2700, z -2000..2000 (5,4 x 4,0 km). Baldosas de 650 m.

Salidas en juego/datos/ciudad/:
  terreno.json  (rejilla MDT a 20 m, claves como las del barrio)
  grafo.json    (nodos/aristas de todas las vías OSM)
  portales.json (Catastro AD completo en la ventana)
  pois.json     (lugares con nombre: OSM + los 28 curados del centro)
  rio.json      (cauce del Ebro ordenado y recortado a la ventana)
  calles_mapa.json / calles_nom.json (polilíneas con nombre)
  tiles/t_<i>_<j>.json  {e: edificios, c: calles, a: árboles, p: pois}
"""
import json, math, re
from pathlib import Path
from PIL import Image
import numpy as np

BASE = Path(__file__).resolve().parent.parent
SAL = BASE / "juego" / "datos" / "ciudad"
(SAL / "tiles").mkdir(parents=True, exist_ok=True)

LON0, LON1, LAT0, LAT1 = -2.4535, -2.4320, 42.4615, 42.4725
X_MIN, X_MAX, Z_MIN, Z_MAX = -2700.0, 2700.0, -2000.0, 2000.0
TILE = 650.0

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

def en_ventana(x, z, m=0.0):
    return X_MIN - m <= x <= X_MAX + m and Z_MIN - m <= z <= Z_MAX + m

def tile_de(x, z):
    return (int((x - X_MIN) // TILE), int((z - Z_MIN) // TILE))

geo = json.loads((BASE / "datos/procesado/logrono_osm.geojson").read_text(encoding="utf-8"))

# ---------- Terreno (MDT05, muestreo a 20 m) ----------
img = np.array(Image.open(BASE / "datos/ign/mdt05_logrono.tif"))
PASO = 20.0
nx = int((X_MAX - X_MIN) / PASO) + 1
nz = int((Z_MAX - Z_MIN) / PASO) + 1
alturas = []
for j in range(nz):
    z = Z_MIN + j * PASO
    for i in range(nx):
        x = X_MIN + i * PASO
        ux, uy = OX + x, OY - z
        px = int((ux - 543000.0) / 5.0)
        py = int((4704000.0 - uy) / 5.0)
        px = min(max(px, 0), img.shape[1] - 1)
        py = min(max(py, 0), img.shape[0] - 1)
        alturas.append(round(float(img[py, px]) - 365.0, 1))
(SAL / "terreno.json").write_text(json.dumps({
    "cols": nx, "rows": nz, "paso_m": PASO, "x0_local": X_MIN, "z0_local": Z_MIN,
    "alturas": alturas}))
print("terreno:", nx, "x", nz, "alturas", min(alturas), "..", max(alturas))

# ---------- Edificios del Catastro -> baldosas ----------
gml = (BASE / "datos/catastro/edificios/A.ES.SDGC.BU.26900.buildingpart.gml")
texto = gml.read_bytes().decode("iso-8859-1")
tiles = {}
def baldosa(t):
    if t not in tiles:
        tiles[t] = {"e": [], "c": [], "a": [], "p": [], "d": []}
    return tiles[t]

n_ed = 0
for m in re.finditer(r"<bu-ext2d:BuildingPart .*?</bu-ext2d:BuildingPart>", texto, re.S):
    bloque = m.group(0)
    pos = re.search(r"<gml:posList[^>]*>([^<]+)</gml:posList>", bloque)
    if not pos:
        continue
    nums = [float(v) for v in pos.group(1).split()]
    puntos = [(nums[i], nums[i + 1]) for i in range(0, len(nums) - 1, 2)]
    if len(puntos) < 4:
        continue
    cx = sum(p[0] for p in puntos) / len(puntos) - OX
    cz = -(sum(p[1] for p in puntos) / len(puntos) - OY)
    if not en_ventana(cx, cz):
        continue
    f = re.search(r"<bu-ext2d:numberOfFloorsAboveGround>(\d+)</bu-ext2d:numberOfFloorsAboveGround>", bloque)
    plantas = int(f.group(1)) if f else 1
    if puntos[0] == puntos[-1]:
        puntos = puntos[:-1]
    parte = [plantas]
    for px, py in puntos:
        parte += [round(px - OX, 1), round(-(py - OY), 1)]
    baldosa(tile_de(cx, cz))["e"].append(parte)
    n_ed += 1
print("edificios (partes) en ventana:", n_ed)

# ---------- Calles OSM: baldosas + grafo + mapa + nombres ----------
ANCHOS = {
    "motorway": 13, "trunk": 12, "primary": 11, "secondary": 10,
    "tertiary": 9, "unclassified": 7, "residential": 7,
    "living_street": 6, "pedestrian": 6, "service": 4.5,
    "footway": 2.5, "path": 2.5, "cycleway": 2.5, "steps": 2.5,
}
nodos = {}
aristas = set()
calles_mapa = []
calles_nom = []
n_seg = 0
for f in geo["features"]:
    p, g = f["properties"], f["geometry"]
    if g is None or g["type"] != "LineString" or not p.get("highway"):
        continue
    pts = [a_local(c[0], c[1]) for c in g["coordinates"]]
    if not any(en_ventana(q[0], q[1], 60) for q in pts):
        continue
    clase = p["highway"]
    ancho = ANCHOS.get(clase, 5.0)
    nombre = p.get("name", "")
    if nombre:
        calles_nom.append({"n": nombre, "p": pts})
    calles_mapa.append(pts)
    # segmentos a baldosas + grafo
    prev_idx = None
    for q in pts:
        clave = (round(q[0] * 2) / 2, round(q[1] * 2) / 2)
        if clave not in nodos:
            nodos[clave] = len(nodos)
        idx = nodos[clave]
        if prev_idx is not None and prev_idx != idx:
            aristas.add((min(prev_idx, idx), max(prev_idx, idx)))
        prev_idx = idx
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        if not en_ventana(mx, mz, 40):
            continue
        baldosa(tile_de(mx, mz))["c"].append(
            {"p": [a, b], "a": ancho, "c": clase})
        n_seg += 1
lista_nodos = [[k[0], k[1]] for k, _ in sorted(nodos.items(), key=lambda kv: kv[1])]
(SAL / "grafo.json").write_text(json.dumps(
    {"nodos": lista_nodos, "aristas": [list(a) for a in aristas]}))
(SAL / "calles_mapa.json").write_text(json.dumps({"calles": calles_mapa}))
(SAL / "calles_nom.json").write_text(json.dumps({"calles": calles_nom}))
print("calles: segmentos", n_seg, "| grafo:", len(lista_nodos), "nodos,",
      len(aristas), "aristas | polilíneas mapa:", len(calles_mapa))

# ---------- Árboles OSM -> baldosas ----------
n_arb = 0
for f in geo["features"]:
    p, g = f["properties"], f["geometry"]
    if g is None or g["type"] != "Point" or p.get("natural") != "tree":
        continue
    x, z = a_local(g["coordinates"][0], g["coordinates"][1])
    if en_ventana(x, z):
        baldosa(tile_de(x, z))["a"].append([x, z])
        n_arb += 1
print("árboles:", n_arb)

# ---------- Portales del Catastro (ventana entera) ----------
t = (BASE / "datos/catastro/direcciones/A.ES.SDGC.AD.26900.gml").read_bytes().decode("iso-8859-1")
nombres = {}
for m in re.finditer(r'<AD:ThoroughfareName gml:id="ES\.SDGC\.TN\.([\d.]+)">(.*?)</AD:ThoroughfareName>', t, re.S):
    txt = re.search(r"<GN:text>([^<]+)</GN:text>", m.group(2))
    if txt:
        nombres[m.group(1)] = txt.group(1).strip()
portales = []
for m in re.finditer(r"<AD:Address .*?</AD:Address>", t, re.S):
    b = m.group(0)
    pos = re.search(r"<gml:pos>([\d.]+) ([\d.]+)</gml:pos>", b)
    tn = re.search(r'xlink:href="#ES\.SDGC\.TN\.([\d.]+)"', b)
    des = re.search(r"<AD:designator>([^<]+)</AD:designator>", b)
    if not (pos and tn):
        continue
    ux, uy = float(pos.group(1)), float(pos.group(2))
    x, z = round(ux - OX, 1), round(-(uy - OY), 1)
    if not en_ventana(x, z):
        continue
    portales.append({"calle": nombres.get(tn.group(1), "TN " + tn.group(1)),
                     "numero": des.group(1).strip() if des else "S-N",
                     "x": x, "z": z})
(SAL / "portales.json").write_text(json.dumps({"portales": portales}, ensure_ascii=False))
print("portales:", len(portales))
# Fase 7: las puertas (portales del Catastro) van también por baldosa,
# para que los coches aparcados nunca tapen un portal.
for p in portales:
    baldosa(tile_de(p["x"], p["z"]))["d"].append([p["x"], p["z"]])
print("puertas en baldosas:", sum(len(t["d"]) for t in tiles.values()))

# ---------- POIs: OSM con nombre + los 28 curados del centro ----------
pois = []
def mete_poi(nombre, x, z, k=0, c=0):
    for q in pois:
        if q["n"] == nombre and math.hypot(q["x"] - x, q["z"] - z) < 80:
            if k > q["k"]:
                q["k"] = k
            if c > q["c"]:
                q["c"] = c
            return
    pois.append({"n": nombre, "x": x, "z": z, "k": k, "c": c})

AMEN_OK = {"townhall", "theatre", "arts_centre", "cinema", "library",
           "marketplace", "university", "hospital", "place_of_worship",
           "school", "college", "bus_station", "ferry_terminal"}
LEIS_OK = {"park", "garden", "stadium", "sports_centre", "marina", "pitch"}

for f in geo["features"]:
    p, g = f["properties"], f["geometry"]
    if g is None or not p.get("name"):
        continue
    if not (p.get("amenity") or p.get("leisure") or p.get("tourism")
            or p.get("historic") or p.get("railway") == "station"
            or p.get("building") in ("church", "cathedral", "public", "train_station", "university", "hospital", "school")):
        continue
    if g["type"] == "Point":
        x, z = a_local(g["coordinates"][0], g["coordinates"][1])
    elif g["type"] in ("Polygon", "MultiPolygon"):
        anillo = g["coordinates"][0]
        if g["type"] == "MultiPolygon":
            anillo = g["coordinates"][0][0]
        cx = sum(c[0] for c in anillo) / len(anillo)
        cy = sum(c[1] for c in anillo) / len(anillo)
        x, z = a_local(cx, cy)
    else:
        continue
    if en_ventana(x, z):
        k = 1 if (p.get("tourism") or p.get("historic")
                  or p.get("railway") == "station"
                  or p.get("building") in ("church", "cathedral", "public", "train_station", "university", "hospital", "school")
                  or p.get("amenity") in AMEN_OK
                  or p.get("leisure") in LEIS_OK) else 0
        mete_poi(p["name"], x, z, k)
entorno = json.loads((BASE / "juego/datos/entorno.json").read_text(encoding="utf-8"))
for p in entorno["pois"]:
    mete_poi(p["n"], float(p["x"]), float(p["z"]), 1, 1)
(SAL / "pois.json").write_text(json.dumps({"pois": pois}, ensure_ascii=False))
for q in pois:
    if q["k"] == 1 and en_ventana(q["x"], q["z"]):
        baldosa(tile_de(q["x"], q["z"]))["p"].append(q)
print("pois ciudad:", len(pois), "| destacados (k=1):", sum(q["k"] for q in pois))

# ---------- Río Ebro: la vía principal (141 puntos) ya viene ordenada
# de OSM y cruza toda la ventana; basta recortarla contra el rectángulo.
vias_ebro = []
for f in geo["features"]:
    p, g = f["properties"], f["geometry"]
    if g is None or p.get("name") != "Río Ebro":
        continue
    if g["type"] == "LineString":
        vias_ebro.append([a_local(c[0], c[1]) for c in g["coordinates"]])
    elif g["type"] == "MultiLineString":
        for parte in g["coordinates"]:
            vias_ebro.append([a_local(c[0], c[1]) for c in parte])
camino = max(vias_ebro, key=len) if vias_ebro else []

def recortar_segmento(a, b, rect):
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

RECT = (X_MIN - 30, Z_MIN - 30, X_MAX + 30, Z_MAX + 30)
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
rio = max(tramos, key=len) if tramos else []
(SAL / "rio.json").write_text(json.dumps({"puntos": rio}))
print("río: ", len(rio), "puntos, de", rio[0] if rio else None, "a", rio[-1] if rio else None)

# ---------- Escribir baldosas ----------
total = 0
for (ti, tj), datos_t in tiles.items():
    if not (datos_t["e"] or datos_t["c"] or datos_t["a"]):
        continue
    ruta = SAL / "tiles" / f"t_{ti}_{tj}.json"
    ruta.write_text(json.dumps(datos_t))
    total += ruta.stat().st_size
print("baldosas escritas:", len([1 for t in tiles.values() if t['e'] or t['c'] or t['a']]),
      "| tamaño total tiles: %.1f MB" % (total / 1e6))
