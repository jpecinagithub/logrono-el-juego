extends Control
# Mapa del barrio: calles, río, lugares, ruta al encargo, coche y jugador.
# La ventana del barrio mide 1776 × 1210 m, centrada en (0, 0).

var datos := {}
var _carr_vivo := {}

func mostrar(d: Dictionary) -> void:
	datos = d
	_carr_vivo = datos["carrera"] if datos.get("carrera") != null else {}
	visible = true
	queue_redraw()

func actualizar_carrera(d: Dictionary) -> void:
	_carr_vivo = d
	if visible:
		queue_redraw()

func actualizar_pos(jugador: Vector2, coche: Vector2) -> void:
	if datos.is_empty():
		return
	datos["jugador"] = jugador
	datos["coche"] = coche
	queue_redraw()

func _conv(p, ox: float, oy: float, escala: float) -> Vector2:
	return Vector2(ox + (float(p[0]) + 2700.0) * escala, oy + (float(p[1]) + 2000.0) * escala)

func _conv2(p: Vector2, ox: float, oy: float, escala: float) -> Vector2:
	return Vector2(ox + (p.x + 2700.0) * escala, oy + (p.y + 2000.0) * escala)

func _draw() -> void:
	if datos.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.10, 0.97))
	var escala := minf((size.x - 60.0) / 5400.0, (size.y - 110.0) / 4000.0)
	var ox := (size.x - 5400.0 * escala) * 0.5
	var oy := 70.0 + (size.y - 70.0 - 4000.0 * escala) * 0.5
	var fuente := get_theme_default_font()
	# Calles
	var col_calle := Color(0.45, 0.47, 0.52)
	for calle in datos["calles"]:
		var pts: Array = calle
		for i in range(pts.size() - 1):
			draw_line(_conv(pts[i], ox, oy, escala), _conv(pts[i + 1], ox, oy, escala), col_calle, 1.0)
	# Río Ebro
	var rio: Array = datos["rio"]
	for i in range(rio.size() - 1):
		draw_line(_conv(rio[i], ox, oy, escala), _conv(rio[i + 1], ox, oy, escala), Color(0.25, 0.50, 0.85), 9.0)
	# Tu recorrido en esta sesión
	var rastro: Array = datos["rastro"]
	for i in range(rastro.size() - 1):
		draw_line(_conv2(rastro[i], ox, oy, escala), _conv2(rastro[i + 1], ox, oy, escala), Color(0.55, 0.95, 0.65), 2.5)
	# Ruta al encargo
	var ruta: Array = datos["ruta"]
	for i in range(ruta.size() - 1):
		var r1: Vector3 = ruta[i]
		var r2: Vector3 = ruta[i + 1]
		draw_line(_conv2(Vector2(r1.x, r1.z), ox, oy, escala), _conv2(Vector2(r2.x, r2.z), ox, oy, escala), Color(0.30, 0.85, 0.95), 3.0)
	# Lugares: punto para todos los destacados; nombre solo en los
	# principales (a esta escala, 400 rótulos se pisan unos a otros)
	for poi in datos["pois"]:
		var pp := _conv([poi["x"], poi["z"]], ox, oy, escala)
		draw_circle(pp, 4.0, Color(1.0, 0.78, 0.2))
		if int(poi.get("c", 0)) == 1:
			draw_string(fuente, pp + Vector2(7, 4), String(poi["n"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.95, 0.90, 0.70))
	# Destino del encargo
	if datos["destino"] != null:
		var pd := _conv2(datos["destino"], ox, oy, escala)
		draw_circle(pd, 8.0, Color(1.0, 0.55, 0.1))
		draw_circle(pd, 8.0, Color(1, 1, 1), false, 2.0)
	# Coche y jugador
	draw_circle(_conv2(datos["coche"], ox, oy, escala), 5.0, Color(0.90, 0.20, 0.16))
	var pj := _conv2(datos["jugador"], ox, oy, escala)
	draw_circle(pj, 6.0, Color(1, 1, 1))
	draw_circle(pj, 6.0, Color(0.10, 0.20, 0.45), false, 2.0)
	# Carrera en curso: recorrido y participantes en vivo
	var carr = datos.get("carrera", null)
	if carr != null:
		var pts: Array = carr["puntos"]
		for i in range(pts.size() - 1):
			draw_line(_conv2(pts[i], ox, oy, escala), _conv2(pts[i + 1], ox, oy, escala), Color(0.30, 0.85, 0.95), 3.0)
		for i in range(carr["cps"].size()):
			var pc := _conv2(carr["cps"][i], ox, oy, escala)
			draw_circle(pc, 5.0, Color(0.25, 0.85, 0.35) if i == 0 else Color(0.85, 0.87, 0.90))
		if not _carr_vivo.is_empty():
			if _carr_vivo["ghost"] != null:
				draw_circle(_conv2(_carr_vivo["ghost"], ox, oy, escala), 6.0, Color(0.45, 0.85, 1.0, 0.55))
			for r in _carr_vivo["rivales"]:
				var pr := _conv2(r["p"], ox, oy, escala)
				draw_circle(pr, 7.0, r["c"])
				draw_arc(pr, 7.0, 0.0, TAU, 20, Color(0.05, 0.05, 0.08), 2.0)
			var py := _conv2(_carr_vivo["yo"], ox, oy, escala)
			draw_circle(py, 8.0, Color(1.0, 0.78, 0.2))
			draw_arc(py, 8.0, 0.0, TAU, 24, Color(1, 1, 1), 2.0)
	# Textos
	draw_string(fuente, Vector2(24, 42), "Mapa — Logroño", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, Color(1, 1, 1))
	draw_string(fuente, Vector2(24, size.y - 16), "Tab: cerrar · Cian: ruta a tu encargo (acepta uno con T) · Verde: tu recorrido · Dorado: lugares · Rojo: tu coche · Blanco: tú", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.75, 0.78, 0.85))
