#!/usr/bin/env python3
"""Horneado del Bloque 7 (transversales): prepara los datos de runtime.

Lee los JSON crudos de banco/ (placas de toda la ciudad, paradas OSM y
contenedores) y escribe las versiones de runtime en juego/datos/ciudad/.

A las paradas y contenedores les añade el rumbo de su calle (hx, hz),
calculado desde el grafo viario horneado (juego/datos/ciudad/grafo.json):
nodo más cercano y su arista más larga. Las placas ya traen rumbo.

También trata las paradas/contenedores que caigan dentro de la
huella de un edificio: se comprueba contra las baldosas horneadas
de la ciudad (clave «e» de cada tile). En runtime las huellas solo
existen para las baldosas ya construidas, así que este filtro tiene
que ir horneado. Criterio: si el punto está dentro pero a menos de
4 m del borde, es una parada de fachada (Ayuntamiento, la estación
de autobuses) y se empuja fuera, a 1,4 m de la huella; solo se
descarta lo que quede a más de 4 m de profundidad, dato sucio.

Script autónomo: solo lee JSON, no importa ningún módulo de pipeline/.
"""
import json
import math
import os
from collections import defaultdict

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BANCO = os.path.join(RAIZ, "banco")
CIUDAD = os.path.join(RAIZ, "juego", "datos", "ciudad")
TILE_M = 650.0
CIUDAD_X0 = -2700.0
CIUDAD_Z0 = -2000.0


