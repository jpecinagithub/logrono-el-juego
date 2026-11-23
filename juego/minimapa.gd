extends Control
## Minimapa circular de la esquina superior derecha: calles, río, ruta
## al encargo (azul), destino (naranja), lugares (dorado), tu coche
## (rojo) y tú (triángulo blanco en el centro, girado a tu rumbo).
## El norte va arriba. El guion principal le pasa los datos con
## actualizar(); al tocarlo se emite «pulsado» y el principal abre
## el mapa grande. Todo se dibuja por código, sin imágenes externas.

signal pulsado

var _datos := {}
var _carr_cache := {}

func actualizar(datos: Dictionary) -> void:
	_datos = datos
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		pulsado.emit()
	elif event is InputEventScreenTouch and event.pressed:
		pulsado.emit()

func _a_pantalla(mundo: Vector2, centro: Vector2, escala: float) -> Vector2:
	var j: Vector2 = _datos["jugador"]
	return centro + Vector2(mundo.x - j.x, mundo.y - j.y) * escala

func _draw() -> void:
	if _datos.is_empty():
		return
	var centro := size * 0.5
	var radio := size.x * 0.5 - 4.0
	var escala := radio / 170.0  # se ven unos 170 m alrededor
	var jug: Vector2 = _datos["jugador"]
	draw_circle(centro, radio, Color(0.11, 0.12, 0.16, 0.96))
	# En carrera, el disco entero es el plano del circuito
	var carr = _datos.get("carrera", null)
	if carr != null:
		_dibujar_carrera(centro, radio, carr)
		return
	# Río Ebro
	var rio: Array = _datos.get("rio", [])
	for i in range(rio.size() - 1):
		_tramo(Vector2(float(rio[i][0]), float(rio[i][1])), Vector2(float(rio[i + 1][0]), float(rio[i + 1][1])), centro, escala, radio, Color(0.25, 0.50, 0.85), 7.0)
	# Calles (se saltan los tramos lejanos: son miles)
	var col_calle := Color(0.52, 0.55, 0.62)
	for calle in _datos.get("calles", []):
		var pts: Array = calle
		for i in range(pts.size() - 1):
			var a := Vector2(float(pts[i][0]), float(pts[i][1]))
			var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			if a.distance_to(jug) > 300.0 and b.distance_to(jug) > 300.0:
				continue
			_tramo(a, b, centro, escala, radio, col_calle, 2.0)
	# Ruta al encargo
	var ruta: Array = _datos.get("ruta", [])
	for i in range(ruta.size() - 1):
		var r1: Vector3 = ruta[i]
		var r2: Vector3 = ruta[i + 1]
		_tramo(Vector2(r1.x, r1.z), Vector2(r2.x, r2.z), centro, escala, radio, Color(0.30, 0.85, 0.95), 3.0)
	# Lugares destacados
	for poi in _datos.get("pois", []):
		var pp := _a_pantalla(Vector2(float(poi["x"]), float(poi["z"])), centro, escala)
		if pp.distance_to(centro) < radio - 6.0:
			draw_circle(pp, 3.5, Color(1.0, 0.78, 0.2))
	# Destino: si queda fuera del disco, se pega al borde en su dirección
	if _datos.get("destino") != null:
		var pd := _a_pantalla(_datos["destino"], centro, escala)
		var d := pd - centro
		if d.length() > radio - 12.0:
			pd = centro + d.normalized() * (radio - 12.0)
		draw_circle(pd, 7.0, Color(1.0, 0.55, 0.1))
		draw_arc(pd, 7.0, 0.0, TAU, 24, Color(1, 1, 1), 2.0)
	# Tu coche, si vas a pie
	if not bool(_datos.get("en_coche", false)):
		var pc := _a_pantalla(_datos["coche"], centro, escala)
		if pc.distance_to(centro) < radio - 6.0:
			draw_circle(pc, 4.5, Color(0.90, 0.20, 0.16))
	# Tú: triángulo blanco en el centro, girado a tu rumbo
	var rumbo := float(_datos.get("rumbo", 0.0))
	var dirp := Vector2(sin(rumbo), cos(rumbo))
	var perp := Vector2(-dirp.y, dirp.x)
	var punta := centro + dirp * 10.0
	var tras_i := centro - dirp * 7.0 + perp * 6.0
	var tras_d := centro - dirp * 7.0 - perp * 6.0
	draw_colored_polygon(PackedVector2Array([punta, tras_i, tras_d]), Color(1, 1, 1))
	# Anillo exterior y letra del norte
	draw_arc(centro, radio - 2.0, 0.0, TAU, 72, Color(0.88, 0.90, 0.94), 4.0)
	var pn := centro + Vector2(0, -radio + 16.0)
	draw_circle(pn, 11.0, Color(0.10, 0.22, 0.48))
	var fuente := get_theme_default_font()
	draw_string(fuente, pn + Vector2(-5.5, 6.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(1, 1, 1))

func _dibujar_carrera(centro: Vector2, radio: float, carr: Dictionary) -> void:
	# Plano del circuito: calles y río de fondo para situarse, el
	# recorrido en blanco grueso, los puntos de control y cada
	# participante en su color, en vivo.
	var pts: Array = carr["puntos"]
	if pts.size() < 2:
		return
	var minp := Vector2(1e9, 1e9)
	var maxp := Vector2(-1e9, -1e9)
	for p in pts:
		minp = minp.min(p)
		maxp = maxp.max(p)
	minp = minp.min(carr["yo"])
	maxp = maxp.max(carr["yo"])
	for r in carr["rivales"]:
		minp = minp.min(r["p"])
		maxp = maxp.max(r["p"])
	if carr["ghost"] != null:
		minp = minp.min(carr["ghost"])
		maxp = maxp.max(carr["ghost"])
	var cc := (minp + maxp) * 0.5
	var ext := maxf(maxf((maxp.x - minp.x) * 0.5, (maxp.y - minp.y) * 0.5), 1.0)
	var esc := (radio - 20.0) / ext
	# Las calles de fondo se filtran una vez por circuito y se
	# cachean; en circuitos enormes solo va el río (a esa escala
	# las calles serían ruido).
	var clave := str(pts.size()) + ":" + str(int(cc.x)) + ":" + str(int(cc.y))
	if _carr_cache.get("clave", "") != clave:
		var tramos: Array = []
		if ext <= 900.0:
			for calle in _datos.get("calles", []):
				var cp: Array = calle
				for i in range(cp.size() - 1):
					var a := Vector2(float(cp[i][0]), float(cp[i][1]))
					var b := Vector2(float(cp[i + 1][0]), float(cp[i + 1][1]))
					var m := (a + b) * 0.5
					if absf(m.x - cc.x) <= ext + 60.0 and absf(m.y - cc.y) <= ext + 60.0:
						tramos.append([a, b])
		_carr_cache = {"clave": clave, "tramos": tramos}
	for t in _carr_cache["tramos"]:
		draw_line(centro + (t[0] - cc) * esc, centro + (t[1] - cc) * esc, Color(0.38, 0.40, 0.46, 0.75), 1.3)
	var rio: Array = _datos.get("rio", [])
	for i in range(rio.size() - 1):
		var a := Vector2(float(rio[i][0]), float(rio[i][1]))
		var b := Vector2(float(rio[i + 1][0]), float(rio[i + 1][1]))
		var m := (a + b) * 0.5
		if absf(m.x - cc.x) <= ext + 60.0 and absf(m.y - cc.y) <= ext + 60.0:
			draw_line(centro + (a - cc) * esc, centro + (b - cc) * esc, Color(0.25, 0.50, 0.85, 0.8), 3.5)
	for pc in [[7.5, Color(0.02, 0.02, 0.03, 0.65)], [4.5, Color(0.95, 0.96, 0.98)]]:
		for i in range(pts.size() - 1):
			draw_line(centro + (pts[i] - cc) * esc, centro + (pts[i + 1] - cc) * esc, pc[1], pc[0])
	var cps: Array = carr["cps"]
	for i in cps.size():
		var pp: Vector2 = centro + (Vector2(cps[i]) - cc) * esc
		if i == 0:
			draw_circle(pp, 6.0, Color(0.25, 0.85, 0.35))
			draw_arc(pp, 6.0, 0.0, TAU, 20, Color(1, 1, 1), 2.0)
		elif i == int(carr["sig"]):
			draw_circle(pp, 5.5, Color(1.0, 0.55, 0.1))
			draw_arc(pp, 5.5, 0.0, TAU, 20, Color(1, 1, 1), 1.5)
		else:
			draw_circle(pp, 3.5, Color(0.80, 0.82, 0.86))
	if carr["ghost"] != null:
		draw_circle(centro + (carr["ghost"] - cc) * esc, 6.0, Color(0.45, 0.85, 1.0, 0.55))
	for r in carr["rivales"]:
		var pr: Vector2 = centro + (Vector2(r["p"]) - cc) * esc
		draw_circle(pr, 6.0, r["c"])
		draw_arc(pr, 6.0, 0.0, TAU, 20, Color(1, 1, 1), 2.0)
	var py: Vector2 = centro + (Vector2(carr["yo"]) - cc) * esc
	draw_circle(py, 8.0, Color(1.0, 0.78, 0.2))
	draw_arc(py, 8.0, 0.0, TAU, 24, Color(1, 1, 1), 2.5)
	draw_arc(centro, radio - 2.0, 0.0, TAU, 72, Color(0.88, 0.90, 0.94), 4.0)
	var pn := centro + Vector2(0, -radio + 16.0)
	draw_circle(pn, 11.0, Color(0.10, 0.22, 0.48))
	draw_string(get_theme_default_font(), pn + Vector2(-5.5, 6.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(1, 1, 1))

func _tramo(a: Vector2, b: Vector2, centro: Vector2, escala: float, radio: float, color: Color, ancho: float) -> void:
	# Dibuja el tramo en pasos cortos y solo lo que cae dentro del disco
	var pasos := maxi(1, int(a.distance_to(b) / 12.0))
	var prev := a
	for k in range(1, pasos + 1):
		var p := a.lerp(b, float(k) / float(pasos))
		var pa := _a_pantalla(prev, centro, escala)
		var pb := _a_pantalla(p, centro, escala)
		if pa.distance_to(centro) < radio - 2.0 or pb.distance_to(centro) < radio - 2.0:
			draw_line(pa, pb, color, ancho)
		prev = p
