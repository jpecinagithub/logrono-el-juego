#!/usr/bin/env python3
"""Mapa 2D v1 del núcleo urbano de Logroño desde OSM (prueba del pipeline).
Salida: datos/procesado/mapa_logrono_v1.png
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw

BASE = Path(__file__).resolve().parent.parent
GJ = BASE / "datos" / "procesado" / "logrono_osm.geojson"
OUT = BASE / "datos" / "procesado" / "mapa_logrono_v1.png"

LON0, LON1 = -2.480, -2.406
LAT0, LAT1 = 42.436, 42.488
W, H = 1850, 1300

img = Image.new("RGB", (W, H), (28, 26, 43))
dr = ImageDraw.Draw(img, "RGBA")

def xy(lon, lat):
    x = (lon - LON0) / (LON1 - LON0) * W
    y = (1 - (lat - LAT0) / (LAT1 - LAT0)) * H
    return (x, y)

def rings(geom):
    t = geom["type"]
    if t == "Polygon":
        yield from geom["coordinates"]
    elif t == "MultiPolygon":
        for poly in geom["coordinates"]:
            yield from poly

def lines(geom):
    t = geom["type"]
    if t == "LineString":
        yield geom["coordinates"]
    elif t == "MultiLineString":
        yield from geom["coordinates"]

gj = json.load(open(GJ, encoding="utf-8"))
feats = gj["features"]

# 1) zonas verdes y agua
for f in feats:
    p = f.get("properties") or {}
    g = f.get("geometry") or {}
    if g.get("type") not in ("Polygon", "MultiPolygon"):
        continue
    if p.get("natural") == "water" or p.get("waterway") == "riverbank":
        for r in rings(g):
            dr.polygon([xy(*c) for c in r], fill=(43, 108, 176, 255))
    elif p.get("leisure") == "park" or p.get("landuse") in ("forest", "grass", "meadow", "recreation_ground") or p.get("leisure") in ("garden", "pitch"):
        for r in rings(g):
            dr.polygon([xy(*c) for c in r], fill=(52, 94, 66, 255))

# 2) edificios
for f in feats:
    p = f.get("properties") or {}
    g = f.get("geometry") or {}
    if not p.get("building") or g.get("type") not in ("Polygon", "MultiPolygon"):
        continue
    for r in rings(g):
        dr.polygon([xy(*c) for c in r], fill=(201, 123, 63, 255), outline=(146, 84, 40, 255))

# 3) vías
estilos = [
    (("motorway", "trunk"), (242, 179, 61), 5),
    (("primary",), (232, 228, 218), 4),
    (("secondary",), (214, 209, 198), 3),
    (("tertiary",), (190, 185, 175), 2),
]
resto = []
for f in feats:
    p = f.get("properties") or {}
    g = f.get("geometry") or {}
    hw = p.get("highway")
    if not hw or g.get("type") not in ("LineString", "MultiLineString"):
        continue
    hecho = False
    for clases, color, ancho in estilos:
        if hw in clases:
            for ln in lines(g):
                dr.line([xy(*c) for c in ln], fill=color, width=ancho)
            hecho = True
            break
    if not hecho and hw in ("residential", "unclassified", "living_street", "service", "pedestrian"):
        resto.append((f, g))
for f, g in resto:
    for ln in lines(g):
        dr.line([xy(*c) for c in ln], fill=(122, 116, 140), width=1)

# 4) el Ebro como línea si viene así
for f in feats:
    p = f.get("properties") or {}
    g = f.get("geometry") or {}
    if p.get("waterway") in ("river", "stream") and g.get("type") in ("LineString", "MultiLineString"):
        for ln in lines(g):
            dr.line([xy(*c) for c in ln], fill=(43, 108, 176), width=6)

img.save(OUT)
print("OK ->", OUT, img.size)
