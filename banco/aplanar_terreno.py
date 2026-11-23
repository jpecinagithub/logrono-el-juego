#!/usr/bin/env python3
"""Aplana el ruido de corto alcance de la rejilla de terreno.

La rejilla viene del MDT del IGN a 20 m de paso: entre celdas vecinas
hay saltos de 1-4 m (y picos de hasta 28 m) que en el juego se ven
como altibajos y cuñas cruzando las calles, cuando Logroño es en la
práctica plano salvo la terraza del Ebro y los bordes.

Qué hace, en orden:
1. Despicado: cada celda que se desvía más de 2,5 m de la mediana de
   su vecindad 3x3 se sustituye por esa mediana (fuera picos de
   edificio/dato erróneo sin tocar la pendiente general).
2. Suavizado: desenfoque gaussiano separable de sigma 3 celdas
   (60 m), dos pasadas. Mata la longitud de onda corta y media
   (20-300 m, que es la que se ve como altibajos en las calles) y
   conserva la geografía ancha: la bajada norte hacia el Ebro
   (300 m de terraza) y la subida de los bordes.

Todo lo demás del juego (edificios, puentes, personajes) lee la
altura de esta misma rejilla en tiempo de ejecución, así que el
mundo entero se asienta sobre el terreno nuevo sin descuadres.

Uso: python3 banco/aplanar_terreno.py
"""
import json
import math
import statistics
import sys

RUTA = "juego/datos/ciudad/terreno.json"


def stats(A, cols, rows, etiqueta):
    difs = []
    for j in range(rows - 1):
        for i in range(cols - 1):
            a = A[j * cols + i]
            difs.append(abs(A[j * cols + i + 1] - a))
            difs.append(abs(A[(j + 1) * cols + i] - a))
    difs.sort()
    print(f"{etiqueta}: dif vecino media={statistics.mean(difs):.3f} "
          f"p95={difs[int(len(difs) * 0.95)]:.2f} max={difs[-1]:.2f}")


def altura(A, cols, rows, x0, z0, paso, x, z):
    gx = min(max((x - x0) / paso, 0.0), cols - 1.001)
    gz = min(max((z - z0) / paso, 0.0), rows - 1.001)
    i, j = int(gx), int(gz)
    fx, fz = gx - i, gz - j
    a00 = A[j * cols + i]
    a10 = A[j * cols + i + 1]
    a01 = A[(j + 1) * cols + i]
    a11 = A[(j + 1) * cols + i + 1]
    if fz <= fx:
        return a00 + (a10 - a00) * fx + (a11 - a10) * fz
    return a00 + (a11 - a01) * fx + (a01 - a00) * fz


def main():
    with open(RUTA) as f:
        t = json.load(f)
    cols, rows, paso = t["cols"], t["rows"], t["paso_m"]
    x0, z0 = t["x0_local"], t["z0_local"]
    A = [float(v) for v in t["alturas"]]
    assert len(A) == cols * rows
    stats(A, cols, rows, "antes ")

    def perfil(nombre, pts):
        vals = [round(altura(A, cols, rows, x0, z0, paso, x, z), 1) for x, z in pts]
        print(f"{nombre}: {vals}")

    pts_z180 = [(x, 180) for x in range(-1200, 1201, 200)]
    pts_ebro = [(-150, z) for z in range(-450, 151, 75)]
    perfil("perfil z=180 antes", pts_z180)
    perfil("corte Ebro antes ", pts_ebro)

    # 1) Despicado por mediana 3x3
    B = A[:]
    for j in range(1, rows - 1):
        for i in range(1, cols - 1):
            vec = [A[(j + dj) * cols + (i + di)] for dj in (-1, 0, 1) for di in (-1, 0, 1)]
            med = statistics.median(vec)
            if abs(A[j * cols + i] - med) > 2.5:
                B[j * cols + i] = med
    A = B

    # 2) Gaussiano separable sigma=3 (radio 9), dos pasadas
    sigma = 3.0
    radio = 9
    nucleo = [math.exp(-(k * k) / (2.0 * sigma * sigma)) for k in range(-radio, radio + 1)]
    sn = sum(nucleo)
    nucleo = [v / sn for v in nucleo]
    for _ in range(2):
        # horizontal
        B = A[:]
        for j in range(rows):
            for i in range(cols):
                s = 0.0
                for k in range(-radio, radio + 1):
                    ii = min(max(i + k, 0), cols - 1)
                    s += nucleo[k + radio] * A[j * cols + ii]
                B[j * cols + i] = s
        A = B
        # vertical
        B = A[:]
        for j in range(rows):
            for i in range(cols):
                s = 0.0
                for k in range(-radio, radio + 1):
                    jj = min(max(j + k, 0), rows - 1)
                    s += nucleo[k + radio] * A[jj * cols + i]
                B[j * cols + i] = s
        A = B

    stats(A, cols, rows, "después")
    perfil("perfil z=180 desp.", pts_z180)
    perfil("corte Ebro desp. ", pts_ebro)
    for nombre, x, z in [("Espolón", -260, 180), ("Gran Vía", -450, 130),
                         ("Catedral", -210, 60), ("Parque Ebro", -150, -250),
                         ("Av. Madrid sur", -430, 1500)]:
        print(nombre, round(altura(A, cols, rows, x0, z0, paso, x, z), 2))

    t["alturas"] = [round(v, 2) for v in A]
    with open(RUTA, "w") as f:
        json.dump(t, f, separators=(",", ":"))
    print("escrito", RUTA)


if __name__ == "__main__":
    sys.exit(main())
