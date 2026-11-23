#!/usr/bin/env python3
"""Inventario de líneas de autobús urbano de Logroño desde OSM.
Lee las relaciones route=bus / route_master=bus del recorte y guarda
datos/procesado/lineas_bus.json con ref, nombre y nº de miembros.
"""
import json, subprocess, urllib.parse
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
PBF = BASE / "datos" / "osm" / "logrono_bbox.osm.pbf"
OUT = BASE / "datos" / "procesado" / "lineas_bus.json"

opl = subprocess.run(["osmium", "cat", str(PBF), "-f", "opl"],
                     capture_output=True, text=True).stdout

def tags_de(linea):
    if " T" not in linea:
        return {}
    t = linea.split(" T", 1)[1].strip()
    tags = {}
    for par in t.split(","):
        if "=" in par:
            k, v = par.split("=", 1)
            tags[k] = urllib.parse.unquote(v)
    return tags

def n_miembros(linea):
    if " M" not in linea:
        return 0
    m = linea.split(" M", 1)[1].split(" T")[0].strip()
    return len([x for x in m.split(",") if x]) if m else 0

lineas, masters = [], []
for ln in opl.splitlines():
    if not ln.startswith("r"):
        continue
    tags = tags_de(ln)
    if tags.get("route") == "bus":
        lineas.append({"ref": tags.get("ref", ""), "nombre": tags.get("name", ""),
                       "desde": tags.get("from", ""), "hasta": tags.get("to", ""),
                       "operador": tags.get("operator", ""), "miembros": n_miembros(ln)})
    elif tags.get("route_master") == "bus":
        masters.append({"ref": tags.get("ref", ""), "nombre": tags.get("name", "")})

lineas.sort(key=lambda d: (d["ref"], d["nombre"]))
res = {"lineas_sentido": lineas, "lineas_agrupadas": masters,
       "total_relaciones_sentido": len(lineas), "total_agrupadas": len(masters)}
OUT.write_text(json.dumps(res, indent=1, ensure_ascii=False), encoding="utf-8")
for l in lineas:
    print(f'{l["ref"]:>4}  {l["nombre"]}  ({l["miembros"]} miembros)')
print("agrupadas:", [m["ref"] for m in masters])
print("OK ->", OUT)
