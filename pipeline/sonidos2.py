#!/usr/bin/env python3
"""Fase 8: banco de sonido ampliado, todo sintetizado por código (sin
ficheros externos), igual que la Fase 5.1. Genera los .wav nuevos en
juego/audio/. Los bucles llevan fundido cruzado al final para que el
corte no se oiga."""
import math
import random
import struct
import wave
from pathlib import Path

SR = 22050
SAL = Path(__file__).resolve().parent.parent / "juego" / "audio"
SAL.mkdir(parents=True, exist_ok=True)
rng = random.Random(1234)


def guarda(nombre, muestras):
    datos = bytearray()
    for m in muestras:
        v = max(-1.0, min(1.0, m))
        datos += struct.pack("<h", int(v * 32767))
    with wave.open(str(SAL / nombre), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(datos))
    print(nombre, "%.2f s" % (len(muestras) / SR))


def ruido(n, semilla):
    r = random.Random(semilla)
    return [r.uniform(-1, 1) for _ in range(n)]


def pasa_bajos(x, alfa):
    y = []
    acc = 0.0
    for v in x:
        acc += alfa * (v - acc)
        y.append(acc)
    return y


def fundido_bucle(x, ms=400):
    n = int(SR * ms / 1000)
    for i in range(n):
        f = i / n
        x[i] = x[i] * f + x[len(x) - n + i] * (1 - f)
    return x[: len(x) - n]


def env(t, a, d, total):
    if t < a:
        return t / a
    return max(0.0, 1.0 - (t - a) / max(0.001, total - a)) ** d


# ---------- efectos cortos ----------
def arranque():
    n = int(SR * 0.95)
    out = []
    for i in range(n):
        t = i / SR
        if t < 0.55:  # motor de arranque: pulsos graves
            pulso = 1.0 if (t * 9) % 1.0 < 0.55 else 0.25
            v = math.sin(2 * math.pi * 52 * t) * 0.5 * pulso + math.sin(2 * math.pi * 104 * t) * 0.18 * pulso
            out.append(v * env(t, 0.02, 0.6, 0.6))
        else:  # el motor cobra vida
            f = 70 + (t - 0.55) * 160
            out.append((math.sin(2 * math.pi * f * t) * 0.42 + math.sin(2 * math.pi * f * 2 * t) * 0.12) * env(t - 0.55, 0.03, 0.8, 0.4))
    return out


def puerta(grave):
    n = int(SR * 0.30)
    base = ruido(n, 7 if grave else 8)
    base = pasa_bajos(base, 0.10 if grave else 0.16)
    out = []
    for i in range(n):
        t = i / SR
        golpe = math.sin(2 * math.pi * (68 if grave else 92) * t) * math.exp(-t * 16)
        out.append((base[i] * 0.5 * math.exp(-t * 11) + golpe * 0.8))
    return out


def bocina(gain, lejana):
    n = int(SR * 0.42)
    out = []
    for i in range(n):
        t = i / SR
        v = (math.sin(2 * math.pi * 370 * t) + math.sin(2 * math.pi * 440 * t)) * 0.30
        out.append(v * gain * env(t, 0.015, 0.4, 0.42))
    if lejana:
        out = pasa_bajos(out, 0.25)
    return out


def frenada():
    n = int(SR * 1.0)
    base = pasa_bajos(ruido(n, 21), 0.5)
    out = []
    for i in range(n):
        t = i / SR
        chillido = math.sin(2 * math.pi * (950 - 420 * t) * t) * 0.16
        out.append((base[i] * 0.35 + chillido) * env(t, 0.05, 0.7, 1.0))
    return out


def paso(tipo):
    n = int(SR * 0.11)
    base = pasa_bajos(ruido(n, {"asfalto": 31, "acera": 32, "hierba": 33}[tipo]), 0.06 if tipo != "hierba" else 0.20)
    f0 = {"asfalto": 105, "acera": 88, "hierba": 60}[tipo]
    out = []
    for i in range(n):
        t = i / SR
        f = f0 - 34 * (t / 0.11)
        golpe = math.sin(2 * math.pi * f * t) * math.exp(-t * 30)
        out.append(golpe * 0.75 + base[i] * (0.25 if tipo == "hierba" else 0.12) * math.exp(-t * 18))
    return out


