#!/usr/bin/env python3
"""Extrae una línea de autobús urbano de Logroño desde el PBF de OSM.

Uso: linea_bus.py <ref>   (p. ej. linea_bus.py 1)

Salida: juego/datos/linea<ref>.json con, por cada sentido (relación
route=bus con ese ref): nombre, desde, hasta, paradas ordenadas
(nombre + coordenadas locales del juego) y la polilínea de la ruta
ya encadenada en coordenadas locales.

La conversión lon/lat -> local copia EXACTAMENTE utm()/a_local() de
pipeline/ciudad.py (mismo origen: centro de la ventana piloto), para
que las paradas caigan sobre las calles del juego.
"""
import json, math, sys
from pathlib import Path
import osmium

BASE = Path(__file__).resolve().parent.parent
PBF = BASE / "datos" / "osm" / "logrono_bbox.osm.pbf"

LON0, LON1, LAT0, LAT1 = -2.4535, -2.4320, 42.4615, 42.4725
X_MIN, X_MAX, Z_MIN, Z_MAX = -2700.0, 2700.0, -2000.0, 2000.0

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

def en_ventana(x, z, m=60.0):
    return X_MIN - m <= x <= X_MAX + m and Z_MIN - m <= z <= Z_MAX + m


class Lector(osmium.SimpleHandler):
    def __init__(self, ref):
        super().__init__()
        self.ref = ref
        self.nodos = {}      # id -> (lon, lat, {tags})
        self.vias = {}       # id -> [node ids]
        self.sentidos = []   # relaciones route=bus con el ref buscado

    def node(self, n):
        tags = {t.k: t.v for t in n.tags}
        self.nodos[n.id] = (n.location.lon, n.location.lat, tags)

    def way(self, w):
        self.vias[w.id] = [n.ref for n in w.nodes]

    def relation(self, r):
        tags = {t.k: t.v for t in r.tags}
        if tags.get("route") == "bus" and tags.get("ref") == self.ref:
            miembros = [(m.type, m.ref, m.role) for m in r.members]
            self.sentidos.append({"tags": tags, "miembros": miembros})


def encadenar(vias_ids, vias, nodos):
    """Une las vías de la ruta en una sola polilínea lon/lat, en orden."""
    puntos = []
    for vid in vias_ids:
        ids = vias.get(vid)
        if not ids:
            continue
        coords = []
        for nid in ids:
            if nid in nodos:
                lon, lat, _ = nodos[nid]
                coords.append((lon, lat))
        if not coords:
            continue
        if puntos:
            # Orientar la vía para que enganche con el final actual.
            d_ini = (coords[0][0] - puntos[-1][0]) ** 2 + (coords[0][1] - puntos[-1][1]) ** 2
            d_fin = (coords[-1][0] - puntos[-1][0]) ** 2 + (coords[-1][1] - puntos[-1][1]) ** 2
            if d_fin < d_ini:
                coords.reverse()
            if coords[0] == puntos[-1]:
                coords = coords[1:]
        puntos.extend(coords)
    return puntos


def main():
    ref = sys.argv[1] if len(sys.argv) > 1 else "1"
    lec = Lector(ref)
    lec.apply_file(str(PBF), locations=False)
    print(f"nodos={len(lec.nodos)} vias={len(lec.vias)} sentidos={len(lec.sentidos)}")
    salida = {"ref": ref, "sentidos": []}
    for s in lec.sentidos:
        tags = s["tags"]
        paradas, vias_ruta = [], []
        for tipo, mref, rol in s["miembros"]:
            if tipo == "w" and (rol == "" or rol in ("route", "forward", "backward")):
                vias_ruta.append(mref)
            elif rol.startswith("platform") or rol.startswith("stop"):
                # Parada: nodo suelto o vía-plataforma (se usa su centro).
                if tipo == "n" and mref in lec.nodos:
                    lon, lat, ntags = lec.nodos[mref]
                    paradas.append((ntags.get("name", ""), lon, lat))
                elif tipo == "w" and mref in lec.vias:
                    pts = [lec.nodos[nid] for nid in lec.vias[mref] if nid in lec.nodos]
                    if pts:
                        lon = sum(p[0] for p in pts) / len(pts)
                        lat = sum(p[1] for p in pts) / len(pts)
                        nombre = ""
                        for p in pts:
                            if p[2].get("name"):
                                nombre = p[2]["name"]
                                break
                        paradas.append((nombre, lon, lat))
        ruta_ll = encadenar(vias_ruta, lec.vias, lec.nodos)
        paradas_out = []
        for i, (nombre, lon, lat) in enumerate(paradas):
            x, z = a_local(lon, lat)
            paradas_out.append({"n": nombre if nombre else f"Parada {i + 1}",
                                "x": x, "z": z, "dentro": en_ventana(x, z)})
        ruta_out = [a_local(lon, lat) for lon, lat in ruta_ll]
        dentro = sum(1 for p in paradas_out if p["dentro"])
        print(f"- {tags.get('name', '?')}: paradas={len(paradas_out)} (dentro={dentro}) "
              f"ruta_pts={len(ruta_out)} desde={tags.get('from', '')} hasta={tags.get('to', '')}")
        salida["sentidos"].append({
            "nombre": tags.get("name", ""), "desde": tags.get("from", ""),
            "hasta": tags.get("to", ""), "paradas": paradas_out, "ruta": ruta_out})
    out = BASE / "juego" / "datos" / f"linea{ref}.json"
    out.write_text(json.dumps(salida, ensure_ascii=False), encoding="utf-8")
    print("escrito", out)

if __name__ == "__main__":
    main()
