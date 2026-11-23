#!/usr/bin/env python3
"""Locales comerciales con nombre (OSM) -> clave "l" en cada baldosa.

Para cada tienda, bar, banco, farmacia... con nombre: posición local,
dirección hacia la calle más cercana (para orientar el escaparate),
tipo, color del cartel (los bancos, con su color de marca) y si lleva
terraza (bares, cafés y restaurantes). El juego dibuja con esto el
escaparate, el cartel con el nombre, el toldo y las mesas de fuera:
la planta baja deja de ser un muro ciego.
"""
import json
import math
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
SAL = BASE / "juego" / "datos" / "ciudad"

LON0, LON1, LAT0, LAT1 = -2.4535, -2.4320, 42.4615, 42.4725
X_MIN, Z_MIN, TILE = -2700.0, -2000.0, 650.0


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
    return round(x - OX, 1), round(-(y - OY), 1)


def tile_de(x, z):
    return (int((x - X_MIN) // TILE), int((z - Z_MIN) // TILE))


# Colores de cartel por marca (bancos) y por tipo
MARCAS = {
    "santander": [0.85, 0.10, 0.10], "bbva": [0.05, 0.25, 0.55],
    "caixabank": [0.05, 0.15, 0.35], "caixa": [0.05, 0.15, 0.35],
    "ibercaja": [0.55, 0.08, 0.16], "kutxabank": [0.10, 0.45, 0.25],
    "laboral": [0.90, 0.45, 0.08], "bankinter": [0.95, 0.50, 0.05],
    "cajamar": [0.15, 0.50, 0.30], "evo": [0.45, 0.15, 0.55],
    "caja rural": [0.20, 0.45, 0.20], "unicaja": [0.10, 0.40, 0.30],
    "abanca": [0.05, 0.30, 0.50], "sabadell": [0.05, 0.25, 0.50],
}
TERRAZA = {"bar", "cafe", "restaurant", "pub", "fast_food", "ice_cream", "biergarten"}
HOSTEL = {"bar", "cafe", "restaurant", "pub", "fast_food", "ice_cream", "bakery"}


def clasifica(p):
    nombre = p.get("name", "").strip()
    if not nombre:
        return None
    if p.get("amenity") == "bank":
        bajo = nombre.lower()
        for marca, col in MARCAS.items():
            if marca in bajo:
                return ("banco", col, 0)
        return ("banco", [0.15, 0.25, 0.45], 0)
    if p.get("amenity") == "pharmacy":
        return ("farmacia", [0.10, 0.55, 0.25], 0)
    am = p.get("amenity", "")
    if am in TERRAZA:
        return ("bar", [0.45, 0.22, 0.12], 1)
    if am == "bakery" or p.get("shop") == "bakery":
        return ("tienda", [0.80, 0.50, 0.15], 0)
    if p.get("shop"):
        h = abs(hash((nombre, p["shop"]))) % 6
        paleta = [[0.55, 0.20, 0.35], [0.15, 0.35, 0.55], [0.65, 0.45, 0.10],
                  [0.25, 0.45, 0.40], [0.50, 0.30, 0.55], [0.70, 0.30, 0.15]]
        return ("tienda", paleta[h], 0)
    if p.get("tourism") == "hotel":
        return ("hotel", [0.25, 0.25, 0.35], 0)
    if p.get("office"):
        return ("oficina", [0.30, 0.32, 0.38], 0)
    if am in ("cinema", "theatre", "marketplace", "library", "books"):
        return ("cultura", [0.40, 0.25, 0.45], 0)
    return None


def centroide(geom):
    if geom["type"] == "Point":
        return geom["coordinates"]
    if geom["type"] in ("Polygon", "LineString"):
        pts = geom["coordinates"][0] if geom["type"] == "Polygon" else geom["coordinates"]
        xs = [c[0] for c in pts]; ys = [c[1] for c in pts]
        return [sum(xs) / len(xs), sum(ys) / len(ys)]
    if geom["type"] == "MultiPolygon":
        pts = geom["coordinates"][0][0]
        xs = [c[0] for c in pts]; ys = [c[1] for c in pts]
        return [sum(xs) / len(xs), sum(ys) / len(ys)]
    return None


# Segmentos de calle con nombre (para orientar cada local a su calle)
calles = json.loads((SAL / "calles_nom.json").read_text(encoding="utf-8"))["calles"]
segmentos = []
for c in calles:
    pts = c["p"]
    for i in range(len(pts) - 1):
        segmentos.append((pts[i], pts[i + 1]))


def hacia_calle(x, z):
    mejor = None; mejor_d = 1e18; mejor_dir = (1.0, 0.0)
    for a, b in segmentos:
        ax, az = a; bx, bz = b
        dx, dz = bx - ax, bz - az
        L2 = dx * dx + dz * dz
        if L2 < 0.01:
            continue
        t = max(0.0, min(1.0, ((x - ax) * dx + (z - az) * dz) / L2))
        px, pz = ax + dx * t, az + dz * t
        d = (x - px) ** 2 + (z - pz) ** 2
        if d < mejor_d:
            mejor_d = d; mejor = (px, pz)
            L = math.sqrt(L2); mejor_dir = (dx / L, dz / L)
    if mejor is None or mejor_d > 45 * 45:
        return None
    hx, hz = mejor[0] - x, mejor[1] - z
    Lh = math.hypot(hx, hz)
    if Lh < 0.5:  # el punto ya está sobre la calle: frente hacia un lado
        hx, hz = -mejor_dir[1], mejor_dir[0]
        Lh = 1.0
    return (hx / Lh, hz / Lh), mejor_dir


geo = json.loads((BASE / "datos/procesado/logrono_osm.geojson").read_text(encoding="utf-8"))
por_tile = {}
total = 0
for f in geo["features"]:
    p = f["properties"]
    cl = clasifica(p)
    if cl is None:
        continue
    c = centroide(f["geometry"])
    if c is None:
        continue
    x, z = a_local(c[0], c[1])
    if not (X_MIN <= x <= -X_MIN and -2000.0 <= z <= 2000.0):
        continue
    oc = hacia_calle(x, z)
    if oc is None:
        continue
    (hx, hz), (dx, dz) = oc
    tipo, col, tz = cl
    por_tile.setdefault(tile_de(x, z), []).append({
        "n": p["name"][:40], "t": tipo, "x": x, "z": z,
        "hx": round(hx, 2), "hz": round(hz, 2),
        "dx": round(dx, 2), "dz": round(dz, 2),
        "c": col, "tz": tz})
    total += 1

escritos = 0
for (ti, tj), lista in por_tile.items():
    ruta = SAL / "tiles" / f"t_{ti}_{tj}.json"
    if not ruta.exists():
        continue
    d = json.loads(ruta.read_text(encoding="utf-8"))
    d["l"] = lista
    ruta.write_text(json.dumps(d))
    escritos += 1

resumen = {}
for lista in por_tile.values():
    for l in lista:
        resumen[l["t"]] = resumen.get(l["t"], 0) + 1
print("locales:", total, "| por tipo:", resumen, "| baldosas con locales:", escritos)
mv = [l for lista in por_tile.values() for l in lista
      if abs(l["x"] + 307) < 120 and abs(l["z"] - 322) < 120]
print("cerca de Miguel Villanueva 1:", [(l["t"], l["n"]) for l in mv][:14])
