#!/usr/bin/env python3
"""Detecta portales «encerrados»: puertas a las que no se puede llegar
andando desde el espacio público porque los edificios las cercan
(bolsillos tras manzanas cerradas, patios de servicio, traseras de
grandes equipamientos). Un encargo a uno de estos portales parece
bloqueado desde casi cualquier lado.

Método (inverso): inundación en rejilla de 2 m sobre una caja de
±90 m, sembrada desde el borde de la caja y desde las calles de
vehículos, con los polígonos de edificios como obstáculos (celda
bloqueada si su centro está a menos de 0,45 m de un polígono, como la
colisión del juego). El portal es VÁLIDO si la inundación alcanza
alguna celda a menos de 5 m del portal (la distancia a la que el
juego da por llegado un encargo). Si no, va a la lista de excluidos.

Salida: juego/datos/ciudad/portales_no.json (índices sobre
portales.json) y un informe por consola.
"""
import json, glob, math
from collections import deque

BASE = "/home/hatch/workspace/logrono-juego/juego/datos/ciudad"
PASO = 2.0
MITAD = 90.0
N = int(2 * MITAD / PASO)  # 90 celdas por lado
RADIO = 0.45
ALCANCE = 5.0
MOTOR = {"primary", "secondary", "tertiary", "residential", "unclassified",
         "living_street", "primary_link", "secondary_link", "tertiary_link"}

polys = []
hash_c = {}  # puntos de calles motor, hash de 20 m
for f in glob.glob(BASE + "/tiles/*.json"):
    d = json.load(open(f))
    for e in d["e"]:
        poly = [(e[i], e[i + 1]) for i in range(1, len(e) - 1, 2)]
        xs = [p[0] for p in poly]
        zs = [p[1] for p in poly]
        polys.append((min(xs), min(zs), max(xs), max(zs), poly))
    for c in d["c"]:
        if c["c"] in MOTOR:
            pts = c["p"]
            for i in range(len(pts) - 1):
                ax, az = pts[i]
                bx, bz = pts[i + 1]
                dist = math.hypot(bx - ax, bz - az)
                pasos = max(1, int(dist / 2.0))
                for k in range(pasos + 1):
                    x = ax + (bx - ax) * k / pasos
                    z = az + (bz - az) * k / pasos
                    hash_c.setdefault((int(math.floor(x / 20.0)), int(math.floor(z / 20.0))), []).append((x, z))
print("polígonos:", len(polys), "celdas de calle:", len(hash_c), flush=True)

CELDAH = 100.0
hash_p = {}
for idx, (mnx, mnz, mxx, mxz, _p) in enumerate(polys):
    for cx in range(int(math.floor((mnx - RADIO) / CELDAH)), int(math.floor((mxx + RADIO) / CELDAH)) + 1):
        for cz in range(int(math.floor((mnz - RADIO) / CELDAH)), int(math.floor((mxz + RADIO) / CELDAH)) + 1):
            hash_p.setdefault((cx, cz), []).append(idx)

def dentro_poly(px, pz, poly):
    ins = False
    n = len(poly)
    for i in range(n):
        x1, z1 = poly[i]
        x2, z2 = poly[(i + 1) % n]
        if (z1 > pz) != (z2 > pz):
            if px < x1 + (pz - z1) * (x2 - x1) / (z2 - z1):
                ins = not ins
    return ins

def dist_poly(px, pz, poly):
    if dentro_poly(px, pz, poly):
        return 0.0
    m = 1e18
    n = len(poly)
    for i in range(n):
        ax, az = poly[i]
        bx, bz = poly[(i + 1) % n]
        dx, dz = bx - ax, bz - az
        l2 = dx * dx + dz * dz
        t = 0.0 if l2 == 0 else max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / l2))
        m = min(m, math.hypot(px - (ax + t * dx), pz - (az + t * dz)))
    return m