def radar():
    n = int(SR * 0.35)
    out = []
    for i in range(n):
        t = i / SR
        v = 0.0
        if t < 0.03:
            v += (1 - t / 0.03) * 0.5
        if 0.06 < t < 0.20:
            v += math.sin(2 * math.pi * 2093 * t) * 0.30 * env(t - 0.06, 0.005, 1.4, 0.14)
        out.append(v)
    return out


def timbre():
    n = int(SR * 0.55)
    out = []
    for i in range(n):
        t = i / SR
        v = 0.0
        for ini in (0.0, 0.22):
            if t >= ini:
                tt = t - ini
                v += (math.sin(2 * math.pi * 1568 * tt) + 0.4 * math.sin(2 * math.pi * 3136 * tt)) * 0.3 * math.exp(-tt * 7)
        out.append(v)
    return out


def aviso():
    n = int(SR * 0.32)
    out = []
    for i in range(n):
        t = i / SR
        f = 880 if t < 0.14 else 1174
        out.append(math.sin(2 * math.pi * f * t) * 0.26 * env(t, 0.01, 0.9, 0.32))
    return out


def monedas():
    n = int(SR * 0.45)
    out = [0.0] * n
    for k, ini in enumerate((0.0, 0.07, 0.15, 0.26)):
        f = (2093, 2637, 2349, 3136)[k % 4]
        for i in range(int(SR * ini), n):
            t = (i - int(SR * ini)) / SR
            out[i] += math.sin(2 * math.pi * f * t) * 0.22 * math.exp(-t * 16)
    return out


def papel():
    n = int(SR * 0.35)
    base = ruido(n, 41)
    out = []
    acc = 0.0
    for i in range(n):
        t = i / SR
        acc += 0.65 * (base[i] - acc)
        crujido = base[i] - acc  # pasa-altos casero
        mod = 0.5 + 0.5 * math.sin(2 * math.pi * 13 * t)
        out.append(crujido * 0.30 * mod * env(t, 0.03, 0.8, 0.35))
    return out


# ---------- ambientes por zonas (bucles) ----------
def rio():
    n = SR * 8
    base = pasa_bajos(ruido(n, 51), 0.08)
    base2 = pasa_bajos(ruido(n, 52), 0.30)
    out = []
    for i in range(n):
        t = i / SR
        lfo = 0.75 + 0.25 * math.sin(2 * math.pi * t / 8.0 * 3)
        out.append((base[i] * 0.55 + base2[i] * 0.16) * lfo)
    return fundido_bucle(out)


def centro():
    n = SR * 8
    base = pasa_bajos(ruido(n, 61), 0.05)
    out = [b * 0.20 for b in base]
    r = random.Random(62)
    for _ in range(46):  # murmullo: ráfagas cortas de tono vocal, ininteligibles
        ini = r.uniform(0, 7.6)
        f = r.uniform(280, 850)
        dur = r.uniform(0.10, 0.30)
        for i in range(int(SR * ini), min(n, int(SR * (ini + dur)))):
            t = (i - int(SR * ini)) / SR
            out[i] += math.sin(2 * math.pi * f * (1 + 0.06 * math.sin(2 * math.pi * 7 * t)) * t) * 0.055 * math.sin(math.pi * t / dur)
    return fundido_bucle(out)


def viento():
    n = SR * 8
    base = pasa_bajos(ruido(n, 71), 0.03)
    out = []
    for i in range(n):
        t = i / SR
        lfo = 0.55 + 0.45 * math.sin(2 * math.pi * t / 8.0)
        out.append(base[i] * 0.85 * lfo)
    return fundido_bucle(out)