def dentro(poly, x, z):
    """Punto en polígono (ray casting); poly = [(x, z), ...]."""
    dentro_ = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, zi = poly[i]
        xj, zj = poly[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi:
            dentro_ = not dentro_
        j = i
    return dentro_


class Huellas:
    """Huellas de edificio por baldosa, cargadas bajo demanda."""

    def __init__(self):
        self.cache = {}

    def de_tile(self, tx, tz):
        clave = (tx, tz)
        if clave not in self.cache:
            ruta = os.path.join(CIUDAD, "tiles", f"t_{tx}_{tz}.json")
            polys = []
            if os.path.exists(ruta):
                d = cargar(ruta)
                for e in d.get("e", []):
                    pts = [(e[i], e[i + 1]) for i in range(1, len(e) - 1, 2)]
                    if len(pts) >= 3:
                        polys.append(pts)
            self.cache[clave] = polys
        return self.cache[clave]

    def corregir(self, x, z):
        """(x, z) corregidos, o None si el punto está enterrado.

        Fuera de toda huella: tal cual. Dentro pero cerca del borde:
        empujado a 1,4 m fuera de la huella. A más de 4 m del borde:
        None (dato sucio, se descarta).
        """
        tx = int((x - CIUDAD_X0) // TILE_M)
        tz = int((z - CIUDAD_Z0) // TILE_M)
        for poly in self.de_tile(tx, tz):
            xs = [p[0] for p in poly]
            zs = [p[1] for p in poly]
            if not (min(xs) - 1 <= x <= max(xs) + 1 and min(zs) - 1 <= z <= max(zs) + 1):
                continue
            if not dentro(poly, x, z):
                continue
            # Punto más cercano del borde y profundidad
            mejor = None
            mejor_d2 = None
            for i in range(len(poly)):
                ax, az = poly[i]
                bx, bz = poly[(i + 1) % len(poly)]
                abx, abz = bx - ax, bz - az
                l2 = abx * abx + abz * abz
                t = 0.0 if l2 == 0 else max(0.0, min(1.0, ((x - ax) * abx + (z - az) * abz) / l2))
                px, pz = ax + abx * t, az + abz * t
                d2 = (x - px) ** 2 + (z - pz) ** 2
                if mejor_d2 is None or d2 < mejor_d2:
                    mejor, mejor_d2 = (px, pz), d2
            prof = math.sqrt(mejor_d2)
            if prof > 4.0:
                return None
            ux, uz = x - mejor[0], z - mejor[1]
            if prof < 1e-6:
                return (x, z)
            ux, uz = ux / prof, uz / prof
            return (round(mejor[0] - ux * 1.4, 1), round(mejor[1] - uz * 1.4, 1))
        return (x, z)


def cargar(ruta):
    with open(ruta, encoding="utf-8") as f:
        return json.load(f)


def guardar(ruta, datos):
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, separators=(",", ":"))
    print("escrito", os.path.relpath(ruta, RAIZ))


def main():
    grafo = cargar(os.path.join(CIUDAD, "grafo.json"))
    nodos = grafo["nodos"]
    vecinos = defaultdict(list)
    for a, b in grafo["aristas"]:
        vecinos[a].append(b)
        vecinos[b].append(a)

    # Rejilla de 50 m para el nodo más cercano
    rejilla = defaultdict(list)
    for i, (x, z) in enumerate(nodos):
        rejilla[(int(x // 50), int(z // 50))].append(i)

    def rumbo(x, z):
        cx, cz = int(x // 50), int(z // 50)
        mejor, mejor_d2 = None, None
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                for i in rejilla.get((cx + dx, cz + dz), []):
                    nx, nz = nodos[i]
                    d2 = (nx - x) ** 2 + (nz - z) ** 2
                    if mejor_d2 is None or d2 < mejor_d2:
                        mejor, mejor_d2 = i, d2
        if mejor is None:
            return 1.0, 0.0
        bx, bz = nodos[mejor]
        hx = hz = None
        largo = -1.0
        for j in vecinos.get(mejor, []):
            vx, vz = nodos[j][0] - bx, nodos[j][1] - bz
            l2 = vx * vx + vz * vz
            if l2 > largo:
                largo, hx, hz = l2, vx, vz
        if hx is None or largo <= 0:
            return 1.0, 0.0
        n = math.sqrt(largo)
        return round(hx / n, 3), round(hz / n, 3)

    # Placas: tal cual (ya traen rumbo)
    placas = cargar(os.path.join(BANCO, "placas_ciudad.json"))
    guardar(os.path.join(CIUDAD, "placas_ciudad.json"), placas)
    print("placas:", len(placas["placas"]))

    # Paradas y contenedores: con rumbo de calle y fuera de edificios
    huellas = Huellas()
    paradas = cargar(os.path.join(BANCO, "paradas.json"))
    buenas = []
    for p in paradas["paradas"]:
        corr = huellas.corregir(p["x"], p["z"])
        if corr is None:
            print("parada enterrada en un edificio, descartada:", p["n"], p["x"], p["z"])
            continue
        if corr != (p["x"], p["z"]):
            print("parada de fachada, empujada fuera:", p["n"], (p["x"], p["z"]), "->", corr)
            p["x"], p["z"] = corr
        p["hx"], p["hz"] = rumbo(p["x"], p["z"])
        buenas.append(p)
    paradas["paradas"] = buenas
    guardar(os.path.join(CIUDAD, "paradas.json"), paradas)
    print("paradas:", len(buenas))

    contenedores = cargar(os.path.join(BANCO, "contenedores.json"))
    buenos = []
    for c in contenedores["contenedores"]:
        corr = huellas.corregir(c["x"], c["z"])
        if corr is None:
            print("contenedor enterrado en un edificio, descartado:", c["x"], c["z"])
            continue
        if corr != (c["x"], c["z"]):
            print("contenedor de fachada, empujado fuera:", (c["x"], c["z"]), "->", corr)
            c["x"], c["z"] = corr
        c["hx"], c["hz"] = rumbo(c["x"], c["z"])
        buenos.append(c)
    contenedores["contenedores"] = buenos
    guardar(os.path.join(CIUDAD, "contenedores.json"), contenedores)
    print("contenedores:", len(buenos))


if __name__ == "__main__":
    main()