def es_valido(px, pz):
    ox, oz = px - MITAD, pz - MITAD
    grid = bytearray(N * N)
    claves = set()
    for cx in range(int(math.floor((px - MITAD) / CELDAH)), int(math.floor((px + MITAD) / CELDAH)) + 1):
        for cz in range(int(math.floor((pz - MITAD) / CELDAH)), int(math.floor((pz + MITAD) / CELDAH)) + 1):
            claves.update(hash_p.get((cx, cz), []))
    for idx in claves:
        mnx, mnz, mxx, mxz, poly = polys[idx]
        gx0 = max(0, int((mnx - RADIO - ox) / PASO))
        gx1 = min(N - 1, int((mxx + RADIO - ox) / PASO))
        gz0 = max(0, int((mnz - RADIO - oz) / PASO))
        gz1 = min(N - 1, int((mxz + RADIO - oz) / PASO))
        for gz in range(gz0, gz1 + 1):
            for gx in range(gx0, gx1 + 1):
                if grid[gz * N + gx]:
                    continue
                x = ox + (gx + 0.5) * PASO
                z = oz + (gz + 0.5) * PASO
                if dist_poly(x, z, poly) < RADIO:
                    grid[gz * N + gx] = 1
    visit = bytearray(N * N)
    dq = deque()

    def semilla(gx, gz):
        if 0 <= gx < N and 0 <= gz < N and not visit[gz * N + gx] and not grid[gz * N + gx]:
            visit[gz * N + gx] = 1
            dq.append((gx, gz))

    for g in range(N):
        semilla(g, 0)
        semilla(g, N - 1)
        semilla(0, g)
        semilla(N - 1, g)
    for cx in range(int(math.floor(ox / 20.0)), int(math.floor((ox + 2 * MITAD) / 20.0)) + 1):
        for cz in range(int(math.floor(oz / 20.0)), int(math.floor((oz + 2 * MITAD) / 20.0)) + 1):
            for (sx, sz) in hash_c.get((cx, cz), []):
                semilla(int((sx - ox) / PASO), int((sz - oz) / PASO))
    while dq:
        gx, gz = dq.popleft()
        wx = ox + (gx + 0.5) * PASO
        wz = oz + (gz + 0.5) * PASO
        if (wx - px) ** 2 + (wz - pz) ** 2 < ALCANCE * ALCANCE:
            return True
        for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            nx, nz = gx + dx, gz + dz
            if 0 <= nx < N and 0 <= nz < N and not visit[nz * N + nx] and not grid[nz * N + nx]:
                visit[nz * N + nx] = 1
                dq.append((nx, nz))
    return False

portales = json.load(open(BASE + "/portales.json"))["portales"]
# Exclusiones manuales verificadas en partida real (22-nov-2026): los 5
# portales de la calle San Bernabé (índices 3127-3131) dan a una calle
# estrecha en diagonal entre dos manzanas cerradas junto a la plaza de
# toros; la ruta guía mal y el acceso en coche es impracticable. Jon no
# pudo completar un encargo al nº 2 ni a pie ni en coche.
EXTRA_MANUAL = {3127, 3128, 3129, 3130, 3131}
excluidos = []
for i, p in enumerate(portales):
    if not es_valido(float(p["x"]), float(p["z"])):
        excluidos.append(i)
    if i % 1000 == 0:
        print("  %d/%d excluidos=%d" % (i, len(portales), len(excluidos)), flush=True)
        json.dump(excluidos, open(BASE + "/portales_no.json", "w"))

excluidos = sorted(set(excluidos) | EXTRA_MANUAL)
json.dump(excluidos, open(BASE + "/portales_no.json", "w"))
print("TOTAL portales:", len(portales), "excluidos:", len(excluidos))
for i in excluidos[:25]:
    p = portales[i]
    print("  -", i, p["calle"], p["numero"], p["x"], p["z"])
sb = [i for i, p in enumerate(portales) if p["calle"] == "CL SAN BERNABE" and str(p["numero"]) == "2"]
print("San Bernabé 2 índice:", sb, "excluido:", bool(sb and sb[0] in excluidos))
