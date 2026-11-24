#!/usr/bin/env python3
# Hornea las fachadas principales de los colegios: para cada
# colegio de colegios.json busca, entre las partes 'e' de las
# baldosas cuyo centroide cae dentro de la parcela, la mayor
# por superficie; de ella toma su arista mas larga y escribe
# {x, z, nx, nz, plantas} (punto medio de la arista, normal
# hacia fuera y plantas) en colegios_fachadas.json, en el
# mismo orden que colegios.json. Si no hay edificio dentro,
# deja null (ese colegio se queda solo con el cartel de la
# puerta). Lo consume _crear_colegios para poner el nombre
# en grande sobre la fachada del edificio principal: en los
# campus grandes la puerta queda a mas de 100 m del edificio
# y el colegio parecia no tener cartel (caso Alcaste).
import json, math, os

BASE = os.path.join(os.path.dirname(__file__), "..", "juego", "datos", "ciudad")


def in_poly(px, py, poly):
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


def area(poly):
    s = 0.0
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        s += x1 * y2 - x2 * y1
    return abs(s) / 2.0


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
            poly = [(float(e[i]), float(e[i + 1])) for i in range(1, len(e) - 1, 2)]
            if len(poly) < 3:
                continue
            cx = sum(p[0] for p in poly) / len(poly)
            cz = sum(p[1] for p in poly) / len(poly)
            xs = [p[0] for p in poly]
            zs = [p[1] for p in poly]
            partes.append((int(e[0]), poly, cx, cz, area(poly),
                           (min(xs), min(zs), max(xs), max(zs))))
print("partes:", len(partes))

colegios = json.load(open(os.path.join(BASE, "colegios.json"), encoding="utf-8"))["colegios"]
salida = []
for col in colegios:
    poly_par = [(float(p[0]), float(p[1])) for p in col["poly"]]
    mejor = None
    for plantas, poly, cx, cz, ar, _bb in partes:
        if in_poly(cx, cz, poly_par):
            if mejor is None or ar > mejor[4]:
                mejor = (plantas, poly, cx, cz, ar)
    if mejor is None:
        salida.append(None)
        print("SIN EDIFICIO:", col["n"])
        continue
    plantas, poly, cx, cz, ar = mejor
    # La arista mas larga de la parte ganadora QUE DE A LA
    # CALLE de verdad: si a 3 m hacia fuera hay otro edificio
    # pegado, esa cara no se ve (paso en Marianistas: el panel
    # quedaba emparedado entre dos pabellones y no se veia).
    n = len(poly)
    aristas = []
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        l = math.hypot(x2 - x1, y2 - y1)
        if l < 0.5:
            continue
        mx0, mz0 = (x1 + x2) / 2.0, (y1 + y2) / 2.0
        dx0, dz0 = (x2 - x1) / l, (y2 - y1) / l
        nx0, nz0 = dz0, -dx0
        if (mx0 - cx) * nx0 + (mz0 - cz) * nz0 < 0:
            nx0, nz0 = -nx0, -nz0
        libre = True
        for dtest in (1.2, 3.0):
            px, pz = mx0 + nx0 * dtest, mz0 + nz0 * dtest
            for _pl, poly2, _cx2, _cz2, _ar2, bb2 in partes:
                if bb2[0] <= px <= bb2[2] and bb2[1] <= pz <= bb2[3] and in_poly(px, pz, poly2):
                    libre = False
                    break
            if not libre:
                break
        aristas.append((l, mx0, mz0, nx0, nz0, libre))
    aristas.sort(key=lambda a: -a[0])
    elegida = None
    for a in aristas:
        if a[5]:
            elegida = a
            break
    if elegida is None:
        elegida = aristas[0]
    _l, mx, mz, nx, nz, _libre = elegida
    salida.append({"x": round(mx, 1), "z": round(mz, 1),
                   "nx": round(nx, 2), "nz": round(nz, 2),
                   "plantas": plantas})
    print(f"{col['n']}: fachada=({mx:.1f},{mz:.1f}) n=({nx:.2f},{nz:.2f}) plantas={plantas} area={ar:.0f}")

# Correcciones verificadas a mano (la arista mas larga no
# siempre es la fachada real del centro):
# - Vuelo Madrid Manila: su direccion oficial es Av. Republica
#   Argentina 54 (web del centro y Gobierno de La Rioja); la
#   arista larga de su edificio mayor mira a Gil de Garate y
#   el juego lo asociaba a esa calle. Se usa su arista sur,
#   la que da a la avenida.
OVERRIDES = {
    "Colegio Vuelo Madrid Manila": {"x": -661.9, "z": 940.5,
                                    "nx": -0.29, "nz": 0.96,
                                    "plantas": 1},
    # Alcaste: la regla de mayor superficie elegia un pabellon
    # bajo de 1 planta en mitad del campus y el cartel no se
    # veia (senalado por Jon el 2026-11-24). Su edificio
    # principal es el de 3 plantas (-667,-1459); se usa su
    # arista sur mas adelantada, la que mira al campus.
    "Colegio Alcaste": {"x": -661.2, "z": -1448.4,
                        "nx": -0.56, "nz": 0.83,
                        "plantas": 3},
}
for i, col in enumerate(colegios):
    if col["n"] in OVERRIDES:
        salida[i] = OVERRIDES[col["n"]]
        print("OVERRIDE:", col["n"])

json.dump({"fachadas": salida},
          open(os.path.join(BASE, "colegios_fachadas.json"), "w", encoding="utf-8"),
          ensure_ascii=False)
print("fachadas:", sum(1 for s in salida if s), "de", len(salida))
