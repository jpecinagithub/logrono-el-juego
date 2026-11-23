#!/usr/bin/env python3
# Hornea las pistas de los colegios: replica EXACTAMENTE el escaneo de
# _crear_colegios (rejilla 6 m en +-42 m, 9 puntos de control, partes 'e'
# de las baldosas con pre-filtro bbox +1 m) y escribe colegios_pistas.json
# con los centros elegidos, en el mismo orden que colegios.json.
# Uso: python3 bake_colegios.py <log_con_PISTA_BAKE_o_vacio>
import json, math, sys, os

BASE = os.path.join(os.path.dirname(__file__), "..", "juego", "datos", "ciudad")

def in_poly(px, py, poly):
    # Misma regla que Geometry2D.is_point_in_polygon (par-impar)
    c = False
    n = len(poly)
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if (yi > py) != (yj > py):
            x = (xj - xi) * (py - yi) / (yj - yi) + xi
            if px < x:
                c = not c
        j = i
    return c

# Cargar partes 'e' con bbox (igual que el GDScript)
partes = []
for tx in range(9):
    for ty in range(7):
        ruta = os.path.join(BASE, "tiles", f"t_{tx}_{ty}.json")
        if not os.path.exists(ruta):
            continue
        dj = json.load(open(ruta, encoding="utf-8"))
        if "e" not in dj:
            continue
        for e in dj["e"]:
            xs = [float(e[i]) for i in range(1, len(e) - 1, 2)]
            zs = [float(e[i]) for i in range(2, len(e) - 1, 2)]
            poly = [(float(e[i]), float(e[i + 1])) for i in range(1, len(e) - 1, 2)]
            partes.append((min(xs), min(zs), max(xs), max(zs), poly))
print("partes:", len(partes))

colegios = json.load(open(os.path.join(BASE, "colegios.json"), encoding="utf-8"))["colegios"]
salida = []
total = 0
for col in colegios:
    poly = [(float(p[0]), float(p[1])) for p in col["poly"]]
    cen = (float(col["c"][0]), float(col["c"][1]))
    hechas = []
    gx = -42.0
    while gx <= 42.0 and len(hechas) < 2:
        gz = -42.0
        while gz <= 42.0 and len(hechas) < 2:
            cand = (cen[0] + gx, cen[1] + gz)
            libre = True
            for ok in hechas:
                if math.hypot(cand[0] - ok[0], cand[1] - ok[1]) < 30.0:
                    libre = False
            for ox in (-12.0, 0.0, 12.0):
                for oz in (-7.5, 0.0, 7.5):
                    q = (cand[0] + ox, cand[1] + oz)
                    if not in_poly(q[0], q[1], poly):
                        libre = False
                    for (mnx, mnz, mxx, mxz, epoly) in partes:
                        if q[0] >= mnx - 1.0 and q[0] <= mxx + 1.0 and q[1] >= mnz - 1.0 and q[1] <= mxz + 1.0:
                            if in_poly(q[0], q[1], epoly):
                                libre = False
            if libre:
                hechas.append(cand)
            gz += 6.0
        gx += 6.0
    salida.append([[round(x, 2), round(z, 2)] for (x, z) in hechas])
    total += len(hechas)
    print(col["n"], "->", hechas)

json.dump({"pistas": salida}, open(os.path.join(BASE, "colegios_pistas.json"), "w", encoding="utf-8"))
print("TOTAL pistas horneadas:", total)

# Comparacion con el log nativo (PISTA_BAKE), si se pasa
if len(sys.argv) > 1 and sys.argv[1]:
    nativas = []
    for linea in open(sys.argv[1], encoding="utf-8", errors="replace"):
        if "PISTA_BAKE" in linea:
            trozos = linea.split("PISTA_BAKE", 1)[1].strip().rsplit(" ", 2)
            nativas.append((float(trozos[1]), float(trozos[2])))
    mias = [(x, z) for sub in salida for (x, z) in sub]
    print("nativas:", len(nativas), "mias:", len(mias))
    dif = 0
    for (a, b) in zip(nativas, mias):
        if abs(a[0] - b[0]) > 0.01 or abs(a[1] - b[1]) > 0.01:
            dif += 1
            print("DIFERENCIA:", a, "vs", b)
    print("COINCIDEN" if dif == 0 and len(nativas) == len(mias) else f"NO COINCIDEN (dif={dif})")
