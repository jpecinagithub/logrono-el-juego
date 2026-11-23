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

Y saca de la CALZADA lo que OSM mapea sobre el asfalto (en OSM las
paradas y los contenedores se pintan muchas veces sobre la propia
vía): con los tramos «c» de las baldosas (polilínea + ancho + clase)
se busca la calle de vehículos más paralela al rumbo del punto; si
cae dentro de su calzada, se desplaza en perpendicular hasta quedar
sobre la acera (semiancho + margen). Lo mismo para las placas de
esquina, que tampoco pueden flotar sobre la calzada.

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

    def prof_max(self, x, z):
        """Profundidad dentro de la huella más honda que pisa el
        punto (0 si está fuera de todas). Las huellas de Catastro
        se solapan entre sí (medianeras), así que «fuera de todas»
        no siempre existe junto a una pared: la piel (<= 1,6 m)
        vale como apoyado en la fachada, enterrado no."""
        tx = int((x - CIUDAD_X0) // TILE_M)
        tz = int((z - CIUDAD_Z0) // TILE_M)
        peor = 0.0
        for poly in self.de_tile(tx, tz):
            xs = [p[0] for p in poly]
            zs = [p[1] for p in poly]
            if not (min(xs) - 1 <= x <= max(xs) + 1 and min(zs) - 1 <= z <= max(zs) + 1):
                continue
            if not dentro(poly, x, z):
                continue
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
                    mejor_d2 = d2
            peor = max(peor, math.sqrt(mejor_d2))
        return peor


VEHICULOS = {"primary", "secondary", "tertiary", "residential",
             "unclassified", "service", "trunk", "primary_link",
             "secondary_link", "tertiary_link"}


class Calles:
    """Tramos de calle con vehículos (clave «c» de las baldosas)."""

    def __init__(self):
        self.segs = []
        tiles = os.path.join(CIUDAD, "tiles")
        for nombre in sorted(os.listdir(tiles)):
            if not nombre.endswith(".json"):
                continue
            d = cargar(os.path.join(tiles, nombre))
            for c in d.get("c", []):
                if c["c"] not in VEHICULOS:
                    continue
                p = c["p"]
                for i in range(len(p) - 1):
                    self.segs.append((p[i][0], p[i][1], p[i + 1][0],
                                      p[i + 1][1], float(c["a"])))
        self.rejilla = defaultdict(list)
        for idx, (ax, az, bx, bz, _a) in enumerate(self.segs):
            for gx in range(int(min(ax, bx) // 50), int(max(ax, bx) // 50) + 1):
                for gz in range(int(min(az, bz) // 50), int(max(az, bz) // 50) + 1):
                    self.rejilla[(gx, gz)].append(idx)

    def referencia(self, x, z, hx, hz):
        """(dist, semiancho, qx, qz, nx, nz) del tramo vehicular más
        paralelo al rumbo entre los cercanos; None si no hay."""
        cx, cz = int(x // 50), int(z // 50)
        mejor = None
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                for idx in self.rejilla.get((cx + dx, cz + dz), []):
                    ax, az, bx, bz, a = self.segs[idx]
                    abx, abz = bx - ax, bz - az
                    l2 = abx * abx + abz * abz
                    if l2 == 0:
                        continue
                    t = max(0.0, min(1.0, ((x - ax) * abx + (z - az) * abz) / l2))
                    qx, qz = ax + abx * t, az + abz * t
                    d = math.hypot(x - qx, z - qz)
                    if d > a / 2 + 6:
                        continue
                    n = math.sqrt(l2)
                    par = abs((abx * hx + abz * hz) / n)
                    if par < 0.45:
                        continue
                    clave = (round(par, 2), -d)
                    if mejor is None or clave > mejor[0]:
                        mejor = (clave, d, a / 2, qx, qz, -abz / n, abx / n)
        if mejor is None:
            return None
        return mejor[1], mejor[2], mejor[3], mejor[4], mejor[5], mejor[6]

    def sacar(self, x, z, hx, hz, destino, huellas=None, forzar_lado=0.0):
        """Si el punto cae en la calzada, lo mueve a la acera
        (semiancho + destino desde el eje). Si no, lo deja igual."""
        r = self.referencia(x, z, hx, hz)
        if r is None:
            return (x, z)
        d, semi, qx, qz, nx, nz = r
        if d >= semi + 0.4:
            return (x, z)
        s = (x - qx) * nx + (z - qz) * nz
        signo = 1.0 if s >= 0 else -1.0
        if forzar_lado != 0.0:
            signo = forzar_lado
        elif abs(s) < 0.3 and huellas is not None:
            # Sobre el eje mismo: se elige el lado sin edificio
            for cand in (1.0, -1.0):
                px, pz = qx + nx * cand * (semi + destino), qz + nz * cand * (semi + destino)
                if huellas.corregir(px, pz) == (px, pz):
                    signo = cand
                    break
        return (round(qx + nx * signo * (semi + destino), 1),
                round(qz + nz * signo * (semi + destino), 1))

    def en_calzada(self, x, z, hx, hz):
        r = self.referencia(x, z, hx, hz)
        return r is not None and r[0] < r[1] + 0.4


def colocar(calles, huellas, x, z, hx, hz, destino):
    """Punto válido (fuera de edificios y fuera del asfalto) o None.

    Sacar de la calzada puede meter el punto en un edificio y
    sacarlo del edificio puede devolverlo a la calzada: se itera
    y, si el lado natural no estabiliza, se prueba el contrario.
    Vale como "fuera del asfalto" estar a semiancho - 0,1 o más
    del eje de la calle de referencia: en las esquinas la calle
    que cruza no debe expulsar el punto de la acera.
    """
    def en_asfalto(px, pz):
        r = calles.referencia(px, pz, hx, hz)
        return r is not None and r[0] < r[1] - 0.1

    mejor = None
    for lado in (0.0, 1.0, -1.0):
        px, pz = x, z
        for _ in range(3):
            qx, qz = calles.sacar(px, pz, hx, hz, destino, huellas, lado)
            r = huellas.corregir(qx, qz)
            if r is None:
                break
            pen = (100.0 if en_asfalto(r[0], r[1]) else 0.0) \
                + max(0.0, huellas.prof_max(r[0], r[1]) - 1.6) * 10.0
            if mejor is None or pen < mejor[0]:
                mejor = (pen, r)
            if pen == 0.0:
                return r
            px, pz = r
    # Vale el mejor candidato que esté fuera del asfalto aunque
    # toque la piel de una fachada; en el asfalto, nunca.
    if mejor is not None and mejor[0] < 100.0:
        return mejor[1]
    return None


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

    huellas = Huellas()
    calles = Calles()

    # Placas: ya traen rumbo; solo salen de la calzada si caen en ella
    for ruta_b, ruta_c in [
            (os.path.join(BANCO, "placas_ciudad.json"), os.path.join(CIUDAD, "placas_ciudad.json")),
            (os.path.join(CIUDAD, "placas.json"), os.path.join(CIUDAD, "placas.json"))]:
        placas = cargar(ruta_b)
        movidas = 0
        for p in placas["placas"]:
            nuevo = colocar(calles, huellas, p["x"], p["z"], p["hx"], p["hz"], 0.8)
            if nuevo is None:
                continue
            if nuevo != (p["x"], p["z"]):
                movidas += 1
                p["x"], p["z"] = nuevo
        guardar(ruta_c, placas)
        print("placas:", len(placas["placas"]), "sacadas de la calzada:", movidas)

    # Paradas y contenedores: rumbo, fuera de la calzada y de edificios
    paradas = cargar(os.path.join(BANCO, "paradas.json"))
    buenas = []
    mov_cal = 0
    for p in paradas["paradas"]:
        ox, oz = p["x"], p["z"]
        p["hx"], p["hz"] = rumbo(ox, oz)
        corr = colocar(calles, huellas, ox, oz, p["hx"], p["hz"], 1.7)
        if corr is None:
            print("parada sin hueco válido (calzada/edificio), descartada:", p["n"], ox, oz)
            continue
        if corr != (ox, oz):
            mov_cal += 1
            p["x"], p["z"] = corr
        p["hx"], p["hz"] = rumbo(p["x"], p["z"])
        buenas.append(p)
    paradas["paradas"] = buenas
    guardar(os.path.join(CIUDAD, "paradas.json"), paradas)
    print("paradas:", len(buenas), "sacadas de la calzada:", mov_cal)

    contenedores = cargar(os.path.join(BANCO, "contenedores.json"))
    buenos = []
    mov_cal = 0
    for c in contenedores["contenedores"]:
        ox, oz = c["x"], c["z"]
        c["hx"], c["hz"] = rumbo(ox, oz)
        corr = colocar(calles, huellas, ox, oz, c["hx"], c["hz"], 1.4)
        if corr is None:
            print("contenedor sin hueco válido (calzada/edificio), descartado:", ox, oz)
            continue
        if corr != (ox, oz):
            mov_cal += 1
            c["x"], c["z"] = corr
        c["hx"], c["hz"] = rumbo(c["x"], c["z"])
        buenos.append(c)
    contenedores["contenedores"] = buenos
    guardar(os.path.join(CIUDAD, "contenedores.json"), contenedores)
    print("contenedores:", len(buenos), "sacadas de la calzada:", mov_cal)


if __name__ == "__main__":
    main()
