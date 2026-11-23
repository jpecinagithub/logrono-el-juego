extends Control
# Mapa del barrio: calles, río, lugares, ruta al encargo, coche y jugador.
# La ventana del barrio mide 1776 × 1210 m, centrada en (0, 0).
# Desde 2026-11-23 el plano también sirve para MOVERSE: clicar un
# punto dorado emite «lugar_elegido» y el juego te lleva allí
# (pedido de Jon: empieza cada partida en Miguel Villanueva y
# quiere reubicarse desde el plano).

signal lugar_elegido(poi)

var datos := {}
var _carr_vivo := {}
var _raton := Vector2(-9999, -9999)

func mostrar(d: Dictionary) -> void:
	datos = d
	_carr_vivo = datos["carrera"] if datos.get("carrera") != null else {}
	_raton = Vector2(-9999, -9999)
	visible = true
	queue_redraw()

func _params() -> Array:
	var escala := minf((size.x - 60.0) / 5400.0, (size.y - 110.0) / 4000.0)
	var ox := (size.x - 5400.0 * escala) * 0.5
	var oy := 70.0 + (size.y - 70.0 - 4000.0 * escala) * 0.5
	return [escala, ox, oy]

func _poi_cercano(pos: Vector2, ox: float, oy: float, escala: float) -> Dictionary:
	var mejor: Dictionary = {}
	var mejor_d := 16.0
	for poi in datos.get("pois", []):
		var d := pos.distance_to(_conv([poi["x"], poi["z"]], ox, oy, escala))
		if d < mejor_d:
			mejor_d = d
			mejor = poi
	return mejor

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_raton = event.position
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_intentar_click(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_intentar_click(event.position)

func _intentar_click(pos: Vector2) -> void:
	if datos.is_empty():
		return
	var pr := _params()
	var cerca := _poi_cercano(pos, pr[1], pr[2], pr[0])
	if not cerca.is_empty():
		emit_signal("lugar_elegido", cerca)

func punto_de_poi(poi: Dictionary) -> Vector2:
	var pr := _params()
	return _conv([poi["x"], poi["z"]], pr[1], pr[2], pr[0])

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
	var prm := _params()
	var escala: float = prm[0]
	var ox: float = prm[1]
	var oy: float = prm[2]
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
	# Tu recorrido en esta sesión. Los saltos largos (entrar en un
	# interior, teletransporte) no se dibujan: no son recorrido.
	var rastro: Array = datos["rastro"]
	for i in range(rastro.size() - 1):
		var ra: Vector2 = rastro[i]
		var rb: Vector2 = rastro[i + 1]
		if ra.distance_to(rb) > 60.0:
			continue
		draw_line(_conv2(ra, ox, oy, escala), _conv2(rb, ox, oy, escala), Color(0.55, 0.95, 0.65), 2.5)
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
	# El lugar bajo el ratón se anilla y se nombra, sea
	# principal o no: así se sabe qué es cada punto dorado
	# antes de clicar para ir allí.
	var cerca := _poi_cercano(_raton, ox, oy, escala)
	if not cerca.is_empty():
		var pc := _conv([cerca["x"], cerca["z"]], ox, oy, escala)
		draw_arc(pc, 9.0, 0.0, TAU, 24, Color(1, 1, 1), 2.0)
		draw_string(fuente, pc + Vector2(13, 4), String(cerca["n"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(1, 1, 1))
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
	draw_string(fuente, Vector2(24, size.y - 16), "Toca un punto dorado para ir a ese lugar · Tab: cerrar · Cian: ruta a tu encargo · Verde: tu recorrido · Rojo: tu coche · Blanco: tú", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.75, 0.78, 0.85))
