#!/usr/bin/env python3
"""Grafo navegable de calles del barrio piloto desde calles.json:
nodos = puntos únicos de las polilíneas, aristas = tramos consecutivos.
Verifica que exista ruta entre el entorno de Miguel Villanueva 1 y
Calle Portales 14 (Dijkstra) antes de pasarlo al juego.
Salida: juego/datos/grafo_calles.json
"""
import json, math, heapq
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
calles = json.loads((BASE / "juego/datos/calles.json").read_text())["calles"]
portales = json.loads((BASE / "juego/datos/portales.json").read_text())["portales"]

nodos = []
indice = {}
aristas = []

def nodo_id(x, z):
    clave = (round(x, 1), round(z, 1))
    if clave not in indice:
        indice[clave] = len(nodos)
        nodos.append([clave[0], clave[1]])
    return indice[clave]

for c in calles:
    pts = c["puntos"]
    for i in range(len(pts) - 1):
        a = nodo_id(pts[i][0], pts[i][1])
        b = nodo_id(pts[i + 1][0], pts[i + 1][1])
        if a != b:
            aristas.append([a, b])

print("nodos:", len(nodos), "aristas:", len(aristas))

# Adyacencia + Dijkstra de comprobación
ady = {}
for a, b in aristas:
    d = math.dist(nodos[a], nodos[b])
    ady.setdefault(a, []).append((b, d))
    ady.setdefault(b, []).append((a, d))

def mas_cercano(x, z):
    return min(range(len(nodos)), key=lambda i: math.dist(nodos[i], (x, z)))

def dijkstra(s, t):
    dist = {s: 0.0}
    prev = {}
    pq = [(0.0, s)]
    while pq:
        d, u = heapq.heappop(pq)
        if u == t:
            break
        if d > dist.get(u, 1e18):
            continue
        for v, w in ady.get(u, []):
            nd = d + w
            if nd < dist.get(v, 1e18):
                dist[v] = nd
                prev[v] = u
                heapq.heappush(pq, (nd, v))
    if t not in dist:
        return None, None
    ruta = [t]
    while ruta[-1] != s:
        ruta.append(prev[ruta[-1]])
    return dist[t], ruta[::-1]

pa = next(p for p in portales if "VILLANUEVA" in p["calle"] and p["numero"] == "1")
pb = next(p for p in portales if p["calle"] == "CL PORTALES" and p["numero"] == "14")
na, nb = mas_cercano(pa["x"], pa["z"]), mas_cercano(pb["x"], pb["z"])
print("nodo cercano a A:", na, nodos[na], "| a B:", nb, nodos[nb])
d, ruta = dijkstra(na, nb)
print("ruta A->B por calles:", None if d is None else f"{d:.0f} m en {len(ruta)} nodos")

salida = {"nodos": nodos, "aristas": aristas}
(BASE / "juego/datos/grafo_calles.json").write_text(json.dumps(salida), encoding="utf-8")
print("OK -> juego/datos/grafo_calles.json")