def parque():
    n = SR * 8
    base = pasa_bajos(ruido(n, 81), 0.04)
    out = [b * 0.10 for b in base]
    r = random.Random(82)
    for _ in range(15):  # cantos: barridos cortos de frecuencia
        ini = r.uniform(0, 7.5)
        f0 = r.uniform(2300, 3200)
        f1 = f0 + r.uniform(400, 1100)
        dur = r.uniform(0.12, 0.28)
        fase = 0.0
        for i in range(int(SR * ini), min(n, int(SR * (ini + dur)))):
            t = (i - int(SR * ini)) / SR
            f = f0 + (f1 - f0) * (t / dur)
            fase += 2 * math.pi * f / SR
            out[i] += math.sin(fase) * 0.11 * math.sin(math.pi * t / dur)
    return fundido_bucle(out)


# ---------- música (composición propia, bucles) ----------
NOTAS = {"C": 130.81, "D": 146.83, "E": 164.81, "F": 174.61, "G": 196.0, "A": 220.0, "B": 246.94,
         "C5": 261.63, "E5": 329.63, "G5": 392.0, "A5": 440.0, "F5": 349.23, "D5": 293.66, "B4": 246.94}


def pad(out, ini, dur, freqs, gain):
    for i in range(int(SR * ini), min(len(out), int(SR * (ini + dur)))):
        t = (i - int(SR * ini)) / SR
        e = min(1.0, t / 0.4) * min(1.0, (dur - t) / 0.4)
        for f in freqs:
            out[i] += math.sin(2 * math.pi * f * t) * gain * e / len(freqs)


def nota(out, ini, dur, f, gain, tipo="seno"):
    for i in range(int(SR * ini), min(len(out), int(SR * (ini + dur)))):
        t = (i - int(SR * ini)) / SR
        e = math.exp(-t * 3.2)
        v = math.sin(2 * math.pi * f * t)
        if tipo == "tri":
            v = 2 * abs(2 * (f * t % 1) - 1) - 1
        out[i] += v * gain * e


def musica_menu():
    n = SR * 12
    out = [0.0] * n
    acordes = [("C", "E", "G"), ("G", "B", "D5"), ("A", "C5", "E5"), ("F", "A", "C5")]
    for k, ac in enumerate(acordes):
        pad(out, k * 3.0, 3.0, [NOTAS[x] for x in ac], 0.30)
        for j, x in enumerate(ac):
            nota(out, k * 3.0 + 0.5 + j * 0.75, 0.7, NOTAS[x] * 2, 0.10, "tri")
    return fundido_bucle(out, 300)


def musica_coche():
    n = SR * 12
    out = [0.0] * n
    acordes = [("A", "C5", "E5"), ("F", "A", "C5"), ("C", "E", "G"), ("G", "B", "D5")]
    graves = [55.0, 43.65, 65.41, 49.0]
    for k, ac in enumerate(acordes):
        ini = k * 3.0
        for b in range(6):  # bajo a negras con octava
            nota(out, ini + b * 0.5, 0.30, graves[k] * (2 if b % 2 else 1), 0.34)
        for b in range(4):  # acordes cortos
            pad(out, ini + b * 0.75 + 0.375, 0.22, [NOTAS[x] * 2 for x in ac], 0.16)
        for b in range(12):  # sombrero: ticks de ruido
            ii = int(SR * (ini + b * 0.25))
            for j in range(300):
                if ii + j < n:
                    out[ii + j] += rng.uniform(-1, 1) * 0.05 * (1 - j / 300)
    return fundido_bucle(out, 300)


guarda("arranque.wav", arranque())
guarda("puerta_abrir.wav", puerta(False))
guarda("puerta_cerrar.wav", puerta(True))
guarda("bocina.wav", bocina(0.85, False))
guarda("bocina_lejana.wav", bocina(0.4, True))
guarda("frenada.wav", frenada())
guarda("paso_asfalto.wav", paso("asfalto"))
guarda("paso_acera.wav", paso("acera"))
guarda("paso_hierba.wav", paso("hierba"))
guarda("radar.wav", radar())
guarda("timbre.wav", timbre())
guarda("aviso.wav", aviso())
guarda("monedas.wav", monedas())
guarda("papel.wav", papel())
guarda("rio.wav", rio())
guarda("centro.wav", centro())
guarda("viento.wav", viento())
guarda("parque.wav", parque())
guarda("musica_menu.wav", musica_menu())
guarda("musica_coche.wav", musica_coche())
print("banco generado")
