#!/usr/bin/env python3
"""Inventario v1 de datos abiertos de Logroño para el juego.
Fuentes: Catastro INSPIRE (BU + AD, municipio Catastro 26900) y OSM (Geofabrik La Rioja).
Salida: datos/procesado/inventario_v1.json + mapa urbano PNG.
"""
import json, re, sys
from collections import Counter
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
CAT = BASE / "datos" / "catastro"
PROC = BASE / "datos" / "procesado"

def count_in_file(path, needle):
    n = 0
    with open(path, "rb") as f:
        while True:
            chunk = f.read(1 << 22)
            if not chunk:
                break
            n += chunk.count(needle)
    return n

inv = {}

# --- Catastro: edificios ---
bu = CAT / "edificios" / "A.ES.SDGC.BU.26900.building.gml"
bup = CAT / "edificios" / "A.ES.SDGC.BU.26900.buildingpart.gml"
inv["catastro_edificios"] = count_in_file(bu, b"<bu-ext2d:Building ")
inv["catastro_partes_edificio"] = count_in_file(bup, b"<bu-ext2d:BuildingPart ")
plantas = Counter()
with open(bup, "rb") as f:
    data = f.read()
for m in re.finditer(rb"<bu-ext2d:numberOfFloorsAboveGround>(\d+)</bu-ext2d:numberOfFloorsAboveGround>", data):
    plantas[int(m.group(1))] += 1
inv["partes_con_dato_plantas"] = sum(plantas.values())
inv["plantas_distribucion_top"] = dict(sorted(plantas.items())[:16])
inv["altura_media_plantas"] = round(sum(k * v for k, v in plantas.items()) / max(1, sum(plantas.values())), 2)
del data

# --- Catastro: direcciones (portales) ---
ad = CAT / "direcciones" / "A.ES.SDGC.AD.26900.gml"
inv["catastro_direcciones_portales"] = count_in_file(ad, b"<AD:Address ")
inv["catastro_vias_con_nombre"] = count_in_file(ad, b"<AD:ThoroughfareName ")
with open(ad, "rb") as f:
    adata = f.read()
nombres = []
for m in re.finditer(rb"<AD:ThoroughfareName .*?</AD:ThoroughfareName>", adata, re.S):
    t = re.search(rb"<GN:text>\s*([^<]+)</GN:text>", m.group(0))
    if t:
        nombres.append(t.group(1).decode("iso-8859-1", "ignore").strip())
inv["nombres_de_via_ejemplos"] = nombres[:15]
inv["total_nombres_de_via"] = len(nombres)
del adata

# --- OSM ---
gj = json.load(open(PROC / "logrono_osm.geojson", encoding="utf-8"))
osm_edificios = 0
vias = Counter()
nombres_via = set()
portales_osm = 0
agua = 0
for feat in gj["features"]:
    p = feat.get("properties") or {}
    if p.get("building"):
        osm_edificios += 1
    hw = p.get("highway")
    if hw:
        vias[hw] += 1
        if p.get("name"):
            nombres_via.add(p["name"])
    if p.get("addr:housenumber"):
        portales_osm += 1
    if p.get("natural") == "water" or p.get("waterway"):
        agua += 1
inv["osm_edificios"] = osm_edificios
inv["osm_tramos_de_via"] = sum(vias.values())
inv["osm_calles_con_nombre_distintas"] = len(nombres_via)
inv["osm_portales_etiquetados"] = portales_osm
inv["osm_elementos_agua"] = agua

PROC.mkdir(parents=True, exist_ok=True)
out = PROC / "inventario_v1.json"
out.write_text(json.dumps(inv, indent=1, ensure_ascii=False), encoding="utf-8")
print(json.dumps(inv, indent=1, ensure_ascii=False))
print("OK ->", out)
