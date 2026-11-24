extends Node3D
## Genera el barrio piloto (Centro / Casco Antiguo) desde datos reales y
## monta la primera misión jugable: a pie o en coche, del portal de
## Miguel Villanueva 1 a Calle Portales 14.
## Modos de verificación (argumentos tras --):
##   verificar       construye y sale
##   capturar        vista aérea del barrio
##   capturar_mision vista de la misión (marcadores)
##   capturar_coche  vista cercana del coche
##   prueba          recorrido automático: a pie hasta el coche, en coche al destino

const M_POR_PLANTA := 3.0
const ANCLA_REDONDA := Vector2(-217.2, 46.6)

var _t_cols := 0
var _t_rows := 0
var _t_paso := 10.0
var _t_x0 := 0.0
var _t_z0 := 0.0
var _t_alturas: Array = []

# Colisiones: polígonos de edificio indexados en una rejilla de 25 m
var _poligonos: Array = []
# Huellas que no deben chocar: suelos deportivos que dibuja
# su hito (Las Norias) y que el Catastro trae como edificio.
var _polys_muertos := {}
var _rejilla := {}
const CELDA := 25.0

var _jugador: Node3D = null
var _coche: Node3D = null
var _coche_dir := 0.0
var _coche_vel := 0.0

# Fase 10: catálogo propio de coches (inventados, nombres de Logroño)
const COCHES := [
	{"n": "Rioja", "clase": "Pequeño", "vmax": 15.0, "acel": 8.5, "freno": 13.0, "giro": 1.60, "precio": 0, "color": Color(0.85, 0.15, 0.12), "estilo": "normal", "dims": Vector3(1.8, 0.55, 4.2)},
	{"n": "Ebro", "clase": "Pequeño", "vmax": 16.5, "acel": 9.5, "freno": 13.5, "giro": 1.65, "precio": 600, "color": Color(0.16, 0.32, 0.58), "estilo": "normal", "dims": Vector3(1.7, 0.55, 3.8)},
	{"n": "Sagasta", "clase": "Pequeño", "vmax": 17.0, "acel": 10.0, "freno": 14.0, "giro": 1.70, "precio": 950, "color": Color(0.85, 0.70, 0.25), "estilo": "normal", "dims": Vector3(1.75, 0.52, 3.9)},
	{"n": "Cantabria", "clase": "Familiar", "vmax": 19.0, "acel": 9.0, "freno": 13.0, "giro": 1.45, "precio": 1800, "color": Color(0.30, 0.46, 0.31), "estilo": "familiar", "dims": Vector3(1.85, 0.58, 4.6)},
	{"n": "San Mateo", "clase": "Familiar", "vmax": 20.0, "acel": 10.0, "freno": 13.5, "giro": 1.50, "precio": 2400, "color": Color(0.78, 0.78, 0.80), "estilo": "familiar", "dims": Vector3(1.85, 0.58, 4.7)},
	{"n": "Espolón", "clase": "Familiar", "vmax": 21.0, "acel": 10.5, "freno": 14.0, "giro": 1.50, "precio": 3900, "color": Color(0.20, 0.22, 0.26), "estilo": "familiar", "dims": Vector3(1.9, 0.60, 4.8)},
	{"n": "Bretón", "clase": "Clásico", "vmax": 17.5, "acel": 8.0, "freno": 12.0, "giro": 1.40, "precio": 2200, "color": Color(0.55, 0.14, 0.13), "estilo": "clasico", "dims": Vector3(1.8, 0.55, 4.5)},
	{"n": "Murallas", "clase": "Clásico", "vmax": 18.5, "acel": 8.5, "freno": 12.5, "giro": 1.42, "precio": 3000, "color": Color(0.10, 0.10, 0.12), "estilo": "clasico", "dims": Vector3(1.85, 0.58, 4.7)},
	{"n": "Valbuena", "clase": "Deportivo", "vmax": 26.0, "acel": 13.0, "freno": 16.0, "giro": 1.80, "precio": 4800, "color": Color(0.92, 0.92, 0.94), "estilo": "deportivo", "dims": Vector3(1.9, 0.45, 4.3)},
	{"n": "Fardachón", "clase": "Deportivo", "vmax": 29.0, "acel": 15.0, "freno": 17.0, "giro": 1.90, "precio": 7000, "color": Color(0.46, 0.27, 0.56), "estilo": "deportivo", "dims": Vector3(1.95, 0.45, 4.4)},
	{"n": "Portales", "clase": "Furgoneta", "vmax": 17.0, "acel": 7.5, "freno": 12.0, "giro": 1.35, "precio": 2600, "color": Color(0.92, 0.92, 0.94), "estilo": "furgo", "dims": Vector3(1.95, 0.60, 4.8)},
	{"n": "Iregua", "clase": "Furgoneta", "vmax": 18.0, "acel": 8.0, "freno": 12.5, "giro": 1.38, "precio": 3200, "color": Color(0.70, 0.45, 0.20), "estilo": "furgo", "dims": Vector3(1.95, 0.60, 5.0)},
	{"n": "Bici Ebro", "clase": "Bicicleta", "vmax": 8.5, "acel": 3.4, "freno": 10.0, "giro": 2.30, "precio": 150, "color": Color(0.10, 0.55, 0.50), "estilo": "bici", "dims": Vector3(0.5, 0.5, 1.8)},
	{"n": "Grajera", "clase": "Bicicleta de montaña", "vmax": 10.5, "acel": 4.4, "freno": 11.0, "giro": 2.55, "precio": 450, "color": Color(0.85, 0.45, 0.10), "estilo": "mtb", "dims": Vector3(0.55, 0.55, 1.85)},
]
var _mis_coches: Array = [{"id": 0, "danio": 0, "motor": 0, "frenos": 0}]
var _coche_activo := 0
var _danio_cd := 0.0
var _acel_forzado := -1.0
var _gas_espacio := false
var _pan_en_mano := false
var _pan_nodo: Node3D = null
var _bolsa_en_mano := false
var _bolsa_nodo: Node3D = null
var _balon_en_mano := false
var _balon_nodo: Node3D = null
var _en_columpio := false
var _aviso_columpio_cd := 0.0
var _en_coche := false
var _origen := Vector3.ZERO
var _destino := Vector3.ZERO
var _auto := false
var _fase_auto := 0
var _mision_ok := false
var _tiempo := 0.0
var _dir_jugador := 0.0
# Media vuelta al pulsar «atrás» a pie o nadando (nada de andar
# hacia atrás): rumbo objetivo, si está girando y la tecla el frame
# anterior, para detectar la pulsación nueva.
var _vuelta_obj := 0.0
var _en_vuelta := false
var _atras_ant := false
var _vista_aerea := false
var _modo_libre := true
# Interfaz tipo «layout de móvil»: minimapa, teléfono, banner de encargo
var _minimapa: Control = null
var _banner: PanelContainer = null
var _banner_texto: Label = null
var _banner_hasta := -1.0
var _pildora: PanelContainer = null
var _pildora_texto: Label = null
var _btn_bajar: Button = null
var _menu_tel: PanelContainer = null
var _burbuja: PanelContainer = null
var _btn_sonido_tel: Button = null
var _ruta_mini: Array = []
var _ruta_mini_de := Vector3.INF
var _ruta_mini_a := Vector3.INF
var _capa_conducir: Control = null
var _toque_giro := 0.0
var _toque_gas := false
var _toque_freno := false

# Grafo de calles para rutas (nodos y adyacencia)
var _nodos: Array = []
var _ady := {}
var _ruta: Array = []
var _ruta_idx := 0
var _ruta_fase := -1
var _origen_libre := Vector3.ZERO
var _destino_libre := Vector3.ZERO

func _registrar_poly(poly: PackedVector2Array) -> void:
	if poly.size() < 3:
		return
	_poligonos.append(poly)
	var idx := _poligonos.size() - 1
	var minx := 1e9
	var maxx := -1e9
	var minz := 1e9
	var maxz := -1e9
	for p in poly:
		minx = minf(minx, p.x)
		maxx = maxf(maxx, p.x)
		minz = minf(minz, p.y)
		maxz = maxf(maxz, p.y)
	for cx in range(int(floor(minx / CELDA)), int(floor(maxx / CELDA)) + 1):
		for cz in range(int(floor(minz / CELDA)), int(floor(maxz / CELDA)) + 1):
			var clave := str(cx) + "," + str(cz)
			if not _rejilla.has(clave):
				_rejilla[clave] = []
			_rejilla[clave].append(idx)

func _altura_terreno(x: float, z: float) -> float:
	if _t_cols == 0:
		return 0.0
	var gx := clampf((x - _t_x0) / _t_paso, 0.0, _t_cols - 1.001)
	var gz := clampf((z - _t_z0) / _t_paso, 0.0, _t_rows - 1.001)
	var i := int(gx)
	var j := int(gz)
	var fx := gx - i
	var fz := gz - j
	var a00: float = _t_alturas[j * _t_cols + i]
	var a10: float = _t_alturas[j * _t_cols + i + 1]
	var a01: float = _t_alturas[(j + 1) * _t_cols + i]
	var a11: float = _t_alturas[(j + 1) * _t_cols + i + 1]
	# La malla del terreno son dos triángulos por celda (diagonal
	# p00-p11): la altura se interpola en el mismo triángulo que se
	# dibuja, para que nadie quede bajo la superficie visible.
	if fz <= fx:
		return a00 + (a10 - a00) * fx + (a11 - a10) * fz
	return a00 + (a11 - a01) * fx + (a01 - a00) * fz

var _puentes: Array = []

func _altura(x: float, z: float) -> float:
	if _en_interior != "":
		return 0.0
	var y := _altura_terreno(x, z)
	for pu in _puentes:
		var a: Vector2 = pu["a"]
		var b: Vector2 = pu["b"]
		var ab := b - a
		var lon2 := ab.length_squared()
		if lon2 < 0.01:
			continue
		var t := clampf((Vector2(x, z) - a).dot(ab) / lon2, 0.0, 1.0)
		var cerca: Vector2 = a + ab * t
		if Vector2(x, z).distance_to(cerca) <= float(pu["ancho"]) * 0.5:
			var ytab := lerpf(float(pu["ya"]), float(pu["yb"]), t) + sin(t * PI) * float(pu.get("bache", 0.5))
			if ytab > y:
				y = ytab
	return y

func _choca(p: Vector2, radio: float) -> bool:
	var clave := str(int(floor(p.x / CELDA))) + "," + str(int(floor(p.y / CELDA)))
	if not _rejilla.has(clave):
		return false
	var muestras := [p, p + Vector2(radio, 0), p - Vector2(radio, 0),
		p + Vector2(0, radio), p - Vector2(0, radio)]
	for idx in _rejilla[clave]:
		if _polys_muertos.has(idx):
			continue
		var poly: PackedVector2Array = _poligonos[idx]
		for m in muestras:
			if Geometry2D.is_point_in_polygon(m, poly):
				return true
	return false

func _mover(entidad: Node3D, desp: Vector3, radio: float) -> void:
	if desp == Vector3.ZERO:
		return
	var pos := entidad.position
	var radio_ent := 1.3 if entidad == _bus else radio
	if _choca(Vector2(pos.x, pos.z), radio) or _choca_entidad(Vector2(pos.x, pos.z), radio_ent, entidad):
		# Ya está dentro de un edificio o pegado a un sólido (p. ej.
		# salió del coche contra una fachada): movimiento libre hasta
		# salir, sin atraparse.
		var libre := pos + desp
		entidad.position = Vector3(libre.x, _altura(libre.x, libre.z) + (0.95 if entidad == _jugador else 0.0), libre.z)
		return
	var intentos := PackedVector3Array([desp, Vector3(desp.x, 0, 0), Vector3(0, 0, desp.z)])
	for d in intentos:
		var nueva := pos + d
		if not _choca(Vector2(nueva.x, nueva.z), radio) and not _choca_entidad(Vector2(nueva.x, nueva.z), radio_ent, entidad):
			entidad.position = Vector3(nueva.x, _altura(nueva.x, nueva.z) + (0.95 if entidad == _jugador else 0.0), nueva.z)
			return

# ---------- Sólidos: la materia no se traspasa ----------
# Coches aparcados y bancos se registran por baldosa como cajas
# orientadas (OBB); coches en marcha, el autobús, tu coche y las
# personas se comprueban en vivo. _mover los trata como edificios.

var _solidos: Array = []
var _rejilla_solidos := {}

func _registrar_solido(x: float, z: float, dir: float, ml: float, ma: float) -> void:
	var idx := _solidos.size()
	_solidos.append([x, z, dir, ml, ma])
	var r := ml + ma + 1.0
	for cx in range(int(floor((x - r) / CELDA)), int(floor((x + r) / CELDA)) + 1):
		for cz in range(int(floor((z - r) / CELDA)), int(floor((z + r) / CELDA)) + 1):
			var clave := str(cx) + "," + str(cz)
			if not _rejilla_solidos.has(clave):
				_rejilla_solidos[clave] = []
			_rejilla_solidos[clave].append(idx)

func _choca_obb(p: Vector2, radio: float, centro: Vector2, dir: float, ml: float, ma: float) -> bool:
	var d := p - centro
	var s := sin(dir)
	var c := cos(dir)
	var lon := d.x * s + d.y * c
	var lat := d.x * c - d.y * s
	var dx := lon - clampf(lon, -ml, ml)
	var dy := lat - clampf(lat, -ma, ma)
	return dx * dx + dy * dy < radio * radio

func _choca_entidad(p: Vector2, radio: float, excluir: Node3D) -> bool:
	var clave := str(int(floor(p.x / CELDA))) + "," + str(int(floor(p.y / CELDA)))
	if _rejilla_solidos.has(clave):
		for idx in _rejilla_solidos[clave]:
			var s: Array = _solidos[idx]
			if _choca_obb(p, radio, Vector2(float(s[0]), float(s[1])), float(s[2]), float(s[3]), float(s[4])):
				return true
	if _coche != null and excluir != _coche:
		if _choca_obb(p, radio, Vector2(_coche.position.x, _coche.position.z), _coche_dir, 2.05, 0.92):
			return true
	if _bus != null and excluir != _bus and _bus.visible:
		if _choca_obb(p, radio, Vector2(_bus.position.x, _bus.position.z), _dir_bus, 4.4, 1.3):
			return true
	for t in _trafico:
		var nodo_t: Node3D = t["nodo3d"]
		if nodo_t == excluir:
			continue
		var tp := Vector2(nodo_t.position.x, nodo_t.position.z)
		if p.distance_squared_to(tp) > 100.0:
			continue
		if _choca_obb(p, radio, tp, nodo_t.rotation.y, 2.05, 0.92):
			return true
	if not _carr.is_empty():
		for est in _carr.get("rivales", []):
			var rn: Node3D = est["nodo"]
			if rn == excluir:
				continue
			var rp := Vector2(rn.position.x, rn.position.z)
			if p.distance_squared_to(rp) > 100.0:
				continue
			if _choca_obb(p, radio, rp, rn.rotation.y, 2.05, 0.92):
				return true
	for peat in _peatones:
		var raiz_p: Node3D = peat["raiz"]
		if raiz_p == excluir:
			continue
		var pp := Vector2(raiz_p.position.x, raiz_p.position.z)
		if p.distance_squared_to(pp) < (radio + 0.34) * (radio + 0.34):
			return true
	for est2 in _estaticos:
		var raiz_e: Node3D = est2["raiz"]
		if raiz_e == excluir:
			continue
		var pe := Vector2(raiz_e.position.x, raiz_e.position.z)
		if p.distance_squared_to(pe) < (radio + 0.34) * (radio + 0.34):
			return true
	for clave_pj in _pjs:
		var pos_pj: Vector3 = _pjs[clave_pj]["pos"]
		if p.distance_squared_to(Vector2(pos_pj.x, pos_pj.z)) < (radio + 0.36) * (radio + 0.36):
			return true
	if not _enc.is_empty() and _enc.has("nodo"):
		var nodo_enc: Node3D = _enc["nodo"]
		if nodo_enc != excluir and nodo_enc != null:
			var p_enc := Vector2(nodo_enc.position.x, nodo_enc.position.z)
			if p.distance_squared_to(p_enc) < (radio + 0.34) * (radio + 0.34):
				return true
	for raiz_t in _tenderos:
		if raiz_t != excluir:
			var p_t := Vector2((raiz_t as Node3D).position.x, (raiz_t as Node3D).position.z)
			if p.distance_squared_to(p_t) < (radio + 0.34) * (radio + 0.34):
				return true
	return false

func _ready() -> void:
	_cargar_portales()
	_cargar_partida()
	_cargar_terreno()
	_cargar_grafo()
	_cargar_frentes()
	_cargar_placas()
	_camara_y_luz()
	_preparar_inicio()
	_crear_mision()
	_crear_entorno()
	_crear_mobiliario()
	_crear_bloque7()
	_crear_recetas()
	_crear_puentes()
	_puentes_medida()
	_crear_vias()
	_crear_colegios()
	_crear_parques_infantiles()
	_hospital_gente()
	_soportales()
	_crear_radares()
	_crear_peatones()
	_parque_gallarza()
	_crear_trafico()
	_crear_buses_urbanos()
	_crear_sonido()
	_crear_interfaz()
	_crear_tactil()
	_comprobar_mando()
	_capturar_si_toca()

func _cargar_terreno() -> void:
	var datos_terreno = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/terreno.json"))
	if datos_terreno == null:
		return
	_t_cols = int(datos_terreno["cols"])
	_t_rows = int(datos_terreno["rows"])
	_t_paso = float(datos_terreno["paso_m"])
	_t_x0 = float(datos_terreno["x0_local"])
	_t_z0 = float(datos_terreno["z0_local"])
	_t_alturas = datos_terreno["alturas"]
	var tv := PackedVector3Array()
	var tn := PackedVector3Array()
	for j in _t_rows - 1:
		for i in _t_cols - 1:
			var x_a := _t_x0 + i * _t_paso
			var x_b := _t_x0 + (i + 1) * _t_paso
			var z_a := _t_z0 + j * _t_paso
			var z_b := _t_z0 + (j + 1) * _t_paso
			var p00 := Vector3(x_a, _altura_terreno(x_a, z_a), z_a)
			var p10 := Vector3(x_b, _altura_terreno(x_b, z_a), z_a)
			var p01 := Vector3(x_a, _altura_terreno(x_a, z_b), z_b)
			var p11 := Vector3(x_b, _altura_terreno(x_b, z_b), z_b)
			_tri(tv, tn, PackedColorArray(), p00, p01, p11, true, Color.WHITE)
			_tri(tv, tn, PackedColorArray(), p00, p11, p10, true, Color.WHITE)
	var malla := _malla_de(tv, tn, PackedColorArray(), Color(0.47, 0.48, 0.43))
	add_child(malla)
	print("TERRENO_OK rejilla=", _t_cols, "x", _t_rows)

func _color_edificio(plantas: int, centro: Vector2) -> Color:
	# Paleta de fachadas: cada edificio coge un tono según su posición,
	# para que ninguna calle sea de un solo color.
	# Paleta disciplinada (Tanda 13): mandan arena, blanco, crema y
	# piedra; el ladrillo suave es el único acento (1 de 10) y la
	# variación de tono es corta. Antes había 8 tonos con ladrillo
	# y salmón saturados: cada calle salía de un color distinto.
	var paleta := [
		Color(0.93, 0.82, 0.64),  # arena
		Color(0.93, 0.91, 0.87),  # blanco
		Color(0.94, 0.88, 0.71),  # crema
		Color(0.84, 0.78, 0.68),  # piedra
		Color(0.93, 0.82, 0.64),  # arena
		Color(0.94, 0.88, 0.71),  # crema
		Color(0.88, 0.72, 0.50),  # ocre suave
		Color(0.82, 0.82, 0.84),  # gris claro
		Color(0.93, 0.91, 0.87),  # blanco
		Color(0.78, 0.52, 0.40),  # ladrillo suave
	]
	var h: float = fposmod(sin(centro.x * 12.9898 + centro.y * 78.233) * 43758.5453, 1.0)
	var base: Color = paleta[int(h * 10.0) % 10]
	var f: float = 0.95 + 0.08 * fposmod(h * 7.31, 1.0)
	return Color(base.r * f, base.g * f, base.b * f)

func _variante_edificio(centro: Vector2) -> int:
	var h: float = fposmod(sin(centro.x * 26.651 + centro.y * 41.313) * 28001.8384, 1.0)
	return int(h * 3.0) % 3

func _color_techo(centro: Vector2, color: Color) -> Color:
	var paleta := [
		Color(0.52, 0.34, 0.27),  # teja
		Color(0.62, 0.43, 0.33),  # teja clara
		Color(0.36, 0.37, 0.41),  # pizarra
		Color(0.45, 0.33, 0.26),  # marrón
	]
	var h: float = fposmod(sin(centro.x * 7.233 + centro.y * 19.19) * 12543.123, 1.0)
	return paleta[int(h * 4.0) % 4].lerp(color, 0.15)

# Fachadas dibujadas por código, en 3 variantes según el edificio:
# 0 clásica, 1 con balcones, 2 ventana estrecha con contraventanas.
# Receta Badajoz (Tanda 13): 512 px por baldosa de 12 m, marcos
# BLANCOS, banda blanca en cada línea de planta con su sombra
# fina, cristal azul grisáceo con brillo, persianas verde gris
# en algunas ventanas y muy pocas encendidas (de día, el 20 %
# de antes salpicaba la calle de cuadrados naranjas). El fondo
# (0,88) lo tiñe el color de cada edificio; la banda y los
# marcos van casi a blanco para que destaquen sobre el tinte.
func _textura_fachada(variante := 0) -> Texture2D:
	if _tex_fachadas.has(variante):
		return _tex_fachadas[variante]
	var img := Image.create(512, 512, false, Image.FORMAT_RGB8)
	img.fill(Color(0.76, 0.74, 0.70))
	var marco := Color(0.97, 0.96, 0.94)
	var cristal := Color(0.18, 0.23, 0.30)
	var brillo := Color(0.36, 0.45, 0.56)
	var persiana := Color(0.60, 0.62, 0.57)
	var persiana_osc := Color(0.50, 0.52, 0.47)
	var sombra := Color(0.58, 0.56, 0.52)
	for fy in 4:
		for fx in 4:
			var x0 := fx * 128
			var y0 := fy * 128
			# La banda de planta y su sombra, arriba de cada celda.
			img.fill_rect(Rect2i(x0, y0, 128, 9), Color(1.0, 0.99, 0.97))
			img.fill_rect(Rect2i(x0, y0 + 9, 128, 3), sombra)
			var hv := fposmod(sin((fx * 7 + variante * 13 + fy * 3) * 12.9898 + fy * 78.233) * 43758.5453, 1.0)
			var cerrada := hv < 0.08
			var con_persiana := hv >= 0.08 and hv < 0.26
			var encendida := hv >= 0.26 and hv < 0.32
			if variante == 2:
				# Contraventanas de lamas, verde apagado.
				img.fill_rect(Rect2i(x0 + 28, y0 + 24, 72, 88), Color(0.58, 0.61, 0.55))
				for ly in 4:
					img.fill_rect(Rect2i(x0 + 32, y0 + 33 + ly * 20, 64, 3), Color(0.50, 0.53, 0.47))
				img.fill_rect(Rect2i(x0 + 46, y0 + 24, 36, 88), marco)
				var gx2 := x0 + 51
				var gy2 := y0 + 29
				if cerrada:
					img.fill_rect(Rect2i(gx2, gy2, 26, 78), persiana)
					for ly2 in 4:
						img.fill_rect(Rect2i(gx2, gy2 + 8 + ly2 * 18, 26, 3), persiana_osc)
				elif encendida:
					img.fill_rect(Rect2i(gx2, gy2, 26, 78), Color(0.90, 0.68, 0.42))
					img.fill_rect(Rect2i(gx2, gy2, 26, 20), Color(0.78, 0.53, 0.30))
				else:
					img.fill_rect(Rect2i(gx2, gy2, 26, 78), cristal)
					img.fill_rect(Rect2i(gx2, gy2, 13, 30), brillo)
					if con_persiana:
						img.fill_rect(Rect2i(gx2, gy2, 26, 40), persiana)
						for ly3 in 3:
							img.fill_rect(Rect2i(gx2, gy2 + 7 + ly3 * 12, 26, 3), persiana_osc)
				img.fill_rect(Rect2i(x0 + 41, y0 + 112, 46, 6), marco)
				img.fill_rect(Rect2i(x0 + 41, y0 + 118, 46, 3), sombra)
			else:
				var ancho_v := 80
				var alto_v := 104 if variante == 1 else 96
				img.fill_rect(Rect2i(x0 + 24, y0 + 20, ancho_v, alto_v), marco)
				var gx := x0 + 33
				var gy := y0 + 29
				var gw := ancho_v - 18
				var gh := alto_v - 18
				if cerrada:
					img.fill_rect(Rect2i(gx, gy, gw, gh), persiana)
					for ly4 in 5:
						img.fill_rect(Rect2i(gx, gy + 9 + ly4 * 17, gw, 3), persiana_osc)
				elif encendida:
					img.fill_rect(Rect2i(gx, gy, gw, gh), Color(0.90, 0.68, 0.42))
					img.fill_rect(Rect2i(gx, gy, gw, 24), Color(0.78, 0.53, 0.30))
				else:
					img.fill_rect(Rect2i(gx, gy, gw, gh), cristal)
					img.fill_rect(Rect2i(gx, gy, gw / 2, gh / 3), brillo)
					if con_persiana:
						var alto_p := int(gh * 0.55)
						img.fill_rect(Rect2i(gx, gy, gw, alto_p), persiana)
						for ly5 in 3:
							img.fill_rect(Rect2i(gx, gy + 8 + ly5 * 14, gw, 3), persiana_osc)
					# Travesaño central de la carpintería.
					img.fill_rect(Rect2i(x0 + 24 + ancho_v / 2 - 2, y0 + 20, 4, alto_v), marco)
				# Alféizar blanco y su sombra.
				img.fill_rect(Rect2i(x0 + 19, y0 + 20 + alto_v, ancho_v + 10, 6), marco)
				img.fill_rect(Rect2i(x0 + 19, y0 + 26 + alto_v, ancho_v + 10, 3), sombra)
	var tex := ImageTexture.create_from_image(img)
	_tex_fachadas[variante] = tex
	return tex

# La planta baja, en su propia baldosa de 12 × 3 m: portal de
# madera, dos escaparates con su banda de rótulo y una ventana
# de vivienda. Las paredes se parten en dos: esta banda abajo
# (conjunto 3) y la retícula de ventanas arriba.
func _textura_planta_baja() -> Texture2D:
	if _tex_pb != null:
		return _tex_pb
	var img := Image.create(512, 128, false, Image.FORMAT_RGB8)
	img.fill(Color(0.76, 0.74, 0.70))
	var marco := Color(0.97, 0.96, 0.94)
	var cristal_e := Color(0.16, 0.20, 0.26)
	var brillo_e := Color(0.30, 0.38, 0.46)
	# La losa sobre la planta baja: banda blanca y sombra.
	img.fill_rect(Rect2i(0, 0, 512, 9), Color(1.0, 0.99, 0.97))
	img.fill_rect(Rect2i(0, 9, 512, 3), Color(0.58, 0.56, 0.52))
	# Portal: marco blanco, puerta de madera y cristal arriba.
	img.fill_rect(Rect2i(18, 34, 58, 94), marco)
	img.fill_rect(Rect2i(23, 39, 48, 89), Color(0.30, 0.21, 0.14))
	img.fill_rect(Rect2i(28, 44, 38, 34), cristal_e)
	img.fill_rect(Rect2i(28, 82, 38, 3), Color(0.20, 0.14, 0.09))
	img.fill_rect(Rect2i(28, 100, 38, 3), Color(0.20, 0.14, 0.09))
	# Escaparate 1: banda de rótulo clara y cristal con brillo.
	img.fill_rect(Rect2i(104, 22, 156, 106), marco)
	img.fill_rect(Rect2i(109, 27, 146, 24), Color(0.92, 0.90, 0.86))
	img.fill_rect(Rect2i(109, 55, 146, 68), cristal_e)
	img.fill_rect(Rect2i(109, 55, 60, 26), brillo_e)
	img.fill_rect(Rect2i(178, 55, 4, 68), marco)
	# Ventana de vivienda entre escaparates.
	img.fill_rect(Rect2i(288, 40, 52, 66), marco)
	img.fill_rect(Rect2i(293, 45, 42, 56), cristal_e)
	img.fill_rect(Rect2i(293, 45, 21, 20), brillo_e)
	# Escaparate 2.
	img.fill_rect(Rect2i(368, 22, 132, 106), marco)
	img.fill_rect(Rect2i(373, 27, 122, 24), Color(0.92, 0.90, 0.86))
	img.fill_rect(Rect2i(373, 55, 122, 68), cristal_e)
	img.fill_rect(Rect2i(373, 55, 48, 26), brillo_e)
	_tex_pb = ImageTexture.create_from_image(img)
	return _tex_pb

func _textura_digitos() -> Texture2D:
	# Dígitos 0-9 en una retícula de 3x5, fondo color placa: cada número de
	# portal se compone con un quad por dígito, sin texturas por portal.
	if _tex_digitos != null:
		return _tex_digitos
	var glyphs := {
		"0": [7, 5, 5, 5, 7], "1": [2, 6, 2, 2, 7], "2": [7, 1, 7, 4, 7],
		"3": [7, 1, 7, 1, 7], "4": [5, 5, 7, 1, 1], "5": [7, 4, 7, 1, 7],
		"6": [7, 4, 7, 5, 7], "7": [7, 1, 2, 2, 2], "8": [7, 5, 7, 5, 7],
		"9": [7, 5, 7, 1, 7]}
	var img := Image.create(300, 50, false, Image.FORMAT_RGB8)
	img.fill(Color(0.13, 0.12, 0.11))
	var tinta := Color(0.93, 0.89, 0.78)
	for d in 10:
		var filas: Array = glyphs[str(d)]
		for fy in 5:
			for fx in 3:
				if (int(filas[fy]) >> (2 - fx)) & 1 == 1:
					img.fill_rect(Rect2i(d * 30 + 5 + fx * 7, 5 + fy * 8, 6, 7), tinta)
	_tex_digitos = ImageTexture.create_from_image(img)
	return _tex_digitos

func _construir_edificios_tile(partes: Array, vigia: Node3D = null, inmediato := true) -> Node3D:
	var cont := Node3D.new()
	# Cuatro conjuntos de malla: uno por variante de fachada y el
	# cuarto para las plantas bajas (su propia textura).
	var conjuntos: Array = []
	for v in 4:
		conjuntos.append([PackedVector3Array(), PackedVector3Array(), PackedColorArray(), PackedVector2Array()])
	var poli_ini := _poligonos.size()
	var tb_minx := 1e9
	var tb_maxx := -1e9
	var tb_minz := 1e9
	var tb_maxz := -1e9
	var _np := 0
	var _trel := Time.get_ticks_msec()
	var gaunas_built := false
	var toyo_built := false
	for parte in partes:
		_np += 1
		if not inmediato and _np % 300 == 0 and Time.get_ticks_msec() - _trel > 9:
			await get_tree().process_frame
			_trel = Time.get_ticks_msec()
			if vigia != null and not is_instance_valid(vigia):
				return null
		var plantas: int = int(parte[0])
		var altura := M_POR_PLANTA if plantas <= 0 else plantas * M_POR_PLANTA
		var poly := PackedVector2Array()
		var ip := 1
		while ip + 1 < parte.size():
			poly.append(Vector2(float(parte[ip]), float(parte[ip + 1])))
			ip += 2
		if poly.size() < 3:
			continue
		_poligonos.append(poly)
		var idx := _poligonos.size() - 1
		var minx := 1e9
		var maxx := -1e9
		var minz := 1e9
		var maxz := -1e9
		var centro := Vector2.ZERO
		for p in poly:
			centro += p
			minx = minf(minx, p.x)
			maxx = maxf(maxx, p.x)
			minz = minf(minz, p.y)
			maxz = maxf(maxz, p.y)
		centro /= poly.size()
		tb_minx = minf(tb_minx, minx)
		tb_maxx = maxf(tb_maxx, maxx)
		tb_minz = minf(tb_minz, minz)
		tb_maxz = maxf(tb_maxz, maxz)
		for cx in range(int(floor(minx / CELDA)), int(floor(maxx / CELDA)) + 1):
			for cz in range(int(floor(minz / CELDA)), int(floor(maxz / CELDA)) + 1):
				var clave := str(cx) + "," + str(cz)
				if not _rejilla.has(clave):
					_rejilla[clave] = []
				_rejilla[clave].append(idx)
		var base := _altura_terreno(centro.x, centro.y) - 0.5
		var techo := base + altura
		var color := _color_edificio(plantas, centro)
		# La Redonda: sus partes (de 1 planta, junto a la plaza) se levantan
		# como la iglesia que es, no como un bloque bajo más.
		var cat := 0
		if plantas == 1 and centro.distance_to(ANCLA_REDONDA) < 36.0:
			var area_p := 0.0
			for i2 in poly.size():
				var q1 := poly[i2]
				var q2 := poly[(i2 + 1) % poly.size()]
				area_p += q1.x * q2.y - q2.x * q1.y
			area_p = absf(area_p) * 0.5
			if area_p >= 50.0:
				if area_p > 600.0:
					cat = 1  # la nave
				elif centro.x < -220.0:
					cat = 2  # el frente de las torres
				elif maxz - minz < 8.0:
					cat = 3  # el ala lateral
				else:
					cat = 4  # la cabecera
		if cat != 0:
			_catedral_partes += 1
			color = Color(0.80, 0.70, 0.53)
			altura = 15.0 if cat == 1 else (11.0 if cat == 2 else (9.0 if cat == 3 else 12.0))
			techo = base + altura
		# Tanda 1 de los 50 símbolos: San Bartolomé, Santa María de Palacio
		# y Santiago el Real se levantan en piedra, con nave alta y tejado.
		var igl := 0
		var area_i := 0.0
		var es_nave_i := false
		var es_torre_i := false
		if cat == 0 and plantas == 1:
			for i2 in poly.size():
				var q1 := poly[i2]
				var q2 := poly[(i2 + 1) % poly.size()]
				area_i += q1.x * q2.y - q2.x * q1.y
			area_i = absf(area_i) * 0.5
			if area_i >= 28.0:
				if centro.x >= -82.0 and centro.x <= -38.0 and centro.y >= -48.0 and centro.y <= -8.0:
					igl = 1
					es_nave_i = area_i >= 170.0
					es_torre_i = centro.distance_to(Vector2(-75.0, -24.0)) < 6.0
				elif centro.x >= -158.0 and centro.x <= -100.0 and centro.y >= -160.0 and centro.y <= -98.0 and area_i >= 60.0:
					igl = 2
					es_nave_i = area_i >= 480.0
					es_torre_i = centro.distance_to(Vector2(-147.0, -133.0)) < 8.0
				elif centro.x >= -422.0 and centro.x <= -372.0 and centro.y >= -107.0 and centro.y <= -70.0 and area_i >= 35.0:
					igl = 3
					es_nave_i = area_i >= 400.0
		var nave_i := false
		if igl != 0:
			_igl_partes += 1
			nave_i = es_nave_i
			color = Color(0.79, 0.68, 0.52) if igl == 1 else (Color(0.77, 0.66, 0.50) if igl == 2 else Color(0.80, 0.70, 0.54))
			altura = (13.0 if igl == 1 else 14.0) if es_nave_i else (9.0 if igl == 1 else 10.0)
			techo = base + altura
		# Tanda 2 de los 50 símbolos: edificios singulares con su color
		# propio (el tratamiento de forma va en los hitos).
		var sing := 0
		if cat == 0 and igl == 0:
			var area_s := 0.0
			for i2 in poly.size():
				var q1 := poly[i2]
				var q2 := poly[(i2 + 1) % poly.size()]
				area_s += q1.x * q2.y - q2.x * q1.y
			area_s = absf(area_s) * 0.5
			if area_s >= 100.0 and centro.x >= -48.0 and centro.x <= 45.0 and centro.y >= 120.0 and centro.y <= 199.0:
				sing = 1  # Instituto Sagasta
			elif area_s >= 400.0 and centro.x >= -398.0 and centro.x <= -328.0 and centro.y >= 128.0 and centro.y <= 160.0:
				sing = 2  # Mercado de San Blas
			elif area_s >= 50.0 and centro.x >= -548.0 and centro.x <= -472.0 and centro.y >= 117.0 and centro.y <= 181.0:
				sing = 3  # Palacio de Espartero – Museo de La Rioja
			elif area_s >= 30.0 and centro.x >= -270.0 and centro.x <= -202.0 and centro.y >= -468.0 and centro.y <= -431.0:
				sing = 4  # Casa de las Ciencias (la antigua estación)
			elif area_s >= 350.0 and centro.x >= -420.0 and centro.x <= -303.0 and centro.y >= -607.0 and centro.y <= -524.0:
				sing = 5  # Bodegas Franco-Españolas
			elif area_s >= 500.0 and centro.x >= -602.0 and centro.x <= -536.0 and centro.y >= 40.0 and centro.y <= 86.0:
				sing = 7  # La Antigua Tabacalera
			elif area_s >= 300.0 and plantas <= 3 and centro.distance_to(Vector2(-676.0, 252.0)) < 48.0:
				sing = 8  # Escuelas Trevijano (posición aproximada)
		if sing != 0:
			_sing_partes += 1
			var cols_sing := {1: Color(0.86, 0.81, 0.71), 2: Color(0.72, 0.52, 0.38), 3: Color(0.82, 0.72, 0.55), 4: Color(0.80, 0.72, 0.58), 5: Color(0.55, 0.30, 0.24), 7: Color(0.66, 0.47, 0.35), 8: Color(0.74, 0.58, 0.42)}
			color = cols_sing[sing]
		# Bloque 4 del plan de calles (la Ribera): la Plaza de Toros y
		# el Riojaforum se construyen a medida, no como bloques.
		# Bloque 3: las grandes naves de Parque Rioja, con su altura
		# real (9 m) y su banda de marca.
		var especial := 0
		var banda_e := Color(0.25, 0.35, 0.55)
		if cat == 0 and igl == 0:
			var area_e := 0.0
			for i2 in poly.size():
				var q1 := poly[i2]
				var q2 := poly[(i2 + 1) % poly.size()]
				area_e += q1.x * q2.y - q2.x * q1.y
			area_e = absf(area_e) * 0.5
			if plantas == 1 and area_e > 5000.0 and centro.distance_to(Vector2(458.0, -487.0)) < 14.0:
				especial = 1
			elif area_e >= 900.0 and centro.x >= 870.0 and centro.x <= 1070.0 and centro.y >= -600.0 and centro.y <= -530.0:
				especial = 2
			elif area_e > 3000.0 and centro.distance_to(Vector2(-2047.0, 1730.0)) < 14.0:
				especial = 3
				banda_e = Color(0.80, 0.10, 0.12)
			elif area_e > 3000.0 and centro.distance_to(Vector2(-2135.0, 1641.0)) < 14.0:
				especial = 3
				banda_e = Color(0.25, 0.35, 0.55)
			elif area_e > 3000.0 and centro.distance_to(Vector2(-2469.0, 1720.0)) < 14.0:
				especial = 3
				banda_e = Color(0.15, 0.55, 0.25)
			elif area_e > 3000.0 and centro.distance_to(Vector2(-2498.0, 1569.0)) < 14.0:
				especial = 3
				banda_e = Color(0.05, 0.25, 0.70)
			elif area_e > 3000.0 and centro.distance_to(Vector2(1897.0, 355.0)) < 14.0:
				especial = 3
				banda_e = Color(0.10, 0.25, 0.65)
			elif area_e > 3000.0 and centro.distance_to(Vector2(1863.0, 437.0)) < 14.0:
				especial = 3
				banda_e = Color(0.20, 0.22, 0.28)
			elif area_e > 900.0 and centro.x >= -960.0 and centro.x <= -765.0 and centro.y >= 1435.0 and centro.y <= 1645.0:
				especial = 4
			elif area_e > 700.0 and centro.distance_to(Vector2(1540.0, 521.0)) < 25.0:
				especial = 6
			elif (area_e > 250.0 and area_e < 1300.0 and centro.x >= -1135.0 and centro.x <= -975.0 and centro.y >= -715.0 and centro.y <= -575.0) or (area_e > 1400.0 and centro.distance_to(Vector2(-1159.0, -866.0)) < 30.0):
				especial = 5
			elif centro.x >= -2610.0 and centro.x <= -2490.0 and centro.y >= 1355.0 and centro.y <= 1510.0:
				especial = 7
		if especial != 0:
			_especiales += 1
			var cj_e: Array = conjuntos[_variante_edificio(centro)]
			if especial == 1:
				_plaza_toros(cj_e[0], cj_e[1], cj_e[2], cj_e[3], poly, centro, base)
			elif especial == 4:
				if not gaunas_built:
					gaunas_built = true
					_las_gaunas(cj_e[0], cj_e[1], cj_e[2], cj_e[3], partes)
			elif especial == 3:
				_nave(cj_e[0], cj_e[1], cj_e[2], cj_e[3], poly, centro, base, banda_e)
			elif especial == 6:
				_unir(cj_e[0], cj_e[1], cj_e[2], cj_e[3], centro, base)
			elif especial == 7:
				if not toyo_built:
					toyo_built = true
					_toyo_ito(cj_e[0], cj_e[1], cj_e[2], cj_e[3], centro, base)
			elif especial == 5:
				# Suelo deportivo de Las Norias: lo dibuja su
				# hito y NO es un edificio: su huella no puede
				# chocar (tapaba las piscinas y las pistas con
				# una pared invisible: ni andar ni nadar).
				_polys_muertos[idx] = true
			else:
				_riojaforum(cj_e[0], cj_e[1], cj_e[2], cj_e[3], poly, centro, base, plantas)
			continue
		var variante := _variante_edificio(centro)
		var cj: Array = conjuntos[variante]
		var color_techo := _color_techo(centro, color)
		# Bloque A: en el casco antiguo, los edificios rectangulares llevan
		# tejado inclinado de teja en vez de azotea plana. Tanda 13: los
		# bajos (2-4 plantas) lo llevan en TODA la ciudad, como en
		# Badajoz; los altos solo en el casco, como hasta ahora.
		var inclinado := false
		if cat == 0 and plantas >= 2 and poly.size() == 4 and (plantas <= 4 or centro.distance_to(Vector2(-160.0, 130.0)) <= 430.0):
			var d01 := (poly[1] - poly[0]).normalized().dot((poly[2] - poly[1]).normalized())
			var d12 := (poly[2] - poly[1]).normalized().dot((poly[3] - poly[2]).normalized())
			inclinado = absf(d01) < 0.30 and absf(d12) < 0.30 and minf(maxx - minx, maxz - minz) > 4.0
		var uv_techo := PackedVector2Array([Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)])
		var tris := Geometry2D.triangulate_polygon(poly) if not inclinado else PackedInt32Array()
		for i in range(0, tris.size(), 3):
			var a := Vector3(poly[tris[i]].x, techo, poly[tris[i]].y)
			var b := Vector3(poly[tris[i + 1]].x, techo, poly[tris[i + 1]].y)
			var c := Vector3(poly[tris[i + 2]].x, techo, poly[tris[i + 2]].y)
			_tri(cj[0], cj[1], cj[2], a, b, c, true, color_techo, cj[3], uv_techo)
		for i in poly.size():
			var p1 := poly[i]
			var p2 := poly[(i + 1) % poly.size()]
			var ab := Vector3(p1.x, base, p1.y)
			var bb := Vector3(p2.x, base, p2.y)
			var bt := Vector3(p2.x, techo, p2.y)
			var at := Vector3(p1.x, techo, p1.y)
			# UV de fachada: una baldosa de textura (4×4 ventanas) cada 12 m
			var u2 := p1.distance_to(p2) / 12.0
			if cat == 0 and igl == 0:
				# Tanda 13: la pared se parte en dos — la planta
				# baja (3 m, conjunto 3, con portales y escaparates)
				# y la retícula de ventanas encima.
				var cj_pb: Array = conjuntos[3]
				var corte := base + M_POR_PLANTA
				if altura <= M_POR_PLANTA + 0.01:
					_tri(cj_pb[0], cj_pb[1], cj_pb[2], ab, bb, bt, false, color, cj_pb[3],
						PackedVector2Array([Vector2(0, 0), Vector2(u2, 0), Vector2(u2, 1)]))
					_tri(cj_pb[0], cj_pb[1], cj_pb[2], ab, bt, at, false, color, cj_pb[3],
						PackedVector2Array([Vector2(0, 0), Vector2(u2, 1), Vector2(0, 1)]))
				else:
					var cb := Vector3(p2.x, corte, p2.y)
					var ca := Vector3(p1.x, corte, p1.y)
					var v2b := (altura - M_POR_PLANTA) / 12.0
					_tri(cj_pb[0], cj_pb[1], cj_pb[2], ab, bb, cb, false, color, cj_pb[3],
						PackedVector2Array([Vector2(0, 0), Vector2(u2, 0), Vector2(u2, 1)]))
					_tri(cj_pb[0], cj_pb[1], cj_pb[2], ab, cb, ca, false, color, cj_pb[3],
						PackedVector2Array([Vector2(0, 0), Vector2(u2, 1), Vector2(0, 1)]))
					_tri(cj[0], cj[1], cj[2], ca, cb, bt, false, color, cj[3],
						PackedVector2Array([Vector2(0, 0), Vector2(u2, 0), Vector2(u2, v2b)]))
					_tri(cj[0], cj[1], cj[2], ca, bt, at, false, color, cj[3],
						PackedVector2Array([Vector2(0, 0), Vector2(u2, v2b), Vector2(0, v2b)]))
			else:
				var v2 := altura / 12.0
				_tri(cj[0], cj[1], cj[2], ab, bb, bt, false, color, cj[3],
					PackedVector2Array([Vector2(0, 0), Vector2(u2, 0), Vector2(u2, v2)]))
				_tri(cj[0], cj[1], cj[2], ab, bt, at, false, color, cj[3],
					PackedVector2Array([Vector2(0, 0), Vector2(u2, v2), Vector2(0, v2)]))
			# Bloque A: la fachada gana cuerpo — zócalo, cornisa y, según la
			# variante, balcones de verdad o aparatos de aire acondicionado.
			if cat == 0:
				var lon_e := p1.distance_to(p2)
				if lon_e > 0.6:
					var dir_e := (p2 - p1) / lon_e
					var nrm_e := Vector2(-dir_e.y, dir_e.x)
					var mid_e := (p1 + p2) * 0.5
					if (mid_e + nrm_e).distance_squared_to(centro) < mid_e.distance_squared_to(centro):
						nrm_e = -nrm_e
					var uv_p := PackedVector2Array([Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)])
					var col_zoc := Color(0.30, 0.27, 0.24).lerp(color, 0.25)
					# Zócalo bajo de verdad (Tanda 13): del suelo a
					# 0,5 m, bajo los escaparates de la planta baja.
					var za := Vector3(p1.x + nrm_e.x * 0.05, base + 0.02, p1.y + nrm_e.y * 0.05)
					var zb := Vector3(p2.x + nrm_e.x * 0.05, base + 0.02, p2.y + nrm_e.y * 0.05)
					var zt := Vector3(p2.x + nrm_e.x * 0.05, base + 0.52, p2.y + nrm_e.y * 0.05)
					var zt2 := Vector3(p1.x + nrm_e.x * 0.05, base + 0.52, p1.y + nrm_e.y * 0.05)
					_tri(cj[0], cj[1], cj[2], za, zb, zt, false, col_zoc, cj[3], uv_p)
					_tri(cj[0], cj[1], cj[2], za, zt, zt2, false, col_zoc, cj[3], uv_p)
					if not inclinado and plantas >= 2:
						var col_cor := Color(0.84, 0.80, 0.72).lerp(color, 0.30)
						var ca := Vector3(p1.x + nrm_e.x * 0.20, techo - 0.34, p1.y + nrm_e.y * 0.20)
						var cb := Vector3(p2.x + nrm_e.x * 0.20, techo - 0.34, p2.y + nrm_e.y * 0.20)
						var ct := Vector3(p2.x + nrm_e.x * 0.20, techo + 0.10, p2.y + nrm_e.y * 0.20)
						var ct2 := Vector3(p1.x + nrm_e.x * 0.20, techo + 0.10, p1.y + nrm_e.y * 0.20)
						_tri(cj[0], cj[1], cj[2], ca, cb, ct, false, col_cor, cj[3], uv_p)
						_tri(cj[0], cj[1], cj[2], ca, ct, ct2, false, col_cor, cj[3], uv_p)
					var rot_f := atan2(nrm_e.x, nrm_e.y)
					if variante == 1 and plantas >= 3 and lon_e >= 5.0:
						for f in range(1, plantas):
							var s := 2.6
							while s < lon_e - 2.2:
								var hb := fposmod(sin((p1.x + s * 3.1 + f * 17.3) * 12.9898 + (p1.y + f * 7.7) * 78.233) * 43758.5453, 1.0)
								if hb >= 0.68:
									var bp := p1 + dir_e * s + nrm_e * 0.31
									var yb := base + f * M_POR_PLANTA + 0.92
									_caja_dir_guiada(cj[0], cj[1], cj[2], cj[3], Vector3(bp.x, yb, bp.y), Vector3(1.7, 0.09, 0.62), Color(0.78, 0.76, 0.72), rot_f)
									_caja_dir_guiada(cj[0], cj[1], cj[2], cj[3], Vector3(bp.x + nrm_e.x * 0.28, yb + 0.33, bp.y + nrm_e.y * 0.28), Vector3(1.7, 0.55, 0.04), Color(0.23, 0.23, 0.25), rot_f)
									_fach_balcones += 1
								s += 6.0
					elif variante != 1 and plantas >= 2 and lon_e >= 8.0:
						for f in range(1, plantas):
							var s := 3.4
							while s < lon_e - 2.6:
								var ha := fposmod(sin((p1.x + s * 5.7 + f * 29.1) * 26.651 + (p1.y + f * 3.3) * 41.313) * 28001.8384, 1.0)
								if ha < 0.15:
									var ap := p1 + dir_e * s + nrm_e * 0.15
									_caja_dir_guiada(cj[0], cj[1], cj[2], cj[3], Vector3(ap.x, base + f * M_POR_PLANTA + 0.55, ap.y), Vector3(0.72, 0.52, 0.27), Color(0.83, 0.83, 0.81), rot_f)
								s += 6.5
		if (cat == 1 or nave_i) and maxx - minx >= maxz - minz:
			# Tejado a dos aguas de la nave, cumbrera a lo largo del eje.
			var col_te := Color(0.48, 0.30, 0.22)
			var uv_c := PackedVector2Array([Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)])
			var zc := (minz + maxz) * 0.5
			var hw := (maxz - minz) * 0.47
			var xa := minx + (maxx - minx) * 0.03
			var xb := maxx - (maxx - minx) * 0.03
			var yr := techo + 5.2
			var e1 := Vector3(xa, techo, zc - hw)
			var e2 := Vector3(xb, techo, zc - hw)
			var e3 := Vector3(xa, techo, zc + hw)
			var e4 := Vector3(xb, techo, zc + hw)
			var r1 := Vector3(xa, yr, zc)
			var r2 := Vector3(xb, yr, zc)
			_tri(cj[0], cj[1], cj[2], e1, e2, r2, true, col_te, cj[3], uv_c)
			_tri(cj[0], cj[1], cj[2], e1, r2, r1, true, col_te, cj[3], uv_c)
			_tri(cj[0], cj[1], cj[2], e4, e3, r1, true, col_te, cj[3], uv_c)
			_tri(cj[0], cj[1], cj[2], e4, r1, r2, true, col_te, cj[3], uv_c)
			_tri(cj[0], cj[1], cj[2], e3, e1, r1, true, color, cj[3], uv_c)
			_tri(cj[0], cj[1], cj[2], e2, e4, r2, true, color, cj[3], uv_c)
		elif nave_i:
			# Cumbrera a lo largo del eje z (naves más largas que anchas).
			var col_te3 := Color(0.48, 0.30, 0.22)
			var uv_c4 := PackedVector2Array([Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)])
			var xc4 := (minx + maxx) * 0.5
			var hw5 := (maxx - minx) * 0.47
			var za4 := minz + (maxz - minz) * 0.03
			var zb4 := maxz - (maxz - minz) * 0.03
			var yr5 := techo + 5.2
			var k1 := Vector3(xc4 - hw5, techo, za4)
			var k2 := Vector3(xc4 - hw5, techo, zb4)
			var k3 := Vector3(xc4 + hw5, techo, za4)
			var k4 := Vector3(xc4 + hw5, techo, zb4)
			var u1 := Vector3(xc4, yr5, za4)
			var u2 := Vector3(xc4, yr5, zb4)
			_tri(cj[0], cj[1], cj[2], k1, k2, u2, true, col_te3, cj[3], uv_c4)
			_tri(cj[0], cj[1], cj[2], k1, u2, u1, true, col_te3, cj[3], uv_c4)
			_tri(cj[0], cj[1], cj[2], k4, k3, u1, true, col_te3, cj[3], uv_c4)
			_tri(cj[0], cj[1], cj[2], k4, u1, u2, true, col_te3, cj[3], uv_c4)
			_tri(cj[0], cj[1], cj[2], k3, k1, u1, true, color, cj[3], uv_c4)
			_tri(cj[0], cj[1], cj[2], k2, k4, u2, true, color, cj[3], uv_c4)
		if cat == 2:
			# Las dos torres de la fachada, con su chapitel.
			var col_t := Color(0.84, 0.74, 0.57)
			var col_cap := Color(0.36, 0.36, 0.40)
			var uv_c2 := PackedVector2Array([Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)])
			for zt in [minz + 3.9, maxz - 3.9]:
				var ct := Vector3(minx + 4.4, base + 15.5, zt)
				_caja_guiada(cj[0], cj[1], cj[2], cj[3], ct, Vector3(6.2, 31.0, 6.2), col_t)
				var yb := base + 31.0
				var ap := Vector3(minx + 4.4, yb + 5.6, zt)
				var c1 := Vector3(ct.x - 3.1, yb, zt - 3.1)
				var c2 := Vector3(ct.x + 3.1, yb, zt - 3.1)
				var c3 := Vector3(ct.x + 3.1, yb, zt + 3.1)
				var c4 := Vector3(ct.x - 3.1, yb, zt + 3.1)
				_tri(cj[0], cj[1], cj[2], c1, c2, ap, true, col_cap, cj[3], uv_c2)
				_tri(cj[0], cj[1], cj[2], c2, c3, ap, true, col_cap, cj[3], uv_c2)
				_tri(cj[0], cj[1], cj[2], c3, c4, ap, true, col_cap, cj[3], uv_c2)
				_tri(cj[0], cj[1], cj[2], c4, c1, ap, true, col_cap, cj[3], uv_c2)
				_catedral_torres += 1
		if igl == 1 and es_torre_i:
			# La torre de San Bartolomé, con su hueco de campanas al sur.
			_igl_torres += 1
			var col_tn := Color(0.74, 0.63, 0.47)
			var col_pz := Color(0.34, 0.34, 0.38)
			var uv_tn := PackedVector2Array([Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)])
			_caja_guiada(cj[0], cj[1], cj[2], cj[3], Vector3(centro.x, base + 13.0, centro.y), Vector3(6.4, 26.0, 6.4), col_tn)
			_caja_guiada(cj[0], cj[1], cj[2], cj[3], Vector3(centro.x, base + 22.6, centro.y + 3.30), Vector3(2.3, 3.8, 0.3), Color(0.15, 0.12, 0.09))
			var ybt := base + 26.0
			var apt := Vector3(centro.x, ybt + 4.4, centro.y)
			var d1 := Vector3(centro.x - 3.4, ybt, centro.y - 3.4)
			var d2 := Vector3(centro.x + 3.4, ybt, centro.y - 3.4)
			var d3 := Vector3(centro.x + 3.4, ybt, centro.y + 3.4)
			var d4 := Vector3(centro.x - 3.4, ybt, centro.y + 3.4)
			_tri(cj[0], cj[1], cj[2], d1, d2, apt, true, col_pz, cj[3], uv_tn)
			_tri(cj[0], cj[1], cj[2], d2, d3, apt, true, col_pz, cj[3], uv_tn)
			_tri(cj[0], cj[1], cj[2], d3, d4, apt, true, col_pz, cj[3], uv_tn)
			_tri(cj[0], cj[1], cj[2], d4, d1, apt, true, col_pz, cj[3], uv_tn)
		if igl == 2 and es_torre_i:
			# Santa María de Palacio: la torre y su AGUJA, la silueta del casco.
			_igl_torres += 1
			var txp := -152.0
			var tzp := -133.0
			var col_tp := Color(0.73, 0.62, 0.46)
			var col_ag := Color(0.23, 0.24, 0.29)
			var uv_tp := PackedVector2Array([Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)])
			_caja_guiada(cj[0], cj[1], cj[2], cj[3], Vector3(txp, base + 10.0, tzp), Vector3(7.0, 20.0, 7.0), col_tp)
			_caja_guiada(cj[0], cj[1], cj[2], cj[3], Vector3(txp, base + 16.5, tzp + 3.53), Vector3(2.4, 3.6, 0.3), Color(0.15, 0.12, 0.09))
			var yba := base + 20.0
			var ap1 := Vector3(txp, yba + 8.0, tzp)
			var b1 := Vector3(txp - 3.9, yba, tzp - 3.9)
			var b2 := Vector3(txp + 3.9, yba, tzp - 3.9)
			var b3 := Vector3(txp + 3.9, yba, tzp + 3.9)
			var b4 := Vector3(txp - 3.9, yba, tzp + 3.9)
			_tri(cj[0], cj[1], cj[2], b1, b2, ap1, true, col_ag, cj[3], uv_tp)
			_tri(cj[0], cj[1], cj[2], b2, b3, ap1, true, col_ag, cj[3], uv_tp)
			_tri(cj[0], cj[1], cj[2], b3, b4, ap1, true, col_ag, cj[3], uv_tp)
			_tri(cj[0], cj[1], cj[2], b4, b1, ap1, true, col_ag, cj[3], uv_tp)
			var ap2 := Vector3(txp, yba + 14.5, tzp)
			var c1 := Vector3(txp - 2.1, yba + 6.5, tzp - 2.1)
			var c2 := Vector3(txp + 2.1, yba + 6.5, tzp - 2.1)
			var c3 := Vector3(txp + 2.1, yba + 6.5, tzp + 2.1)
			var c4 := Vector3(txp - 2.1, yba + 6.5, tzp + 2.1)
			_tri(cj[0], cj[1], cj[2], c1, c2, ap2, true, col_ag, cj[3], uv_tp)
			_tri(cj[0], cj[1], cj[2], c2, c3, ap2, true, col_ag, cj[3], uv_tp)
			_tri(cj[0], cj[1], cj[2], c3, c4, ap2, true, col_ag, cj[3], uv_tp)
			_tri(cj[0], cj[1], cj[2], c4, c1, ap2, true, col_ag, cj[3], uv_tp)
			_caja_guiada(cj[0], cj[1], cj[2], cj[3], Vector3(txp, yba + 15.2, tzp), Vector3(0.18, 1.6, 0.18), col_ag)
			_caja_guiada(cj[0], cj[1], cj[2], cj[3], Vector3(txp, yba + 15.5, tzp), Vector3(0.95, 0.18, 0.18), col_ag)
		if igl == 3 and es_nave_i:
			# La torre de Santiago, robusta, en su esquina suroeste.
			_igl_torres += 1
			var txs := -414.0
			var tzs := -100.0
			var col_ts := Color(0.75, 0.64, 0.48)
			var col_ps := Color(0.36, 0.36, 0.40)
			var uv_ts := PackedVector2Array([Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)])
			_caja_guiada(cj[0], cj[1], cj[2], cj[3], Vector3(txs, base + 12.0, tzs), Vector3(8.0, 24.0, 8.0), col_ts)
			_caja_guiada(cj[0], cj[1], cj[2], cj[3], Vector3(txs, base + 19.5, tzs + 4.03), Vector3(2.6, 4.0, 0.3), Color(0.15, 0.12, 0.09))
			var ybs := base + 24.0
			var aps := Vector3(txs, ybs + 5.0, tzs)
			var e1 := Vector3(txs - 4.3, ybs, tzs - 4.3)
			var e2 := Vector3(txs + 4.3, ybs, tzs - 4.3)
			var e3 := Vector3(txs + 4.3, ybs, tzs + 4.3)
			var e4 := Vector3(txs - 4.3, ybs, tzs + 4.3)
			_tri(cj[0], cj[1], cj[2], e1, e2, aps, true, col_ps, cj[3], uv_ts)
			_tri(cj[0], cj[1], cj[2], e2, e3, aps, true, col_ps, cj[3], uv_ts)
			_tri(cj[0], cj[1], cj[2], e3, e4, aps, true, col_ps, cj[3], uv_ts)
			_tri(cj[0], cj[1], cj[2], e4, e1, aps, true, col_ps, cj[3], uv_ts)
		if inclinado:
			_fach_tejados += 1
			var col_ti := _color_techo(centro, color)
			var uv_t := PackedVector2Array([Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)])
			if maxx - minx >= maxz - minz:
				var zc2 := (minz + maxz) * 0.5
				var hw2 := (maxz - minz) * 0.47
				var xa2 := minx + (maxx - minx) * 0.03
				var xb2 := maxx - (maxx - minx) * 0.03
				var yr2 := techo + minf(3.0, (maxz - minz) * 0.24)
				var e1 := Vector3(xa2, techo, zc2 - hw2)
				var e2 := Vector3(xb2, techo, zc2 - hw2)
				var e3 := Vector3(xa2, techo, zc2 + hw2)
				var e4 := Vector3(xb2, techo, zc2 + hw2)
				var r1 := Vector3(xa2, yr2, zc2)
				var r2 := Vector3(xb2, yr2, zc2)
				_tri(cj[0], cj[1], cj[2], e1, e2, r2, true, col_ti, cj[3], uv_t)
				_tri(cj[0], cj[1], cj[2], e1, r2, r1, true, col_ti, cj[3], uv_t)
				_tri(cj[0], cj[1], cj[2], e4, e3, r1, true, col_ti, cj[3], uv_t)
				_tri(cj[0], cj[1], cj[2], e4, r1, r2, true, col_ti, cj[3], uv_t)
				_tri(cj[0], cj[1], cj[2], e3, e1, r1, true, color, cj[3], uv_t)
				_tri(cj[0], cj[1], cj[2], e2, e4, r2, true, color, cj[3], uv_t)
			else:
				var xc2 := (minx + maxx) * 0.5
				var hw3 := (maxx - minx) * 0.47
				var za2 := minz + (maxz - minz) * 0.03
				var zb2 := maxz - (maxz - minz) * 0.03
				var yr3 := techo + minf(3.0, (maxx - minx) * 0.24)
				var g1 := Vector3(xc2 - hw3, techo, za2)
				var g2 := Vector3(xc2 - hw3, techo, zb2)
				var g3 := Vector3(xc2 + hw3, techo, za2)
				var g4 := Vector3(xc2 + hw3, techo, zb2)
				var s1 := Vector3(xc2, yr3, za2)
				var s2 := Vector3(xc2, yr3, zb2)
				_tri(cj[0], cj[1], cj[2], g1, g2, s2, true, col_ti, cj[3], uv_t)
				_tri(cj[0], cj[1], cj[2], g1, s2, s1, true, col_ti, cj[3], uv_t)
				_tri(cj[0], cj[1], cj[2], g4, g3, s1, true, col_ti, cj[3], uv_t)
				_tri(cj[0], cj[1], cj[2], g4, s1, s2, true, col_ti, cj[3], uv_t)
				_tri(cj[0], cj[1], cj[2], g3, g1, s1, true, color, cj[3], uv_t)
				_tri(cj[0], cj[1], cj[2], g2, g4, s2, true, color, cj[3], uv_t)
		elif cat == 0 and plantas >= 3:
			# Caseta de escalera en algunas azoteas grandes
			var area_t := 0.0
			for i2 in poly.size():
				var q1 := poly[i2]
				var q2 := poly[(i2 + 1) % poly.size()]
				area_t += q1.x * q2.y - q2.x * q1.y
			if absf(area_t) * 0.5 > 130.0:
				var hb2 := fposmod(sin(centro.x * 12.9898 + centro.y * 78.233) * 43758.5453, 1.0)
				var bc := Vector3(centro.x + (hb2 - 0.5) * (maxx - minx) * 0.3, techo + 0.55, centro.y + (fposmod(hb2 * 7.31, 1.0) - 0.5) * (maxz - minz) * 0.3)
				_caja_guiada(cj[0], cj[1], cj[2], cj[3], bc, Vector3(2.6, 1.1, 2.2), Color(0.55, 0.53, 0.50))
	# Bloque A: puerta de portal con su número, donde el Catastro marca
	# un portal sobre la fachada de un edificio de esta baldosa.
	var cj0: Array = conjuntos[0]
	var dig_v := PackedVector3Array()
	var dig_n := PackedVector3Array()
	var dig_c := PackedColorArray()
	var dig_uv := PackedVector2Array()
	if not _portales.is_empty():
		for pt in _portales:
			var px := float(pt["x"])
			var pz := float(pt["z"])
			if px < tb_minx - 2.0 or px > tb_maxx + 2.0 or pz < tb_minz - 2.0 or pz > tb_maxz + 2.0:
				continue
			var pp := Vector2(px, pz)
			var mejor_d := 2.6
			var m_a := Vector2.ZERO
			var m_b := Vector2.ZERO
			var m_c := Vector2.ZERO
			var m_p := Vector2.ZERO
			for pi in range(poli_ini, _poligonos.size()):
				var pl: PackedVector2Array = _poligonos[pi]
				var cen := Vector2.ZERO
				for q in pl:
					cen += q
				cen /= pl.size()
				if cen.distance_squared_to(pp) > 2025.0:
					continue
				for ei in pl.size():
					var ea := pl[ei]
					var eb := pl[(ei + 1) % pl.size()]
					var seg := Geometry2D.get_closest_point_to_segment(pp, ea, eb)
					var dd := seg.distance_to(pp)
					if dd < mejor_d:
						mejor_d = dd
						m_a = ea
						m_b = eb
						m_c = cen
						m_p = seg
			if mejor_d > 2.6 or m_a == m_b:
				continue
			var de := (m_b - m_a).normalized()
			var n2 := Vector2(-de.y, de.x)
			if n2.dot(m_p - m_c) < 0.0:
				n2 = -n2
				de = -de
			var rot_d := atan2(n2.x, n2.y)
			var base_d := _altura_terreno(px, pz) - 0.10
			var p3 := Vector3(m_p.x, 0, m_p.y)
			var n3 := Vector3(n2.x, 0, n2.y)
			var hd := fposmod(sin(px * 12.9898 + pz * 78.233) * 43758.5453, 1.0)
			var col_puerta: Color = [Color(0.30, 0.20, 0.13), Color(0.16, 0.22, 0.18), Color(0.15, 0.18, 0.28), Color(0.35, 0.33, 0.30)][int(hd * 4.0) % 4]
			_caja_dir_guiada(cj0[0], cj0[1], cj0[2], cj0[3], p3 + n3 * 0.03 + Vector3(0, base_d + 1.22, 0), Vector3(1.34, 2.44, 0.10), Color(0.78, 0.74, 0.66), rot_d)
			_caja_dir_guiada(cj0[0], cj0[1], cj0[2], cj0[3], p3 + n3 * 0.08 + Vector3(0, base_d + 1.12, 0), Vector3(1.08, 2.24, 0.06), col_puerta, rot_d)
			_caja_dir_guiada(cj0[0], cj0[1], cj0[2], cj0[3], p3 + n3 * 0.30 + Vector3(0, base_d + 0.06, 0), Vector3(1.5, 0.12, 0.5), Color(0.55, 0.53, 0.50), rot_d)
			_fach_puertas += 1
			var digs := ""
			for ch in String(pt["numero"]):
				if ch >= "0" and ch <= "9":
					digs += ch
			if digs.length() > 3:
				digs = digs.substr(0, 3)
			var nd := digs.length()
			for k in nd:
				var dig := int(digs[k])
				var off := (float(k) - float(nd - 1) * 0.5) * 0.21
				var cen_q := p3 + Vector3(de.x * off, 0, de.y * off) + n3 * 0.10 + Vector3(0, base_d + 2.66, 0)
				var d3 := Vector3(de.x, 0, de.y)
				var bl := cen_q - d3 * 0.095 - Vector3(0, 0.15, 0)
				var br := cen_q + d3 * 0.095 - Vector3(0, 0.15, 0)
				var tr := cen_q + d3 * 0.095 + Vector3(0, 0.15, 0)
				var tl := cen_q - d3 * 0.095 + Vector3(0, 0.15, 0)
				var u0 := float(dig) / 10.0
				var u1 := float(dig + 1) / 10.0
				_tri(dig_v, dig_n, dig_c, bl, br, tr, false, Color.WHITE, dig_uv, PackedVector2Array([Vector2(u0, 1.0), Vector2(u1, 1.0), Vector2(u1, 0.0)]))
				_tri(dig_v, dig_n, dig_c, bl, tr, tl, false, Color.WHITE, dig_uv, PackedVector2Array([Vector2(u0, 1.0), Vector2(u1, 0.0), Vector2(u0, 0.0)]))
	_fach_digitos += dig_v.size() / 3
	if not dig_v.is_empty():
		cont.add_child(_malla_de(dig_v, dig_n, dig_c, Color.WHITE, dig_uv, _textura_digitos()))
	for v in 3:
		var cv: Array = conjuntos[v]
		if (cv[0] as PackedVector3Array).is_empty():
			continue
		cont.add_child(_malla_de(cv[0], cv[1], cv[2], Color.WHITE, cv[3], _textura_fachada(v)))
	var cvb: Array = conjuntos[3]
	if not (cvb[0] as PackedVector3Array).is_empty():
		cont.add_child(_malla_de(cvb[0], cvb[1], cvb[2], Color.WHITE, cvb[3], _textura_planta_baja()))
	return cont

func _construir_calles_tile(calles: Array, vigia: Node3D = null, inmediato := true) -> Node3D:
	var cont := Node3D.new()
	var cv := PackedVector3Array()
	var cn := PackedVector3Array()
	var sv := PackedVector3Array()
	var sn := PackedVector3Array()
	var bv := PackedVector3Array()
	var bn := PackedVector3Array()
	var bc := PackedColorArray()
	# Fase 7: extremos de tramo para detectar cruces y pintar pasos de cebra
	var extremos := {}
	for calle_e in calles:
		var pts_e: Array = calle_e["p"]
		for i in range(pts_e.size() - 1):
			var a_e := Vector2(float(pts_e[i][0]), float(pts_e[i][1]))
			var b_e := Vector2(float(pts_e[i + 1][0]), float(pts_e[i + 1][1]))
			if a_e.distance_to(b_e) < 0.5:
				continue
			var dir_e := (b_e - a_e).normalized()
			for ext in [a_e, b_e]:
				var clave_e := str(int(round(ext.x))) + "," + str(int(round(ext.y)))
				if extremos.has(clave_e):
					extremos[clave_e]["n"] = int(extremos[clave_e]["n"]) + 1
				else:
					extremos[clave_e] = {"n": 1, "pos": ext, "dir": dir_e if ext == a_e else -dir_e, "ancho": float(calle_e["a"]), "clase": String(calle_e["c"])}
	var _nc := 0
	var _trel2 := Time.get_ticks_msec()
	for calle in calles:
		_nc += 1
		if not inmediato and _nc % 100 == 0 and Time.get_ticks_msec() - _trel2 > 9:
			await get_tree().process_frame
			_trel2 = Time.get_ticks_msec()
			if vigia != null and not is_instance_valid(vigia):
				return null
		var medio: float = float(calle["a"]) * 0.5
		var clase := String(calle["c"])
		var con_acera := clase in ["primary", "secondary", "residential", "living_street"] and medio >= 2.75
		var pts: Array = []
		var base_pts: Array[Vector2] = []
		for q in calle["p"]:
			base_pts.append(Vector2(float(q[0]), float(q[1])))
		for i in base_pts.size():
			if i > 0:
				var desde_p: Vector2 = base_pts[i - 1]
				var hasta_p: Vector2 = base_pts[i]
				var tramos := int(ceil(desde_p.distance_to(hasta_p) / 6.0))
				for k in range(1, tramos):
					var mp: Vector2 = desde_p.lerp(hasta_p, float(k) / float(tramos))
					pts.append([mp.x, mp.y])
			pts.append([base_pts[i].x, base_pts[i].y])
		var ant_izq := Vector3.ZERO
		var ant_der := Vector3.ZERO
		var ant_borde: Array = []
		var ant_ai := Vector3.ZERO
		var ant_ao := Vector3.ZERO
		var ant_di := Vector3.ZERO
		var ant_do := Vector3.ZERO
		var primero := true
		for i in pts.size():
			var p := Vector2(float(pts[i][0]), float(pts[i][1]))
			var dir := Vector2.ZERO
			if i > 0:
				dir += p - Vector2(float(pts[i - 1][0]), float(pts[i - 1][1]))
			if i < pts.size() - 1:
				dir += Vector2(float(pts[i + 1][0]), float(pts[i + 1][1])) - p
			if dir.length() < 0.001:
				continue
			dir = dir.normalized()
			var normal2 := Vector2(-dir.y, dir.x)
			# Cada vértice se apoya en SU terreno (antes toda la sección
			# iba plana a la altura del centro: en calles con pendiente
			# lateral un borde flotaba como una losa y el otro quedaba
			# enterrado). En los puentes el tablero sí es plano: allí se
			# mantiene la altura del centro en toda la sección.
			var y_c := _altura(p.x, p.y)
			var en_puente := y_c > _altura_terreno(p.x, p.y) + 0.05
			var alt := func(qx: float, qz: float, off: float) -> float:
				return (y_c if en_puente else _altura(qx, qz)) + off
			var xz_izq: Vector2 = p + normal2 * medio
			var xz_der := p - normal2 * medio
			var izq := Vector3(xz_izq.x, alt.call(xz_izq.x, xz_izq.y, 0.08), xz_izq.y)
			var der := Vector3(xz_der.x, alt.call(xz_der.x, xz_der.y, 0.08), xz_der.y)
			var xz_ai: Vector2 = p + normal2 * (medio + 0.05)
			var xz_ao: Vector2 = p + normal2 * (medio + 1.75)
			var xz_di := p - normal2 * (medio + 0.05)
			var xz_do := p - normal2 * (medio + 1.75)
			var ai := Vector3(xz_ai.x, alt.call(xz_ai.x, xz_ai.y, 0.17), xz_ai.y)
			var ao := Vector3(xz_ao.x, alt.call(xz_ao.x, xz_ao.y, 0.17), xz_ao.y)
			var di := Vector3(xz_di.x, alt.call(xz_di.x, xz_di.y, 0.17), xz_di.y)
			var do2 := Vector3(xz_do.x, alt.call(xz_do.x, xz_do.y, 0.17), xz_do.y)
			if not primero:
				_tri(cv, cn, PackedColorArray(), ant_izq, der, ant_der, true, Color.WHITE)
				_tri(cv, cn, PackedColorArray(), ant_izq, izq, der, true, Color.WHITE)
				if con_acera:
					_tri(sv, sn, PackedColorArray(), ant_ai, ao, ant_ao, true, Color.WHITE)
					_tri(sv, sn, PackedColorArray(), ant_ai, ai, ao, true, Color.WHITE)
					_tri(sv, sn, PackedColorArray(), ant_di, ant_do, do2, true, Color.WHITE)
					_tri(sv, sn, PackedColorArray(), ant_di, do2, di, true, Color.WHITE)
			if medio >= 2.25:
				var lados_b: Array = []
				for sgn in [1.0, -1.0]:
					var xz_go: Vector2 = p + normal2 * sgn * (medio - 0.03)
					var xz_gi: Vector2 = p + normal2 * sgn * (medio - 0.58)
					var xz_lo: Vector2 = p + normal2 * sgn * (medio - 0.31)
					var xz_li: Vector2 = p + normal2 * sgn * (medio - 0.46)
					var go := Vector3(xz_go.x, alt.call(xz_go.x, xz_go.y, 0.092), xz_go.y)
					var gi := Vector3(xz_gi.x, alt.call(xz_gi.x, xz_gi.y, 0.092), xz_gi.y)
					var lo := Vector3(xz_lo.x, alt.call(xz_lo.x, xz_lo.y, 0.106), xz_lo.y)
					var li := Vector3(xz_li.x, alt.call(xz_li.x, xz_li.y, 0.106), xz_li.y)
					lados_b.append([go, gi, lo, li])
				if not primero:
					for sb in range(2):
						var pa: Array = ant_borde[sb]
						var pb: Array = lados_b[sb]
						_tri(bv, bn, bc, pa[0], pb[0], pa[1], true, Color(0.20, 0.20, 0.22))
						_tri(bv, bn, bc, pb[0], pb[1], pa[1], true, Color(0.20, 0.20, 0.22))
						_tri(bv, bn, bc, pa[2], pb[2], pa[3], true, Color(0.85, 0.84, 0.78))
						_tri(bv, bn, bc, pb[2], pb[3], pa[3], true, Color(0.85, 0.84, 0.78))
				ant_borde = lados_b
			ant_izq = izq
			ant_der = der
			ant_ai = ai
			ant_ao = ao
			ant_di = di
			ant_do = do2
			primero = false
	cont.add_child(_malla_de(cv, cn, PackedColorArray(), Color(0.32, 0.32, 0.35)))
	if sv.size() > 0:
		cont.add_child(_malla_de(sv, sn, PackedColorArray(), Color(0.60, 0.58, 0.55)))
	if bv.size() > 0:
		cont.add_child(_malla_de(bv, bn, bc, Color.WHITE))
	# Pasos de cebra: en los cruces (3+ tramos) con calle ancha, 5 franjas
	# blancas fundidas en una sola malla por baldosa.
	var zv := PackedVector3Array()
	var zn := PackedVector3Array()
	var zc := PackedColorArray()
	var nceb := 0
	for clave_e in extremos:
		if nceb >= 10:
			break
		var e: Dictionary = extremos[clave_e]
		var ancho_e := float(e["ancho"])
		if int(e["n"]) < 3 or ancho_e < 6.0:
			continue
		if not ["primary", "secondary", "tertiary", "residential"].has(String(e["clase"])):
			continue
		var pos_e: Vector2 = e["pos"]
		var dir_c: Vector2 = e["dir"]
		var y_e := _altura(pos_e.x, pos_e.y) + 0.17
		for k in 5:
			var cen := pos_e + dir_c * (2.4 + float(k) * 0.95)
			_caja_en(zv, zn, zc, Vector3(cen.x, y_e, cen.y), Vector3(ancho_e * 0.78, 0.03, 0.55), Color(0.88, 0.88, 0.86), atan2(dir_c.x, dir_c.y))
		nceb += 1
	if nceb > 0:
		cont.add_child(_malla_de(zv, zn, zc, Color.WHITE))
	return cont

func _cargar_grafo() -> void:
	var datos_g = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/grafo.json"))
	if datos_g == null:
		return
	for n in datos_g["nodos"]:
		_nodos.append(Vector2(float(n[0]), float(n[1])))
	for a in datos_g["aristas"]:
		var i := int(a[0])
		var j := int(a[1])
		var d: float = Vector2(_nodos[i]).distance_to(Vector2(_nodos[j]))
		if not _ady.has(i):
			_ady[i] = []
		if not _ady.has(j):
			_ady[j] = []
		_ady[i].append([j, d])
		_ady[j].append([i, d])
	print("GRAFO_OK nodos=", _nodos.size())

func _nodo_cercano(p: Vector2) -> int:
	var mejor := -1
	var md := 1e18
	for i in _nodos.size():
		var d := p.distance_squared_to(_nodos[i])
		if d < md:
			md = d
			mejor = i
	return mejor

func _heap_push(h: Array, item: Array) -> void:
	h.append(item)
	var i := h.size() - 1
	while i > 0:
		var padre := (i - 1) / 2
		if float(h[padre][0]) <= float(h[i][0]):
			break
		var tmp = h[padre]
		h[padre] = h[i]
		h[i] = tmp
		i = padre

func _heap_pop(h: Array) -> Array:
	var top: Array = h[0]
	var ult = h.pop_back()
	if not h.is_empty():
		h[0] = ult
		var i := 0
		while true:
			var l := i * 2 + 1
			var r := l + 1
			var men := i
			if l < h.size() and float(h[l][0]) < float(h[men][0]):
				men = l
			if r < h.size() and float(h[r][0]) < float(h[men][0]):
				men = r
			if men == i:
				break
			var tmp = h[men]
			h[men] = h[i]
			h[i] = tmp
			i = men
	return top

func _segmento_libre(a: Vector2, b: Vector2, radio: float) -> bool:
	# Recta a-b sin chocar (muestreo cada 1,5 m; los extremos no cuentan:
	# el destino puede estar pegado a una fachada).
	var pasos := int(ceil(a.distance_to(b) / 1.5))
	for i in range(1, pasos):
		if _choca(a.lerp(b, float(i) / float(maxi(pasos, 1))), radio):
			return false
	return true

func _tramo_transitable(a: Vector2, b: Vector2) -> Array:
	# Camino andando de a hasta b (sin incluir a, incluyendo b) que no
	# atraviesa edificios: recta si está libre; si no, búsqueda en rejilla
	# de 2 m, con cajas cada vez más grandes hasta rodear la manzana
	# entera si hace falta (Bloque G del plan de detalle).
	if _segmento_libre(a, b, 0.35):
		return [Vector3(b.x, 0, b.y)]
	for margen in [14.0, 44.0, 84.0]:
		var r := _bfs_tramo(a, b, margen)
		if not r.is_empty():
			return r
	# Los pasos estrechos (un callejón de 2-3 m entre manzanas) se pierden
	# en la rejilla de 2 m: las celdas caen sobre las fachadas y el paso
	# desaparece. Segunda pasada con rejilla de 1 m, que sí los resuelve.
	for margen in [14.0, 44.0, 84.0]:
		var r2 := _bfs_tramo(a, b, margen, 1.0)
		if not r2.is_empty():
			return r2
	return [Vector3(b.x, 0, b.y)]

func _bfs_tramo(a: Vector2, b: Vector2, margen: float, paso := 2.0) -> Array:
	var salida: Array = []
	var minx := minf(a.x, b.x) - margen
	var minz := minf(a.y, b.y) - margen
	var nx := int(ceil((maxf(a.x, b.x) + margen - minx) / paso)) + 1
	var nz := int(ceil((maxf(a.y, b.y) + margen - minz) / paso)) + 1
	if nx * nz > 45000 or nx < 2 or nz < 2:
		return salida
	var bloq := PackedByteArray()
	bloq.resize(nx * nz)
	for iz in nz:
		for ix in nx:
			bloq[iz * nx + ix] = 1 if _choca(Vector2(minx + (ix + 0.5) * paso, minz + (iz + 0.5) * paso), 0.35) else 0
	var celda_de := func(p: Vector2) -> Vector2i:
		return Vector2i(clampi(int((p.x - minx) / paso), 0, nx - 1), clampi(int((p.y - minz) / paso), 0, nz - 1))
	var centro := func(c: Vector2i) -> Vector2:
		return Vector2(minx + (c.x + 0.5) * paso, minz + (c.y + 0.5) * paso)
	var ini: Vector2i = celda_de.call(a)
	var fin: Vector2i = celda_de.call(b)
	if bloq[ini.y * nx + ini.x] == 1:
		# El arranque puede caer dentro del grosor de una fachada (un nodo
		# de calle pegado a una esquina): sin salida ortogonal, la búsqueda
		# muere en la primera celda. Se arranca de la libre más cercana,
		# igual que se hace con el destino.
		var mejor_i := ini
		var mdi := 1e9
		for iz2 in range(maxi(0, ini.y - 3), mini(nz, ini.y + 4)):
			for ix2 in range(maxi(0, ini.x - 3), mini(nx, ini.x + 4)):
				if bloq[iz2 * nx + ix2] == 0:
					var d2 := Vector2(ix2 - ini.x, iz2 - ini.y).length()
					if d2 < mdi:
						mdi = d2
						mejor_i = Vector2i(ix2, iz2)
		ini = mejor_i
	if bloq[fin.y * nx + fin.x] == 1:
		# La celda del destino está dentro de una fachada: se busca la libre
		# más cercana y el último salto (corto) se hace en recta.
		var mejor := fin
		var md := 1e9
		for iz in range(maxi(0, fin.y - 3), mini(nz, fin.y + 4)):
			for ix in range(maxi(0, fin.x - 3), mini(nx, fin.x + 4)):
				if bloq[iz * nx + ix] == 0:
					var d := Vector2(ix - fin.x, iz - fin.y).length()
					if d < md:
						md = d
						mejor = Vector2i(ix, iz)
		fin = mejor
	var prev := PackedInt32Array()
	prev.resize(nx * nz)
	prev.fill(-2)
	var cola: Array = [ini]
	prev[ini.y * nx + ini.x] = -1
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	var cabeza := 0
	while cabeza < cola.size():
		var c: Vector2i = cola[cabeza]
		cabeza += 1
		if c == fin:
			break
		for d in dirs:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= nx or n.y >= nz:
				continue
			if bloq[n.y * nx + n.x] == 1 or prev[n.y * nx + n.x] != -2:
				continue
			if d.x != 0 and d.y != 0 and (bloq[c.y * nx + n.x] == 1 or bloq[n.y * nx + c.x] == 1):
				continue  # nada de cortar esquinas en diagonal
			prev[n.y * nx + n.x] = c.y * nx + c.x
			cola.append(n)
	if prev[fin.y * nx + fin.x] == -2:
		return salida
	var celdas: Array = []
	var cur := fin.y * nx + fin.x
	while cur != -1:
		celdas.push_front(Vector2i(cur % nx, cur / nx))
		cur = prev[cur]
	var puntos: Array = []
	for c in celdas:
		puntos.append(centro.call(c))
	puntos.append(b)
	# Suavizado: saltar al punto más lejano visible en línea recta libre.
	var i := 0
	var desde_p := a
	while i < puntos.size():
		var j := puntos.size() - 1
		while j > i and not _segmento_libre(desde_p, puntos[j], 0.35):
			j -= 1
		if j == i and not _segmento_libre(desde_p, puntos[j], 0.35):
			j = i  # ni el siguiente se ve: se avanza un paso igualmente
		salida.append(Vector3(puntos[j].x, 0, puntos[j].y))
		desde_p = puntos[j]
		i = j + 1
	return salida

func _calcular_ruta(desde: Vector3, hasta: Vector3) -> Array:
	var salida: Array = []
	if _nodos.is_empty():
		salida.append(hasta)
		return salida
	var s := _nodo_cercano(Vector2(desde.x, desde.z))
	var t := _nodo_cercano(Vector2(hasta.x, hasta.z))
	var dist := {s: 0.0}
	var prev := {}
	var abierta: Array = []
	_heap_push(abierta, [_nodos[s].distance_to(_nodos[t]), s])
	var cerrados := {}
	while not abierta.is_empty():
		var actual: Array = _heap_pop(abierta)
		var u: int = actual[1]
		if cerrados.has(u):
			continue
		cerrados[u] = true
		if u == t:
			break
		for par in _ady.get(u, []):
			var v: int = par[0]
			var nd: float = dist.get(u, 1e18) + par[1]
			if nd < dist.get(v, 1e18):
				dist[v] = nd
				prev[v] = u
				_heap_push(abierta, [nd + _nodos[v].distance_to(_nodos[t]), v])
	if not prev.has(t) and s != t:
		for p in _tramo_transitable(_nodos[t], Vector2(hasta.x, hasta.z)):
			salida.append(p)
		return salida
	var cadena: Array = [t]
	while cadena[0] != s:
		cadena.push_front(prev[cadena[0]])
	var cabeza_tramo := _tramo_transitable(_nodos[s], Vector2(desde.x, desde.z))
	for k in range(cabeza_tramo.size() - 1, -1, -1):
		salida.append(cabeza_tramo[k])
	for idn in cadena:
		var nv: Vector2 = _nodos[idn]
		salida.append(Vector3(nv.x, 0, nv.y))
	for p in _tramo_transitable(_nodos[t], Vector2(hasta.x, hasta.z)):
		salida.append(p)
	return salida

func _ruta_calle(desde: Vector3, hasta: Vector3) -> Array:
	# Como _calcular_ruta pero SOLO por nodos del grafo, sin
	# los tramos de conexion al punto exacto: para las lineas
	# de autobus, que tienen que ir por las calles y volver
	# por el mismo recorrido. Los tramos (pensados para llegar
	# a un portal) metian en las lineas excursiones en
	# escalera rodeando edificios y ganchos en las cabeceras
	# (visto por Jon en las lineas roja, verde y azul).
	# El coste lleva una penalizacion por giro (3 m por
	# radian): sin ella, en las avenidas de doble calzada el
	# camino mas corto saltaba de una calzada a la otra a
	# mitad de manzana y la linea salia con escalones (Jon:
	# «que la linea roja sea una linea recta», y lo mismo
	# la verde). Con la penalizacion el autobus se queda en
	# una sola calzada y solo gira donde la calle gira de
	# verdad. La busqueda es sobre aristas dirigidas (el
	# estado es el par nodo anterior/nodo) porque el giro
	# depende de como se llega a cada nodo.
	var salida: Array = []
	if _nodos.is_empty():
		salida.append(hasta)
		return salida
	var s := _nodo_cercano(Vector2(desde.x, desde.z))
	var t := _nodo_cercano(Vector2(hasta.x, hasta.z))
	if s == t:
		salida.append(Vector3(_nodos[t].x, 0, _nodos[t].y))
		return salida
	var dist := {}
	var prev := {}
	var abierta: Array = []
	dist[Vector2i(-1, s)] = 0.0
	_heap_push(abierta, [_nodos[s].distance_to(_nodos[t]), 0.0, -1, s])
	var cerrados := {}
	var llegada := Vector2i(-2, -2)
	while not abierta.is_empty():
		var actual: Array = _heap_pop(abierta)
		var g: float = actual[1]
		var p: int = actual[2]
		var u: int = actual[3]
		var estado := Vector2i(p, u)
		if cerrados.has(estado):
			continue
		cerrados[estado] = true
		if u == t:
			llegada = estado
			break
		for par in _ady.get(u, []):
			var v: int = par[0]
			var giro := 0.0
			if p >= 0:
				var a1 := atan2(_nodos[u].x - _nodos[p].x, _nodos[u].y - _nodos[p].y)
				var a2 := atan2(_nodos[v].x - _nodos[u].x, _nodos[v].y - _nodos[u].y)
				giro = absf(wrapf(a2 - a1, -PI, PI))
			var nd: float = g + float(par[1]) + 3.0 * giro
			var estado_v := Vector2i(u, v)
			if nd < float(dist.get(estado_v, 1e18)):
				dist[estado_v] = nd
				prev[estado_v] = estado
				_heap_push(abierta, [nd + _nodos[v].distance_to(_nodos[t]), nd, u, v])
	if llegada.x == -2:
		salida.append(Vector3(_nodos[t].x, 0, _nodos[t].y))
		return salida
	var cadena: Array = []
	var est := llegada
	while true:
		cadena.push_front(est.y)
		if est.x < 0:
			break
		est = prev[est]
	for idn in cadena:
		var nv: Vector2 = _nodos[idn]
		salida.append(Vector3(nv.x, 0, nv.y))
	return salida

func _punto_libre(p: Vector3, radio: float) -> Vector3:
	if not _choca(Vector2(p.x, p.z), radio):
		return p
	for r in range(2, 42, 2):
		for k in 12:
			var ang := TAU * k / 12.0
			var cand := p + Vector3(cos(ang) * r, 0, sin(ang) * r)
			if not _choca(Vector2(cand.x, cand.z), radio):
				return cand
	return p

func _es_encerrado(p: Vector2) -> bool:
	# Un punto puede no estar dentro de ningun edificio y aun
	# asi no tener salida: el patio interior del Hospital San
	# Pedro, donde el teletransporte del plano dejaba a Jon
	# encerrado entre cuatro paredes. Se mira en 8 direcciones
	# si hay paso libre hasta 50 m; si todas tropiezan con
	# edificios antes, el punto esta encerrado.
	for k in 8:
		var dir := Vector2(cos(TAU * float(k) / 8.0), sin(TAU * float(k) / 8.0))
		var libre := true
		var r := 4.0
		while r <= 50.0:
			if _choca(p + dir * r, 0.5):
				libre = false
				break
			r += 4.0
		if libre:
			return false
	return true

func _objetivo_ruta() -> Vector3:
	if _ruta_idx < _ruta.size():
		return _ruta[_ruta_idx]
	return Vector3.INF

var _atrapado_t := 0.0
var _cam: Camera3D

# ---------- Fase 5.5: ciudad entera por baldosas (streaming) ----------

const TILE_M := 650.0
const CIUDAD_X0 := -2700.0
const CIUDAD_Z0 := -2000.0

func _tile_de(p: Vector2) -> Vector2i:
	return Vector2i(int(floor((p.x - CIUDAD_X0) / TILE_M)), int(floor((p.y - CIUDAD_Z0) / TILE_M)))

func _clave_tile(t: Vector2i) -> String:
	return str(t.x) + "," + str(t.y)

func _preparar_inicio() -> void:
	var datos_p = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/portales.json"))
	var a := Vector2(-307.0, 322.0)
	if datos_p != null:
		for p in datos_p["portales"]:
			if String(p["calle"]).contains("VILLANUEVA") and String(p["numero"]) == "1":
				a = Vector2(float(p["x"]), float(p["z"]))
				break
	var ct := _tile_de(a)
	_construir_tile(ct)
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx != 0 or dy != 0:
				_cola_tiles.append(Vector2i(ct.x + dx, ct.y + dy))
	print("CIUDAD_OK baldosa_inicial=", _clave_tile(ct), " poligonos=", _poligonos.size())

func _oca_casilla(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float, y: float, gp: Vector2i, num: int) -> void:
	var ocas := [5, 9, 14, 18, 23, 27, 32, 36, 41, 45, 50, 54, 59, 63]
	var col := Color(0.80, 0.77, 0.70) if num % 2 == 0 else Color(0.60, 0.56, 0.49)
	if ocas.has(num):
		col = Color(0.78, 0.50, 0.28)
	_caja_en(verts, normals, cols, Vector3(gx + float(gp.x) * 1.16, y + 0.085, gz + float(gp.y) * 1.16), Vector3(1.02, 0.05, 1.02), col, 0.0)

func _hito_oca(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# El tablero del Juego de la Oca de la Plaza de Santiago: 63 casillas
	# en espiral sobre el pavimento, con las ocas en color propio.
	var y := _altura(gx, gz)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.03, gz), Vector3(11.6, 0.06, 11.6), Color(0.38, 0.36, 0.33), 0.0)
	var pos := Vector2i(-4, -4)
	var dirs := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	var tramos := [8, 8, 7, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1]
	var num := 1
	_oca_casilla(verts, normals, cols, gx, gz, y, pos, num)
	var di := 0
	for t in tramos:
		for s in t:
			if num >= 63:
				break
			pos += dirs[di]
			num += 1
			_oca_casilla(verts, normals, cols, gx, gz, y, pos, num)
		di = (di + 1) % 4
		if num >= 63:
			break

func _hito_fuente(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# La Fuente del Peregrino: vaso octogonal de piedra y pilar central.
	var y := _altura(gx, gz)
	var piedra := Color(0.70, 0.64, 0.54)
	for i in 8:
		var a := float(i) * PI / 4.0
		_caja_en(verts, normals, cols, Vector3(gx + sin(a) * 1.55, y + 0.38, gz + cos(a) * 1.55), Vector3(1.30, 0.76, 0.34), piedra, a)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.52, gz), Vector3(2.5, 0.06, 2.5), Color(0.45, 0.66, 0.78), PI / 4.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.65, gz), Vector3(0.34, 1.3, 0.34), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 1.42, gz), Vector3(0.58, 0.24, 0.58), piedra, PI / 4.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 1.62, gz), Vector3(0.16, 0.3, 0.16), piedra, 0.0)

func _muro_revellin(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, a: Vector2, b: Vector2, piedra: Color, piedra2: Color) -> void:
	var mid := (a + b) * 0.5
	var d := b - a
	var lon := d.length()
	var y := _altura(mid.x, mid.y)
	var rot := atan2(d.x, d.y)
	_caja_en(verts, normals, cols, Vector3(mid.x, y + 3.1, mid.y), Vector3(1.9, 6.2, lon), piedra, rot)
	var dir := d / lon
	var s := 1.1
	while s < lon - 0.6:
		var p := a + dir * s
		_caja_en(verts, normals, cols, Vector3(p.x, y + 6.65, p.y), Vector3(2.0, 0.9, 0.95), piedra2, rot)
		s += 2.3

func _hito_revellin(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# El Cubo del Revellín: el gran torreón redondo de la muralla, con
	# dos lienzos almenados y la Puerta del Revellín entre ellos.
	var y := _altura(gx, gz)
	var piedra := Color(0.63, 0.56, 0.45)
	var piedra2 := Color(0.58, 0.51, 0.41)
	_caja_en(verts, normals, cols, Vector3(gx, y + 6.5, gz), Vector3(9.6, 13.0, 9.6), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 6.5, gz), Vector3(9.6, 13.0, 9.6), piedra, PI / 4.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 13.6, gz), Vector3(8.4, 1.2, 8.4), piedra2, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 13.6, gz), Vector3(8.4, 1.2, 8.4), piedra2, PI / 4.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 15.3, gz), Vector3(3.2, 2.2, 3.2), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 16.8, gz), Vector3(2.3, 0.8, 2.3), piedra2, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 17.5, gz), Vector3(1.3, 0.7, 1.3), piedra2, 0.0)
	_muro_revellin(verts, normals, cols, Vector2(-602.0, 3.0), Vector2(-601.0, 9.0), piedra, piedra2)
	_muro_revellin(verts, normals, cols, Vector2(-600.6, 17.0), Vector2(-600.0, 27.0), piedra, piedra2)
	var yp := _altura(-600.8, 13.0)
	_caja_en(verts, normals, cols, Vector3(-600.8, yp + 5.6, 13.0), Vector3(2.2, 1.4, 8.6), piedra, 0.05)
	_muro_revellin(verts, normals, cols, Vector2(-596.0, -13.0), Vector2(-566.0, -23.0), piedra, piedra2)

func _hito_chapiteles(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# Los dos chapiteles del palacio de Portales: torrecillas de piedra
	# con aguja de pizarra sobre los extremos de su fachada.
	var piedra := Color(0.80, 0.70, 0.53)
	var pizarra := Color(0.29, 0.29, 0.33)
	for px in [-84.0, -66.0]:
		var y := _altura(px, 57.0) + 14.4
		_caja_en(verts, normals, cols, Vector3(px, y + 2.2, 57.0), Vector3(2.1, 4.4, 2.1), piedra, 0.0)
		_caja_en(verts, normals, cols, Vector3(px, y + 4.85, 57.0), Vector3(1.8, 0.9, 1.8), pizarra, 0.0)
		_caja_en(verts, normals, cols, Vector3(px, y + 5.75, 57.0), Vector3(1.25, 0.9, 1.25), pizarra, 0.0)
		_caja_en(verts, normals, cols, Vector3(px, y + 6.65, 57.0), Vector3(0.7, 0.9, 0.7), pizarra, 0.0)
		_caja_en(verts, normals, cols, Vector3(px, y + 7.45, 57.0), Vector3(0.2, 0.8, 0.2), pizarra, 0.0)

func _hito_espartero(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# El Monumento a Espartero del Espolón: el general a caballo, en
	# bronce, sobre su alto pedestal de piedra. Mira al este.
	var y := _altura(gx, gz)
	var piedra := Color(0.62, 0.59, 0.55)
	var piedra_o := Color(0.50, 0.47, 0.44)
	var bronce := Color(0.35, 0.28, 0.16)
	var bronce_o := Color(0.26, 0.20, 0.11)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.5, gz), Vector3(4.6, 1.0, 3.4), piedra_o, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 2.6, gz), Vector3(2.7, 3.2, 2.0), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 4.45, gz), Vector3(3.3, 0.5, 2.5), piedra_o, 0.0)
	var yc := y + 4.7  # la base del caballo
	# el caballo: cuerpo, pecho, cuello escalonado y cabeza
	_caja_en(verts, normals, cols, Vector3(gx, yc + 1.55, gz), Vector3(2.7, 1.05, 0.95), bronce, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 1.30, yc + 1.95, gz), Vector3(0.75, 0.85, 0.72), bronce, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 1.72, yc + 2.42, gz), Vector3(0.62, 0.72, 0.5), bronce_o, 0.0)
	# las patas: una delantera levantada, como en el monumento
	_caja_en(verts, normals, cols, Vector3(gx + 1.02, yc + 0.52, gz + 0.30), Vector3(0.26, 1.05, 0.26), bronce, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 1.35, yc + 1.02, gz - 0.30), Vector3(0.24, 0.5, 0.24), bronce, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 1.62, yc + 0.86, gz - 0.30), Vector3(0.55, 0.22, 0.22), bronce, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx - 1.05, yc + 0.52, gz + 0.30), Vector3(0.26, 1.05, 0.26), bronce, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx - 1.05, yc + 0.52, gz - 0.30), Vector3(0.26, 1.05, 0.26), bronce_o, 0.0)
	# la cola
	_caja_en(verts, normals, cols, Vector3(gx - 1.52, yc + 1.45, gz), Vector3(0.28, 1.15, 0.3), bronce_o, 0.0)
	# el jinete: piernas, torso, cabeza con bicornio y el brazo de las riendas
	_caja_en(verts, normals, cols, Vector3(gx - 0.05, yc + 2.02, gz + 0.56), Vector3(0.95, 0.62, 0.2), bronce_o, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx - 0.05, yc + 2.02, gz - 0.56), Vector3(0.95, 0.62, 0.2), bronce_o, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx - 0.05, yc + 2.72, gz), Vector3(0.62, 1.05, 0.52), bronce, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 0.42, yc + 2.55, gz + 0.18), Vector3(0.85, 0.2, 0.2), bronce, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx - 0.02, yc + 3.48, gz), Vector3(0.34, 0.4, 0.34), bronce_o, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx - 0.02, yc + 3.74, gz), Vector3(0.62, 0.14, 0.3), bronce_o, 0.0)

func _hito_zubia(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# La Glorieta del Doctor Zubía: jardín cerrado con verja, caminos
	# cruzados y su monumento en el centro, frente al Sagasta.
	var y := _altura(gx, gz)
	var verja := Color(0.16, 0.17, 0.18)
	var grava := Color(0.78, 0.74, 0.66)
	var piedra := Color(0.66, 0.62, 0.56)
	var bronce := Color(0.35, 0.28, 0.16)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.04, gz), Vector3(27.0, 0.08, 3.2), grava, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.04, gz), Vector3(3.2, 0.08, 19.0), grava, 0.0)
	for lado in [-1.0, 1.0]:
		_caja_en(verts, normals, cols, Vector3(gx + lado * 6.8, y + 0.45, gz - 9.5), Vector3(13.4, 0.9, 0.08), verja, 0.0)
		_caja_en(verts, normals, cols, Vector3(gx + lado * 6.8, y + 0.45, gz + 9.5), Vector3(13.4, 0.9, 0.08), verja, 0.0)
		_caja_en(verts, normals, cols, Vector3(gx - 13.5, y + 0.45, gz + lado * 4.9), Vector3(0.08, 0.9, 9.0), verja, 0.0)
		_caja_en(verts, normals, cols, Vector3(gx + 13.5, y + 0.45, gz + lado * 4.9), Vector3(0.08, 0.9, 9.0), verja, 0.0)
	# el monumento central: pedestal y busto
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.9, gz), Vector3(1.0, 1.8, 1.0), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 1.95, gz), Vector3(0.72, 0.3, 0.42), bronce, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 2.32, gz), Vector3(0.36, 0.44, 0.36), bronce, 0.0)
	# cuatro farolas del jardín
	for fx in [-11.0, 11.0]:
		for fz in [-7.5, 7.5]:
			_caja_en(verts, normals, cols, Vector3(gx + fx, y + 1.5, gz + fz), Vector3(0.09, 3.0, 0.09), verja, 0.0)
			_caja_en(verts, normals, cols, Vector3(gx + fx, y + 3.15, gz + fz), Vector3(0.34, 0.34, 0.34), Color(0.98, 0.90, 0.70), 0.0)

func _hito_ayto(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# La torre del reloj del Ayuntamiento de Moneo, en su esquina.
	var y := _altura(gx, gz) + 8.5
	var hormigon := Color(0.82, 0.80, 0.76)
	var oscuro := Color(0.20, 0.20, 0.22)
	_caja_en(verts, normals, cols, Vector3(gx, y + 6.5, gz), Vector3(5.2, 13.0, 5.2), hormigon, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 13.25, gz), Vector3(5.9, 0.5, 5.9), oscuro, 0.0)
	# el reloj, a mediodía y al este: esfera clara y manecillas
	for cara in [0, 1]:
		var ex := gx if cara == 0 else gx + 2.63
		var ez := gz + 2.63 if cara == 0 else gz
		var ancho := Vector3(2.6, 2.6, 0.14) if cara == 0 else Vector3(0.14, 2.6, 2.6)
		_caja_en(verts, normals, cols, Vector3(ex, y + 10.2, ez), ancho, Color(0.93, 0.91, 0.84), 0.0)
		var mv := Vector3(0.17, 1.05, 0.2) if cara == 0 else Vector3(0.2, 1.05, 0.17)
		var mh := Vector3(0.95, 0.17, 0.2) if cara == 0 else Vector3(0.2, 0.17, 0.95)
		var ox := 0.0 if cara == 0 else 0.10
		var oz := 0.10 if cara == 0 else 0.0
		_caja_en(verts, normals, cols, Vector3(ex + ox, y + 10.45, ez + oz), mv, oscuro, 0.0)
		_caja_en(verts, normals, cols, Vector3(ex + ox, y + 10.2, ez + oz), mh, oscuro, 0.0)

func _hito_breton(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# El pórtico del Teatro Bretón: seis columnas, entablamento y
	# frontón sobre su fachada norte, con la cartelera entre columnas.
	var y := _altura(gx, gz - 2.0)
	var blanco := Color(0.88, 0.85, 0.78)
	var fz := gz - 2.2
	for i in 6:
		var cx := gx - 10.0 + float(i) * 4.0
		_caja_en(verts, normals, cols, Vector3(cx, y + 3.75, fz), Vector3(0.55, 7.5, 0.55), blanco, 0.0)
		_caja_en(verts, normals, cols, Vector3(cx, y + 7.62, fz), Vector3(0.85, 0.25, 0.85), blanco, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 8.3, fz), Vector3(23.5, 1.15, 1.7), blanco, 0.0)
	# el frontón triangular
	var b1 := Vector3(gx - 5.5, y + 8.9, fz - 0.86)
	var b2 := Vector3(gx + 5.5, y + 8.9, fz - 0.86)
	var b3 := Vector3(gx + 5.5, y + 8.9, fz + 0.86)
	var b4 := Vector3(gx - 5.5, y + 8.9, fz + 0.86)
	var ap := Vector3(gx, y + 11.0, fz)
	_tri(verts, normals, cols, b1, b2, ap, false, blanco)
	_tri(verts, normals, cols, b4, b3, ap, false, blanco)
	_tri(verts, normals, cols, b2, b3, ap, false, blanco)
	_tri(verts, normals, cols, b1, ap, b4, false, blanco)
	_tri(verts, normals, cols, b1, b4, b3, false, blanco)
	_tri(verts, normals, cols, b1, b3, b2, false, blanco)
	# la cartelera
	for i in 3:
		_caja_en(verts, normals, cols, Vector3(gx - 8.0 + float(i) * 8.0, y + 2.3, gz - 0.15), Vector3(1.15, 1.85, 0.1), Color(0.62, 0.22, 0.16), 0.0)

func _hito_sanblas(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# La gran cubierta a dos aguas del Mercado de San Blas, sobre
	# las losas planas de sus tres cuerpos, con su friso de ladrillo.
	_caja_en(verts, normals, cols, Vector3(gx, _altura(gx, gz) + 9.3, gz), Vector3(61.5, 1.1, 29.8), Color(0.72, 0.52, 0.38), 0.0)
	var y := _altura(gx, gz) + 9.8
	var teja := Color(0.45, 0.32, 0.26)
	var ladrillo := Color(0.72, 0.52, 0.38)
	var xa := gx - 31.0
	var xb := gx + 30.0
	var e1 := Vector3(xa, y, gz - 14.5)
	var e2 := Vector3(xb, y, gz - 14.5)
	var e3 := Vector3(xa, y, gz + 14.5)
	var e4 := Vector3(xb, y, gz + 14.5)
	var r1 := Vector3(xa, y + 4.2, gz)
	var r2 := Vector3(xb, y + 4.2, gz)
	_tri(verts, normals, cols, e1, e2, r2, true, teja)
	_tri(verts, normals, cols, e1, r2, r1, true, teja)
	_tri(verts, normals, cols, e4, e3, r1, true, Color(0.37, 0.26, 0.21))
	_tri(verts, normals, cols, e4, r1, r2, true, Color(0.37, 0.26, 0.21))
	_tri(verts, normals, cols, e3, e1, r1, true, ladrillo)
	_tri(verts, normals, cols, e2, e4, r2, true, ladrillo)

func _hito_museo(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# La fachada del Palacio de Espartero a la Plaza de San Agustín:
	# puerta mayor, su balcón con el escudo y dos balcones laterales.
	var y := _altura(gx - 7.0, gz)
	var piedra := Color(0.82, 0.72, 0.55)
	var oscuro := Color(0.25, 0.22, 0.19)
	var fx := gx - 6.8
	_caja_en(verts, normals, cols, Vector3(fx, y + 1.7, gz), Vector3(0.3, 3.4, 2.3), oscuro, 0.0)
	_caja_en(verts, normals, cols, Vector3(fx - 0.35, y + 4.55, gz), Vector3(1.0, 0.18, 3.1), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(fx - 0.8, y + 5.0, gz), Vector3(0.07, 0.75, 3.1), oscuro, 0.0)
	_caja_en(verts, normals, cols, Vector3(fx - 0.1, y + 6.9, gz), Vector3(0.22, 1.15, 0.95), Color(0.88, 0.80, 0.62), 0.0)
	for lz in [-6.0, 6.0]:
		_caja_en(verts, normals, cols, Vector3(fx - 0.35, y + 4.55, gz + lz), Vector3(1.0, 0.18, 2.2), piedra, 0.0)
		_caja_en(verts, normals, cols, Vector3(fx - 0.8, y + 5.0, gz + lz), Vector3(0.07, 0.75, 2.2), oscuro, 0.0)

func _hito_casa(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# La Casa de las Ciencias (la antigua estación): su cuerpo central
	# con el reloj y las puertas de la fachada que mira al río.
	var y := _altura(gx, gz)
	var piedra := Color(0.80, 0.72, 0.58)
	var teja := Color(0.48, 0.30, 0.22)
	var oscuro := Color(0.25, 0.22, 0.19)
	var yr := y + 11.5
	_caja_en(verts, normals, cols, Vector3(gx, yr + 1.1, gz), Vector3(5.2, 2.2, 6.2), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, yr + 2.6, gz), Vector3(3.8, 0.8, 4.6), teja, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, yr + 3.4, gz), Vector3(2.3, 0.8, 3.0), teja, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, yr + 4.15, gz), Vector3(0.9, 0.7, 1.3), teja, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, yr + 1.2, gz + 3.18), Vector3(1.7, 1.7, 0.14), Color(0.93, 0.91, 0.84), 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, yr + 1.32, gz + 3.28), Vector3(0.14, 0.62, 0.1), oscuro, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, yr + 1.2, gz + 3.28), Vector3(0.55, 0.14, 0.1), oscuro, 0.0)
	for dx in [7.0, 14.0, 21.0]:
		_caja_en(verts, normals, cols, Vector3(gx + dx, y + 1.5, gz + 14.2), Vector3(2.2, 3.0, 0.25), oscuro, 0.0)

func _hito_franco(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# Franco-Españolas: la chimenea de ladrillo sobre las naves y la
	# puerta de la bodega al sur.
	var y := _altura(gx, gz)
	var lad := Color(0.55, 0.30, 0.24)
	var lad_o := Color(0.45, 0.24, 0.19)
	_caja_en(verts, normals, cols, Vector3(gx, y + 3.0, gz), Vector3(3.0, 6.0, 3.0), lad, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 9.0, gz), Vector3(2.5, 6.0, 2.5), lad, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 12.2, gz), Vector3(2.6, 0.45, 2.6), lad_o, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 14.7, gz), Vector3(2.0, 5.0, 2.0), lad, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 17.4, gz), Vector3(2.3, 0.5, 2.3), lad_o, 0.0)
	var gy := _altura(gx + 36.0, gz + 62.0)
	var piedra := Color(0.66, 0.62, 0.56)
	for dx in [-4.5, 4.5]:
		_caja_en(verts, normals, cols, Vector3(gx + 36.0 + dx, gy + 1.7, gz + 62.0), Vector3(0.85, 3.4, 0.85), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 36.0, gy + 3.75, gz + 62.0), Vector3(10.0, 0.7, 0.95), piedra, 0.0)
	# El nombre de la bodega, en grande: sobre la viga de la
	# puerta y coronando la fachada sur de la nave que hay tras
	# ella (la de 2 plantas). Sin esto el complejo no tenia
	# ningun cartel visible desde la calle (Jon, 2026-11-24).
	_rotulos_tile_actual.append({"n": "Franco-Españolas", "h": Vector2(0, 1), "w": 9.4, "g": 2.0, "p": Vector3(gx + 36.0, gy + 3.75, gz + 62.0 + 0.58)})
	var fn := Vector2(-0.22, 0.97)
	var fx := gx + 30.1
	var fz := gz + 44.0
	var py := _altura(fx, fz)
	var rot_f := atan2(fn.x, fn.y)
	var vino := Color(0.30, 0.09, 0.15)
	_caja_en(verts, normals, cols, Vector3(fx + fn.x * 0.16, py + 5.05, fz + fn.y * 0.16), Vector3(19.0, 1.6, 0.18), vino, rot_f)
	_caja_en(verts, normals, cols, Vector3(fx + fn.x * 0.16, py + 5.90, fz + fn.y * 0.16), Vector3(19.0, 0.09, 0.20), Color(0.85, 0.88, 0.90), rot_f)
	_rotulos_tile_actual.append({"n": "Bodegas Franco-Españolas", "h": fn, "w": 18.6, "g": 4.2, "p": Vector3(fx + fn.x * 0.35, py + 5.05, fz + fn.y * 0.35)})

func _datos_enamorados() -> Dictionary:
	# La planta del parque, horneada desde el polígono OSM:
	# celdas de césped (fuera de calles y edificios), árboles
	# y bancos junto a los caminos de paseo.
	if not _enamorados_datos.is_empty():
		return _enamorados_datos
	var ruta := "res://datos/ciudad/enamorados.json"
	if FileAccess.file_exists(ruta):
		var d = JSON.parse_string(FileAccess.get_file_as_string(ruta))
		if d != null and d.has("celdas"):
			_enamorados_datos = d
	return _enamorados_datos

func _hito_enamorados(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# El Parque de los Enamorados (pedido de Jon: «está
	# completamente vacío, trabájalo más, más zona verde»):
	# el césped sobre el polígono real del parque y los
	# bancos junto a los caminos. La gente va en
	# _enamorados_gente().
	var datos := _datos_enamorados()
	if datos.is_empty():
		return
	var verde1 := Color(0.30, 0.50, 0.22)
	var verde2 := Color(0.35, 0.55, 0.25)
	for celda in datos["celdas"]:
		var cx := float(celda[0])
		var cz := float(celda[1])
		var hh: float = fposmod(sin(cx * 12.9898 + cz * 78.233) * 43758.5453, 1.0)
		_caja_en(verts, normals, cols, Vector3(cx, _altura(cx, cz) + 0.04, cz), Vector3(12.6, 0.09, 12.6), verde1 if hh < 0.5 else verde2, 0.0)
	for banco in datos.get("bancos", []):
		_banco_paseo(verts, normals, cols, Vector2(float(banco[0]), float(banco[1])), float(banco[2]))

func _enamorados_gente() -> void:
	# La vida del parque (pedido de Jon): una pareja sentada
	# en un banco y otra andando de la mano por el parque.
	if _enamorados_hecho:
		return
	var datos := _datos_enamorados()
	if datos.is_empty():
		return
	_enamorados_hecho = true
	var arboles_m := _malla_arboles(datos.get("arboles", []))
	if arboles_m != null:
		add_child(arboles_m)
	var bancos: Array = datos.get("bancos", [])
	if bancos.size() > 3:
		var banco: Array = bancos[3]
		var bx := float(banco[0])
		var bz := float(banco[1])
		var rot_b := float(banco[2])
		var lat_b := Vector3(cos(rot_b), 0, -sin(rot_b))
		var cen_b := Vector3(bx, _altura(bx, bz), bz)
		var camisas_s: Array = [Color(0.80, 0.30, 0.35), Color(0.25, 0.40, 0.75)]
		var pelos_s: Array = [Color(0.16, 0.11, 0.07), Color(0.45, 0.30, 0.16)]
		for k in 2:
			var per_s := _persona_en(cen_b, Vector2.ZERO, camisas_s[k], pelos_s[k])
			var raiz_s: Node3D = per_s["raiz"]
			var sitio_s := cen_b + lat_b * (-0.45 if k == 0 else 0.45)
			raiz_s.position = Vector3(sitio_s.x, _altura(sitio_s.x, sitio_s.z) + 0.52, sitio_s.z)
			raiz_s.rotation.y = rot_b
			(per_s["pi"] as Node3D).rotation.x = -1.25
			(per_s["pd"] as Node3D).rotation.x = -1.25
			_estaticos.append({"d": per_s, "raiz": raiz_s, "tipo": "sentado", "fase": _rng.randf() * 6.0})
	# La pareja que pasea de la mano: dos figuras que dan
	# vueltas al parque por una elipse; se mueven en
	# _mover_peatones, en su propio bloque.
	var per_a := _persona_en(Vector3(-2219, 0, 103), Vector2.ZERO, Color(0.85, 0.55, 0.20), Color(0.16, 0.11, 0.07))
	var per_b := _persona_en(Vector3(-2219, 0, 104), Vector2.ZERO, Color(0.55, 0.30, 0.60), Color(0.70, 0.60, 0.35))
	_pareja_enamorados = {"a": per_a, "b": per_b, "tita": 0.0, "fase": 0.0}
	print("ENAMORADOS_OK bancos=", bancos.size(), " arboles=", (datos.get("arboles", []) as Array).size())

func _hito_puerta(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# La Puerta del Ebro: el gran marco de acero cortén de la ribera.
	var y := _altura(gx, gz)
	var corten := Color(0.55, 0.32, 0.20)
	var corten_o := Color(0.44, 0.25, 0.15)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.12, gz), Vector3(15.5, 0.25, 3.2), corten_o, 0.0)
	for dx in [-6.5, 6.5]:
		_caja_en(verts, normals, cols, Vector3(gx + dx, y + 4.5, gz), Vector3(1.1, 9.0, 1.1), corten, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 9.35, gz), Vector3(14.4, 1.15, 1.25), corten, 0.0)
	_viga(verts, normals, cols, Vector3(gx - 6.5, y + 6.4, gz), Vector3(gx - 4.0, y + 8.8, gz), Vector2(0, 1), 0.16, 0.16, corten_o)
	_viga(verts, normals, cols, Vector3(gx + 6.5, y + 6.4, gz), Vector3(gx + 4.0, y + 8.8, gz), Vector2(0, 1), 0.16, 0.16, corten_o)

func _hito_danza(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# El Bosque de la Danza de La Ribera: bailarines de acero en corro.
	var y := _altura(gx, gz)
	var corten := Color(0.55, 0.32, 0.20)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.035, gz), Vector3(8.4, 0.07, 8.4), Color(0.78, 0.74, 0.66), 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.035, gz), Vector3(8.4, 0.07, 8.4), Color(0.78, 0.74, 0.66), PI / 4.0)
	for i in 6:
		var a := float(i) * PI / 3.0 + 0.3
		var px := gx + cos(a) * 2.9
		var pz := gz + sin(a) * 2.9
		var h := 3.4 + float(i % 3) * 1.05
		_caja_en(verts, normals, cols, Vector3(px, y + h * 0.5, pz), Vector3(0.17, h, 0.17), corten, 0.0)
		_caja_en(verts, normals, cols, Vector3(px, y + h + 0.28, pz), Vector3(0.75, 0.55, 0.09), corten, a * 1.7)

func _hito_riojanos(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# La Fuente de los Riojanos Ilustres: gran vaso circular con los
	# bustos de los ilustres alrededor de su isla central.
	var y := _altura(gx, gz)
	var piedra := Color(0.70, 0.64, 0.54)
	var bronce := Color(0.35, 0.28, 0.16)
	for i in 12:
		var a := float(i) * PI / 6.0
		_caja_en(verts, normals, cols, Vector3(gx + sin(a) * 5.4, y + 0.4, gz + cos(a) * 5.4), Vector3(2.9, 0.8, 0.35), piedra, a)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.55, gz), Vector3(8.8, 0.06, 8.8), Color(0.45, 0.66, 0.78), PI / 4.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.3, gz), Vector3(2.5, 0.6, 2.5), piedra, PI / 4.0)
	for i in 4:
		var a := float(i) * PI / 2.0
		var px := gx + sin(a) * 3.2
		var pz := gz + cos(a) * 3.2
		_caja_en(verts, normals, cols, Vector3(px, y + 0.95, pz), Vector3(0.55, 1.3, 0.55), piedra, 0.0)
		_caja_en(verts, normals, cols, Vector3(px, y + 1.82, pz), Vector3(0.36, 0.44, 0.36), bronce, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 1.6, gz), Vector3(0.5, 2.6, 0.5), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 3.05, gz), Vector3(0.36, 0.36, 0.36), bronce, 0.0)

func _tonel(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, px: float, py: float, pz: float, rot: float) -> void:
	# Un tonel de vino tumbado: cuerpo abombado y aros oscuros.
	var mad := Color(0.45, 0.32, 0.20)
	var aro := Color(0.25, 0.18, 0.12)
	_caja_en(verts, normals, cols, Vector3(px, py + 0.48, pz), Vector3(0.82, 0.82, 0.32), mad, rot)
	_caja_en(verts, normals, cols, Vector3(px, py + 0.48, pz), Vector3(0.96, 0.96, 0.42), mad, rot)
	var dir := Vector2(sin(rot), cos(rot))
	_caja_en(verts, normals, cols, Vector3(px - dir.x * 0.3, py + 0.48, pz - dir.y * 0.3), Vector3(0.99, 0.99, 0.09), aro, rot)
	_caja_en(verts, normals, cols, Vector3(px + dir.x * 0.3, py + 0.48, pz + dir.y * 0.3), Vector3(0.99, 0.99, 0.09), aro, rot)

func _farola_h(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, px: float, py: float, pz: float) -> void:
	_caja_en(verts, normals, cols, Vector3(px, py + 1.5, pz), Vector3(0.11, 3.0, 0.11), Color(0.16, 0.17, 0.19), 0.0)
	_caja_en(verts, normals, cols, Vector3(px, py + 3.1, pz), Vector3(0.4, 0.3, 0.4), Color(1.0, 0.86, 0.58), 0.0)

func _hito_mercado(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# La Plaza del Mercado, a los pies de La Redonda: su fuente
	# central, farolas y bancos alrededor.
	var y := _altura(gx, gz)
	var piedra := Color(0.70, 0.64, 0.54)
	for i in 8:
		var a := float(i) * PI / 4.0
		_caja_en(verts, normals, cols, Vector3(gx + sin(a) * 2.6, y + 0.35, gz + cos(a) * 2.6), Vector3(2.05, 0.7, 0.3), piedra, a)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.42, gz), Vector3(4.3, 0.05, 4.3), Color(0.45, 0.66, 0.78), PI / 4.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.95, gz), Vector3(0.42, 1.1, 0.42), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 1.65, gz), Vector3(0.85, 0.3, 0.85), piedra, 0.0)
	for i in 4:
		var a := float(i) * PI / 2.0 + PI / 4.0
		_farola_h(verts, normals, cols, gx + sin(a) * 7.5, y, gz + cos(a) * 7.5)
		_caja_en(verts, normals, cols, Vector3(gx + sin(a) * 5.2, y + 0.45, gz + cos(a) * 5.2), Vector3(1.8, 0.09, 0.45), Color(0.40, 0.30, 0.20), a + PI / 2.0)

func _hito_barto(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# La Plaza de San Bartolomé: el suelo de piedra y su crucero.
	var y := _altura(gx, gz)
	var piedra := Color(0.72, 0.66, 0.56)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.03, gz), Vector3(17.0, 0.06, 17.0), Color(0.76, 0.72, 0.64), 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.03, gz), Vector3(17.0, 0.06, 17.0), Color(0.76, 0.72, 0.64), PI / 4.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.5, gz), Vector3(1.25, 1.0, 1.25), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 2.25, gz), Vector3(0.34, 2.5, 0.34), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 4.05, gz), Vector3(0.2, 1.15, 0.2), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 4.2, gz), Vector3(0.85, 0.2, 0.2), piedra, 0.0)
	for dx in [-8.0, 8.0]:
		for dz in [-8.0, 8.0]:
			_farola_h(verts, normals, cols, gx + dx, y, gz + dz)

func _hito_calado(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# El Calado de San Gregorio en Ruavieja: el portal de piedra de
	# la bodega subterránea y sus toneles en la puerta.
	var y := _altura(gx, gz)
	var piedra := Color(0.62, 0.55, 0.45)
	var oscuro := Color(0.16, 0.13, 0.10)
	for dx in [-1.9, 1.9]:
		_caja_en(verts, normals, cols, Vector3(gx + dx, y + 1.6, gz), Vector3(0.7, 3.2, 0.7), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 3.55, gz), Vector3(4.6, 0.8, 0.9), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 1.3, gz - 0.2), Vector3(3.1, 2.6, 0.2), oscuro, 0.0)
	_tonel(verts, normals, cols, gx - 3.6, y, gz + 1.2, 0.3)
	_tonel(verts, normals, cols, gx + 3.6, y, gz + 1.2, -0.2)
	_tonel(verts, normals, cols, gx + 3.6, y + 0.92, gz + 1.2, 0.15)

func _hito_lagares(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# El Espacio Lagares: la entrada actual, con su marquesina,
	# junto a los toneles del barrio del vino.
	var y := _altura(gx, gz)
	var acero := Color(0.30, 0.32, 0.35)
	for dx in [-2.6, 2.6]:
		_caja_en(verts, normals, cols, Vector3(gx + dx, y + 1.5, gz + 1.0), Vector3(0.14, 3.0, 0.14), acero, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 3.1, gz + 1.0), Vector3(6.4, 0.18, 2.3), Color(0.35, 0.55, 0.55), 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 1.35, gz - 0.2), Vector3(3.4, 2.7, 0.2), Color(0.20, 0.24, 0.26), 0.0)
	_tonel(verts, normals, cols, gx - 4.4, y, gz + 1.4, 0.1)
	_tonel(verts, normals, cols, gx + 4.4, y, gz + 1.4, -0.3)

func _hito_tabacalera(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# La chimenea de la Antigua Tabacalera sobre sus naves.
	var y := _altura(gx, gz)
	var lad := Color(0.66, 0.47, 0.35)
	var lad_o := Color(0.55, 0.38, 0.28)
	_caja_en(verts, normals, cols, Vector3(gx, y + 2.75, gz), Vector3(2.9, 5.5, 2.9), lad, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 8.25, gz), Vector3(2.4, 5.5, 2.4), lad, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 11.2, gz), Vector3(2.5, 0.45, 2.5), lad_o, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 13.6, gz), Vector3(1.9, 4.4, 1.9), lad, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 16.0, gz), Vector3(2.2, 0.5, 2.2), lad_o, 0.0)

func _hito_parlamento(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# La Plaza del Parlamento: suelo de piedra, farolas y los
	# mástiles con las banderas ante la sede.
	var y := _altura(gx, gz)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.03, gz), Vector3(21.0, 0.06, 15.0), Color(0.76, 0.72, 0.64), 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.03, gz), Vector3(21.0, 0.06, 15.0), Color(0.76, 0.72, 0.64), PI / 4.0)
	for dx in [-3.2, 3.2]:
		_caja_en(verts, normals, cols, Vector3(gx + dx, y + 3.25, gz + 4.0), Vector3(0.09, 6.5, 0.09), Color(0.55, 0.57, 0.60), 0.0)
	_caja_en(verts, normals, cols, Vector3(gx - 3.2 + 0.6, y + 5.9, gz + 4.0), Vector3(1.15, 0.72, 0.06), Color(0.80, 0.62, 0.16), 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 3.2 + 0.6, y + 6.05, gz + 4.0), Vector3(1.15, 0.24, 0.06), Color(0.88, 0.86, 0.82), 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 3.2 + 0.6, y + 5.81, gz + 4.0), Vector3(1.15, 0.24, 0.06), Color(0.62, 0.20, 0.18), 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 3.2 + 0.6, y + 5.57, gz + 4.0), Vector3(1.15, 0.24, 0.06), Color(0.25, 0.48, 0.30), 0.0)
	for dx in [-9.0, 9.0]:
		for dz in [-6.0, 6.0]:
			_farola_h(verts, normals, cols, gx + dx, y, gz + dz)

func _hito_trevijano(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# Las Escuelas Trevijano: la puerta del colegio y su mástil
	# (la posición es la aproximada de su calle).
	var y := _altura(gx, gz)
	var lad := Color(0.74, 0.58, 0.42)
	for dx in [-2.3, 2.3]:
		_caja_en(verts, normals, cols, Vector3(gx + dx, y + 1.3, gz), Vector3(0.5, 2.6, 0.5), lad, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, y + 2.85, gz), Vector3(5.4, 0.5, 0.6), lad, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 4.6, y + 3.0, gz + 1.5), Vector3(0.08, 6.0, 0.08), Color(0.55, 0.57, 0.60), 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 4.6 + 0.55, y + 5.3, gz + 1.5), Vector3(1.05, 0.65, 0.06), Color(0.80, 0.62, 0.16), 0.0)

func _tri_u(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, a: Vector3, b: Vector3, c: Vector3, forz: bool, col: Color) -> void:
	_tri(verts, normals, cols, a, b, c, forz, col, uvs, PackedVector2Array([Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)]))

func _caja_u(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, centro: Vector3, tam: Vector3, col: Color, rot: float) -> void:
	var tv := PackedVector3Array()
	var tn := PackedVector3Array()
	var tc := PackedColorArray()
	_caja_en(tv, tn, tc, centro, tam, col, rot)
	for v in tv:
		verts.append(v)
		uvs.append(Vector2(0.02, 0.02))
	for n in tn:
		normals.append(n)
	for c in tc:
		cols.append(c)

func _anillo(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, pa: Array, ha: float, pb: Array, hb: float, col: Color) -> void:
	# Banda entre dos anillos de puntos: dos triángulos por tramo.
	for i in pa.size():
		var j := (i + 1) % pa.size()
		var a := Vector3(pa[i].x, ha, pa[i].y)
		var b := Vector3(pa[j].x, ha, pa[j].y)
		var c := Vector3(pb[j].x, hb, pb[j].y)
		var d := Vector3(pb[i].x, hb, pb[i].y)
		_tri_u(verts, normals, cols, uvs, a, b, c, true, col)
		_tri_u(verts, normals, cols, uvs, a, c, d, true, col)

func _muro_anillo(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, pts: Array, y0: float, y1: float, col: Color) -> void:
	# Muro vertical siguiendo un anillo de puntos, con el mismo orden
	# de vértices que las fachadas genéricas.
	for i in pts.size():
		var j := (i + 1) % pts.size()
		var ab := Vector3(pts[i].x, y0, pts[i].y)
		var bb := Vector3(pts[j].x, y0, pts[j].y)
		var bt := Vector3(pts[j].x, y1, pts[j].y)
		var at := Vector3(pts[i].x, y1, pts[i].y)
		_tri_u(verts, normals, cols, uvs, ab, bb, bt, false, col)
		_tri_u(verts, normals, cols, uvs, ab, bt, at, false, col)

func _plaza_toros(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, poly: PackedVector2Array, centro: Vector2, base: float) -> void:
	# La plaza de verdad: muro circular de ladrillo, cornisa, tejado
	# en anillo sobre las gradas, las gradas bajando y el albero en
	# el centro. Antes era una losa plana de una planta.
	var pts: Array = []
	var paso := maxi(1, poly.size() / 56)
	var k := 0
	while k < poly.size():
		pts.append(poly[k])
		k += paso
	var ladrillo := Color(0.60, 0.40, 0.29)
	_muro_anillo(verts, normals, cols, uvs, pts, base, base + 11.5, ladrillo)
	_muro_anillo(verts, normals, cols, uvs, pts, base + 3.2, base + 3.75, ladrillo.darkened(0.18))
	var fuera: Array = []
	var grada_a: Array = []
	var grada_b: Array = []
	for p in pts:
		fuera.append(centro + (p - centro) * 1.015)
		grada_a.append(centro + (p - centro) * 0.60)
		grada_b.append(centro + (p - centro) * 0.40)
	_anillo(verts, normals, cols, uvs, fuera, base + 12.15, pts, base + 11.5, Color(0.78, 0.70, 0.58))
	_anillo(verts, normals, cols, uvs, pts, base + 11.5, grada_a, base + 8.0, Color(0.34, 0.30, 0.27))
	_anillo(verts, normals, cols, uvs, grada_a, base + 8.0, grada_b, base + 2.2, Color(0.56, 0.54, 0.51))
	_muro_anillo(verts, normals, cols, uvs, grada_b, base + 0.2, base + 2.2, Color(0.45, 0.32, 0.20))
	var cen3 := Vector3(centro.x, base + 0.25, centro.y)
	for i in grada_b.size():
		var j := (i + 1) % grada_b.size()
		_tri_u(verts, normals, cols, uvs, cen3, Vector3(grada_b[i].x, base + 0.25, grada_b[i].y), Vector3(grada_b[j].x, base + 0.25, grada_b[j].y), true, Color(0.78, 0.66, 0.44))
	# La puerta grande, al sur (hacia la ciudad): hueco oscuro con
	# marco de piedra.
	var sur: Vector2 = pts[0]
	for p in pts:
		if p.y > sur.y:
			sur = p
	var dir_s := (sur - centro).normalized()
	var rot_s := atan2(dir_s.x, dir_s.y)
	var pd := centro + dir_s * (centro.distance_to(sur) + 0.3)
	_caja_u(verts, normals, cols, uvs, Vector3(pd.x, base + 3.1, pd.y), Vector3(6.4, 6.2, 0.7), Color(0.16, 0.12, 0.10), rot_s)
	_caja_u(verts, normals, cols, uvs, Vector3(pd.x, base + 6.6, pd.y), Vector3(8.0, 0.8, 0.9), Color(0.78, 0.70, 0.58), rot_s)
	for lado in [-1.0, 1.0]:
		var pp: Vector2 = pd + Vector2(-dir_s.y, dir_s.x) * (3.6 * lado)
		_caja_u(verts, normals, cols, uvs, Vector3(pp.x, base + 3.3, pp.y), Vector3(0.8, 6.6, 0.9), Color(0.78, 0.70, 0.58), rot_s)
	print("HITO_OK toros")

func _riojaforum(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, poly: PackedVector2Array, centro: Vector2, base: float, plantas: int) -> void:
	# El palacio de congresos: volúmenes de piedra clara con la
	# planta baja entera de cristal, no bloques anónimos.
	var h := maxf(9.0, float(plantas) * 3.4)
	var cristal := Color(0.42, 0.55, 0.64)
	var piedra := Color(0.84, 0.80, 0.72)
	for i in poly.size():
		var p1 := poly[i]
		var p2 := poly[(i + 1) % poly.size()]
		for banda in [[base, base + 3.4, cristal], [base + 3.4, base + h, piedra]]:
			var ab := Vector3(p1.x, banda[0], p1.y)
			var bb := Vector3(p2.x, banda[0], p2.y)
			var bt := Vector3(p2.x, banda[1], p2.y)
			var at := Vector3(p1.x, banda[1], p1.y)
			_tri_u(verts, normals, cols, uvs, ab, bb, bt, false, banda[2])
			_tri_u(verts, normals, cols, uvs, ab, bt, at, false, banda[2])
	var tris := Geometry2D.triangulate_polygon(poly)
	for i in range(0, tris.size(), 3):
		_tri_u(verts, normals, cols, uvs, Vector3(poly[tris[i]].x, base + h, poly[tris[i]].y), Vector3(poly[tris[i + 1]].x, base + h, poly[tris[i + 1]].y), Vector3(poly[tris[i + 2]].x, base + h, poly[tris[i + 2]].y), true, Color(0.45, 0.43, 0.40))
	if plantas == 1:
		# El lucernario corrido de la sala grande, visto desde el aire
		var minx := 1e9
		var maxx := -1e9
		var minz := 1e9
		var maxz := -1e9
		for p in poly:
			minx = minf(minx, p.x)
			maxx = maxf(maxx, p.x)
			minz = minf(minz, p.y)
			maxz = maxf(maxz, p.y)
		_caja_u(verts, normals, cols, uvs, Vector3(centro.x, base + h + 0.45, centro.y), Vector3((maxx - minx) * 0.55, 0.9, (maxz - minz) * 0.38), cristal.lightened(0.15), 0.0)
	print("HITO_OK riojaforum")

func _nave(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, poly: PackedVector2Array, centro: Vector2, base: float, banda: Color) -> void:
	# Una nave comercial de verdad: 9 m de pared clara y su banda
	# de marca arriba, no una casa de una planta de 3 m.
	var pared := Color(0.80, 0.79, 0.76)
	for i in poly.size():
		var p1 := poly[i]
		var p2 := poly[(i + 1) % poly.size()]
		for bnd in [[base, base + 7.2, pared], [base + 7.2, base + 9.0, banda]]:
			var ab := Vector3(p1.x, bnd[0], p1.y)
			var bb := Vector3(p2.x, bnd[0], p2.y)
			var bt := Vector3(p2.x, bnd[1], p2.y)
			var at := Vector3(p1.x, bnd[1], p1.y)
			_tri_u(verts, normals, cols, uvs, ab, bb, bt, false, bnd[2])
			_tri_u(verts, normals, cols, uvs, ab, bt, at, false, bnd[2])
	var tris := Geometry2D.triangulate_polygon(poly)
	for i in range(0, tris.size(), 3):
		_tri_u(verts, normals, cols, uvs, Vector3(poly[tris[i]].x, base + 9.0, poly[tris[i]].y), Vector3(poly[tris[i + 1]].x, base + 9.0, poly[tris[i + 1]].y), Vector3(poly[tris[i + 2]].x, base + 9.0, poly[tris[i + 2]].y), true, Color(0.45, 0.44, 0.42))
	print("HITO_OK nave")

func _banda_u(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, anillo: PackedVector2Array, c: Vector2, s1: float, y1: float, s2: float, y2: float, col: Color) -> void:
	# Una banda entre dos anillos escalados del contorno (muro,
	# tejado inclinado o huella de grada), con sus UV.
	for i in anillo.size():
		var p1 := anillo[i]
		var p2 := anillo[(i + 1) % anillo.size()]
		var a := Vector3(c.x + (p1.x - c.x) * s1, y1, c.y + (p1.y - c.y) * s1)
		var b := Vector3(c.x + (p2.x - c.x) * s1, y1, c.y + (p2.y - c.y) * s1)
		var bt := Vector3(c.x + (p2.x - c.x) * s2, y2, c.y + (p2.y - c.y) * s2)
		var at := Vector3(c.x + (p1.x - c.x) * s2, y2, c.y + (p1.y - c.y) * s2)
		_tri_u(verts, normals, cols, uvs, a, b, bt, false, col)
		_tri_u(verts, normals, cols, uvs, a, bt, at, false, col)

func _las_gaunas(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, partes: Array) -> void:
	# El Estadio Municipal Las Gaunas a medida (Bloque 5): el
	# Catastro lo parte en seis piezas; de sus puntos sale la
	# envolvente real, y sobre ella van el muro, la banda roja, el
	# tejado, las gradas en anillo, el campo con sus franjas y las
	# cuatro torres de focos. El MDT hunde el centro (el campo está
	# en un cuenco): la base se toma del anillo, no del centro.
	var C := Vector2(-864.0, 1538.0)
	var NB := 56
	var paso_a := TAU / float(NB)
	var radio := PackedFloat32Array()
	radio.resize(NB)
	for parte in partes:
		var poly := PackedVector2Array()
		var ip := 1
		while ip + 1 < parte.size():
			poly.append(Vector2(float(parte[ip]), float(parte[ip + 1])))
			ip += 2
		if poly.size() < 3:
			continue
		var cen := Vector2.ZERO
		for p in poly:
			cen += p
		cen /= float(poly.size())
		var ar := 0.0
		for i in poly.size():
			var q1 := poly[i]
			var q2 := poly[(i + 1) % poly.size()]
			ar += q1.x * q2.y - q2.x * q1.y
		if absf(ar) * 0.5 <= 900.0 or cen.x < -960.0 or cen.x > -765.0 or cen.y < 1435.0 or cen.y > 1645.0:
			continue
		for p in poly:
			var d := p - C
			var b := int(floor((atan2(d.y, d.x) + PI) / paso_a)) % NB
			if d.length() > radio[b]:
				radio[b] = d.length()
	for i in NB:
		if radio[i] < 30.0:
			var iz := 0.0
			var de := 0.0
			for k in range(1, NB):
				if radio[(i - k + NB * 2) % NB] >= 30.0:
					iz = radio[(i - k + NB * 2) % NB]
					break
			for k in range(1, NB):
				if radio[(i + k) % NB] >= 30.0:
					de = radio[(i + k) % NB]
					break
			radio[i] = (iz + de) * 0.5
	var suave := PackedFloat32Array()
	suave.resize(NB)
	for i in NB:
		suave[i] = radio[(i - 1 + NB) % NB] * 0.25 + radio[i] * 0.5 + radio[(i + 1) % NB] * 0.25
	var anillo := PackedVector2Array()
	for i in NB:
		var a := -PI + (float(i) + 0.5) * paso_a
		anillo.append(C + Vector2(cos(a), sin(a)) * suave[i])
	var base := 0.0
	for k in 8:
		var a2 := float(k) * TAU / 8.0
		var ps := C + Vector2(cos(a2), sin(a2)) * 78.0
		base += _altura_terreno(ps.x, ps.y)
	base = base / 8.0 - 0.5
	var hormigon := Color(0.78, 0.76, 0.72)
	_banda_u(verts, normals, cols, uvs, anillo, C, 1.0, base - 0.6, 1.0, base + 12.4, hormigon)
	_banda_u(verts, normals, cols, uvs, anillo, C, 1.0, base + 12.4, 1.0, base + 14.2, Color(0.62, 0.10, 0.12))
	_banda_u(verts, normals, cols, uvs, anillo, C, 1.0, base + 14.2, 0.80, base + 11.8, Color(0.50, 0.51, 0.54))
	for k in 3:
		var s_out := 0.80 - float(k) * 0.055
		var h := 11.8 - float(k) * 2.2
		_banda_u(verts, normals, cols, uvs, anillo, C, s_out, base + h, s_out - 0.055, base + h, Color(0.60, 0.58, 0.56) if k % 2 == 0 else Color(0.55, 0.53, 0.51))
		_banda_u(verts, normals, cols, uvs, anillo, C, s_out - 0.055, base + h, s_out - 0.055, base + h - 2.2, Color(0.48, 0.46, 0.44))
	_banda_u(verts, normals, cols, uvs, anillo, C, 0.635, base + 5.2, 0.635, base + 1.2, Color(0.66, 0.64, 0.60))
	var interior := PackedVector2Array()
	for p in anillo:
		interior.append(C + (p - C) * 0.635)
	var tris := Geometry2D.triangulate_polygon(interior)
	for i in range(0, tris.size(), 3):
		_tri_u(verts, normals, cols, uvs, Vector3(interior[tris[i]].x, base + 1.15, interior[tris[i]].y), Vector3(interior[tris[i + 1]].x, base + 1.15, interior[tris[i + 1]].y), Vector3(interior[tris[i + 2]].x, base + 1.15, interior[tris[i + 2]].y), true, Color(0.35, 0.36, 0.34))
	for f in 10:
		var z1 := C.y - 50.0 + float(f) * 10.0
		var verde := Color(0.15, 0.40, 0.15) if f % 2 == 0 else Color(0.18, 0.45, 0.18)
		_tri_u(verts, normals, cols, uvs, Vector3(C.x - 32.0, base + 1.2, z1), Vector3(C.x + 32.0, base + 1.2, z1), Vector3(C.x + 32.0, base + 1.2, z1 + 10.0), true, verde)
		_tri_u(verts, normals, cols, uvs, Vector3(C.x - 32.0, base + 1.2, z1), Vector3(C.x + 32.0, base + 1.2, z1 + 10.0), Vector3(C.x - 32.0, base + 1.2, z1 + 10.0), true, verde)
	for k in 4:
		var a3 := PI * 0.25 + float(k) * PI * 0.5
		var dir3 := Vector2(cos(a3), sin(a3))
		var pos3 := C + dir3 * 96.0
		var rot3 := atan2(-dir3.x, -dir3.y)
		_caja_u(verts, normals, cols, uvs, Vector3(pos3.x, base + 12.0, pos3.y), Vector3(0.5, 24.0, 0.5), Color(0.35, 0.35, 0.38), 0.0)
		var cab := pos3 - dir3 * 1.2
		_caja_u(verts, normals, cols, uvs, Vector3(cab.x, base + 24.6, cab.y), Vector3(5.0, 2.4, 0.35), Color(0.20, 0.20, 0.22), rot3)
		var pan := pos3 - dir3 * 1.45
		_caja_u(verts, normals, cols, uvs, Vector3(pan.x, base + 24.6, pan.y), Vector3(4.6, 2.0, 0.12), Color(0.92, 0.92, 0.85), rot3)
	print("GAUNAS_OK base=", snappedf(base, 0.1))

func _suelo(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, cx: float, cz: float, y: float, ancho: float, largo: float, col: Color, rot := 0.0) -> void:
	# Un rectangulo plano en el suelo (pistas, piscinas, patios).
	var d := Vector2(sin(rot), cos(rot))
	var n2 := Vector2(-d.y, d.x)
	var c := Vector2(cx, cz)
	var p1 := c + n2 * (ancho * 0.5) + d * (largo * 0.5)
	var p2 := c - n2 * (ancho * 0.5) + d * (largo * 0.5)
	var p3 := c - n2 * (ancho * 0.5) - d * (largo * 0.5)
	var p4 := c + n2 * (ancho * 0.5) - d * (largo * 0.5)
	_tri(verts, normals, cols, Vector3(p1.x, y, p1.y), Vector3(p2.x, y, p2.y), Vector3(p3.x, y, p3.y), true, col)
	_tri(verts, normals, cols, Vector3(p1.x, y, p1.y), Vector3(p3.x, y, p3.y), Vector3(p4.x, y, p4.y), true, col)

func _unir(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, centro: Vector2, base: float) -> void:
	# La sede de la UNIR, junto al Seminario: un bloque moderno
	# blanco con bandas de cristal oscuro por planta, sobre su
	# huella real en paralelogramo de OSM.
	var c := Vector2(1528.5, 521.5)
	var rot := atan2(0.952, 0.306)
	_caja_u(verts, normals, cols, uvs, Vector3(c.x, base + 7.5, c.y), Vector3(49.3, 15.0, 58.8), Color(0.88, 0.87, 0.84), rot)
	for f in range(5):
		_caja_u(verts, normals, cols, uvs, Vector3(c.x, base + 1.7 + float(f) * 3.0, c.y), Vector3(49.7, 1.7, 59.2), Color(0.14, 0.20, 0.28), rot)
	var salida := Vector2(-0.30, 0.95)
	var mid := Vector2(1521.0, 545.0)
	_caja_u(verts, normals, cols, uvs, Vector3(mid.x + salida.x * 0.3, base + 1.6, mid.y + salida.y * 0.3), Vector3(6.0, 3.2, 0.4), Color(0.10, 0.12, 0.16), atan2(salida.x, salida.y))
	_caja_u(verts, normals, cols, uvs, Vector3(mid.x + salida.x * 1.8, base + 3.6, mid.y + salida.y * 1.8), Vector3(10.0, 0.25, 3.6), Color(0.30, 0.30, 0.33), atan2(salida.x, salida.y))
	_rotulos_tile_actual.append({"n": "UNIR", "h": salida, "w": 16.0, "g": 5.0, "p": Vector3(mid.x + salida.x * 0.6, base + 13.9, mid.y + salida.y * 0.6)})
	# La caja dibujada (49,3 x 58,8 girada) es mas grande que la
	# huella de Catastro registrada como poligono: sin este solido
	# con la medida y el giro de la caja, las paredes se atravesaban.
	_registrar_solido(c.x, c.y, rot, 29.4, 24.65)
	print("UNIR_OK")

func _toyo_ito(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, centro: Vector2, base: float) -> void:
	# Los edificios de Toyo Ito (Prado Paterna): una torre
	# ondulada revestida de verde azulado, con muy pocas
	# ventanas, sobre su anillo real de OSM (33 puntos).
	var anillo: Array = [Vector2(-2575.6, 1483.7), Vector2(-2564.7, 1478.3), Vector2(-2561.2, 1472.7), Vector2(-2561.0, 1482.0), Vector2(-2560.0, 1489.7), Vector2(-2557.7, 1498.8), Vector2(-2550.3, 1487.9), Vector2(-2551.3, 1478.0), Vector2(-2551.2, 1471.5), Vector2(-2550.1, 1464.3), Vector2(-2547.3, 1453.9), Vector2(-2545.3, 1447.7), Vector2(-2543.1, 1439.7), Vector2(-2541.4, 1431.1), Vector2(-2540.6, 1421.0), Vector2(-2540.8, 1412.1), Vector2(-2542.1, 1403.2), Vector2(-2542.8, 1399.4), Vector2(-2551.9, 1404.0), Vector2(-2550.9, 1410.5), Vector2(-2550.5, 1415.3), Vector2(-2552.2, 1409.5), Vector2(-2554.3, 1401.8), Vector2(-2557.5, 1393.6), Vector2(-2568.1, 1394.4), Vector2(-2563.2, 1406.5), Vector2(-2561.1, 1416.2), Vector2(-2560.6, 1428.7), Vector2(-2562.4, 1440.7), Vector2(-2565.1, 1448.9), Vector2(-2568.5, 1458.1), Vector2(-2571.8, 1467.1), Vector2(-2574.4, 1476.7)]
	var cen := Vector2(-2556.0, 1442.0)
	var yb := _altura_terreno(cen.x, cen.y) - 0.5
	var alto := 30.0
	var verdes := [Color(0.11, 0.36, 0.31), Color(0.14, 0.42, 0.36)]
	var oscuro := Color(0.07, 0.24, 0.21)
	for i in range(anillo.size()):
		var a: Vector2 = anillo[i]
		var b: Vector2 = anillo[(i + 1) % anillo.size()]
		var dir := b - a
		var largo := dir.length()
		if largo < 0.5:
			continue
		dir /= largo
		var rot := atan2(dir.x, dir.y)
		var mid := (a + b) * 0.5
		var col: Color = verdes[i % 2]
		_caja_u(verts, normals, cols, uvs, Vector3(mid.x, yb + alto * 0.5, mid.y), Vector3(largo + 0.35, alto, 0.7), col, rot)
		_caja_u(verts, normals, cols, uvs, Vector3(mid.x, yb + alto + 0.35, mid.y), Vector3(largo + 0.35, 0.7, 0.8), oscuro, rot)
		for f in range(1, 10):
			_caja_u(verts, normals, cols, uvs, Vector3(mid.x, yb + float(f) * 3.0, mid.y), Vector3(largo + 0.38, 0.16, 0.74), oscuro, rot)
		var n2 := Vector2(-dir.y, dir.x)
		if n2.dot(mid - cen) < 0.0:
			n2 = -n2
		for f in range(10):
			for s in range(2):
				var sem := (i * 31 + f * 7 + s * 13) % 100
				if sem >= 16:
					continue
				var wp: Vector2 = a + dir * (largo * (0.33 + 0.34 * float(s))) + n2 * 0.40
				_caja_u(verts, normals, cols, uvs, Vector3(wp.x, yb + 1.0 + float(f) * 3.0, wp.y), Vector3(1.1, 1.4, 0.14), Color(0.09, 0.13, 0.15), rot)
	var tris := Geometry2D.triangulate_polygon(PackedVector2Array(anillo))
	for t in range(0, tris.size() - 2, 3):
		var p1: Vector2 = anillo[tris[t]]
		var p2: Vector2 = anillo[tris[t + 1]]
		var p3: Vector2 = anillo[tris[t + 2]]
		_tri_u(verts, normals, cols, uvs, Vector3(p1.x, yb + alto, p1.y), Vector3(p2.x, yb + alto, p2.y), Vector3(p3.x, yb + alto, p3.y), true, Color(0.16, 0.30, 0.27))
	print("TOYO_OK")

func _hito_norias(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# El complejo deportivo de Las Norias sobre las posiciones
	# reales de OSM: piscinas con toboganes, tenis, padel,
	# polideportivas, fronton, rocodromo, futbol y voley playa.
	var yp := _altura_terreno(-1155.0, -870.0)
	var borde := Color(0.88, 0.89, 0.90)
	_suelo(verts, normals, cols, -1155, -870, yp + 0.05, 116, 109, Color(0.82, 0.80, 0.74))
	_suelo(verts, normals, cols, -1167, -862, yp + 0.10, 27, 52, borde)
	_suelo(verts, normals, cols, -1167, -862, yp + 0.15, 25, 50, Color(0.13, 0.44, 0.74))
	for i in range(7):
		_suelo(verts, normals, cols, -1167 - 9.35 + float(i) * 3.12, -862, yp + 0.17, 0.28, 47, Color(0.85, 0.93, 1.0))
	_suelo(verts, normals, cols, -1152, -902, yp + 0.10, 58, 31, borde)
	_suelo(verts, normals, cols, -1152, -902, yp + 0.15, 55, 28, Color(0.15, 0.48, 0.78))
	var cols_tob := [Color(1.0, 0.72, 0.12), Color(0.88, 0.22, 0.18)]
	var k_t := 0
	for zt in [-894.0, -910.0]:
		for dx in [-0.8, 0.8]:
			for dz in [-0.8, 0.8]:
				_caja_en(verts, normals, cols, Vector3(-1182 + dx, yp + 2.8, zt + dz), Vector3(0.18, 5.6, 0.18), Color(0.35, 0.36, 0.40), 0.0)
		_caja_en(verts, normals, cols, Vector3(-1182, yp + 5.7, zt), Vector3(2.2, 0.25, 2.2), Color(0.35, 0.36, 0.40), 0.0)
		var via := [Vector3(-1181, yp + 5.5, zt), Vector3(-1177, yp + 3.4, zt), Vector3(-1173, yp + 1.4, zt), Vector3(-1169, yp + 0.45, zt)]
		for s in range(3):
			_viga(verts, normals, cols, via[s], via[s + 1], Vector2(0, 1), 1.15, 0.22, cols_tob[k_t])
			_viga(verts, normals, cols, via[s] + Vector3(0, 0.35, -0.55), via[s + 1] + Vector3(0, 0.35, -0.55), Vector2(0, 1), 0.08, 0.08, cols_tob[k_t])
			_viga(verts, normals, cols, via[s] + Vector3(0, 0.35, 0.55), via[s + 1] + Vector3(0, 0.35, 0.55), Vector2(0, 1), 0.08, 0.08, cols_tob[k_t])
		k_t += 1
	var yc := _altura_terreno(-1138.0, -716.0)
	_suelo(verts, normals, cols, -1138, -716, yc + 0.08, 17, 17, borde)
	for i in range(12):
		var a1 := TAU * float(i) / 12.0
		var a2 := TAU * float(i + 1) / 12.0
		_tri(verts, normals, cols, Vector3(-1138, yc + 0.13, -716), Vector3(-1138 + sin(a1) * 7.5, yc + 0.13, -716 + cos(a1) * 7.5), Vector3(-1138 + sin(a2) * 7.5, yc + 0.13, -716 + cos(a2) * 7.5), true, Color(0.30, 0.62, 0.90))
	var lin := Color(0.92, 0.92, 0.90)
	for i in range(4):
		var cx := -1110.0 + float(i) * 35.0
		var cz := -640.0
		var y := _altura_terreno(cx, cz)
		_suelo(verts, normals, cols, cx, cz, y + 0.07, 19, 34, Color(0.17, 0.40, 0.29))
		_suelo(verts, normals, cols, cx, cz, y + 0.09, 11.5, 24.5, Color(0.20, 0.38, 0.62))
		_suelo(verts, normals, cols, cx - 5.35, cz, y + 0.11, 0.25, 23.8, lin)
		_suelo(verts, normals, cols, cx + 5.35, cz, y + 0.11, 0.25, 23.8, lin)
		_suelo(verts, normals, cols, cx, cz - 11.9, y + 0.11, 11.0, 0.25, lin)
		_suelo(verts, normals, cols, cx, cz + 11.9, y + 0.11, 11.0, 0.25, lin)
		_suelo(verts, normals, cols, cx, cz - 6.4, y + 0.11, 8.2, 0.22, lin)
		_suelo(verts, normals, cols, cx, cz + 6.4, y + 0.11, 8.2, 0.22, lin)
		_caja_en(verts, normals, cols, Vector3(cx, y + 0.55, cz), Vector3(11.8, 1.05, 0.07), Color(0.10, 0.10, 0.12), 0.0)
		_caja_en(verts, normals, cols, Vector3(cx, y + 1.10, cz), Vector3(11.8, 0.09, 0.09), lin, 0.0)
		for lado in [-1.0, 1.0]:
			for s in range(5):
				_caja_en(verts, normals, cols, Vector3(cx + 9.5 * lado, y + 1.2, cz - 16.0 + float(s) * 8.0), Vector3(0.07, 2.4, 0.07), Color(0.10, 0.22, 0.16), 0.0)
			var p_a := Vector3(cx + 9.5 * lado, y + 2.35, cz - 16.0)
			var p_b := Vector3(cx + 9.5 * lado, y + 2.35, cz + 16.0)
			_viga(verts, normals, cols, p_a, p_b, Vector2(1, 0), 0.05, 0.05, Color(0.10, 0.22, 0.16))
	for cp in [Vector2(-1068, -568), Vector2(-1088, -568), Vector2(-1068, -590), Vector2(-1088, -590)]:
		var cx: float = cp.x
		var cz: float = cp.y
		var y := _altura_terreno(cx, cz)
		_suelo(verts, normals, cols, cx, cz, y + 0.07, 12, 22, Color(0.16, 0.38, 0.44))
		var cristal := Color(0.72, 0.82, 0.88)
		_caja_en(verts, normals, cols, Vector3(cx, y + 1.5, cz - 10.6), Vector3(12, 3.0, 0.18), cristal, 0.0)
		_caja_en(verts, normals, cols, Vector3(cx, y + 1.5, cz + 10.6), Vector3(12, 3.0, 0.18), cristal, 0.0)
		for lado in [-1.0, 1.0]:
			_caja_en(verts, normals, cols, Vector3(cx + 5.9 * lado, y + 1.5, cz - 6.9), Vector3(0.18, 3.0, 6.2), cristal, 0.0)
			_caja_en(verts, normals, cols, Vector3(cx + 5.9 * lado, y + 1.5, cz + 6.9), Vector3(0.18, 3.0, 6.2), cristal, 0.0)
		_caja_en(verts, normals, cols, Vector3(cx, y + 0.5, cz), Vector3(10, 0.95, 0.07), Color(0.10, 0.10, 0.12), 0.0)
		_caja_en(verts, normals, cols, Vector3(cx, y + 1.0, cz), Vector3(10, 0.08, 0.08), lin, 0.0)
	for poli in [[-1294.0, -935.0, 22.0, 42.0], [-1240.0, -880.0, 20.0, 38.0]]:
		var cx: float = poli[0]
		var cz: float = poli[1]
		var an: float = poli[2]
		var la: float = poli[3]
		var y := _altura_terreno(cx, cz)
		_suelo(verts, normals, cols, cx, cz, y + 0.07, an, la, Color(0.32, 0.44, 0.64))
		_suelo(verts, normals, cols, cx, cz, y + 0.10, an, 0.3, lin)
		_suelo(verts, normals, cols, cx - an * 0.5 + 0.6, cz, y + 0.10, 0.3, la - 1.2, lin)
		_suelo(verts, normals, cols, cx + an * 0.5 - 0.6, cz, y + 0.10, 0.3, la - 1.2, lin)
		_suelo(verts, normals, cols, cx, cz - la * 0.5 + 0.6, y + 0.10, an - 1.2, 0.3, lin)
		_suelo(verts, normals, cols, cx, cz + la * 0.5 - 0.6, y + 0.10, an - 1.2, 0.3, lin)
		for s in range(10):
			var aa := TAU * float(s) / 10.0
			_suelo(verts, normals, cols, cx + sin(aa) * 3.2, cz + cos(aa) * 3.2, y + 0.10, 0.28, 2.0, lin, aa)
		for lado in [-1.0, 1.0]:
			var hz: float = cz + (la * 0.5 - 1.2) * lado
			_caja_en(verts, normals, cols, Vector3(cx, y + 1.7, hz), Vector3(0.14, 3.4, 0.14), Color(0.30, 0.30, 0.33), 0.0)
			_caja_en(verts, normals, cols, Vector3(cx, y + 3.35, hz - 0.45 * lado), Vector3(1.7, 1.1, 0.08), lin, 0.0)
			_caja_en(verts, normals, cols, Vector3(cx, y + 3.0, hz - 0.85 * lado), Vector3(0.5, 0.05, 0.5), Color(0.90, 0.45, 0.10), 0.0)
	var yf := _altura_terreno(-1235.0, -790.0)
	_suelo(verts, normals, cols, -1235, -790, yf + 0.07, 13, 32, Color(0.62, 0.60, 0.55))
	_caja_en(verts, normals, cols, Vector3(-1235, yf + 4.5, -805.2), Vector3(12.5, 9.0, 0.8), Color(0.80, 0.74, 0.62), 0.0)
	_caja_en(verts, normals, cols, Vector3(-1235, yf + 3.4, -805.2), Vector3(12.5, 0.18, 0.85), Color(0.35, 0.30, 0.24), 0.0)
	_caja_en(verts, normals, cols, Vector3(-1235, yf + 8.6, -805.2), Vector3(12.5, 0.5, 0.85), Color(0.55, 0.48, 0.38), 0.0)
	_caja_en(verts, normals, cols, Vector3(-1241.2, yf + 2.5, -795), Vector3(0.7, 5.0, 20), Color(0.80, 0.74, 0.62), 0.0)
	var yr := _altura_terreno(-1200.0, -745.0)
	var paneles := [Color(0.85, 0.55, 0.20), Color(0.30, 0.55, 0.75), Color(0.75, 0.35, 0.45)]
	for k in range(3):
		_caja_en(verts, normals, cols, Vector3(-1200, yr + 1.4 + float(k) * 2.7, -745 - float(k) * 0.35), Vector3(11, 2.8, 0.7), paneles[k], 0.0)
	var presas := [Color(0.95, 0.30, 0.25), Color(0.20, 0.70, 0.35), Color(0.95, 0.80, 0.15), Color(0.30, 0.45, 0.95)]
	for i in range(26):
		var hx := -1200.0 + (fposmod(sin(float(i) * 12.9898) * 43758.5453, 1.0) - 0.5) * 10.0
		var hy := yr + 0.8 + fposmod(float(i) * 1.37, 7.2)
		var hz := -744.4 - (hy - yr) * 0.13
		_caja_en(verts, normals, cols, Vector3(hx, hy, hz), Vector3(0.18, 0.18, 0.12), presas[i % 4], 0.0)
	_suelo(verts, normals, cols, -1200, -741.5, yr + 0.06, 12, 4.5, Color(0.70, 0.28, 0.28))
	for fut in [[-1179.0, -1090.0, 105.0, 68.0], [-1086.0, -1171.0, 105.0, 68.0], [-1087.0, -552.0, 54.0, 38.0]]:
		var cx: float = fut[0]
		var cz: float = fut[1]
		var an: float = fut[2]
		var la: float = fut[3]
		var y := _altura_terreno(cx, cz)
		_suelo(verts, normals, cols, cx, cz, y + 0.06, an, la, Color(0.20, 0.48, 0.22))
		_suelo(verts, normals, cols, cx, cz, y + 0.09, 0.3, la, lin)
		_suelo(verts, normals, cols, cx - an * 0.5 + 0.5, cz, y + 0.09, 0.3, la - 1.0, lin)
		_suelo(verts, normals, cols, cx + an * 0.5 - 0.5, cz, y + 0.09, 0.3, la - 1.0, lin)
		_suelo(verts, normals, cols, cx, cz - la * 0.5 + 0.5, y + 0.09, an - 1.0, 0.3, lin)
		_suelo(verts, normals, cols, cx, cz + la * 0.5 - 0.5, y + 0.09, an - 1.0, 0.3, lin)
		var rr := 9.15 if an > 80.0 else 5.0
		for s in range(12):
			var aa := TAU * float(s) / 12.0
			_suelo(verts, normals, cols, cx + sin(aa) * rr, cz + cos(aa) * rr, y + 0.09, 0.28, rr * 0.55, lin, aa)
		for lado in [-1.0, 1.0]:
			var gx2: float = cx + (an * 0.5) * lado
			_caja_en(verts, normals, cols, Vector3(gx2, y + 1.22, cz - 3.66), Vector3(0.12, 2.44, 0.12), lin, 0.0)
			_caja_en(verts, normals, cols, Vector3(gx2, y + 1.22, cz + 3.66), Vector3(0.12, 2.44, 0.12), lin, 0.0)
			_caja_en(verts, normals, cols, Vector3(gx2, y + 2.44, cz), Vector3(0.12, 0.12, 7.44), lin, 0.0)
	var yv := _altura_terreno(-1350.0, -933.0)
	_suelo(verts, normals, cols, -1350, -933, yv + 0.07, 20, 12, Color(0.85, 0.76, 0.55))
	_caja_en(verts, normals, cols, Vector3(-1350, yv + 0.6, -933), Vector3(0.07, 1.1, 16), Color(0.92, 0.92, 0.90), 0.0)
	var ys := _altura_terreno(-899.0, -735.0)
	_suelo(verts, normals, cols, -899, -735, ys + 0.06, 38, 30, Color(0.58, 0.58, 0.60))
	_viga(verts, normals, cols, Vector3(-910, ys + 0.1, -742), Vector3(-910, ys + 1.9, -734), Vector2(1, 0), 5.0, 0.3, Color(0.50, 0.50, 0.53))
	_viga(verts, normals, cols, Vector3(-888, ys + 0.1, -728), Vector3(-888, ys + 1.9, -736), Vector2(1, 0), 5.0, 0.3, Color(0.50, 0.50, 0.53))
	# El skate park equipado (pedido de Jon: la losa estaba
	# vacia): funbox central con barandilla, barandilla plana
	# de grind al norte, un bank al este y un cajon al sur.
	var horm := Color(0.52, 0.52, 0.55)
	var metal := Color(0.75, 0.76, 0.78)
	_caja_en(verts, normals, cols, Vector3(-899, ys + 0.34, -735), Vector3(6.0, 0.55, 3.6), horm, 0.0)
	_caja_en(verts, normals, cols, Vector3(-901.6, ys + 0.85, -735), Vector3(0.09, 0.5, 0.09), metal, 0.0)
	_caja_en(verts, normals, cols, Vector3(-896.4, ys + 0.85, -735), Vector3(0.09, 0.5, 0.09), metal, 0.0)
	_viga(verts, normals, cols, Vector3(-902.0, ys + 1.12, -735), Vector3(-896.0, ys + 1.12, -735), Vector2(0, 1), 0.09, 0.09, metal)
	for px in [-907.6, -904.0, -900.4]:
		_caja_en(verts, normals, cols, Vector3(px, ys + 0.30, -726.5), Vector3(0.08, 0.48, 0.08), metal, 0.0)
	_viga(verts, normals, cols, Vector3(-908.0, ys + 0.56, -726.5), Vector3(-900.0, ys + 0.56, -726.5), Vector2(0, 1), 0.09, 0.09, metal)
	_viga(verts, normals, cols, Vector3(-883.0, ys + 0.12, -741), Vector3(-883.0, ys + 2.0, -733), Vector2(1, 0), 6.0, 0.3, horm)
	_caja_en(verts, normals, cols, Vector3(-899, ys + 0.28, -722.5), Vector3(8.0, 0.45, 0.6), horm, 0.0)
	print("NORIAS_OK")

var _tex_rayas_v: Texture2D = null

func _tex_rayas() -> Texture2D:
	# Las rayas verticales rojiblancas de la camiseta del Logrones.
	if _tex_rayas_v != null:
		return _tex_rayas_v
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for x in range(64):
		var c := Color(0.85, 0.10, 0.12) if (x / 8) % 2 == 0 else Color(0.95, 0.95, 0.95)
		for y in range(64):
			img.set_pixel(x, y, c)
	_tex_rayas_v = ImageTexture.create_from_image(img)
	return _tex_rayas_v

func _fan_logrones(per: Dictionary) -> void:
	var mc = per.get("mat_camisa")
	if mc != null:
		mc.albedo_texture = _tex_rayas()
		mc.albedo_color = Color(1, 1, 1)

func _gaunas_gente() -> void:
	# Aficionados del Logrones en las puertas del estadio.
	var pelos := [Color(0.16, 0.11, 0.07), Color(0.45, 0.30, 0.16), Color(0.10, 0.08, 0.06), Color(0.55, 0.50, 0.45), Color(0.20, 0.13, 0.08), Color(0.35, 0.22, 0.12)]
	var k := 0
	for par in [[Vector2(-956, 1537.2), Vector2(-956, 1538.8)], [Vector2(-861, 1642.2), Vector2(-863, 1642.2)]]:
		var perA := _persona_en(Vector3(par[0].x, 0, par[0].y), Vector2.ZERO, Color(0.95, 0.95, 0.95), pelos[k % 6])
		k += 1
		var perB := _persona_en(Vector3(par[1].x, 0, par[1].y), Vector2.ZERO, Color(0.95, 0.95, 0.95), pelos[k % 6])
		k += 1
		var ra: Node3D = perA["raiz"]
		var rb: Node3D = perB["raiz"]
		ra.rotation.y = atan2(rb.position.x - ra.position.x, rb.position.z - ra.position.z)
		rb.rotation.y = atan2(ra.position.x - rb.position.x, ra.position.z - rb.position.z)
		_fan_logrones(perA)
		_fan_logrones(perB)
		_estaticos.append({"d": perA, "raiz": ra, "tipo": "hablar", "fase": _rng.randf() * 6.0})
		_estaticos.append({"d": perB, "raiz": rb, "tipo": "hablar", "fase": _rng.randf() * 6.0})
	for solo in [Vector2(-864, 1433), Vector2(-771, 1538)]:
		var per := _persona_en(Vector3(solo.x, 0, solo.y), Vector2.ZERO, Color(0.95, 0.95, 0.95), pelos[k % 6])
		k += 1
		_fan_logrones(per)
		_estaticos.append({"d": per, "raiz": per["raiz"], "tipo": "movil", "fase": _rng.randf() * 6.0})

func _columna_ruina(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, base: Vector3, eje: Vector3, largo: float, radio: float, col: Color) -> void:
	# Un fuste octogonal entre dos puntos (de pie si el eje es
	# vertical, tumbado si es horizontal), con sus dos tapas.
	var e := eje.normalized()
	var ref := Vector3.RIGHT if absf(e.y) >= 0.9 else Vector3.UP
	var u := ref.cross(e).normalized()
	var v := e.cross(u).normalized()
	var cen_b := base + e * (largo * 0.5)
	var cen_t := base + e * largo
	for k in range(8):
		var a1 := TAU * float(k) / 8.0
		var a2 := TAU * float(k + 1) / 8.0
		var d1 := u * cos(a1) + v * sin(a1)
		var d2 := u * cos(a2) + v * sin(a2)
		var pa := base + d1 * radio
		var pb := base + d2 * radio
		var pc := cen_t + d2 * radio
		var pd := cen_t + d1 * radio
		_tri(verts, normals, cols, pa, pb, pc, false, col)
		_tri(verts, normals, cols, pa, pc, pd, false, col)
		_tri(verts, normals, cols, cen_t, pa + e * largo, pb + e * largo, false, col)
		_tri(verts, normals, cols, base, pb, pa, false, col)

func _hito_cantabria(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# Las ruinas romanas de la cima del Monte Cantabria
	# (pedido de Jon): el podio de un templo con sus columnas
	# rotas, dos en pie con su arquitrabe, muros de la cella,
	# fustes caidos y cascotes, todo de piedra caliza.
	var gy := _altura_terreno(gx, gz)
	var piedra := Color(0.64, 0.60, 0.52)
	var piedra2 := Color(0.58, 0.54, 0.47)
	var piedra3 := Color(0.52, 0.48, 0.42)
	_suelo(verts, normals, cols, gx, gz, gy + 0.07, 34, 26, Color(0.60, 0.56, 0.49))
	_caja_en(verts, normals, cols, Vector3(gx, gy + 0.50, gz), Vector3(15.0, 1.0, 11.0), piedra2, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, gy + 1.45, gz), Vector3(13.0, 0.9, 9.4), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx, gy + 2.32, gz), Vector3(11.4, 0.85, 8.0), piedra2, 0.0)
	var base_c := gy + 2.75
	var cols_c: Array = [
		[Vector2(-4.2, -2.4), 4.4], [Vector2(0.0, -2.4), 4.4], [Vector2(4.2, -2.4), 1.3],
		[Vector2(-4.2, 2.4), 3.1], [Vector2(0.0, 2.4), 0.7], [Vector2(4.2, 2.4), 2.0]]
	for cc in cols_c:
		var lp: Vector2 = cc[0]
		_columna_ruina(verts, normals, cols, Vector3(gx + lp.x, base_c, gz + lp.y), Vector3.UP, float(cc[1]), 0.42, piedra)
		_caja_en(verts, normals, cols, Vector3(gx + lp.x, base_c + 0.12, gz + lp.y), Vector3(1.05, 0.24, 1.05), piedra3, 0.0)
	for lp2 in [Vector2(-4.2, -2.4), Vector2(0.0, -2.4)]:
		_caja_en(verts, normals, cols, Vector3(gx + lp2.x, base_c + 4.58, gz + lp2.y), Vector3(1.15, 0.35, 1.15), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx - 2.1, base_c + 5.0, gz - 2.4), Vector3(5.8, 0.5, 1.0), piedra2, 0.0)
	# Muros rotos de la cella, al fondo del podio y a los lados
	_caja_en(verts, normals, cols, Vector3(gx - 4.5, gy + 0.87, gz - 5.2), Vector3(3.0, 1.6, 0.6), piedra3, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx - 0.5, gy + 0.52, gz - 5.2), Vector3(2.5, 0.9, 0.6), piedra2, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 3.2, gy + 1.02, gz - 5.2), Vector3(3.4, 1.9, 0.6), piedra3, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx - 6.5, gy + 0.67, gz - 3.5), Vector3(0.6, 1.2, 3.5), piedra2, 0.0)
	_caja_en(verts, normals, cols, Vector3(gx + 6.5, gy + 0.42, gz - 3.5), Vector3(0.6, 0.7, 3.5), piedra3, 0.0)
	# Fustes caidos y cascotes por la explanada
	_columna_ruina(verts, normals, cols, Vector3(gx - 7.5, gy + 0.48, gz + 4.5), Vector3(1, 0, 0.15), 2.6, 0.42, piedra)
	_columna_ruina(verts, normals, cols, Vector3(gx + 6.8, gy + 0.48, gz + 5.5), Vector3(-0.3, 0, 1), 1.9, 0.42, piedra2)
	_columna_ruina(verts, normals, cols, Vector3(gx + 8.5, gy + 0.07, gz - 3.0), Vector3.UP, 0.8, 0.42, piedra)
	_columna_ruina(verts, normals, cols, Vector3(gx - 8.0, gy + 0.07, gz - 4.0), Vector3.UP, 0.5, 0.46, piedra3)
	_caja_en(verts, normals, cols, Vector3(gx - 3.0, gy + 0.25, gz + 7.5), Vector3(1.15, 0.35, 1.15), piedra, 0.4)
	var cascotes: Array = [
		[Vector2(-9, 3), 0.8], [Vector2(-6, -6.5), 0.6], [Vector2(3, 6.5), 1.0], [Vector2(7, -5.5), 0.7],
		[Vector2(-2, 8), 0.5], [Vector2(10.5, 1), 0.9], [Vector2(-11, -2), 0.65], [Vector2(5, -8), 0.55],
		[Vector2(1.5, -7), 0.75]]
	var ki := 0
	for casc in cascotes:
		var cp: Vector2 = casc[0]
		var tam_c := float(casc[1])
		_caja_en(verts, normals, cols, Vector3(gx + cp.x, gy + 0.07 + tam_c * 0.3, gz + cp.y), Vector3(tam_c, tam_c * 0.62, tam_c * 0.8), piedra3 if ki % 2 == 0 else piedra2, float(ki) * 0.7)
		ki += 1
	_ruinas = true

func _skate_gente() -> void:
	# Los tres chavales del skate park de Las Norias: uno
	# subiendo y bajando la rampa, otro dando vueltas al
	# funbox con sus ollies y otro grindando la barandilla.
	# Cada uno con su tabla; la animacion vive en
	# _mover_peatones, en su propio bloque (no son estaticos:
	# alli la respiracion les pisaria la altura).
	var ys := _altura_terreno(-899.0, -735.0)
	var datos: Array = [
		[Color(0.85, 0.30, 0.20), Color(0.16, 0.11, 0.07), 0],
		[Color(0.20, 0.45, 0.85), Color(0.45, 0.30, 0.16), 1],
		[Color(0.95, 0.80, 0.20), Color(0.10, 0.08, 0.06), 2]]
	for d in datos:
		var per := _persona_en(Vector3(-899, 0, -735), Vector2.ZERO, d[0], d[1])
		var raiz: Node3D = per["raiz"]
		var tabla := Node3D.new()
		tabla.position = Vector3(0, -0.93, 0.02)
		tabla.add_child(_pieza(Vector3(0.24, 0.04, 0.84), Vector3.ZERO, Color(0.16, 0.16, 0.18)))
		# Ruedas redondas también en el monopatín (pedido de
		# Jon: nada de ruedas cuadradas en ningún vehículo).
		var mat_rs := StandardMaterial3D.new()
		mat_rs.albedo_color = Color(0.85, 0.85, 0.85)
		for wz in [0.26, -0.26]:
			for wx in [-0.085, 0.085]:
				var cil_s := CylinderMesh.new()
				cil_s.top_radius = 0.045
				cil_s.bottom_radius = 0.045
				cil_s.height = 0.035
				cil_s.radial_segments = 12
				cil_s.material = mat_rs
				var rueda_s := MeshInstance3D.new()
				rueda_s.mesh = cil_s
				rueda_s.rotation_degrees = Vector3(0, 0, 90)
				rueda_s.position = Vector3(wx, -0.055, wz)
				tabla.add_child(rueda_s)
		raiz.add_child(tabla)
		_skaters.append({"d": per, "raiz": raiz, "tabla": tabla, "modo": int(d[2]), "fase": _rng.randf() * 6.0, "ys": ys})

func _norias_gente() -> void:
	# La vida del complejo: tenistas, jugadores de padel y de
	# fronton, banistas en las piscinas y escaladores.
	var camisas := [Color(0.90, 0.90, 0.92), Color(0.85, 0.25, 0.20), Color(0.20, 0.35, 0.80), Color(0.95, 0.80, 0.20), Color(0.25, 0.65, 0.35), Color(0.90, 0.50, 0.15)]
	var pelos := [Color(0.16, 0.11, 0.07), Color(0.45, 0.30, 0.16), Color(0.10, 0.08, 0.06), Color(0.70, 0.60, 0.35), Color(0.20, 0.13, 0.08), Color(0.35, 0.22, 0.12)]
	var k := 0
	for cx in [-1075.0, -1005.0]:
		for lado in [-1.0, 1.0]:
			var per := _persona_en(Vector3(cx + 2.5 * lado, 0, -640 + 10.5 * lado), Vector2.ZERO, camisas[k % 6], pelos[k % 6])
			k += 1
			var raiz: Node3D = per["raiz"]
			raiz.rotation.y = 0.0 if lado < 0.0 else PI
			_estaticos.append({"d": per, "raiz": raiz, "tipo": "tenis", "fase": _rng.randf() * 6.0, "casa": raiz.position, "eje": Vector2(1, 0), "amp": 2.4, "mira": raiz.rotation.y})
	for cp in [Vector2(-1068, -568), Vector2(-1088, -590)]:
		for lado in [-1.0, 1.0]:
			var per := _persona_en(Vector3(cp.x + 2.0 * lado, 0, cp.y + 6.0 * lado), Vector2.ZERO, camisas[k % 6], pelos[k % 6])
			k += 1
			var raiz2: Node3D = per["raiz"]
			raiz2.rotation.y = 0.0 if lado < 0.0 else PI
			_estaticos.append({"d": per, "raiz": raiz2, "tipo": "tenis", "fase": _rng.randf() * 6.0, "casa": raiz2.position, "eje": Vector2(1, 0), "amp": 1.6, "mira": raiz2.rotation.y})
	for fp in [Vector2(-1237, -778), Vector2(-1232, -784)]:
		var per := _persona_en(Vector3(fp.x, 0, fp.y), Vector2.ZERO, camisas[k % 6], pelos[k % 6])
		k += 1
		var raiz3: Node3D = per["raiz"]
		raiz3.rotation.y = PI
		_estaticos.append({"d": per, "raiz": raiz3, "tipo": "tenis", "fase": _rng.randf() * 6.0, "casa": raiz3.position, "eje": Vector2(1, 0), "amp": 1.8, "mira": PI})
	var yp := _altura_terreno(-1155.0, -870.0)
	# En la piscina de calles, tres nadadores haciendo largos
	# sin parar (Jon, 2026-11-24: «no veo a nadie nadando y
	# haciendo largos»); un cuarto cruza la de recreo a ritmo
	# tranquilo, y en esa los demas flotan.
	for lg in [[-1171.7, -862.0, 0, 20.0, 1.15], [-1165.4, -862.0, 0, 20.0, 1.35], [-1159.2, -862.0, 0, 20.0, 1.25], [-1152.0, -904.0, 1, 22.0, 0.9]]:
		var per := _persona_en(Vector3(lg[0], 0, lg[1]), Vector2.ZERO, camisas[k % 6], pelos[k % 6])
		k += 1
		var raizl: Node3D = per["raiz"]
		raizl.position.y = yp + 0.44
		raizl.rotation.x = 1.0
		var eje_l := Vector2(1, 0) if int(lg[2]) == 1 else Vector2(0, 1)
		_estaticos.append({"d": per, "raiz": raizl, "tipo": "largos", "fase": _rng.randf() * 6.0, "casa": raizl.position, "eje": eje_l, "amp": lg[3], "vel": lg[4]})
	for sp in [[-1140.0, -900.0, 1.2], [-1160.0, -908.0, 5.5], [-1170.0, -896.0, 3.4], [-1135.0, -910.0, 2.2]]:
		var per := _persona_en(Vector3(sp[0], 0, sp[1]), Vector2.ZERO, camisas[k % 6], pelos[k % 6])
		k += 1
		var raiz4: Node3D = per["raiz"]
		raiz4.position.y = yp + 0.44
		raiz4.rotation.y = sp[2]
		raiz4.rotation.x = 0.5
		_estaticos.append({"d": per, "raiz": raiz4, "tipo": "nadar", "fase": _rng.randf() * 6.0})
	var yc2 := _altura_terreno(-1138.0, -716.0)
	for sp2 in [[-1136.0, -714.0], [-1141.0, -719.0]]:
		var per := _persona_en(Vector3(sp2[0], 0, sp2[1]), Vector2.ZERO, camisas[k % 6], pelos[k % 6])
		k += 1
		var raiz5: Node3D = per["raiz"]
		raiz5.position.y = yc2 + 0.40
		raiz5.rotation.x = 0.5
		_estaticos.append({"d": per, "raiz": raiz5, "tipo": "nadar", "fase": _rng.randf() * 6.0})
	var yr := _altura_terreno(-1200.0, -745.0)
	for ep in [[-1202.5, 3.0, 1.6], [-1197.5, 4.6, 2.2]]:
		var per := _persona_en(Vector3(ep[0], 0, -743.9), Vector2.ZERO, camisas[k % 6], pelos[k % 6])
		k += 1
		var raiz6: Node3D = per["raiz"]
		raiz6.position.y = yr + ep[1]
		raiz6.rotation.y = PI
		_estaticos.append({"d": per, "raiz": raiz6, "tipo": "escalar", "fase": _rng.randf() * 6.0, "sube": ep[2]})

func _construir_tile(t: Vector2i, inmediato := true) -> void:
	var clave := _clave_tile(t)
	if _tiles.has(clave):
		return
	var ruta := "res://datos/ciudad/tiles/t_%d_%d.json" % [t.x, t.y]
	if not FileAccess.file_exists(ruta):
		_tiles[clave] = {"nodo": null}
		return
	var datos = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	var cont := Node3D.new()
	cont.name = "Tile_" + clave
	if not inmediato:
		# En segundo plano: registrar ya el contenedor y construir por
		# etapas entre fotogramas, para no congelar el juego en marcha.
		add_child(cont)
		_tiles[clave] = {"nodo": cont}
	if datos != null:
		var ed := await _construir_edificios_tile(datos.get("e", []), cont, inmediato)
		if ed == null:
			return  # la baldosa se descargó a mitad de construir
		cont.add_child(ed)
		if not inmediato:
			await get_tree().process_frame
			if not is_instance_valid(cont):
				return
		var ca := await _construir_calles_tile(datos.get("c", []), cont, inmediato)
		if ca == null:
			return
		if not is_instance_valid(cont):
			return  # la baldosa se descargó mientras se hacían las calles
		cont.add_child(ca)
		if not inmediato:
			await get_tree().process_frame
			if not is_instance_valid(cont):
				return
		var ar := _malla_arboles(datos.get("a", []))
		if ar != null:
			cont.add_child(ar)
		_aparcados_tile(cont, datos.get("c", []), datos.get("d", []))
		_pois_tile(cont, datos.get("p", []))
		_rotulos_tile_actual = []
		_locales_tile(cont, datos.get("l", []))
		_rotulos_datos[clave] = _rotulos_tile_actual
		_hitos_tile(cont, t)
	if inmediato:
		add_child(cont)
		_tiles[clave] = {"nodo": cont}

func _actualizar_tiles() -> void:
	if _jugador == null:
		return
	var ancla := _jugador.position
	if _en_bus and _bus != null:
		ancla = _bus.position
	elif _en_coche:
		ancla = _coche.position
	var centro := _tile_de(Vector2(ancla.x, ancla.z))
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var t := Vector2i(centro.x + dx, centro.y + dy)
			if not _tiles.has(_clave_tile(t)) and not _cola_tiles.has(t):
				_cola_tiles.append(t)
	for clave in _tiles.keys():
		var partes: PackedStringArray = String(clave).split(",")
		var t := Vector2i(int(partes[0]), int(partes[1]))
		if maxi(absi(t.x - centro.x), absi(t.y - centro.y)) > 2:
			var ent: Dictionary = _tiles[clave]
			var nodo: Node3D = ent.get("nodo")
			if nodo != null:
				nodo.queue_free()
			_tiles.erase(clave)
			_rotulos_datos.erase(clave)

func _procesar_tiles(delta: float) -> void:
	if _en_interior != "":
		return
	_tile_timer += delta
	if _tile_timer < 0.35:
		return
	_tile_timer = 0.0
	_actualizar_tiles()
	if not _cola_tiles.is_empty():
		_construir_tile(_cola_tiles.pop_front(), false)

func _malla_arboles(lista: Array) -> MeshInstance3D:
	if lista.is_empty():
		return null
	var tv := PackedVector3Array()
	var tn := PackedVector3Array()
	var tc := PackedColorArray()
	var col_tronco := Color(0.35, 0.25, 0.18)
	for a in lista:
		var ax := float(a[0])
		var az := float(a[1])
		var y0 := _altura(ax, az)
		var h: float = fposmod(sin(ax * 3.1 + az * 7.7) * 43758.5453, 1.0)
		var s := 0.85 + 0.5 * h
		var col_copa := Color(0.25, 0.45, 0.22).lerp(Color(0.38, 0.56, 0.26), h)
		for k in 4:
			var a1 := Vector2(ax, az) + Vector2(cos(k * PI / 2.0), sin(k * PI / 2.0)) * 0.16
			var a2 := Vector2(ax, az) + Vector2(cos((k + 1) * PI / 2.0), sin((k + 1) * PI / 2.0)) * 0.16
			_tri(tv, tn, tc, Vector3(a1.x, y0, a1.y), Vector3(a2.x, y0, a2.y), Vector3(a2.x, y0 + 2.0 * s, a2.y), false, col_tronco)
			_tri(tv, tn, tc, Vector3(a1.x, y0, a1.y), Vector3(a2.x, y0 + 2.0 * s, a2.y), Vector3(a1.x, y0 + 2.0 * s, a1.y), false, col_tronco)
		_bola_en(tv, tn, tc, Vector3(ax, y0 + 3.1 * s, az), 1.85 * s, col_copa, ax * 1.3 + az * 2.9)
		_bola_en(tv, tn, tc, Vector3(ax + 0.8 * s, y0 + 2.5 * s, az + 0.4 * s), 1.15 * s, col_copa.darkened(0.08), ax * 3.7 + az * 1.1)
	return _malla_de(tv, tn, tc, Color.WHITE)

func _bola_en(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray,
		centro: Vector3, radio: float, color: Color, semilla: float, aplast := 1.0) -> void:
	# Esfera baja en polígonos con el radio alterado por un ruido fijo:
	# la copa deja de ser una caja y pasa a parecer un árbol.
	var anillos := 3
	var lados := 7
	var pts := {}
	for j in range(anillos + 1):
		var phi := PI * float(j) / float(anillos)
		for i in lados:
			var theta := TAU * float(i) / float(lados)
			var r := radio * (1.0 + 0.18 * (fposmod(sin(semilla + float(j * 7 + i) * 12.9898) * 43758.5453, 1.0) - 0.5))
			pts[str(j) + "," + str(i)] = Vector3(centro.x + cos(theta) * sin(phi) * r, centro.y + cos(phi) * radio * aplast, centro.z + sin(theta) * sin(phi) * r)
	for j in anillos:
		for i in lados:
			var i2 := (i + 1) % lados
			var a: Vector3 = pts[str(j) + "," + str(i)]
			var b: Vector3 = pts[str(j) + "," + str(i2)]
			var c: Vector3 = pts[str(j + 1) + "," + str(i)]
			var d: Vector3 = pts[str(j + 1) + "," + str(i2)]
			var tono := color.lerp(Color(1, 1, 1), 0.10 * fposmod(sin(semilla + float(j * 13 + i) * 7.3) * 24634.6, 1.0))
			_tri(verts, normals, cols, a, c, b, false, tono)
			_tri(verts, normals, cols, b, c, d, false, tono)

func _coche_en(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray,
		origen: Vector3, ang: float, color: Color, hh := 0.0) -> void:
	# Un coche aparcado dibujado como cajas dentro de la malla fundida de
	# la baldosa, con la silueta de una clase del catálogo según hh.
	var cr := cos(ang)
	var sr := sin(ang)
	var cuerpo := Vector3(1.8, 0.55, 4.2)
	var cabina := Vector3(1.6, 0.5, 2.0)
	var cab_z := -0.2
	var vidrio := Color(0.10, 0.12, 0.16)
	var hh2 := fposmod(hh * 7.31, 1.0)
	if hh2 < 0.16:
		# Furgoneta: caja alta y luna pequeña
		cuerpo = Vector3(1.95, 0.60, 4.8)
		cabina = Vector3(1.91, 1.02, 3.1)
		cab_z = -0.65
		vidrio = color
	elif hh2 < 0.38:
		# Familiar: cabina larga
		cabina = Vector3(1.65, 0.5, 2.7)
		cab_z = -0.1
	elif hh2 < 0.52:
		# Deportivo: bajo y cabina corta
		cuerpo = Vector3(1.9, 0.45, 4.3)
		cabina = Vector3(1.6, 0.36, 1.8)
	elif hh2 < 0.66:
		# Clásico: cabina retrasada
		cabina = Vector3(1.5, 0.55, 1.7)
		cab_z = -0.5
	var partes := [
		[Vector3(0, 0.28 + cuerpo.y / 2.0, 0), cuerpo, color],
		[Vector3(0, 0.28 + cuerpo.y + cabina.y / 2.0 - 0.03, cab_z), cabina, vidrio],
	]
	for parte in partes:
		var off: Vector3 = parte[0]
		var centro := origen + Vector3(off.x * cr + off.z * sr, off.y, -off.x * sr + off.z * cr)
		_caja_en(verts, normals, cols, centro, parte[1], parte[2], ang)
	# Ruedas REDONDAS (pedido de Jon: «todas las ruedas de
	# todos los vehículos sean circulares, nunca cuadradas»):
	# cilindros octogonales con su buje claro, como los del
	# autobús, en vez de las cajas que llevaban los coches
	# aparcados y los del tráfico (ambos salen de aquí).
	var eje_r := Vector3(cr, 0, -sr)
	for ox in [-(cuerpo.x / 2.0 - 0.05), cuerpo.x / 2.0 - 0.05]:
		for oz in [-(cuerpo.z / 2.0 - 0.65), cuerpo.z / 2.0 - 0.65]:
			var cw := origen + Vector3(ox * cr + oz * sr, 0.35, -ox * sr + oz * cr)
			_columna_ruina(verts, normals, cols, cw - eje_r * 0.13, eje_r, 0.26, 0.35, Color(0.05, 0.05, 0.05))
			_columna_ruina(verts, normals, cols, cw - eje_r * 0.145, eje_r, 0.29, 0.19, Color(0.55, 0.56, 0.58))

func _aparcados_tile(cont: Node3D, calles: Array, puertas: Array = []) -> void:
	# Coches aparcados FUNDIDOS en una sola malla por baldosa. Antes cada
	# coche era un nodo con 6 mallas y materiales propios: con varias
	# baldosas cargadas, la versión web dejaba de dibujar la escena entera
	# (en escritorio no pasaba). Fundidos, 42 coches son una sola malla.
	var paleta_coches := [Color(0.92, 0.92, 0.94), Color(0.12, 0.12, 0.14), Color(0.62, 0.64, 0.68), Color(0.70, 0.16, 0.14), Color(0.16, 0.28, 0.55), Color(0.25, 0.25, 0.28), Color(0.55, 0.58, 0.62), Color(0.10, 0.30, 0.28)]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var aparcados := 0
	for calle in calles:
		if aparcados >= 42:
			break
		if not ["primary", "secondary", "tertiary", "residential", "unclassified"].has(String(calle["c"])):
			continue
		var ancho := float(calle["a"])
		if ancho < 5.0:
			continue
		var pts: Array = calle["p"]
		for i in range(pts.size() - 1):
			if aparcados >= 42:
				break
			var p1 := Vector2(float(pts[i][0]), float(pts[i][1]))
			var p2 := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			var pasos := int(p1.distance_to(p2) / 19.0)
			for k in pasos:
				var hh: float = fposmod(sin(p1.x * 1.7 + p1.y * 2.3 + float(k) * 13.7) * 43758.5453, 1.0)
				if hh < 0.30:
					continue
				var base := p1.lerp(p2, (float(k) + 0.5) / float(pasos))
				var dirv := (p2 - p1).normalized()
				var perp := Vector2(-dirv.y, dirv.x)
				var lado := 1.0 if hh > 0.65 else -1.0
				var pos := base + perp * lado * (ancho * 0.5 - 1.15)
				if _choca(pos, 1.05):
					continue
				# Fase 7: ningún coche aparcado tapa un portal (puerta del Catastro a menos de 3,2 m)
				var tapa_puerta := false
				for pu in puertas:
					if pos.distance_squared_to(Vector2(float(pu[0]), float(pu[1]))) < 10.24:
						tapa_puerta = true
						break
				if tapa_puerta:
					continue
				var origen := Vector3(pos.x, _altura(pos.x, pos.y), pos.y)
				_coche_en(verts, normals, cols, origen, atan2(dirv.x, dirv.y), paleta_coches[int(hh * 8.0) % 8], hh)
				_registrar_solido(pos.x, pos.y, atan2(dirv.x, dirv.y), 2.05, 0.92)
				aparcados += 1
	if aparcados > 0:
		cont.add_child(_malla_de(verts, normals, cols, Color.WHITE))

const HITOS: Array = [
	{"n": "gaunas", "x": -944, "z": 1538},
	{"n": "norias", "x": -1155, "z": -872},
	{"n": "palacio", "x": -1046, "z": 1551},
	{"n": "carrefour", "x": 1882, "z": 416},
	{"n": "berceo", "x": 1855, "z": 530},
	{"n": "eci_b", "x": 1729, "z": 477},
	{"n": "mediamarkt", "x": 1773, "z": 541},
	{"n": "forum", "x": 1800, "z": 391},
	{"n": "bk_b", "x": 1710, "z": 525},
	{"n": "alcampo", "x": -2110, "z": 1681},
	{"n": "mall", "x": -2135, "z": 1696},
	{"n": "leroy", "x": -2469, "z": 1668},
	{"n": "decathlon", "x": -2458, "z": 1564},
	{"n": "aldi", "x": -2446, "z": 1595},
	{"n": "lupa", "x": -2461, "z": 1632},
	{"n": "totem_pr", "x": -2285, "z": 1697},
	{"n": "bk", "x": -2239, "z": 1693},
	{"n": "rioja", "x": 970, "z": -603},
	{"n": "labrador", "x": -139.4, "z": 487.2},
	{"n": "oca", "x": -362.0, "z": -82.0},
	{"n": "fuente", "x": -370.0, "z": -70.0},
	{"n": "revellin", "x": -604.0, "z": -9.0},
	{"n": "chapiteles", "x": -78.0, "z": 51.0},
	{"n": "espartero", "x": -247.0, "z": 261.0},
	{"n": "zubia", "x": -4.0, "z": 146.0},
	{"n": "cantabria", "x": 1350, "z": -1345},
	{"n": "ayto", "x": 270.0, "z": 55.0},
	{"n": "breton", "x": -472.0, "z": 218.0},
	{"n": "sanblas", "x": -363.0, "z": 144.0},
	{"n": "museo", "x": -541.0, "z": 137.0},
	{"n": "casa", "x": -234.0, "z": -446.0},
	{"n": "franco", "x": -390.0, "z": -582.0},
	{"n": "enamorados", "x": -2311.3, "z": 100.0},
	{"n": "puerta", "x": 305.0, "z": -274.0},
	{"n": "danza", "x": -120.0, "z": -430.0},
	{"n": "riojanos", "x": -824.0, "z": 253.0},
	{"n": "mercado", "x": -234.0, "z": 13.0},
	{"n": "barto", "x": -56.0, "z": 6.0},
	{"n": "calado", "x": -216.0, "z": -140.0},
	{"n": "lagares", "x": -231.0, "z": -104.0},
	{"n": "tabacalera", "x": -591.0, "z": 66.0},
	{"n": "parlamento", "x": -559.0, "z": 20.0},
	{"n": "trevijano", "x": -676.0, "z": 252.0},
]

func _hito_rioja(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# El frente del Riojaforum sobre el parque: explanada de piedra
	# clara, tres mástiles y la marquesina de la entrada. El nombre
	# va en el sistema de rótulos (pegado a la fachada norte).
	var y := _altura(gx, gz)
	_caja_en(verts, normals, cols, Vector3(gx, y + 0.07, gz), Vector3(176.0, 0.14, 17.0), Color(0.80, 0.77, 0.70), 0.0)
	for mx in [-22.0, 0.0, 22.0]:
		_caja_en(verts, normals, cols, Vector3(gx + mx, y + 4.4, gz - 2.0), Vector3(0.14, 8.8, 0.14), Color(0.35, 0.35, 0.38), 0.0)
		_caja_en(verts, normals, cols, Vector3(gx + mx + 0.75, y + 8.2, gz - 2.0), Vector3(1.5, 0.8, 0.04), Color(0.75, 0.68, 0.30), 0.0)
	var ye := _altura(950.0, -590.0)
	_caja_en(verts, normals, cols, Vector3(950.0, ye + 4.35, -589.5), Vector3(17.0, 0.28, 4.4), Color(0.30, 0.30, 0.33), 0.0)
	_caja_en(verts, normals, cols, Vector3(950.0, ye + 1.75, -588.6), Vector3(11.0, 3.5, 0.25), Color(0.14, 0.16, 0.20), 0.0)
	_rotulos_tile_actual.append({"n": "Riojaforum", "h": Vector2(0, -1), "w": 9.0, "p": Vector3(950.0, ye + 7.6, -590.5)})

func _marca(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float, mira: Vector2, nombre: String, g: float, ancho: float, y_rot: float) -> void:
	# El frente de marca de una nave: puerta oscura, marquesina y
	# el nombre en letras grandes sobre la banda (rótulo «g»).
	var y := _altura(gx, gz)
	var rot := atan2(mira.x, mira.y)
	_caja_en(verts, normals, cols, Vector3(gx + mira.x * 0.25, y + 1.55, gz + mira.y * 0.25), Vector3(5.6, 3.1, 0.35), Color(0.13, 0.15, 0.19), rot)
	_caja_en(verts, normals, cols, Vector3(gx + mira.x * 1.7, y + 3.55, gz + mira.y * 1.7), Vector3(ancho * 0.62, 0.25, 3.4), Color(0.30, 0.30, 0.33), rot)
	_rotulos_tile_actual.append({"n": nombre, "h": mira, "w": ancho, "g": g, "p": Vector3(gx + mira.x * 0.5, y + y_rot, gz + mira.y * 0.5)})

func _coche_aparcado(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, px: float, pz: float, rot: float, semilla: int) -> void:
	# Un coche aparcado fundido en dos cajas (carrocería y techo),
	# como los del tráfico pero quieto y sin nodos propios.
	var paleta := [Color(0.55, 0.55, 0.58), Color(0.35, 0.35, 0.38), Color(0.60, 0.15, 0.15), Color(0.15, 0.25, 0.50), Color(0.75, 0.73, 0.70), Color(0.20, 0.35, 0.25)]
	var col: Color = paleta[semilla % paleta.size()]
	var y := _altura(px, pz)
	var f := Vector2(sin(rot), cos(rot))
	_caja_en(verts, normals, cols, Vector3(px, y + 0.55, pz), Vector3(1.8, 0.55, 4.2), col, rot)
	_caja_en(verts, normals, cols, Vector3(px - f.x * 0.2, y + 1.05, pz - f.y * 0.2), Vector3(1.65, 0.5, 2.2), col.darkened(0.35), rot)

func _hito_totem_pr(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# El tótem de la entrada de Parque Rioja, con los paneles de
	# colores de sus marcas, como el de verdad junto a Prado Viejo.
	var y := _altura(gx, gz)
	_caja_en(verts, normals, cols, Vector3(gx, y + 3.75, gz), Vector3(0.35, 7.5, 0.35), Color(0.30, 0.30, 0.33), 0.0)
	var bandas := [Color(0.80, 0.10, 0.12), Color(0.25, 0.35, 0.55), Color(0.15, 0.55, 0.25), Color(0.05, 0.25, 0.70), Color(0.85, 0.50, 0.10)]
	for i in bandas.size():
		_caja_en(verts, normals, cols, Vector3(gx - 0.16, y + 3.1 + float(i) * 0.95, gz), Vector3(0.16, 0.85, 1.9), bandas[i], 0.0)
	_rotulos_tile_actual.append({"n": "Parque Rioja", "h": Vector2(-1, 0), "w": 12.0, "g": 3.0, "p": Vector3(gx - 0.5, y + 8.1, gz)})

func _hito_bk(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, gx: float, gz: float) -> void:
	# El poste-cartel del Burger King, visible desde la calle.
	var y := _altura(gx, gz)
	_caja_en(verts, normals, cols, Vector3(gx, y + 3.0, gz), Vector3(0.22, 6.0, 0.22), Color(0.30, 0.30, 0.33), 0.0)
	_caja_en(verts, normals, cols, Vector3(gx - 0.2, y + 5.6, gz), Vector3(0.25, 1.6, 3.0), Color(0.85, 0.50, 0.10), 0.0)
	_rotulos_tile_actual.append({"n": "Burger King", "h": Vector2(-1, 0), "w": 8.0, "g": 3.0, "p": Vector3(gx - 0.45, y + 5.6, gz)})

func _hitos_tile(cont: Node3D, t: Vector2i) -> void:
	# Monumentos y piezas únicas con nombre propio, construidos a
	# medida en su sitio exacto (la estatua del Labrador en su
	# glorieta, para empezar). Todo fundido en una malla por baldosa.
	var x0 := -2700.0 + float(t.x) * 650.0
	var z0 := -2000.0 + float(t.y) * 650.0
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var hecho := false
	for h in HITOS:
		var hx := float(h["x"])
		var hz := float(h["z"])
		if hx < x0 or hx >= x0 + 650.0 or hz < z0 or hz >= z0 + 650.0:
			continue
		match String(h["n"]):
			"labrador":
				_hito_labrador(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK labrador")
			"oca":
				_hito_oca(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK oca")
			"fuente":
				_hito_fuente(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK fuente")
			"revellin":
				_hito_revellin(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK revellin")
			"chapiteles":
				_hito_chapiteles(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK chapiteles")
			"espartero":
				_hito_espartero(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK espartero")
			"zubia":
				_hito_zubia(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK zubia")
			"ayto":
				_hito_ayto(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK ayto")
			"breton":
				_hito_breton(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK breton")
			"sanblas":
				_hito_sanblas(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK sanblas")
			"museo":
				_hito_museo(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK museo")
			"casa":
				_hito_casa(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK casa")
			"franco":
				_hito_franco(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK franco")
			"enamorados":
				_hito_enamorados(verts, normals, cols, hx, hz)
				_enamorados_gente()
				hecho = true
				print("HITO_OK enamorados")
			"gaunas":
				_marca(verts, normals, cols, hx, hz, Vector2(-1, 0), "Estadio Las Gaunas", 6.0, 26.0, 12.8)
				_marca(verts, normals, cols, -864, 1634, Vector2(0, 1), "Estadio Las Gaunas", 6.0, 26.0, 12.8)
				_marca(verts, normals, cols, -864, 1442, Vector2(0, -1), "Estadio Las Gaunas", 6.0, 26.0, 12.8)
				_marca(verts, normals, cols, -781, 1538, Vector2(1, 0), "Estadio Las Gaunas", 6.0, 26.0, 12.8)
				_gaunas_gente()
				for i in 12:
					_coche_aparcado(verts, normals, cols, -985.0, 1470.0 + float(i) * 7.4, PI * 0.5, i)
					_coche_aparcado(verts, normals, cols, -976.0, 1470.0 + float(i) * 7.4, -PI * 0.5, i + 2)
				hecho = true
				print("HITO_OK gaunas")
			"norias":
				_hito_norias(verts, normals, cols, hx, hz)
				_norias_gente()
				_skate_gente()
				hecho = true
				print("HITO_OK norias")
			"cantabria":
				_hito_cantabria(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK cantabria")
			"palacio":
				_marca(verts, normals, cols, hx, hz, Vector2(1, 0), "Palacio de los Deportes", 4.0, 22.0, 3.7)
				hecho = true
				print("HITO_OK palacio")
			"carrefour":
				_marca(verts, normals, cols, hx, hz, Vector2(0, 1), "Carrefour", 6.0, 24.0, 8.0)
				hecho = true
				print("HITO_OK carrefour")
			"berceo":
				_marca(verts, normals, cols, hx, hz, Vector2(0, 1), "Centro Comercial Berceo", 5.0, 30.0, 8.0)
				for i in 7:
					_coche_aparcado(verts, normals, cols, 1975.0, 405.0 + float(i) * 7.4, -PI * 0.5, i + 1)
				hecho = true
				print("HITO_OK berceo")
			"eci_b":
				_marca(verts, normals, cols, hx, hz, Vector2(-1, 0), "El Corte Inglés", 4.0, 18.0, 7.6)
				hecho = true
				print("HITO_OK eci_b")
			"mediamarkt":
				_marca(verts, normals, cols, hx, hz, Vector2(1, 0), "MediaMarkt", 4.0, 16.0, 3.7)
				hecho = true
				print("HITO_OK mediamarkt")
			"forum":
				_marca(verts, normals, cols, hx, hz, Vector2(0, -1), "Forum Sport", 4.0, 16.0, 7.6)
				hecho = true
				print("HITO_OK forum")
			"bk_b":
				_hito_bk(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK bk_b")
			"alcampo":
				_marca(verts, normals, cols, hx, hz, Vector2(0, -1), "Alcampo", 6.0, 24.0, 8.0)
				hecho = true
				print("HITO_OK alcampo")
			"mall":
				_marca(verts, normals, cols, hx, hz, Vector2(0, 1), "Parque Rioja", 6.0, 26.0, 8.0)
				_rotulos_tile_actual.append({"n": "El Corte Inglés Outlet", "h": Vector2(0, 1), "w": 20.0, "g": 4.0, "p": Vector3(-2085.0, _altura(-2085.0, 1696.0) + 8.0, 1696.5)})
				hecho = true
				print("HITO_OK mall")
			"leroy":
				_marca(verts, normals, cols, hx, hz, Vector2(0, -1), "Leroy Merlin", 6.0, 22.0, 8.0)
				for i in 9:
					_coche_aparcado(verts, normals, cols, -2522.0, 1690.0 + float(i) * 7.4, PI * 0.5, i)
				hecho = true
				print("HITO_OK leroy")
			"decathlon":
				_marca(verts, normals, cols, hx, hz, Vector2(1, 0), "Decathlon", 6.0, 20.0, 8.0)
				for i in 7:
					_coche_aparcado(verts, normals, cols, -2450.0, 1544.0 + float(i) * 7.4, -PI * 0.5, i)
					_coche_aparcado(verts, normals, cols, -2441.0, 1544.0 + float(i) * 7.4, PI * 0.5, i + 3)
				hecho = true
				print("HITO_OK decathlon")
			"aldi":
				_marca(verts, normals, cols, hx, hz, Vector2(0, -1), "ALDI", 3.5, 11.0, 3.7)
				hecho = true
				print("HITO_OK aldi")
			"lupa":
				_marca(verts, normals, cols, hx, hz, Vector2(0, -1), "Lupa", 3.5, 13.0, 3.7)
				hecho = true
				print("HITO_OK lupa")
			"totem_pr":
				_hito_totem_pr(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK totem_pr")
			"bk":
				_hito_bk(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK bk")
			"rioja":
				_hito_rioja(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK rioja")
			"puerta":
				_hito_puerta(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK puerta")
			"danza":
				_hito_danza(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK danza")
			"riojanos":
				_hito_riojanos(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK riojanos")
			"mercado":
				_hito_mercado(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK mercado")
			"barto":
				_hito_barto(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK barto")
			"calado":
				_hito_calado(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK calado")
			"lagares":
				_hito_lagares(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK lagares")
			"tabacalera":
				_hito_tabacalera(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK tabacalera")
			"parlamento":
				_hito_parlamento(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK parlamento")
			"trevijano":
				_hito_trevijano(verts, normals, cols, hx, hz)
				hecho = true
				print("HITO_OK trevijano")
	if hecho:
		cont.add_child(_malla_de(verts, normals, cols, Color.WHITE))

func _hito_labrador(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, px: float, pz: float) -> void:
	# El Monumento al Labrador, en su glorieta: peana de piedra
	# octogonal, pedestal y la figura de bronce de un labrador con
	# su azada, mirando al sur, hacia la avenida Solidaridad.
	var y := _altura(px, pz)
	var piedra := Color(0.55, 0.53, 0.50)
	var piedra_o := Color(0.42, 0.40, 0.38)
	var bronce := Color(0.36, 0.29, 0.17)
	var bronce_o := Color(0.27, 0.21, 0.12)
	var f := Vector2(0.0, 1.0)  # frente: al sur
	var r := Vector2(1.0, 0.0)  # lateral
	var rot := atan2(r.x, r.y)
	_caja_en(verts, normals, cols, Vector3(px, y + 0.18, pz), Vector3(3.6, 0.36, 3.6), piedra, 0.0)
	_caja_en(verts, normals, cols, Vector3(px, y + 0.18, pz), Vector3(3.6, 0.36, 3.6), piedra, PI / 4.0)
	_caja_en(verts, normals, cols, Vector3(px, y + 1.10, pz), Vector3(1.35, 1.50, 1.35), piedra_o, rot)
	_caja_en(verts, normals, cols, Vector3(px, y + 1.94, pz), Vector3(1.65, 0.20, 1.65), piedra, rot)
	var yf := y + 2.04  # los pies de la figura
	var c := Vector2(px, pz)
	var pp: Vector2
	pp = c + r * -0.13
	_caja_en(verts, normals, cols, Vector3(pp.x, yf + 0.44, pp.y), Vector3(0.19, 0.88, 0.17), bronce_o, rot)
	pp = c + r * 0.15
	_caja_en(verts, normals, cols, Vector3(pp.x, yf + 0.44, pp.y), Vector3(0.19, 0.88, 0.17), bronce_o, rot)
	_caja_en(verts, normals, cols, Vector3(px, yf + 1.24, pz), Vector3(0.30, 0.78, 0.56), bronce, rot)
	_caja_en(verts, normals, cols, Vector3(px, yf + 0.92, pz), Vector3(0.32, 0.10, 0.58), bronce_o, rot)
	pp = c + r * -0.36
	_caja_en(verts, normals, cols, Vector3(pp.x, yf + 1.22, pp.y), Vector3(0.13, 0.66, 0.12), bronce, rot)
	pp = c + r * 0.36 + f * 0.10
	_caja_en(verts, normals, cols, Vector3(pp.x, yf + 1.20, pp.y), Vector3(0.13, 0.62, 0.12), bronce, rot)
	_caja_en(verts, normals, cols, Vector3(px, yf + 1.80, pz), Vector3(0.25, 0.30, 0.25), bronce, rot)
	_caja_en(verts, normals, cols, Vector3(px, yf + 1.97, pz), Vector3(0.48, 0.07, 0.48), bronce_o, rot)
	_caja_en(verts, normals, cols, Vector3(px, yf + 2.06, pz), Vector3(0.27, 0.13, 0.27), bronce_o, rot)
	# La azada, plantada delante, con su mango largo y la hoja
	pp = c + f * 0.42 + r * 0.36
	_caja_en(verts, normals, cols, Vector3(pp.x, yf + 0.95, pp.y), Vector3(0.055, 1.95, 0.055), Color(0.30, 0.22, 0.13), 0.0)
	_caja_en(verts, normals, cols, Vector3(pp.x, yf + 0.06, pp.y), Vector3(0.30, 0.10, 0.06), bronce_o, rot)

func _es_pinchos(p: Vector2) -> bool:
	# La zona de pinchos: a menos de 17 m del eje de Laurel, su
	# Travesía, San Agustín, San Juan o Albornoz.
	var ejes := [[Vector2(-524, 173), Vector2(-401, 173)], [Vector2(-526, 127), Vector2(-526, 212)], [Vector2(-605, 120), Vector2(-400, 120)], [Vector2(-238, 134), Vector2(-88, 134)], [Vector2(-470, 115), Vector2(-470, 167)]]
	for e in ejes:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if p.distance_to(a + ab * t) < 17.0:
			return true
	return false

func _es_eje(p: Vector2) -> bool:
	# Los grandes ejes comerciales (Bloque 2): a menos de 16 m del
	# eje de Gran Via, Portugal, Republica Argentina, Perez Galdos,
	# Chile, Juan XXIII, Calvo Sotelo, Club Deportivo, La Paz, Vara
	# de Rey, Murrieta o San Anton.
	if _ejes_polys.is_empty():
		var nombres := ["GRAN VÍA JUAN CARLOS I", "AVENIDA PORTUGAL", "AVENIDA REPÚBLICA ARGENTINA", "CALLE CHILE", "AVENIDA JUAN XXIII", "CALLE JUAN XXIII", "CALLE PRESIDENTE LEOPOLDO CALVO SOTELO", "AVENIDA CLUB DEPORTIVO", "AVENIDA DE LA PAZ", "CALLE GENERAL VARA DE REY", "CALLE MARQUÉS DE MURRIETA", "CALLE SAN ANTÓN", "CALLE PÉREZ GALDÓS"]
		for c in _calles_nombradas:
			if nombres.has(String(c["n"]).to_upper()):
				_ejes_polys.append(c["p"])
	for poly in _ejes_polys:
		for i in range(poly.size() - 1):
			var a := Vector2(float(poly[i][0]), float(poly[i][1]))
			var b := Vector2(float(poly[i + 1][0]), float(poly[i + 1][1]))
			var ab := b - a
			var t := clampf((p - a).dot(ab) / maxf(0.01, ab.length_squared()), 0.0, 1.0)
			if p.distance_to(a + ab * t) < 16.0:
				return true
	return false

func _locales_tile(cont: Node3D, locales: Array) -> void:
	# Planta baja con vida: escaparate de cristal, cartel con el nombre
	# del local (los bancos, con su color), toldo y terraza con mesas.
	# Todo el cristal y el mobiliario van fundidos en UNA malla por
	# baldosa; solo el nombre es un rótulo aparte por local.
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var n := 0
	var con_terraza := 0
	for l in locales:
		var px := float(l["x"])
		var pz := float(l["z"])
		var hacia := Vector2(float(l["hx"]), float(l["hz"]))
		var dir := Vector2(float(l["dx"]), float(l["dz"]))
		var col_arr: Array = l["c"]
		var col := Color(float(col_arr[0]), float(col_arr[1]), float(col_arr[2]))
		var rot := atan2(dir.x, dir.y)
		if String(l["t"]) == "gasolinera":
			# Estación de servicio: explanada, marquesina sobre
			# pilares en el color de la marca, tres surtidores,
			# tienda detrás y tótem de precios junto a la calle.
			var gy := _altura(px, pz)
			var cen := Vector2(px, pz)
			_caja_en(verts, normals, cols, Vector3(px, gy + 0.05, pz), Vector3(13.0, 0.10, 12.0), Color(0.60, 0.60, 0.62), rot)
			_caja_en(verts, normals, cols, Vector3(px, gy + 4.95, pz), Vector3(7.2, 0.42, 11.4), col, rot)
			# La cenefa clara de la marquesina: de canto, desde
			# la calle, es lo que hace que se lea «gasolinera»
			# (la losa naranja sola se perdía contra el cielo).
			_caja_en(verts, normals, cols, Vector3(px, gy + 4.60, pz), Vector3(7.5, 0.52, 11.7), Color(0.93, 0.93, 0.94), rot)
			for ph in [-2.9, 2.9]:
				for pd in [-4.7, 4.7]:
					var pp: Vector2 = cen + hacia * ph + dir * pd
					_caja_en(verts, normals, cols, Vector3(pp.x, _altura(pp.x, pp.y) + 2.30, pp.y), Vector3(0.24, 4.60, 0.24), Color(0.85, 0.85, 0.87), 0.0)
			for pd2 in [-2.3, 0.0, 2.3]:
				var sp: Vector2 = cen + dir * pd2
				var sy := _altura(sp.x, sp.y)
				_caja_en(verts, normals, cols, Vector3(sp.x, sy + 0.30, sp.y), Vector3(1.6, 0.12, 0.9), Color(0.45, 0.45, 0.48), rot)
				# El surtidor claro y con su banda de marca:
				# el oscuro antiguo no se veía ni de cerca.
				_caja_en(verts, normals, cols, Vector3(sp.x, sy + 0.92, sp.y), Vector3(0.62, 1.25, 0.44), Color(0.88, 0.88, 0.90), rot)
				_caja_en(verts, normals, cols, Vector3(sp.x, sy + 1.05, sp.y), Vector3(0.64, 0.55, 0.46), col, rot)
				_caja_en(verts, normals, cols, Vector3(sp.x, sy + 1.60, sp.y), Vector3(0.64, 0.12, 0.46), col, rot)
			# Dos coches repostando: sin ellos la estación
			# parecía abandonada (Jon: «no se ven coches»).
			# Van al lado de dentro: desde la calle se ven los
			# surtidores delante y los coches detrás.
			var rot_coche := atan2(dir.x, dir.y)
			for pd3 in [-2.3, 2.3]:
				var cp: Vector2 = cen + dir * pd3 - hacia * 1.8
				_coche_aparcado(verts, normals, cols, cp.x, cp.y, rot_coche, int(pd3 * 10.0) + 40)
			var tp2: Vector2 = cen - hacia * 5.4
			var ty := _altura(tp2.x, tp2.y)
			_caja_en(verts, normals, cols, Vector3(tp2.x, ty + 1.35, tp2.y), Vector3(3.4, 2.70, 5.6), Color(0.88, 0.87, 0.84), rot)
			_caja_en(verts, normals, cols, Vector3(tp2.x, ty + 2.85, tp2.y), Vector3(3.5, 0.28, 5.7), col, rot)
			# El escaparate oscuro de la tienda, hacia la calle
			var tf: Vector2 = tp2 + hacia * 1.72
			var tfy := _altura(tf.x, tf.y)
			_caja_en(verts, normals, cols, Vector3(tf.x, tfy + 1.15, tf.y), Vector3(0.14, 1.70, 4.6), Color(0.16, 0.19, 0.24), rot)
			var tot: Vector2 = cen + hacia * 6.2 + dir * 5.2
			var toy := _altura(tot.x, tot.y)
			_caja_en(verts, normals, cols, Vector3(tot.x, toy + 2.10, tot.y), Vector3(0.26, 4.20, 0.26), Color(0.30, 0.30, 0.33), 0.0)
			_caja_en(verts, normals, cols, Vector3(tot.x, toy + 3.60, tot.y), Vector3(0.20, 1.70, 1.25), col, rot)
			# La tabla de precios, blanca bajo el panel de marca
			_caja_en(verts, normals, cols, Vector3(tot.x, toy + 2.30, tot.y), Vector3(0.18, 1.05, 1.25), Color(0.95, 0.95, 0.96), rot)
			_rotulos_tile_actual.append({"n": String(l["n"]), "h": hacia, "w": 1.15, "p": Vector3(tot.x + hacia.x * 0.4, toy + 3.60, tot.y + hacia.y * 0.4)})
			n += 1
			continue
		# El escaparate se apoya en la fachada: si el punto cae dentro
		# del edificio, se avanza hacia la calle hasta salir.
		var frente := Vector2(px, pz) + hacia * 1.1
		if _choca(Vector2(px, pz), 0.35):
			# El punto cae dentro del edificio: se sale hacia la
			# calle con correa larga (hay manzanas de 20 m y
			# naves de 45 m con el punto en el centro; con la
			# corta el escaparate quedaba enterrado dentro).
			var pasos := 0
			while _choca(frente, 0.35) and pasos < 90:
				frente += hacia * 0.55
				pasos += 1
		elif _choca(frente, 0.35):
			# El punto esta fuera pero el frente cae dentro: la
			# pared buena es la primera que se toca.
			var q := Vector2(px, pz) + hacia * 0.55
			var s2 := 0
			while not _choca(q, 0.35) and s2 < 4:
				q += hacia * 0.55
				s2 += 1
			frente = q - hacia * 0.55
		else:
			# El punto esta en la acera con el edificio a la
			# espalda: se busca la pared hacia atras.
			var g := Vector2(px, pz) - hacia * 0.55
			var s3 := 0
			while s3 < 12:
				if _choca(g, 0.35):
					frente = g + hacia * 0.55
					break
				g -= hacia * 0.55
				s3 += 1
		var y := _altura(frente.x, frente.y)
		var zona_p := _es_pinchos(frente)
		_caja_en(verts, normals, cols, Vector3(frente.x, y + 1.45, frente.y), Vector3(0.30, 2.90, 6.4), Color(0.48, 0.60, 0.72), rot)
		_caja_en(verts, normals, cols, Vector3(frente.x, y + 1.45, frente.y), Vector3(0.34, 2.90, 0.95), Color(0.16, 0.18, 0.22), rot)
		_caja_en(verts, normals, cols, Vector3(frente.x, y + 2.98, frente.y), Vector3(0.34, 0.24, 6.6), col, rot)
		_caja_en(verts, normals, cols, Vector3(frente.x, y + 0.10, frente.y), Vector3(0.34, 0.20, 6.6), col.darkened(0.25), rot)
		var pos_cartel := frente + hacia * 0.22
		_caja_en(verts, normals, cols, Vector3(pos_cartel.x, y + 3.50, pos_cartel.y), Vector3(0.22, 0.72, 6.6), col, rot)
		var zona_e := _es_eje(frente)
		if String(l["t"]) in ["bar", "tienda", "farmacia"] or (zona_e and String(l["t"]) in ["banco", "oficina"]):
			var pos_toldo := frente + hacia * 0.75
			_caja_en(verts, normals, cols, Vector3(pos_toldo.x, y + 2.62, pos_toldo.y), Vector3(1.5, 0.07, 6.4 if (zona_p or zona_e) else 4.6), col.lerp(Color.WHITE, 0.25), rot)
		if zona_p and String(l["t"]) == "bar":
			# Toneles de pie flanqueando la puerta: la foto
			# clásica del Laurel, fundidos en la misma malla.
			for lado in [-2.35, 2.35]:
				var pb: Vector2 = frente + hacia * 1.05 + dir * float(lado)
				if _choca(pb, 0.5):
					continue
				var yb := _altura(pb.x, pb.y)
				_caja_en(verts, normals, cols, Vector3(pb.x, yb + 0.46, pb.y), Vector3(0.66, 0.92, 0.66), Color(0.45, 0.32, 0.20), rot)
				_caja_en(verts, normals, cols, Vector3(pb.x, yb + 0.95, pb.y), Vector3(0.70, 0.06, 0.70), Color(0.30, 0.21, 0.13), rot)
				_caja_en(verts, normals, cols, Vector3(pb.x, yb + 0.62, pb.y), Vector3(0.69, 0.07, 0.69), Color(0.25, 0.18, 0.12), rot)
		if int(l["tz"]) == 1:
			var mesas := 0
			# Las cuatro cafeterías del Espolón (Ibiza, La Rosaleda,
			# Delicias y Cuatro) llevan terraza grande: 6 mesas en dos
			# filas y clientes sentados, como las de verdad.
			var n_mesas := 6 if String(l["n"]) in ["Ibiza", "La Rosaleda", "Cafe Delicias", "Bar Cuatro", "Café Kiosco La Fundación"] else 3
			for m in n_mesas:
				var lat := (float(m % 3) - 1.0) * 1.9
				var tp := frente + hacia * ((1.95 if zona_p else 2.6) + 0.4 * float(m % 2) + 1.7 * float(m / 3)) + dir * lat
				if _choca(tp, 0.55):
					continue
				var yt := _altura(tp.x, tp.y)
				_caja_en(verts, normals, cols, Vector3(tp.x, yt + 0.74, tp.y), Vector3(0.95, 0.06, 0.95), Color(0.92, 0.90, 0.86), rot + 0.3)
				_caja_en(verts, normals, cols, Vector3(tp.x, yt + 0.37, tp.y), Vector3(0.09, 0.72, 0.09), Color(0.25, 0.25, 0.27), 0.0)
				for s in [-1.0, 1.0]:
					var sp: Vector2 = tp + dir * (float(s) * 0.85)
					_caja_en(verts, normals, cols, Vector3(sp.x, _altura(sp.x, sp.y) + 0.24, sp.y), Vector3(0.42, 0.48, 0.42), Color(0.40, 0.33, 0.22), rot)
				if m == 1 or m == 4:
					_caja_en(verts, normals, cols, Vector3(tp.x, yt + 1.55, tp.y), Vector3(0.07, 1.7, 0.07), Color(0.30, 0.28, 0.25), 0.0)
					_caja_en(verts, normals, cols, Vector3(tp.x, yt + 2.42, tp.y), Vector3(2.1, 0.10, 2.1), col.lerp(Color.WHITE, 0.15), rot + PI / 4.0)
				mesas += 1
			if mesas > 0:
				con_terraza += 1
			if n_mesas == 6 and mesas >= 4:
				# Dos clientes sentados en la terraza: se ve habitada
				var paleta_cli := [Color(0.65, 0.30, 0.28), Color(0.25, 0.40, 0.60), Color(0.80, 0.68, 0.30), Color(0.35, 0.55, 0.35)]
				for silla in [1, 4]:
					var tp_s := frente + hacia * (2.6 + 0.4 * float(silla % 2) + 1.7 * float(silla / 3)) + dir * ((float(silla % 3) - 1.0) * 1.9 + 0.85)
					var per_s := _hacer_persona(paleta_cli[(silla + n) % 4], Color(0.24, 0.24, 0.28), Color(0.30, 0.22, 0.15), false, silla == 4)
					var raiz_s: Node3D = per_s["raiz"]
					raiz_s.position = Vector3(tp_s.x, _altura(tp_s.x, tp_s.y) + 0.52, tp_s.y)
					raiz_s.rotation.y = atan2(-dir.x, -dir.y)
					add_child(raiz_s)
					(per_s["pi"] as Node3D).rotation.x = -1.25
					(per_s["pd"] as Node3D).rotation.x = -1.25
					_estaticos.append({"d": per_s, "raiz": raiz_s, "tipo": "sentado", "fase": _rng.randf() * 6.0})
		_rotulos_tile_actual.append({"n": String(l["n"]), "h": hacia, "w": 4.6, "p": Vector3(pos_cartel.x + hacia.x * 0.36, y + 3.50, pos_cartel.y + hacia.y * 0.36)})
		n += 1
	if n > 0:
		cont.add_child(_malla_de(verts, normals, cols, Color.WHITE))
	_locales_total += n
	_terrazas_total += con_terraza

func _refrescar_rotulos() -> void:
	# Los nombres de los locales NO son un Label3D por local: con
	# cientos de rótulos fijos la versión web dejaba de dibujar la
	# escena entera (verificado por bisección). Se crean solo los de
	# los locales cercanos (máx. 48, a menos de 140 m) y se retiran
	# al alejarse: el nombre aparece donde estás, sin saturar nada.
	if _jugador == null:
		return
	var jp := _coche.position if _en_coche and _coche != null else _jugador.position
	var candidatos: Array = []
	var grandes: Array = []
	for clave in _rotulos_datos:
		for r in _rotulos_datos[clave]:
			var p: Vector3 = r["p"]
			var dx := p.x - jp.x
			var dz := p.z - jp.z
			var d2 := dx * dx + dz * dz
			if d2 < 19600.0:
				candidatos.append([d2, clave, r])
			elif float(r.get("g", 1.0)) >= 3.5 and d2 < 250000.0:
				grandes.append([d2, clave, r])
	candidatos.sort_custom(func(a, b): return a[0] < b[0])
	grandes.sort_custom(func(a, b): return a[0] < b[0])
	var deseados := {}
	var hechos := 0
	var orden: Array = []
	var ng := 0
	for c in grandes:
		if ng >= 24:
			break
		orden.append(c)
		ng += 1
	orden.append_array(candidatos)
	var placas_c: Array = []
	for r in _placas_datos:
		var pp2: Vector3 = r["p"]
		var dxp := pp2.x - jp.x
		var dzp := pp2.z - jp.z
		var d2p := dxp * dxp + dzp * dzp
		if d2p < 4900.0:
			placas_c.append([d2p, "placa", r])
	placas_c.sort_custom(func(a, b): return a[0] < b[0])
	var np := 0
	for pc in placas_c:
		if np >= 10:
			break
		orden.append(pc)
		np += 1
	for c in orden:
		if hechos >= 64:
			break
		var rp: Vector3 = c[2]["p"]
		var id := String(c[1]) + "|" + str(int(rp.x)) + "," + str(int(rp.z)) + "|" + String(c[2]["n"])
		deseados[id] = c[2]
		hechos += 1
	for id in _rotulos_activos.keys():
		if not deseados.has(id):
			_rotulos_activos[id].queue_free()
			_rotulos_activos.erase(id)
	for id in deseados:
		if not _rotulos_activos.has(id):
			var r: Dictionary = deseados[id]
			var et := Label3D.new()
			var nombre_r := String(r["n"])
			et.text = nombre_r
			et.font_size = 96
			# Pegado a su cartel y sin pasarse de su ancho: letras de
			# hasta 0,50 m (antes ~1 m: en las calles estrechas el
			# nombre ocupaba media calle y no dejaba ver ni pasar).
			et.pixel_size = minf(0.0052 * float(r.get("g", 1.0)), float(r.get("w", 4.6)) / (float(maxi(1, nombre_r.length())) * 48.0))
			et.modulate = Color(1, 1, 1)
			et.outline_size = 6
			et.outline_modulate = Color(0.05, 0.05, 0.08)
			et.position = r["p"]
			var hr: Vector2 = r.get("h", Vector2(0, 1))
			et.rotation.y = atan2(hr.x, hr.y)
			add_child(et)
			_rotulos_activos[id] = et

func _pois_tile(cont: Node3D, pois: Array) -> void:
	for p in pois:
		# Solo los lugares señalados (c=1) llevan pilar y rótulo 3D: crear
		# un Label3D por cada punto destacado de la baldosa disparaba el
		# número de objetos en pantalla y la versión web dejaba de dibujar.
		if int(p.get("c", 0)) != 1:
			continue
		var px := float(p["x"])
		var pz := float(p["z"])
		var pos := Vector3(px, _altura(px, pz), pz)
		cont.add_child(_marcador(pos, Color(1.0, 0.78, 0.2), false, 0.45, true))
		var et := Label3D.new()
		et.text = String(p["n"])
		et.font_size = 96
		et.pixel_size = 0.009
		et.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		et.modulate = Color(1.0, 0.85, 0.3)
		et.outline_size = 12
		et.outline_modulate = Color(0.10, 0.08, 0.02)
		et.position = pos + Vector3(0, 11, 0)
		cont.add_child(et)

func _camara_y_luz() -> void:
	_cam = Camera3D.new()
	_cam.look_at_from_position(Vector3(0, 900, 900), Vector3.ZERO, Vector3.UP)
	add_child(_cam)
	_cam.current = true
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -118, 0)
	sol.light_color = Color(1.0, 0.97, 0.92)
	sol.light_energy = 1.15
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 350.0
	add_child(sol)
	var entorno := WorldEnvironment.new()
	var env := Environment.new()
	# Día limpio (Tanda 12, paquete de acabado): cielo azul con el
	# horizonte pálido, ambiente neutro y niebla azul grisácea muy
	# ligera. Antes era un atardecer naranja permanente que teñía
	# toda la ciudad (Fase 4).
	env.background_mode = Environment.BG_SKY
	var mat_cielo := ProceduralSkyMaterial.new()
	mat_cielo.sky_top_color = Color(0.25, 0.50, 0.85)
	mat_cielo.sky_horizon_color = Color(0.78, 0.87, 0.95)
	mat_cielo.ground_bottom_color = Color(0.35, 0.36, 0.38)
	mat_cielo.ground_horizon_color = Color(0.72, 0.78, 0.84)
	mat_cielo.sun_angle_max = 30.0
	var cielo := Sky.new()
	cielo.sky_material = mat_cielo
	env.sky = cielo
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.78, 0.88)
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color(0.80, 0.86, 0.92)
	env.fog_density = 0.00032
	entorno.environment = env
	add_child(entorno)
	_nubes()
	# Interfaz en pantalla: pastilla de calle, teléfono, minimapa,
	# píldora de distancia, botón de subir/bajar y banner del encargo
	var capa := CanvasLayer.new()
	add_child(capa)
	_crear_hud(capa)
	_actualizar_hud_dinero()
	_actualizar_hud()

func _nubes() -> void:
	# Nubes del día limpio: 16 láminas grandes y suaves a 300-380 m
	# de altura con la textura nubes.png (manchas blancas difusas).
	# Sin sombreado y sin escribir profundidad: se ven como nubes
	# lejanas desde cualquier calle. Semilla fija: siempre las
	# mismas, para que las capturas sean comparables.
	var tex_n := load("res://nubes.png") as Texture2D
	if tex_n == null:
		return
	var mat_n := StandardMaterial3D.new()
	mat_n.albedo_texture = tex_n
	mat_n.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_n.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_n.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Billboard: la lámina mira siempre a la cámara. Tumbada en
	# horizontal se veía de canto desde la calle: dos rayas
	# blancas en vez de nubes (primera captura de la tanda).
	mat_n.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var rng_n := RandomNumberGenerator.new()
	rng_n.seed = 20261124
	for i in 16:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		var ancho_n := rng_n.randf_range(260.0, 560.0)
		qm.size = Vector2(ancho_n, ancho_n * 0.5)
		qm.material = mat_n
		q.mesh = qm
		q.position = Vector3(rng_n.randf_range(-2900.0, 2900.0), rng_n.randf_range(300.0, 380.0), rng_n.randf_range(-2200.0, 2200.0))
		add_child(q)

func _estilo_caja(color: Color, radio: int, borde := 0, col_borde := Color(1, 1, 1)) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = color
	e.set_corner_radius_all(radio)
	if borde > 0:
		e.set_border_width_all(borde)
		e.border_color = col_borde
	return e

func _en_redondo(x: float, y: float, x0: float, y0: float, x1: float, y1: float, r: float) -> bool:
	if x < x0 or x > x1 or y < y0 or y > y1:
		return false
	var cx := clampf(x, x0 + r, x1 - r)
	var cy := clampf(y, y0 + r, y1 - r)
	return Vector2(x, y).distance_to(Vector2(cx, cy)) <= r or (x >= x0 + r and x <= x1 - r) or (y >= y0 + r and y <= y1 - r)

func _icono_telefono() -> ImageTexture:
	# Un teléfono dibujado píxel a píxel (icono propio, sin ficheros)
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 96:
		for x in 96:
			if _en_redondo(x, y, 30, 8, 66, 88, 11):
				img.set_pixel(x, y, Color(0.13, 0.14, 0.18))
			if x >= 36 and x <= 60 and y >= 22 and y <= 68:
				img.set_pixel(x, y, Color(0.55, 0.75, 0.95))
			if x >= 43 and x <= 53 and y >= 14 and y <= 17:
				img.set_pixel(x, y, Color(0.65, 0.67, 0.72))
			if Vector2(x, y).distance_to(Vector2(48, 78)) <= 3.5:
				img.set_pixel(x, y, Color(0.65, 0.67, 0.72))
	return ImageTexture.create_from_image(img)

func _icono_pin(color: Color) -> ImageTexture:
	# Una chincheta de mapa dibujada por código (círculo y pico)
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 64:
		for x in 48:
			var dentro := Vector2(x, y).distance_to(Vector2(24, 23)) <= 20.0
			if y > 23 and y <= 61:
				var mitad := (61.0 - float(y)) * (19.0 / 38.0)
				if absf(float(x) - 24.0) <= mitad:
					dentro = true
			if dentro:
				img.set_pixel(x, y, color)
			if Vector2(x, y).distance_to(Vector2(24, 23)) <= 8.5:
				img.set_pixel(x, y, Color(1, 1, 1))
	return ImageTexture.create_from_image(img)

func _icono_volante() -> ImageTexture:
	# Un volante sencillo (aro, radios y buje) dibujado por código
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var col := Color(0.88, 0.89, 0.92)
	for y in 96:
		for x in 96:
			var d := Vector2(x, y).distance_to(Vector2(48, 48))
			var dentro := (d >= 29.0 and d <= 38.0)
			if y >= 44 and y <= 52 and d <= 38.0:
				dentro = true
			if x >= 44 and x <= 52 and y >= 48 and d <= 38.0:
				dentro = true
			if d <= 10.0:
				dentro = true
			if dentro:
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _crear_hud(capa: CanvasLayer) -> void:
	# Pastilla azul con el nombre de la calle, centrada arriba
	var pill := PanelContainer.new()
	pill.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pill.offset_left = -210
	pill.offset_right = 210
	pill.offset_top = 10
	pill.offset_bottom = 58
	var est_pill := _estilo_caja(Color(0.09, 0.26, 0.55, 0.96), 24)
	est_pill.content_margin_left = 20
	est_pill.content_margin_right = 20
	pill.add_theme_stylebox_override("panel", est_pill)
	_et_calle = Label.new()
	_et_calle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_et_calle.add_theme_font_size_override("font_size", 25)
	_et_calle.add_theme_color_override("font_color", Color(1, 1, 1))
	_et_calle.text = ""
	pill.add_child(_et_calle)
	capa.add_child(pill)
	# Botón del teléfono (arriba a la izquierda): encargos y mapa
	var tel := Button.new()
	tel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tel.offset_left = 14
	tel.offset_top = 12
	tel.offset_right = 92
	tel.offset_bottom = 90
	tel.add_theme_stylebox_override("normal", _estilo_caja(Color(0.97, 0.97, 0.98), 39, 3, Color(0.15, 0.16, 0.20)))
	tel.add_theme_stylebox_override("hover", _estilo_caja(Color(0.88, 0.90, 0.95), 39, 3, Color(0.15, 0.16, 0.20)))
	tel.add_theme_stylebox_override("pressed", _estilo_caja(Color(0.80, 0.84, 0.90), 39, 3, Color(0.15, 0.16, 0.20)))
	tel.add_theme_stylebox_override("focus", _estilo_caja(Color(0, 0, 0, 0), 39))
	var ic_tel := TextureRect.new()
	ic_tel.texture = _icono_telefono()
	ic_tel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic_tel.offset_left = 13
	ic_tel.offset_top = 13
	ic_tel.offset_right = -13
	ic_tel.offset_bottom = -13
	ic_tel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic_tel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic_tel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tel.add_child(ic_tel)
	tel.pressed.connect(_t_telefono)
	capa.add_child(tel)
	# Bocadillo de pista junto al teléfono (hasta que lo tocas una vez)
	_burbuja = PanelContainer.new()
	_burbuja.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_burbuja.offset_left = 104
	_burbuja.offset_top = 26
	_burbuja.offset_right = 452
	_burbuja.offset_bottom = 76
	var est_b := _estilo_caja(Color(0.98, 0.98, 0.99, 0.98), 16)
	est_b.content_margin_left = 16
	est_b.content_margin_right = 16
	_burbuja.add_theme_stylebox_override("panel", est_b)
	var lb := Label.new()
	lb.text = "Toca el teléfono: encargos y mapa"
	lb.add_theme_font_size_override("font_size", 20)
	lb.add_theme_color_override("font_color", Color(0.10, 0.11, 0.14))
	_burbuja.add_child(lb)
	capa.add_child(_burbuja)
	# Dinero y reloj: píldora pequeña bajo el teléfono
	var pill_d := PanelContainer.new()
	pill_d.set_anchors_preset(Control.PRESET_TOP_LEFT)
	pill_d.offset_left = 14
	pill_d.offset_top = 102
	pill_d.offset_right = 238
	pill_d.offset_bottom = 142
	var est_d := _estilo_caja(Color(0.07, 0.08, 0.11, 0.85), 20)
	est_d.content_margin_left = 14
	est_d.content_margin_right = 14
	pill_d.add_theme_stylebox_override("panel", est_d)
	_hud_dinero = Label.new()
	_hud_dinero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_dinero.add_theme_font_size_override("font_size", 19)
	_hud_dinero.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	pill_d.add_child(_hud_dinero)
	capa.add_child(pill_d)
	# Velocimetro: solo se ve conduciendo (coche o bici)
	_pill_vel = PanelContainer.new()
	_pill_vel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_pill_vel.offset_left = -176
	_pill_vel.offset_top = -88
	_pill_vel.offset_right = -14
	_pill_vel.offset_bottom = -28
	var est_v := _estilo_caja(Color(0.07, 0.08, 0.11, 0.85), 20)
	est_v.content_margin_left = 16
	est_v.content_margin_right = 16
	_pill_vel.add_theme_stylebox_override("panel", est_v)
	_hud_vel = Label.new()
	_hud_vel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_vel.add_theme_font_size_override("font_size", 30)
	_hud_vel.add_theme_color_override("font_color", Color(1, 1, 1))
	_hud_vel.text = "0 km/h"
	_pill_vel.add_child(_hud_vel)
	_pill_vel.visible = false
	capa.add_child(_pill_vel)
	# Menú del teléfono (oculto hasta tocar el botón)
	_menu_tel = PanelContainer.new()
	_menu_tel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_menu_tel.offset_left = 14
	_menu_tel.offset_top = 154
	_menu_tel.offset_right = 264
	_menu_tel.offset_bottom = 596
	var est_m := _estilo_caja(Color(0.07, 0.09, 0.13, 0.97), 14)
	est_m.content_margin_left = 12
	est_m.content_margin_right = 12
	est_m.content_margin_top = 12
	est_m.content_margin_bottom = 12
	_menu_tel.add_theme_stylebox_override("panel", est_m)
	var vm := VBoxContainer.new()
	vm.add_theme_constant_override("separation", 8)
	_menu_tel.add_child(vm)
	var b_enc := Button.new()
	b_enc.text = "Encargos"
	b_enc.add_theme_font_size_override("font_size", 21)
	b_enc.pressed.connect(func() -> void: _desde_tel(_t_encargos))
	vm.add_child(b_enc)
	var b_map := Button.new()
	b_map.text = "Mapa"
	b_map.add_theme_font_size_override("font_size", 21)
	b_map.pressed.connect(func() -> void: _desde_tel(_t_mapa))
	vm.add_child(b_map)
	var b_ayu := Button.new()
	b_ayu.text = "Ayuda"
	b_ayu.add_theme_font_size_override("font_size", 21)
	b_ayu.pressed.connect(func() -> void: _desde_tel(_t_ayuda))
	vm.add_child(b_ayu)
	_btn_personaje_tel = Button.new()
	_btn_personaje_tel.text = "Personaje: chica" if _personaje == 1 else "Personaje: chico"
	_btn_personaje_tel.add_theme_font_size_override("font_size", 21)
	_btn_personaje_tel.pressed.connect(func() -> void: _desde_tel(_cambiar_personaje))
	vm.add_child(_btn_personaje_tel)
	var b_coc := Button.new()
	b_coc.text = "Mis coches"
	b_coc.add_theme_font_size_override("font_size", 21)
	b_coc.pressed.connect(func() -> void: _desde_tel(func() -> void: _abrir_panel_coches("garaje")))
	vm.add_child(b_coc)
	var b_esp := Button.new()
	b_esp.text = "Trabajos especiales"
	b_esp.add_theme_font_size_override("font_size", 21)
	b_esp.pressed.connect(func() -> void: _desde_tel(_abrir_panel_esp))
	vm.add_child(b_esp)
	var b_his := Button.new()
	b_his.text = "Historia"
	b_his.add_theme_font_size_override("font_size", 21)
	b_his.pressed.connect(func() -> void: _desde_tel(_historia_info))
	vm.add_child(b_his)
	var b_carr := Button.new()
	b_carr.text = "Carreras"
	b_carr.add_theme_font_size_override("font_size", 21)
	b_carr.pressed.connect(func() -> void: _desde_tel(_abrir_panel_carr))
	vm.add_child(b_carr)
	_btn_sonido_tel = Button.new()
	_btn_sonido_tel.text = "Sonido: activado"
	_btn_sonido_tel.add_theme_font_size_override("font_size", 21)
	_btn_sonido_tel.pressed.connect(_desde_tel_sonido)
	vm.add_child(_btn_sonido_tel)
	var b_cam := Button.new()
	b_cam.text = "Camiseta: cambiar color"
	b_cam.add_theme_font_size_override("font_size", 21)
	b_cam.pressed.connect(_desde_tel_camiseta)
	vm.add_child(b_cam)
	var b_pelo := Button.new()
	b_pelo.text = "Pelo: cambiar color"
	b_pelo.add_theme_font_size_override("font_size", 21)
	b_pelo.pressed.connect(_desde_tel_pelo)
	vm.add_child(b_pelo)
	_menu_tel.visible = false
	capa.add_child(_menu_tel)
	# Minimapa circular (arriba a la derecha); tocarlo abre el mapa grande
	_minimapa = Control.new()
	_minimapa.set_script(load("res://minimapa.gd"))
	_minimapa.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_minimapa.offset_left = -208
	_minimapa.offset_right = -12
	_minimapa.offset_top = 12
	_minimapa.offset_bottom = 208
	_minimapa.connect("pulsado", _t_mapa)
	capa.add_child(_minimapa)
	# Botón redondo de vista aérea, bajo el minimapa
	var vista := Button.new()
	vista.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	vista.offset_left = -140
	vista.offset_right = -84
	vista.offset_top = 218
	vista.offset_bottom = 274
	vista.add_theme_stylebox_override("normal", _estilo_caja(Color(0.32, 0.33, 0.38, 0.92), 28))
	vista.add_theme_stylebox_override("hover", _estilo_caja(Color(0.42, 0.43, 0.48, 0.95), 28))
	vista.add_theme_stylebox_override("pressed", _estilo_caja(Color(0.24, 0.25, 0.29, 0.95), 28))
	vista.add_theme_stylebox_override("focus", _estilo_caja(Color(0, 0, 0, 0), 28))
	var ic_v := TextureRect.new()
	ic_v.texture = _icono_volante()
	ic_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic_v.offset_left = 9
	ic_v.offset_top = 9
	ic_v.offset_right = -9
	ic_v.offset_bottom = -9
	ic_v.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic_v.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vista.add_child(ic_v)
	vista.pressed.connect(_t_vista)
	capa.add_child(vista)
	# Píldora blanca con la distancia al destino y su X
	_pildora = PanelContainer.new()
	_pildora.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pildora.offset_left = -196
	_pildora.offset_right = -12
	_pildora.offset_top = 286
	_pildora.offset_bottom = 336
	var est_pi := _estilo_caja(Color(0.97, 0.97, 0.98, 0.97), 25)
	est_pi.content_margin_left = 14
	est_pi.content_margin_right = 8
	_pildora.add_theme_stylebox_override("panel", est_pi)
	var hp := HBoxContainer.new()
	hp.add_theme_constant_override("separation", 7)
	_pildora.add_child(hp)
	var ic_pin := TextureRect.new()
	ic_pin.texture = _icono_pin(Color(0.88, 0.22, 0.16))
	ic_pin.custom_minimum_size = Vector2(21, 28)
	ic_pin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic_pin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic_pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp.add_child(ic_pin)
	_pildora_texto = Label.new()
	_pildora_texto.add_theme_font_size_override("font_size", 22)
	_pildora_texto.add_theme_color_override("font_color", Color(0.10, 0.11, 0.14))
	_pildora_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp.add_child(_pildora_texto)
	var bx := Button.new()
	bx.text = "×"
	bx.flat = true
	bx.add_theme_font_size_override("font_size", 24)
	bx.add_theme_color_override("font_color", Color(0.35, 0.36, 0.40))
	bx.pressed.connect(_cancelar_trabajo)
	hp.add_child(bx)
	_pildora.visible = false
	capa.add_child(_pildora)
	# Botón azul de subir/bajar del coche
	_btn_bajar = Button.new()
	_btn_bajar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_btn_bajar.offset_left = -320
	_btn_bajar.offset_right = -12
	_btn_bajar.offset_top = 348
	_btn_bajar.offset_bottom = 408
	_btn_bajar.add_theme_font_size_override("font_size", 23)
	# Que ninguna indicación se salga de la pantalla: el texto
	# se parte en dos líneas dentro del botón si hace falta
	# (pasaba con «Decathlon: un casco de ciclismo (35 €)»).
	_btn_bajar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_btn_bajar.clip_text = true
	_btn_bajar.add_theme_color_override("font_color", Color(1, 1, 1))
	_btn_bajar.add_theme_stylebox_override("normal", _estilo_caja(Color(0.10, 0.36, 0.85, 0.97), 16))
	_btn_bajar.add_theme_stylebox_override("hover", _estilo_caja(Color(0.16, 0.44, 0.95, 0.97), 16))
	_btn_bajar.add_theme_stylebox_override("pressed", _estilo_caja(Color(0.07, 0.28, 0.70, 0.97), 16))
	_btn_bajar.add_theme_stylebox_override("focus", _estilo_caja(Color(0, 0, 0, 0), 16))
	_btn_bajar.text = "Bajar"
	_btn_bajar.pressed.connect(_t_coche)
	_btn_bajar.visible = false
	capa.add_child(_btn_bajar)
	# Banner oscuro del encargo, centrado abajo
	_banner = PanelContainer.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_banner.offset_left = -315
	_banner.offset_right = 315
	_banner.offset_top = -94
	_banner.offset_bottom = -16
	var est_bn := _estilo_caja(Color(0.06, 0.07, 0.10, 0.94), 16)
	est_bn.content_margin_left = 16
	est_bn.content_margin_right = 8
	_banner.add_theme_stylebox_override("panel", est_bn)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	_banner.add_child(hb)
	var ic_pin2 := TextureRect.new()
	ic_pin2.texture = _icono_pin(Color(0.98, 0.70, 0.15))
	ic_pin2.custom_minimum_size = Vector2(23, 31)
	ic_pin2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic_pin2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic_pin2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(ic_pin2)
	_banner_texto = Label.new()
	_banner_texto.add_theme_font_size_override("font_size", 20)
	_banner_texto.add_theme_color_override("font_color", Color(1, 1, 1))
	_banner_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_banner_texto.clip_text = true
	# Las indicaciones largas se parten en dos líneas en vez
	# de cortarse a mitad de frase.
	_banner_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hb.add_child(_banner_texto)
	var bx2 := Button.new()
	bx2.text = "×"
	bx2.flat = true
	bx2.add_theme_font_size_override("font_size", 26)
	bx2.add_theme_color_override("font_color", Color(0.75, 0.77, 0.82))
	bx2.pressed.connect(_cancelar_trabajo)
	hb.add_child(bx2)
	_banner.visible = false
	capa.add_child(_banner)

func _t_telefono() -> void:
	if _burbuja != null:
		_burbuja.visible = false
	if _menu_tel != null:
		_menu_tel.visible = not _menu_tel.visible

func _desde_tel(accion: Callable) -> void:
	if _menu_tel != null:
		_menu_tel.visible = false
	accion.call()

func _desde_tel_camiseta() -> void:
	_camisa_idx = (_camisa_idx + 1) % CAMISETAS.size()
	if _mat_camisa_j != null:
		_mat_camisa_j.albedo_color = CAMISETAS[_camisa_idx]
	if _estampado_j != null:
		_estampado_j.visible = _camisa_idx == 0
	_guardar()

func _desde_tel_pelo() -> void:
	_pelo_idx = (_pelo_idx + 1) % PELOS.size()
	if _mat_pelo_j != null:
		_mat_pelo_j.albedo_color = PELOS[_pelo_idx]
	_guardar()

func _desde_tel_sonido() -> void:
	_t_sonido()
	if _btn_sonido_tel != null:
		_btn_sonido_tel.text = "Sonido: " + ("activado" if _sonido else "silenciado")

func _cancelar_trabajo() -> void:
	if _trabajo.is_empty():
		if not _esp.is_empty():
			_cancelar_especial()
		elif not _hist.is_empty():
			_hist_cancelar()
		elif not _enc.is_empty():
			_enc_cancelar()
		elif not _carr.is_empty():
			_cancelar_carrera()
		return
	_trabajo = {}
	_quitar_encargante()
	_fase_trabajo = 0
	_pilar_destino.visible = false
	_ruta_mini = []
	_objetivo_texto = "Encargo cancelado · Pulsa T para ver encargos"
	_banner_hasta = _tiempo + 4.0
	_generar_trabajos()
	_actualizar_hud()
	print("ENCARGO_CANCELADO")

func _cargar_calles_mapa() -> void:
	if _calles_mapa.is_empty():
		var datos_cm = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/calles_mapa.json"))
		if datos_cm != null:
			_calles_mapa = datos_cm["calles"]

func _ruta_para_minimapa() -> Array:
	var desde := _coche.position if _en_coche else _jugador.position
	if _ruta_mini.is_empty() or _ruta_mini_a != _destino_libre or desde.distance_to(_ruta_mini_de) > 30.0:
		_ruta_mini = _calcular_ruta(desde, _destino_libre)
		_ruta_mini_de = desde
		_ruta_mini_a = _destino_libre
	return _ruta_mini

func _carr_mapa_datos() -> Dictionary:
	# El plano de la carrera: recorrido muestreado, puntos de
	# control y la posición viva de cada participante.
	var riv: Array = []
	for est in _carr["rivales"]:
		var np: Vector3 = est["nodo"].position
		riv.append({"p": Vector2(np.x, np.z), "c": est["color"]})
	var gh = null
	var ghost: Dictionary = _carr["ghost"]
	if not ghost.is_empty():
		var gp: Vector3 = ghost["nodo"].position
		gh = Vector2(gp.x, gp.z)
	var cps2: Array = []
	for cp3 in _carr["cps"]:
		var v3: Vector3 = cp3
		cps2.append(Vector2(v3.x, v3.z))
	return {"puntos": _carr["mini_pts"], "cps": cps2, "sig": int(_carr["cp"]),
		"yo": Vector2(_coche.position.x, _coche.position.z), "rivales": riv, "ghost": gh}

func _datos_minimapa() -> Dictionary:
	_cargar_calles_mapa()
	var destino = null
	var ruta: Array = []
	if not _trabajo.is_empty():
		destino = Vector2(_destino_libre.x, _destino_libre.z)
		ruta = _ruta_para_minimapa()
	elif not _esp.is_empty() or not _hist.is_empty() or not _enc.is_empty() or _historia_idx < 12:
		destino = Vector2(_destino_libre.x, _destino_libre.z)
	if _pois_minimapa.is_empty():
		for p in _pois_mapa:
			if int(p.get("c", 0)) == 1:
				_pois_minimapa.append(p)
	var d := {"calles": _calles_mapa, "rio": _rio, "pois": _pois_minimapa, "ruta": ruta,
		"destino": destino, "jugador": Vector2(_bus.position.x, _bus.position.z) if _en_bus else (Vector2(_coche.position.x, _coche.position.z) if _en_coche else (Vector2(_jugador.position.x, _jugador.position.z) if _en_interior == "" else _ancla_minimapa)),
		"coche": Vector2(_coche.position.x, _coche.position.z), "en_coche": _en_coche or _en_bus,
		"rumbo": _dir_bus if _en_bus else (_coche_dir if _en_coche else _dir_jugador)}
	if not _carr.is_empty():
		d["carrera"] = _carr_mapa_datos()
	return d

func _refrescar_tactil() -> void:
	if _capa_conducir != null:
		_capa_conducir.visible = _en_coche
	if _joy_base != null:
		_joy_base.visible = not _en_coche
		_joy_perilla.visible = not _en_coche

var _corriendo := false
var _brazo_i: Node3D
var _cabeza_j: Node3D
var _brazo_d: Node3D
var _pierna_i: Node3D
var _pierna_d: Node3D
var _codo_i: Node3D
var _codo_d: Node3D
var _rodilla_i: Node3D
var _rodilla_d: Node3D
# Caras de los protagonistas (ojos que parpadean, boca que se
# mueve al hablar): {nombre, oi, od, boca, prox, cierra}.
var _caras: Array = []
var _fase_paso := 0.0
var _et_calle: Label
var _calles_nombradas: Array = []
var _ejes_polys: Array = []
var _placas_datos: Array = []
# Bloque 7: marquesinas de parada y contenedores colocados
var _b7_paradas := 0
var _b7_contenedores := 0
var _paradas_red: Array = []
var _t_calle := 0.0
# Fase 3: dinero, encargos, mapa
var _dinero := 60
var _dia := 1
var _minutos := 8 * 60 + 15.0
var _hud_dinero: Label
var _hud_vel: Label
var _pill_vel: PanelContainer
var _portales: Array = []
var _pois: Array = []
var _rio: Array = []
var _trabajos: Array = []
var _trabajo: Dictionary = {}
var _fase_trabajo := 0
var _pilar_destino: MeshInstance3D
var _panel: PanelContainer
var _panel_lista: VBoxContainer
var _panel_abierto := false
var _panel_coches: PanelContainer = null
var _panel_coches_lista: VBoxContainer = null
var _panel_coches_titulo: Label = null
var _panel_coches_abierto := false
var _lugares_coches := {}
var _en_interior := ""
var _catedral_partes := 0
var _fach_puertas := 0
var _fach_tejados := 0
var _fach_balcones := 0
var _fach_digitos := 0
var _tex_digitos: Texture2D = null
var _tex_fachadas := {}
var _tex_pb: Texture2D = null
var _catedral_torres := 0
var _igl_partes := 0
var _igl_torres := 0
var _sing_partes := 0
var _especiales := 0
var _empleo_desbloqueado := false
# Fase 12: trabajos especiales
var _panel_esp: PanelContainer = null
var _panel_esp_lista: VBoxContainer = null
var _panel_esp_abierto := false
var _esp: Dictionary = {}
var _linea1: Dictionary = {}
var _bus: Node3D = null
var _en_bus := false
var _vel_bus := 0.0
var _dir_bus := 0.0
var _bus_ruta: Array = []
var _bus_ruta_s: Array = []
var _bus_ruta_total := 0.0
var _bus_hint := 0
var _bus_s_prog := 0.0
var _bus_auto := false
var _masas: Array = []
var _historia_idx := 0
var _hist: Dictionary = {}
var _pjs: Dictionary = {}
var _panel_dlg: PanelContainer = null
var _dlg_nombre: Label = null
var _dlg_texto: Label = null
var _dlg_botones: HBoxContainer = null
var _dlg_abierto := false
var _dlg_sel := 0
var _dlg_lineas: Array = []
var _dlg_i := 0
var _dlg_al_cerrar: Callable = Callable()
var _dlg_opciones: Array = []
var _enc: Dictionary = {}
var _enc_prox := -1.0
var _carr: Dictionary = {}
var _carr_auto := false
var _records: Dictionary = {}
var _panel_carr: PanelContainer = null
var _panel_carr_lista: VBoxContainer = null
var _panel_carr_abierto := false
var _gim_t := 0.0
var _interiores := {}
var _tenderos: Array = []
var _volver_a := Vector3.ZERO
var _ancla_minimapa := Vector2.ZERO
var _mapa: Control
var _mapa_abierto := false
var _calles_mapa: Array = []
var _ayuda: PanelContainer
var _ayuda_dinero: Label
var _ayuda_abierta := false
var _rastro: Array = []
var _peatones: Array = []
var _estaticos: Array = []
var _perros: Array = []
var _tic_vis := 0.0
var _columpios: Array = []
var _skaters: Array = []
var _parque_columpios: Array = []
var _ruinas := false
var _balon_gal: Dictionary = {}
var _gallarza_verde := 0
var _pajaros: Array = []
var _palomas: Array = []
var _anciano_pos := Vector3.ZERO
var _frentes: Dictionary = {}
var _encargante: Node3D = null
var _camisa_idx := 0
var _pelo_idx := 0
var _mat_camisa_j: StandardMaterial3D
var _estampado_j: Node3D = null
var _personaje := 0  # 0 = chico, 1 = chica
var _btn_personaje_tel: Button = null
var _mat_pelo_j: StandardMaterial3D
var _son_motor: AudioStreamPlayer
var _son_amb: AudioStreamPlayer
var _son_pasos: AudioStreamPlayer
var _son_ding: AudioStreamPlayer
var _son_cobro: AudioStreamPlayer
var _banco := {}
var _son_rio: AudioStreamPlayer
var _son_centro: AudioStreamPlayer
var _son_viento: AudioStreamPlayer
var _son_parque: AudioStreamPlayer
var _son_musica: AudioStreamPlayer
var _mus_menu: AudioStream
var _mus_coche: AudioStream
var _frenada_cd := 0.0
var _bocina_cd := 0.0
var _paso_idx := 0
var _sonido := true
var _dist_pasos := 0.0
var _capa_tactil: CanvasLayer
var _joy_base: Panel
var _joy_perilla: Panel
var _joy_id := -1
var _joy_centro := Vector2.ZERO
var _joy_valor := Vector2.ZERO
var _trafico: Array = []
var _buses_urbanos: Array = []
var _lineas_bus: Array = []
var _bus_pasajero: Dictionary = {}
var _pois_minimapa: Array = []
var _asientos: Array = []
var _sentado := false
var _nadando := false
var _vel_nado := Vector2.ZERO
var _espuma_nado: MeshInstance3D = null
var _varado_cd := 0.0
var _aviso_banco_cd := 0.0
var _btn_modo := "coche"
var _locales_total := 0
var _rotulos_datos := {}
var _colegios_puertas := {}
var _rotulos_tile_actual: Array = []
var _rotulos_activos := {}
var _terrazas_total := 0
var _radares: Array = []
var _radar_cd := 0.0
var _aviso := ""
var _aviso_hasta := -1.0
var _tiles := {}
var _cola_tiles: Array = []
var _tile_timer := 0.0
var _t_mini := 0.0
var _pois_mapa: Array = []
var _rng := RandomNumberGenerator.new()
var _objetivo_texto := "Sin encargo · Pulsa T para ver encargos"

func _pieza(caja: Vector3, pos: Vector3, color: Color, mat: Material = null) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = caja
	inst.mesh = m
	inst.position = pos
	if mat != null:
		m.material = mat
	else:
		var nuevo := StandardMaterial3D.new()
		nuevo.albedo_color = color
		m.material = nuevo
	return inst

# Persona low-poly propia, con brazos y piernas articulados para andar.
# La raíz queda a la altura de la cadera; los pies están en -0,90.
func _fundida(cajas: Array) -> MeshInstance3D:
	# Varias cajas de colores fundidas en UNA malla de colores de vértice;
	# cada elemento de cajas es [centro, tamaño, color]. Se usa en los
	# personajes secundarios y los perros: por piezas sueltas, la gente de
	# la calle sumaba cientos de objetos en pantalla y la versión web
	# dejaba de dibujar la escena a los pocos minutos.
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	for cj in cajas:
		var parte: Array = cj
		_caja_en(verts, normals, cols, parte[0], parte[1], parte[2], 0.0)
	return _malla_de(verts, normals, cols, Color.WHITE)

func _hacer_persona(camisa: Color, pantalon: Color, pelo: Color, detalle := false, femenino := false, opc: Dictionary = {}) -> Dictionary:
	var p := Node3D.new()
	var piel := Color(opc.get("piel", Color(0.92, 0.72, 0.58)))
	var mat_camisa := StandardMaterial3D.new()
	mat_camisa.albedo_color = camisa
	var mat_pantalon := StandardMaterial3D.new()
	mat_pantalon.albedo_color = pantalon
	var mat_pelo := StandardMaterial3D.new()
	mat_pelo.albedo_color = pelo
	if not detalle:
		# ===== Nivel sencillo (multitud): piezas fundidas y 6
		# mallas por persona, pero ya no clones (E5): talla y
		# complexión propias, pelo por estilos fundido en la
		# misma malla de la cabeza y falda para quien la lleva.
		# Todo cuelga de «cuerpo_s», recolocado para que la
		# suela quede exactamente donde siempre. =====
		var ts := float(opc.get("talla", 1.0))
		var cx := float(opc.get("complexion", 1.0))
		var cuerpo_s := Node3D.new()
		cuerpo_s.scale = Vector3(cx, ts, cx)
		cuerpo_s.position.y = 0.925 * (ts - 1.0)
		p.add_child(cuerpo_s)
		var con_falda := femenino and bool(opc.get("falda", false))
		if con_falda:
			cuerpo_s.add_child(_fundida([
				[Vector3(0, 0.30, 0), Vector3(0.38, 0.54, 0.215), camisa],
				[Vector3(0, -0.02, 0), Vector3(0.46, 0.34, 0.30), pantalon],
				[Vector3(0, 0.65, 0), Vector3(0.08, 0.10, 0.08), piel],
			]))
		else:
			cuerpo_s.add_child(_fundida([
				[Vector3(0, 0.30, 0), Vector3(0.38, 0.56, 0.215), camisa],
				[Vector3(0, 0.0, 0), Vector3(0.35, 0.16, 0.20), pantalon],
				[Vector3(0, 0.65, 0), Vector3(0.08, 0.10, 0.08), piel],
			]))
		var pivote_cabeza_s := Node3D.new()
		pivote_cabeza_s.position = Vector3(0, 0.75, 0)
		var hv := PackedVector3Array()
		var hn := PackedVector3Array()
		var hc := PackedColorArray()
		_bola_en(hv, hn, hc, Vector3.ZERO, 0.115, piel, 3.7)
		var estilo_s := String(opc.get("pelo_estilo", "corto"))
		if estilo_s != "calvo":
			_caja_en(hv, hn, hc, Vector3(0, 0.095, 0), Vector3(0.225, 0.07, 0.225), pelo, 0.0)
		if estilo_s == "melena" or estilo_s == "coleta":
			_caja_en(hv, hn, hc, Vector3(0, -0.01, -0.098), Vector3(0.21, 0.30, 0.05), pelo, 0.0)
			_caja_en(hv, hn, hc, Vector3(-0.104, 0.0, 0), Vector3(0.04, 0.26, 0.19), pelo, 0.0)
			_caja_en(hv, hn, hc, Vector3(0.104, 0.0, 0), Vector3(0.04, 0.26, 0.19), pelo, 0.0)
		if estilo_s == "coleta":
			_caja_en(hv, hn, hc, Vector3(0, -0.08, -0.145), Vector3(0.06, 0.26, 0.06), pelo, 0.0)
		if estilo_s == "mono":
			_bola_en(hv, hn, hc, Vector3(0, 0.105, -0.095), 0.042, pelo, 3.7)
		pivote_cabeza_s.add_child(_malla_de(hv, hn, hc, Color.WHITE))
		cuerpo_s.add_child(pivote_cabeza_s)
		var bi_s: Node3D = null
		var bd_s: Node3D = null
		var pi_s: Node3D = null
		var pd_s: Node3D = null
		for lado in [-1.0, 1.0]:
			var hombro := Node3D.new()
			hombro.position = Vector3(0.235 * lado, 0.52, 0)
			hombro.add_child(_fundida([
				[Vector3(0, -0.26, 0), Vector3(0.088, 0.56, 0.088), camisa],
				[Vector3(0, -0.58, 0), Vector3(0.082, 0.09, 0.082), piel],
			]))
			cuerpo_s.add_child(hombro)
			if lado < 0.0:
				bi_s = hombro
			else:
				bd_s = hombro
		for lado in [-1.0, 1.0]:
			var cadera := Node3D.new()
			cadera.position = Vector3(0.095 * lado, -0.02, 0)
			if con_falda:
				# Con falda, las piernas son piel: muslo y
				# pantorrilla en la misma malla fundida.
				cadera.add_child(_fundida([
					[Vector3(0, -0.20, 0), Vector3(0.125, 0.38, 0.125), piel],
					[Vector3(0, -0.60, 0), Vector3(0.105, 0.40, 0.105), piel],
					[Vector3(0, -0.86, 0.05), Vector3(0.125, 0.09, 0.25), Color(0.12, 0.10, 0.09)],
				]))
			else:
				cadera.add_child(_fundida([
					[Vector3(0, -0.42, 0), Vector3(0.125, 0.80, 0.125), pantalon],
					[Vector3(0, -0.86, 0.05), Vector3(0.125, 0.09, 0.25), Color(0.12, 0.10, 0.09)],
				]))
			cuerpo_s.add_child(cadera)
			if lado < 0.0:
				pi_s = cadera
			else:
				pd_s = cadera
		return {"raiz": p, "bi": bi_s, "bd": bd_s, "pi": pi_s, "pd": pd_s, "cabeza": pivote_cabeza_s, "mat_camisa": mat_camisa, "mat_pelo": mat_pelo, "estampado": null, "ci": null, "cd": null, "ri": null, "rd": null, "ojo_i": null, "ojo_d": null, "boca": null}
	# ===== Nivel protagonista (E1+E2): proporciones por talla,
	# torso en dos piezas, brazos con codo y piernas con rodilla,
	# cara completa siempre, pelo por estilos e identidad por
	# personaje (gafas, gorra, barba, bigote, bastón, falda).
	# Todo cuelga de «cuerpo», desplazado para que la suela quede
	# exactamente donde siempre (los llamantes no cambian). =====
	var t := float(opc.get("talla", 1.0))
	var cuerpo := Node3D.new()
	var suelo := 0.065 + 0.855 * t
	cuerpo.position.y = suelo - 0.925
	p.add_child(cuerpo)
	var ancho_torso := 0.385 if femenino else 0.42
	var prof := 0.235
	# Pelvis (pantalón) y pecho (camisa): el torso ya no es un bloque.
	cuerpo.add_child(_pieza(Vector3(ancho_torso - 0.05, 0.18 * t, prof - 0.02), Vector3(0, 0.03 * t, 0), pantalon, mat_pantalon))
	cuerpo.add_child(_pieza(Vector3(ancho_torso, 0.42 * t, prof), Vector3(0, 0.33 * t, 0), camisa, mat_camisa))
	var hombro_t := Vector3(0.11, 0.11, 0.215) if femenino else Vector3(0.12, 0.115, 0.225)
	var hombro_x := 0.21 if femenino else 0.225
	cuerpo.add_child(_pieza(hombro_t, Vector3(-hombro_x, 0.50 * t, 0), camisa, mat_camisa))
	cuerpo.add_child(_pieza(hombro_t, Vector3(hombro_x, 0.50 * t, 0), camisa, mat_camisa))
	cuerpo.add_child(_pieza(Vector3(0.095, 0.13 * t, 0.095), Vector3(0, 0.615 * t, 0), piel))
	# ---- Ropa en piezas (E3): lo que viste a cada uno ----
	if bool(opc.get("mono_trabajo", false)):
		# El mono de trabajo: peto y tirantes del color del
		# pantalón sobre la camisa, con su bolsillo en el pecho.
		cuerpo.add_child(_pieza(Vector3(ancho_torso - 0.14, 0.30 * t, 0.024), Vector3(0, 0.26 * t, prof * 0.5 + 0.004), pantalon, mat_pantalon))
		cuerpo.add_child(_pieza(Vector3(0.075, 0.17 * t, 0.024), Vector3(-0.115, 0.455 * t, prof * 0.5 + 0.004), pantalon, mat_pantalon))
		cuerpo.add_child(_pieza(Vector3(0.075, 0.17 * t, 0.024), Vector3(0.115, 0.455 * t, prof * 0.5 + 0.004), pantalon, mat_pantalon))
		cuerpo.add_child(_pieza(Vector3(0.13, 0.10 * t, 0.026), Vector3(0, 0.30 * t, prof * 0.5 + 0.005), camisa, mat_camisa))
	if bool(opc.get("reflectante", false)):
		# Las bandas plateadas del uniforme de trabajo.
		var col_refl := Color(0.83, 0.85, 0.87)
		cuerpo.add_child(_pieza(Vector3(ancho_torso + 0.014, 0.05, prof + 0.014), Vector3(0, 0.22 * t, 0), col_refl))
		cuerpo.add_child(_pieza(Vector3(ancho_torso + 0.014, 0.05, prof + 0.014), Vector3(0, 0.40 * t, 0), col_refl))
	var col_chaqueta := Color(opc.get("chaqueta", Color(0, 0, 0, 0)))
	if col_chaqueta.a > 0.0:
		# Chaqueta abierta: dos delanteros y la espalda sobre
		# la camisa (las mangas van en los brazos).
		cuerpo.add_child(_pieza(Vector3(0.125, 0.42 * t, 0.024), Vector3(-0.128, 0.33 * t, prof * 0.5 + 0.004), col_chaqueta))
		cuerpo.add_child(_pieza(Vector3(0.125, 0.42 * t, 0.024), Vector3(0.128, 0.33 * t, prof * 0.5 + 0.004), col_chaqueta))
		cuerpo.add_child(_pieza(Vector3(ancho_torso, 0.42 * t, 0.024), Vector3(0, 0.33 * t, -prof * 0.5 - 0.004), col_chaqueta))
	if bool(opc.get("falda", false)):
		# Falda sobre las caderas; las piernas salen por debajo.
		cuerpo.add_child(_pieza(Vector3(ancho_torso + 0.10, 0.36 * t, prof + 0.12), Vector3(0, -0.06 * t, 0), pantalon, mat_pantalon))
	var estampado: Node3D = null
	if bool(opc.get("estampado", false)):
		# Solo el jugador: el billete en el pecho y la g de Glera
		# en la espalda (pedido de Jon con el logo).
		estampado = Node3D.new()
		var billete := _pieza(Vector3(0.30, 0.20, 0.012), Vector3(0, 0.30 * t, 0.121), Color(0.38, 0.56, 0.36))
		estampado.add_child(billete)
		estampado.add_child(_pieza(Vector3(0.10, 0.13, 0.014), Vector3(0, 0.30 * t, 0.123), Color(0.78, 0.84, 0.68)))
		estampado.add_child(_pieza(Vector3(0.26, 0.03, 0.014), Vector3(0, 0.215 * t, 0.123), Color(0.30, 0.46, 0.30)))
		cuerpo.add_child(estampado)
		var tex_g := load("res://glera_g.png") as Texture2D
		if tex_g != null:
			var mat_g := StandardMaterial3D.new()
			mat_g.albedo_texture = tex_g
			mat_g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var quad_g := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.193, 0.46)
			qm.material = mat_g
			quad_g.mesh = qm
			quad_g.position = Vector3(0, 0.29 * t, -0.1215)
			quad_g.rotation.y = PI
			cuerpo.add_child(quad_g)
	# ---- Cabeza con cara completa ----
	var pivote_cabeza := Node3D.new()
	pivote_cabeza.position = Vector3(0, 0.75 * t, 0)
	cuerpo.add_child(pivote_cabeza)
	var cabeza := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.115
	esfera.height = 0.23
	cabeza.mesh = esfera
	var mat_piel := StandardMaterial3D.new()
	mat_piel.albedo_color = piel
	esfera.material = mat_piel
	pivote_cabeza.add_child(cabeza)
	pivote_cabeza.add_child(_pieza(Vector3(0.034, 0.058, 0.034), Vector3(0, -0.008, 0.115), piel))
	pivote_cabeza.add_child(_pieza(Vector3(0.024, 0.055, 0.04), Vector3(-0.117, -0.008, 0), piel))
	pivote_cabeza.add_child(_pieza(Vector3(0.024, 0.055, 0.04), Vector3(0.117, -0.008, 0), piel))
	pivote_cabeza.add_child(_pieza(Vector3(0.058, 0.014, 0.010), Vector3(-0.043, 0.058, 0.105), pelo, mat_pelo))
	pivote_cabeza.add_child(_pieza(Vector3(0.058, 0.014, 0.010), Vector3(0.043, 0.058, 0.105), pelo, mat_pelo))
	var ojo_i := _pieza(Vector3(0.032, 0.040, 0.010), Vector3(-0.042, 0.018, 0.107), Color(0.10, 0.08, 0.07))
	var ojo_d := _pieza(Vector3(0.032, 0.040, 0.010), Vector3(0.042, 0.018, 0.107), Color(0.10, 0.08, 0.07))
	pivote_cabeza.add_child(ojo_i)
	pivote_cabeza.add_child(ojo_d)
	var boca := _pieza(Vector3(0.042, 0.012, 0.010), Vector3(0, -0.044, 0.108), Color(0.72, 0.38, 0.38))
	pivote_cabeza.add_child(boca)
	# ---- Pelo por estilos ----
	var estilo := String(opc.get("pelo_estilo", "coleta" if femenino else "corto"))
	var base_cabeza := _pieza(Vector3(0.225, 0.07, 0.225), Vector3(0, 0.095, 0), pelo, mat_pelo)
	pivote_cabeza.add_child(base_cabeza)
	if estilo != "calvo" and estilo != "gorra":
		pivote_cabeza.add_child(_pieza(Vector3(0.215, 0.06, 0.20), Vector3(0, 0.135, 0.008), pelo, mat_pelo))
		pivote_cabeza.add_child(_pieza(Vector3(0.215, 0.055, 0.045), Vector3(0, 0.108, 0.10), pelo, mat_pelo))
	if estilo == "corto" or estilo == "mono" or estilo == "calvo" or estilo == "gorra":
		pivote_cabeza.add_child(_pieza(Vector3(0.035, 0.10, 0.185), Vector3(-0.107, 0.035, -0.008), pelo, mat_pelo))
		pivote_cabeza.add_child(_pieza(Vector3(0.035, 0.10, 0.185), Vector3(0.107, 0.035, -0.008), pelo, mat_pelo))
		pivote_cabeza.add_child(_pieza(Vector3(0.215, 0.13, 0.045), Vector3(0, 0.03, -0.105), pelo, mat_pelo))
	if estilo == "melena" or estilo == "coleta":
		pivote_cabeza.add_child(_pieza(Vector3(0.035, 0.20, 0.185), Vector3(-0.107, -0.02, -0.008), pelo, mat_pelo))
		pivote_cabeza.add_child(_pieza(Vector3(0.035, 0.20, 0.185), Vector3(0.107, -0.02, -0.008), pelo, mat_pelo))
		pivote_cabeza.add_child(_pieza(Vector3(0.215, 0.23, 0.045), Vector3(0, -0.02, -0.105), pelo, mat_pelo))
	if estilo == "coleta":
		pivote_cabeza.add_child(_pieza(Vector3(0.075, 0.075, 0.075), Vector3(0, 0.075, -0.14), pelo, mat_pelo))
		var coleta := _pieza(Vector3(0.065, 0.28, 0.065), Vector3(0, -0.09, -0.165), pelo, mat_pelo)
		coleta.rotation.x = -0.15
		pivote_cabeza.add_child(coleta)
	if estilo == "mono":
		pivote_cabeza.add_child(_pieza(Vector3(0.085, 0.085, 0.085), Vector3(0, 0.105, -0.128), pelo, mat_pelo))
	if estilo == "gorra":
		var col_gorra := Color(opc.get("gorra_color", Color(0.36, 0.39, 0.44)))
		pivote_cabeza.add_child(_pieza(Vector3(0.235, 0.06, 0.235), Vector3(0, 0.128, 0), col_gorra))
		pivote_cabeza.add_child(_pieza(Vector3(0.155, 0.024, 0.095), Vector3(0, 0.105, 0.148), col_gorra))
	if bool(opc.get("barba", false)):
		pivote_cabeza.add_child(_pieza(Vector3(0.20, 0.105, 0.115), Vector3(0, -0.078, 0.045), pelo, mat_pelo))
	if bool(opc.get("barba", false)) or bool(opc.get("bigote", false)):
		pivote_cabeza.add_child(_pieza(Vector3(0.095, 0.024, 0.022), Vector3(0, -0.030, 0.107), pelo, mat_pelo))
	if bool(opc.get("gafas", false)):
		var col_mont := Color(0.08, 0.08, 0.09)
		for lado_g in [-1.0, 1.0]:
			pivote_cabeza.add_child(_pieza(Vector3(0.072, 0.058, 0.008), Vector3(0.043 * lado_g, 0.020, 0.108), col_mont))
			pivote_cabeza.add_child(_pieza(Vector3(0.052, 0.038, 0.010), Vector3(0.043 * lado_g, 0.020, 0.109), Color(0.78, 0.86, 0.90)))
			pivote_cabeza.add_child(_pieza(Vector3(0.010, 0.010, 0.11), Vector3(0.112 * lado_g, 0.026, 0.054), col_mont))
		pivote_cabeza.add_child(_pieza(Vector3(0.024, 0.010, 0.008), Vector3(0, 0.027, 0.108), col_mont))
	# ---- Brazos con codo ----
	var bi: Node3D = null
	var bd: Node3D = null
	var ci: Node3D = null
	var cd: Node3D = null
	for lado in [-1.0, 1.0]:
		var hombro := Node3D.new()
		hombro.position = Vector3(((0.245 if femenino else 0.26)) * lado, 0.52 * t, 0)
		if col_chaqueta.a > 0.0:
			hombro.add_child(_pieza(Vector3(0.098, 0.27 * t, 0.098), Vector3(0, -0.135 * t, 0), col_chaqueta))
		else:
			hombro.add_child(_pieza(Vector3(0.098, 0.27 * t, 0.098), Vector3(0, -0.135 * t, 0), camisa, mat_camisa))
		var codo := Node3D.new()
		codo.position = Vector3(0, -0.27 * t, 0)
		codo.add_child(_pieza(Vector3(0.082, 0.25 * t, 0.082), Vector3(0, -0.125 * t, 0), piel))
		codo.add_child(_pieza(Vector3(0.082, 0.09, 0.082), Vector3(0, -0.29 * t, 0), piel))
		hombro.add_child(codo)
		cuerpo.add_child(hombro)
		if lado < 0.0:
			bi = hombro
			ci = codo
		else:
			bd = hombro
			cd = codo
	if bool(opc.get("baston", false)) and bd != null:
		# El bastón de Elías, colgando de la mano derecha hasta el suelo.
		var baston := _pieza(Vector3(0.035, 0.95 * t, 0.035), Vector3(0, -0.70 * t, 0.03), Color(0.35, 0.25, 0.16))
		bd.add_child(baston)
		bd.add_child(_pieza(Vector3(0.045, 0.045, 0.10), Vector3(0, -0.235 * t, 0.03), Color(0.25, 0.17, 0.10)))
	# ---- Piernas con rodilla ----
	var pi: Node3D = null
	var pd: Node3D = null
	var ri: Node3D = null
	var rd: Node3D = null
	var mat_pierna: Material = mat_pantalon
	var col_pierna := pantalon
	if bool(opc.get("falda", false)):
		mat_pierna = null
		col_pierna = piel
	for lado in [-1.0, 1.0]:
		var cadera := Node3D.new()
		cadera.position = Vector3(0.095 * lado, -0.02, 0)
		cadera.add_child(_pieza(Vector3(0.125, 0.44 * t, 0.125), Vector3(0, -0.22 * t, 0), pantalon, mat_pantalon))
		var rodilla := Node3D.new()
		rodilla.position = Vector3(0, -0.44 * t, 0)
		rodilla.add_child(_pieza(Vector3(0.105, 0.38 * t, 0.105), Vector3(0, -0.19 * t, 0), col_pierna, mat_pierna))
		rodilla.add_child(_pieza(Vector3(0.125, 0.09, 0.25), Vector3(0, -0.415 * t, 0.05), Color(0.12, 0.10, 0.09)))
		cadera.add_child(rodilla)
		cuerpo.add_child(cadera)
		if lado < 0.0:
			pi = cadera
			ri = rodilla
		else:
			pd = cadera
			rd = rodilla
	if bool(opc.get("reflectante", false)):
		# Y las bandas de las perneras, a juego con las del torso.
		for lado_r in [-1.0, 1.0]:
			cuerpo.add_child(_pieza(Vector3(0.14, 0.045, 0.14), Vector3(0.095 * lado_r, -0.26, 0), Color(0.83, 0.85, 0.87)))
	return {"raiz": p, "bi": bi, "bd": bd, "pi": pi, "pd": pd, "cabeza": pivote_cabeza, "mat_camisa": mat_camisa, "mat_pelo": mat_pelo, "estampado": estampado, "ci": ci, "cd": cd, "ri": ri, "rd": rd, "ojo_i": ojo_i, "ojo_d": ojo_d, "boca": boca}

const CAMISETAS := [Color(0.92, 0.91, 0.89), Color(0.25, 0.38, 0.52), Color(0.62, 0.35, 0.30), Color(0.32, 0.47, 0.36), Color(0.78, 0.62, 0.32), Color(0.25, 0.25, 0.28), Color(0.68, 0.50, 0.52), Color(0.45, 0.38, 0.50)]
const PELOS := [Color(0.30, 0.20, 0.12), Color(0.10, 0.08, 0.06), Color(0.55, 0.40, 0.25), Color(0.75, 0.72, 0.68), Color(0.65, 0.25, 0.10), Color(0.87, 0.71, 0.36)]

func _cambiar_personaje() -> void:
	_personaje = 1 - _personaje
	_pelo_idx = 5 if _personaje == 1 else 0
	var pos := _jugador.position
	var rot := _jugador.rotation.y
	_jugador.queue_free()
	_jugador = _crear_personaje()
	add_child(_jugador)
	_jugador.position = pos
	_jugador.rotation.y = rot
	_refrescar_pan()
	if _btn_personaje_tel != null:
		_btn_personaje_tel.text = "Personaje: chica" if _personaje == 1 else "Personaje: chico"
	_guardar()

func _crear_personaje() -> Node3D:
	var opc_j: Dictionary = {"estampado": true, "talla": 1.0, "pelo_estilo": "corto", "barba": true, "piel": Color(0.90, 0.70, 0.56)}
	if _personaje == 1:
		opc_j = {"estampado": true, "talla": 0.97, "pelo_estilo": "coleta", "piel": Color(0.93, 0.74, 0.60)}
	var d := _hacer_persona(CAMISETAS[_camisa_idx % CAMISETAS.size()], Color(0.22, 0.23, 0.30), PELOS[_pelo_idx % PELOS.size()], true, _personaje == 1, opc_j)
	_estampado_j = d["estampado"]
	if _estampado_j != null:
		_estampado_j.visible = (_camisa_idx % CAMISETAS.size()) == 0
	_mat_camisa_j = d["mat_camisa"]
	_mat_pelo_j = d["mat_pelo"]
	_brazo_i = d["bi"]
	_cabeza_j = d["cabeza"]
	_brazo_d = d["bd"]
	_pierna_i = d["pi"]
	_pierna_d = d["pd"]
	_codo_i = d["ci"]
	_codo_d = d["cd"]
	_rodilla_i = d["ri"]
	_rodilla_d = d["rd"]
	_registrar_cara(d, "Tú")
	return d["raiz"]

func _balanceo_extra(d: Dictionary, fase: float) -> void:
	# Rodillas y codos del nivel protagonista durante el paso; en
	# el nivel sencillo no hay esas piezas y no hace nada.
	if d.get("ri") == null:
		return
	(d["ri"] as Node3D).rotation.x = maxf(0.0, sin(fase + 2.2)) * 0.5
	(d["rd"] as Node3D).rotation.x = maxf(0.0, -sin(fase + 2.2)) * 0.5
	(d["ci"] as Node3D).rotation.x = -0.28 + (d["bi"] as Node3D).rotation.x * 0.3
	(d["cd"] as Node3D).rotation.x = -0.28 + (d["bd"] as Node3D).rotation.x * 0.3

func _pose_reposo(d: Dictionary, delta: float) -> void:
	# Al parar, las piezas vuelven a su sitio poco a poco (las
	# caderas y los hombros antes se quedaban a mitad de paso).
	var k := clampf(delta * 8.0, 0.0, 1.0)
	for clave in ["pi", "pd", "bi", "bd", "ri", "rd", "ci", "cd"]:
		var piv: Node3D = d.get(clave)
		if piv != null:
			piv.rotation.x = lerpf(piv.rotation.x, 0.0, k)

func _registrar_cara(d: Dictionary, nombre: String) -> void:
	# Sustituye la cara anterior del mismo nombre (el jugador se
	# recrea al cambiar de personaje) y registra ojos y boca.
	if d.get("ojo_i") == null:
		return
	_caras = _caras.filter(func(c: Dictionary) -> bool: return String(c["nombre"]) != nombre)
	_caras.append({"nombre": nombre, "oi": d["ojo_i"], "od": d["ojo_d"], "boca": d["boca"], "prox": _tiempo + randf_range(1.0, 4.0), "cierra": -1.0})

func _actualizar_caras() -> void:
	if _caras.is_empty():
		return
	var hablante := ""
	if _dlg_abierto and _dlg_i < _dlg_lineas.size():
		hablante = String(_dlg_lineas[_dlg_i][0])
	for c in _caras:
		if _tiempo >= float(c["prox"]):
			c["prox"] = _tiempo + randf_range(2.2, 5.0)
			c["cierra"] = _tiempo + 0.12
		var esc_o := 0.12 if _tiempo < float(c["cierra"]) else 1.0
		(c["oi"] as Node3D).scale.y = esc_o
		(c["od"] as Node3D).scale.y = esc_o
		var boca: Node3D = c["boca"]
		if boca != null:
			if hablante != "" and String(c["nombre"]) == hablante:
				boca.scale.y = 1.0 + sin(_tiempo * 22.0) * 0.9
				boca.scale.x = 1.0 + sin(_tiempo * 17.0) * 0.15
			else:
				boca.scale.y = 1.0
				boca.scale.x = 1.0

func _animar_paso(delta: float, andando: bool) -> void:
	if _pierna_i == null:
		return
	if andando:
		_fase_paso += delta * (15.0 if _corriendo else 9.0)
		var a := sin(_fase_paso) * (0.7 if _corriendo else 0.55)
		_pierna_i.rotation.x = a
		_pierna_d.rotation.x = -a
		_brazo_i.rotation.x = -a * 0.7
		_brazo_d.rotation.x = a * 0.7
		# Con algo en la mano, ese brazo no se balancea: el del
		# pan va medio doblado, el de la bolsa cuelga con su
		# peso y el del balón lo sujeta bajo el brazo.
		if _pan_en_mano:
			_brazo_d.rotation.x = -0.55 + sin(_fase_paso + PI) * 0.15
		elif _bolsa_en_mano:
			_brazo_d.rotation.x = -0.15 + sin(_fase_paso + PI) * 0.12
		if _balon_en_mano:
			_brazo_i.rotation.x = -0.22 + sin(_fase_paso) * 0.08
		if _rodilla_i != null:
			# La rodilla flexiona cuando su pierna avanza (talón
			# que se levanta por detrás) y el codo mantiene una
			# flexión natural con un punto de contrafase.
			_rodilla_i.rotation.x = maxf(0.0, sin(_fase_paso + 2.2)) * (0.62 if _corriendo else 0.5)
			_rodilla_d.rotation.x = maxf(0.0, -sin(_fase_paso + 2.2)) * (0.62 if _corriendo else 0.5)
			_codo_i.rotation.x = -0.28 + _brazo_i.rotation.x * 0.3
			_codo_d.rotation.x = -0.28 + _brazo_d.rotation.x * 0.3
		if _cabeza_j != null:
			_cabeza_j.rotation.y = sin(_fase_paso * 0.5) * 0.12
	else:
		var pivs: Array = [_pierna_i, _pierna_d, _brazo_i, _brazo_d]
		if _rodilla_i != null:
			pivs += [_rodilla_i, _rodilla_d, _codo_i, _codo_d]
		for piv in pivs:
			piv.rotation.x = lerpf(piv.rotation.x, 0.0, clampf(delta * 8.0, 0.0, 1.0))
		if _cabeza_j != null and not _sentado:
			_cabeza_j.rotation.y = sin(_tiempo * 0.35) * 0.4
			_cabeza_j.rotation.x = sin(_tiempo * 0.9) * 0.04

func _cargar_portales() -> Dictionary:
	# Los portales se cargan ANTES que cualquier baldosa: la primera
	# baldosa (la de casa) se construye al arrancar, y si _portales
	# aún está vacío sus edificios se quedan sin puertas ni números
	# (pasó de verdad: la baldosa central no tenía ni una puerta).
	var datos_p = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/portales.json"))
	if datos_p == null:
		return {}
	_portales = datos_p["portales"]
	# Portales encerrados entre edificios (sin llegada andando posible):
	# fuera de encargos, repartos e historia. Lista generada por
	# pipeline/portales_no.py (inundación desde calles y bordes).
	var datos_no = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/portales_no.json"))
	if datos_no != null:
		var no_set := {}
		for ii in datos_no:
			no_set[int(ii)] = true
		var filtrados: Array = []
		for ip2 in _portales.size():
			if not no_set.has(ip2):
				filtrados.append(_portales[ip2])
		print("PORTALES_NO excluidos=", _portales.size() - filtrados.size(), " de ", _portales.size())
		_portales = filtrados
	return datos_p

func _crear_mision() -> void:
	var datos_p: Dictionary = {}
	if _portales.is_empty():
		datos_p = _cargar_portales()
	else:
		datos_p = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/portales.json"))
	if datos_p == null or datos_p.is_empty():
		return
	var pa: Dictionary = {}
	var pb: Dictionary = {}
	for p in datos_p["portales"]:
		if String(p["calle"]).contains("VILLANUEVA") and String(p["numero"]) == "1":
			pa = p
		if String(p["calle"]) == "CL PORTALES" and String(p["numero"]) == "14":
			pb = p
	if pa.is_empty() or pb.is_empty():
		push_warning("Portales de la misión no encontrados")
		return
	_origen = Vector3(float(pa["x"]), 0, float(pa["z"]))
	_destino = Vector3(float(pb["x"]), 0, float(pb["z"]))
	_origen.y = _altura(_origen.x, _origen.z)
	_destino.y = _altura(_destino.x, _destino.z)
	_origen_libre = _punto_libre(_origen, 0.4)
	_destino_libre = _punto_libre(_destino, 0.4)
	# La cámara arranca mirando hacia el destino (a lo largo de la calle)
	_dir_jugador = atan2(_destino_libre.x - _origen_libre.x, _destino_libre.z - _origen_libre.z)
	add_child(_marcador(_origen_libre, Color(0.2, 0.95, 0.3), false, 0.45, true))
	_pilar_destino = _marcador(_destino_libre, Color(1.0, 0.55, 0.1), true, 0.85)
	_pilar_destino.visible = false
	add_child(_pilar_destino)
	_jugador = _crear_personaje()
	_jugador.position = _origen_libre + Vector3(0, 0.95, 0)
	add_child(_jugador)
	_crear_coche()
	# El jugador empieza junto al coche, en la calzada: en su portal la
	# cámara no tiene sitio (la pared queda a ~1 m de su espalda).
	var junto_coche := _punto_libre(_coche.position + Vector3(2.5, 0, 0), 0.4)
	_jugador.position = junto_coche
	_jugador.position.y = _altura(junto_coche.x, junto_coche.z) + 0.95
	# Cámara inicial: junto al coche (en la calzada, sitio despejado),
	# mirando al jugador; la cámara seguidora toma el relevo al instante.
	_cam.position = _coche.position + Vector3(6, 5, 6)
	_cam.look_at(_jugador.position + Vector3(0, 1.5, 0), Vector3.UP)
	_auto = OS.get_cmdline_user_args().has("prueba") or OS.get_cmdline_user_args().has("probar_encargante")
	_refrescar_rotulos()
	_crear_lugares_coches()
	_crear_interiores()
	_crear_historia()
	print("MISION_CREADA de Miguel Villanueva 1 a Calle Portales 14, distancia=",
		roundf(_origen.distance_to(_destino)), " m")

func _modelo_bici(color: Color) -> Node3D:
	# La bicicleta: dos ruedas, cuadro de tubos, manillar y sillin.
	var bici := Node3D.new()
	var mat_c := StandardMaterial3D.new()
	mat_c.albedo_color = color
	var mat_n := StandardMaterial3D.new()
	mat_n.albedo_color = Color(0.06, 0.06, 0.07)
	var mat_g := StandardMaterial3D.new()
	mat_g.albedo_color = Color(0.45, 0.46, 0.50)
	for sz in [-0.55, 0.55]:
		var rueda := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.34
		cil.bottom_radius = 0.34
		cil.height = 0.05
		rueda.mesh = cil
		cil.material = mat_n
		rueda.rotation_degrees = Vector3(0, 0, 90)
		rueda.position = Vector3(0, 0.34, sz)
		bici.add_child(rueda)
		var buje := MeshInstance3D.new()
		var bj := CylinderMesh.new()
		bj.top_radius = 0.05
		bj.bottom_radius = 0.05
		bj.height = 0.09
		buje.mesh = bj
		bj.material = mat_g
		buje.rotation_degrees = Vector3(0, 0, 90)
		buje.position = Vector3(0, 0.34, sz)
		bici.add_child(buje)
	var tubos := [
		[Vector3(0, 0.70, 0.03), Vector3(0.05, 0.05, 0.72), 0.10],
		[Vector3(0, 0.52, 0.20), Vector3(0.05, 0.05, 0.66), 0.72],
		[Vector3(0, 0.55, -0.30), Vector3(0.05, 0.55, 0.05), -0.30],
		[Vector3(0, 0.52, 0.48), Vector3(0.05, 0.60, 0.05), -0.28],
		[Vector3(0, 0.42, -0.42), Vector3(0.04, 0.04, 0.42), 0.45],
	]
	for t in tubos:
		var tubo := MeshInstance3D.new()
		var tj := BoxMesh.new()
		tj.size = t[1]
		tubo.mesh = tj
		tubo.position = t[0]
		tubo.rotation.x = t[2]
		tj.material = mat_c
		bici.add_child(tubo)
	var man := MeshInstance3D.new()
	var mj := BoxMesh.new()
	mj.size = Vector3(0.46, 0.05, 0.05)
	man.mesh = mj
	man.position = Vector3(0, 0.88, 0.53)
	mj.material = mat_n
	bici.add_child(man)
	var sil := MeshInstance3D.new()
	var sj := BoxMesh.new()
	sj.size = Vector3(0.17, 0.06, 0.30)
	sil.mesh = sj
	sil.position = Vector3(0, 0.84, -0.33)
	sj.material = mat_n
	bici.add_child(sil)
	return bici

func _modelo_mtb(color: Color) -> Node3D:
	# La de montaña: ruedas anchas de tacos, cuadro grueso con tubo
	# superior inclinado, horquilla de suspensión y manillar recto.
	var bici := Node3D.new()
	var mat_c := StandardMaterial3D.new()
	mat_c.albedo_color = color
	var mat_n := StandardMaterial3D.new()
	mat_n.albedo_color = Color(0.08, 0.08, 0.09)
	var mat_g := StandardMaterial3D.new()
	mat_g.albedo_color = Color(0.45, 0.46, 0.50)
	for sz in [-0.57, 0.57]:
		var rueda := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.36
		cil.bottom_radius = 0.36
		cil.height = 0.10
		rueda.mesh = cil
		cil.material = mat_n
		rueda.rotation_degrees = Vector3(0, 0, 90)
		rueda.position = Vector3(0, 0.36, sz)
		bici.add_child(rueda)
		var buje := MeshInstance3D.new()
		var bj := CylinderMesh.new()
		bj.top_radius = 0.06
		bj.bottom_radius = 0.06
		bj.height = 0.13
		buje.mesh = bj
		bj.material = mat_g
		buje.rotation_degrees = Vector3(0, 0, 90)
		buje.position = Vector3(0, 0.36, sz)
		bici.add_child(buje)
	var tubos := [
		[Vector3(0, 0.66, 0.02), Vector3(0.07, 0.07, 0.74), 0.16],
		[Vector3(0, 0.50, 0.20), Vector3(0.07, 0.07, 0.68), 0.72],
		[Vector3(0, 0.55, -0.30), Vector3(0.07, 0.58, 0.07), -0.30],
		[Vector3(0, 0.52, 0.48), Vector3(0.06, 0.62, 0.06), -0.28],
		[Vector3(0, 0.40, -0.44), Vector3(0.05, 0.05, 0.44), 0.45],
		[Vector3(-0.06, 0.52, 0.52), Vector3(0.05, 0.66, 0.05), -0.28],
		[Vector3(0.06, 0.52, 0.52), Vector3(0.05, 0.66, 0.05), -0.28],
	]
	for t in tubos:
		var tubo := MeshInstance3D.new()
		var tj := BoxMesh.new()
		tj.size = t[1]
		tubo.mesh = tj
		tubo.position = t[0]
		tubo.rotation.x = t[2]
		tj.material = mat_c
		bici.add_child(tubo)
	var man := MeshInstance3D.new()
	var mj := BoxMesh.new()
	mj.size = Vector3(0.58, 0.05, 0.05)
	man.mesh = mj
	man.position = Vector3(0, 0.90, 0.55)
	mj.material = mat_n
	bici.add_child(man)
	var sil := MeshInstance3D.new()
	var sj := BoxMesh.new()
	sj.size = Vector3(0.19, 0.06, 0.30)
	sil.mesh = sj
	sil.position = Vector3(0, 0.86, -0.33)
	sj.material = mat_n
	bici.add_child(sil)
	return bici

func _modelo_coche(color: Color, estilo := "normal", dims := Vector3(1.8, 0.55, 4.2)) -> Node3D:
	if estilo == "bici":
		return _modelo_bici(color)
	if estilo == "mtb":
		return _modelo_mtb(color)
	var coche := Node3D.new()
	var mat_c := StandardMaterial3D.new()
	mat_c.albedo_color = color
	var mat_v := StandardMaterial3D.new()
	mat_v.albedo_color = Color(0.10, 0.12, 0.16)
	var mat_n := StandardMaterial3D.new()
	mat_n.albedo_color = Color(0.05, 0.05, 0.05)
	var mat_g := StandardMaterial3D.new()
	mat_g.albedo_color = Color(0.16, 0.16, 0.18)
	var w := dims.x
	var h := dims.y
	var l := dims.z
	var cuerpo := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = dims
	cuerpo.mesh = caja
	cuerpo.position = Vector3(0, 0.28 + h / 2.0, 0)
	caja.material = mat_c
	coche.add_child(cuerpo)
	var cabina := MeshInstance3D.new()
	var cj := BoxMesh.new()
	match estilo:
		"furgo":
			cj.size = Vector3(w - 0.04, 1.02, l * 0.66)
			cabina.position = Vector3(0, 0.83 + 0.51, -l * 0.14)
			cj.material = mat_c
		"familiar":
			cj.size = Vector3(w - 0.18, 0.50, l * 0.60)
			cabina.position = Vector3(0, 0.28 + h + 0.22, -l * 0.06)
			cj.material = mat_v
		"clasico":
			cj.size = Vector3(w - 0.30, 0.55, l * 0.38)
			cabina.position = Vector3(0, 0.28 + h + 0.24, -l * 0.10)
			cj.material = mat_v
		"deportivo":
			cj.size = Vector3(w - 0.25, 0.36, l * 0.42)
			cabina.position = Vector3(0, 0.28 + h + 0.15, -l * 0.05)
			cj.material = mat_v
		_:
			cj.size = Vector3(w - 0.20, 0.50, l * 0.48)
			cabina.position = Vector3(0, 0.28 + h + 0.22, -0.2)
			cj.material = mat_v
	cabina.mesh = cj
	coche.add_child(cabina)
	if estilo == "furgo":
		var luna := MeshInstance3D.new()
		var lj := BoxMesh.new()
		lj.size = Vector3(w - 0.16, 0.40, 0.06)
		luna.mesh = lj
		luna.position = Vector3(0, 0.98, l * 0.315)
		lj.material = mat_v
		coche.add_child(luna)
	if estilo == "deportivo":
		var aleron := MeshInstance3D.new()
		var aj := BoxMesh.new()
		aj.size = Vector3(w * 0.92, 0.05, 0.30)
		aleron.mesh = aj
		aleron.position = Vector3(0, 1.04, -l / 2.0 + 0.25)
		aj.material = mat_n
		coche.add_child(aleron)
		for sx2 in [-w * 0.30, w * 0.30]:
			var sop := MeshInstance3D.new()
			var sj := BoxMesh.new()
			sj.size = Vector3(0.06, 0.18, 0.06)
			sop.mesh = sj
			sop.position = Vector3(sx2, 0.93, -l / 2.0 + 0.25)
			sj.material = mat_n
			coche.add_child(sop)
	if estilo == "clasico":
		var maletero := MeshInstance3D.new()
		var mj := BoxMesh.new()
		mj.size = Vector3(w - 0.10, 0.20, l * 0.20)
		maletero.mesh = mj
		maletero.position = Vector3(0, 0.28 + h + 0.04, -l * 0.38)
		mj.material = mat_c
		coche.add_child(maletero)
	# Faros, pilotos y parachoques
	var mat_f := StandardMaterial3D.new()
	mat_f.albedo_color = Color(1.0, 0.96, 0.78)
	var mat_p := StandardMaterial3D.new()
	mat_p.albedo_color = Color(0.75, 0.10, 0.10)
	for sx in [-w * 0.31, w * 0.31]:
		var faro := MeshInstance3D.new()
		var fj := BoxMesh.new()
		fj.size = Vector3(0.30, 0.09, 0.05)
		faro.mesh = fj
		faro.position = Vector3(sx, 0.62, l / 2.0 + 0.01)
		fj.material = mat_f
		coche.add_child(faro)
		var piloto := MeshInstance3D.new()
		var pj := BoxMesh.new()
		pj.size = Vector3(0.26, 0.08, 0.05)
		piloto.mesh = pj
		piloto.position = Vector3(sx, 0.64, -l / 2.0 - 0.01)
		pj.material = mat_p
		coche.add_child(piloto)
	for sz in [-1.0, 1.0]:
		var para := MeshInstance3D.new()
		var bj := BoxMesh.new()
		bj.size = Vector3(w + 0.02, 0.13, 0.14)
		para.mesh = bj
		para.position = Vector3(0, 0.34, sz * (l / 2.0 + 0.03))
		bj.material = mat_g
		coche.add_child(para)
	var radio_r := 0.40 if estilo == "furgo" else 0.35
	for sx in [-(w / 2.0 - 0.02), w / 2.0 - 0.02]:
		for sz in [-(l / 2.0 - 0.65), l / 2.0 - 0.65]:
			var rueda := MeshInstance3D.new()
			var cil := CylinderMesh.new()
			cil.top_radius = radio_r
			cil.bottom_radius = radio_r
			cil.height = 0.25
			rueda.mesh = cil
			cil.material = mat_n
			rueda.rotation_degrees = Vector3(0, 0, 90)
			rueda.position = Vector3(sx, radio_r, sz)
			coche.add_child(rueda)
	return coche

func _es_bici() -> bool:
	var inst: Dictionary = _mis_coches[_coche_activo]
	var cat: Dictionary = COCHES[int(inst["id"])]
	return String(cat["estilo"]) in ["bici", "mtb"]

func _probar_gallarza() -> void:
	var pasa := true
	pasa = pasa and _gallarza_verde > 300
	pasa = pasa and _columpios.size() == 2
	pasa = pasa and not _balon_gal.is_empty()
	var en_parque := 0
	for est in _estaticos:
		var rz: Node3D = est["raiz"]
		if rz.position.x > -546.0 and rz.position.x < -426.0 and rz.position.z > 678.0 and rz.position.z < 794.0:
			en_parque += 1
	pasa = pasa and en_parque >= 7
	# El balón se mueve: dos muestras separadas en el tiempo difieren
	var p0: Vector3 = (_balon_gal["nodo"] as Node3D).position
	_mover_peatones(0.6)
	var p1: Vector3 = (_balon_gal["nodo"] as Node3D).position
	pasa = pasa and p0.distance_to(p1) > 0.5
	# El columpio ocupado se balancea (con el reloj en dos
	# instantes distintos: a _tiempo 0 el seno vale 0 y la
	# comprobación antigua fallaba sin que nada estuviera roto)
	var piv0: Node3D = _columpios[0]["pivote"]
	_tiempo = 0.8
	_mover_peatones(0.1)
	var rot_a := absf(piv0.rotation.x)
	_tiempo = 1.6
	_mover_peatones(0.1)
	pasa = pasa and (rot_a > 0.02 or absf(piv0.rotation.x) > 0.02)
	# Montarse en el columpio libre con la E (pedido de Jon):
	# el jugador queda sentado en el asiento y se baja bien.
	_jugador.position = Vector3(-511.2, _altura(-511.2, 716.3) + 0.95, 716.3)
	var libre_ok := not _columpio_libre().is_empty()
	pasa = pasa and libre_ok
	_alternar_columpio()
	var montado_ok := _en_columpio
	pasa = pasa and montado_ok
	_mover_peatones(0.4)
	_actualizar_columpio(0.4)
	var asiento: Vector3 = (_columpios[1]["pivote"] as Node3D).to_global(Vector3(0, -1.40, 0.03))
	var dist_asiento := _jugador.position.distance_to(asiento)
	pasa = pasa and dist_asiento < 0.05
	_bajar_columpio()
	pasa = pasa and not _en_columpio
	print("GALLARZA_PRUEBA_OK pasa=", pasa, " verde=", _gallarza_verde, " en_parque=", en_parque, " libre=", libre_ok, " montado=", montado_ok, " dist_asiento=", dist_asiento)

func _probar_pan() -> void:
	# La barra comprada se ve en la mano (pedido de Jon) y se
	# esconde donde las manos van al volante.
	var pasa := true
	_dinero = 10
	_comprar_pan()
	pasa = pasa and _pan_en_mano and _pan_nodo != null and is_instance_valid(_pan_nodo)
	_en_coche = true
	_refrescar_pan()
	pasa = pasa and _pan_nodo == null
	_en_coche = false
	_refrescar_pan()
	pasa = pasa and _pan_nodo != null and is_instance_valid(_pan_nodo)
	# E4: el balón de Decathlon va bajo el brazo izquierdo y
	# la compra en una bolsa en la mano derecha; el pan de la
	# misión manda sobre la bolsa, y en casa se deja todo
	# menos el pan.
	_dinero = 100
	_comprar_tienda("dec_balon")
	pasa = pasa and _balon_en_mano and _balon_nodo != null and is_instance_valid(_balon_nodo)
	_comprar_tienda("dec_mochila")
	# La bolsa se compra, pero con el pan en la mano espera:
	# el pan de la misión manda en la mano derecha.
	pasa = pasa and _bolsa_en_mano and _bolsa_nodo == null
	_pan_en_mano = false
	_refrescar_pan()
	pasa = pasa and _bolsa_nodo != null and is_instance_valid(_bolsa_nodo) and _pan_nodo == null
	_comprar_pan()
	pasa = pasa and _pan_nodo != null and _bolsa_nodo == null and _balon_nodo != null
	_entrar_interior("piso")
	pasa = pasa and not _bolsa_en_mano and not _balon_en_mano and _balon_nodo == null
	_salir_interior()
	print("PAN_PRUEBA_OK pasa=", pasa, " dinero=", _dinero)

func _probar_mapa() -> void:
	# El plano sirve para moverse (pedido de Jon): se abre el
	# mapa, se clica el punto dorado de un lugar con el MISMO
	# camino de entrada que usa el ratón, y el jugador aparece
	# allí con el mapa cerrado.
	var pasa := true
	var poi: Dictionary = {}
	for p in _pois_mapa:
		if String(p["n"]).contains("Estadio"):
			poi = p
			break
	if poi.is_empty() and not _pois_mapa.is_empty():
		poi = _pois_mapa[0]
	pasa = pasa and not poi.is_empty()
	_abrir_mapa()
	pasa = pasa and _mapa_abierto
	var antes := _jugador.position
	var pos_px: Vector2 = _mapa.call("punto_de_poi", poi)
	# El clic ahora es pulsar y soltar sin arrastrar
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos_px
	_mapa.call("_gui_input", ev)
	ev.pressed = false
	_mapa.call("_gui_input", ev)
	var d := Vector2(_jugador.position.x - float(poi["x"]), _jugador.position.z - float(poi["z"])).length()
	pasa = pasa and not _mapa_abierto and d < 30.0 and _jugador.position.distance_to(antes) > 100.0
	# Zoom con la rueda (pedido de Jon): la escala crece y el
	# clic sobre el punto sigue llevando al mismo lugar
	_abrir_mapa()
	var pr0: Array = _mapa.call("_params")
	var evw := InputEventMouseButton.new()
	evw.button_index = MOUSE_BUTTON_WHEEL_UP
	evw.pressed = true
	evw.position = _mapa.call("punto_de_poi", poi)
	_mapa.call("_gui_input", evw)
	_mapa.call("_gui_input", evw)
	var pr1: Array = _mapa.call("_params")
	# absf: sin frames, la escala base puede salir negativa en
	# headless al reabrir el plano; lo que se prueba es que la
	# rueda la multiplica (×1,44 con dos toques).
	pasa = pasa and absf(float(pr1[0])) > absf(float(pr0[0])) * 1.3
	var pos2: Vector2 = _mapa.call("punto_de_poi", poi)
	var ev2 := InputEventMouseButton.new()
	ev2.button_index = MOUSE_BUTTON_LEFT
	ev2.pressed = true
	ev2.position = pos2
	_mapa.call("_gui_input", ev2)
	ev2.pressed = false
	_mapa.call("_gui_input", ev2)
	var d2 := Vector2(_jugador.position.x - float(poi["x"]), _jugador.position.z - float(poi["z"])).length()
	pasa = pasa and not _mapa_abierto and d2 < 30.0
	# Arrastrar mueve la vista y NO teletransporta. Se fija el
	# zoom y el centro a mano: sin frames de por medio, el
	# tamaño del control al reabrir el plano no es fiable en
	# headless (en el navegador sí hay frames y se asienta).
	_abrir_mapa()
	_mapa.set("_zoom", 2.0)
	_mapa.set("_centro", Vector2.ZERO)
	var centro_antes: Vector2 = _mapa.get("_centro")
	var evp := InputEventMouseButton.new()
	evp.button_index = MOUSE_BUTTON_LEFT
	evp.pressed = true
	evp.position = Vector2(400, 300)
	_mapa.call("_gui_input", evp)
	var evm := InputEventMouseMotion.new()
	evm.relative = Vector2(150, 0)
	evm.position = Vector2(550, 300)
	_mapa.call("_gui_input", evm)
	evp.pressed = false
	evp.position = Vector2(550, 300)
	_mapa.call("_gui_input", evp)
	pasa = pasa and _mapa_abierto and (_mapa.get("_centro") as Vector2) != centro_antes
	_cerrar_mapa()
	print("MAPA_PRUEBA_OK pasa=", pasa, " lugar=", String(poi.get("n", "?")), " dist=", d, " zoom=", snappedf(float(pr1[0]) / float(pr0[0]), 0.01), " d2=", snappedf(d2, 0.1), " centro=", _mapa.get("_centro"))

func _probar_multitud() -> void:
	# E5: la multitud ya no es de clones y el presupuesto de
	# dibujo no cambia: 6 mallas por persona sencilla sea cual
	# sea la variante, la talla vive en el cuerpo interior y
	# la melena funde más pelo en la misma malla de la cabeza
	# que el pelo corto.
	var pasa := true
	var variantes: Array = [
		{"pelo_estilo": "corto"},
		{"pelo_estilo": "calvo"},
		{"pelo_estilo": "melena"},
		{"pelo_estilo": "coleta"},
		{"pelo_estilo": "mono"},
		{"pelo_estilo": "corto", "falda": true},
	]
	var verts_cabeza := {}
	for v in variantes:
		var opc: Dictionary = {"talla": 0.95, "complexion": 1.0}
		opc.merge(v)
		var per := _hacer_persona(Color(0.4, 0.3, 0.3), Color(0.2, 0.2, 0.25), Color(0.15, 0.10, 0.08), false, bool(v.get("falda", false)), opc)
		pasa = pasa and _contar_mallas(per["raiz"]) == 6
		var cabeza: Node = per["cabeza"]
		var malla := (cabeza.get_child(0) as MeshInstance3D).mesh
		verts_cabeza[String(v["pelo_estilo"]) + ("_falda" if bool(v.get("falda", false)) else "")] = (malla.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var per_t := _hacer_persona(Color(0.4, 0.3, 0.3), Color(0.2, 0.2, 0.25), Color(0.15, 0.10, 0.08), false, false, {"talla": 1.05})
	var cuerpo_t: Node3D = per_t["raiz"].get_child(0)
	pasa = pasa and absf(cuerpo_t.scale.y - 1.05) < 0.001
	pasa = pasa and int(verts_cabeza["melena"]) > int(verts_cabeza["corto"]) and int(verts_cabeza["coleta"]) > int(verts_cabeza["corto"])
	print("MULTITUD_OK pasa=", pasa, " verts=", verts_cabeza)

func _probar_coche() -> void:
	# Dos quejas de Jon con el coche: «no acelera con la tecla
	# espacio» y «las teclas derecha/izquierda están al revés».
	# Se prueban con teclas simuladas de verdad, como la bici.
	var pasa := true
	_usar_coche(0)
	_en_coche = true
	_coche.position = Vector3(-500, _altura(-500, 173), 173)
	_coche_dir = 0.0
	_coche.rotation.y = 0.0
	_coche_vel = 0.0
	var pulsar := func(codigo: int, bajar: bool) -> void:
		var ev := InputEventKey.new()
		ev.keycode = codigo
		ev.pressed = bajar
		Input.parse_input_event(ev)
	pulsar.call(KEY_SPACE, true)
	await get_tree().process_frame
	_conducir(0.5)
	var vel_esp := _coche_vel
	pasa = pasa and vel_esp > 0.5
	pulsar.call(KEY_SPACE, false)
	# Yendo hacia +Z (el sur), la derecha del conductor es -X
	# (el oeste): con la D el rumbo tiene que BAJAR, no subir.
	_coche.position = Vector3(-500, _altura(-500, 173), 173)
	_coche_vel = 8.0
	_coche_dir = 0.0
	pulsar.call(KEY_D, true)
	await get_tree().process_frame
	for f in 10:
		_conducir(0.05)
	pulsar.call(KEY_D, false)
	var dir_d := _coche_dir
	pasa = pasa and dir_d < -0.05
	_coche.position = Vector3(-500, _altura(-500, 173), 173)
	_coche_vel = 8.0
	_coche_dir = 0.0
	pulsar.call(KEY_A, true)
	await get_tree().process_frame
	for f in 10:
		_conducir(0.05)
	pulsar.call(KEY_A, false)
	pasa = pasa and _coche_dir > 0.05
	print("COCHE_PRUEBA_OK pasa=", pasa, " vel_espacio=", vel_esp, " dir_D=", dir_d, " dir_A=", _coche_dir)

func _probar_bici() -> void:
	var pasa := true
	_dinero = 1000
	var n0 := _mis_coches.size()
	pasa = pasa and _comprar_coche(12)
	pasa = pasa and _mis_coches.size() == n0 + 1
	_usar_coche(n0)
	pasa = pasa and _es_bici()
	var st := _stats_activo()
	pasa = pasa and float(st["vmax"]) < 10.0
	# El espacio tambien acelera: tecla simulada de verdad
	_coche.position = Vector3(-500, _altura(-500, 173), 173)
	_coche_dir = PI * 0.5
	_coche.rotation.y = _coche_dir
	_coche_vel = 0.0
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	_en_coche = true
	_conducir(0.5)
	pasa = pasa and _coche_vel > 0.5
	var ev2 := InputEventKey.new()
	ev2.keycode = KEY_SPACE
	ev2.pressed = false
	Input.parse_input_event(ev2)
	pasa = pasa and _pill_vel != null and _pill_vel.visible and _hud_vel.text.contains("km/h")
	# Sin marcha atrás en bici: con S pisado frena hasta 0 y de ahí
	# no pasa, por mucho que insistas.
	var ev3 := InputEventKey.new()
	ev3.keycode = KEY_S
	ev3.pressed = true
	Input.parse_input_event(ev3)
	await get_tree().process_frame
	var min_vel := 99.0
	for f_s in 40:
		_conducir(0.1)
		min_vel = minf(min_vel, _coche_vel)
	pasa = pasa and min_vel >= 0.0 and _coche_vel == 0.0
	var ev4 := InputEventKey.new()
	ev4.keycode = KEY_S
	ev4.pressed = false
	Input.parse_input_event(ev4)
	# La de montaña: se compra, cuenta como bici (pedaleando, sin
	# motor) y corre más que la de paseo.
	_dinero = 1000
	var n1 := _mis_coches.size()
	pasa = pasa and _comprar_coche(13)
	pasa = pasa and _mis_coches.size() == n1 + 1
	_usar_coche(n1)
	pasa = pasa and _es_bici()
	var st2 := _stats_activo()
	pasa = pasa and float(st2["vmax"]) > 10.0
	pasa = pasa and _coche != null and _coche.get_child_count() > 5
	print("BICI_PRUEBA_OK pasa=", pasa, " vel=", _coche_vel, " hud=", _hud_vel.text if _hud_vel != null else "?")
	get_tree().quit()

func _stats_activo() -> Dictionary:
	return _stats_de(_mis_coches[_coche_activo])

func _stats_de(inst: Dictionary) -> Dictionary:
	var cat: Dictionary = COCHES[int(inst["id"])]
	var rend := 1.0 - 0.003 * float(inst["danio"])
	return {"vmax": float(cat["vmax"]) * (1.0 + 0.10 * int(inst["motor"])) * rend,
		"acel": float(cat["acel"]) * (1.0 + 0.10 * int(inst["motor"])) * rend,
		"freno": float(cat["freno"]) * (1.0 + 0.15 * int(inst["frenos"])),
		"giro": float(cat["giro"])}

func _comprar_coche(id: int) -> bool:
	var cat: Dictionary = COCHES[id]
	if _dinero < int(cat["precio"]):
		return false
	_dinero -= int(cat["precio"])
	_mis_coches.append({"id": id, "danio": 0, "motor": 0, "frenos": 0})
	_actualizar_hud_dinero()
	_guardar()
	_sonar("cobro")
	print("COCHE_COMPRADO ", cat["n"], " por ", cat["precio"], " €")
	return true

func _usar_coche(i: int) -> void:
	if i == _coche_activo or i < 0 or i >= _mis_coches.size():
		return
	_coche_activo = i
	_reconstruir_coche()
	_guardar()

func _vender_coche(i: int) -> bool:
	if _mis_coches.size() <= 1 or i < 0 or i >= _mis_coches.size():
		return false
	var cat: Dictionary = COCHES[int(_mis_coches[i]["id"])]
	_dinero += int(int(cat["precio"]) * 0.7)
	_mis_coches.remove_at(i)
	if _coche_activo >= _mis_coches.size():
		_coche_activo = 0
	_reconstruir_coche()
	_actualizar_hud_dinero()
	_guardar()
	print("COCHE_VENDIDO ", cat["n"])
	return true

func _reparar_coche() -> bool:
	var inst: Dictionary = _mis_coches[_coche_activo]
	var coste := int(inst["danio"]) * 6
	if coste <= 0 or _dinero < coste:
		return false
	_dinero -= coste
	inst["danio"] = 0
	_actualizar_hud_dinero()
	_guardar()
	_sonar("cobro")
	print("COCHE_REPARADO por ", coste, " €")
	return true

func _mejorar_coche(tipo: String) -> bool:
	var inst: Dictionary = _mis_coches[_coche_activo]
	var nivel := int(inst[tipo])
	if nivel >= 3:
		return false
	var coste := (500 if tipo == "motor" else 350) * (nivel + 1)
	if _dinero < coste:
		return false
	_dinero -= coste
	inst[tipo] = nivel + 1
	_actualizar_hud_dinero()
	_guardar()
	_sonar("cobro")
	print("COCHE_MEJORADO ", tipo, " nivel ", nivel + 1)
	return true

func _danar_coche(n: int) -> void:
	if _es_bici():
		return
	var inst: Dictionary = _mis_coches[_coche_activo]
	inst["danio"] = mini(100, int(inst["danio"]) + n)
	if _tiempo > _danio_cd:
		_danio_cd = _tiempo + 6.0
		_aviso = "¡Choque! Tu coche tiene un %d %% de daño" % int(inst["danio"])
		_aviso_hasta = _tiempo + 2.5
	_guardar()

func _reconstruir_coche() -> void:
	if _coche == null:
		return
	var pos := _coche.position
	var dir := _coche_dir
	_coche.queue_free()
	var inst: Dictionary = _mis_coches[_coche_activo]
	var cat: Dictionary = COCHES[int(inst["id"])]
	_coche = _modelo_coche(cat["color"], String(cat["estilo"]), cat["dims"])
	_coche.position = pos
	_coche.rotation.y = dir
	add_child(_coche)

func _crear_coche() -> void:
	var inst0: Dictionary = _mis_coches[_coche_activo]
	var cat0: Dictionary = COCHES[int(inst0["id"])]
	_coche = _modelo_coche(cat0["color"], String(cat0["estilo"]), cat0["dims"])
	# Aparcar en el nodo de calle más cercano al portal de origen
	var sitio := _origen_libre
	if not _nodos.is_empty():
		var nv: Vector2 = _nodos[_nodo_cercano(Vector2(_origen_libre.x, _origen_libre.z))]
		sitio = Vector3(nv.x, 0, nv.y)
	_coche.position = Vector3(sitio.x, _altura(sitio.x, sitio.z), sitio.z)
	_coche_dir = 0.0
	add_child(_coche)
	print("COCHE_OK aparcado en ", _coche.position)

func _marcador(pos: Vector3, color: Color, atravesar := false, radio := 0.45, tenue := false) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = radio
	cil.bottom_radius = radio
	cil.height = 26.0
	inst.mesh = cil
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.7
	if tenue:
		# Translúcido: marca el lugar sin tragarse a quien pasa por él
		mat.albedo_color.a = 0.30
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if atravesar:
		# El pilar del destino se ve a través de los edificios: nunca se pierde de vista
		mat.no_depth_test = true
		mat.render_priority = 5
	cil.material = mat
	inst.position = pos + Vector3(0, 13, 0)
	return inst

func _input(event: InputEvent) -> void:
	# Joystick táctil flotante (mitad izquierda baja de la pantalla)
	if event is InputEventScreenTouch:
		if _capa_tactil != null:
			_capa_tactil.visible = true
		if event.pressed and _joy_id == -1 and not _en_coche and not _panel_abierto and not _mapa_abierto and not _ayuda_abierta and not _panel_coches_abierto:
			var vp := get_viewport().get_visible_rect().size
			if event.position.x < vp.x * 0.45 and event.position.y > vp.y * 0.4:
				_joy_id = event.index
				_joy_centro = event.position
				_joy_valor = Vector2.ZERO
				_colocar_joy()
		elif not event.pressed and event.index == _joy_id:
			_joy_id = -1
			_joy_valor = Vector2.ZERO
			_colocar_joy()
	elif event is InputEventScreenDrag and event.index == _joy_id:
		var d: Vector2 = event.position - _joy_centro
		if d.length() > 55.0:
			d = d.normalized() * 55.0
		_joy_valor = d / 55.0
		_colocar_joy()
	if event is InputEventJoypadButton and event.pressed and not _auto and _jugador != null:
		if _ayuda_abierta:
			_cerrar_ayuda()
		elif event.button_index == JOY_BUTTON_A:
			if _dlg_abierto:
				_dlg_confirmar()
			elif not _bus_pasajero.is_empty():
				_bajar_bus_pasajero()
			elif _en_interior != "":
				_ejecutar_accion_interior(_accion_interior_cercana())
			elif _en_columpio or not _columpio_libre().is_empty():
				_alternar_columpio()
			elif not _en_coche and not _en_bus and not _sentado and not _bus_linea_cercano().is_empty():
				_subir_bus_pasajero(_bus_linea_cercano())
			else:
				_alternar_coche()
		elif _dlg_abierto and event.button_index == JOY_BUTTON_DPAD_DOWN:
			_dlg_mover(1)
		elif _dlg_abierto and event.button_index == JOY_BUTTON_DPAD_UP:
			_dlg_mover(-1)
		elif event.button_index == JOY_BUTTON_Y:
			_t_encargos()
		elif event.button_index == JOY_BUTTON_START:
			_t_mapa()
		elif event.button_index == JOY_BUTTON_X:
			if _en_coche:
				_sonar("bocina")
		elif event.button_index == JOY_BUTTON_B:
			_vista_aerea = not _vista_aerea
		elif event.button_index == JOY_BUTTON_BACK:
			_t_ayuda()
		elif event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_alternar_sentarse()
	if event is InputEventKey and event.keycode == KEY_SPACE and not event.echo:
		# El espacio también acelera, memorizado por evento: en
		# el navegador la consulta directa de la tecla puede
		# fallar si el lienzo pierde el foco un instante (Jon:
		# «el coche no acelera con la tecla espacio»).
		_gas_espacio = event.pressed
	if event is InputEventKey and event.pressed and not event.echo:
		if _son_amb != null and not _son_amb.playing:
			_son_amb.play()
		if event.keycode == KEY_N:
			_sonido = not _sonido
			AudioServer.set_bus_mute(0, not _sonido)
		elif event.keycode == KEY_M:
			_vista_aerea = not _vista_aerea
		elif event.keycode == KEY_B and _en_coche and not _auto:
			_sonar("bocina")
		elif event.keycode == KEY_F and not _auto and _jugador != null:
			_alternar_sentarse()
		elif event.keycode == KEY_E and not _auto and _jugador != null:
			if _dlg_abierto:
				_dlg_confirmar()
			elif not _bus_pasajero.is_empty():
				_bajar_bus_pasajero()
			elif _en_interior != "":
				_ejecutar_accion_interior(_accion_interior_cercana())
			elif _puerta_cercana() != "":
				_entrar_interior(_puerta_cercana())
			elif _en_columpio or not _columpio_libre().is_empty():
				_alternar_columpio()
			elif not _esp.is_empty() and String(_esp.get("tipo", "")) == "bus" and _bus != null and (_en_bus or _jugador.position.distance_to(_bus.position) < 4.5):
				_alternar_bus()
			elif not _esp.is_empty() and String(_esp.get("tipo", "")) == "camalote" and _masa_cercana() != null:
				_retirar_masa_cercana()
			elif _pj_cercano() != "":
				_hablar_cercano()
			elif not _en_coche and not _en_bus and not _sentado and not _bus_linea_cercano().is_empty():
				_subir_bus_pasajero(_bus_linea_cercano())
			else:
				_alternar_coche()
		elif _dlg_abierto and not _dlg_opciones.is_empty() and (event.keycode == KEY_S or event.keycode == KEY_DOWN):
			_dlg_mover(1)
		elif _dlg_abierto and not _dlg_opciones.is_empty() and (event.keycode == KEY_W or event.keycode == KEY_UP):
			_dlg_mover(-1)
		elif _dlg_abierto and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
			_dlg_confirmar()
		elif event.keycode == KEY_TAB and not _auto and _jugador != null:
			if _mapa_abierto:
				_cerrar_mapa()
			else:
				_cerrar_panel()
				_abrir_mapa()
		elif event.keycode == KEY_T and not _auto and _jugador != null:
			if _panel_abierto:
				_cerrar_panel()
			else:
				_cerrar_mapa()
				_abrir_panel()
		elif _panel_abierto and event.keycode >= KEY_1 and event.keycode <= KEY_3:
			_aceptar_trabajo(event.keycode - KEY_1)
		elif event.keycode == KEY_H and not _auto and _jugador != null:
			if _ayuda_abierta:
				_cerrar_ayuda()
			else:
				_cerrar_panel()
				_cerrar_mapa()
				_abrir_ayuda()
		elif _ayuda_abierta and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE):
			_cerrar_ayuda()

# Entrar/salir del coche con UNA pulsación de E. Antes se leía la tecla en
# cada fotograma y una sola pulsación entraba y salía decenas de veces.
func _banco_cercano() -> Dictionary:
	var mejor := {}
	var mejor_d := 1.7
	if _jugador == null:
		return mejor
	for a in _asientos:
		var ap: Vector3 = a["pos"]
		var d := Vector2(_jugador.position.x - ap.x, _jugador.position.z - ap.z).length()
		if d < mejor_d:
			mejor_d = d
			mejor = a
	return mejor

func _alternar_sentarse() -> void:
	if _en_coche:
		return
	if _sentado:
		_sentado = false
		_pierna_i.rotation.x = 0.0
		_pierna_d.rotation.x = 0.0
		var frente := Vector3(sin(_dir_jugador), 0, cos(_dir_jugador))
		_jugador.position += frente * 0.9
		_jugador.position.y = _altura(_jugador.position.x, _jugador.position.z) + 0.95
		_actualizar_hud()
		return
	var a := _banco_cercano()
	if a.is_empty():
		return
	_sentado = true
	var ap: Vector3 = a["pos"]
	_jugador.position = Vector3(ap.x, ap.y + 0.55, ap.z)
	_dir_jugador = float(a["rot"])
	_jugador.rotation.y = _dir_jugador
	_actualizar_hud()

func _alternar_coche() -> void:
	if _sentado:
		_alternar_sentarse()
		return
	if _en_coche:
		_en_coche = false
		_jugador.visible = true
		# El escolta de la historia se baja contigo, junto al coche.
		if not _hist.is_empty() and bool(_hist.get("pasajero", false)):
			_hist["pasajero"] = false
			var m_b: Dictionary = HISTORIA[int(_hist["idx"])]
			var rn3: Node3D = _pjs[String(m_b["pj"])]["nodo"]
			if rn3 != null and is_instance_valid(rn3):
				var salida3 := _punto_libre(_coche.position + Vector3(-2.0, 0, 2.0), 0.45)
				rn3.position = Vector3(salida3.x, _altura(salida3.x, salida3.z) + 0.95, salida3.z)
				rn3.visible = true
		_jugador.position = _punto_libre(_coche.position + Vector3(2.0, 0, 0), 0.45)
		# El pasajero del encuentro se baja contigo, al otro lado.
		if not _enc.is_empty() and bool(_enc.get("en_coche", false)):
			_enc["en_coche"] = false
			var rn2: Node3D = _enc["nodo"]
			if rn2 != null and is_instance_valid(rn2):
				var salida := _punto_libre(_coche.position + Vector3(-2.0, 0, 0), 0.45)
				rn2.position = Vector3(salida.x, _altura(salida.x, salida.z) + 0.95, salida.z)
				rn2.visible = true
		_jugador.position.y = _altura(_jugador.position.x, _jugador.position.z) + 0.95
		if _pill_vel != null:
			_pill_vel.visible = false
		if _es_bici():
			_dir_jugador = _coche_dir
			_jugador.rotation.x = 0.0
			_pierna_i.rotation.x = 0.0
			_pierna_d.rotation.x = 0.0
			_brazo_i.rotation.x = 0.0
			_brazo_d.rotation.x = 0.0
		if _agua_profunda(Vector2(_coche.position.x, _coche.position.z)):
			# Sales a nado: te quedas en el agua, junto al coche.
			_nadando = true
			_jugador.position = Vector3(_coche.position.x + 2.2, _nivel_agua(Vector2(_coche.position.x, _coche.position.z)) + 0.30, _coche.position.z)
			_dir_jugador = _coche_dir
		_coche_vel = 0.0
		if _son_motor != null:
			_son_motor.stop()
		_sonar("puerta_abrir")
		_musica_para(false)
	elif _jugador.position.distance_to(_coche.position) < 3.5:
		_en_coche = true
		_nadando = false
		_jugador.rotation.x = 0.0
		_jugador.visible = _es_bici()
		# La persona de un encuentro activo se monta contigo si está
		# cerca: viaja dentro y se baja cuando tú te bajes (Jon vio al
		# estudiante quedarse en la acera mirando cómo se iba el coche).
		if not _enc.is_empty() and bool(_enc.get("activo", false)):
			var rn: Node3D = _enc["nodo"]
			if rn != null and is_instance_valid(rn) and Vector2(rn.position.x, rn.position.z).distance_to(Vector2(_coche.position.x, _coche.position.z)) < 30.0:
				_enc["en_coche"] = true
				rn.visible = false
				_aviso_set(String(_enc["nombre"]) + " se monta en el coche", 3.5)
		# Y el escolta de una misión de historia, si está cerca.
		if not _hist.is_empty() and String(_hist.get("fase", "")) == "ir":
			var m_m: Dictionary = HISTORIA[int(_hist["idx"])]
			if String(m_m.get("esc", "")) != "":
				var rn4: Node3D = _pjs[String(m_m["pj"])]["nodo"]
				if rn4 != null and is_instance_valid(rn4) and Vector2(rn4.position.x, rn4.position.z).distance_to(Vector2(_coche.position.x, _coche.position.z)) < 30.0:
					_hist["pasajero"] = true
					rn4.visible = false
					_aviso_set(String(_pjs[String(m_m["pj"])]["nombre"]) + " se monta en el coche", 3.5)
		if not _es_bici():
			if _son_motor != null:
				_son_motor.play()
			_sonar("puerta_cerrar")
			_sonar("arranque")
		_musica_para(true)
	_refrescar_pan()
	_refrescar_tactil()
	_actualizar_hud()

func _actualizar_camara(delta: float) -> void:
	if _vista_aerea:
		_cam.look_at_from_position(Vector3(0, 900, 900), Vector3.ZERO, Vector3.UP)
		return
	if _en_coche and _es_bici():
		_jugador.visible = true
		_jugador.position = _coche.position + Vector3(0, 0.80, 0)
		_jugador.rotation.y = _coche_dir
		_jugador.rotation.x = 0.10
		_fase_paso += delta * (3.0 + absf(_coche_vel) * 1.7)
		var ped := sin(_fase_paso) * 0.42
		_pierna_i.rotation.x = -0.50 + ped
		_pierna_d.rotation.x = -0.50 - ped
		_brazo_i.rotation.x = -0.58
		_brazo_d.rotation.x = -0.58
	var objetivo := _bus.position if _en_bus else (_coche.position if _en_coche else _jugador.position)
	var dir := _dir_bus if _en_bus else (_coche_dir if _en_coche else _dir_jugador)
	var dist := 20.0 if _en_bus else (17.0 if _en_coche else 7.5)
	var alto := 9.5 if _en_bus else (8.0 if _en_coche else 4.5)
	var deseada := objetivo - Vector3(sin(dir), 0, cos(dir)) * dist + Vector3(0, alto, 0)
	# Si la cámara quedaría dentro de un edificio, acercarla al jugador
	# hasta encontrar un punto libre (las calles son estrechas).
	var desplazamiento := deseada - objetivo
	var f := 1.0
	while f > 0.2 and _choca(Vector2(objetivo.x + desplazamiento.x * f, objetivo.z + desplazamiento.z * f), 0.3):
		f -= 0.15
	if _choca(Vector2(objetivo.x, objetivo.z), 0.3):
		# El propio jugador (o el coche) está dentro de un edificio:
		# cenital alta, sobre los tejados, para ver dónde estás y salir.
		deseada = objetivo + Vector3(0, 75, 0.5)
	elif _choca(Vector2(objetivo.x + desplazamiento.x * f, objetivo.z + desplazamiento.z * f), 0.3):
		# Ni acercándola cabe (p. ej. espalda contra una pared):
		# vista cenital sobre el jugador, cuya columna siempre está libre.
		deseada = objetivo + Vector3(0, 14, 0.5)
	else:
		deseada = objetivo + Vector3(desplazamiento.x * f, 0, desplazamiento.z * f) + Vector3(0, alto, 0)
		# Altura final: sobre el terreno en su posición definitiva y nunca a ras
		var suelo := _altura(deseada.x, deseada.z) + 2.0
		if deseada.y < suelo:
			deseada.y = suelo
		if deseada.y < objetivo.y + 3.0:
			deseada.y = objetivo.y + 3.0
	_cam.position = _cam.position.lerp(deseada, clampf(delta * 3.5, 0.0, 1.0))
	# Rescate: la cámara jamás queda bajo el terreno en su posición
	var suelo_cam := _altura(_cam.position.x, _cam.position.z) + 1.2
	if _cam.position.y < suelo_cam:
		_cam.position.y = suelo_cam
	_cam.look_at(objetivo + Vector3(0, 1.5, 0), Vector3.UP)

func _physics_process(delta: float) -> void:
	if _jugador == null:
		return
	_procesar_tiles(delta)
	_tiempo += delta
	if (_mapa_abierto or _panel_abierto or _ayuda_abierta or _panel_coches_abierto or _panel_esp_abierto or _dlg_abierto or _panel_carr_abierto) and not _auto:
		return
	if _en_bus:
		_conducir_bus(delta)
	elif _en_coche or (_auto and _fase_auto == 1):
		if not _carr.is_empty() and String(_carr.get("fase", "")) == "cuenta":
			_coche_vel = 0.0
		elif _carr_auto and not _carr.is_empty() and String(_carr.get("fase", "")) == "corriendo":
			_seguir_ruta(_carr["yo"], delta)
			_coche_dir = _coche.rotation.y
			_coche_vel = float(_carr["yo"]["vel"])
		else:
			_conducir(delta)
	elif not _bus_pasajero.is_empty():
		_actualizar_pasajero(delta)
	elif _en_columpio:
		_actualizar_columpio(delta)
	else:
		if _nadando:
			_nadar(delta)
		else:
			_andar(delta)
			if _agua_profunda(Vector2(_jugador.position.x, _jugador.position.z)):
				_nadando = true
	_comprobar_salida_interior()
	_actualizar_tenderos(delta)
	# Rastro del recorrido (para el mapa) y peatones. Dentro de un
	# interior no se anota: las salas viven lejos de la ciudad y el
	# mapa dibujaba una recta imposible hasta ellas.
	var pos_r := _bus.position if _en_bus else (_coche.position if (_en_coche or (_auto and _fase_auto == 1)) else _jugador.position)
	var p2 := Vector2(pos_r.x, pos_r.z)
	if _en_interior == "" and (_rastro.is_empty() or p2.distance_to(_rastro[_rastro.size() - 1]) > 8.0):
		_rastro.append(p2)
		if _rastro.size() > 500:
			_rastro.remove_at(0)
	_mover_peatones(delta)
	_mover_palomas(delta)
	_mover_trafico(delta)
	_mover_buses(delta)
	_tic_vis += delta
	if _tic_vis > 0.25:
		_tic_vis = 0.0
		_actualizar_visibilidad()
	_actualizar_especiales(delta)
	_actualizar_caras()
	_actualizar_encuentros(delta)
	_mover_encuentro(delta)
	_mover_historia(delta)
	_actualizar_carrera(delta)
	# ¿Llegada al objetivo del encargo?
	if not _trabajo.is_empty():
		var en_coche_ahora := _en_coche or (_auto and _fase_auto == 1)
		var pos_ref := _coche.position if en_coche_ahora else _jugador.position
		var dist := Vector2(pos_ref.x - _destino_libre.x, pos_ref.z - _destino_libre.z).length()
		var margen := 5.0 if en_coche_ahora else 3.5
		if dist < margen and (en_coche_ahora or not _auto):
			_al_llegar()
	if not _hist.is_empty() and String(_hist.get("fase", "")) == "ir":
		var pos_ref_h := _coche.position if _en_coche else _jugador.position
		var dist_h := Vector2(pos_ref_h.x - _destino_libre.x, pos_ref_h.z - _destino_libre.z).length()
		if dist_h < (5.0 if _en_coche else 3.5):
			var m_h: Dictionary = HISTORIA[int(_hist["idx"])]
			if String(m_h.get("esc", "")) != "":
				var pp_h: Vector3 = _pjs[String(m_h["pj"])]["pos"]
				if Vector2(pp_h.x - _destino_libre.x, pp_h.z - _destino_libre.z).length() < 30.0:
					_hist_llegada()
			else:
				_hist_llegada()
	if not _enc.is_empty():
		var pos_ref_e := _coche.position if _en_coche else _jugador.position
		var dist_e := Vector2(pos_ref_e.x - _destino_libre.x, pos_ref_e.z - _destino_libre.z).length()
		if dist_e < (5.0 if _en_coche else 3.5):
			_enc_llegada()
	if _auto and not _mision_ok and _tiempo > 240.0:
		print("MISION_FALLO tiempo agotado")
		get_tree().quit()
	# Rescate anti-atrapamiento: dentro de un edificio demasiado tiempo
	if not _en_coche and not _sentado and _choca(Vector2(_jugador.position.x, _jugador.position.z), 0.4):
		_atrapado_t += delta
		if _atrapado_t > 1.5:
			_atrapado_t = 0.0
			var rescate := _punto_libre(_jugador.position, 0.45)
			rescate.y = _altura(rescate.x, rescate.z) + 0.95
			_jugador.position = rescate
			print("RESCATE jugador movido a ", rescate)
	else:
		_atrapado_t = 0.0
	# Reloj del juego: un minuto por segundo real
	if _modo_libre and not _auto:
		var antes := int(_minutos)
		_minutos += delta
		if _minutos >= 1440.0:
			_minutos -= 1440.0
			_dia += 1
		if int(_minutos) != antes:
			_actualizar_hud_dinero()
	if _modo_libre and not _auto and _minimapa != null and _jugador != null:
		_t_mini += delta
		if _t_mini >= 0.15:
			_t_mini = 0.0
			_minimapa.call("actualizar", _datos_minimapa())
	if _modo_libre and not _auto and _et_calle != null:
		_t_calle += delta
		if _t_calle > 0.3:
			_t_calle = 0.0
			var pos_et := _coche.position if _en_coche else _jugador.position
			var nombre := _calle_actual(pos_et)
			_et_calle.text = nombre
			_actualizar_hud()
			_actualizar_ambientes()
			_refrescar_rotulos()
			if _en_interior != "" and not _dlg_abierto and _tiempo > _aviso_hasta:
				var acc_h := _accion_interior_cercana()
				if acc_h != "":
					var textos_h := {"dormir": "Dormir", "pelo": "Cambiar de pelo", "ropa": "Cambiar camiseta", "pan": "Comprar pan (2 €)", "subir": "Subir a la planta alta", "bajar": "Bajar a la planta baja", "comprar:game": "Game: un videojuego (40 €)", "comprar:mediamarkt": "MediaMarkt: auriculares (25 €)", "comprar:eci": "El Corte Inglés: un perfume (30 €)", "comprar:forum": "Forum Sport: zapatillas (45 €)", "comprar:bk": "Burger King: un menú (10 €)", "comprar:cafe": "Cafetería: café con pincho (3 €)", "comprar:quiosco": "Quiosco: una revista (4 €)", "comprar:yelmo": "Yelmo Cines: una entrada (9 €)", "comprar:alehop": "ALE-HOP: un regalo (8 €)", "comprar:fosters": "Foster's: una cena (14 €)", "comprar:dec_bici": "Decathlon: bicicleta de montaña Grajera (450 €)", "comprar:dec_casco": "Decathlon: un casco de ciclismo (35 €)", "comprar:dec_mochila": "Decathlon: una mochila de montaña (40 €)", "comprar:dec_chaqueta": "Decathlon: una chaqueta impermeable (80 €)", "comprar:dec_mancuernas": "Decathlon: unas mancuernas (30 €)", "comprar:dec_zapatillas": "Decathlon: unas zapatillas de trail (65 €)", "comprar:dec_balon": "Decathlon: un balón de fútbol (20 €)", "comprar:dec_raqueta": "Decathlon: una raqueta de pádel (55 €)", "comprar:dec_banador": "Decathlon: bañador y gafas de natación (25 €)", "comprar:dec_tienda": "Decathlon: una tienda de campaña (120 €)"}
					_aviso = "Pulsa E · " + String(textos_h.get(acc_h, acc_h))
					_aviso_hasta = _tiempo + 2.0
			if not _en_coche and not _sentado and _tiempo > _aviso_banco_cd and not _banco_cercano().is_empty():
				_aviso_banco_cd = _tiempo + 14.0
				_aviso = "Pulsa F para sentarte en el banco"
				_aviso_hasta = _tiempo + 2.5
				_actualizar_hud()
			if not _en_coche and not _en_columpio and _en_interior == "" and _tiempo > _aviso_columpio_cd and not _columpio_libre().is_empty():
				_aviso_columpio_cd = _tiempo + 14.0
				_aviso = "Pulsa E para montarte en el columpio"
				_aviso_hasta = _tiempo + 2.5
				_actualizar_hud()
			if _mapa_abierto:
				var pos_ef := _bus.position if _en_bus else (_coche.position if _en_coche else _jugador.position)
				_mapa.call("actualizar_pos", Vector2(pos_ef.x, pos_ef.z), Vector2(_coche.position.x, _coche.position.z))
				if not _carr.is_empty():
					_mapa.call("actualizar_carrera", _carr_mapa_datos())
	if _modo_libre and not _auto:
		_actualizar_camara(delta)

func _andar(delta: float) -> void:
	if _sentado:
		_pierna_i.rotation.x = -1.25
		_pierna_d.rotation.x = -1.25
		if _rodilla_i != null:
			# Sentado de verdad: muslo horizontal, espinilla colgando.
			_rodilla_i.rotation.x = 1.2
			_rodilla_d.rotation.x = 1.2
		_brazo_i.rotation.x = -0.15
		_brazo_d.rotation.x = -0.15
		if _cabeza_j != null:
			_cabeza_j.rotation.y = sin(_tiempo * 0.3) * 0.5
		return
	var vel := Vector3.ZERO
	if _auto:
		if _ruta_fase != 0:
			_ruta = _calcular_ruta(_jugador.position, _coche.position)
			_ruta_idx = 0
			_ruta_fase = 0
		if _jugador.position.distance_to(_coche.position) < 2.6:
			_fase_auto = 1
			_en_coche = true
			_jugador.visible = false
			print("PRUEBA: jugador entra en el coche")
			return
		var obj := _objetivo_ruta()
		if obj != Vector3.INF:
			var hacia := obj - _jugador.position
			hacia.y = 0
			if hacia.length() < 2.0:
				_ruta_idx += 1
			elif hacia.length() > 0.1:
				vel = hacia.normalized() * 6.0
	else:
		var dir := Vector2.ZERO
		if _joy_valor.length() > 0.15:
			dir = _joy_valor
		var pad_dir := Vector2(_pad_eje(JOY_AXIS_LEFT_X), _pad_eje(JOY_AXIS_LEFT_Y))
		if pad_dir.length() > 0.2:
			dir = pad_dir
		_corriendo = Input.is_key_pressed(KEY_SPACE)
		if dir.length() > 0.01:
			# El joystick y el stick apuntan: andas hacia donde empujas.
			vel = Vector3(dir.x, 0, dir.y).normalized() * (10.2 if _corriendo else 6.0)
			_dir_jugador = atan2(vel.x, vel.z)
		else:
			# Teclado RELATIVO, como al conducir: izquierda y derecha
			# GIRAN al personaje; arriba anda hacia donde mira. Abajo
			# NO es marcha atrás (una persona no anda hacia atrás):
			# al pulsarlo, el personaje se da media vuelta y anda en
			# sentido contrario. La cámara va siempre tras él.
			var giro := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
			var adelante := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
			var atras := Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
			if giro != 0.0:
				_dir_jugador = wrapf(_dir_jugador + giro * 2.6 * delta, -PI, PI)
				_en_vuelta = false
			var frente := Vector3(sin(_dir_jugador), 0, cos(_dir_jugador))
			if adelante:
				_en_vuelta = false
				vel = frente * (10.2 if _corriendo else 6.0)
			elif atras:
				if not _en_vuelta and not _atras_ant:
					_en_vuelta = true
					_vuelta_obj = wrapf(_dir_jugador + PI, -PI, PI)
				if _en_vuelta:
					var dif_v := wrapf(_vuelta_obj - _dir_jugador, -PI, PI)
					_dir_jugador = wrapf(_dir_jugador + clampf(dif_v, -10.0 * delta, 10.0 * delta), -PI, PI)
					if absf(dif_v) < 0.08:
						_en_vuelta = false
				else:
					vel = frente * (10.2 if _corriendo else 6.0)
			_atras_ant = atras
	if _profundidad(Vector2(_jugador.position.x, _jugador.position.z)) > 0.08:
		# Vadeando la orilla: el agua frena el paso y no se
		# puede correr; cuando cubre (> 0,24) ya toca nadar.
		vel *= 0.55
		_corriendo = false
	_mover(_jugador, vel * delta, 0.4)
	var andando := vel.length() > 0.1
	if andando:
		_dist_pasos += vel.length() * delta
		if _dist_pasos > 2.1:
			_dist_pasos = 0.0
			_paso_idx += 1
			var variantes := ["paso_asfalto", "paso_acera", "paso_hierba"]
			var elegido: AudioStreamPlayer = null
			if _banco.has(variantes[_paso_idx % 3]):
				elegido = _banco[variantes[_paso_idx % 3]]
			if elegido != null:
				elegido.pitch_scale = randf_range(0.92, 1.08)
				elegido.play()
			elif _son_pasos != null:
				_son_pasos.pitch_scale = randf_range(0.92, 1.08)
				_son_pasos.play()
	if _auto:
		if andando:
			_jugador.rotation.y = atan2(vel.x, vel.z)
	else:
		# También girando en parado: el cuerpo sigue al rumbo siempre.
		_jugador.rotation.y = lerp_angle(_jugador.rotation.y, _dir_jugador, clampf(delta * 10.0, 0.0, 1.0))
	_animar_paso(delta, andando)

func _crear_espuma_nado() -> void:
	# El disco de espuma que rodea al nadador: un cilindro
	# blanco semitransparente pegado a la superficie.
	var cil := CylinderMesh.new()
	cil.top_radius = 0.85
	cil.bottom_radius = 0.85
	cil.height = 0.04
	cil.radial_segments = 20
	_espuma_nado = MeshInstance3D.new()
	_espuma_nado.mesh = cil
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.98, 1.0, 0.38)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_espuma_nado.material_override = mat
	_espuma_nado.visible = false
	add_child(_espuma_nado)

func _terminar_nado() -> void:
	_nadando = false
	_vel_nado = Vector2.ZERO
	_jugador.rotation.x = 0.0
	_jugador.rotation.z = 0.0
	if _cabeza_j != null:
		_cabeza_j.rotation.x = 0.0
	if _codo_i != null:
		_codo_i.rotation.x = 0.0
	if _codo_d != null:
		_codo_d.rotation.x = 0.0
	if _rodilla_i != null:
		_rodilla_i.rotation.x = 0.0
	if _rodilla_d != null:
		_rodilla_d.rotation.x = 0.0
	if _espuma_nado != null:
		_espuma_nado.visible = false
	_jugador.position.y = _altura(_jugador.position.x, _jugador.position.z) + 0.95

func _nadar(delta: float) -> void:
	# A nado de verdad (Jon, 2026-11-24: antes «la movilidad
	# era muy rara» y no se notaba que nadaba): el cuerpo va
	# casi horizontal braceando a crol, con impulso a tirones
	# al ritmo de la brazada, balanceo del cuerpo, patada de
	# tijera y la espuma alrededor. Se entra cuando el agua
	# cubre (> 0,24 m) y se sale al hacer pie (< 0,16 m);
	# entre medias se vadea andando (ver _andar).
	var p := Vector2(_jugador.position.x, _jugador.position.z)
	# Se sale al hacer pie; y si esta ENCIMA de una estructura
	# (el tablero de un puente), no debajo de ella: nadando
	# se pasa bajo los puentes sin salir del agua.
	if _profundidad(p) < 0.16 or (_altura(p.x, p.y) > _altura_terreno(p.x, p.y) + 0.05 and _jugador.position.y > _nivel_agua(p) + 1.2):
		_terminar_nado()
		return
	if _espuma_nado == null:
		_crear_espuma_nado()
	var dir := Vector2.ZERO
	if _joy_valor.length() > 0.15:
		dir = _joy_valor
	var pad_dir := Vector2(_pad_eje(JOY_AXIS_LEFT_X), _pad_eje(JOY_AXIS_LEFT_Y))
	if pad_dir.length() > 0.2:
		dir = pad_dir
	var deseo := Vector2.ZERO
	if dir.length() > 0.01:
		deseo = dir.normalized()
		_dir_jugador = atan2(deseo.x, deseo.y)
	else:
		var giro := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		var adelante := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
		var atras := Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
		if giro != 0.0:
			_dir_jugador = wrapf(_dir_jugador + giro * 2.2 * delta, -PI, PI)
			_en_vuelta = false
		if adelante:
			_en_vuelta = false
			deseo = Vector2(sin(_dir_jugador), cos(_dir_jugador))
		elif atras:
			# Tampoco se nada hacia atrás: media vuelta y a bracear.
			if not _en_vuelta and not _atras_ant:
				_en_vuelta = true
				_vuelta_obj = wrapf(_dir_jugador + PI, -PI, PI)
			if _en_vuelta:
				var dif_v := wrapf(_vuelta_obj - _dir_jugador, -PI, PI)
				_dir_jugador = wrapf(_dir_jugador + clampf(dif_v, -7.0 * delta, 7.0 * delta), -PI, PI)
				if absf(dif_v) < 0.08:
					_en_vuelta = false
			else:
				deseo = Vector2(sin(_dir_jugador), cos(_dir_jugador))
		_atras_ant = atras
	var braceando := deseo.length() > 0.01
	if braceando:
		_fase_paso += delta * 5.2
	# El impulso llega con cada brazada: avanza a tirones.
	var impulso := 1.5 + 0.55 * maxf(0.0, sin(_fase_paso))
	_vel_nado = _vel_nado.lerp(deseo * impulso, clampf(delta * 3.2, 0.0, 1.0))
	var nueva := p + _vel_nado * delta
	if not _choca(nueva, 0.4):
		_jugador.position.x = nueva.x
		_jugador.position.z = nueva.y
	var na := _nivel_agua(Vector2(_jugador.position.x, _jugador.position.z))
	if na < -100.0:
		_terminar_nado()
		return
	_jugador.position.y = na + 0.26 + sin(_tiempo * 2.1) * 0.045
	_jugador.rotation.y = lerp_angle(_jugador.rotation.y, _dir_jugador, clampf(delta * 10.0, 0.0, 1.0))
	var rapido := _vel_nado.length() > 0.35
	# Braceando va tumbado; quieto, se mantiene a flote mas
	# vertical, como quien se sostiene en el agua.
	var incl_obj := 1.02 if rapido else 0.38
	_jugador.rotation.x = lerp_angle(_jugador.rotation.x, incl_obj, clampf(delta * 4.0, 0.0, 1.0))
	if rapido:
		_jugador.rotation.z = sin(_fase_paso) * 0.09
		_brazo_i.rotation.x = sin(_fase_paso) * 1.85
		if _codo_i != null:
			_codo_i.rotation.x = -0.30 - maxf(0.0, sin(_fase_paso - PI * 0.5)) * 0.85
		if _pan_en_mano:
			# Con la barra en la mano, el brazo derecho va medio
			# doblado y apenas se balancea.
			_brazo_d.rotation.x = -0.55 + sin(_fase_paso + PI) * 0.15
			if _codo_d != null:
				_codo_d.rotation.x = -0.9
		else:
			_brazo_d.rotation.x = sin(_fase_paso + PI) * 1.85
			if _codo_d != null:
				_codo_d.rotation.x = -0.30 - maxf(0.0, sin(_fase_paso + PI * 0.5)) * 0.85
		_pierna_i.rotation.x = sin(_fase_paso * 2.0) * 0.38
		_pierna_d.rotation.x = sin(_fase_paso * 2.0 + PI) * 0.38
		if _rodilla_i != null:
			_rodilla_i.rotation.x = 0.22 + maxf(0.0, -sin(_fase_paso * 2.0)) * 0.30
		if _rodilla_d != null:
			_rodilla_d.rotation.x = 0.22 + maxf(0.0, sin(_fase_paso * 2.0)) * 0.30
	else:
		_brazo_i.rotation.x = sin(_tiempo * 2.4) * 0.45
		_brazo_d.rotation.x = sin(_tiempo * 2.4 + 0.6) * 0.45
		if _codo_i != null:
			_codo_i.rotation.x = -0.55
		if _codo_d != null:
			_codo_d.rotation.x = -0.55
		_pierna_i.rotation.x = sin(_tiempo * 3.1) * 0.22
		_pierna_d.rotation.x = sin(_tiempo * 3.1 + PI) * 0.22
		if _rodilla_i != null:
			_rodilla_i.rotation.x = 0.3
		if _rodilla_d != null:
			_rodilla_d.rotation.x = 0.3
	if _cabeza_j != null:
		# La cabeza fuera del agua, mirando al frente.
		_cabeza_j.rotation.x = -0.52 if rapido else -0.12
	_espuma_nado.visible = true
	_espuma_nado.position = Vector3(_jugador.position.x, na + 0.33, _jugador.position.z)
	_espuma_nado.rotation.y = _jugador.rotation.y
	var esc := 1.0 + 0.10 * sin(_fase_paso)
	_espuma_nado.scale = Vector3(esc * 0.85, 1.0, esc * 1.2)

func _conducir(delta: float) -> void:
	var acel := 0.0
	if _acel_forzado > -0.5 and not _auto:
		acel = _acel_forzado
	var giro := 0.0
	if _auto:
		if _ruta_fase != 1:
			_ruta = _calcular_ruta(_coche.position, _destino_libre)
			_ruta_idx = 0
			_ruta_fase = 1
			print("PRUEBA: ruta en coche con ", _ruta.size(), " puntos")
		var obj := _objetivo_ruta()
		var hacia := (obj if obj != Vector3.INF else _destino_libre) - _coche.position
		hacia.y = 0
		if obj != Vector3.INF:
			var rumbo := Vector3(sin(_coche_dir), 0, cos(_coche_dir))
			var pasado: bool = hacia.length() < 12.0 and hacia.normalized().dot(rumbo) < 0.0
			if hacia.length() < 8.0 or pasado:
				_ruta_idx += 1
		var ang_obj := atan2(hacia.x, hacia.z)
		var dif := wrapf(ang_obj - _coche_dir, -PI, PI)
		giro = clampf(dif * 1.8, -1.0, 1.0)
		var es_final := _ruta_idx >= _ruta.size() - 1
		var vel_obj := 11.0
		if es_final:
			vel_obj = clampf(hacia.length() * 0.6, 2.0, 6.0)
		if _coche_vel < vel_obj:
			acel = 1.0
		elif _coche_vel > vel_obj + 1.0:
			acel = -0.4
	else:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			acel = 1.0
		if Input.is_key_pressed(KEY_SPACE):
			acel = 1.0
		if _gas_espacio:
			acel = 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			acel = -0.7
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			giro = -1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			giro = 1.0
	if not _auto:
		if absf(_joy_valor.y) > 0.15:
			acel = clampf(-_joy_valor.y, -0.7, 1.0)
		if absf(_joy_valor.x) > 0.15:
			giro = _joy_valor.x
		# Pedales y volante táctiles del layout nuevo
		if _toque_gas:
			acel = 1.0
		if _toque_freno:
			acel = -0.7
		if _toque_giro != 0.0:
			giro = _toque_giro
		# Mando: el stick gira y los gatillos aceleran y frenan
		var pad_giro := _pad_eje(JOY_AXIS_LEFT_X)
		if absf(pad_giro) > 0.15:
			giro = pad_giro
		var gat_d := _pad_gatillo(JOY_AXIS_TRIGGER_RIGHT)
		var gat_i := _pad_gatillo(JOY_AXIS_TRIGGER_LEFT)
		if gat_d > 0.05:
			acel = gat_d
		elif gat_i > 0.05:
			acel = -0.7 * gat_i
		else:
			var pad_y := _pad_eje(JOY_AXIS_LEFT_Y)
			if pad_y < -0.3:
				acel = 1.0
			elif pad_y > 0.3:
				acel = -0.7
	if not _auto:
		# Las manos giran al contrario que el piloto automático:
		# con la cámara detrás del coche, la D tiene que llevar
		# el morro a la derecha (Jon: «están al revés»).
		giro = -giro
	var st := _stats_activo()
	if acel > 0.0:
		_coche_vel += acel * float(st["acel"]) * delta
	elif acel < 0.0:
		if _coche_vel > 0.5:
			_coche_vel += acel * float(st["freno"]) * delta
		elif _es_bici():
			# En bici no hay marcha atrás: el freno solo detiene.
			_coche_vel = move_toward(_coche_vel, 0.0, float(st["freno"]) * delta)
		else:
			_coche_vel += acel * float(st["acel"]) * 0.6 * delta
	_coche_vel = clampf(_coche_vel, 0.0 if _es_bici() else -float(st["vmax"]) * 0.35, float(st["vmax"]))
	if _pill_vel != null:
		_pill_vel.visible = true
		_hud_vel.text = str(int(round(absf(_coche_vel) * 3.6))) + " km/h"
	if _son_motor != null and not _es_bici():
		if not _son_motor.playing:
			_son_motor.play()
		var vel_abs := absf(_coche_vel)
		var marcha := clampf(floor(vel_abs / 4.5), 0.0, 3.0)
		_son_motor.pitch_scale = 0.72 + marcha * 0.13 + (fposmod(vel_abs, 4.5) / 4.5) * 0.38
	if not _auto and acel < 0.0 and absf(_coche_vel) > 9.0 and _tiempo > _frenada_cd:
		_frenada_cd = _tiempo + 2.5
		_sonar("frenada")
	if acel == 0.0:
		_coche_vel = move_toward(_coche_vel, 0.0, float(st["freno"]) * 0.35 * delta)
	if absf(_coche_vel) > 0.05 or _auto:
		var factor := clampf(absf(_coche_vel) / 6.0, 0.35, 1.0)
		_coche_dir += giro * float(st["giro"]) * delta * (signf(_coche_vel) if absf(_coche_vel) > 0.05 else 1.0) * factor
	var avance := Vector3(sin(_coche_dir), 0, cos(_coche_dir)) * _coche_vel * delta
	if _auto:
		# El conductor automático sigue el grafo de calles: sin colisión
		# (la ruta ya va por la calzada; la colisión es para el modo manual)
		_coche.position += avance
		_coche.position.y = _altura(_coche.position.x, _coche.position.z)
	else:
		if _agua_profunda(Vector2(_coche.position.x, _coche.position.z)):
			# En el agua el coche no anda: queda varado y toca
			# salir con E y nadar hasta la orilla.
			_coche_vel = 0.0
			if _son_motor != null:
				_son_motor.stop()
			if _tiempo > _varado_cd:
				_varado_cd = _tiempo + 7.0
				_aviso_set("El coche esta en el agua: sal con E y nada hasta la orilla", 4.5)
			_coche.rotation.y = _coche_dir
			return
		var antes := _coche.position
		_mover(_coche, avance, 0.85)
		var movido := _coche.position.distance_to(antes)
		if movido < avance.length() * 0.3 and absf(_coche_vel) > 2.0:
			if movido < avance.length() * 0.1:
				if absf(_coche_vel) > 6.0:
					_danar_coche(int((absf(_coche_vel) - 6.0) * 1.5) + 2)
				_coche_vel = 0.0  # choque de frente contra un edificio
			else:
				_coche_vel *= 0.45  # roce: frena, pero no se queda clavado
	_coche.rotation.y = _coche_dir
	_comprobar_radares()

# Calle con nombre más cercana a una posición (para la etiqueta «Estás en»)
func _calle_actual(pos: Vector3) -> String:
	var mejor := ""
	var mejor_d := 22.0
	var p := Vector2(pos.x, pos.z)
	for c in _calles_nombradas:
		var pts: Array = c["p"]
		for i in range(pts.size() - 1):
			var a := Vector2(float(pts[i][0]), float(pts[i][1]))
			var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			var d := p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))
			if d < mejor_d:
				mejor_d = d
				mejor = String(c["n"])
	return mejor

func _crear_entorno() -> void:
	var datos = JSON.parse_string(FileAccess.get_file_as_string("res://datos/entorno.json"))
	if datos == null:
		return
	var datos_nom = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/calles_nom.json"))
	if datos_nom != null:
		_calles_nombradas = datos_nom["calles"]
	var datos_pois = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/pois.json"))
	if datos_pois != null:
		_pois = datos_pois["pois"]
		_pois_mapa = []
		for q in _pois:
			if int(q.get("k", 0)) == 1:
				_pois_mapa.append(q)
	var datos_rio = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/rio.json"))
	var rio: Array = []
	if datos_rio != null:
		_rio = datos_rio["puntos"]
		var base_rio: Array[Vector2] = []
		for q in _rio:
			base_rio.append(Vector2(float(q[0]), float(q[1])))
		for i in base_rio.size():
			if i > 0:
				var desde_r: Vector2 = base_rio[i - 1]
				var hasta_r: Vector2 = base_rio[i]
				var tramos_r := int(ceil(desde_r.distance_to(hasta_r) / 8.0))
				for k in range(1, tramos_r):
					var mr: Vector2 = desde_r.lerp(hasta_r, float(k) / float(tramos_r))
					rio.append([mr.x, mr.y])
			rio.append([base_rio[i].x, base_rio[i].y])
	# Río Ebro: cinta azul sobre el cauce
	if rio.size() > 1:
		var rv := PackedVector3Array()
		var rn := PackedVector3Array()
		var sin_cols := PackedColorArray()
		var ant_fila: Array[Vector3] = []
		var primero := true
		for i in rio.size():
			var p := Vector2(float(rio[i][0]), float(rio[i][1]))
			var dir := Vector2.ZERO
			if i > 0:
				dir += p - Vector2(float(rio[i - 1][0]), float(rio[i - 1][1]))
			if i < rio.size() - 1:
				dir += Vector2(float(rio[i + 1][0]), float(rio[i + 1][1])) - p
			if dir.length() < 0.001:
				continue
			dir = dir.normalized()
			var perp := Vector2(-dir.y, dir.x)
			var fila: Array[Vector3] = []
			for fr in [-33.0, -16.5, 0.0, 16.5, 33.0]:
				var pp: Vector2 = p + perp * float(fr)
				fila.append(Vector3(pp.x, _altura_terreno(pp.x, pp.y) + 0.35, pp.y))
			if not primero:
				for k in 4:
					_tri(rv, rn, sin_cols, ant_fila[k], ant_fila[k + 1], fila[k + 1], true, Color.WHITE)
					_tri(rv, rn, sin_cols, ant_fila[k], fila[k + 1], fila[k], true, Color.WHITE)
			ant_fila = fila
			primero = false
		add_child(_malla_de(rv, rn, PackedColorArray(), Color(0.13, 0.32, 0.58)))
		_crear_paseo()
	# Árboles reales (posiciones OSM): tronco y copa fundidos en una malla
	var tv := PackedVector3Array()
	var tn := PackedVector3Array()
	var tc := PackedColorArray()
	var col_tronco := Color(0.35, 0.25, 0.18)
	for a in []:  # los árboles van por baldosas (Fase 5.5)
		var ax := float(a[0])
		var az := float(a[1])
		var y0 := _altura(ax, az)
		var h: float = fposmod(sin(ax * 3.1 + az * 7.7) * 43758.5453, 1.0)
		var s := 0.85 + 0.5 * h
		var col_copa := Color(0.25, 0.45, 0.22).lerp(Color(0.38, 0.56, 0.26), h)
		for k in 4:
			var a1 := Vector2(ax, az) + Vector2(cos(k * PI / 2.0), sin(k * PI / 2.0)) * 0.16
			var a2 := Vector2(ax, az) + Vector2(cos((k + 1) * PI / 2.0), sin((k + 1) * PI / 2.0)) * 0.16
			_tri(tv, tn, tc, Vector3(a1.x, y0, a1.y), Vector3(a2.x, y0, a2.y), Vector3(a2.x, y0 + 2.0 * s, a2.y), false, col_tronco)
			_tri(tv, tn, tc, Vector3(a1.x, y0, a1.y), Vector3(a2.x, y0 + 2.0 * s, a2.y), Vector3(a1.x, y0 + 2.0 * s, a1.y), false, col_tronco)
		var cy := y0 + 3.3 * s
		var r := 1.7 * s
		var top := Vector3(ax, cy + r, az)
		var bot := Vector3(ax, cy - r * 0.7, az)
		var eq: Array[Vector3] = []
		for k in 4:
			eq.append(Vector3(ax + cos(k * PI / 2.0) * r, cy, az + sin(k * PI / 2.0) * r))
		for k in 4:
			var e1: Vector3 = eq[k]
			var e2: Vector3 = eq[(k + 1) % 4]
			_tri(tv, tn, tc, top, e2, e1, false, col_copa)
			_tri(tv, tn, tc, bot, e1, e2, false, col_copa)
	if not tv.is_empty():
		add_child(_malla_de(tv, tn, tc, Color.WHITE))
	# Señales con el nombre de cada calle
	for s in datos["senales"]:
		var et := Label3D.new()
		et.text = String(s["n"])
		et.font_size = 96
		et.pixel_size = 0.006
		et.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		et.modulate = Color(1, 1, 1)
		et.outline_size = 12
		et.outline_modulate = Color(0.05, 0.08, 0.14)
		var sx := float(s["x"])
		var sz := float(s["z"])
		et.position = Vector3(sx, _altura(sx, sz) + 5.0, sz)
		add_child(et)
	# Lugares que identifican la ciudad: pilar dorado y nombre
	for p in []:  # los lugares van por baldosas (Fase 5.5)
		var px := float(p["x"])
		var pz := float(p["z"])
		var pos := Vector3(px, _altura(px, pz), pz)
		add_child(_marcador(pos, Color(1.0, 0.78, 0.2)))
		var et := Label3D.new()
		et.text = String(p["n"])
		et.font_size = 96
		et.pixel_size = 0.009
		et.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		et.modulate = Color(1.0, 0.85, 0.3)
		et.outline_size = 12
		et.outline_modulate = Color(0.10, 0.08, 0.02)
		et.position = pos + Vector3(0, 11, 0)
		add_child(et)
	# Coches aparcados a lo largo de las calles anchas
	var datos_c = null  # los aparcados van por baldosas (Fase 5.5)
	var paleta_coches := [Color(0.92, 0.92, 0.94), Color(0.12, 0.12, 0.14), Color(0.62, 0.64, 0.68), Color(0.70, 0.16, 0.14), Color(0.16, 0.28, 0.55), Color(0.25, 0.25, 0.28), Color(0.55, 0.58, 0.62), Color(0.10, 0.30, 0.28)]
	var aparcados := 0
	if datos_c != null:
		for calle in datos_c["calles"]:
			if aparcados >= 110:
				break
			if not ["primary", "secondary", "tertiary", "residential", "unclassified"].has(String(calle["clase"])):
				continue
			var ancho := float(calle["ancho"])
			if ancho < 5.0:
				continue
			var pts: Array = calle["puntos"]
			for i in range(pts.size() - 1):
				if aparcados >= 110:
					break
				var p1 := Vector2(float(pts[i][0]), float(pts[i][1]))
				var p2 := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
				var pasos := int(p1.distance_to(p2) / 19.0)
				for k in pasos:
					var hh: float = fposmod(sin(p1.x * 1.7 + p1.y * 2.3 + float(k) * 13.7) * 43758.5453, 1.0)
					if hh < 0.30:
						continue
					var base := p1.lerp(p2, (float(k) + 0.5) / float(pasos))
					var dirv := (p2 - p1).normalized()
					var perp := Vector2(-dirv.y, dirv.x)
					var lado := 1.0 if hh > 0.65 else -1.0
					var pos := base + perp * lado * (ancho * 0.5 - 1.15)
					if _choca(pos, 1.05):
						continue
					var c := _modelo_coche(paleta_coches[int(hh * 8.0) % 8])
					c.position = Vector3(pos.x, _altura(pos.x, pos.y), pos.y)
					c.rotation.y = atan2(dirv.x, dirv.y)
					add_child(c)
					aparcados += 1
	print("ENTORNO_OK senales=", datos["senales"].size(), " pois_ciudad=", _pois.size(), " pois_mapa=", _pois_mapa.size())

# ---------- Fase 3: dinero, encargos y mapa ----------

func _actualizar_hud() -> void:
	# El objetivo vive en el banner inferior y en la píldora de distancia
	# junto al minimapa. Sin encargo, el banner solo aparece unos
	# segundos para avisar de un cobro o una cancelación.
	var con_trabajo := not _trabajo.is_empty() or not _esp.is_empty() or not _hist.is_empty() or not _enc.is_empty() or not _carr.is_empty() or (_historia_idx < 12 and _en_interior == "")
	if _banner != null:
		_banner.visible = con_trabajo or _tiempo < _banner_hasta or _tiempo < _aviso_hasta
		if _banner.visible:
			var hay_aviso := _tiempo < _aviso_hasta
			var texto := _aviso if hay_aviso else _objetivo_texto
			if con_trabajo and not hay_aviso and _jugador != null:
				var pos_ref := _bus.position if _en_bus else (_coche.position if _en_coche else _jugador.position)
				var d := Vector2(pos_ref.x - _destino_libre.x, pos_ref.z - _destino_libre.z).length()
				texto += " · a " + str(int(round(d))) + " m"
				if not _esp.is_empty() and String(_esp.get("tipo", "")) == "bus":
					texto += " · Pasajeros: " + str(int(_esp.get("a_bordo", 0)))
			_banner_texto.text = texto
	if not _bus_pasajero.is_empty() and _banner != null and _banner_texto != null:
		_banner.visible = true
		_banner_texto.text = "Autobús línea " + str(int(_bus_pasajero["linea"]) + 1) + " · próxima parada: " + _proxima_parada_nombre(_bus_pasajero) + " · pulsa E para bajar"
	if _pildora != null:
		_pildora.visible = con_trabajo
		if con_trabajo and _jugador != null:
			var pos_ref2 := _bus.position if _en_bus else (_coche.position if _en_coche else _jugador.position)
			var d2 := Vector2(pos_ref2.x - _destino_libre.x, pos_ref2.z - _destino_libre.z).length()
			_pildora_texto.text = str(int(round(d2))) + " m"
	if _btn_bajar != null:
		if _en_bus:
			_btn_bajar.text = "Bajar"
			_btn_bajar.visible = true
			_btn_modo = "bus"
		elif not _bus_pasajero.is_empty():
			_btn_bajar.text = "Bajar del autobús"
			_btn_bajar.visible = true
			_btn_modo = "bajarpas"
		elif not _esp.is_empty() and String(_esp.get("tipo", "")) == "bus" and _bus != null and _jugador != null and _jugador.position.distance_to(_bus.position) < 4.5:
			_btn_bajar.text = "Subir al autobús"
			_btn_bajar.visible = true
			_btn_modo = "bus"
		elif not _esp.is_empty() and String(_esp.get("tipo", "")) == "camalote" and _masa_cercana() != null:
			_btn_bajar.text = "Retirar camalote"
			_btn_bajar.visible = true
			_btn_modo = "camalote"
		elif _pj_cercano() != "":
			_btn_bajar.text = "Hablar con " + String(_pjs[_pj_cercano()]["nombre"])
			_btn_bajar.visible = true
			_btn_modo = "hablar"
		elif _en_coche:
			_btn_bajar.text = "Bajar"
			_btn_bajar.visible = true
			_btn_modo = "coche"
		elif _sentado:
			_btn_bajar.text = "Levantarse"
			_btn_bajar.visible = true
			_btn_modo = "banco"
		elif _jugador != null and _coche != null and _jugador.position.distance_to(_coche.position) < 4.5:
			_btn_bajar.text = "Subir"
			_btn_bajar.visible = true
			_btn_modo = "coche"
		elif _jugador != null and _en_interior == "" and not _bus_linea_cercano().is_empty():
			_btn_bajar.text = "Subir al autobús · 1 €"
			_btn_bajar.visible = true
			_btn_modo = "buspas"
		elif _en_interior != "":
			var acc_i := _accion_interior_cercana()
			if acc_i != "":
				var textos_acc := {"dormir": "Dormir", "pelo": "Cambiar de pelo", "ropa": "Cambiar camiseta", "pan": "Comprar pan (2 €)", "subir": "Subir a la planta alta", "bajar": "Bajar a la planta baja", "comprar:game": "Game: un videojuego (40 €)", "comprar:mediamarkt": "MediaMarkt: auriculares (25 €)", "comprar:eci": "El Corte Inglés: un perfume (30 €)", "comprar:forum": "Forum Sport: zapatillas (45 €)", "comprar:bk": "Burger King: un menú (10 €)", "comprar:cafe": "Cafetería: café con pincho (3 €)", "comprar:quiosco": "Quiosco: una revista (4 €)", "comprar:yelmo": "Yelmo Cines: una entrada (9 €)", "comprar:alehop": "ALE-HOP: un regalo (8 €)", "comprar:fosters": "Foster's: una cena (14 €)", "comprar:dec_bici": "Decathlon: bicicleta de montaña Grajera (450 €)", "comprar:dec_casco": "Decathlon: un casco de ciclismo (35 €)", "comprar:dec_mochila": "Decathlon: una mochila de montaña (40 €)", "comprar:dec_chaqueta": "Decathlon: una chaqueta impermeable (80 €)", "comprar:dec_mancuernas": "Decathlon: unas mancuernas (30 €)", "comprar:dec_zapatillas": "Decathlon: unas zapatillas de trail (65 €)", "comprar:dec_balon": "Decathlon: un balón de fútbol (20 €)", "comprar:dec_raqueta": "Decathlon: una raqueta de pádel (55 €)", "comprar:dec_banador": "Decathlon: bañador y gafas de natación (25 €)", "comprar:dec_tienda": "Decathlon: una tienda de campaña (120 €)"}
				if acc_i.begins_with("comprar:"):
					# En el botón no cabe el texto largo de la
					# tienda: producto sin artículo y precio.
					var tb: Dictionary = _tiendas_mall().get(acc_i.trim_prefix("comprar:"), {})
					if not tb.is_empty():
						var prod := String(tb["producto"])
						for art in ["unas ", "unos ", "una ", "un "]:
							if prod.begins_with(art):
								prod = prod.substr(art.length())
								break
						_btn_bajar.text = prod.substr(0, 1).to_upper() + prod.substr(1) + " · " + str(int(tb["precio"])) + " €"
					else:
						_btn_bajar.text = String(textos_acc.get(acc_i, acc_i))
				else:
					_btn_bajar.text = String(textos_acc.get(acc_i, acc_i))
				_btn_bajar.visible = true
				_btn_modo = acc_i
			else:
				var den2: Vector3 = _interiores[_en_interior]["dentro"]
				if Vector2(_jugador.position.x - den2.x, _jugador.position.z - den2.z).length() < 2.6:
					_btn_bajar.text = "Salir"
					_btn_bajar.visible = true
					_btn_modo = "salir"
				else:
					_btn_bajar.visible = false
		elif _jugador != null and _en_interior == "" and _puerta_cercana() != "":
			var id_p := _puerta_cercana()
			_btn_bajar.text = "Entrar: " + String(_interiores[id_p]["nombre"])
			_btn_bajar.visible = true
			_btn_modo = "puerta:" + id_p
		elif _jugador != null and _lugar_coche_cercano() != "":
			var nombres_l := {"concesionario": "Concesionario", "taller": "Taller", "garaje": "Garaje"}
			var lg2 := _lugar_coche_cercano()
			_btn_bajar.text = String(nombres_l[lg2])
			_btn_bajar.visible = true
			_btn_modo = "lugar:" + lg2
		elif _jugador != null and not _banco_cercano().is_empty():
			_btn_bajar.text = "Sentarse"
			_btn_bajar.visible = true
			_btn_modo = "banco"
		else:
			_btn_bajar.visible = false

func _actualizar_hud_dinero() -> void:
	if _hud_dinero == null:
		return
	_hud_dinero.text = "Día %d · %02d:%02d · %d €" % [_dia, int(_minutos) / 60, int(_minutos) % 60, _dinero]

func _guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("partida", "dinero", _dinero)
	cfg.set_value("partida", "dia", _dia)
	cfg.set_value("partida", "camisa", _camisa_idx)
	cfg.set_value("partida", "pelo", _pelo_idx)
	cfg.set_value("partida", "coches", JSON.stringify(_mis_coches))
	cfg.set_value("partida", "coche_activo", _coche_activo)
	cfg.set_value("partida", "personaje", _personaje)
	cfg.set_value("partida", "empleo", _empleo_desbloqueado)
	cfg.set_value("partida", "historia", _historia_idx)
	cfg.set_value("partida", "carreras", JSON.stringify(_records))
	cfg.save("user://partida.cfg")

func _cargar_partida() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://partida.cfg") == OK:
		_dinero = int(cfg.get_value("partida", "dinero", 60))
		_dia = int(cfg.get_value("partida", "dia", 1))
		_camisa_idx = int(cfg.get_value("partida", "camisa", 0))
		_pelo_idx = int(cfg.get_value("partida", "pelo", 0))
		var cj = cfg.get_value("partida", "coches", "")
		if typeof(cj) == TYPE_STRING and String(cj) != "":
			var parsed = JSON.parse_string(String(cj))
			if typeof(parsed) == TYPE_ARRAY and not (parsed as Array).is_empty():
				_mis_coches = parsed
		_coche_activo = clampi(int(cfg.get_value("partida", "coche_activo", 0)), 0, _mis_coches.size() - 1)
		_personaje = clampi(int(cfg.get_value("partida", "personaje", 0)), 0, 1)
		_empleo_desbloqueado = bool(cfg.get_value("partida", "empleo", false))
		_historia_idx = clampi(int(cfg.get_value("partida", "historia", 0)), 0, 12)
		var cr = cfg.get_value("partida", "carreras", "")
		if typeof(cr) == TYPE_STRING and String(cr) != "":
			var pc = JSON.parse_string(String(cr))
			if typeof(pc) == TYPE_DICTIONARY:
				_records = pc

func _crear_lugares_coches() -> void:
	var defs := [
		["garaje", "Tu garaje", _origen_libre + Vector3(4, 0, 4), Color(0.30, 0.75, 0.40)],
		["concesionario", "Concesionario AutoRioja", Vector3(958.5, 0, 365.0), Color(0.30, 0.60, 1.0)],
		["taller", "Taller Ebro", Vector3(-100, 0, 150), Color(1.0, 0.55, 0.20)],
	]
	for d in defs:
		var p: Vector3 = d[2]
		var nodo := _nodo_cercano(Vector2(p.x, p.z))
		if nodo >= 0:
			var np: Vector2 = _nodos[nodo]
			p = Vector3(np.x, 0, np.y)
		p = _punto_libre(p + Vector3(3.5, 0, 3.5), 0.5)
		p.y = _altura(p.x, p.z)
		_lugares_coches[d[0]] = p
		var col: Color = d[3]
		_marcador(p, col, true, 0.6, true)
		var et := Label3D.new()
		et.text = String(d[1])
		et.font_size = 96
		et.pixel_size = 0.012
		et.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		et.modulate = col
		et.outline_size = 10
		et.outline_modulate = Color(0.05, 0.05, 0.08)
		et.position = p + Vector3(0, 6.5, 0)
		add_child(et)
	print("LUGARES_COCHES_OK n=", _lugares_coches.size())

func _lugar_coche_cercano() -> String:
	if _jugador == null:
		return ""
	for k in _lugares_coches:
		var p: Vector3 = _lugares_coches[k]
		if Vector2(_jugador.position.x - p.x, _jugador.position.z - p.z).length() < 5.5:
			return String(k)
	return ""

func _registrar_rect(centro: Vector3, local: Vector2, tam: Vector2) -> void:
	var x0 := centro.x + local.x - tam.x / 2.0
	var x1 := centro.x + local.x + tam.x / 2.0
	var z0 := centro.z + local.y - tam.y / 2.0
	var z1 := centro.z + local.y + tam.y / 2.0
	_registrar_poly(PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]))

func _mueble(v: PackedVector3Array, n: PackedVector3Array, c: PackedColorArray,
		centro: Vector3, local: Vector3, tam: Vector3, color: Color, colision := true) -> void:
	_caja_en(v, n, c, centro + local, tam, color, 0.0)
	if colision:
		_registrar_rect(centro, Vector2(local.x, local.z), Vector2(tam.x, tam.z))

func _crear_interiores() -> void:
	var defs := [
		["piso", "Tu piso", _origen_libre + Vector3(-3, 0, 5), Color(0.95, 0.80, 0.35), Vector2(16, 12), Color(0.52, 0.40, 0.28), Color(0.88, 0.84, 0.78)],
		["ayuntamiento", "Ayuntamiento", Vector3(261, 0, 64), Color(0.85, 0.85, 0.90), Vector2(18, 12), Color(0.62, 0.62, 0.65), Color(0.85, 0.82, 0.75)],
		["gimnasio", "Gimnasio", Vector3(880, 0, 430), Color(0.40, 0.80, 0.90), Vector2(16, 12), Color(0.35, 0.42, 0.52), Color(0.80, 0.82, 0.85)],
		["peluqueria", "Peluquería", Vector3(-160, 0, 90), Color(0.95, 0.55, 0.75), Vector2(12, 10), Color(0.70, 0.68, 0.72), Color(0.90, 0.85, 0.88)],
		["tienda", "Tienda de ropa", Vector3(-60, 0, 300), Color(0.65, 0.85, 0.45), Vector2(14, 11), Color(0.60, 0.52, 0.42), Color(0.88, 0.86, 0.80)],
		["panaderia", "Panadería", Vector3(-190, 0, 130), Color(0.95, 0.70, 0.40), Vector2(12, 10), Color(0.72, 0.62, 0.48), Color(0.92, 0.86, 0.76)],
		["decathlon", "Decathlon", Vector3(-2487, 0, 1564), Color(0.10, 0.30, 0.75), Vector2(26, 18), Color(0.62, 0.64, 0.68), Color(0.85, 0.88, 0.92)],
	]
	for i in defs.size():
		var d: Array = defs[i]
		var id := String(d[0])
		var centro := Vector3(4000 + i * 40, 0, 5000)
		var tam: Vector2 = d[4]
		var v := PackedVector3Array()
		var n := PackedVector3Array()
		var c := PackedColorArray()
		var suelo_c: Color = d[5]
		var pared: Color = d[6]
		_caja_en(v, n, c, centro + Vector3(0, -0.06, 0), Vector3(tam.x + 1.4, 0.12, tam.y + 1.4), suelo_c, 0.0)
		var hx := tam.x / 2.0
		var hz := tam.y / 2.0
		_caja_en(v, n, c, centro + Vector3(0, 1.3, -hz), Vector3(tam.x + 0.3, 2.6, 0.3), pared, 0.0)
		_caja_en(v, n, c, centro + Vector3(-hx, 1.3, 0), Vector3(0.3, 2.6, tam.y), pared, 0.0)
		_caja_en(v, n, c, centro + Vector3(hx, 1.3, 0), Vector3(0.3, 2.6, tam.y), pared, 0.0)
		var tramo := hx - 0.7
		_caja_en(v, n, c, centro + Vector3(-(0.7 + tramo / 2.0), 1.3, hz), Vector3(tramo, 2.6, 0.3), pared, 0.0)
		_caja_en(v, n, c, centro + Vector3(0.7 + tramo / 2.0, 1.3, hz), Vector3(tramo, 2.6, 0.3), pared, 0.0)
		_registrar_rect(centro, Vector2(0, -hz), Vector2(tam.x + 0.3, 0.3))
		_registrar_rect(centro, Vector2(-hx, 0), Vector2(0.3, tam.y))
		_registrar_rect(centro, Vector2(hx, 0), Vector2(0.3, tam.y))
		_registrar_rect(centro, Vector2(-(0.7 + tramo / 2.0), hz), Vector2(tramo, 0.3))
		_registrar_rect(centro, Vector2(0.7 + tramo / 2.0, hz), Vector2(tramo, 0.3))
		var acciones := {}
		match id:
			"piso":
				_mueble(v, n, c, centro, Vector3(-6.2, 0.23, -3.8), Vector3(2.0, 0.45, 1.5), Color(0.75, 0.78, 0.85))
				_mueble(v, n, c, centro, Vector3(-6.2, 0.53, -4.35), Vector3(0.7, 0.14, 0.35), Color(0.95, 0.95, 0.95), false)
				_mueble(v, n, c, centro, Vector3(-6.2, 0.50, -3.35), Vector3(2.0, 0.10, 0.85), Color(0.65, 0.30, 0.25), false)
				_mueble(v, n, c, centro, Vector3(4.6, 0.38, -4.5), Vector3(2.4, 0.75, 1.0), Color(0.45, 0.35, 0.55))
				_mueble(v, n, c, centro, Vector3(4.6, 0.95, -4.95), Vector3(2.4, 0.45, 0.2), Color(0.45, 0.35, 0.55), false)
				_mueble(v, n, c, centro, Vector3(7.55, 0.23, -4.5), Vector3(0.45, 0.45, 1.7), Color(0.45, 0.33, 0.22))
				_mueble(v, n, c, centro, Vector3(7.5, 1.05, -4.5), Vector3(0.07, 0.8, 1.35), Color(0.05, 0.05, 0.08), false)
				_mueble(v, n, c, centro, Vector3(0.5, 0.37, -1.2), Vector3(1.5, 0.74, 0.9), Color(0.45, 0.33, 0.22))
				_mueble(v, n, c, centro, Vector3(-7.55, 0.45, 1.2), Vector3(0.7, 0.9, 3.4), Color(0.80, 0.80, 0.82))
				_mueble(v, n, c, centro, Vector3(-7.5, 0.9, 3.9), Vector3(0.8, 1.8, 0.8), Color(0.85, 0.87, 0.90))
				acciones["dormir"] = centro + Vector3(-6.2, 0, -2.1)
			"ayuntamiento":
				_mueble(v, n, c, centro, Vector3(0, 0.53, -1.2), Vector3(5.0, 1.05, 0.8), Color(0.45, 0.32, 0.20))
				_mueble(v, n, c, centro, Vector3(0, 1.09, -1.2), Vector3(5.2, 0.06, 0.95), Color(0.55, 0.40, 0.25), false)
				_mueble(v, n, c, centro, Vector3(-5.5, 0.38, -4.2), Vector3(1.6, 0.75, 0.9), Color(0.50, 0.38, 0.26))
				_mueble(v, n, c, centro, Vector3(5.5, 0.38, -4.2), Vector3(1.6, 0.75, 0.9), Color(0.50, 0.38, 0.26))
				_mueble(v, n, c, centro, Vector3(-4.5, 0.25, 3.6), Vector3(2.6, 0.5, 0.6), Color(0.40, 0.45, 0.55))
				_mueble(v, n, c, centro, Vector3(4.5, 0.25, 3.6), Vector3(2.6, 0.5, 0.6), Color(0.40, 0.45, 0.55))
				for sx3 in [-8.3, 8.3]:
					_mueble(v, n, c, centro, Vector3(sx3, 0.25, 5.2), Vector3(0.45, 0.5, 0.45), Color(0.40, 0.28, 0.18), false)
					_bola_en(v, n, c, centro + Vector3(sx3, 1.0, 5.2), 0.45, Color(0.25, 0.45, 0.25), sx3, 0.9)
			"gimnasio":
				for gx in [-5.0, -2.6, -0.2]:
					_mueble(v, n, c, centro, Vector3(gx, 0.23, -4.2), Vector3(0.9, 0.45, 1.9), Color(0.25, 0.26, 0.30))
					_mueble(v, n, c, centro, Vector3(gx, 0.95, -5.05), Vector3(0.9, 0.55, 0.14), Color(0.35, 0.37, 0.42), false)
				_mueble(v, n, c, centro, Vector3(4.6, 0.22, -4.2), Vector3(1.9, 0.44, 0.5), Color(0.30, 0.30, 0.33))
				_mueble(v, n, c, centro, Vector3(7.55, 0.55, 0.6), Vector3(0.5, 1.1, 2.4), Color(0.35, 0.35, 0.38))
				_mueble(v, n, c, centro, Vector3(-3.5, 0.04, 2.6), Vector3(1.8, 0.07, 0.7), Color(0.85, 0.45, 0.30), false)
				_mueble(v, n, c, centro, Vector3(-1.2, 0.04, 2.6), Vector3(1.8, 0.07, 0.7), Color(0.35, 0.55, 0.85), false)
				_mueble(v, n, c, centro, Vector3(1.1, 0.04, 2.6), Vector3(1.8, 0.07, 0.7), Color(0.40, 0.65, 0.40), false)
			"peluqueria":
				for px in [-2.2, 0.8]:
					_mueble(v, n, c, centro, Vector3(px, 0.28, -3.0), Vector3(0.65, 0.55, 0.65), Color(0.30, 0.30, 0.35))
					_mueble(v, n, c, centro, Vector3(px, 0.75, -3.38), Vector3(0.65, 0.65, 0.14), Color(0.30, 0.30, 0.35), false)
					_mueble(v, n, c, centro, Vector3(px, 1.45, -4.92), Vector3(1.0, 1.1, 0.05), Color(0.78, 0.86, 0.92), false)
					_mueble(v, n, c, centro, Vector3(px, 0.45, -4.55), Vector3(1.3, 0.9, 0.35), Color(0.85, 0.83, 0.80))
				_mueble(v, n, c, centro, Vector3(4.2, 0.48, 3.4), Vector3(1.8, 0.95, 0.6), Color(0.55, 0.42, 0.30))
				acciones["pelo"] = centro + Vector3(-2.2, 0, -1.9)
			"tienda":
				var cols_ropa := [Color(0.75, 0.30, 0.25), Color(0.16, 0.38, 0.62), Color(0.20, 0.55, 0.35), Color(0.85, 0.65, 0.20), Color(0.80, 0.45, 0.60), Color(0.50, 0.30, 0.60)]
				var k_r := 0
				for rx in [-4.2, 0.0, 4.2]:
					var rz := -2.7 if rx == 0.0 else -2.4
					_mueble(v, n, c, centro, Vector3(rx, 1.55, rz), Vector3(1.8, 0.07, 0.07), Color(0.60, 0.60, 0.62), false)
					for dx_r in [-0.55, 0.0, 0.55]:
						_mueble(v, n, c, centro, Vector3(rx + dx_r, 1.05, rz), Vector3(0.45, 0.95, 0.28), cols_ropa[k_r % cols_ropa.size()], false)
						k_r += 1
					_registrar_rect(centro, Vector2(rx, rz), Vector2(1.8, 0.4))
				_mueble(v, n, c, centro, Vector3(5.2, 0.48, 3.2), Vector3(2.0, 0.95, 0.7), Color(0.50, 0.38, 0.26))
				acciones["ropa"] = centro + Vector3(0, 0, -1.5)
			"panaderia":
				_mueble(v, n, c, centro, Vector3(0, 0.5, -2.6), Vector3(3.4, 1.0, 0.75), Color(0.60, 0.45, 0.30))
				_mueble(v, n, c, centro, Vector3(0, 1.20, -2.6), Vector3(3.2, 0.38, 0.6), Color(0.80, 0.88, 0.90), false)
				for bx in [-1.2, -0.4, 0.4, 1.2]:
					_mueble(v, n, c, centro, Vector3(bx, 1.06, -2.15), Vector3(0.42, 0.15, 0.3), Color(0.85, 0.65, 0.38), false)
				_mueble(v, n, c, centro, Vector3(-4.9, 0.75, -4.2), Vector3(1.6, 1.5, 0.9), Color(0.30, 0.28, 0.30))
				_mueble(v, n, c, centro, Vector3(5.55, 0.8, -0.8), Vector3(0.5, 1.6, 2.4), Color(0.55, 0.42, 0.28))
				acciones["pan"] = centro + Vector3(0, 0, -1.4)
			"decathlon":
				# La nave de Decathlon (pedido de Jon): pasillos de
				# góndolas por secciones, las bicis en exposición,
				# balones, la tienda de campaña montada y caja. Cada
				# producto tiene su punto de compra: al acercarte se
				# ve el precio y con E lo compras.
				var col_gond := Color(0.25, 0.30, 0.45)
				var secciones := [
					[Vector2(-5.5, -2.8), Color(0.20, 0.55, 0.30)],
					[Vector2(5.5, -2.8), Color(0.90, 0.50, 0.15)],
					[Vector2(-5.5, 3.0), Color(0.80, 0.25, 0.20)],
					[Vector2(5.5, 3.0), Color(0.15, 0.45, 0.70)],
				]
				for sec in secciones:
					var gp: Vector2 = sec[0]
					var col_s: Color = sec[1]
					_mueble(v, n, c, centro, Vector3(gp.x, 0.52, gp.y), Vector3(5.6, 1.05, 0.9), col_gond)
					_mueble(v, n, c, centro, Vector3(gp.x, 1.85, gp.y), Vector3(5.6, 0.35, 0.95), col_s, false)
					for dpx in [-2.25, -1.35, -0.45, 0.45, 1.35, 2.25]:
						_mueble(v, n, c, centro, Vector3(gp.x + dpx, 1.32, gp.y), Vector3(0.6, 0.5, 0.62), col_s.lightened(0.25 + 0.1 * (int(dpx * 10) % 3)), false)
				# Bicis en exposición contra la pared oeste
				var cols_bici := [Color(0.85, 0.45, 0.10), Color(0.10, 0.55, 0.50), Color(0.80, 0.20, 0.18)]
				for bi in 3:
					var bici_d := _modelo_mtb(cols_bici[bi]) if bi == 0 else _modelo_bici(cols_bici[bi])
					bici_d.position = centro + Vector3(-11.3, 0, -5.6 + bi * 2.1)
					bici_d.rotation.y = 0.22
					add_child(bici_d)
				_registrar_rect(centro, Vector2(-11.3, -3.5), Vector2(1.1, 6.4))
				# Cascos en su expositor
				_mueble(v, n, c, centro, Vector3(-11.3, 0.45, -7.9), Vector3(1.7, 0.9, 0.5), col_gond)
				for dpx2 in [-0.55, 0.0, 0.55]:
					_bola_en(v, n, c, centro + Vector3(-11.3 + dpx2, 1.08, -7.9), 0.17, cols_bici[int(abs(dpx2 * 10)) % 3], dpx2 * 7.0, 0.9)
				# Balones en su cesta
				_mueble(v, n, c, centro, Vector3(-5.5, 0.30, 4.75), Vector3(1.9, 0.6, 0.7), Color(0.35, 0.36, 0.40))
				_bola_en(v, n, c, centro + Vector3(-6.1, 0.78, 4.75), 0.19, Color(0.93, 0.93, 0.93), 3.1)
				_bola_en(v, n, c, centro + Vector3(-5.5, 0.78, 4.75), 0.19, Color(0.90, 0.50, 0.15), 5.7)
				_bola_en(v, n, c, centro + Vector3(-4.9, 0.78, 4.75), 0.19, Color(0.90, 0.80, 0.20), 8.3)
				# La tienda de campaña, montada en su rincón
				_mueble(v, n, c, centro, Vector3(10.8, 0.03, 6.2), Vector3(2.6, 0.06, 2.2), Color(0.30, 0.32, 0.36), false)
				for lado_t in [-1.0, 1.0]:
					var panel := _pieza(Vector3(2.4, 0.06, 2.0), Vector3.ZERO, Color(0.20, 0.50, 0.30))
					panel.position = centro + Vector3(10.8 + lado_t * 0.52, 0.62, 6.2)
					panel.rotation.z = lado_t * 0.68
					add_child(panel)
				_registrar_rect(centro, Vector2(10.8, 6.2), Vector2(2.4, 2.1))
				# Caja y mostrador junto a la puerta
				_mueble(v, n, c, centro, Vector3(0, 0.5, 6.6), Vector3(3.6, 1.0, 0.8), Color(0.15, 0.25, 0.50))
				_mueble(v, n, c, centro, Vector3(0, 1.04, 6.6), Vector3(3.8, 0.07, 0.95), Color(0.85, 0.86, 0.88), false)
				acciones["comprar:dec_bici"] = centro + Vector3(-9.7, 0, -3.5)
				acciones["comprar:dec_casco"] = centro + Vector3(-10.0, 0, -7.6)
				acciones["comprar:dec_mochila"] = centro + Vector3(-6.9, 0, -1.5)
				acciones["comprar:dec_chaqueta"] = centro + Vector3(-4.1, 0, -1.5)
				acciones["comprar:dec_mancuernas"] = centro + Vector3(4.1, 0, -1.5)
				acciones["comprar:dec_zapatillas"] = centro + Vector3(6.9, 0, -1.5)
				acciones["comprar:dec_balon"] = centro + Vector3(-6.9, 0, 4.35)
				acciones["comprar:dec_raqueta"] = centro + Vector3(-4.1, 0, 4.35)
				acciones["comprar:dec_banador"] = centro + Vector3(6.9, 0, 4.35)
				acciones["comprar:dec_tienda"] = centro + Vector3(9.1, 0, 4.9)
		var nodo_s := Node3D.new()
		nodo_s.add_child(_malla_de(v, n, c, Color.WHITE))
		add_child(nodo_s)
		var fuera: Vector3 = d[2]
		var nodo_g := _nodo_cercano(Vector2(fuera.x, fuera.z))
		if nodo_g >= 0:
			var np: Vector2 = _nodos[nodo_g]
			fuera = Vector3(np.x, 0, np.y)
		fuera = _punto_libre(fuera + Vector3(3.0, 0, 3.0), 0.5)
		if id == "decathlon":
			# La puerta de verdad es la del frente de marca, que
			# mira al aparcamiento (al este). El ajuste al grafo
			# dejaba la entrada a casi 40 m, dentro de la nave, y
			# Jon no podía entrar estando en la puerta.
			fuera = _punto_libre(Vector3(-2455.0, 0, 1564.0), 0.5)
		fuera.y = _altura_terreno(fuera.x, fuera.z)
		var col_ext: Color = d[3]
		_marcador(fuera, col_ext, true, 0.6, true)
		var et := Label3D.new()
		et.text = String(d[1])
		et.font_size = 96
		et.pixel_size = 0.012
		et.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		et.modulate = col_ext
		et.outline_size = 10
		et.outline_modulate = Color(0.05, 0.05, 0.08)
		et.position = fuera + Vector3(0, 6.5, 0)
		add_child(et)
		_interiores[id] = {"nombre": String(d[1]), "fuera": fuera, "dentro": centro + Vector3(0, 0, hz - 1.7), "centro": centro, "tam": tam, "acciones": acciones}
		if id == "gimnasio":
			_interiores[id]["estaciones"] = [
				{"n": "la cinta", "p": centro + Vector3(-2.6, 0, -2.6)},
				{"n": "el banco de press", "p": centro + Vector3(4.6, 0, -2.8)},
				{"n": "las pesas", "p": centro + Vector3(6.2, 0, 0.6)},
				{"n": "la esterilla", "p": centro + Vector3(-1.2, 0, 1.2)}]
	# Tenderos: las tiendas tienen quien atienda tras el mostrador o
	# junto a la mercancía, y ofrece lo suyo por diálogo al acercarte.
	var tenderos_def := {
		"panaderia": [Vector3(0, 0, -3.7), Color(0.93, 0.91, 0.87), Color(0.30, 0.28, 0.30), Color(0.35, 0.22, 0.12), true],
		"peluqueria": [Vector3(-3.6, 0, -2.2), Color(0.25, 0.45, 0.55), Color(0.25, 0.25, 0.30), Color(0.15, 0.12, 0.10), false],
		"tienda": [Vector3(1.9, 0, -2.9), Color(0.80, 0.45, 0.60), Color(0.25, 0.25, 0.30), Color(0.75, 0.55, 0.25), true],
		"decathlon": [Vector3(2.3, 0, 7.1), Color(0.15, 0.35, 0.75), Color(0.22, 0.22, 0.26), Color(0.25, 0.17, 0.12), false]}
	for id_t in tenderos_def:
		var td: Array = tenderos_def[id_t]
		var per_t := _hacer_persona(td[1], td[2], td[3], false, bool(td[4]))
		var raiz_t: Node3D = per_t["raiz"]
		raiz_t.position = (_interiores[id_t]["centro"] as Vector3) + (td[0] as Vector3) + Vector3(0, 0.95, 0)
		add_child(raiz_t)
		_interiores[id_t]["tendero"] = raiz_t
		_interiores[id_t]["tendero_d"] = per_t
		_tenderos.append(raiz_t)
	_crear_mall()
	print("INTERIORES_OK salas=", _interiores.size())

func _tiendas_mall() -> Dictionary:
	return {
		"eci": {"nombre": "El Corte Inglés", "producto": "un perfume", "precio": 30, "color": Color(0.10, 0.35, 0.25)},
		"mediamarkt": {"nombre": "MediaMarkt", "producto": "unos auriculares", "precio": 25, "color": Color(0.80, 0.10, 0.15)},
		"forum": {"nombre": "Forum Sport", "producto": "unas zapatillas", "precio": 45, "color": Color(0.15, 0.40, 0.75)},
		"game": {"nombre": "Game", "producto": "un videojuego", "precio": 40, "color": Color(0.85, 0.20, 0.20)},
		"bk": {"nombre": "Burger King", "producto": "un menú Whopper", "precio": 10, "color": Color(0.90, 0.55, 0.10)},
		"cafe": {"nombre": "Cafetería", "producto": "un café con pincho", "precio": 3, "color": Color(0.55, 0.35, 0.20)},
		"quiosco": {"nombre": "Quiosco", "producto": "una revista", "precio": 4, "color": Color(0.30, 0.55, 0.60)},
		"yelmo": {"nombre": "Yelmo Cines", "producto": "una entrada de cine", "precio": 9, "color": Color(0.15, 0.15, 0.45), "cine": true},
		"alehop": {"nombre": "ALE-HOP", "producto": "un regalo", "precio": 8, "color": Color(0.95, 0.55, 0.10)},
		"fosters": {"nombre": "Foster's Hollywood", "producto": "una cena", "precio": 14, "color": Color(0.60, 0.15, 0.15)},
		"dec_bici": {"nombre": "Decathlon", "producto": "la bicicleta de montaña Grajera", "precio": 450, "color": Color(0.10, 0.30, 0.75)},
		"dec_casco": {"nombre": "Decathlon", "producto": "un casco de ciclismo", "precio": 35, "color": Color(0.10, 0.30, 0.75)},
		"dec_mochila": {"nombre": "Decathlon", "producto": "una mochila de montaña de 30 L", "precio": 40, "color": Color(0.10, 0.30, 0.75)},
		"dec_chaqueta": {"nombre": "Decathlon", "producto": "una chaqueta impermeable", "precio": 80, "color": Color(0.10, 0.30, 0.75)},
		"dec_mancuernas": {"nombre": "Decathlon", "producto": "un juego de mancuernas", "precio": 30, "color": Color(0.10, 0.30, 0.75)},
		"dec_zapatillas": {"nombre": "Decathlon", "producto": "unas zapatillas de trail", "precio": 65, "color": Color(0.10, 0.30, 0.75)},
		"dec_balon": {"nombre": "Decathlon", "producto": "un balón de fútbol", "precio": 20, "color": Color(0.10, 0.30, 0.75)},
		"dec_raqueta": {"nombre": "Decathlon", "producto": "una raqueta de pádel", "precio": 55, "color": Color(0.10, 0.30, 0.75)},
		"dec_banador": {"nombre": "Decathlon", "producto": "un bañador y unas gafas de natación", "precio": 25, "color": Color(0.10, 0.30, 0.75)},
		"dec_tienda": {"nombre": "Decathlon", "producto": "una tienda de campaña", "precio": 120, "color": Color(0.10, 0.30, 0.75)},
	}

func _comprar_tienda(clave: String) -> void:
	var tiendas := _tiendas_mall()
	if not tiendas.has(clave):
		return
	var t: Dictionary = tiendas[clave]
	var precio := int(t["precio"])
	if _dinero < precio:
		_aviso_set("No te llega: %s cuesta %d €" % [String(t["producto"]), precio], 3.5)
		return
	_dinero -= precio
	if clave == "dec_bici":
		# La Grajera comprada en Decathlon entra en el garaje de
		# verdad, como la del concesionario.
		_mis_coches.append({"id": 13, "danio": 0, "motor": 0, "frenos": 0})
		_aviso_set("Has comprado la bicicleta de montaña Grajera: ya está en tu garaje", 4.0)
		_sonar("cobro")
		_actualizar_hud_dinero()
		_guardar()
		print("MALL_COMPRA_OK ", clave, " dinero=", _dinero, " garaje=", _mis_coches.size())
		return
	if bool(t.get("cine", false)):
		_minutos += 110.0
		if _minutos >= 1440.0:
			_minutos -= 1440.0
			_dia += 1
		_aviso_set("Yelmo Cines: has visto la película. ¡Dos horas que han volado!", 4.0)
	else:
		_aviso_set("Has comprado %s en %s" % [String(t["producto"]), String(t["nombre"])], 3.5)
	# Lo comprado se lleva encima (E4): el balón bajo el brazo
	# y lo demás en una bolsa en la mano. La comida y el cine
	# se disfrutan allí mismo, sin bolsa.
	if clave == "dec_balon":
		_balon_en_mano = true
		_refrescar_pan()
	elif clave in ["game", "mediamarkt", "eci", "forum", "alehop", "dec_casco", "dec_mochila", "dec_chaqueta", "dec_mancuernas", "dec_zapatillas", "dec_raqueta", "dec_banador", "dec_tienda"]:
		_bolsa_en_mano = true
		_refrescar_pan()
	_sonar("cobro")
	_actualizar_hud_dinero()
	_guardar()
	print("MALL_COMPRA_OK ", clave, " dinero=", _dinero)

func _cambiar_planta(arriba: bool) -> void:
	if arriba:
		_en_interior = "berceo1"
		_jugador.position = (_interiores["berceo1"]["dentro"] as Vector3) + Vector3(0, 0.95, 0)
	else:
		_en_interior = "berceo"
		_jugador.position = (_interiores["berceo"]["escalera"] as Vector3) + Vector3(0, 0.95, 0)
	_dir_jugador = -PI / 2.0
	_jugador.rotation.y = _dir_jugador
	_sonar("puerta_abrir")
	print("MALL_PLANTA ", _en_interior)

func _paredes_mall(v: PackedVector3Array, n: PackedVector3Array, c: PackedColorArray, centro: Vector3, tam: Vector2, con_puerta: bool) -> void:
	var hx := tam.x / 2.0
	var hz := tam.y / 2.0
	var pared := Color(0.90, 0.88, 0.84)
	_caja_en(v, n, c, centro + Vector3(0, -0.06, 0), Vector3(tam.x + 1.4, 0.12, tam.y + 1.4), Color(0.78, 0.76, 0.72), 0.0)
	for fx in range(-4, 5):
		_caja_en(v, n, c, centro + Vector3(float(fx) * 10.0, 0.006, 0), Vector3(0.18, 0.012, tam.y), Color(0.68, 0.66, 0.62), 0.0)
	_caja_en(v, n, c, centro + Vector3(0, 1.7, -hz), Vector3(tam.x + 0.3, 3.4, 0.3), pared, 0.0)
	_caja_en(v, n, c, centro + Vector3(-hx, 1.7, 0), Vector3(0.3, 3.4, tam.y), pared, 0.0)
	_caja_en(v, n, c, centro + Vector3(hx, 1.7, 0), Vector3(0.3, 3.4, tam.y), pared, 0.0)
	if con_puerta:
		var tramo := hx - 3.5
		_caja_en(v, n, c, centro + Vector3(-(3.5 + tramo / 2.0), 1.7, hz), Vector3(tramo, 3.4, 0.3), pared, 0.0)
		_caja_en(v, n, c, centro + Vector3(3.5 + tramo / 2.0, 1.7, hz), Vector3(tramo, 3.4, 0.3), pared, 0.0)
		_caja_en(v, n, c, centro + Vector3(0, 3.05, hz), Vector3(7.0, 0.7, 0.3), pared, 0.0)
		_registrar_rect(centro, Vector2(-(3.5 + tramo / 2.0), hz), Vector2(tramo, 0.3))
		_registrar_rect(centro, Vector2(3.5 + tramo / 2.0, hz), Vector2(tramo, 0.3))
	else:
		_caja_en(v, n, c, centro + Vector3(0, 1.7, hz), Vector3(tam.x + 0.3, 3.4, 0.3), pared, 0.0)
		_registrar_rect(centro, Vector2(0, hz), Vector2(tam.x + 0.3, 0.3))
	_registrar_rect(centro, Vector2(0, -hz), Vector2(tam.x + 0.3, 0.3))
	_registrar_rect(centro, Vector2(-hx, 0), Vector2(0.3, tam.y))
	_registrar_rect(centro, Vector2(hx, 0), Vector2(0.3, tam.y))

func _local_mall(v: PackedVector3Array, n: PackedVector3Array, c: PackedColorArray, centro: Vector3, x: float, lado: float, ancho: float, clave: String, acciones: Dictionary) -> void:
	# Un local del centro comercial: tabiques, mostrador, banda con el
	# nombre, estanterías, dependiente y punto de compra delante.
	var td: Dictionary = _tiendas_mall()[clave]
	var col_t: Color = td["color"]
	var zf := lado * 16.2
	var zd := lado * 19.0
	var pared := Color(0.88, 0.86, 0.82)
	for s in [-1.0, 1.0]:
		_mueble(v, n, c, centro, Vector3(x + s * ancho / 2.0, 1.7, lado * 19.0), Vector3(0.25, 3.4, 5.6), pared)
	_mueble(v, n, c, centro, Vector3(x, 0.5, zf), Vector3(ancho - 0.6, 1.0, 0.8), Color(0.45, 0.38, 0.30))
	_mueble(v, n, c, centro, Vector3(x, 1.04, zf), Vector3(ancho - 0.4, 0.07, 0.95), Color(0.60, 0.50, 0.38), false)
	_mueble(v, n, c, centro, Vector3(x, 2.6, zf - lado * 0.3), Vector3(ancho - 0.4, 0.95, 0.22), col_t, false)
	var et := Label3D.new()
	et.text = String(td["nombre"])
	et.font_size = 96
	et.pixel_size = 0.016
	et.modulate = Color(1, 1, 1)
	et.outline_size = 8
	et.outline_modulate = Color(0.05, 0.05, 0.08)
	et.position = centro + Vector3(x, 2.6, zf - lado * 0.55)
	et.rotation.y = 0.0 if lado < 0.0 else PI
	add_child(et)
	for dx in [-ancho / 4.0, ancho / 4.0]:
		_mueble(v, n, c, centro, Vector3(x + dx, 0.9, zd + lado * 1.6), Vector3(ancho / 2.6, 1.8, 0.7), Color(0.70, 0.66, 0.60))
	var per := _hacer_persona(col_t, Color(0.25, 0.25, 0.30), Color(0.30, 0.20, 0.12), false, false)
	var raiz: Node3D = per["raiz"]
	raiz.position = centro + Vector3(x + ancho / 4.0, 0.95, (zf + zd) / 2.0)
	raiz.rotation.y = 0.0 if lado < 0.0 else PI
	add_child(raiz)
	_estaticos.append({"d": per, "raiz": raiz, "tipo": "espera", "fase": randf() * 6.0})
	acciones["comprar:" + clave] = centro + Vector3(x, 0, zf - lado * 2.0)

func _escaleras_mall(v: PackedVector3Array, n: PackedVector3Array, c: PackedColorArray, centro: Vector3, x0: float, z0: float) -> void:
	var col_e := Color(0.62, 0.60, 0.58)
	for i in range(9):
		var alt := (float(i) + 1.0) * 0.47
		_caja_en(v, n, c, centro + Vector3(x0 + float(i) * 1.15 + 0.575, alt / 2.0, z0), Vector3(1.15, alt, 4.4), col_e, 0.0)
	_caja_en(v, n, c, centro + Vector3(x0 + 12.5, 4.23 - 0.15, z0), Vector3(4.6, 0.3, 4.4), col_e, 0.0)
	_registrar_rect(centro, Vector2(x0 + 7.3, z0), Vector2(15.2, 4.4))

func _crear_mall() -> void:
	# El Centro Comercial Berceo por dentro: dos plantas (dos salas
	# comunicadas por las escaleras) con las tiendas de verdad del
	# centro y cosas que comprar en cada una.
	var tam := Vector2(96, 44)
	# ---------- planta baja ----------
	var c0 := Vector3(4340, 0, 5000)
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	_paredes_mall(v, n, c, c0, tam, true)
	var acc0 := {}
	_local_mall(v, n, c, c0, -36, -1.0, 20, "eci", acc0)
	_local_mall(v, n, c, c0, -19, -1.0, 12, "mediamarkt", acc0)
	_local_mall(v, n, c, c0, -7, -1.0, 10, "forum", acc0)
	_local_mall(v, n, c, c0, 3, -1.0, 10, "game", acc0)
	_local_mall(v, n, c, c0, -30, 1.0, 12, "bk", acc0)
	_local_mall(v, n, c, c0, -16, 1.0, 10, "cafe", acc0)
	_local_mall(v, n, c, c0, 12, 1.0, 10, "quiosco", acc0)
	_escaleras_mall(v, n, c, c0, 30, -6)
	acc0["subir"] = c0 + Vector3(28.2, 0, -6)
	for ix in [-12.0, 10.0]:
		_mueble(v, n, c, c0, Vector3(ix, 0.25, 0), Vector3(3.2, 0.5, 0.9), Color(0.45, 0.33, 0.22))
		_mueble(v, n, c, c0, Vector3(ix - 1.1, 0.85, 0), Vector3(0.8, 0.7, 0.8), Color(0.25, 0.45, 0.25), false)
		_mueble(v, n, c, c0, Vector3(ix + 1.1, 0.85, 0), Vector3(0.8, 0.7, 0.8), Color(0.25, 0.45, 0.25), false)
	var nodo0 := Node3D.new()
	nodo0.add_child(_malla_de(v, n, c, Color.WHITE))
	add_child(nodo0)
	var fuera := _punto_libre(Vector3(1858, 0, 548), 0.5)
	fuera.y = _altura_terreno(fuera.x, fuera.z)
	_marcador(fuera, Color(0.30, 0.55, 0.95), true, 0.6, true)
	_interiores["berceo"] = {"nombre": "Centro Comercial Berceo", "fuera": fuera, "dentro": c0 + Vector3(0, 0, 19.8), "centro": c0, "tam": tam, "acciones": acc0, "escalera": c0 + Vector3(26.5, 0, -6)}
	# ---------- planta alta ----------
	var c1 := Vector3(4520, 0, 5000)
	var v1 := PackedVector3Array()
	var n1 := PackedVector3Array()
	var c1a := PackedColorArray()
	_paredes_mall(v1, n1, c1a, c1, tam, false)
	var acc1 := {}
	_local_mall(v1, n1, c1a, c1, -32, -1.0, 18, "yelmo", acc1)
	_local_mall(v1, n1, c1a, c1, -8, -1.0, 10, "alehop", acc1)
	_local_mall(v1, n1, c1a, c1, 8, -1.0, 14, "fosters", acc1)
	_escaleras_mall(v1, n1, c1a, c1, 30, -6)
	acc1["bajar"] = c1 + Vector3(28.2, 0, -6)
	# La sala de cine: caja oscura con pantalla y butacas, delante
	# del local de Yelmo, con la entrada por el lado sur.
	var oscuro := Color(0.10, 0.10, 0.13)
	_mueble(v1, n1, c1a, c1, Vector3(-32, 1.6, -15.0), Vector3(18.0, 3.2, 0.3), oscuro)
	_mueble(v1, n1, c1a, c1, Vector3(-41.0, 1.6, -10.0), Vector3(0.3, 3.2, 10.0), oscuro)
	_mueble(v1, n1, c1a, c1, Vector3(-23.0, 1.6, -10.0), Vector3(0.3, 3.2, 10.0), oscuro)
	_mueble(v1, n1, c1a, c1, Vector3(-37.2, 1.6, -5.0), Vector3(7.6, 3.2, 0.3), oscuro)
	_mueble(v1, n1, c1a, c1, Vector3(-26.8, 1.6, -5.0), Vector3(7.6, 3.2, 0.3), oscuro)
	_mueble(v1, n1, c1a, c1, Vector3(-32, 1.9, -14.7), Vector3(11.0, 2.6, 0.15), Color(0.85, 0.90, 0.95), false)
	for fila in range(3):
		for bx in range(5):
			_mueble(v1, n1, c1a, c1, Vector3(-38.5 + float(bx) * 3.2, 0.45, -8.0 - float(fila) * 2.2), Vector3(0.62, 0.9, 0.62), Color(0.45, 0.12, 0.15), false)
	# Mesas de la zona de comidas, al sur de la planta alta
	for tx2 in [-24.0, -12.0, 0.0, 12.0]:
		_mueble(v1, n1, c1a, c1, Vector3(tx2, 0.38, 12.0), Vector3(1.6, 0.75, 1.6), Color(0.80, 0.78, 0.75))
		_mueble(v1, n1, c1a, c1, Vector3(tx2, 0.85, 12.0), Vector3(0.5, 0.35, 0.5), Color(0.85, 0.45, 0.30), false)
	var nodo1 := Node3D.new()
	nodo1.add_child(_malla_de(v1, n1, c1a, Color.WHITE))
	add_child(nodo1)
	_interiores["berceo1"] = {"nombre": "Berceo · planta alta", "fuera": c1 + Vector3(0, 0, 60), "dentro": c1 + Vector3(26.5, 0, -6), "centro": c1, "tam": tam, "acciones": acc1}
	print("MALL_OK plantas=2 tiendas=", acc0.size() + acc1.size() - 2)

func _probar_berceo() -> void:
	var pasa := true
	_dinero = 200
	_minutos = 600.0
	_entrar_interior("berceo")
	pasa = pasa and _en_interior == "berceo"
	_comprar_tienda("game")
	pasa = pasa and _dinero == 160
	_comprar_tienda("yelmo")
	pasa = pasa and _dinero == 151 and _minutos >= 709.0
	_jugador.position = (_interiores["berceo"]["acciones"]["subir"] as Vector3) + Vector3(0, 0.95, 0)
	pasa = pasa and _accion_interior_cercana() == "subir"
	_cambiar_planta(true)
	pasa = pasa and _en_interior == "berceo1"
	pasa = pasa and _accion_interior_cercana() == "bajar"
	_cambiar_planta(false)
	pasa = pasa and _en_interior == "berceo"
	_salir_interior()
	pasa = pasa and _en_interior == ""
	print("BERCEO_PRUEBA_OK pasa=", pasa)
	get_tree().quit()

func _cargar_placas() -> void:
	# Placas con el nombre de la calle en las esquinas: primero las
	# de los grandes ejes (horneadas en placas.json) y, desde el
	# Bloque 7, las de toda la ciudad (placas_ciudad.json). Una caja
	# oscura fundida por placa y el nombre por el canal de rotulos
	# de proximidad, como los de los locales.
	var crudas: Array = []
	for ruta in ["res://datos/ciudad/placas.json", "res://datos/ciudad/placas_ciudad.json"]:
		if not FileAccess.file_exists(ruta):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string(ruta))
		if d != null and d.has("placas"):
			crudas.append_array(d["placas"])
	if crudas.is_empty():
		return
	# Sin duplicadas: las de los ejes se repiten dentro de la lista
	# de la ciudad; misma calle a menos de 8 m es la misma placa.
	# Tambien es la misma calle si solo cambia el tipo de via
	# («Avenida Juan XXIII» y «Calle Juan XXIII» conviven en los
	# datos y salian las dos en la misma esquina).
	var rej := {}
	var aceptadas: Array = []
	for pl in crudas:
		var x := float(pl["x"])
		var z := float(pl["z"])
		var nom := String(pl["n"])
		var base := _nombre_calle_base(nom)
		var dup := false
		for cx in range(int(floor((x - 8.0) / 10.0)), int(floor((x + 8.0) / 10.0)) + 1):
			for cz in range(int(floor((z - 8.0) / 10.0)), int(floor((z + 8.0) / 10.0)) + 1):
				var clave := str(cx) + "," + str(cz)
				if not rej.has(clave):
					continue
				for ia in rej[clave]:
					var pa: Dictionary = aceptadas[ia]
					if (String(pa["n"]) == nom or _nombre_calle_base(String(pa["n"])) == base) and Vector2(x - float(pa["x"]), z - float(pa["z"])).length_squared() < 64.0:
						dup = true
		if dup:
			continue
		var clave_p := str(int(floor(x / 10.0))) + "," + str(int(floor(z / 10.0)))
		if not rej.has(clave_p):
			rej[clave_p] = []
		rej[clave_p].append(aceptadas.size())
		aceptadas.append(pl)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var col_placa := Color(0.13, 0.16, 0.28)
	for ip in aceptadas.size():
		var pl: Dictionary = aceptadas[ip]
		var x := float(pl["x"])
		var z := float(pl["z"])
		var h := Vector2(float(pl["hx"]), float(pl["hz"]))
		# Placas superpuestas (visto por Jon: dos nombres en el
		# mismo punto y con el mismo rumbo se leian mezclados):
		# en los datos, cada cruce trae una placa por calle pero
		# todas en el mismo punto y rumbo. Las que coincidan con
		# una ya puesta se apilan en vertical sobre el mismo
		# poste, como en las esquinas de verdad.
		var nivel := 0
		var rumbo := atan2(h.x, h.y)
		for cx in range(int(floor((x - 1.0) / 10.0)), int(floor((x + 1.0) / 10.0)) + 1):
			for cz in range(int(floor((z - 1.0) / 10.0)), int(floor((z + 1.0) / 10.0)) + 1):
				var clave_n := str(cx) + "," + str(cz)
				if not rej.has(clave_n):
					continue
				for ia in rej[clave_n]:
					if ia >= ip:
						continue
					var pa: Dictionary = aceptadas[ia]
					if Vector2(x - float(pa["x"]), z - float(pa["z"])).length() < 1.0 and absf(wrapf(rumbo - atan2(float(pa["hx"]), float(pa["hz"])), -PI, PI)) < 0.3:
						nivel += 1
		var y := _altura_terreno(x, z) + 2.7 + float(nivel) * 0.78
		var rot := rumbo
		_caja_en(verts, normals, cols, Vector3(x - h.x * 0.06, y, z - h.y * 0.06), Vector3(0.08, 0.62, 3.0), col_placa, rot)
		_placas_datos.append({"n": String(pl["n"]), "h": h, "w": 3.2, "g": 0.55, "p": Vector3(x + h.x * 0.12, y, z + h.y * 0.12)})
	if not verts.is_empty():
		add_child(_malla_de(verts, normals, cols, Color.WHITE))
	print("PLACAS_OK n=", _placas_datos.size())

func _nombre_calle_base(nom: String) -> String:
	# El nombre de la calle sin el tipo de via inicial, para
	# reconocer la misma calle venga como Avenida o como Calle.
	var s := nom.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"]]:
		s = s.replace(par[0], par[1])
	for tipo in ["avenida", "calle", "plaza", "paseo", "travesia", "camino", "ronda", "glorieta", "parque", "acceso"]:
		if s.begins_with(tipo + " "):
			s = s.substr(tipo.length() + 1)
			break
	for art in ["de la ", "de los ", "de las ", "del ", "de ", "la ", "los ", "las ", "el "]:
		if s.begins_with(art):
			s = s.substr(art.length())
			break
	return s

func _crear_bloque7() -> void:
	# Bloque 7 (transversales): marquesinas en las paradas reales
	# de autobús (OSM, horneadas en paradas.json con el rumbo de su
	# calle y fuera de las huellas de edificio) y contenedores
	# (contenedores.json). Todo fundido en UNA sola malla de colores
	# de vértice — el presupuesto web no admite objetos sueltos — y
	# cada pieza con su sólido, como los bancos del mobiliario. El
	# nombre de la parada va por el canal de rótulos de proximidad.
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var col_hierro := Color(0.13, 0.13, 0.14)
	var col_techo := Color(0.20, 0.22, 0.25)
	var col_cristal := Color(0.55, 0.65, 0.70)
	var col_madera := Color(0.45, 0.31, 0.17)
	var col_cartel := Color(0.10, 0.25, 0.60)
	_b7_paradas = 0
	_b7_contenedores = 0
	var rotulos_paradas: Array = []
	if FileAccess.file_exists("res://datos/ciudad/paradas.json"):
		var dp = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/paradas.json"))
		if dp != null and dp.has("paradas"):
			for pa in dp["paradas"]:
				var x := float(pa["x"])
				var z := float(pa["z"])
				var h := Vector2(float(pa.get("hx", 1.0)), float(pa.get("hz", 0.0)))
				var rot := atan2(h.x, h.y)
				var lat := Vector3(cos(rot), 0, -sin(rot))
				var detras := Vector3(-sin(rot), 0, -cos(rot))
				var y := _altura(x, z)
				var cen := Vector3(x, y, z)
				_caja_en(verts, normals, cols, cen + lat * 1.2 + Vector3(0, 1.15, 0), Vector3(0.09, 2.3, 0.09), col_hierro, rot)
				_caja_en(verts, normals, cols, cen - lat * 1.2 + Vector3(0, 1.15, 0), Vector3(0.09, 2.3, 0.09), col_hierro, rot)
				_caja_en(verts, normals, cols, cen + Vector3(0, 2.35, 0), Vector3(2.8, 0.1, 1.3), col_techo, rot)
				_caja_en(verts, normals, cols, cen + detras * 0.6 + Vector3(0, 1.15, 0), Vector3(2.8, 1.05, 0.05), col_cristal, rot)
				_caja_en(verts, normals, cols, cen + Vector3(0, 0.55, 0), Vector3(2.3, 0.08, 0.4), col_madera, rot)
				_caja_en(verts, normals, cols, cen + lat * 1.7 + Vector3(0, 1.3, 0), Vector3(0.07, 2.6, 0.07), col_hierro, rot)
				_caja_en(verts, normals, cols, cen + lat * 1.7 + Vector3(0, 2.45, 0), Vector3(0.06, 0.55, 0.75), col_cartel, rot)
				_registrar_solido(x, z, rot, 0.65, 1.4)
				rotulos_paradas.append({"n": String(pa["n"]), "h": h, "w": 3.0, "g": 0.5, "p": Vector3(x, y + 2.95, z)})
				_paradas_red.append({"x": x, "z": z, "hx": h.x, "hz": h.y, "n": String(pa["n"])})
				_b7_paradas += 1
	if not rotulos_paradas.is_empty():
		_rotulos_datos["paradas"] = rotulos_paradas
	if FileAccess.file_exists("res://datos/ciudad/contenedores.json"):
		var dc = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/contenedores.json"))
		if dc != null and dc.has("contenedores"):
			for co in dc["contenedores"]:
				var x := float(co["x"])
				var z := float(co["z"])
				var h := Vector2(float(co.get("hx", 1.0)), float(co.get("hz", 0.0)))
				var rot := atan2(h.x, h.y)
				var lat := Vector3(cos(rot), 0, -sin(rot))
				var y := _altura(x, z)
				var cen := Vector3(x, y, z)
				var es_punto := String(co.get("t", "container")) == "waste_disposal"
				var col_cuerpo := Color(0.35, 0.36, 0.38) if es_punto else Color(0.16, 0.30, 0.18)
				var col_tapa := Color(0.45, 0.46, 0.48) if es_punto else Color(0.22, 0.40, 0.24)
				_caja_en(verts, normals, cols, cen + Vector3(0, 0.62, 0), Vector3(1.15, 1.25, 2.0), col_cuerpo, rot)
				_caja_en(verts, normals, cols, cen + Vector3(0, 1.29, 0), Vector3(1.2, 0.09, 2.05), col_tapa, rot)
				_caja_en(verts, normals, cols, cen + lat * 0.59 + Vector3(0, 0.95, 0), Vector3(0.04, 0.28, 0.7), Color(0.05, 0.05, 0.05), rot)
				_caja_en(verts, normals, cols, cen - lat * 0.59 + Vector3(0, 0.95, 0), Vector3(0.04, 0.28, 0.7), Color(0.05, 0.05, 0.05), rot)
				_registrar_solido(x, z, rot, 1.0, 0.6)
				_b7_contenedores += 1
	if not verts.is_empty():
		add_child(_malla_de(verts, normals, cols, Color.WHITE))
	print("BLOQUE7_OK paradas=", _b7_paradas, " contenedores=", _b7_contenedores)

func _puerta_cercana() -> String:
	if _jugador == null or _en_interior != "":
		return ""
	for id in _interiores:
		var f: Vector3 = _interiores[id]["fuera"]
		if Vector2(_jugador.position.x - f.x, _jugador.position.z - f.z).length() < 3.2:
			return String(id)
	return ""

func _ejecutar_accion_interior(acc: String) -> void:
	# La acción de un interior, igual para la tecla E, el botón
	# A del mando y el botón táctil: una sola vía, para que un
	# camino roto no deje la tienda muda en los demás (pasó con
	# las compras: la E cortaba «comprar:» con substr(9) y pedía
	# «ec_casco», que no existe; el mando y el botón ni siquiera
	# tenían rama de compra).
	if acc == "dormir":
		_dormir()
	elif acc == "pelo":
		_desde_tel_pelo()
	elif acc == "ropa":
		_desde_tel_camiseta()
	elif acc == "pan":
		_comprar_pan()
	elif acc == "subir":
		_cambiar_planta(true)
	elif acc == "bajar":
		_cambiar_planta(false)
	elif acc.begins_with("comprar:"):
		_comprar_tienda(acc.trim_prefix("comprar:"))
	elif acc == "" and _en_interior != "":
		var den_e: Vector3 = _interiores[_en_interior]["dentro"]
		if Vector2(_jugador.position.x - den_e.x, _jugador.position.z - den_e.z).length() < 2.6:
			_salir_interior()

func _accion_interior_cercana() -> String:
	if _en_interior == "":
		return ""
	var accs: Dictionary = _interiores[_en_interior]["acciones"]
	for a in accs:
		var p: Vector3 = accs[a]
		if Vector2(_jugador.position.x - p.x, _jugador.position.z - p.z).length() < 2.1:
			return String(a)
	return ""

func _entrar_interior(id: String) -> void:
	var d: Dictionary = _interiores[id]
	_volver_a = _jugador.position
	_en_interior = id
	_interiores[id]["ofrecido"] = false
	var f: Vector3 = d["fuera"]
	_ancla_minimapa = Vector2(f.x, f.z)
	var den: Vector3 = d["dentro"]
	_jugador.position = den + Vector3(0, 0.95, 0)
	_dir_jugador = PI
	_sonar("puerta_abrir")
	if id == "piso":
		# Al llegar a casa dejas la compra y el balón.
		_bolsa_en_mano = false
		_balon_en_mano = false
	_refrescar_pan()
	if id == "ayuntamiento" and not _empleo_desbloqueado:
		_empleo_desbloqueado = true
		_aviso = "Ayuntamiento: ya puedes aceptar trabajos especiales"
		_aviso_hasta = _tiempo + 4.0
		_guardar()
	print("INTERIOR_ENTRA ", id)

func _salir_interior() -> void:
	_en_interior = ""
	_jugador.position = _volver_a
	_sonar("puerta_cerrar")
	_refrescar_pan()
	print("INTERIOR_SALE")

func _comprobar_salida_interior() -> void:
	# Salir andando por el hueco de la puerta también saca a la calle: si
	# el jugador rebasa las paredes de la sala (más 1 m de margen), se le
	# devuelve a la calle. Sin esto, quien salía por la puerta sin pulsar
	# E se quedaba en el vacío de fuera, sin teletransporte de vuelta.
	if _en_interior == "" or not _interiores.has(_en_interior):
		return
	var di: Dictionary = _interiores[_en_interior]
	var cen: Vector3 = di["centro"]
	var tam_i: Vector2 = di["tam"]
	if absf(_jugador.position.x - cen.x) > tam_i.x / 2.0 + 1.0 or absf(_jugador.position.z - cen.z) > tam_i.y / 2.0 + 1.0:
		_salir_interior()

func _dormir() -> void:
	if _minutos >= 480.0:
		_dia += 1
	_minutos = 480.0
	_actualizar_hud_dinero()
	_guardar()
	_aviso = "Has dormido hasta las 08:00. Día %d" % _dia
	_aviso_hasta = _tiempo + 3.5
	_sonar("cobro")
	print("DORMIR_OK dia=", _dia)

func _refrescar_pan() -> void:
	# Lo que llevas encima se ve (Jon: «cuando salgo de la
	# panadería no llevo ninguna barra en la mano»): la barra
	# en la mano derecha hasta entregar la misión de Carmen,
	# la bolsa de la compra también en la derecha si no hay
	# pan, y el balón bajo el brazo izquierdo. En coche o en
	# bus las manos van al volante y en casa no se ve nada.
	if _pan_nodo != null:
		if is_instance_valid(_pan_nodo):
			_pan_nodo.queue_free()
		_pan_nodo = null
	if _bolsa_nodo != null:
		if is_instance_valid(_bolsa_nodo):
			_bolsa_nodo.queue_free()
		_bolsa_nodo = null
	if _balon_nodo != null:
		if is_instance_valid(_balon_nodo):
			_balon_nodo.queue_free()
		_balon_nodo = null
	if _brazo_d == null or _en_coche or _en_bus or _en_interior == "piso":
		return
	if _pan_en_mano:
		var pan := _pieza(Vector3(0.10, 0.10, 0.46), Vector3(0, -0.72, 0.10), Color(0.85, 0.62, 0.33))
		_brazo_d.add_child(pan)
		_pan_nodo = pan
	elif _bolsa_en_mano:
		var bolsa := Node3D.new()
		bolsa.add_child(_pieza(Vector3(0.27, 0.30, 0.19), Vector3(0, -0.86, 0.06), Color(0.74, 0.60, 0.39)))
		bolsa.add_child(_pieza(Vector3(0.27, 0.05, 0.19), Vector3(0, -0.70, 0.06), Color(0.62, 0.48, 0.30)))
		_brazo_d.add_child(bolsa)
		_bolsa_nodo = bolsa
	if _balon_en_mano and _brazo_i != null:
		var hv2 := PackedVector3Array()
		var hn2 := PackedVector3Array()
		var hc2 := PackedColorArray()
		_bola_en(hv2, hn2, hc2, Vector3(0, -0.52, 0.07), 0.145, Color(0.10, 0.30, 0.75), 3.7)
		var balon := _malla_de(hv2, hn2, hc2, Color.WHITE)
		_brazo_i.add_child(balon)
		_balon_nodo = balon

func _comprar_pan() -> void:
	if _dinero < 2:
		return
	_dinero -= 2
	_pan_en_mano = true
	_refrescar_pan()
	_actualizar_hud_dinero()
	_guardar()
	_sonar("cobro")
	_aviso = "Pan comprado. ¡Qué bien huele!"
	_aviso_hasta = _tiempo + 2.5
	print("PAN_OK")

func _actualizar_tenderos(delta: float) -> void:
	# Quien atiende respira, te mira y te ofrece lo suyo por diálogo la
	# primera vez que te acercas en cada visita.
	if _en_interior == "" or not _interiores.has(_en_interior):
		return
	var di: Dictionary = _interiores[_en_interior]
	if not di.has("tendero"):
		return
	var raiz: Node3D = di["tendero"]
	raiz.position.y = 0.95 + sin(_tiempo * 1.5 + raiz.position.x) * 0.012
	var hacia := Vector2(_jugador.position.x - raiz.position.x, _jugador.position.z - raiz.position.z)
	if hacia.length() > 0.05:
		raiz.rotation.y = lerp_angle(raiz.rotation.y, atan2(hacia.x, hacia.y), clampf(delta * 6.0, 0.0, 1.0))
	if _dlg_abierto or bool(di.get("ofrecido", false)):
		return
	if hacia.length() < 2.6:
		di["ofrecido"] = true
		_tendero_ofrecer(_en_interior)

func _tendero_ofrecer(id: String) -> void:
	match id:
		"panaderia":
			_abrir_dialogo_opciones("La panadera", "¡Buenos días! Acaba de salir una hornada y huele que alimenta. ¿Te pongo una barra? Son 2 €.", [
				{"t": "Sí, una barra (2 €)", "f": Callable(self, "_tendero_pan")},
				{"t": "Solo estoy mirando", "f": Callable(self, "_tendero_nada")}])
		"peluqueria":
			_abrir_dialogo_opciones("El peluquero", "¡Hola! Pasa, pasa. ¿Te repaso el pelo? Te dejo como nuevo en un momento.", [
				{"t": "Vamos, cámbiame el pelo", "f": Callable(self, "_desde_tel_pelo")},
				{"t": "Otro día", "f": Callable(self, "_tendero_nada")}])
		"tienda":
			_abrir_dialogo_opciones("La dependienta", "¡Hola! Si buscas camiseta, hoy han entrado colores nuevos. ¿Quieres verlas?", [
				{"t": "A ver las camisetas", "f": Callable(self, "_desde_tel_camiseta")},
				{"t": "Solo miro, gracias", "f": Callable(self, "_tendero_nada")}])
		"decathlon":
			_abrir_dialogo_opciones("El dependiente", "¡Hola! Bienvenido a Decathlon. Si buscas bici de montaña, la Grajera es la de la casa: 450 € y te queda en el garaje.", [
				{"t": "Me llevo la Grajera (450 €)", "f": func() -> void: _comprar_tienda("dec_bici")},
				{"t": "Solo estoy mirando", "f": Callable(self, "_tendero_nada")}])

func _tendero_pan() -> void:
	if _dinero < 2:
		_aviso_set("No te llega: la barra cuesta 2 €", 3.5)
		return
	_comprar_pan()
	_aviso_set("La panadera te da la barra: \u00a1gracias!", 3.0)

func _tendero_nada() -> void:
	_aviso_set("Cuando quieras, ya sabes dónde estoy", 3.0)

func _nombre_bonito(calle: String) -> String:
	var tipos := {"CL": "Calle", "AV": "Avenida", "PS": "Paseo", "PZ": "Plaza", "CM": "Camino", "CR": "Carretera", "GL": "Glorieta", "TR": "Travesía", "PJ": "Pasaje"}
	var partes := calle.split(" ")
	if partes.is_empty():
		return calle
	var salida := ""
	var resto := calle
	if tipos.has(partes[0]):
		salida = String(tipos[partes[0]])
		resto = calle.substr(partes[0].length() + 1)
	var menores := ["de", "la", "el", "del", "las", "los", "y", "en"]
	var bonitas: Array = []
	var palabras := resto.split(" ")
	for i in palabras.size():
		var w := String(palabras[i])
		if w == "":
			continue
		var lw := w.to_lower()
		if i > 0 and menores.has(lw):
			bonitas.append(lw)
		else:
			bonitas.append(lw.substr(0, 1).to_upper() + lw.substr(1))
	var nombre := " ".join(PackedStringArray(bonitas))
	return (salida + " " + nombre) if salida != "" else nombre

func _distancia_ruta(a: Vector3, b: Vector3) -> float:
	var ruta := _calcular_ruta(a, b)
	var d := 0.0
	for i in range(ruta.size() - 1):
		var p1: Vector3 = ruta[i]
		var p2: Vector3 = ruta[i + 1]
		d += Vector2(p1.x - p2.x, p1.z - p2.z).length()
	return d

func _cargar_frentes() -> void:
	# Frentes de los locales (punto de encuentro en su puerta y hacia
	# dónde miran), calculados sobre los datos de la ciudad: los
	# encargos se recogen y entregan EN LA PUERTA del local, no en
	# un punto empotrado dentro del edificio.
	if FileAccess.file_exists("res://datos/ciudad/locales.json"):
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/locales.json"))
		if d != null:
			_frentes = d

func _poner_encargante(punto: Vector3, hacia: Vector2) -> void:
	# Una persona esperando en la puerta: es quien te entrega el
	# paquete o lo recibe (Jon: «en la cafetería Tucán nadie me
	# atiende»). Se queda junto al objetivo, respirando.
	_quitar_encargante()
	var camisas_e := [Color(0.75, 0.35, 0.25), Color(0.25, 0.45, 0.65), Color(0.35, 0.60, 0.35), Color(0.80, 0.60, 0.20)]
	var fem_p := _rng.randf() < 0.5
	var per := _hacer_persona(camisas_e[_rng.randi() % camisas_e.size()], Color(0.25, 0.25, 0.30), PELOS[_rng.randi() % PELOS.size()], false, fem_p, {
		"piel": [Color(0.93, 0.74, 0.60), Color(0.88, 0.64, 0.47), Color(0.72, 0.50, 0.36)][_rng.randi() % 3],
		"talla": 0.94 + _rng.randf() * 0.10,
		"pelo_estilo": ("melena" if _rng.randf() < 0.5 else "coleta") if fem_p else "corto",
		"falda": fem_p and _rng.randf() < 0.3,
	})
	var raiz: Node3D = per["raiz"]
	var sitio: Vector3
	if hacia != Vector2.ZERO:
		sitio = _punto_libre(punto + Vector3(-hacia.y * 1.1, 0, hacia.x * 1.1), 0.4)
		raiz.rotation.y = atan2(hacia.x, hacia.y)
	else:
		sitio = _punto_libre(punto + Vector3(1.3, 0, 0.6), 0.4)
		raiz.rotation.y = atan2(_jugador.position.x - sitio.x, _jugador.position.z - sitio.z)
	raiz.position = Vector3(sitio.x, _altura(sitio.x, sitio.z) + 0.95, sitio.z)
	add_child(raiz)
	_estaticos.append({"d": per, "raiz": raiz, "tipo": "espera", "fase": _rng.randf() * 6.0, "encargo": true})
	_encargante = raiz
	print("ENCARGANTE en ", sitio)

func _quitar_encargante() -> void:
	if _encargante == null:
		return
	for i in range(_estaticos.size() - 1, -1, -1):
		if bool(_estaticos[i].get("encargo", false)):
			_estaticos.remove_at(i)
	_encargante.queue_free()
	_encargante = null

func _punto_aleatorio() -> Dictionary:
	if _rng.randf() < 0.4 and not _pois.is_empty():
		var poi = _pois[_rng.randi() % _pois.size()]
		var base := Vector3(float(poi["x"]), 0, float(poi["z"]))
		base.y = _altura(base.x, base.z)
		var clave_f := String(poi["n"]) + "@" + str(int(round(float(poi["x"])))) + "," + str(int(round(float(poi["z"]))))
		if _frentes.has(clave_f):
			var f: Array = _frentes[clave_f]
			return {"nombre": String(poi["n"]), "punto": Vector3(float(f[0]), 0, float(f[1])), "hacia": Vector2(float(f[2]), float(f[3]))}
		return {"nombre": String(poi["n"]), "punto": _punto_libre(base, 0.4), "hacia": Vector2.ZERO}
	var portal = _portales[_rng.randi() % _portales.size()]
	var base2 := Vector3(float(portal["x"]), 0, float(portal["z"]))
	base2.y = _altura(base2.x, base2.z)
	return {"nombre": _nombre_bonito(String(portal["calle"])) + " " + String(portal["numero"]), "punto": _punto_libre(base2, 0.4), "hacia": Vector2.ZERO}

func _generar_trabajos() -> void:
	# La paga se estima por distancia en línea recta x1,35 (calcular la
	# ruta real de cada candidato salía muy caro con el grafo de la
	# ciudad entera); la ruta de verdad se calcula al aceptar el encargo.
	# Destinos en un radio jugable: 60 m .. 1.600 m estimados. En los
	# repartos la recogida también se acota (cerca de ti y del destino):
	# antes salía en cualquier punto de la ciudad y el panel anunciaba
	# «3.091 m» para entregar a 144 m de casa (queja de Jon, 22-nov).
	_trabajos.clear()
	var tope := 1100.0 if _auto else 1600.0
	for i in 3:
		var dest := _punto_aleatorio()
		var pd: Vector3 = dest["punto"]
		var dist := _jugador.position.distance_to(pd) * 1.35
		var mejor := dest
		var mejor_dist := dist
		var intentos := 0
		while (dist < 60.0 or dist > tope) and intentos < 40:
			var pen := 0.0
			if dist < 60.0:
				pen = 60.0 - dist
			elif dist > tope:
				pen = dist - tope
			var pen_m := 0.0
			if mejor_dist < 60.0:
				pen_m = 60.0 - mejor_dist
			elif mejor_dist > tope:
				pen_m = mejor_dist - tope
			if pen < pen_m or (pen == pen_m and absf(dist - 800.0) < absf(mejor_dist - 800.0)):
				mejor = dest
				mejor_dist = dist
			dest = _punto_aleatorio()
			pd = dest["punto"]
			dist = _jugador.position.distance_to(pd) * 1.35
			intentos += 1
		if dist < 60.0 or dist > tope:
			dest = mejor
			pd = dest["punto"]
			dist = mejor_dist
		var tipo := "Recado"
		if not _auto and _rng.randf() < 0.4:
			tipo = "Reparto"
		var trabajo := {"tipo": tipo, "destino": dest}
		if tipo == "Reparto":
			# Recogida coherente: a 40..950 m de ti y a <=1.150 m del destino
			var rec := _punto_aleatorio()
			var pr: Vector3 = rec["punto"]
			var d1 := _jugador.position.distance_to(pr) * 1.35
			var d2 := pr.distance_to(pd) * 1.35
			var mejor_rec := rec
			var mejor_d1 := d1
			var mejor_d2 := d2
			intentos = 0
			while (d1 < 40.0 or d1 > 950.0 or d2 > 1150.0) and intentos < 40:
				if d1 + d2 < mejor_d1 + mejor_d2:
					mejor_rec = rec
					mejor_d1 = d1
					mejor_d2 = d2
				rec = _punto_aleatorio()
				pr = rec["punto"]
				d1 = _jugador.position.distance_to(pr) * 1.35
				d2 = pr.distance_to(pd) * 1.35
				intentos += 1
			if d1 < 40.0 or d1 > 950.0 or d2 > 1150.0:
				rec = mejor_rec
				d1 = mejor_d1
				d2 = mejor_d2
			dist = d1 + d2
			trabajo["recogida"] = rec
			trabajo["d1"] = int(round(d1))
			trabajo["d2"] = int(round(d2))
			trabajo["paga"] = int(round(12.0 + dist * 0.07))
		else:
			trabajo["d1"] = int(round(dist))
			trabajo["d2"] = 0
			trabajo["paga"] = int(round(8.0 + dist * 0.06))
		trabajo["distancia"] = int(round(dist))
		_trabajos.append(trabajo)
		print("ENCARGO_GEN ", i, " ", tipo, " dist=", trabajo["distancia"], " d1=", trabajo["d1"], " d2=", trabajo["d2"], " dest=", String(dest["nombre"]), " paga=", trabajo["paga"])
	if OS.get_cmdline_user_args().has("probar_encargante") and not _trabajos.is_empty():
		# Prueba determinista del reparto entre locales: recogida en el
		# Ibiza y entrega en La Rosaleda, ambos con su persona esperando.
		var f1: Array = _frentes["Ibiza@-268,183"]
		var f2: Array = _frentes["La Rosaleda@-337,233"]
		_trabajos[0] = {"tipo": "Reparto", "destino": {"nombre": "La Rosaleda", "punto": Vector3(float(f2[0]), 0, float(f2[1])), "hacia": Vector2(float(f2[2]), float(f2[3]))}, "recogida": {"nombre": "Ibiza", "punto": Vector3(float(f1[0]), 0, float(f1[1])), "hacia": Vector2(float(f1[2]), float(f1[3]))}, "paga": 20, "d1": 150, "d2": 120, "dist": 270}
		print("FORZADO_LOCAL reparto Ibiza -> La Rosaleda")
	print("ENCARGOS_OK generados=", _trabajos.size())

func _fijar_objetivo(punto: Vector3) -> void:
	# El objetivo (y su pilar) se ponen en el punto alcanzable junto al
	# portal, no dentro de la fachada (Bloque G). Dentro de la ciudad; los
	# interiores viven fuera de sus límites y se dejan como están.
	if punto.x > CIUDAD_X0 and punto.x < CIUDAD_X0 + 5400.0 and punto.z > CIUDAD_Z0 and punto.z < CIUDAD_Z0 + 4000.0:
		punto = _punto_libre(punto, 0.4)
	_destino_libre = punto
	_pilar_destino.position = Vector3(punto.x, _altura(punto.x, punto.z) + 13.0, punto.z)
	_pilar_destino.visible = true

func _aceptar_trabajo(idx: int) -> void:
	if idx < 0 or idx >= _trabajos.size() or not _trabajo.is_empty():
		return
	_trabajo = _trabajos[idx]
	_fase_trabajo = 1
	if _trabajo["tipo"] == "Reparto":
		var rec: Dictionary = _trabajo["recogida"]
		_objetivo_texto = "Recoge el paquete en " + String(rec["nombre"])
		_fijar_objetivo(rec["punto"])
		var rp: Vector3 = rec["punto"]
		_poner_encargante(rp, rec.get("hacia", Vector2.ZERO))
	else:
		var dest: Dictionary = _trabajo["destino"]
		_objetivo_texto = "Ve a " + String(dest["nombre"]) + " · +" + str(int(_trabajo["paga"])) + " €"
		_fijar_objetivo(dest["punto"])
		var hc: Vector2 = dest.get("hacia", Vector2.ZERO)
		if hc != Vector2.ZERO:
			var dp2: Vector3 = dest["punto"]
			_poner_encargante(dp2, hc)
	_actualizar_hud()
	_cerrar_panel()
	if _son_ding != null:
		_son_ding.play()
	print("ENCARGO_ACEPTADO ", _objetivo_texto)

func _al_llegar() -> void:
	if _trabajo["tipo"] == "Reparto" and _fase_trabajo == 1:
		_fase_trabajo = 2
		var dest: Dictionary = _trabajo["destino"]
		_objetivo_texto = "Entrega el paquete en " + String(dest["nombre"]) + " · +" + str(int(_trabajo["paga"])) + " €"
		_fijar_objetivo(dest["punto"])
		var dp3: Vector3 = dest["punto"]
		_poner_encargante(dp3, dest.get("hacia", Vector2.ZERO))
		_aviso_set("—Aquí tienes el paquete. ¡Que llegue entero!", 4.0)
		_ruta_fase = -1
		if _son_ding != null:
			_son_ding.play()
		print("REPARTO_RECOGIDO, a entregar en ", String(dest["nombre"]))
		_actualizar_hud()
		return
	var paga := int(_trabajo["paga"])
	_dinero += paga
	if _son_cobro != null:
		_son_cobro.play()
	print("ENCARGO_OK completado: +", paga, " € (dinero=", _dinero, ") en ", roundf(_tiempo), " s")
	var habia_encargante := _encargante != null
	_quitar_encargante()
	if habia_encargante:
		_aviso_set("—¡Gracias! Encargo cumplido.", 3.5)
	_trabajo = {}
	_fase_trabajo = 0
	_pilar_destino.visible = false
	_ruta_mini = []
	_objetivo_texto = "¡Encargo completado! +" + str(paga) + " € · Pulsa T para más encargos"
	_banner_hasta = _tiempo + 5.0
	_generar_trabajos()
	_guardar()
	_actualizar_hud()
	_actualizar_hud_dinero()
	if _auto:
		_mision_ok = true
		get_tree().quit()

func _crear_interfaz() -> void:
	_rng.randomize()
	var capa := CanvasLayer.new()
	add_child(capa)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(580, 0)
	_panel.offset_left = -290
	_panel.offset_top = -200
	_panel.offset_right = 290
	_panel.offset_bottom = 200
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.09, 0.13, 0.95)
	estilo.corner_radius_top_left = 14
	estilo.corner_radius_top_right = 14
	estilo.corner_radius_bottom_left = 14
	estilo.corner_radius_bottom_right = 14
	estilo.content_margin_left = 20
	estilo.content_margin_right = 20
	estilo.content_margin_top = 16
	estilo.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", estilo)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_panel.add_child(vb)
	var titulo := Label.new()
	titulo.text = "Encargos"
	titulo.add_theme_font_size_override("font_size", 28)
	vb.add_child(titulo)
	_panel_lista = VBoxContainer.new()
	_panel_lista.add_theme_constant_override("separation", 8)
	vb.add_child(_panel_lista)
	var pista := Label.new()
	pista.text = "Toca un encargo para aceptarlo · T para cerrar"
	pista.add_theme_font_size_override("font_size", 15)
	pista.add_theme_color_override("font_color", Color(0.70, 0.74, 0.82))
	vb.add_child(pista)
	_panel.visible = false
	capa.add_child(_panel)
	_panel_coches = PanelContainer.new()
	_panel_coches.set_anchors_preset(Control.PRESET_CENTER)
	_panel_coches.custom_minimum_size = Vector2(640, 0)
	_panel_coches.offset_left = -320
	_panel_coches.offset_top = -230
	_panel_coches.offset_right = 320
	_panel_coches.offset_bottom = 230
	_panel_coches.add_theme_stylebox_override("panel", estilo)
	var vc := VBoxContainer.new()
	vc.add_theme_constant_override("separation", 10)
	_panel_coches.add_child(vc)
	_panel_coches_titulo = Label.new()
	_panel_coches_titulo.add_theme_font_size_override("font_size", 26)
	vc.add_child(_panel_coches_titulo)
	var scroll_c := ScrollContainer.new()
	scroll_c.custom_minimum_size = Vector2(600, 350)
	vc.add_child(scroll_c)
	_panel_coches_lista = VBoxContainer.new()
	_panel_coches_lista.add_theme_constant_override("separation", 8)
	_panel_coches_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_c.add_child(_panel_coches_lista)
	var b_cerrar_c := Button.new()
	b_cerrar_c.text = "Cerrar"
	b_cerrar_c.add_theme_font_size_override("font_size", 19)
	b_cerrar_c.pressed.connect(func() -> void: _cerrar_panel_coches())
	vc.add_child(b_cerrar_c)
	_panel_coches.visible = false
	capa.add_child(_panel_coches)
	_panel_esp = PanelContainer.new()
	_panel_esp.set_anchors_preset(Control.PRESET_CENTER)
	_panel_esp.custom_minimum_size = Vector2(620, 0)
	_panel_esp.offset_left = -310
	_panel_esp.offset_top = -215
	_panel_esp.offset_right = 310
	_panel_esp.offset_bottom = 215
	_panel_esp.add_theme_stylebox_override("panel", estilo)
	var ve := VBoxContainer.new()
	ve.add_theme_constant_override("separation", 10)
	_panel_esp.add_child(ve)
	var tit_e := Label.new()
	tit_e.text = "Trabajos especiales"
	tit_e.add_theme_font_size_override("font_size", 26)
	ve.add_child(tit_e)
	_panel_esp_lista = VBoxContainer.new()
	_panel_esp_lista.add_theme_constant_override("separation", 8)
	ve.add_child(_panel_esp_lista)
	var b_cerrar_e := Button.new()
	b_cerrar_e.text = "Cerrar"
	b_cerrar_e.add_theme_font_size_override("font_size", 19)
	b_cerrar_e.pressed.connect(func() -> void: _cerrar_panel_esp())
	ve.add_child(b_cerrar_e)
	_panel_esp.visible = false
	capa.add_child(_panel_esp)
	_panel_dlg = PanelContainer.new()
	_panel_dlg.set_anchors_preset(Control.PRESET_CENTER)
	_panel_dlg.custom_minimum_size = Vector2(680, 0)
	_panel_dlg.offset_left = -340
	_panel_dlg.offset_top = 96
	_panel_dlg.offset_right = 340
	_panel_dlg.offset_bottom = 252
	_panel_dlg.add_theme_stylebox_override("panel", estilo)
	var vd := VBoxContainer.new()
	vd.add_theme_constant_override("separation", 8)
	_panel_dlg.add_child(vd)
	_dlg_nombre = Label.new()
	_dlg_nombre.add_theme_font_size_override("font_size", 22)
	_dlg_nombre.add_theme_color_override("font_color", Color(1.0, 0.78, 0.35))
	vd.add_child(_dlg_nombre)
	_dlg_texto = Label.new()
	_dlg_texto.add_theme_font_size_override("font_size", 20)
	_dlg_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vd.add_child(_dlg_texto)
	_dlg_botones = HBoxContainer.new()
	_dlg_botones.add_theme_constant_override("separation", 10)
	vd.add_child(_dlg_botones)
	_panel_dlg.visible = false
	capa.add_child(_panel_dlg)
	_panel_carr = PanelContainer.new()
	_panel_carr.set_anchors_preset(Control.PRESET_CENTER)
	_panel_carr.custom_minimum_size = Vector2(640, 0)
	_panel_carr.offset_left = -320
	_panel_carr.offset_top = -225
	_panel_carr.offset_right = 320
	_panel_carr.offset_bottom = 225
	_panel_carr.add_theme_stylebox_override("panel", estilo)
	var vca := VBoxContainer.new()
	vca.add_theme_constant_override("separation", 10)
	_panel_carr.add_child(vca)
	var tit_ca := Label.new()
	tit_ca.text = "Carreras"
	tit_ca.add_theme_font_size_override("font_size", 26)
	vca.add_child(tit_ca)
	_panel_carr_lista = VBoxContainer.new()
	_panel_carr_lista.add_theme_constant_override("separation", 8)
	vca.add_child(_panel_carr_lista)
	var b_cerrar_ca := Button.new()
	b_cerrar_ca.text = "Cerrar"
	b_cerrar_ca.add_theme_font_size_override("font_size", 19)
	b_cerrar_ca.pressed.connect(func() -> void: _cerrar_panel_carr())
	vca.add_child(b_cerrar_ca)
	_panel_carr.visible = false
	capa.add_child(_panel_carr)
	_mapa = Control.new()
	_mapa.set_script(load("res://mapa.gd"))
	_mapa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mapa.visible = false
	_mapa.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_mapa.connect("lugar_elegido", _al_elegir_lugar_mapa)
	capa.add_child(_mapa)
	# Pantalla de ayuda al empezar, con el dinero actual
	_ayuda = PanelContainer.new()
	_ayuda.set_anchors_preset(Control.PRESET_CENTER)
	_ayuda.custom_minimum_size = Vector2(620, 0)
	_ayuda.offset_left = -310
	_ayuda.offset_top = -250
	_ayuda.offset_right = 310
	_ayuda.offset_bottom = 250
	var estilo_a := StyleBoxFlat.new()
	estilo_a.bg_color = Color(0.07, 0.09, 0.13, 0.96)
	estilo_a.corner_radius_top_left = 14
	estilo_a.corner_radius_top_right = 14
	estilo_a.corner_radius_bottom_left = 14
	estilo_a.corner_radius_bottom_right = 14
	estilo_a.content_margin_left = 24
	estilo_a.content_margin_right = 24
	estilo_a.content_margin_top = 20
	estilo_a.content_margin_bottom = 20
	_ayuda.add_theme_stylebox_override("panel", estilo_a)
	var va := VBoxContainer.new()
	va.add_theme_constant_override("separation", 12)
	_ayuda.add_child(va)
	var tit := Label.new()
	tit.text = "Cómo jugar"
	tit.add_theme_font_size_override("font_size", 30)
	va.add_child(tit)
	_ayuda_dinero = Label.new()
	_ayuda_dinero.add_theme_font_size_override("font_size", 22)
	_ayuda_dinero.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	va.add_child(_ayuda_dinero)
	var cuerpo := Label.new()
	cuerpo.text = "Estás en Logroño. Gana dinero haciendo encargos.\n\n1. A pie, WASD o flechas: arriba anda hacia donde miras, izquierda y derecha giras, abajo te das la vuelta y andas en sentido contrario (nadie anda marcha atrás; en bici tampoco hay marcha atrás: el freno solo para).\n2. Tecla T o el teléfono de arriba: encargos, elige uno.\n3. Sigue la ruta azul del minimapa hasta el pilar naranja.\n4. Tecla E junto a tu coche rojo: a conducir.\n5. Al llegar cobras solo. Repartos: recoger y entregar.\n6. Tab: mapa grande con tu recorrido.\n\nMóvil: joystick para andar; conduciendo, volante y pedales.\nMando de Play: stick para andar y conducir; botón cruz: coche; botón triángulo: encargos; Options: mapa.\n\nEspacio (a pie): correr. F: sentarte en un banco. Se guarda solo. H: ver esta ayuda otra vez.\nCoches: compra en el concesionario AutoRioja (Av. de la Paz), repara y mejora en el Taller Ebro (centro) y cambia de coche en tu garaje (en casa, Miguel Villanueva).\nInteriores: entra por las puertas en tu piso (la cama es para dormir), el Ayuntamiento, el gimnasio, la peluquería, la tienda de ropa y la panadería."
	cuerpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_font_size_override("font_size", 17)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(cuerpo)
	va.add_child(scroll)
	var boton := Button.new()
	boton.text = "¡A jugar!"
	boton.add_theme_font_size_override("font_size", 22)
	boton.pressed.connect(func() -> void: _cerrar_ayuda())
	va.add_child(boton)
	_ayuda.visible = false
	capa.add_child(_ayuda)
	get_viewport().size_changed.connect(func() -> void:
		if _ayuda_abierta:
			_ajustar_ayuda())
	_generar_trabajos()
	if _auto:
		_aceptar_trabajo(0)
	elif OS.get_cmdline_user_args().is_empty():
		_abrir_ayuda()

func _ajustar_ayuda() -> void:
	# El panel se adapta a la ventana: nunca más del 94 % de ancho ni de
	# alto, para que las instrucciones quepan en cualquier pantalla.
	var vp := get_viewport().get_visible_rect().size
	var w := minf(620.0, vp.x * 0.94)
	var h := minf(560.0, vp.y * 0.94)
	_ayuda.offset_left = -w / 2.0
	_ayuda.offset_right = w / 2.0
	_ayuda.offset_top = -h / 2.0
	_ayuda.offset_bottom = h / 2.0

func _abrir_ayuda() -> void:
	_ayuda_dinero.text = "Tu dinero ahora: %d € · Día %d" % [_dinero, _dia]
	_ajustar_ayuda()
	_ayuda.visible = true
	_ayuda_abierta = true

func _cerrar_ayuda() -> void:
	_ayuda.visible = false
	_ayuda_abierta = false

func _rellenar_panel() -> void:
	for h in _panel_lista.get_children():
		h.queue_free()
	if not _trabajo.is_empty():
		var l := Label.new()
		l.text = "Ya tienes un encargo en curso:\n" + _objetivo_texto
		l.add_theme_font_size_override("font_size", 19)
		_panel_lista.add_child(l)
		return
	for i in _trabajos.size():
		var t: Dictionary = _trabajos[i]
		var dest: Dictionary = t["destino"]
		var texto := str(i + 1) + " · " + String(t["tipo"]) + " — " + String(dest["nombre"])
		if t["tipo"] == "Reparto":
			texto += "\n    Recoge en " + String((t["recogida"] as Dictionary)["nombre"]) + " · a " + str(int(t.get("d1", 0))) + " m"
			texto += "\n    Total ≈ " + str(int(t["distancia"])) + " m · +" + str(int(t["paga"])) + " €"
		else:
			texto += "\n    ≈ " + str(int(t["distancia"])) + " m · +" + str(int(t["paga"])) + " €"
		var b := Button.new()
		b.text = texto
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 19)
		var idx := i
		b.pressed.connect(func() -> void: _aceptar_trabajo(idx))
		_panel_lista.add_child(b)

func _abrir_panel() -> void:
	if not _carr.is_empty():
		_aviso_set("Estás en plena carrera: termina o abandona con la ×", 4.0)
		return
	_rellenar_panel()
	_panel.visible = true
	_panel_abierto = true

func _cerrar_panel() -> void:
	_panel.visible = false
	_panel_abierto = false

func _abrir_panel_coches(tipo: String) -> void:
	_rellenar_panel_coches(tipo)
	_panel_coches.visible = true
	_panel_coches_abierto = true

func _cerrar_panel_coches() -> void:
	_panel_coches.visible = false
	_panel_coches_abierto = false

func _kmh(v: float) -> int:
	return int(round(v * 3.6))

func _fila_coche(texto: String, botones: Array) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	var et := Label.new()
	et.text = texto
	et.add_theme_font_size_override("font_size", 18)
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(et)
	for b in botones:
		var bd: Array = b
		var btn := Button.new()
		btn.text = String(bd[0])
		btn.add_theme_font_size_override("font_size", 18)
		btn.disabled = not bool(bd[2])
		btn.pressed.connect(bd[1])
		fila.add_child(btn)
	_panel_coches_lista.add_child(fila)

func _comprar_y_refrescar(id: int) -> void:
	if _comprar_coche(id):
		_rellenar_panel_coches("concesionario")

func _vender_y_refrescar(i: int) -> void:
	if _vender_coche(i):
		_rellenar_panel_coches("garaje")

func _usar_y_refrescar(i: int) -> void:
	_usar_coche(i)
	_rellenar_panel_coches("garaje")

func _reparar_y_refrescar() -> void:
	if _reparar_coche():
		_rellenar_panel_coches("taller")

func _mejorar_y_refrescar(tipo: String) -> void:
	if _mejorar_coche(tipo):
		_rellenar_panel_coches("taller")

func _rellenar_panel_coches(tipo: String) -> void:
	for h in _panel_coches_lista.get_children():
		h.queue_free()
	if tipo == "concesionario":
		_panel_coches_titulo.text = "Concesionario AutoRioja · Tu dinero: %d €" % _dinero
		for id in COCHES.size():
			var cat: Dictionary = COCHES[id]
			var ya := false
			for inst in _mis_coches:
				if int(inst["id"]) == id:
					ya = true
			var txt := "%s · %s · %d km/h" % [cat["n"], cat["clase"], _kmh(float(cat["vmax"]))]
			var idc := id
			if ya:
				_fila_coche(txt, [["En tu garaje", func() -> void: pass, false]])
			else:
				_fila_coche(txt + " · %d €" % int(cat["precio"]), [["Comprar", func() -> void: _comprar_y_refrescar(idc), _dinero >= int(cat["precio"])]])
	elif tipo == "garaje":
		_panel_coches_titulo.text = "Tu garaje · Tu dinero: %d €" % _dinero
		for i in _mis_coches.size():
			var inst2: Dictionary = _mis_coches[i]
			var cat2: Dictionary = COCHES[int(inst2["id"])]
			var st2 := _stats_de(inst2)
			var txt2 := "%s · %s · %d km/h · daño %d %%" % [cat2["n"], cat2["clase"], _kmh(float(st2["vmax"])), int(inst2["danio"])]
			if int(inst2["motor"]) > 0 or int(inst2["frenos"]) > 0:
				txt2 += " · motor %d · frenos %d" % [int(inst2["motor"]), int(inst2["frenos"])]
			var ic := i
			var venta := int(int(cat2["precio"]) * 0.7)
			if i == _coche_activo:
				_fila_coche(txt2 + " · EN USO", [["Vender %d €" % venta, func() -> void: _vender_y_refrescar(ic), _mis_coches.size() > 1]])
			else:
				_fila_coche(txt2, [["Usar", func() -> void: _usar_y_refrescar(ic), true], ["Vender %d €" % venta, func() -> void: _vender_y_refrescar(ic), _mis_coches.size() > 1]])
	else:
		var insta: Dictionary = _mis_coches[_coche_activo]
		var cata: Dictionary = COCHES[int(insta["id"])]
		var sta := _stats_activo()
		_panel_coches_titulo.text = "Taller Ebro · Tu %s · %d €" % [cata["n"], _dinero]
		_fila_coche("Velocidad máx. actual: %d km/h · daño %d %%" % [_kmh(float(sta["vmax"])), int(insta["danio"])], [])
		var coste_r := int(insta["danio"]) * 6
		_fila_coche("Reparar todo el daño (6 € por punto)", [["Reparar %d €" % coste_r, func() -> void: _reparar_y_refrescar(), coste_r > 0 and _dinero >= coste_r]])
		var nm := int(insta["motor"])
		_fila_coche("Motor nivel %d/3 (+10 %% por nivel)" % nm, [["Mejorar %d €" % (500 * (nm + 1)), func() -> void: _mejorar_y_refrescar("motor"), nm < 3 and _dinero >= 500 * (nm + 1)]])
		var nf := int(insta["frenos"])
		_fila_coche("Frenos nivel %d/3 (+15 %% por nivel)" % nf, [["Mejorar %d €" % (350 * (nf + 1)), func() -> void: _mejorar_y_refrescar("frenos"), nf < 3 and _dinero >= 350 * (nf + 1)]])

func _datos_mapa() -> Dictionary:
	_cargar_calles_mapa()
	var ruta: Array = []
	var destino = null
	if not _trabajo.is_empty():
		var desde := _coche.position if _en_coche else _jugador.position
		ruta = _calcular_ruta(desde, _destino_libre)
		destino = Vector2(_destino_libre.x, _destino_libre.z)
	var d := {
		"calles": _calles_mapa, "rio": _rio, "pois": _pois_mapa, "ruta": ruta, "rastro": _rastro,
		"destino": destino,
		"jugador": Vector2((_bus.position if _en_bus else (_coche.position if _en_coche else _jugador.position)).x, (_bus.position if _en_bus else (_coche.position if _en_coche else _jugador.position)).z),
		"coche": Vector2(_coche.position.x, _coche.position.z),
	}
	# Las líneas de autobús, para pintarlas en el plano
	var lineas_d: Array = []
	for lin in _lineas_bus:
		var pts_d: Array = []
		# El plano pinta tambien el anillo completo de cada
		# cabecera: la linea llega a la rotonda, la rodea
		# entera y vuelve por donde vino.
		for p2 in lin["giro_ini"]:
			pts_d.append([p2.x, p2.y])
		for p2 in lin["pts"]:
			pts_d.append([p2.x, p2.y])
		for p2 in lin["giro_fin"]:
			pts_d.append([p2.x, p2.y])
		var par_d: Array = []
		for par in lin["paradas"]:
			par_d.append([float(par["x"]), float(par["z"])])
		lineas_d.append({"ext": String(lin["ext"]), "c": lin["c"], "pts": pts_d, "paradas": par_d})
	d["lineas"] = lineas_d
	if not _carr.is_empty():
		d["carrera"] = _carr_mapa_datos()
	return d

func _abrir_mapa() -> void:
	_mapa.call("mostrar", _datos_mapa())
	_mapa_abierto = true

func _cerrar_mapa() -> void:
	_mapa.visible = false
	_mapa_abierto = false

func _al_elegir_lugar_mapa(poi: Dictionary) -> void:
	# Clic en un punto dorado del plano = aparecer en ese
	# lugar (pedido de Jon: empieza cada partida en Miguel
	# Villanueva y quiere reubicarse desde el plano). Antes
	# del salto se sale limpiamente de donde esté: columpio,
	# interior, bus, coche o banco.
	if not _carr.is_empty():
		_aviso_set("En plena carrera no puedes saltar por el mapa", 3.0)
		return
	if _auto:
		_aviso_set("El piloto automático va conduciendo; espera a llegar", 3.0)
		return
	if _en_columpio:
		_bajar_columpio()
	if not _bus_pasajero.is_empty():
		_bajar_bus_pasajero()
	if _en_interior != "":
		_salir_interior()
	if _en_bus:
		_alternar_bus()
	elif _en_coche:
		_alternar_coche()
	if _sentado:
		_alternar_sentarse()
	_nadando = false
	_jugador.rotation.x = 0.0
	_en_vuelta = false
	var destino := Vector3(float(poi["x"]), 0, float(poi["z"]))
	var libre := _punto_libre(destino, 0.5)
	if _choca(Vector2(libre.x, libre.z), 0.5) or _es_encerrado(Vector2(libre.x, libre.z)):
		# Dentro de un edificio o encerrado en un patio sin
		# salida: se aparece en el nodo de calle mas cercano
		# al lugar, que siempre esta libre y conectado.
		var nodo: Vector2 = _nodos[_nodo_cercano(Vector2(destino.x, destino.z))]
		libre = Vector3(nodo.x, 0, nodo.y)
	_jugador.position = Vector3(libre.x, _altura(libre.x, libre.z) + 0.95, libre.z)
	_cerrar_mapa()
	_aviso_set("Has ido directo a " + String(poi["n"]), 3.0)

# ---------- Fase 5.2: controles táctiles ----------

func _t_coche() -> void:
	if not _auto and _jugador != null:
		if _btn_modo == "bus":
			_alternar_bus()
		elif _btn_modo == "bajarpas":
			_bajar_bus_pasajero()
		elif _btn_modo == "buspas":
			_subir_bus_pasajero(_bus_linea_cercano())
		elif _btn_modo == "camalote":
			_retirar_masa_cercana()
		elif _btn_modo == "hablar":
			_hablar_cercano()
		elif _btn_modo == "banco":
			_alternar_sentarse()
		elif _btn_modo.begins_with("lugar:"):
			_abrir_panel_coches(_btn_modo.trim_prefix("lugar:"))
		elif _btn_modo == "salir":
			_salir_interior()
		elif _btn_modo.begins_with("puerta:"):
			_entrar_interior(_btn_modo.trim_prefix("puerta:"))
		elif _btn_modo == "dormir":
			_dormir()
		elif _btn_modo == "pelo":
			_desde_tel_pelo()
		elif _btn_modo == "ropa":
			_desde_tel_camiseta()
		elif _btn_modo == "pan":
			_comprar_pan()
		elif _btn_modo == "subir":
			_cambiar_planta(true)
		elif _btn_modo == "bajar":
			_cambiar_planta(false)
		elif _btn_modo.begins_with("comprar:"):
			_comprar_tienda(_btn_modo.trim_prefix("comprar:"))
		else:
			_alternar_coche()

func _t_encargos() -> void:
	if _auto or _jugador == null:
		return
	if _panel_abierto:
		_cerrar_panel()
	else:
		_cerrar_mapa()
		_abrir_panel()

func _t_mapa() -> void:
	if _auto or _jugador == null:
		return
	if _mapa_abierto:
		_cerrar_mapa()
	else:
		_cerrar_panel()
		_abrir_mapa()

func _t_ayuda() -> void:
	if _auto or _jugador == null:
		return
	if _ayuda_abierta:
		_cerrar_ayuda()
	else:
		_cerrar_panel()
		_cerrar_mapa()
		_abrir_ayuda()

func _t_vista() -> void:
	_vista_aerea = not _vista_aerea

# ---------- Mando (PlayStation y compatibles) ----------

func _comprobar_mando() -> void:
	print("MANDO_OK pads=", Input.get_connected_joypads().size())

func _pad() -> int:
	var pads := Input.get_connected_joypads()
	return int(pads[0]) if not pads.is_empty() else -1

func _pad_eje(eje: JoyAxis) -> float:
	var p := _pad()
	if p < 0:
		return 0.0
	var v := Input.get_joy_axis(p, eje)
	return v if absf(v) > 0.12 else 0.0

func _pad_gatillo(eje: JoyAxis) -> float:
	var p := _pad()
	if p < 0:
		return 0.0
	return clampf(Input.get_joy_axis(p, eje), 0.0, 1.0)

func _t_sonido() -> void:
	_sonido = not _sonido
	AudioServer.set_bus_mute(0, not _sonido)

func _colocar_joy() -> void:
	if _joy_base == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var centro := _joy_centro
	if _joy_id == -1:
		centro = Vector2(100, vp.y - 100)
	_joy_base.position = centro - Vector2(75, 75)
	_joy_perilla.position = centro + _joy_valor * 44.0 - Vector2(31, 31)

func _crear_tactil() -> void:
	_capa_tactil = CanvasLayer.new()
	_capa_tactil.layer = 3
	_joy_base = Panel.new()
	var est := StyleBoxFlat.new()
	est.bg_color = Color(1, 1, 1, 0.10)
	est.set_corner_radius_all(75)
	est.set_border_width_all(2)
	est.border_color = Color(1, 1, 1, 0.35)
	_joy_base.add_theme_stylebox_override("panel", est)
	_joy_base.size = Vector2(150, 150)
	_joy_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_tactil.add_child(_joy_base)
	_joy_perilla = Panel.new()
	var est2 := StyleBoxFlat.new()
	est2.bg_color = Color(1, 1, 1, 0.35)
	est2.set_corner_radius_all(31)
	_joy_perilla.add_theme_stylebox_override("panel", est2)
	_joy_perilla.size = Vector2(62, 62)
	_joy_perilla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_tactil.add_child(_joy_perilla)
	# Controles de conducción (solo visibles al conducir): barra de
	# dirección abajo a la izquierda y pedales abajo a la derecha.
	# Los botones de encargos/mapa/ayuda viven ahora en el teléfono.
	_capa_conducir = Control.new()
	_capa_conducir.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa_conducir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_tactil.add_child(_capa_conducir)
	var barra := PanelContainer.new()
	barra.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	barra.offset_left = 18
	barra.offset_top = -118
	barra.offset_right = 272
	barra.offset_bottom = -24
	var est_barra := _estilo_caja(Color(0.22, 0.23, 0.27, 0.55), 47)
	est_barra.content_margin_left = 10
	est_barra.content_margin_right = 10
	barra.add_theme_stylebox_override("panel", est_barra)
	_capa_conducir.add_child(barra)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	barra.add_child(hb)
	var b_izq := Button.new()
	b_izq.text = "<"
	b_izq.flat = true
	b_izq.custom_minimum_size = Vector2(64, 0)
	b_izq.add_theme_font_size_override("font_size", 38)
	b_izq.add_theme_color_override("font_color", Color(1, 1, 1))
	b_izq.button_down.connect(func() -> void: _toque_giro = -1.0)
	b_izq.button_up.connect(func() -> void: if _toque_giro < 0.0: _toque_giro = 0.0)
	hb.add_child(b_izq)
	var ic_vol := TextureRect.new()
	ic_vol.texture = _icono_volante()
	ic_vol.custom_minimum_size = Vector2(58, 58)
	ic_vol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic_vol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic_vol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic_vol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(ic_vol)
	var b_der := Button.new()
	b_der.text = ">"
	b_der.flat = true
	b_der.custom_minimum_size = Vector2(64, 0)
	b_der.add_theme_font_size_override("font_size", 38)
	b_der.add_theme_color_override("font_color", Color(1, 1, 1))
	b_der.button_down.connect(func() -> void: _toque_giro = 1.0)
	b_der.button_up.connect(func() -> void: if _toque_giro > 0.0: _toque_giro = 0.0)
	hb.add_child(b_der)
	var gas := Button.new()
	gas.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	gas.offset_left = -118
	gas.offset_right = -18
	gas.offset_top = -142
	gas.offset_bottom = -22
	gas.text = "↑"
	gas.add_theme_font_size_override("font_size", 38)
	gas.add_theme_color_override("font_color", Color(1, 1, 1))
	gas.add_theme_stylebox_override("normal", _estilo_caja(Color(0.22, 0.23, 0.27, 0.55), 50))
	gas.add_theme_stylebox_override("pressed", _estilo_caja(Color(0.45, 0.47, 0.52, 0.75), 50))
	gas.add_theme_stylebox_override("focus", _estilo_caja(Color(0, 0, 0, 0), 50))
	gas.button_down.connect(func() -> void: _toque_gas = true)
	gas.button_up.connect(func() -> void: _toque_gas = false)
	_capa_conducir.add_child(gas)
	var freno := Button.new()
	freno.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	freno.offset_left = -238
	freno.offset_right = -138
	freno.offset_top = -142
	freno.offset_bottom = -22
	freno.text = "="
	freno.add_theme_font_size_override("font_size", 34)
	freno.add_theme_color_override("font_color", Color(1, 1, 1))
	freno.add_theme_stylebox_override("normal", _estilo_caja(Color(0.22, 0.23, 0.27, 0.55), 50))
	freno.add_theme_stylebox_override("pressed", _estilo_caja(Color(0.45, 0.47, 0.52, 0.75), 50))
	freno.add_theme_stylebox_override("focus", _estilo_caja(Color(0, 0, 0, 0), 50))
	freno.button_down.connect(func() -> void: _toque_freno = true)
	freno.button_up.connect(func() -> void: _toque_freno = false)
	_capa_conducir.add_child(freno)
	add_child(_capa_tactil)
	_capa_tactil.visible = DisplayServer.is_touchscreen_available()
	_colocar_joy()
	_refrescar_tactil()
	print("TACTIL_OK visible=", _capa_tactil.visible)

# ---------- Fase 5.3: recetas de vestido por calle ----------

const RECETAS := {
	"Paseo del Espolón": {"esp": "magnolio", "cada": 7.0, "desp": 2.6},
	"Gran Vía Juan Carlos I": {"esp": "platano", "cada": 9.0, "desp": 5.4},
	"Avenida de La Paz": {"esp": "platano", "cada": 9.0, "desp": 5.4},
	"Avenida de la Constitución": {"esp": "palmera", "cada": 10.0, "desp": 4.6},
	"Calle Portales": {"esp": "magnolio", "cada": 8.0, "desp": 3.0},
	"Calle General Vara de Rey": {"esp": "platano", "cada": 8.0, "desp": 3.8},
	"Avenida de La Rioja": {"esp": "magnolio", "cada": 8.0, "desp": 4.2},
	"Avenida de Colón": {"esp": "palmera", "cada": 10.0, "desp": 4.2},
	"Calle Duquesa de la Victoria": {"esp": "platano", "cada": 9.0, "desp": 4.0},
	"Avenida de Viana": {"esp": "magnolio", "cada": 8.0, "desp": 4.0},
	"Calle Muro de Cervantes": {"esp": "magnolio", "cada": 8.0, "desp": 3.0},
	"Calle Muro del Carmen": {"esp": "magnolio", "cada": 8.0, "desp": 3.0},
	"Calle Muro de Francisco de la Mata": {"esp": "platano", "cada": 8.0, "desp": 3.4},
	"Calle Presidente Leopoldo Calvo Sotelo": {"esp": "platano", "cada": 9.0, "desp": 4.2},
	"Calle Luis de Ulloa": {"esp": "platano", "cada": 9.0, "desp": 4.0},
	"Calle Bretón de los Herreros": {"esp": "magnolio", "cada": 8.0, "desp": 3.0},
	"Calle San Juan": {"esp": "magnolio", "cada": 8.0, "desp": 2.8},
	"Calle Marqués de San Nicolás": {"esp": "magnolio", "cada": 8.0, "desp": 3.0},
	"Calle Sagasta": {"esp": "platano", "cada": 9.0, "desp": 4.0},
	"Avenida de Lobete": {"esp": "platano", "cada": 9.0, "desp": 4.6},
	"Calle Chile": {"esp": "platano", "cada": 9.0, "desp": 4.0},
	"Avenida de Madrid": {"esp": "palmera", "cada": 10.0, "desp": 4.6},
	"Avenida de Burgos": {"esp": "platano", "cada": 9.0, "desp": 4.6},
	"Calle Hermanos Moroy": {"esp": "magnolio", "cada": 8.0, "desp": 3.0},
	"Avenida de la Sierra": {"esp": "platano", "cada": 9.0, "desp": 4.2},
	"Calle Lardero": {"esp": "magnolio", "cada": 8.0, "desp": 3.4},
}

const ESPECIES := {
	"platano": {"cols": [Color(0.48, 0.68, 0.30), Color(0.55, 0.74, 0.34), Color(0.43, 0.63, 0.27)], "tronco": 2.6, "copa": 2.7},
	"magnolio": {"cols": [Color(0.16, 0.34, 0.16), Color(0.20, 0.40, 0.19), Color(0.13, 0.29, 0.14)], "tronco": 2.2, "copa": 2.1},
	"palmera": {"cols": [Color(0.36, 0.58, 0.26), Color(0.42, 0.63, 0.29)], "tronco": 4.6, "copa": 2.0},
}

func _plantar(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray,
		pos: Vector2, esp: Dictionary, semilla: int) -> void:
	var y := _altura(pos.x, pos.y)
	var ht := float(esp["tronco"])
	_caja_en(verts, normals, cols, Vector3(pos.x, y + ht * 0.5, pos.y), Vector3(0.20, ht, 0.20), Color(0.35, 0.25, 0.16), 0.0)
	var cols_esp: Array = esp["cols"]
	var col: Color = cols_esp[semilla % cols_esp.size()]
	var copa := float(esp["copa"])
	if ht > 4.0:
		# Palmera: penacho ancho y plano (esfera aplastada) sobre el tronco alto
		_bola_en(verts, normals, cols, Vector3(pos.x, y + ht + 0.30, pos.y), copa * 0.95, col, float(semilla) * 2.3 + pos.x, 0.32)
	else:
		_bola_en(verts, normals, cols, Vector3(pos.x, y + ht + copa * 0.42, pos.y), copa * 0.62, col, float(semilla) * 1.7 + pos.x)
		_bola_en(verts, normals, cols, Vector3(pos.x + copa * 0.30, y + ht + copa * 0.30, pos.y + copa * 0.18), copa * 0.42, col.darkened(0.07), float(semilla) * 3.1 + pos.y)

func _crear_recetas() -> void:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var n := 0
	var calles_ok := {}
	for calle in _calles_nombradas:
		var nombre := String(calle["n"])
		if not RECETAS.has(nombre):
			continue
		calles_ok[nombre] = true
		var rec: Dictionary = RECETAS[nombre]
		var esp: Dictionary = ESPECIES[String(rec["esp"])]
		var pts: Array = calle["p"]
		var resto := float(rec["cada"]) * 0.5
		var lado := 1.0
		for i in range(pts.size() - 1):
			var a := Vector2(float(pts[i][0]), float(pts[i][1]))
			var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			var largo := a.distance_to(b)
			if largo < 0.01:
				continue
			var dir := (b - a) / largo
			var perp := Vector2(-dir.y, dir.x)
			var d := resto
			while d < largo:
				if n < 600:
					var pos := a + dir * d + perp * (lado * float(rec["desp"]))
					if not _choca(pos, 0.55):
						_plantar(verts, normals, cols, pos, esp, n)
						n += 1
				lado = -lado
				d += float(rec["cada"])
			resto = d - largo
	if n > 0:
		add_child(_malla_de(verts, normals, cols, Color.WHITE))
	print("RECETAS_OK calles=", calles_ok.size(), " arboles=", n)

# ---------- Fase 5.4: tráfico circulante ----------

func _modelo_coche_fundido(color: Color, estilo := "normal", dims := Vector3(1.8, 0.55, 4.2)) -> MeshInstance3D:
	# Coche de tráfico como UNA sola malla de colores de vértice (cuerpo,
	# cabina y ruedas salen de _coche_en; se añaden faros y pilotos). El
	# modelo por piezas creaba ~14 objetos por coche, y la suma de objetos
	# en pantalla acababa tumbando la vista 3D de la versión web.
	var hh := 0.109
	if estilo == "furgo":
		hh = 0.011
	elif estilo == "familiar":
		hh = 0.037
	elif estilo == "deportivo":
		hh = 0.062
	elif estilo == "clasico":
		hh = 0.081
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	_coche_en(verts, normals, cols, Vector3.ZERO, 0.0, color, hh)
	var l := dims.z
	var w := dims.x
	_caja_en(verts, normals, cols, Vector3(-(w / 2.0 - 0.28), 0.62, l / 2.0 - 0.02), Vector3(0.34, 0.16, 0.06), Color(1.0, 0.96, 0.78), 0.0)
	_caja_en(verts, normals, cols, Vector3(w / 2.0 - 0.28, 0.62, l / 2.0 - 0.02), Vector3(0.34, 0.16, 0.06), Color(1.0, 0.96, 0.78), 0.0)
	_caja_en(verts, normals, cols, Vector3(-(w / 2.0 - 0.28), 0.62, -l / 2.0 + 0.02), Vector3(0.34, 0.14, 0.06), Color(0.75, 0.12, 0.10), 0.0)
	_caja_en(verts, normals, cols, Vector3(w / 2.0 - 0.28, 0.62, -l / 2.0 + 0.02), Vector3(0.34, 0.14, 0.06), Color(0.75, 0.12, 0.10), 0.0)
	return _malla_de(verts, normals, cols, Color.WHITE)

func _crear_trafico() -> void:
	# Solo coches: el catálogo también trae las bicis, y el tráfico
	# dibujaba una bici como un cochecito en miniatura.
	var pool: Array = []
	for cat_p in COCHES:
		if not (String(cat_p["estilo"]) in ["bici", "mtb"]):
			pool.append(cat_p)
	for k in 22:
		var lim_tx := 620.0 if k % 2 == 0 else 1250.0
		var lim_tz := 460.0 if k % 2 == 0 else 950.0
		var nodo := -1
		for intento in 60:
			var cand := _rng.randi() % _nodos.size()
			var np: Vector2 = _nodos[cand]
			if absf(np.x) <= lim_tx and absf(np.y) <= lim_tz and _ady.has(cand) and not (_ady[cand] as Array).is_empty():
				nodo = cand
				break
		if nodo < 0:
			continue
		var cat_t: Dictionary = pool[_rng.randi() % pool.size()]
		var coche := _modelo_coche_fundido(cat_t["color"], String(cat_t["estilo"]), cat_t["dims"])
		var np2: Vector2 = _nodos[nodo]
		coche.position = Vector3(np2.x, _altura(np2.x, np2.y), np2.y)
		add_child(coche)
		var vecinos: Array = _ady[nodo]
		var sig: int = vecinos[_rng.randi() % vecinos.size()][0]
		_trafico.append({"nodo3d": coche, "destino": sig, "previo": nodo, "vel": 6.5 + _rng.randf() * 3.0, "vel_act": 0.0})
	print("TRAFICO_OK n=", _trafico.size())

func _mover_trafico(delta: float) -> void:
	for t in _trafico:
		var coche: Node3D = t["nodo3d"]
		var dp: Vector2 = _nodos[int(t["destino"])]
		var hacia := Vector2(dp.x - coche.position.x, dp.y - coche.position.z)
		if hacia.length() < 3.0:
			var actual: int = t["destino"]
			var vecinos: Array = _ady.get(actual, [])
			if vecinos.is_empty():
				continue
			var opciones := []
			for v in vecinos:
				if int(v[0]) != int(t["previo"]):
					opciones.append(int(v[0]))
			if opciones.is_empty():
				opciones = [int(vecinos[0][0])]
			t["previo"] = actual
			t["destino"] = opciones[_rng.randi() % opciones.size()]
			continue
		var dir := hacia / hacia.length()
		var derecha := Vector2(-dir.y, dir.x)
		var obj := dp + derecha * 1.3
		var hacia_obj := Vector2(obj.x - coche.position.x, obj.y - coche.position.z)
		if hacia_obj.length() > 0.1:
			dir = hacia_obj / hacia_obj.length()
		var vel_obj := float(t["vel"])
		var to_j := Vector2(_jugador.position.x - coche.position.x, _jugador.position.z - coche.position.z)
		if to_j.length() < 7.5 and to_j.length() > 0.01 and dir.dot(to_j / to_j.length()) > 0.55:
			vel_obj = 0.0
		if _en_coche:
			var to_c := Vector2(_coche.position.x - coche.position.x, _coche.position.z - coche.position.z)
			if to_c.length() < 8.5 and to_c.length() > 0.01 and dir.dot(to_c / to_c.length()) > 0.55:
				vel_obj = 0.0
		if vel_obj > 0.0:
			for peat_t in _peatones:
				var rp_t: Node3D = peat_t["raiz"]
				var to_p := Vector2(rp_t.position.x - coche.position.x, rp_t.position.z - coche.position.z)
				if to_p.length() < 7.5 and to_p.length() > 0.01 and dir.dot(to_p / to_p.length()) > 0.55:
					vel_obj = 0.0
					break
		if vel_obj > 0.0:
			for est_t in _estaticos:
				var re_t: Node3D = est_t["raiz"]
				var to_e := Vector2(re_t.position.x - coche.position.x, re_t.position.z - coche.position.z)
				if to_e.length() < 7.5 and to_e.length() > 0.01 and dir.dot(to_e / to_e.length()) > 0.55:
					vel_obj = 0.0
					break
		var va := float(t["vel_act"])
		if vel_obj == 0.0 and va > 3.5 and _tiempo > _bocina_cd and _rng.randf() < 0.3:
			_bocina_cd = _tiempo + 7.0
			_sonar("bocina_lejana")
		va = move_toward(va, vel_obj, (10.0 if vel_obj < va else 5.0) * delta)
		t["vel_act"] = va
		coche.position.x += dir.x * va * delta
		coche.position.z += dir.y * va * delta
		coche.position.y = _altura(coche.position.x, coche.position.z)
		coche.rotation.y = atan2(dir.x, dir.y)

# ---------- Autobuses urbanos: la flota que recorre la ciudad ----------

func _modelo_bus_fundido(color_linea: Color = Color(0.15, 0.55, 0.30), con_conductor := true) -> MeshInstance3D:
	# El autobús urbano como UNA malla fundida (25 sueltos no
	# pueden ser 25x15 piezas en la web), pero trabajado
	# (pedido de Jon): ruedas REDONDAS (cilindros de 8 lados),
	# ventanillas de verdad — la banda es hueca, con sus
	# pilares — y dentro se ven el conductor tras el
	# parabrisas y los pasajeros sentados en las ventanillas.
	var blanco := Color(0.92, 0.93, 0.94)
	var verde := color_linea
	var oscuro := Color(0.13, 0.14, 0.17)
	var cristal := Color(0.55, 0.68, 0.76)
	var cajas: Array = [
		# interior oscuro (lo que se ve entre los pasajeros)
		[Vector3(0, 1.30, 0), Vector3(1.70, 1.85, 10.6), oscuro],
		# falda inferior del color de la línea
		[Vector3(0, 0.60, 0), Vector3(2.54, 0.55, 11.0), verde],
		# paneles laterales bajo las ventanillas y travesaño
		[Vector3(-1.26, 1.06, 0), Vector3(0.06, 0.42, 10.9), blanco],
		[Vector3(1.26, 1.06, 0), Vector3(0.06, 0.42, 10.9), blanco],
		[Vector3(-1.26, 2.24, 0), Vector3(0.06, 0.26, 10.9), blanco],
		[Vector3(1.26, 2.24, 0), Vector3(0.06, 0.26, 10.9), blanco],
		[Vector3(0, 2.44, 0), Vector3(2.42, 0.14, 10.7), blanco],
		# frente y trasera: panel bajo, panel sobre el cristal
		[Vector3(0, 1.06, 5.47), Vector3(2.46, 0.42, 0.06), blanco],
		[Vector3(0, 1.06, -5.47), Vector3(2.46, 0.42, 0.06), blanco],
		[Vector3(0, 2.24, 5.47), Vector3(2.46, 0.26, 0.06), blanco],
		[Vector3(0, 2.24, -5.47), Vector3(2.46, 0.26, 0.06), blanco],
		# luneta trasera (cristal cerrado) y pilar del parabrisas
		[Vector3(0, 1.74, -5.48), Vector3(1.90, 0.74, 0.04), cristal],
		[Vector3(0, 1.74, 5.47), Vector3(0.10, 0.74, 0.06), blanco],
		# letrero de línea, faros y pilotos
		[Vector3(0, 2.24, 5.53), Vector3(1.6, 0.40, 0.06), verde],
		[Vector3(-0.8, 0.92, 5.52), Vector3(0.40, 0.25, 0.08), Color(1.0, 0.96, 0.78)],
		[Vector3(0.8, 0.92, 5.52), Vector3(0.40, 0.25, 0.08), Color(1.0, 0.96, 0.78)],
		[Vector3(-0.8, 0.92, -5.52), Vector3(0.40, 0.22, 0.08), Color(0.80, 0.15, 0.12)],
		[Vector3(0.8, 0.92, -5.52), Vector3(0.40, 0.22, 0.08), Color(0.80, 0.15, 0.12)],
		# puerta delantera con su cristal (lado de la acera)
		[Vector3(-1.27, 1.30, 3.95), Vector3(0.05, 1.95, 1.25), oscuro],
		[Vector3(-1.28, 1.78, 3.95), Vector3(0.04, 0.75, 1.05), cristal],
		# retrovisores
		[Vector3(-1.36, 2.02, 5.30), Vector3(0.07, 0.30, 0.16), oscuro],
		[Vector3(1.36, 2.02, 5.30), Vector3(0.07, 0.30, 0.16), oscuro],
	]
	# Pilares entre ventanillas (los huecos son las ventanas)
	for lado in [-1.26, 1.26]:
		for pz in [-5.30, -3.95, -2.65, -1.35, 0.0, 1.35, 2.65, 3.95, 5.30]:
			if lado < 0.0 and pz > 3.2 and pz < 4.7:
				continue  # ese tramo lo ocupa la puerta
			cajas.append([Vector3(lado, 1.74, pz), Vector3(0.06, 0.74, 0.22), blanco])
	var pieles: Array = [Color(0.93, 0.74, 0.60), Color(0.88, 0.64, 0.47), Color(0.72, 0.50, 0.36), Color(0.84, 0.60, 0.44)]
	var camisas: Array = [Color(0.80, 0.30, 0.25), Color(0.25, 0.40, 0.75), Color(0.30, 0.65, 0.40), Color(0.90, 0.75, 0.30), Color(0.60, 0.35, 0.70), Color(0.90, 0.90, 0.92), Color(0.95, 0.55, 0.20), Color(0.35, 0.35, 0.38)]
	var pelos: Array = [Color(0.16, 0.11, 0.07), Color(0.45, 0.30, 0.16), Color(0.10, 0.08, 0.06), Color(0.70, 0.60, 0.35), Color(0.85, 0.84, 0.80)]
	if con_conductor:
		# El conductor, tras el parabrisas, con su volante
		cajas.append([Vector3(0.55, 1.52, 4.62), Vector3(0.46, 0.55, 0.30), Color(0.92, 0.92, 0.94)])
		cajas.append([Vector3(0.55, 1.94, 4.62), Vector3(0.25, 0.27, 0.25), pieles[0]])
		cajas.append([Vector3(0.55, 2.09, 4.62), Vector3(0.27, 0.06, 0.27), pelos[0]])
		cajas.append([Vector3(0.55, 1.28, 5.02), Vector3(0.44, 0.30, 0.07), oscuro])
	# Pasajeros sentados: en cada ventanilla, según el azar
	# de este bus (cada autobús lleva gente distinta)
	for lado in [-1.0, 1.0]:
		for pz in [-4.60, -3.30, -2.00, -0.70, 0.65, 2.00, 3.30]:
			if lado < 0.0 and pz > 2.6:
				continue  # delante, en ese lado, va la puerta
			if _rng.randf() < 0.42:
				continue
			var px: float = 1.02 * lado
			var camisa_p: Color = camisas[_rng.randi() % camisas.size()]
			var piel_p: Color = pieles[_rng.randi() % pieles.size()]
			var pelo_p: Color = pelos[_rng.randi() % pelos.size()]
			var dy := (_rng.randf() - 0.5) * 0.07
			cajas.append([Vector3(px, 1.50 + dy, pz), Vector3(0.46, 0.52, 0.30), camisa_p])
			cajas.append([Vector3(px, 1.90 + dy, pz), Vector3(0.24, 0.26, 0.24), piel_p])
			cajas.append([Vector3(px, 2.04 + dy, pz), Vector3(0.26, 0.06, 0.26), pelo_p])
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	for cj in cajas:
		var parte: Array = cj
		_caja_en(verts, normals, cols, parte[0], parte[1], parte[2], 0.0)
	# Ruedas redondas: cilindros con su buje claro
	for sx in [-1.13, 1.13]:
		for sz in [-3.6, 3.6]:
			_columna_ruina(verts, normals, cols, Vector3(sx - 0.18, 0.5, sz), Vector3.RIGHT, 0.36, 0.50, Color(0.09, 0.09, 0.10))
			_columna_ruina(verts, normals, cols, Vector3(sx - 0.21, 0.5, sz), Vector3.RIGHT, 0.42, 0.22, Color(0.55, 0.56, 0.58))
	return _malla_de(verts, normals, cols, Color.WHITE)

func _proyeccion(p: Vector2, a: Vector2, b: Vector2, s0: float) -> Array:
	# [distancia del punto p al segmento ab, s a lo largo del recorrido]
	var ab := b - a
	var largo2 := ab.length_squared()
	var t := 0.0
	if largo2 > 0.001:
		t = clampf((p - a).dot(ab) / largo2, 0.0, 1.0)
	var cerca := a + ab * t
	return [p.distance_to(cerca), s0 + ab.length() * t]

func _crear_lineas_bus() -> void:
	# 5 líneas de autobús urbano (pedido de Jon, 2026-11-23),
	# repartidas por la ciudad: cada una une dos extremos pasando
	# por el centro, con su recorrido calculado sobre el grafo de
	# calles y sus paradas tomadas de la red real (las que queden
	# a menos de 60 m del trazado, ordenadas y sin apelotonar).
	_lineas_bus.clear()
	# Extremos SIEMPRE en rotonda (Jon, 2026-11-24: «cada
	# linea debe empezar y terminar en una rotonda, para que
	# el autobus no tenga que hacer cosas raras; esto es
	# fundamental») y la rotonda ENTERA (Jon, al ver la
	# primera version: «la idea de la rotonda es que la
	# hagan entera, no solo una parte: hacen la rotonda
	# entera y vuelven por donde han venido»): la primera y
	# la ultima ancla de cada linea son el nodo de ENTRADA
	# de una rotonda real del grafo, y al llegar a la
	# cabecera el bus recorre el anillo completo (los puntos
	# del giro van en datos/ciudad/rotondas_bus.json, en el
	# sentido contrario a las agujas del reloj, como se
	# circula en Espana) antes de dar la vuelta y volver por
	# donde vino. De paso se quitaron las ramas que senalo
	# (la de la L1 junto a la UNIR y la de la L5 al este,
	# salidas y vueltas por la misma callejuela) y dos
	# anclas que forzaban rodeos: la de la L1 sobre la
	# avenida (1500,480 -> 1482.5,542, un nodo de la propia
	# avenida) y la de la L4 en (1700,-580), que obligaba a
	# ir y volver por el mismo corredor del este; la L5 del
	# sur se alarga hasta la rotonda de Los Cascajos porque
	# El Cubo no tiene ninguna. Segunda pasada del mismo
	# dia (Jon: «la linea roja hace cosas muy raras,
	# simplifica», y otra rama rectangular senalada en la
	# L5): las anclas intermedias que caian en callejuelas
	# laterales (L1 -700,-20, L2 -180,-600, L3 850,230,
	# L5 950,150 y 850,750) se movieron a la calle principal
	# de cada linea o se quitaron; cada ancla tiene que
	# caer SOBRE la calle que la linea sigue, porque si
	# cae en una rama, el bus entra y sale de la rama.
	# Tercera pasada (Jon, sobre la captura del Espolon:
	# «simplifica esta linea, que vaya por Vara de Rey
	# hasta la rotonda del Labrador y luego Gran Via»): la
	# L4 cruzaba el centro en escalera entre (250,180) y
	# (-450,520); ahora entra por Vara de Rey (anclas sobre
	# la propia avenida: -101,199.5 y -161,406), pasa la
	# rotonda del Labrador y sale por Gran Via (-365,422
	# y -813,261) hacia Yagüe.
	var defs: Array = [
		{"ext": "Varea — El Campillo", "c": Color(0.92, 0.25, 0.22), "anclas": [Vector2(1920.5, 675.5), Vector2(1482.5, 542), Vector2(700, 280), Vector2(0, 120), Vector2(-798, -6), Vector2(-1522, -301.5), Vector2(-1786, -697.5)]},
		{"ext": "Las Norias — La Grajera", "c": Color(0.20, 0.45, 1.00), "anclas": [Vector2(-148, -965), Vector2(-160, -582.5), Vector2(-60, 60), Vector2(-120, 650), Vector2(-280, 1250), Vector2(-435, 1471)]},
		{"ext": "Valdegastea — Universidad", "c": Color(0.15, 0.65, 0.30), "anclas": [Vector2(-1983, 544), Vector2(-1550, 520), Vector2(-750, 430), Vector2(50, 330), Vector2(868, 203.5), Vector2(1650, 90), Vector2(2009, 421.5)]},
		{"ext": "Yagüe — Madre de Dios", "c": Color(1.00, 0.55, 0.10), "anclas": [Vector2(-1880.5, 1219.5), Vector2(-1150, 820), Vector2(-813, 261), Vector2(-365, 422), Vector2(-161, 406), Vector2(-101, 199.5), Vector2(250, 180), Vector2(950, -220), Vector2(2146, -565)]},
		{"ext": "El Cubo — Cascajos", "c": Color(0.60, 0.35, 0.90), "anclas": [Vector2(1651, -1566.5), Vector2(1236.5, -1201), Vector2(885, 180), Vector2(690, 753), Vector2(550, 1350), Vector2(446, 1724)]},
	]
	# Los giros completos de las rotondas de cabecera,
	# horneados desde OSM (anillo ordenado, cerrado sobre
	# el nodo de entrada de cada extremo).
	var giros_d: Dictionary = {}
	if FileAccess.file_exists("res://datos/ciudad/rotondas_bus.json"):
		var parsed_g = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/rotondas_bus.json"))
		if parsed_g is Dictionary:
			giros_d = parsed_g
	for d in defs:
		var pts: Array = []
		var anclas: Array = d["anclas"]
		for i in range(anclas.size() - 1):
			var a2: Vector2 = anclas[i]
			var b2: Vector2 = anclas[i + 1]
			var tramo := _ruta_calle(Vector3(a2.x, 0, a2.y), Vector3(b2.x, 0, b2.y))
			for p3 in tramo:
				var p2 := Vector2((p3 as Vector3).x, (p3 as Vector3).z)
				if pts.is_empty() or (pts[pts.size() - 1] as Vector2).distance_to(p2) > 0.5:
					pts.append(p2)
		if pts.size() < 2:
			continue
		var ss: Array = [0.0]
		for i in range(1, pts.size()):
			ss.append(float(ss[i - 1]) + (pts[i] as Vector2).distance_to(pts[i - 1]))
		var longitud := float(ss[ss.size() - 1])
		var cands: Array = []
		for par in _paradas_red:
			var pp := Vector2(float(par["x"]), float(par["z"]))
			var mejor := 1e9
			var s_mejor := 0.0
			for i in range(pts.size() - 1):
				var seg := _proyeccion(pp, pts[i], pts[i + 1], float(ss[i]))
				if float(seg[0]) < mejor:
					mejor = float(seg[0])
					s_mejor = float(seg[1])
			if mejor <= 60.0:
				cands.append({"x": pp.x, "z": pp.y, "s": s_mejor, "n": String(par.get("n", "Parada"))})
		cands.sort_custom(func(a, b): return float(a["s"]) < float(b["s"]))
		var paradas: Array = []
		for c in cands:
			if paradas.is_empty() or float(c["s"]) - float(paradas[paradas.size() - 1]["s"]) >= 130.0:
				paradas.append(c)
		var giro_ini: Array = []
		var giro_fin: Array = []
		var gd: Dictionary = giros_d.get(str(_lineas_bus.size()), {})
		for par_g in gd.get("ini", []):
			giro_ini.append(Vector2(float(par_g[0]), float(par_g[1])))
		for par_g in gd.get("fin", []):
			giro_fin.append(Vector2(float(par_g[0]), float(par_g[1])))
		_lineas_bus.append({"ext": String(d["ext"]), "c": d["c"], "pts": pts, "s": ss, "longitud": longitud, "paradas": paradas, "giro_ini": giro_ini, "giro_fin": giro_fin})
		print("LINEA_OK ", _lineas_bus.size(), " pts=", pts.size(), " paradas=", paradas.size(), " long=", int(longitud))

func _crear_buses_urbanos() -> void:
	# 25 autobuses urbanos: 5 por línea, repartidos por el
	# trazado en los dos sentidos, cada uno con el color de su
	# línea en la banda y el letrero.
	_crear_lineas_bus()
	for li in _lineas_bus.size():
		var lin: Dictionary = _lineas_bus[li]
		var pts: Array = lin["pts"]
		var ss: Array = lin["s"]
		for j in 5:
			var s_obj := float(lin["longitud"]) * (float(j) / 5.0 + 0.03 * float(li))
			var ip := 0
			while ip < ss.size() - 1 and float(ss[ip]) < s_obj:
				ip += 1
			var dir := 1 if j % 2 == 0 else -1
			var p0: Vector2 = pts[ip]
			var bus := Node3D.new()
			bus.add_child(_modelo_bus_fundido(lin["c"]))
			bus.position = Vector3(p0.x, _altura(p0.x, p0.y), p0.y)
			add_child(bus)
			var idx := clampi(ip + dir, 0, pts.size() - 1)
			_buses_urbanos.append({"nodo3d": bus, "linea": li, "idx": idx, "dir": dir, "s": float(ss[ip]), "vel": 6.0 + _rng.randf() * 1.5, "vel_act": 0.0, "parada_t": 0.0, "espera": _rng.randf() * 20.0, "giro": [], "giro_i": 0, "giro_fin_dir": 1})
	print("BUSES_OK n=", _buses_urbanos.size())

func _mover_buses(delta: float) -> void:
	for bu in _buses_urbanos:
		var bus: Node3D = bu["nodo3d"]
		bu["espera"] = float(bu["espera"]) - delta
		if float(bu["parada_t"]) > 0.0:
			bu["parada_t"] = float(bu["parada_t"]) - delta
			bu["vel_act"] = move_toward(float(bu["vel_act"]), 0.0, 8.0 * delta)
			continue
		var lin: Dictionary = _lineas_bus[int(bu["linea"])]
		var pts: Array = lin["pts"]
		var ss: Array = lin["s"]
		var idx: int = int(bu["idx"])
		var sentido: int = int(bu["dir"])
		if idx < 0 or idx >= pts.size():
			sentido = -sentido
			bu["dir"] = sentido
			idx = clampi(idx, 0, pts.size() - 1)
			bu["idx"] = idx
		# Giro de cabecera en curso: el bus esta recorriendo
		# la rotonda ENTERA (mismo gobierno que en la linea,
		# con su desplazamiento a la derecha, pero sin
		# paradas: la pausa de cabecera viene al cerrar el
		# anillo, en el punto de entrada).
		if not (bu["giro"] as Array).is_empty():
			var gpts: Array = bu["giro"]
			var gi: int = int(bu["giro_i"])
			var gp: Vector2 = gpts[gi]
			var hg := Vector2(gp.x - bus.position.x, gp.y - bus.position.z)
			if hg.length() < 4.0:
				gi += 1
				bu["giro_i"] = gi
				if gi >= gpts.size():
					bu["giro"] = []
					bu["dir"] = int(bu["giro_fin_dir"])
					bu["parada_t"] = 6.0
				continue
			var dirg := hg / hg.length()
			var derg := Vector2(-dirg.y, dirg.x)
			var objg := gp + derg * 1.7
			var hog := Vector2(objg.x - bus.position.x, objg.y - bus.position.z)
			if hog.length() > 0.1:
				dirg = hog / hog.length()
			var velg := float(bu["vel"])
			var to_jg := Vector2(_jugador.position.x - bus.position.x, _jugador.position.z - bus.position.z)
			if to_jg.length() < 9.0 and to_jg.length() > 0.01 and dirg.dot(to_jg / to_jg.length()) > 0.5:
				velg = 0.0
			var vag := float(bu["vel_act"])
			vag = move_toward(vag, velg, (9.0 if velg < vag else 4.0) * delta)
			bu["vel_act"] = vag
			bus.position.x += dirg.x * vag * delta
			bus.position.z += dirg.y * vag * delta
			bus.position.y = _altura(bus.position.x, bus.position.z)
			bus.rotation.y = atan2(dirg.x, dirg.y)
			continue
		var dp: Vector2 = pts[idx]
		var hacia := Vector2(dp.x - bus.position.x, dp.y - bus.position.z)
		if hacia.length() < 4.0:
			bu["s"] = float(ss[idx])
			var sig := idx + sentido
			if sig < 0 or sig >= pts.size():
				# Cabecera de linea: si la cabecera es una
				# rotonda, el bus la recorre ENTERA antes de
				# volver por donde vino (la media vuelta y la
				# pausa se hacen al cerrar el anillo); si no
				# hay giro definido, pausa y media vuelta.
				var gl: Array = lin["giro_ini"] if sig < 0 else lin["giro_fin"]
				if not gl.is_empty():
					bu["giro"] = gl
					bu["giro_i"] = 0
					bu["giro_fin_dir"] = -sentido
				else:
					bu["dir"] = -sentido
					bu["parada_t"] = 6.0
				sig = idx
			bu["idx"] = sig
			continue
		var dir := hacia / hacia.length()
		var derecha := Vector2(-dir.y, dir.x)
		var obj := dp + derecha * 1.7
		var hacia_obj := Vector2(obj.x - bus.position.x, obj.y - bus.position.z)
		if hacia_obj.length() > 0.1:
			dir = hacia_obj / hacia_obj.length()
		var vel_obj := float(bu["vel"])
		var to_j := Vector2(_jugador.position.x - bus.position.x, _jugador.position.z - bus.position.z)
		if to_j.length() < 9.0 and to_j.length() > 0.01 and dir.dot(to_j / to_j.length()) > 0.5:
			vel_obj = 0.0
		if vel_obj > 0.0 and _en_coche:
			var to_c := Vector2(_coche.position.x - bus.position.x, _coche.position.z - bus.position.z)
			if to_c.length() < 10.0 and to_c.length() > 0.01 and dir.dot(to_c / to_c.length()) > 0.5:
				vel_obj = 0.0
		# Parada en las paradas DE SU LÍNEA: la posición del bus
		# sobre el recorrido (s) manda, no la cercanía física a la
		# marquesina — la parada puede estar en la acera de
		# enfrente o a la vuelta de la esquina y el bus para igual.
		var s_aprox := float(ss[idx]) - float(sentido) * hacia.length()
		bu["s"] = s_aprox
		if vel_obj > 0.0 and float(bu["espera"]) <= 0.0:
			for par in lin["paradas"]:
				if absf(s_aprox - float(par["s"])) < 9.0:
					bu["parada_t"] = 4.0
					bu["espera"] = 25.0
					vel_obj = 0.0
					break
		var va := float(bu["vel_act"])
		va = move_toward(va, vel_obj, (9.0 if vel_obj < va else 4.0) * delta)
		bu["vel_act"] = va
		bus.position.x += dir.x * va * delta
		bus.position.z += dir.y * va * delta
		bus.position.y = _altura(bus.position.x, bus.position.z)
		bus.rotation.y = atan2(dir.x, dir.y)

# ---------- El autobús como pasajero (1 €) ----------

func _bus_linea_cercano() -> Dictionary:
	if _jugador == null:
		return {}
	var mejor: Dictionary = {}
	var mejor_d := 6.5
	for bu in _buses_urbanos:
		var b: Node3D = bu["nodo3d"]
		var d := Vector2(b.position.x - _jugador.position.x, b.position.z - _jugador.position.z).length()
		if d < mejor_d:
			mejor_d = d
			mejor = bu
	return mejor

func _subir_bus_pasajero(bu: Dictionary) -> void:
	if bu.is_empty() or not _bus_pasajero.is_empty():
		return
	if _dinero < 1:
		_aviso_set("No te llega: el billete del autobús cuesta 1 €", 3.5)
		return
	_dinero -= 1
	_actualizar_hud_dinero()
	if _son_cobro != null:
		_son_cobro.play()
	_bus_pasajero = bu
	bu["parada_t"] = maxf(float(bu["parada_t"]), 2.5)
	_aviso_set("Autobús línea " + str(int(bu["linea"]) + 1) + " · billete 1 € · baja con E cuando quieras", 4.0)
	_guardar()

func _bajar_bus_pasajero() -> void:
	if _bus_pasajero.is_empty():
		return
	var bus: Node3D = _bus_pasajero["nodo3d"]
	_bus_pasajero = {}
	var lado3 := bus.global_transform.basis.x
	var lado := Vector3(lado3.x, 0, lado3.z).normalized() * 2.8
	var libre := _punto_libre(bus.position + lado, 0.5)
	_jugador.position = Vector3(libre.x, _altura(libre.x, libre.z) + 0.95, libre.z)
	_aviso_set("Has bajado del autobús", 2.5)

func _actualizar_pasajero(_delta: float) -> void:
	if _bus_pasajero.is_empty():
		return
	var bus: Node3D = _bus_pasajero["nodo3d"]
	if not is_instance_valid(bus):
		_bus_pasajero = {}
		return
	_jugador.position = Vector3(bus.position.x, _altura(bus.position.x, bus.position.z) + 0.95, bus.position.z)
	_jugador.rotation.y = bus.rotation.y

func _proxima_parada_nombre(bu: Dictionary) -> String:
	var lin: Dictionary = _lineas_bus[int(bu["linea"])]
	var s_bus := float(bu["s"])
	var paradas_l: Array = lin["paradas"]
	if int(bu["dir"]) > 0:
		for par in paradas_l:
			if float(par["s"]) > s_bus + 8.0:
				return String(par["n"])
	else:
		for i in range(paradas_l.size() - 1, -1, -1):
			if float(paradas_l[i]["s"]) < s_bus - 8.0:
				return String(paradas_l[i]["n"])
	return "fin de línea"

func _probar_decathlon() -> void:
	var pasa := true
	pasa = pasa and _interiores.has("decathlon")
	# El camino de verdad: de pie ante la puerta visible del
	# frente de marca (-2458, 1564), la E tiene que ofrecer la
	# entrada (Jon: «estoy en la puerta y no puedo entrar»).
	_jugador.position = Vector3(-2456.0, _altura(-2456.0, 1564.0) + 0.95, 1564.0)
	pasa = pasa and _puerta_cercana() == "decathlon"
	_entrar_interior("decathlon")
	pasa = pasa and _en_interior == "decathlon"
	var accs: Dictionary = _interiores["decathlon"]["acciones"]
	pasa = pasa and accs.size() == 10
	# Junto a las bicis, la acción cercana es comprar la Grajera
	_jugador.position = (accs["comprar:dec_bici"] as Vector3) + Vector3(0, 0.95, 0)
	pasa = pasa and _accion_interior_cercana() == "comprar:dec_bici"
	# Comprar el balón descuenta 20 €; la bici entra en el garaje
	_dinero = 500
	_comprar_tienda("dec_balon")
	pasa = pasa and _dinero == 480
	var g0 := _mis_coches.size()
	_comprar_tienda("dec_bici")
	pasa = pasa and _dinero == 30
	pasa = pasa and _mis_coches.size() == g0 + 1 and int(_mis_coches[_mis_coches.size() - 1]["id"]) == 13
	# Sin dinero, no hay compra
	_comprar_tienda("dec_tienda")
	pasa = pasa and _dinero == 30
	# Comprar por los caminos de verdad: la tecla E como evento
	# por _input, el botón táctil y el botón A del mando. Antes
	# la E pedía «ec_casco» (substr(9) sobre «comprar:») y no
	# pasaba nada; el botón y el mando ni tenían rama de compra.
	_dinero = 100
	_jugador.position = (accs["comprar:dec_casco"] as Vector3) + Vector3(0, 0.95, 0)
	var ev := InputEventKey.new()
	ev.keycode = KEY_E
	ev.pressed = true
	_input(ev)
	pasa = pasa and _dinero == 65 and _bolsa_en_mano
	_btn_modo = "comprar:dec_mochila"
	_t_coche()
	pasa = pasa and _dinero == 25
	var evp := InputEventJoypadButton.new()
	evp.button_index = JOY_BUTTON_A
	evp.pressed = true
	_jugador.position = (accs["comprar:dec_banador"] as Vector3) + Vector3(0, 0.95, 0)
	_input(evp)
	pasa = pasa and _dinero == 0
	# Sin dinero para la Grajera: avisa «No te llega» y no cobra
	_jugador.position = (accs["comprar:dec_bici"] as Vector3) + Vector3(0, 0.95, 0)
	_input(ev)
	pasa = pasa and _dinero == 0 and _aviso.begins_with("No te llega")
	_salir_interior()
	pasa = pasa and _en_interior == ""
	print("DECATHLON_PRUEBA_OK pasa=", pasa, " acciones=", accs.size(), " dinero=", _dinero, " garaje=", _mis_coches.size())

func _probar_ra() -> void:
	var pasa := true
	var n_ra := 0
	for pu in _puentes:
		if String(pu.get("n", "")) == "República Argentina (ferrocarril)":
			n_ra += 1
	pasa = pasa and n_ra >= 8
	# Sobre las vías, las DOS calzadas van altas…
	var h1 := _altura(-649.4, 1074.9) - _altura_terreno(-649.4, 1074.9)
	var h2 := _altura(-657.3, 1077.8) - _altura_terreno(-657.3, 1077.8)
	pasa = pasa and h1 > 3.6 and h2 > 3.4
	# …y a ~100 m la avenida ya rueda a ras de suelo
	var h3 := _altura(-680.6, 1176.6) - _altura_terreno(-680.6, 1176.6)
	var h4 := _altura(-622.0, 972.6) - _altura_terreno(-622.0, 972.6)
	pasa = pasa and h3 < 0.7 and h4 < 0.7
	print("RA_PRUEBA_OK pasa=", pasa, " tramos=", n_ra, " h_cruce=", snappedf(h1, 0.1), "/", snappedf(h2, 0.1), " h_extremos=", snappedf(h3, 0.1), "/", snappedf(h4, 0.1))

func _probar_buses() -> void:
	var pasa := true
	pasa = pasa and _buses_urbanos.size() == 25
	# El censo de peatones varía con el azar de la colocación
	# (hay días de 67 y días de 78): el mínimo pide «ciudad
	# poblada», no un censo exacto.
	pasa = pasa and _peatones.size() >= 60
	var antes: Array = []
	for bu in _buses_urbanos:
		antes.append((bu["nodo3d"] as Node3D).position)
	for paso in 40:
		_mover_buses(0.5)
	var movido := 0.0
	for i in _buses_urbanos.size():
		movido += (_buses_urbanos[i]["nodo3d"] as Node3D).position.distance_to(antes[i])
	pasa = pasa and movido > 60.0
	# Un bus que llega a una parada DE SU LÍNEA con la espera
	# agotada se detiene en ella: se le coloca SOBRE su recorrido,
	# 6 m antes de la parada en su sentido de marcha (la parada
	# manda por su s en el trazado, no por cercanía física).
	var bu0: Dictionary = _buses_urbanos[0]
	var lin0: Dictionary = _lineas_bus[int(bu0["linea"])]
	if not (lin0["paradas"] as Array).is_empty():
		var par0: Dictionary = lin0["paradas"][0]
		var bus0: Node3D = bu0["nodo3d"]
		var pts0: Array = lin0["pts"]
		var ss0: Array = lin0["s"]
		var iw := 1
		while iw < ss0.size() - 1 and float(ss0[iw]) < float(par0["s"]):
			iw += 1
		var seg0 := (pts0[iw] as Vector2) - (pts0[iw - 1] as Vector2)
		var t0 := 0.0
		if seg0.length() > 0.01:
			t0 = (float(par0["s"]) - float(ss0[iw - 1])) / seg0.length()
		var proj0: Vector2 = (pts0[iw - 1] as Vector2) + seg0 * clampf(t0, 0.0, 1.0)
		var dir_ruta := seg0.normalized() * float(int(bu0["dir"]))
		var pp0 := proj0 - dir_ruta * 6.0
		bus0.position = Vector3(pp0.x, _altura(pp0.x, pp0.y), pp0.y)
		bu0["idx"] = iw if int(bu0["dir"]) > 0 else iw - 1
		bu0["espera"] = 0.0
		bu0["parada_t"] = 0.0
		bu0["vel_act"] = 5.0
		var paro := false
		for paso2 in 12:
			_mover_buses(0.4)
			if float(bu0["parada_t"]) > 0.0:
				paro = true
		pasa = pasa and paro
	print("BUSES_PRUEBA_OK pasa=", pasa, " peatones=", _peatones.size(), " trafico=", _trafico.size(), " movido=", snappedf(movido, 0.1))

func _probar_lineas() -> void:
	# Las 5 líneas existen, cruzan la ciudad, tienen paradas de
	# sobra y el plano las recibe; y el pasajero paga 1 €, viaja
	# pegado al autobús y se baja a pie.
	var pasa := true
	pasa = pasa and _lineas_bus.size() == 5
	for lin in _lineas_bus:
		pasa = pasa and float(lin["longitud"]) > 2500.0
		pasa = pasa and (lin["paradas"] as Array).size() >= 6
		pasa = pasa and (lin["pts"] as Array).size() > 40
	var bu: Dictionary = _buses_urbanos[0]
	var bus: Node3D = bu["nodo3d"]
	_jugador.position = Vector3(bus.position.x + 2.0, _altura(bus.position.x, bus.position.z) + 0.95, bus.position.z)
	_dinero = 10
	pasa = pasa and not _bus_linea_cercano().is_empty()
	_subir_bus_pasajero(_bus_linea_cercano())
	pasa = pasa and _dinero == 9 and not _bus_pasajero.is_empty()
	for i in 30:
		_mover_buses(0.5)
		_actualizar_pasajero(0.5)
	pasa = pasa and _jugador.position.distance_to(bus.position) < 2.5
	_bajar_bus_pasajero()
	pasa = pasa and _bus_pasajero.is_empty()
	pasa = pasa and Vector2(_jugador.position.x - bus.position.x, _jugador.position.z - bus.position.z).length() < 8.0
	# Sin dinero no hay billete, y avisa
	_jugador.position = Vector3(bus.position.x + 2.0, _jugador.position.y, bus.position.z)
	_dinero = 0
	_subir_bus_pasajero(_bus_linea_cercano())
	pasa = pasa and _bus_pasajero.is_empty() and _aviso.begins_with("No te llega")
	# Giro ENTERO de rotonda en cabecera (Jon, 2026-11-24):
	# cada linea trae los dos anillos cerrados sobre su
	# nodo de entrada y la direccion gira una vuelta
	# completa al recorrerlos (la suma de giros ~ 2*PI;
	# un arco parcial daria mucho menos).
	for lin in _lineas_bus:
		var gi: Array = lin["giro_ini"]
		var gf: Array = lin["giro_fin"]
		pasa = pasa and gi.size() >= 12 and gf.size() >= 12
		pasa = pasa and (gi[0] as Vector2).distance_to(gi[gi.size() - 1]) < 0.6
		pasa = pasa and (gf[0] as Vector2).distance_to(gf[gf.size() - 1]) < 0.6
		for anillo in [gi, gf]:
			var suma := 0.0
			var n_a: int = anillo.size()
			for k in range(n_a):
				var p_a: Vector2 = anillo[k]
				var p_b: Vector2 = anillo[(k + 1) % n_a]
				var p_c: Vector2 = anillo[(k + 2) % n_a]
				var a1 := atan2(p_b.y - p_a.y, p_b.x - p_a.x)
				var a2 := atan2(p_c.y - p_b.y, p_c.x - p_b.x)
				var da := a2 - a1
				while da > PI:
					da -= TAU
				while da < -PI:
					da += TAU
				suma += da
			pasa = pasa and absf(suma) > 5.5
	# Y un bus puesto en la cabecera de la L1 la rodea de
	# verdad: entra en giro, recorre casi todo el perimetro
	# del anillo (140 m; un arco parcial daria ~70) y sale
	# con el sentido cambiado y su pausa de cabecera.
	var lin0: Dictionary = _lineas_bus[0]
	var bu2: Dictionary = _buses_urbanos[1]
	var bus2: Node3D = bu2["nodo3d"]
	var pts0: Array = lin0["pts"]
	bu2["linea"] = 0
	bu2["idx"] = pts0.size() - 1
	bu2["dir"] = 1
	bu2["parada_t"] = 0.0
	bu2["espera"] = 99999.0
	bu2["giro"] = []
	bu2["vel_act"] = 0.0
	var entrada: Vector2 = pts0[pts0.size() - 1]
	bus2.position = Vector3(entrada.x, _altura(entrada.x, entrada.y), entrada.y)
	_jugador.position = Vector3(-400.0, _altura(-400.0, 0.0) + 0.95, 0.0)
	var vio_giro := false
	var recorrido_giro := 0.0
	var pos_ant := bus2.position
	for i in 600:
		_mover_buses(0.25)
		recorrido_giro += Vector2(bus2.position.x - pos_ant.x, bus2.position.z - pos_ant.z).length()
		pos_ant = bus2.position
		if not (bu2["giro"] as Array).is_empty():
			vio_giro = true
		if vio_giro and (bu2["giro"] as Array).is_empty() and int(bu2["dir"]) == -1:
			break
	pasa = pasa and vio_giro
	pasa = pasa and int(bu2["dir"]) == -1
	pasa = pasa and recorrido_giro > 110.0
	pasa = pasa and Vector2(bus2.position.x - entrada.x, bus2.position.z - entrada.y).length() < 12.0
	var datos := _datos_mapa()
	pasa = pasa and (datos.get("lineas", []) as Array).size() == 5
	print("LINEAS_OK pasa=", pasa, " lineas=", _lineas_bus.size())

# ---------- Fase 7: radares de velocidad ----------

func _crear_radares() -> void:
	var nombres := ["Avenida de La Paz", "Gran Vía Juan Carlos I", "Avenida de Lobete", "Avenida de Madrid"]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	for nombre in nombres:
		var mejor: Array = []
		for c in _calles_nombradas:
			var pts_c: Array = c["p"]
			if String(c["n"]) == nombre and pts_c.size() > mejor.size():
				mejor = pts_c
		if mejor.size() < 3:
			continue
		var im := mejor.size() / 2
		var centro := Vector2(float(mejor[im][0]), float(mejor[im][1]))
		var dir := Vector2(float(mejor[im + 1][0]), float(mejor[im + 1][1])) - centro
		if dir.length() < 0.01:
			continue
		dir = dir.normalized()
		var perp := Vector2(-dir.y, dir.x)
		var lado3 := _punto_libre(Vector3(centro.x + perp.x * 7.0, 0, centro.y + perp.y * 7.0), 0.4)
		var y := _altura(lado3.x, lado3.z)
		var rot := atan2(dir.x, dir.y)
		_caja_en(verts, normals, cols, Vector3(lado3.x, y + 1.1, lado3.z), Vector3(0.18, 2.2, 0.18), Color(0.25, 0.26, 0.30), 0.0)
		_caja_en(verts, normals, cols, Vector3(lado3.x, y + 2.6, lado3.z), Vector3(0.7, 0.9, 0.5), Color(0.55, 0.57, 0.60), rot)
		_caja_en(verts, normals, cols, Vector3(lado3.x, y + 2.78, lado3.z), Vector3(0.42, 0.3, 0.56), Color(0.08, 0.08, 0.10), rot)
		_radares.append(Vector3(centro.x, 0, centro.y))
	if not _radares.is_empty():
		add_child(_malla_de(verts, normals, cols, Color.WHITE))
	print("RADARES_OK n=", _radares.size())

func _comprobar_radares() -> void:
	if not _en_coche or _auto or _tiempo < _radar_cd:
		return
	if absf(_coche_vel) < 13.5:  # 48,6 km/h: el radar salta a partir de 50
		return
	for r in _radares:
		var rp: Vector3 = r
		if Vector2(_coche.position.x - rp.x, _coche.position.z - rp.z).length() < 16.0:
			_radar_cd = _tiempo + 20.0
			_dinero = maxi(0, _dinero - 30)
			_guardar()
			_aviso = "Radar: vas a %d km/h · Multa de 30 €" % int(absf(_coche_vel) * 3.6)
			_aviso_hasta = _tiempo + 5.0
			_actualizar_hud_dinero()
			_actualizar_hud()
			_sonar("radar")
			print("RADAR_MULTA vel_kmh=", int(absf(_coche_vel) * 3.6), " dinero=", _dinero)
			return

# ---------- Fase 5.1: sonido (sintetizado, sin ficheros externos) ----------

func _hacer_player(ruta: String, vol: float, bucle: bool) -> AudioStreamPlayer:
	var flujo = load(ruta)
	if flujo == null:
		return null
	if bucle and flujo is AudioStreamWAV:
		flujo.loop_mode = AudioStreamWAV.LOOP_FORWARD
		flujo.loop_begin = 0
		flujo.loop_end = int(flujo.get_length() * flujo.mix_rate)
	var p := AudioStreamPlayer.new()
	p.stream = flujo
	p.volume_db = vol
	add_child(p)
	return p

func _crear_sonido() -> void:
	_son_motor = _hacer_player("res://audio/motor.wav", -13.0, true)
	_son_amb = _hacer_player("res://audio/ambiente.wav", -21.0, true)
	_son_pasos = _hacer_player("res://audio/paso.wav", -13.0, false)
	_son_ding = _hacer_player("res://audio/ding.wav", -8.0, false)
	_son_cobro = _hacer_player("res://audio/cobro.wav", -8.0, false)
	if _son_amb != null:
		_son_amb.play()
	# Fase 8: banco de efectos, un reproductor por efecto
	var efectos := ["arranque", "puerta_abrir", "puerta_cerrar", "bocina", "bocina_lejana", "frenada", "paso_asfalto", "paso_acera", "paso_hierba", "radar", "timbre", "aviso", "monedas", "papel"]
	for e in efectos:
		var pl := _hacer_player("res://audio/" + e + ".wav", -11.0, false)
		if pl != null:
			_banco[e] = pl
	# Ambientes por zonas en bucle; el volumen depende de dónde estés
	_son_rio = _hacer_player("res://audio/rio.wav", -34.0, true)
	_son_centro = _hacer_player("res://audio/centro.wav", -36.0, true)
	_son_viento = _hacer_player("res://audio/viento.wav", -32.0, true)
	_son_parque = _hacer_player("res://audio/parque.wav", -36.0, true)
	for pz in [_son_rio, _son_centro, _son_viento, _son_parque]:
		if pz != null:
			pz.play()
	# Música propia en bucle: tema de menú a pie y tema de conducción
	_mus_menu = load("res://audio/musica_menu.wav") as AudioStream
	_mus_coche = load("res://audio/musica_coche.wav") as AudioStream
	for m in [_mus_menu, _mus_coche]:
		if m is AudioStreamWAV:
			(m as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			(m as AudioStreamWAV).loop_begin = 0
			(m as AudioStreamWAV).loop_end = int((m as AudioStreamWAV).get_length() * (m as AudioStreamWAV).mix_rate)
	_son_musica = AudioStreamPlayer.new()
	_son_musica.volume_db = -17.0
	add_child(_son_musica)
	if _mus_menu != null:
		_son_musica.stream = _mus_menu
		_son_musica.play()
	var eventos := 5 + _banco.size()
	for pz2 in [_son_rio, _son_centro, _son_viento, _son_parque, _son_musica]:
		if pz2 != null:
			eventos += 1
	print("AUDIO_OK eventos=", eventos, " banco=", _banco.size())

# ================= Fase 12: trabajos especiales =================

func _aviso_set(texto: String, segundos := 5.0) -> void:
	_aviso = texto
	_aviso_hasta = _tiempo + segundos

func _cargar_linea1() -> void:
	if not _linea1.is_empty():
		return
	var datos = JSON.parse_string(FileAccess.get_file_as_string("res://datos/linea1.json"))
	if datos != null:
		_linea1 = datos

func _nombre_parada(n: String) -> String:
	var i := n.find(" (")
	return n.substr(0, i) if i > 0 else n

func _abrir_panel_esp() -> void:
	if not _carr.is_empty():
		_aviso_set("Estás en plena carrera: termina o abandona con la ×", 4.0)
		return
	_rellenar_panel_esp()
	_panel_esp.visible = true
	_panel_esp_abierto = true

func _cerrar_panel_esp() -> void:
	_panel_esp.visible = false
	_panel_esp_abierto = false

func _boton_esp(texto: String, activo: bool, accion: Callable) -> void:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", 19)
	b.disabled = not activo
	b.pressed.connect(accion)
	_panel_esp_lista.add_child(b)

func _nota_esp(texto: String) -> void:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.70, 0.74, 0.82))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_esp_lista.add_child(l)

func _rellenar_panel_esp() -> void:
	for h in _panel_esp_lista.get_children():
		h.queue_free()
	if not _empleo_desbloqueado:
		_nota_esp("Estos trabajos los asigna el Ayuntamiento. Pásate por allí (plaza del Ayuntamiento) y entra: al salir ya podrás aceptarlos aquí.")
		return
	if not _esp.is_empty():
		_nota_esp("Ya tienes un trabajo especial en curso. Puedes cancelarlo con la X de la píldora de distancia.")
		return
	if not _trabajo.is_empty():
		_nota_esp("Termina o cancela primero el encargo normal que llevas.")
		return
	_boton_esp("Autobús · Línea 1: Hospital → Lardero (15 paradas)", true, func() -> void: _cerrar_panel_esp(); _iniciar_bus(0))
	_boton_esp("Autobús · Línea 1: Lardero → Hospital (14 paradas)", true, func() -> void: _cerrar_panel_esp(); _iniciar_bus(1))
	_boton_esp("Reparto con furgoneta · 5 paquetes", true, func() -> void: _cerrar_panel_esp(); _iniciar_furgo())
	_boton_esp("Camalote en el Ebro · retira 8 masas", true, func() -> void: _cerrar_panel_esp(); _iniciar_camalote())
	_boton_esp("Gimnasio · sesión con 4 clientes", true, func() -> void: _cerrar_panel_esp(); _iniciar_gimnasio())
	_nota_esp("El autobús paga por línea completa; la furgoneta exige llevar una furgoneta activa.")

# ---------- Autobús: ruta y paradas ----------

func _preparar_ruta_bus(puntos: Array) -> void:
	_bus_ruta.clear()
	_bus_ruta_s.clear()
	var s := 0.0
	var prev := Vector2.ZERO
	for i in range(puntos.size()):
		var p := Vector2(float(puntos[i][0]), float(puntos[i][1]))
		if i > 0:
			s += p.distance_to(prev)
		_bus_ruta.append(p)
		_bus_ruta_s.append(s)
		prev = p
	_bus_ruta_total = s

func _s_cercana_bus(p: Vector2, hint: int) -> Array:
	var n := _bus_ruta.size()
	if n < 2:
		return [0.0, 0]
	var i0 := 0
	var i1 := n - 2
	if hint >= 0:
		i0 = maxi(0, hint - 3)
		i1 = mini(n - 2, hint + 40)
	var mejor_s := 0.0
	var mejor_d := 1.0e18
	var mejor_i := 0
	for i in range(i0, i1 + 1):
		var a: Vector2 = _bus_ruta[i]
		var b: Vector2 = _bus_ruta[i + 1]
		var c := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := p.distance_squared_to(c)
		if d < mejor_d:
			mejor_d = d
			mejor_i = i
			mejor_s = float(_bus_ruta_s[i]) + a.distance_to(c)
	return [mejor_s, mejor_i]

func _punto_en_ruta_bus(s: float) -> Vector2:
	if _bus_ruta.is_empty():
		return Vector2.ZERO
	s = clampf(s, 0.0, _bus_ruta_total)
	for i in range(_bus_ruta.size() - 1):
		if float(_bus_ruta_s[i + 1]) >= s:
			var a: Vector2 = _bus_ruta[i]
			var b: Vector2 = _bus_ruta[i + 1]
			var seg := float(_bus_ruta_s[i + 1]) - float(_bus_ruta_s[i])
			var t := 0.0 if seg <= 0.0 else (s - float(_bus_ruta_s[i])) / seg
			return a.lerp(b, t)
	return _bus_ruta[_bus_ruta.size() - 1]

func _modelo_bus() -> Node3D:
	# El autobús que conduce Jon (el del trabajo de línea):
	# el mismo modelo trabajado de la flota, con su color
	# naranja en la banda y sin conductor (el conductor es él).
	var raiz := Node3D.new()
	raiz.add_child(_modelo_bus_fundido(Color(0.92, 0.55, 0.12), false))
	return raiz

func _iniciar_bus(sentido: int) -> void:
	if not _empleo_desbloqueado or not _esp.is_empty() or not _trabajo.is_empty():
		return
	_cargar_linea1()
	if _linea1.is_empty():
		return
	var sentidos: Array = _linea1["sentidos"]
	if sentido < 0 or sentido >= sentidos.size():
		return
	var sen: Dictionary = sentidos[sentido]
	_preparar_ruta_bus(sen["ruta"])
	var paradas: Array = []
	for p in sen["paradas"]:
		if bool(p["dentro"]):
			var pv := Vector2(float(p["x"]), float(p["z"]))
			var sc := _s_cercana_bus(pv, -1)
			paradas.append({"n": _nombre_parada(String(p["n"])), "p": pv, "s": float(sc[0])})
	paradas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["s"]) < float(b["s"]))
	_esp = {"tipo": "bus", "sentido": sentido, "paradas": paradas, "idx": 0,
		"servidas": 0, "saltadas": 0, "a_bordo": 0, "transportados": 0,
		"parado_t": 0.0, "entro": false}
	var s0 := float(paradas[0]["s"])
	var p_ini := _punto_en_ruta_bus(s0)
	var p_dir := _punto_en_ruta_bus(s0 + 20.0)
	_dir_bus = atan2(p_dir.x - p_ini.x, p_dir.y - p_ini.y)
	if _bus == null:
		_bus = _modelo_bus()
		add_child(_bus)
	_bus.visible = true
	_bus.position = Vector3(p_ini.x, _altura(p_ini.x, p_ini.y), p_ini.y)
	_bus.rotation.y = _dir_bus
	_vel_bus = 0.0
	_bus_hint = 0
	_bus_s_prog = 0.0
	_fijar_objetivo_bus()
	_aviso_set("Línea 1: el autobús te espera en " + String(paradas[0]["n"]))
	print("BUS_INICIO sentido=", sentido, " paradas=", paradas.size())

func _fijar_objetivo_bus() -> void:
	var idx := int(_esp["idx"])
	var paradas: Array = _esp["paradas"]
	if idx >= paradas.size():
		return
	var pv: Vector2 = paradas[idx]["p"]
	_fijar_objetivo(Vector3(pv.x, 0, pv.y))
	_objetivo_texto = "Línea 1 · Parada %d/%d: %s" % [idx + 1, paradas.size(), String(paradas[idx]["n"])]
	_banner_hasta = _tiempo + 6.0
	_actualizar_hud()

func _alternar_bus() -> void:
	if _bus == null:
		return
	if _en_bus:
		_en_bus = false
		_jugador.visible = true
		_jugador.position = _punto_libre(_bus.position + Vector3(2.8, 0, 0), 0.45)
		_jugador.position.y = _altura(_jugador.position.x, _jugador.position.z) + 0.95
		_vel_bus = 0.0
		if _son_motor != null:
			_son_motor.stop()
		_sonar("puerta_abrir")
		_musica_para(false)
	elif _jugador.position.distance_to(_bus.position) < 4.5:
		_en_bus = true
		_jugador.visible = false
		if _son_motor != null:
			_son_motor.play()
		_sonar("puerta_cerrar")
		_sonar("arranque")
		_musica_para(true)
		if not _esp.is_empty() and String(_esp.get("tipo", "")) == "bus" and not bool(_esp["entro"]):
			_esp["entro"] = true
			_servir_parada()
	_refrescar_pan()
	_refrescar_tactil()
	_actualizar_hud()

func _conducir_bus(delta: float) -> void:
	if not _esp.is_empty() and float(_esp.get("parado_t", 0.0)) > 0.0:
		_esp["parado_t"] = float(_esp["parado_t"]) - delta
		_vel_bus = move_toward(_vel_bus, 0.0, 18.0 * delta)
		_aplicar_mov_bus(delta)
		if float(_esp["parado_t"]) <= 0.0:
			_sonar("puerta_cerrar")
			_avanzar_parada(false)
		return
	var acel := 0.0
	var giro := 0.0
	if _bus_auto:
		var res := _auto_bus()
		acel = float(res[0])
		giro = float(res[1])
	else:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			acel = 1.0
		if Input.is_key_pressed(KEY_SPACE):
			acel = 1.0
		if _gas_espacio:
			acel = 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			acel = -0.7
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			giro = -1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			giro = 1.0
		if absf(_joy_valor.y) > 0.15:
			acel = clampf(-_joy_valor.y, -0.7, 1.0)
		if absf(_joy_valor.x) > 0.15:
			giro = _joy_valor.x
		if _toque_gas:
			acel = 1.0
		if _toque_freno:
			acel = -0.7
		if _toque_giro != 0.0:
			giro = _toque_giro
		var pad_giro := _pad_eje(JOY_AXIS_LEFT_X)
		if absf(pad_giro) > 0.15:
			giro = pad_giro
		var gat_d := _pad_gatillo(JOY_AXIS_TRIGGER_RIGHT)
		var gat_i := _pad_gatillo(JOY_AXIS_TRIGGER_LEFT)
		if gat_d > 0.05:
			acel = gat_d
		elif gat_i > 0.05:
			acel = -0.7 * gat_i
		# Igual que en el coche: el giro de las manos va al
		# revés que el del piloto automático.
		giro = -giro
	if acel > 0.0:
		_vel_bus += acel * 4.5 * delta
	elif acel < 0.0:
		if _vel_bus > 0.5:
			_vel_bus += acel * 9.0 * delta
		else:
			_vel_bus += acel * 2.7 * delta
	else:
		_vel_bus = move_toward(_vel_bus, 0.0, 3.0 * delta)
	_vel_bus = clampf(_vel_bus, -4.0, 11.5)
	if absf(_vel_bus) > 0.05:
		var factor := clampf(absf(_vel_bus) / 6.0, 0.35, 1.0)
		_dir_bus += giro * 0.85 * delta * signf(_vel_bus) * factor
	_aplicar_mov_bus(delta)
	if _son_motor != null:
		_son_motor.pitch_scale = 0.65 + absf(_vel_bus) / 11.5 * 0.5
	if not _esp.is_empty() and String(_esp.get("tipo", "")) == "bus":
		_control_paradas_bus()

func _auto_bus() -> Array:
	# Piloto automático del banco de pruebas: sigue la polilínea real
	# y se detiene en la parada actual.
	var paradas: Array = _esp["paradas"]
	var idx := int(_esp["idx"])
	if idx >= paradas.size():
		return [0.0, 0.0]
	var pv: Vector2 = paradas[idx]["p"]
	var pos2 := Vector2(_bus.position.x, _bus.position.z)
	var sc := _s_cercana_bus(pos2, _bus_hint)
	_bus_hint = int(sc[1])
	var s_bus := maxf(float(sc[0]), _bus_s_prog)
	_bus_s_prog = s_bus
	var s_obj := float(paradas[idx]["s"])
	var s_mira := minf(s_bus + 18.0, s_obj)
	var mira := _punto_en_ruta_bus(s_mira)
	var dist_p := pos2.distance_to(pv)
	if dist_p < 25.0:
		mira = pv
	elif mira.distance_to(pos2) < 9.0 and s_mira < s_obj:
		# En curvas cerradas el punto a 18 m de arco puede quedar dentro del
		# radio de giro del autobús y el piloto orbita sin alcanzarlo jamás:
		# se alarga la mirada hasta que el objetivo quede a 9 m en el espacio.
		var s_ext := s_mira
		while s_ext < s_obj and _punto_en_ruta_bus(s_ext).distance_to(pos2) < 9.0:
			s_ext = minf(s_ext + 4.0, s_obj)
		mira = _punto_en_ruta_bus(s_ext)
	var hacia := mira - pos2
	var ang_obj := atan2(hacia.x, hacia.y)
	var dif := wrapf(ang_obj - _dir_bus, -PI, PI)
	var giro := clampf(dif * 1.8, -1.0, 1.0)
	var dist := pos2.distance_to(pv)
	var vel_obj := 9.0
	if dist < 30.0:
		vel_obj = clampf((dist - 6.0) * 0.30, 0.0, 9.0)
	if absf(dif) > 0.6:
		vel_obj = minf(vel_obj, 4.0)
	var acel := 0.0
	if _vel_bus < vel_obj:
		acel = 1.0
	elif _vel_bus > vel_obj + 0.5:
		acel = -0.7
	return [acel, giro]

func _aplicar_mov_bus(delta: float) -> void:
	var avance := Vector3(sin(_dir_bus), 0, cos(_dir_bus)) * _vel_bus * delta
	if _bus_auto:
		_bus.position += avance
		_bus.position.y = _altura(_bus.position.x, _bus.position.z)
	else:
		var antes := _bus.position
		_mover(_bus, avance, 1.6)
		var movido := _bus.position.distance_to(antes)
		if movido < avance.length() * 0.3 and absf(_vel_bus) > 2.0:
			_vel_bus = 0.0
	_bus.rotation.y = _dir_bus

func _control_paradas_bus() -> void:
	var paradas: Array = _esp["paradas"]
	var idx := int(_esp["idx"])
	if idx >= paradas.size():
		return
	var pos2 := Vector2(_bus.position.x, _bus.position.z)
	var sc := _s_cercana_bus(pos2, _bus_hint)
	_bus_hint = int(sc[1])
	var s_bus := maxf(float(sc[0]), _bus_s_prog)
	_bus_s_prog = s_bus
	var pv: Vector2 = paradas[idx]["p"]
	var dist := pos2.distance_to(pv)
	if dist < 14.0 and absf(_vel_bus) < 0.9:
		_servir_parada()
	elif s_bus > float(paradas[idx]["s"]) + 30.0:
		_avanzar_parada(true)

func _servir_parada() -> void:
	_sonar("timbre")
	_esp["parado_t"] = 2.5
	var idx := int(_esp["idx"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + idx * 77 + int(_esp["sentido"]) * 1000
	var bajan := mini(int(_esp["a_bordo"]), rng.randi_range(0, 3))
	var suben := rng.randi_range(0, 4)
	_esp["a_bordo"] = int(_esp["a_bordo"]) - bajan + suben
	_esp["transportados"] = int(_esp["transportados"]) + suben
	print("BUS_PARADA ", idx + 1, " ", String(_esp["paradas"][idx]["n"]), " suben=", suben, " bajan=", bajan, " a_bordo=", _esp["a_bordo"])

func _avanzar_parada(saltada: bool) -> void:
	if saltada:
		_esp["saltadas"] = int(_esp["saltadas"]) + 1
		print("BUS_SALTADA ", int(_esp["idx"]) + 1, " ", String(_esp["paradas"][int(_esp["idx"])]["n"]))
		_aviso_set("Parada saltada: " + String(_esp["paradas"][int(_esp["idx"])]["n"]))
	else:
		_esp["servidas"] = int(_esp["servidas"]) + 1
	_esp["idx"] = int(_esp["idx"]) + 1
	if int(_esp["idx"]) >= (_esp["paradas"] as Array).size():
		_fin_bus()
	else:
		_fijar_objetivo_bus()

func _fin_bus() -> void:
	var cobro := 25 + 2 * int(_esp["servidas"]) + int(0.5 * float(int(_esp["transportados"])))
	_dinero += cobro
	_sonar("cobro")
	_pilar_destino.visible = false
	_objetivo_texto = "Línea 1 completada: +%d €" % cobro
	_banner_hasta = _tiempo + 6.0
	print("BUS_OK servidas=", _esp["servidas"], " saltadas=", _esp["saltadas"], " transportados=", _esp["transportados"], " cobro=", cobro)
	_esp = {}
	_guardar()
	_actualizar_hud()
	if _bus_auto:
		get_tree().quit()

func _cancelar_especial() -> void:
	if _esp.is_empty():
		return
	var tipo := String(_esp.get("tipo", ""))
	if tipo == "bus":
		if _en_bus:
			_alternar_bus()
		if _bus != null:
			_bus.visible = false
	elif tipo == "camalote":
		for m in _masas:
			(m["nodo"] as Node3D).queue_free()
		_masas.clear()
	elif tipo == "gimnasio":
		_liberar_clientes_gim()
	_esp = {}
	_pilar_destino.visible = false
	_objetivo_texto = "Trabajo especial cancelado"
	_banner_hasta = _tiempo + 4.0
	print("ESP_CANCELADO tipo=", tipo)
	_actualizar_hud()

func _iniciar_furgo() -> void:
	if not _empleo_desbloqueado or not _esp.is_empty() or not _trabajo.is_empty():
		return
	if _mis_coches.is_empty():
		return
	var id_act := int(_mis_coches[_coche_activo]["id"])
	if String(COCHES[id_act]["clase"]) != "Furgoneta":
		_aviso_set("Necesitas una furgoneta activa: cómprala en AutoRioja o cámbiala en tu garaje")
		return
	_esp = {"tipo": "furgo", "fase": "cargar", "entregas": [], "quedan": 0, "ruta_m": 0.0}
	var g: Vector3 = _lugares_coches["garaje"]
	_fijar_objetivo(g)
	_objetivo_texto = "Furgoneta · ve a cargar 5 paquetes a tu garaje"
	_banner_hasta = _tiempo + 6.0
	_actualizar_hud()
	print("FURGO_INICIO")

func _objetivo_furgo() -> void:
	# Objetivo = la entrega pendiente más cercana a la furgoneta
	var mejor: Dictionary = {}
	var mejor_d := 1.0e18
	for e in _esp["entregas"]:
		if bool(e["hecha"]):
			continue
		var p: Vector3 = e["p"]
		var d := Vector2(_coche.position.x - p.x, _coche.position.z - p.z).length()
		if d < mejor_d:
			mejor_d = d
			mejor = e
	if mejor.is_empty():
		return
	var p2: Vector3 = mejor["p"]
	_fijar_objetivo(p2)
	_objetivo_texto = "Furgoneta · quedan %d paquetes · entrega en %s" % [int(_esp["quedan"]), String(mejor["n"])]
	_banner_hasta = _tiempo + 6.0
	_actualizar_hud()

func _fin_furgo() -> void:
	var cobro := 30 + int(float(_esp["ruta_m"]) / 100.0)
	_dinero += cobro
	_sonar("cobro")
	_pilar_destino.visible = false
	_objetivo_texto = "Reparto completado: +%d €" % cobro
	_banner_hasta = _tiempo + 6.0
	print("FURGO_OK cobro=", cobro, " ruta_m=", int(float(_esp["ruta_m"])))
	_esp = {}
	_guardar()
	_actualizar_hud()
	if _bus_auto:
		get_tree().quit()

func _actualizar_especiales(delta: float) -> void:
	if _esp.is_empty():
		return
	var tipo := String(_esp.get("tipo", ""))
	if tipo == "camalote":
		# Deriva río abajo, balanceo y objetivo = la masa más cercana
		var mejor_m: Dictionary = {}
		var mejor_d := 1.0e18
		for m in _masas:
			m["s"] = float(m["s"]) + 0.4 * delta
			if float(m["s"]) > _rio_total - 60.0:
				m["s"] = 60.0
			var nodo_m: Node3D = m["nodo"]
			var pm := _punto_en_rio(float(m["s"]), float(m["lat"]))
			nodo_m.position = Vector3(pm.x, _altura_terreno(pm.x, pm.y) + 0.45 + sin(_tiempo * 1.3 + float(m["fase"])) * 0.08, pm.y)
			nodo_m.rotation.y += delta * 0.05
			var d := Vector2(_jugador.position.x - pm.x, _jugador.position.z - pm.y).length()
			if d < mejor_d:
				mejor_d = d
				mejor_m = m
		if not mejor_m.is_empty():
			var nm: Node3D = mejor_m["nodo"]
			_destino_libre = nm.position
			_pilar_destino.position = Vector3(nm.position.x, _altura(nm.position.x, nm.position.z) + 13.0, nm.position.z)
			_pilar_destino.visible = true
	elif tipo == "gimnasio":
		_actualizar_gimnasio(delta)
	if tipo == "furgo":
		if String(_esp["fase"]) == "cargar":
			var g: Vector3 = _lugares_coches["garaje"]
			if Vector2(_coche.position.x - g.x, _coche.position.z - g.z).length() < 7.0:
				# Cargar: 5 destinos desde los portales reales
				var entregas: Array = []
				var intentos := 0
				while entregas.size() < 5 and intentos < 300:
					intentos += 1
					var por: Dictionary = _portales[_rng.randi_range(0, _portales.size() - 1)]
					var pp := Vector3(float(por["x"]), 0, float(por["z"]))
					var dg := Vector2(pp.x - g.x, pp.z - g.z).length()
					if dg < 250.0 or dg > 1400.0:
						continue
					var lejos := true
					for e in entregas:
						var pe: Vector3 = e["p"]
						if Vector2(pp.x - pe.x, pp.z - pe.z).length() < 200.0:
							lejos = false
					if not lejos:
						continue
					var libre := _punto_libre(pp, 1.0)
					libre.y = _altura(libre.x, libre.z)
					entregas.append({"n": String(por["calle"]) + " " + String(por["numero"]), "p": libre, "hecha": false})
				_esp["entregas"] = entregas
				_esp["quedan"] = entregas.size()
				_esp["fase"] = "repartir"
				_sonar("papel")
				_aviso_set("Furgoneta cargada: %d paquetes" % entregas.size())
				print("FURGO_CARGADA destinos=", entregas.size())
				_objetivo_furgo()
		else:
			# Reparto: acumular ruta y entregar al acercar la furgoneta
			var pos_c := Vector2(_coche.position.x, _coche.position.z)
			if _esp.has("ult"):
				var ult: Vector2 = _esp["ult"]
				_esp["ruta_m"] = float(_esp["ruta_m"]) + pos_c.distance_to(ult)
			_esp["ult"] = pos_c
			for e in _esp["entregas"]:
				if bool(e["hecha"]):
					continue
				var p: Vector3 = e["p"]
				if Vector2(_coche.position.x - p.x, _coche.position.z - p.z).length() < 6.5:
					e["hecha"] = true
					_esp["quedan"] = int(_esp["quedan"]) - 1
					_sonar("papel")
					print("FURGO_ENTREGA ", String(e["n"]), " quedan=", int(_esp["quedan"]))
					if int(_esp["quedan"]) <= 0:
						_fin_furgo()
					else:
						_objetivo_furgo()
					break

func _probar_furgo() -> void:
	_empleo_desbloqueado = true
	_dinero = 20000
	_comprar_coche(10)
	_usar_coche(_mis_coches.size() - 1)
	_iniciar_furgo()
	if _esp.is_empty():
		print("FURGO_PRUEBA_OK pasa=false (no arranco)")
		get_tree().quit()
		return
	_bus_auto = true
	var t0 := _tiempo
	var ruta: Array = []
	var idx := 0
	var ult_obj := Vector3.INF
	while not _esp.is_empty():
		await get_tree().physics_frame
		if _tiempo - t0 > 1200.0:
			print("FURGO_PRUEBA_OK pasa=false (timeout)")
			get_tree().quit()
			return
		if _destino_libre != ult_obj:
			ult_obj = _destino_libre
			ruta = _calcular_ruta(_coche.position, _destino_libre)
			idx = 0
		if ruta.is_empty():
			continue
		var obj: Vector3 = ruta[mini(idx, ruta.size() - 1)]
		var hacia := obj - _coche.position
		hacia.y = 0
		if hacia.length() < 6.0:
			idx += 1
			continue
		_coche_dir = atan2(hacia.x, hacia.z)
		_coche.position += Vector3(sin(_coche_dir), 0, cos(_coche_dir)) * 11.0 / 60.0
		_coche.position.y = _altura(_coche.position.x, _coche.position.z)
		_coche.rotation.y = _coche_dir
	print("FURGO_PRUEBA_OK pasa=true")
	get_tree().quit()

var _rio_pts: Array = []
var _rio_s: Array = []
var _rio_total := 0.0

func _banco_paseo(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, bp: Vector2, rot: float) -> void:
	# Un banco como los del mobiliario urbano, registrado para
	# poder sentarse con F y como sólido.
	var col_madera := Color(0.45, 0.31, 0.17)
	var col_hierro := Color(0.13, 0.13, 0.14)
	var yb := _altura(bp.x, bp.y)
	var lat := Vector3(cos(rot), 0, -sin(rot))
	var detras := Vector3(-sin(rot), 0, -cos(rot))
	var cen := Vector3(bp.x, yb, bp.y)
	_caja_en(verts, normals, cols, cen + Vector3(0, 0.46, 0), Vector3(1.8, 0.10, 0.5), col_madera, rot)
	_caja_en(verts, normals, cols, cen + detras * 0.22 + Vector3(0, 0.78, 0), Vector3(1.8, 0.5, 0.09), col_madera, rot)
	_caja_en(verts, normals, cols, cen + lat * 0.7 + Vector3(0, 0.22, 0), Vector3(0.08, 0.44, 0.42), col_hierro, rot)
	_caja_en(verts, normals, cols, cen - lat * 0.7 + Vector3(0, 0.22, 0), Vector3(0.08, 0.44, 0.42), col_hierro, rot)
	_asientos.append({"pos": cen, "rot": rot})
	_registrar_solido(cen.x, cen.z, rot, 0.32, 0.95)

func _camino(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, pts: Array, ancho: float, col: Color) -> void:
	# Cinta de camino sobre el terreno: subdividida cada ~6 m y con
	# la altura muestreada en cada vértice, para que no vuele en
	# las vaguadas como les pasaba a las calles largas.
	var ant: Array = []
	for i in pts.size():
		var p: Vector2 = pts[i]
		var subs: Array = []
		if i > 0:
			var prev: Vector2 = pts[i - 1]
			var n := int(ceil(prev.distance_to(p) / 6.0))
			for k in range(1, n + 1):
				subs.append(prev.lerp(p, float(k) / float(n)))
		else:
			subs.append(p)
		for q in subs:
			var dir := Vector2.ZERO
			if i > 0:
				dir = q - Vector2(pts[i - 1])
			if i < pts.size() - 1:
				dir += Vector2(pts[i + 1]) - q
			if dir.length() < 0.001:
				dir = Vector2(0, 1)
			dir = dir.normalized()
			var perp := Vector2(-dir.y, dir.x) * (ancho * 0.5)
			var a: Vector2 = q - perp
			var b: Vector2 = q + perp
			var fila := [Vector3(a.x, _altura_terreno(a.x, a.y) + 0.16, a.y), Vector3(b.x, _altura_terreno(b.x, b.y) + 0.16, b.y)]
			if ant.size() == 2:
				_tri(verts, normals, cols, ant[0], ant[1], fila[1], true, col)
				_tri(verts, normals, cols, ant[0], fila[1], fila[0], true, col)
			ant = fila

func _crear_paseo() -> void:
	# Tanda 4.2 (la Ribera): el paseo fluvial continuo por la
	# orilla sur del Ebro y los caminos de sus tres parques
	# (del Ebro, de La Ribera y de la Florida). Todo fundido en
	# una sola malla; los bancos se registran como asientos.
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var base_rio: Array[Vector2] = []
	for q in _rio:
		base_rio.append(Vector2(float(q[0]), float(q[1])))
	var rio_d: Array = []
	for i in base_rio.size():
		if i > 0:
			var desde_r: Vector2 = base_rio[i - 1]
			var hasta_r: Vector2 = base_rio[i]
			var tramos_r := int(ceil(desde_r.distance_to(hasta_r) / 8.0))
			for k in range(1, tramos_r):
				rio_d.append(desde_r.lerp(hasta_r, float(k) / float(tramos_r)))
		rio_d.append(base_rio[i])
	var ant_fila: Array = []
	var largo := 0.0
	var ant_p := Vector2.ZERO
	var hay_ant := false
	var dist_f := 0.0
	var dist_b := 20.0
	var n_farolas := 0
	var n_bancos := 0
	for i in rio_d.size():
		var p: Vector2 = rio_d[i]
		if p.x < -1500.0 or p.x > 1600.0:
			ant_fila = []
			hay_ant = false
			continue
		var dir := Vector2.ZERO
		if i > 0:
			dir += p - Vector2(rio_d[i - 1])
		if i < rio_d.size() - 1:
			dir += Vector2(rio_d[i + 1]) - p
		if dir.length() < 0.001:
			continue
		dir = dir.normalized()
		var perp := Vector2(-dir.y, dir.x)
		var signo := 1.0 if (p + perp).y > (p - perp).y else -1.0
		var sur := perp * signo
		var fila: Array = []
		for lat in [36.0, 40.0, 44.0]:
			var pp: Vector2 = p + sur * lat
			fila.append(Vector3(pp.x, _altura_terreno(pp.x, pp.y) + 0.22, pp.y))
		if ant_fila.size() == 3:
			_tri(verts, normals, cols, ant_fila[0], ant_fila[1], fila[1], true, Color(0.74, 0.68, 0.56))
			_tri(verts, normals, cols, ant_fila[0], fila[1], fila[0], true, Color(0.74, 0.68, 0.56))
			_tri(verts, normals, cols, ant_fila[1], ant_fila[2], fila[2], true, Color(0.67, 0.61, 0.50))
			_tri(verts, normals, cols, ant_fila[1], fila[2], fila[1], true, Color(0.67, 0.61, 0.50))
			var d := p.distance_to(ant_p)
			largo += d
			dist_f += d
			dist_b += d
			if dist_f >= 28.0:
				dist_f = 0.0
				var pf: Vector2 = p + sur * 42.8
				_farola_h(verts, normals, cols, pf.x, _altura_terreno(pf.x, pf.y) + 0.1, pf.y)
				n_farolas += 1
			if dist_b >= 56.0:
				dist_b = 0.0
				var pb: Vector2 = p + sur * 37.6
				if not _choca(pb, 0.9):
					_banco_paseo(verts, normals, cols, pb, atan2(-sur.x, -sur.y))
					n_bancos += 1
		ant_fila = fila
		ant_p = p
		hay_ant = true
	# Los caminos de los parques, de gravilla clara
	var grav := Color(0.78, 0.71, 0.58)
	_camino(verts, normals, cols, [Vector2(950, -612), Vector2(948, -690), Vector2(945, -766)], 3.6, grav)
	_camino(verts, normals, cols, [Vector2(458, -548), Vector2(455, -650), Vector2(452, -766)], 3.6, grav)
	_camino(verts, normals, cols, [Vector2(516, -566), Vector2(700, -592), Vector2(876, -606)], 3.6, grav)
	_camino(verts, normals, cols, [Vector2(-560, -352), Vector2(-300, -328), Vector2(-120, -290)], 3.6, grav)
	_camino(verts, normals, cols, [Vector2(-300, -328), Vector2(-303, -398)], 3.6, grav)
	_camino(verts, normals, cols, [Vector2(268, -404), Vector2(268, -474)], 3.2, grav)
	_camino(verts, normals, cols, [Vector2(272, -384), Vector2(298, -290)], 3.2, grav)
	# La glorieta de la Florida: disco de gravilla sobre el terreno
	var cf := Vector2(268, -393)
	var nseg := 18
	for i in nseg:
		var a1 := cf + Vector2(cos(TAU * float(i) / nseg), sin(TAU * float(i) / nseg)) * 12.0
		var a2 := cf + Vector2(cos(TAU * float(i + 1) / nseg), sin(TAU * float(i + 1) / nseg)) * 12.0
		_tri(verts, normals, cols, Vector3(cf.x, _altura_terreno(cf.x, cf.y) + 0.17, cf.y), Vector3(a1.x, _altura_terreno(a1.x, a1.y) + 0.17, a1.y), Vector3(a2.x, _altura_terreno(a2.x, a2.y) + 0.17, a2.y), true, grav)
	# Bancos y farolas de los parques
	_banco_paseo(verts, normals, cols, Vector2(943, -690), PI)
	_banco_paseo(verts, normals, cols, Vector2(450, -650), PI)
	_banco_paseo(verts, normals, cols, Vector2(-300, -320), PI)
	_banco_paseo(verts, normals, cols, Vector2(256, -388), PI * 0.5)
	_banco_paseo(verts, normals, cols, Vector2(280, -398), -PI * 0.5)
	n_bancos += 5
	for fp in [Vector2(949, -690), Vector2(453, -650), Vector2(-300, -335), Vector2(268, -420)]:
		_farola_h(verts, normals, cols, fp.x, _altura_terreno(fp.x, fp.y) + 0.1, fp.y)
		n_farolas += 1
	add_child(_malla_de(verts, normals, cols, Color.WHITE))
	print("PASEO_OK m=", int(largo), " bancos=", n_bancos, " farolas=", n_farolas)

var _piscinas: Array = []
var _piscinas_listas := false

func _preparar_piscinas() -> void:
	if _piscinas_listas:
		return
	_piscinas_listas = true
	# Las dos piscinas grandes de Las Norias: la de largos
	# (25x50, con sus calles dibujadas) y la de recreo de los
	# toboganes. Su lamina es un suelo plano a terreno + 0,15;
	# para nadar cuentan con profundidad de sobra.
	var yp := _altura_terreno(-1155.0, -870.0)
	_piscinas.append({"r": Rect2(-1179.5, -887.0, 25.0, 50.0), "n": yp + 0.15})
	_piscinas.append({"r": Rect2(-1179.5, -916.0, 55.0, 28.0), "n": yp + 0.15})

func _piscina_en(p: Vector2) -> float:
	# El nivel de la lamina si el punto cae en una piscina;
	# -1000 si no cae en ninguna.
	_preparar_piscinas()
	for pi in _piscinas:
		if (pi["r"] as Rect2).has_point(p):
			return float(pi["n"])
	return -1000.0

func _nivel_agua(p: Vector2) -> float:
	# La superficie del agua sobre p: la lamina de una
	# piscina de Las Norias si cae dentro, o la del Ebro
	# (el nivel del eje del rio mas cercano + 0,35, como se
	# dibuja la cinta). Devuelve -1000 si no hay agua.
	var np := _piscina_en(p)
	if np > -500.0:
		return np
	_preparar_rio()
	var mejor := 1.0e9
	var centro := Vector2.ZERO
	for i in range(_rio_pts.size() - 1):
		var a: Vector2 = _rio_pts[i]
		var b: Vector2 = _rio_pts[i + 1]
		var ab := b - a
		var t := 0.0
		if ab.length_squared() > 0.001:
			t = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var q := a + ab * t
		var d := p.distance_to(q)
		if d < mejor:
			mejor = d
			centro = q
	if mejor > 33.0:
		return -1000.0
	return _altura_terreno(centro.x, centro.y) + 0.35

func _profundidad(p: Vector2) -> float:
	# Cuanto cubre el agua en un punto: el nivel del rio
	# (terreno del eje + 0,35) menos el fondo en ese punto.
	# En las orillas y las barras de grava que quedan por
	# encima del nivel, sale cero o negativo: ahi se hace pie.
	# En una piscina siempre cubre (1,4 m de sobra).
	if _piscina_en(p) > -500.0:
		return 1.4
	if _nivel_agua(p) < -100.0:
		return -1.0
	return _nivel_agua(p) - _altura_terreno(p.x, p.y)

func _agua_profunda(p: Vector2) -> bool:
	# Agua que cubre de verdad: mas de 0,24 m sobre el fondo,
	# lo bastante para nadar y para que un coche se cale.
	# Sobre un puente la altura solida supera al terreno y
	# nunca cuenta como agua.
	if _nivel_agua(p) < -100.0:
		return false
	if _altura(p.x, p.y) > _altura_terreno(p.x, p.y) + 0.05:
		return false
	return _profundidad(p) > 0.24

var _piraguas: Array = []
var _enamorados_datos: Dictionary = {}
var _enamorados_hecho := false
var _pareja_enamorados: Dictionary = {}
var _piragua_ruta: Array = []
var _piragua_lens: Array = []
var _piragua_total := 0.0

func _preparar_piraguas() -> void:
	# Dos piraguistas en el Ebro (Jon, 2026-11-24): su
	# circuito va del Puente de Piedra al de Hierro, bajando
	# por la orilla sur y subiendo por la norte, remando con
	# el remo de doble pala. La animacion vive en
	# _mover_peatones.
	if not _piraguas.is_empty():
		return
	_preparar_rio()
	# El circuito se traza por distancia sobre el eje del
	# rio, parando 35 m antes de cada puente: remar entre
	# los puentes, no bajo sus tableros (el tablero queda a
	# ras del agua y la piragua se veria encima de la calzada).
	var d_piedra := 0.0
	var d_hierro := 0.0
	var s_ac := 0.0
	var bd_p := 1.0e9
	var bd_h := 1.0e9
	for i in _rio_pts.size():
		if i > 0:
			s_ac += (_rio_pts[i] as Vector2).distance_to(_rio_pts[i - 1])
		var p: Vector2 = _rio_pts[i]
		var dp := p.distance_to(Vector2(-89, -361))
		if dp < bd_p:
			bd_p = dp
			d_piedra = s_ac
		var dh := p.distance_to(Vector2(-352, -427))
		if dh < bd_h:
			bd_h = dh
			d_hierro = s_ac
	var d0 := minf(d_piedra, d_hierro) + 35.0
	var d1 := maxf(d_piedra, d_hierro) - 35.0
	# Que lateral cae al sur (la orilla de la ciudad)
	var lat_sur := 7.0
	if _punto_en_rio((d0 + d1) / 2.0, -7.0).y > _punto_en_rio((d0 + d1) / 2.0, 7.0).y:
		lat_sur = -7.0
	_piragua_ruta = []
	var d := d0
	while d < d1:
		_piragua_ruta.append(_punto_en_rio(d, lat_sur))
		d += 25.0
	_piragua_ruta.append(_punto_en_rio(d1, lat_sur))
	d = d1
	while d > d0:
		_piragua_ruta.append(_punto_en_rio(d, -lat_sur))
		d -= 25.0
	_piragua_ruta.append(_punto_en_rio(d0, -lat_sur))
	_piragua_lens = [0.0]
	for i in range(1, _piragua_ruta.size()):
		_piragua_lens.append(float(_piragua_lens[i - 1]) + (_piragua_ruta[i] as Vector2).distance_to(_piragua_ruta[i - 1]))
	_piragua_total = float(_piragua_lens[_piragua_lens.size() - 1]) + (_piragua_ruta[0] as Vector2).distance_to(_piragua_ruta[_piragua_ruta.size() - 1])
	var cols_k := [[Color(0.85, 0.22, 0.16), Color(0.95, 0.55, 0.10)], [Color(0.95, 0.78, 0.15), Color(0.15, 0.35, 0.75)]]
	for k in 2:
		_piraguas.append(_hacer_piragua(cols_k[k][0], cols_k[k][1], float(k) * _piragua_total / 2.0))

func _piragua_en(s: float) -> Vector2:
	if _piragua_ruta.is_empty():
		return Vector2.ZERO
	var ss := fmod(s, _piragua_total)
	var i := 0
	while i < _piragua_lens.size() - 1 and float(_piragua_lens[i + 1]) < ss:
		i += 1
	var p0: Vector2 = _piragua_ruta[i]
	var p1: Vector2 = _piragua_ruta[(i + 1) % _piragua_ruta.size()]
	var seg := p0.distance_to(p1)
	if seg < 0.01:
		return p0
	return p0.lerp(p1, (ss - float(_piragua_lens[i])) / seg)

func _hacer_piragua(col_casco: Color, col_chaleco: Color, s0: float) -> Dictionary:
	var grupo := Node3D.new()
	add_child(grupo)
	# El casco: largo y estrecho, con la proa y la popa
	# levantadas y la bañera oscura en el centro.
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	_caja_en(v, n, c, Vector3(0, 0.10, 0), Vector3(0.55, 0.20, 3.1), col_casco, 0.0)
	_caja_en(v, n, c, Vector3(0, 0.16, 1.72), Vector3(0.40, 0.16, 0.45), col_casco, 0.0)
	_caja_en(v, n, c, Vector3(0, 0.16, -1.72), Vector3(0.40, 0.16, 0.45), col_casco, 0.0)
	_caja_en(v, n, c, Vector3(0, 0.215, -0.1), Vector3(0.46, 0.05, 0.95), col_casco.darkened(0.35), 0.0)
	grupo.add_child(_malla_de(v, n, c, Color.WHITE))
	# El palista, sentado con las piernas dentro del casco.
	var per := _persona_en(Vector3(-220, 0, -395), Vector2.ZERO, col_chaleco, Color(0.16, 0.11, 0.07))
	var raiz: Node3D = per["raiz"]
	raiz.get_parent().remove_child(raiz)
	grupo.add_child(raiz)
	raiz.position = Vector3(0, 0.26, -0.15)
	raiz.rotation = Vector3.ZERO
	(per["pi"] as Node3D).rotation.x = -1.45
	(per["pd"] as Node3D).rotation.x = -1.45
	# El remo de doble pala, en un pivote a la altura de las
	# manos para poder balancearlo a un lado y a otro.
	var piv := Node3D.new()
	piv.position = Vector3(0, 0.80, 0.28)
	grupo.add_child(piv)
	var v2 := PackedVector3Array()
	var n2 := PackedVector3Array()
	var c2 := PackedColorArray()
	_caja_en(v2, n2, c2, Vector3(0, 0, 0), Vector3(2.3, 0.045, 0.045), Color(0.75, 0.72, 0.68), 0.0)
	_caja_en(v2, n2, c2, Vector3(-1.22, 0, 0), Vector3(0.30, 0.02, 0.55), col_casco, 0.0)
	_caja_en(v2, n2, c2, Vector3(1.22, 0, 0), Vector3(0.30, 0.02, 0.55), col_casco, 0.0)
	piv.add_child(_malla_de(v2, n2, c2, Color.WHITE))
	return {"grupo": grupo, "d": per, "remo": piv, "s": s0, "vel": 2.1, "fase": _rng.randf() * 6.0}

func _preparar_rio() -> void:
	if not _rio_pts.is_empty():
		return
	var s := 0.0
	var prev := Vector2.ZERO
	for i in range(_rio.size()):
		var p := Vector2(float(_rio[i][0]), float(_rio[i][1]))
		if i > 0:
			s += p.distance_to(prev)
		_rio_pts.append(p)
		_rio_s.append(s)
		prev = p
	_rio_total = s

func _punto_en_rio(s: float, lat: float) -> Vector2:
	if _rio_pts.is_empty():
		return Vector2.ZERO
	s = clampf(s, 0.0, _rio_total)
	for i in range(_rio_pts.size() - 1):
		if float(_rio_s[i + 1]) >= s:
			var a: Vector2 = _rio_pts[i]
			var b: Vector2 = _rio_pts[i + 1]
			var seg := float(_rio_s[i + 1]) - float(_rio_s[i])
			var t := 0.0 if seg <= 0.0 else (s - float(_rio_s[i])) / seg
			var dir := (b - a).normalized()
			var perp := Vector2(-dir.y, dir.x)
			return a.lerp(b, t) + perp * lat
	return _rio_pts[_rio_pts.size() - 1]

func _masa_nodo() -> Node3D:
	var partes: Array = [
		[Vector3(0, 0.16, 0), Vector3(3.4, 0.34, 2.6), Color(0.25, 0.45, 0.20)],
		[Vector3(1.0, 0.26, 0.6), Vector3(1.9, 0.30, 1.7), Color(0.32, 0.52, 0.22)],
		[Vector3(-1.1, 0.22, -0.6), Vector3(1.7, 0.28, 1.5), Color(0.22, 0.40, 0.18)],
		[Vector3(0.2, 0.32, -1.0), Vector3(1.3, 0.24, 1.1), Color(0.38, 0.55, 0.25)]]
	return _fundida(partes)

func _iniciar_camalote() -> void:
	if not _empleo_desbloqueado or not _esp.is_empty() or not _trabajo.is_empty():
		return
	_preparar_rio()
	if _rio_total <= 0.0:
		return
	_esp = {"tipo": "camalote", "retiradas": 0}
	for i in range(12):
		var s := _rio_total * (0.12 + 0.76 * float(i) / 11.0)
		var lat := (8.0 if i % 2 == 0 else -8.0) * (0.6 + 0.4 * fposmod(sin(float(i) * 7.3) * 43758.5453, 1.0))
		var nodo := _masa_nodo()
		add_child(nodo)
		var pm := _punto_en_rio(s, lat)
		nodo.position = Vector3(pm.x, _altura_terreno(pm.x, pm.y) + 0.45, pm.y)
		_masas.append({"nodo": nodo, "s": s, "lat": lat, "fase": float(i) * 1.7})
	_objetivo_texto = "Camalote · retiradas 0/8 · acércate y pulsa E"
	_banner_hasta = _tiempo + 6.0
	_actualizar_hud()
	print("CAMALOTE_INICIO masas=", _masas.size())

func _masa_cercana() -> Variant:
	if _esp.is_empty() or String(_esp.get("tipo", "")) != "camalote":
		return null
	var mejor: Variant = null
	var mejor_d := 3.5
	for m in _masas:
		var nm: Node3D = m["nodo"]
		var d := Vector2(_jugador.position.x - nm.position.x, _jugador.position.z - nm.position.z).length()
		if d < mejor_d:
			mejor_d = d
			mejor = m
	return mejor

func _retirar_masa_cercana() -> void:
	var m: Variant = _masa_cercana()
	if m == null:
		return
	_masas.erase(m)
	(m["nodo"] as Node3D).queue_free()
	_esp["retiradas"] = int(_esp["retiradas"]) + 1
	_sonar("paso_hierba")
	print("CAMALOTE_RETIRADA ", int(_esp["retiradas"]))
	if int(_esp["retiradas"]) >= 8:
		_fin_camalote()
	else:
		_objetivo_texto = "Camalote · retiradas %d/8 · acércate y pulsa E" % int(_esp["retiradas"])
		_banner_hasta = _tiempo + 4.0
		_actualizar_hud()

func _fin_camalote() -> void:
	for m in _masas:
		(m["nodo"] as Node3D).queue_free()
	_masas.clear()
	_dinero += 30
	_sonar("cobro")
	_pilar_destino.visible = false
	_objetivo_texto = "Ebro limpio: +30 €"
	_banner_hasta = _tiempo + 6.0
	print("CAMALOTE_OK retiradas=", int(_esp["retiradas"]))
	_esp = {}
	_guardar()
	_actualizar_hud()
	if _bus_auto:
		get_tree().quit()

func _probar_camalote() -> void:
	_empleo_desbloqueado = true
	_iniciar_camalote()
	if _esp.is_empty():
		print("CAMALOTE_PRUEBA_OK pasa=false (no arranco)")
		get_tree().quit()
		return
	_bus_auto = true
	var t0 := _tiempo
	while not _esp.is_empty():
		await get_tree().physics_frame
		if _tiempo - t0 > 300.0:
			print("CAMALOTE_PRUEBA_OK pasa=false (timeout)")
			get_tree().quit()
			return
		if not _masas.is_empty():
			var nm: Node3D = _masas[0]["nodo"]
			_jugador.position = Vector3(nm.position.x, _altura(nm.position.x, nm.position.z) + 0.95, nm.position.z)
			_retirar_masa_cercana()
	print("CAMALOTE_PRUEBA_OK pasa=true")
	get_tree().quit()

func _iniciar_gimnasio() -> void:
	if not _empleo_desbloqueado or not _esp.is_empty() or not _trabajo.is_empty():
		return
	_esp = {"tipo": "gimnasio", "idx": 0, "clientes": false}
	_gim_t = 0.0
	var fuera: Vector3 = _interiores["gimnasio"]["fuera"]
	_fijar_objetivo(fuera)
	_objetivo_texto = "Gimnasio · entra y supervisa las estaciones"
	_banner_hasta = _tiempo + 6.0
	_actualizar_hud()
	print("GIMNASIO_INICIO")

func _liberar_clientes_gim() -> void:
	if _esp.has("nodos_clientes"):
		for nd in _esp["nodos_clientes"]:
			(nd as Node3D).queue_free()
		_esp["nodos_clientes"] = []

func _actualizar_gimnasio(delta: float) -> void:
	var est: Array = _interiores["gimnasio"]["estaciones"]
	var idx := int(_esp["idx"])
	if _en_interior != "gimnasio":
		var fuera: Vector3 = _interiores["gimnasio"]["fuera"]
		_destino_libre = fuera
		_pilar_destino.position = Vector3(fuera.x, _altura(fuera.x, fuera.z) + 13.0, fuera.z)
		_pilar_destino.visible = true
		return
	if not bool(_esp["clientes"]):
		_esp["clientes"] = true
		var nodos: Array = []
		var cols := [Color(0.75, 0.30, 0.25), Color(0.16, 0.38, 0.62), Color(0.20, 0.55, 0.35), Color(0.85, 0.65, 0.20)]
		for i in range(est.size()):
			var per: Dictionary = _hacer_persona(cols[i], Color(0.22, 0.23, 0.30), Color(0.10, 0.08, 0.06))
			var raiz: Node3D = per["raiz"]
			var pe: Vector3 = est[i]["p"]
			raiz.position = pe + Vector3(0.8, 0.95, 0.8)
			add_child(raiz)
			nodos.append(raiz)
		_esp["nodos_clientes"] = nodos
	if idx >= est.size():
		return
	var p: Vector3 = est[idx]["p"]
	_destino_libre = p
	_pilar_destino.position = p + Vector3(0, 13, 0)
	_pilar_destino.visible = true
	var d := Vector2(_jugador.position.x - p.x, _jugador.position.z - p.z).length()
	if d < 1.6:
		_gim_t += delta
		_objetivo_texto = "Gimnasio · supervisando %s… %d s" % [String(est[idx]["n"]), int(ceil(4.0 - _gim_t))]
		if _gim_t >= 4.0:
			_gim_t = 0.0
			_esp["idx"] = idx + 1
			_sonar("ding")
			print("GIM_ESTACION ", idx + 1, " ", String(est[idx]["n"]))
			if idx + 1 >= est.size():
				_fin_gimnasio()
				return
			_objetivo_texto = "Gimnasio · ahora %s" % String(est[idx + 1]["n"])
			_banner_hasta = _tiempo + 4.0
	else:
		_gim_t = 0.0
		_objetivo_texto = "Gimnasio · supervisa %s (%d/4)" % [String(est[idx]["n"]), idx + 1]

func _fin_gimnasio() -> void:
	_liberar_clientes_gim()
	_dinero += 20
	_sonar("cobro")
	_pilar_destino.visible = false
	_objetivo_texto = "Sesión de gimnasio completada: +20 €"
	_banner_hasta = _tiempo + 6.0
	print("GIMNASIO_OK cobro=20")
	_esp = {}
	_guardar()
	_actualizar_hud()
	if _bus_auto:
		get_tree().quit()

func _probar_gimnasio() -> void:
	_empleo_desbloqueado = true
	_iniciar_gimnasio()
	if _esp.is_empty():
		print("GIMNASIO_PRUEBA_OK pasa=false (no arranco)")
		get_tree().quit()
		return
	_bus_auto = true
	_entrar_interior("gimnasio")
	var t0 := _tiempo
	var est: Array = _interiores["gimnasio"]["estaciones"]
	while not _esp.is_empty():
		await get_tree().physics_frame
		if _tiempo - t0 > 300.0:
			print("GIMNASIO_PRUEBA_OK pasa=false (timeout)")
			get_tree().quit()
			return
		var idx := int(_esp["idx"])
		if idx < est.size():
			var p: Vector3 = est[idx]["p"]
			_jugador.position = p + Vector3(0, 0.95, 0)
	print("GIMNASIO_PRUEBA_OK pasa=true")
	get_tree().quit()

func _probar_bus() -> void:
	_probar_bus_desde(0)

func _probar_bus_b() -> void:
	_probar_bus_desde(0, 1)

func _probar_bus_desde(k: int, sentido := 0) -> void:
	_empleo_desbloqueado = true
	_iniciar_bus(sentido)
	if _esp.is_empty():
		print("BUS_PRUEBA_OK pasa=false (no arranco)")
		get_tree().quit()
		return
	if k > 0:
		# Saltar a la parada k ya servida: el autobús arranca desde ahí
		_esp["idx"] = k
		_esp["servidas"] = k
		_esp["entro"] = true
		var pv: Vector2 = _esp["paradas"][k - 1]["p"]
		var s_k := float(_esp["paradas"][k - 1]["s"])
		var pr := _punto_en_ruta_bus(s_k)
		var pd := _punto_en_ruta_bus(s_k + 20.0)
		_dir_bus = atan2(pd.x - pr.x, pd.y - pr.y)
		_bus.position = Vector3(pr.x, _altura(pr.x, pr.y), pr.y)
		_bus.rotation.y = _dir_bus
		_fijar_objetivo_bus()
	_jugador.position = _bus.position + Vector3(2.0, 0, 0)
	_jugador.position.y = _altura(_jugador.position.x, _jugador.position.z) + 0.95
	_bus_auto = true
	_alternar_bus()
	var t0 := _tiempo
	var frames := 0
	while not _esp.is_empty():
		await get_tree().physics_frame
		frames += 1
		if frames % 1800 == 0:
			var idx_a := int(_esp["idx"])
			var pv2: Vector2 = _esp["paradas"][mini(idx_a, _esp["paradas"].size() - 1)]["p"]
			var sc2 := _s_cercana_bus(Vector2(_bus.position.x, _bus.position.z), _bus_hint)
			print("BUS_LATIDO pos=(", snappedf(_bus.position.x, 0.1), ",", snappedf(_bus.position.z, 0.1), ") vel=", snappedf(_vel_bus, 0.1), " idx=", idx_a, " dist_parada=", snappedf(Vector2(_bus.position.x, _bus.position.z).distance_to(pv2), 0.1), " s_bus=", snappedf(float(sc2[0]), 0.1))
		if _tiempo - t0 > 1500.0:
			print("BUS_PRUEBA_OK pasa=false (timeout)")
			get_tree().quit()
			return
	print("BUS_PRUEBA_OK pasa=true")
	get_tree().quit()


# ============ FASE 13: HISTORIA Y ENCUENTROS ============
# Historia lineal propia (13A: 3 capítulos, 12 misiones, 5 personajes
# fijos), con sistema de diálogos, y encuentros callejeros con vecinos.
const HISTORIA: Array = [
	{"pj": "carmen", "titulo": "La casera", "dest": "panaderia", "dest_txt": "ve a la panadería", "paga": 10, "adelanto": 5, "tipo": "",
	 "intro": [["Carmen", "¡Hombre, el inquilino nuevo! Soy Carmen, tu casera. El piso es pequeño, pero tiene una luz preciosa."], ["Tú", "Encantado, Carmen. Acabo de llegar y aún no tengo ni desayuno."], ["Carmen", "Pues baja a la panadería de aquí al lado y tráeme una barra de paso. Quédate las vueltas para un café."]],
	 "cierre": [["Carmen", "Esa barra huele a gloria. En Logroño el pan se compra a diario, ¿eh? No me seas de congelar."], ["Tú", "Anotado, Carmen."]]},
	{"pj": "elias", "titulo": "El banco del Espolón", "dest": "parque_ebro", "dest_txt": "acompáñale al Parque del Ebro", "paga": 12, "tipo": "", "esc": "pie",
	 "intro": [["Elías", "Siéntate un rato, joven. Llevo cuarenta años en este banco y el Espolón no me ha fallado ni un día."], ["Tú", "¿Y no se cansa de mirar siempre lo mismo?"], ["Elías", "Lo mismo, dice… Anda, acompáñame al Parque del Ebro y te enseño el río de verdad."]],
	 "cierre": [["Elías", "¿Ves? El Ebro no pasa: se queda. Por eso los de aquí volvemos siempre."], ["Tú", "Creo que lo entiendo, Elías."]]},
	{"pj": "lucia", "titulo": "Un libro para Carmen", "dest": "pj:carmen", "dest_txt": "lleva el libro a Carmen", "paga": 15, "tipo": "",
	 "intro": [["Lucía", "Bienvenido a la librería. Carmen, tu casera, es mi mejor clienta: un libro por semana."], ["Tú", "Justo venía a presentarme."], ["Lucía", "Pues hazme un favor: llévale este ejemplar que tenía encargado. Dile que esta vez se va a reír."]],
	 "cierre": [["Lucía", "¿Entregado? Carmen con un libro es feliz una semana entera. Pásate cuando quieras: aquí el que lee, repite."]]},
	{"pj": "paco", "titulo": "El coche suena raro", "dest": "taller", "dest_txt": "lleva el coche al Taller Ebro", "paga": 0, "tipo": "reparar",
	 "intro": [["Paco", "Ese motor suena a cazuela, amigo. Soy Paco, del Taller Ebro. Tráeme el coche y te lo escucho de cerca."], ["Tú", "¿Tan mal suena?"], ["Paco", "En Logroño nos conocemos por el ruido del coche. Ven al taller y salimos de dudas."]],
	 "cierre": [["Paco", "Listo: era menos de lo que parecía. Te lo he dejado como nuevo, sin cobrarte: la primera visita es de la casa."], ["Tú", "Gracias, Paco. Te debo una."]]},
	{"pj": "marta", "titulo": "La conductora", "dest": "hospital", "dest_txt": "ve a la terminal del Hospital", "paga": 18, "tipo": "",
	 "intro": [["Marta", "Perdona, ¿tú eres el nuevo del barrio? Soy Marta, conduzco la línea 1. Se me ha quedado el termo en la terminal del Hospital."], ["Tú", "¿Y no puedes ir a por él?"], ["Marta", "Salgo en cinco minutos y sin termo no soy persona. ¿Me lo recoges? Está en la parada de Puente Madre."]],
	 "cierre": [["Marta", "¡Mi termo! Hoy la línea 1 va a funcionar como un reloj. Sube un día y te enseño la ruta entera."]]},
	{"pj": "elias", "titulo": "Fotos del Ebro", "dest": "hierro", "dest_txt": "llévale al Puente de Hierro", "paga": 20, "tipo": "", "esc": "coche",
	 "intro": [["Elías", "De joven cruzaba el Puente de Hierro contando los remaches. Mil doscientos, decíamos."], ["Tú", "¿Y eran mil doscientos?"], ["Elías", "Nunca lo supimos: siempre nos salían cuentas distintas. Llévame en coche y lo comprobamos… de lejos."]],
	 "cierre": [["Elías", "Ahí sigue, firme desde 1882. Los puentes de hierro no se oxidan: se jubilan, como yo."]]},
	{"pj": "paco", "titulo": "La furgoneta de Paco", "dest": "lejos", "dest_txt": "entrega el paquete en Varea", "paga": 25, "tipo": "",
	 "intro": [["Paco", "Tengo un paquete para un cliente de Varea y la furgoneta del taller está en las últimas."], ["Tú", "¿Quieres que lo lleve yo?"], ["Paco", "Si me haces ese favor, te lo pago como un reparto de los buenos. Es el portal que te marco en el mapa."]],
	 "cierre": [["Paco", "Entregado y firmado. Varea queda ahí al lado, pero sin coche es el fin del mundo."]]},
	{"pj": "lucia", "titulo": "Cierre de la librería", "dest": "mercado", "dest_txt": "lleva las cajas al Mercado de San Blas", "paga": 22, "tipo": "",
	 "intro": [["Lucía", "Hoy cerramos antes: es la fiesta del barrio y llevo unas cajas de libros al puesto del Mercado de San Blas."], ["Tú", "¿Te echo una mano?"], ["Lucía", "Dos manos y un paseo, que el mercado a esta hora es una preciosidad."]],
	 "cierre": [["Lucía", "Cajas entregadas. Si el puesto vende la mitad, este año la fiesta se paga sola."]]},
	{"pj": "carmen", "titulo": "El pregón", "dest": "ayto", "dest_txt": "ve a la Plaza del Ayuntamiento", "paga": 20, "tipo": "",
	 "intro": [["Carmen", "¿Ya es San Mateo? El pregón en la plaza del Ayuntamiento no te lo puedes perder el primer año."], ["Tú", "¿Tan importante es?"], ["Carmen", "En Logroño, San Mateo es sagrado: vino, fiestas y la ciudad entera en la calle. Ve a la plaza y luego me cuentas."]],
	 "cierre": [["Carmen", "¿Has visto? Cuando suena el pregón, hasta las campanas de la Redonda parecen aplaudir."]]},
	{"pj": "carmen", "titulo": "Vino para la fiesta", "dest": "tienda", "dest_txt": "ve a la tienda de Gran Vía", "paga": 26, "tipo": "",
	 "intro": [["Carmen", "Esta noche vienen mis sobrinos a ver los fuegos y no tengo ni vino decente en casa."], ["Tú", "¿Compro yo?"], ["Carmen", "En la tienda de Gran Vía saben mi gusto: pide «lo de Carmen» y no discutas, que aciertan siempre."]],
	 "cierre": [["Carmen", "Rioja crianza, como debe ser. Esta noche brindamos en el balcón, que se ven los fuegos del Ebro."]]},
	{"pj": "marta", "titulo": "El día grande de Marta", "dest": "toros", "dest_txt": "llévala a la Plaza de Toros", "paga": 30, "tipo": "", "esc": "coche",
	 "intro": [["Marta", "Hoy termino el turno en la Estación y he quedado en la Plaza de Toros con media cuadrilla de conductores."], ["Tú", "¿Te llevo?"], ["Marta", "Si me acercas en coche, llego a la primera copa. Es mi día grande, no me hagas ir andando."]],
	 "cierre": [["Marta", "¡A tiempo! Hoy brinda la línea 1 entera. Gracias por el paseo, vecina… digo, vecino."]]},
	{"pj": "elias", "titulo": "Fuegos en el Ebro", "dest": "parque_ebro", "dest_txt": "ve al Parque del Ebro", "paga": 40, "tipo": "",
	 "intro": [["Elías", "Esta noche hay fuegos sobre el Ebro, como cada San Mateo. Carmen, Marta y Lucía vienen a verlos al parque."], ["Tú", "¿Me guardáis sitio?"], ["Elías", "A ti te guardamos el mejor: el de mirar el río con nosotros. Ven al Parque del Ebro al caer el sol."]],
	 "cierre": [["Elías", "Mira el río, joven: cada fuego se duplica en el agua."], ["Carmen", "Y este año, por fin, la pandilla está completa."], ["Marta", "El año que viene te toca traer el vino a ti."], ["Tú", "Trato hecho. Feliz San Mateo."]]},
]
const SALUDOS: Dictionary = {
	"carmen": "¿Qué tal el piso? Si la caldera hace ruidos raros, me llamas, ¿eh?",
	"paco": "Ese coche ya suena a coche de verdad. Cuídalo.",
	"lucia": "Pásate un día sin prisa: tengo una estantería entera para ti.",
	"elias": "Mi banco tiene sitio para dos. Cuando quieras, charlamos.",
	"marta": "La línea 1 y yo seguimos dando vueltas por Logroño.",
}
const ENCUENTROS: Array = [
	{"nombre": "Una turista", "texto": "Perdona, ¿sabes por dónde queda la Concatedral de la Redonda? Llevo el mapa del revés…", "dest": "redonda", "paga": 8, "camisa": 1},
	{"nombre": "Un señor con bolsas", "texto": "Joven, ¿me ayudas con estas bolsas? Vivo aquí al lado, pero pesan como piedras.", "dest": "portal", "paga": 6, "camisa": 3},
	{"nombre": "Una niña", "texto": "Se me ha caído el balón por el Espolón y no lo encuentro…", "dest": "espolon", "paga": 5, "camisa": 4},
	{"nombre": "Un repartidor", "texto": "Perdona, este portal no aparece en mi ruta y es mi primer día. ¿Me acompañas?", "dest": "portal", "paga": 10, "camisa": 5},
	{"nombre": "Una abuela", "texto": "Ay, hijo, ¿me acompañas un poco más adelante? Con esta luz no veo ni los carteles.", "dest": "portal", "paga": 7, "camisa": 6},
	{"nombre": "Un estudiante", "texto": "¿Sabes llegar a la plaza del Ayuntamiento? He quedado allí y voy tarde.", "dest": "ayto", "paga": 9, "camisa": 2},
]

func _crear_historia() -> void:
	var defs: Array = [
		{"id": "carmen", "nombre": "Carmen", "camisa": Color(0.55, 0.30, 0.45), "pantalon": Color(0.25, 0.22, 0.28), "pelo": Color(0.45, 0.42, 0.40), "fem": true},
		{"id": "paco", "nombre": "Paco", "camisa": Color(0.30, 0.35, 0.55), "pantalon": Color(0.20, 0.20, 0.22), "pelo": Color(0.12, 0.10, 0.08), "fem": false},
		{"id": "lucia", "nombre": "Lucía", "camisa": Color(0.70, 0.55, 0.25), "pantalon": Color(0.35, 0.25, 0.20), "pelo": Color(0.25, 0.15, 0.08), "fem": true},
		{"id": "elias", "nombre": "Elías", "camisa": Color(0.45, 0.48, 0.42), "pantalon": Color(0.30, 0.28, 0.25), "pelo": Color(0.80, 0.78, 0.75), "fem": false},
		{"id": "marta", "nombre": "Marta", "camisa": Color(0.85, 0.55, 0.12), "pantalon": Color(0.22, 0.24, 0.35), "pelo": Color(0.35, 0.22, 0.12), "fem": true},
	]
	var sitios: Dictionary = {}
	var fuera_piso: Vector3 = _interiores["piso"]["fuera"]
	# Carmen espera EN LA CALLE, junto al portal: el desplazamiento
	# anterior (fuera + (2,5, 0, 1,5)) caía dentro del edificio y la
	# búsqueda de punto libre la dejaba invisible; Jon la buscó hasta
	# dentro de su piso. Ahora queda al norte del portal, en la acera.
	sitios["carmen"] = _origen_libre + Vector3(1.2, 0, -2.4)
	sitios["paco"] = Vector3(_lugares_coches["taller"]) + Vector3(2.0, 0, 2.0)
	var mejor_lucia := Vector3(-160, 0, 90)
	var mejor_d := 1e9
	for p in _portales:
		if String(p["calle"]).contains("PORTALES"):
			var d := absf(float(p["x"]) + 160.0)
			if d < mejor_d:
				mejor_d = d
				mejor_lucia = Vector3(float(p["x"]), 0, float(p["z"]))
	sitios["lucia"] = mejor_lucia + Vector3(1.5, 0, 1.5)
	sitios["elias"] = Vector3(-256, 0, 273)
	sitios["marta"] = Vector3(-268.7, 0, 737.2)
	for d in defs:
		var id := String(d["id"])
		var pos := _punto_libre(Vector3(sitios[id]), 0.5)
		var opcs_pj := {
			"carmen": {"piel": Color(0.93, 0.74, 0.60), "talla": 0.95, "pelo_estilo": "mono", "gafas": true, "falda": true, "chaqueta": Color(0.22, 0.18, 0.32)},
			"paco": {"piel": Color(0.88, 0.66, 0.50), "talla": 1.03, "pelo_estilo": "corto", "barba": true, "mono_trabajo": true},
			"lucia": {"piel": Color(0.94, 0.76, 0.62), "talla": 0.99, "pelo_estilo": "coleta", "gafas": true, "chaqueta": Color(0.27, 0.34, 0.48)},
			"elias": {"piel": Color(0.91, 0.71, 0.57), "talla": 0.97, "pelo_estilo": "gorra", "bigote": true, "baston": true},
			"marta": {"piel": Color(0.89, 0.68, 0.53), "talla": 1.0, "pelo_estilo": "mono", "reflectante": true},
		}
		var per := _hacer_persona(d["camisa"], d["pantalon"], d["pelo"], true, bool(d["fem"]), opcs_pj.get(id, {}))
		var raiz: Node3D = per["raiz"]
		raiz.position = Vector3(pos.x, _altura(pos.x, pos.z) + 0.95, pos.z)
		raiz.rotation.y = randf() * TAU
		if id == "carmen":
			raiz.rotation.y = atan2(_origen_libre.x - pos.x, _origen_libre.z - pos.z)
		print("PJ_POS ", id, " ", raiz.position)
		add_child(raiz)
		var et := Label3D.new()
		et.text = String(d["nombre"])
		et.font_size = 72
		et.pixel_size = 0.008
		et.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		et.modulate = Color(1.0, 0.85, 0.45)
		et.outline_size = 10
		et.outline_modulate = Color(0.05, 0.08, 0.14)
		et.position = raiz.position + Vector3(0, 1.35, 0)
		add_child(et)
		_pjs[id] = {"nombre": String(d["nombre"]), "pos": raiz.position, "nodo": raiz, "d": per, "et": et, "casa": raiz.position, "fase": 0.0, "atasco": 0.0, "volviendo": false}
		_registrar_cara(per, String(d["nombre"]))
	_hist_marcar()
	print("HISTORIA_OK personajes=", _pjs.size(), " misiones=", HISTORIA.size(), " idx=", _historia_idx)

func _pj_cercano() -> String:
	if _jugador == null or _en_coche or _en_bus or _en_interior != "":
		return ""
	for id in _pjs.keys():
		var pp: Vector3 = _pjs[id]["pos"]
		if Vector2(_jugador.position.x - pp.x, _jugador.position.z - pp.z).length() < 3.2:
			return String(id)
	return ""

func _hist_dest(clave: String) -> Vector3:
	if clave.begins_with("pj:"):
		return Vector3(_pjs[clave.trim_prefix("pj:")]["pos"])
	match clave:
		"panaderia":
			return Vector3(_interiores["panaderia"]["fuera"])
		"tienda":
			return Vector3(_interiores["tienda"]["fuera"])
		"taller":
			return Vector3(_lugares_coches["taller"])
		"parque_ebro":
			return Vector3(-142, 0, -238)
		"hierro":
			return Vector3(-341.1, 0, -263.8)
		"ayto", "redonda":
			return Vector3(261, 0, 64) if clave == "ayto" else Vector3(-217, 0, 46)
		"mercado":
			return Vector3(-342, 0, 145)
		"toros":
			return Vector3(456, 0, -490)
		"hospital":
			return Vector3(1612.8, 0, 1517.8)
		"espolon":
			return Vector3(-259, 0, 271)
		"lejos":
			var mejor := Vector3(1500, 0, 300)
			var mejor_x := -1e9
			for p in _portales:
				if float(p["x"]) > mejor_x and float(p["x"]) > 1100.0:
					mejor_x = float(p["x"])
					mejor = Vector3(float(p["x"]), 0, float(p["z"]))
			return mejor
	return Vector3.ZERO

func _hist_fijar(p: Vector3, texto: String) -> void:
	_fijar_objetivo(_punto_libre(p, 0.4))
	_objetivo_texto = texto
	_actualizar_hud()

func _hist_marcar() -> void:
	if not _hist.is_empty():
		var m: Dictionary = HISTORIA[int(_hist["idx"])]
		if String(_hist["fase"]) == "ir":
			_hist_fijar(_hist_dest(String(m["dest"])), "Historia · " + String(m["titulo"]) + ": " + String(m["dest_txt"]))
		elif String(m.get("esc", "")) != "":
			_hist_fijar(_hist_dest("pj:" + String(m["pj"])), "Historia · habla con " + String(_pjs[String(m["pj"])]["nombre"]))
		else:
			_hist_fijar(_hist_dest("pj:" + String(m["pj"])), "Historia · vuelve con " + String(_pjs[String(m["pj"])]["nombre"]))
	elif _historia_idx < HISTORIA.size():
		var m2: Dictionary = HISTORIA[_historia_idx]
		_hist_fijar(_hist_dest("pj:" + String(m2["pj"])), "Historia · habla con " + String(_pjs[String(m2["pj"])]["nombre"]))
	else:
		_pilar_destino.visible = false
		_objetivo_texto = "Historia terminada · gracias por jugar"

func _hablar_cercano() -> void:
	if not _carr.is_empty():
		_aviso_set("Estás en plena carrera: ahora no es momento de charla", 4.0)
		return
	var id := _pj_cercano()
	if id == "":
		return
	var nombre := String(_pjs[id]["nombre"])
	if not _hist.is_empty():
		var m: Dictionary = HISTORIA[int(_hist["idx"])]
		if String(_hist["fase"]) == "volver" and String(m["pj"]) == id:
			_abrir_dialogo(m["cierre"], Callable(self, "_hist_completar"))
		else:
			_abrir_dialogo([[nombre, "Ahora estás a lo de " + String(_pjs[String(m["pj"])]["nombre"]) + ": no te despistes."]], Callable())
		return
	if not _trabajo.is_empty() or not _esp.is_empty():
		_abrir_dialogo([[nombre, "Ahora no, vecino: termina primero lo que llevas entre manos y luego hablamos."]], Callable())
		return
	if _historia_idx >= HISTORIA.size():
		_abrir_dialogo([[nombre, String(SALUDOS[id])]], Callable())
		return
	var mision: Dictionary = HISTORIA[_historia_idx]
	if String(mision["pj"]) == id:
		_abrir_dialogo(mision["intro"], Callable(self, "_hist_empezar"))
	else:
		_abrir_dialogo([[nombre, String(SALUDOS[id]) + " Creo que " + String(_pjs[String(mision["pj"])]["nombre"]) + " te andaba buscando."]], Callable())

func _hist_empezar() -> void:
	var m: Dictionary = HISTORIA[_historia_idx]
	_hist = {"idx": _historia_idx, "fase": "ir", "pasajero": false}
	var adelanto := int(m.get("adelanto", 0))
	if adelanto > 0:
		# Recados con compra: quien encarga pone el dinero por delante
		# (Carmen: 5 € para una barra de 2 €, «quédate las vueltas»).
		_dinero += adelanto
		_actualizar_hud_dinero()
		_aviso_set(String(_pjs[String(m["pj"])]["nombre"]) + " te da " + str(adelanto) + " € para el recado", 5.0)
		print("HISTORIA_ADELANTO ", adelanto, " dinero=", _dinero)
	if String(m.get("esc", "")) != "":
		_pjs[String(m["pj"])]["volviendo"] = false
	_hist_marcar()
	_sonar("ding")
	print("HISTORIA_INICIO ", _historia_idx + 1, " ", String(m["titulo"]))

func _hist_llegada() -> void:
	var m: Dictionary = HISTORIA[int(_hist["idx"])]
	if String(m["tipo"]) == "reparar" and not _mis_coches.is_empty():
		_mis_coches[_coche_activo]["danio"] = 0
		_guardar()
		_aviso_set("Paco ha dejado tu coche como nuevo", 5.0)
		print("HISTORIA_REPARA danio=0")
	_hist["fase"] = "volver"
	_hist_marcar()
	_sonar("ding")
	print("HISTORIA_DESTINO ", int(_hist["idx"]) + 1)

func _hist_completar() -> void:
	var m: Dictionary = HISTORIA[int(_hist["idx"])]
	if String(m.get("esc", "")) != "":
		_pjs[String(m["pj"])]["volviendo"] = true
	var paga := int(m["paga"])
	if paga > 0:
		_dinero += paga
		_sonar("cobro")
	if int(_hist["idx"]) == 0 and _pan_en_mano:
		# La barra llega a su destino: la mano queda libre.
		_pan_en_mano = false
		_refrescar_pan()
	_historia_idx += 1
	_hist = {}
	_guardar()
	print("HISTORIA_MISION_OK ", _historia_idx, " paga=", paga, " dinero=", _dinero)
	if _historia_idx < HISTORIA.size():
		var sig: Dictionary = HISTORIA[_historia_idx]
		_aviso_set("Historia · nueva misión: " + String(sig["titulo"]) + " (habla con " + String(_pjs[String(sig["pj"])]["nombre"]) + ")", 6.0)
	_hist_marcar()
	_actualizar_hud()

func _hist_cancelar() -> void:
	if not _hist.is_empty():
		var m_c: Dictionary = HISTORIA[int(_hist["idx"])]
		if String(m_c.get("esc", "")) != "":
			_pjs[String(m_c["pj"])]["volviendo"] = true
	_hist = {}
	_hist_marcar()
	_aviso_set("Historia en pausa: la misión te espera donde estaba", 5.0)
	print("HISTORIA_PAUSA")

func _historia_info() -> void:
	if _historia_idx >= HISTORIA.size():
		_aviso_set("Historia (13A) terminada: gracias por jugar", 5.0)
		return
	var m: Dictionary = HISTORIA[_historia_idx]
	_hist_marcar()
	if not _hist.is_empty():
		_aviso_set("Historia · " + String(m["titulo"]) + ": " + String(m["dest_txt"]), 5.0)
	else:
		_aviso_set("Historia · " + String(m["titulo"]) + ": habla con " + String(_pjs[String(m["pj"])]["nombre"]), 5.0)

# ---------- Diálogos ----------
func _abrir_dialogo(lineas: Array, al_cerrar: Callable) -> void:
	_dlg_lineas = lineas
	_dlg_i = 0
	_dlg_al_cerrar = al_cerrar
	_dlg_opciones = []
	_dlg_sel = 0
	_dlg_abierto = true
	_panel_dlg.visible = true
	_mostrar_linea()

func _abrir_dialogo_opciones(nombre: String, texto: String, opciones: Array) -> void:
	_dlg_lineas = [[nombre, texto]]
	_dlg_i = 0
	_dlg_al_cerrar = Callable()
	_dlg_opciones = opciones
	_dlg_sel = 0
	_dlg_abierto = true
	_panel_dlg.visible = true
	_mostrar_linea()

func _mostrar_linea() -> void:
	if _dlg_i >= _dlg_lineas.size():
		_cerrar_dialogo()
		return
	var lin: Array = _dlg_lineas[_dlg_i]
	_dlg_nombre.text = String(lin[0])
	_dlg_texto.text = String(lin[1])
	for h in _dlg_botones.get_children():
		h.queue_free()
	if not _dlg_opciones.is_empty():
		for i in _dlg_opciones.size():
			var op: Dictionary = _dlg_opciones[i]
			var b := Button.new()
			b.text = ("▸ " if i == _dlg_sel else "") + String(op["t"])
			b.add_theme_font_size_override("font_size", 19)
			if i == _dlg_sel:
				b.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
			var f: Callable = op["f"]
			b.pressed.connect(func() -> void: _dlg_elegir(f))
			_dlg_botones.add_child(b)
	else:
		var b2 := Button.new()
		b2.text = "Seguir ▸" if _dlg_i < _dlg_lineas.size() - 1 else "Cerrar"
		b2.add_theme_font_size_override("font_size", 19)
		b2.pressed.connect(func() -> void: _dlg_seguir())
		_dlg_botones.add_child(b2)

func _dlg_mover(d: int) -> void:
	if _dlg_opciones.is_empty():
		return
	_dlg_sel = (_dlg_sel + d + _dlg_opciones.size()) % _dlg_opciones.size()
	_mostrar_linea()

func _dlg_confirmar() -> void:
	if _dlg_opciones.is_empty():
		_dlg_seguir()
		return
	var f: Callable = _dlg_opciones[_dlg_sel]["f"]
	_dlg_elegir(f)

func _dlg_seguir() -> void:
	if not _dlg_opciones.is_empty():
		return
	_dlg_i += 1
	_mostrar_linea()

func _dlg_elegir(f: Callable) -> void:
	_dlg_opciones = []
	_dlg_abierto = false
	_panel_dlg.visible = false
	if f.is_valid():
		f.call()

func _cerrar_dialogo() -> void:
	_dlg_abierto = false
	_panel_dlg.visible = false
	var f := _dlg_al_cerrar
	_dlg_al_cerrar = Callable()
	if f.is_valid():
		f.call()

# ---------- Encuentros ----------
func _mover_encuentro(delta: float) -> void:
	# La persona del encuentro acompaña al jugador andando tras él, con
	# sus pasos y su balanceo (antes se quedaba clavada donde aparecía).
	if _enc.is_empty() or not bool(_enc.get("activo", false)) or _dlg_abierto:
		return
	if _en_coche:
		# Si se montó contigo, viaja dentro del coche (invisible y
		# pegado a él); si no se montó, te espera donde está.
		if bool(_enc.get("en_coche", false)):
			var raiz_c: Node3D = _enc["nodo"]
			if raiz_c != null and is_instance_valid(raiz_c):
				raiz_c.position = _coche.position
		return
	if _en_bus or _en_interior != "" or _sentado:
		return
	var raiz: Node3D = _enc["nodo"]
	if raiz == null or not is_instance_valid(raiz):
		return
	var yo := Vector2(_jugador.position.x, _jugador.position.z)
	var el := Vector2(raiz.position.x, raiz.position.z)
	var dist := yo.distance_to(el)
	if dist > 120.0:
		# Se quedó muy atrás (un atasco, un rodeo): reaparece cerca de ti,
		# en un punto libre, como hacen los juegos de escolta.
		var detras := _jugador.position - Vector3(sin(_dir_jugador), 0, cos(_dir_jugador)) * 3.0
		var cerca := _punto_libre(detras, 0.5)
		raiz.position = Vector3(cerca.x, _altura(cerca.x, cerca.z) + 0.95, cerca.z)
		return
	if dist < 1.7:
		return  # ya va a tu lado
	var dir := (yo - el) / dist
	var objetivo := yo - dir * 1.6
	var hacia := objetivo - el
	if hacia.length() < 0.05:
		return
	var vel := clampf(dist * 1.7, 2.6, 10.6)
	var paso := hacia.normalized() * minf(vel * delta, hacia.length())
	var dir_mov := paso
	var movio := false
	if _choca(el, 0.34):
		# Ya está dentro de la zona gruesa de un muro: sale en línea
		# recta, como hace _mover con quien se queda pegado a una fachada.
		raiz.position.x = el.x + paso.x
		raiz.position.z = el.y + paso.y
		movio = true
	else:
		for ang in [0.0, 0.7, -0.7, 1.4, -1.4]:
			var cand := el + paso.rotated(ang)
			if not _choca(cand, 0.34) and not _choca_entidad(cand, 0.34, raiz):
				raiz.position.x = cand.x
				raiz.position.z = cand.y
				dir_mov = cand - el
				movio = true
				break
	if movio:
		_enc["atasco"] = 0.0
	elif dist > 3.5:
		# Atascada contra algo que no puede rodear: al cabo de un segundo
		# y pico reaparece a tu lado, en un punto libre (truco de escolta).
		_enc["atasco"] = float(_enc.get("atasco", 0.0)) + delta
		if float(_enc["atasco"]) > 1.4:
			_enc["atasco"] = 0.0
			var detras2 := _jugador.position - Vector3(sin(_dir_jugador), 0, cos(_dir_jugador)) * 2.6
			var cerca2 := _punto_libre(detras2, 0.5)
			raiz.position = Vector3(cerca2.x, _altura(cerca2.x, cerca2.z) + 0.95, cerca2.z)
			return
	raiz.position.y = _altura(raiz.position.x, raiz.position.z) + 0.95
	if movio:
		raiz.rotation.y = atan2(dir_mov.x, dir_mov.y)
		_enc["fase"] = float(_enc.get("fase", 0.0)) + delta * vel * 4.2
		var a := sin(float(_enc["fase"])) * 0.5
		var d: Dictionary = _enc["d"]
		(d["pi"] as Node3D).rotation.x = a
		(d["pd"] as Node3D).rotation.x = -a
		(d["bi"] as Node3D).rotation.x = -a * 0.7
		(d["bd"] as Node3D).rotation.x = a * 0.7
		_balanceo_extra(d, float(_enc["fase"]))
		raiz.position.y += absf(sin(float(_enc["fase"]))) * 0.035

func _pj_caminar(pj: Dictionary, objetivo: Vector2, delta: float, tras_jugador: bool) -> void:
	# Andar hacia un punto con la misma receta del encuentro: rodeos
	# cortos si choca, balanceo de pasos y, si se atasca o queda muy
	# atrás, reaparición discreta en un punto libre (truco de escolta).
	var raiz: Node3D = pj["nodo"]
	var el := Vector2(raiz.position.x, raiz.position.z)
	var dist := el.distance_to(objetivo)
	if tras_jugador and dist > 120.0:
		var detras := _jugador.position - Vector3(sin(_dir_jugador), 0, cos(_dir_jugador)) * 3.0
		var cerca := _punto_libre(detras, 0.5)
		raiz.position = Vector3(cerca.x, _altura(cerca.x, cerca.z) + 0.95, cerca.z)
		return
	if dist < (1.7 if tras_jugador else 0.4):
		_pose_reposo(pj["d"], delta)
		return
	var dir := (objetivo - el) / dist
	var destino := objetivo - dir * (1.6 if tras_jugador else 0.0)
	var hacia := destino - el
	if hacia.length() < 0.05:
		return
	var vel := clampf(dist * 1.7, 2.6, 10.6)
	var paso := hacia.normalized() * minf(vel * delta, hacia.length())
	var dir_mov := paso
	var movio := false
	if _choca(el, 0.34):
		raiz.position.x = el.x + paso.x
		raiz.position.z = el.y + paso.y
		movio = true
	else:
		for ang in [0.0, 0.7, -0.7, 1.4, -1.4]:
			var cand := el + paso.rotated(ang)
			if not _choca(cand, 0.34) and not _choca_entidad(cand, 0.34, raiz):
				raiz.position.x = cand.x
				raiz.position.z = cand.y
				dir_mov = cand - el
				movio = true
				break
	if movio:
		pj["atasco"] = 0.0
	elif dist > 3.5:
		pj["atasco"] = float(pj.get("atasco", 0.0)) + delta
		if float(pj["atasco"]) > 1.4:
			pj["atasco"] = 0.0
			var base_t := _jugador.position if tras_jugador else Vector3(objetivo.x, _altura(objetivo.x, objetivo.y), objetivo.y)
			var detras2 := base_t - Vector3(sin(_dir_jugador), 0, cos(_dir_jugador)) * 2.6
			var cerca2 := _punto_libre(detras2 if tras_jugador else base_t, 0.5)
			raiz.position = Vector3(cerca2.x, _altura(cerca2.x, cerca2.z) + 0.95, cerca2.z)
			return
	raiz.position.y = _altura(raiz.position.x, raiz.position.z) + 0.95
	if movio:
		raiz.rotation.y = atan2(dir_mov.x, dir_mov.y)
		pj["fase"] = float(pj.get("fase", 0.0)) + delta * vel * 4.2
		var a := sin(float(pj["fase"])) * 0.5
		var d: Dictionary = pj["d"]
		(d["pi"] as Node3D).rotation.x = a
		(d["pd"] as Node3D).rotation.x = -a
		(d["bi"] as Node3D).rotation.x = -a * 0.7
		(d["bd"] as Node3D).rotation.x = a * 0.7
		_balanceo_extra(d, float(pj["fase"]))
		raiz.position.y += absf(sin(float(pj["fase"]))) * 0.035

func _mover_historia(delta: float) -> void:
	# Los personajes de las misiones de escolta acompañan de verdad:
	# andan tras el jugador, se montan en el coche si conduces y, al
	# terminar la misión, regresan andando a su sitio. Antes se
	# quedaban clavados donde estaban y la ficción se rompía (Jon:
	# «me dice Elías que lo acompañe… y se queda quieto»).
	var id := ""
	var modo := ""
	if not _hist.is_empty() and String(_hist.get("fase", "")) == "ir":
		var m: Dictionary = HISTORIA[int(_hist["idx"])]
		if String(m.get("esc", "")) != "":
			id = String(m["pj"])
			modo = "seguir"
	if id == "":
		for k in _pjs.keys():
			if bool(_pjs[k].get("volviendo", false)):
				id = String(k)
				modo = "casa"
				break
	if id == "":
		return
	var pj: Dictionary = _pjs[id]
	var raiz: Node3D = pj["nodo"]
	if raiz == null or not is_instance_valid(raiz):
		return
	if modo == "seguir" and not _dlg_abierto:
		if _en_coche:
			if bool(_hist.get("pasajero", false)) and not raiz.visible:
				raiz.position = _coche.position
			elif Vector2(raiz.position.x, raiz.position.z).distance_to(Vector2(_coche.position.x, _coche.position.z)) < 6.0:
				_hist["pasajero"] = true
				raiz.visible = false
				_aviso_set(String(pj["nombre"]) + " se monta en el coche", 3.5)
		elif _en_bus or _en_interior != "" or _sentado:
			pass
		else:
			_pj_caminar(pj, Vector2(_jugador.position.x, _jugador.position.z), delta, true)
	elif modo == "casa" and not _dlg_abierto and not _en_coche:
		var casa: Vector3 = pj["casa"]
		if Vector2(raiz.position.x, raiz.position.z).distance_to(Vector2(casa.x, casa.z)) < 2.0:
			pj["volviendo"] = false
		else:
			_pj_caminar(pj, Vector2(casa.x, casa.z), delta, false)
	pj["pos"] = raiz.position
	var et: Label3D = pj["et"]
	if et != null and is_instance_valid(et):
		et.position = raiz.position + Vector3(0, 1.35, 0)

func _actualizar_encuentros(delta: float) -> void:
	if _enc_prox < 0.0:
		_enc_prox = _tiempo + 150.0
		return
	if _auto or not _modo_libre or _dlg_abierto:
		return
	if _tiempo < _enc_prox:
		return
	if _en_coche or _en_bus or _sentado or _en_interior != "":
		return
	if not _trabajo.is_empty() or not _esp.is_empty() or not _hist.is_empty() or not _enc.is_empty() or not _carr.is_empty():
		return
	_lanzar_encuentro()

func _lanzar_encuentro() -> void:
	var e: Dictionary = ENCUENTROS[_rng.randi_range(0, ENCUENTROS.size() - 1)]
	var frente := Vector3(sin(_dir_jugador), 0, cos(_dir_jugador))
	var lado := Vector3(frente.z, 0, -frente.x)
	var pos := _punto_libre(_jugador.position + frente * 4.5, 0.5)
	for cand in [_jugador.position + frente * 4.5, _jugador.position - frente * 3.5, _jugador.position + lado * 3.5, _jugador.position - lado * 3.5]:
		var libre_c := _punto_libre(cand, 0.5)
		if _segmento_libre(Vector2(_jugador.position.x, _jugador.position.z), Vector2(libre_c.x, libre_c.z), 0.35):
			pos = libre_c
			break
	var per := _hacer_persona(CAMISETAS[int(e["camisa"])], Color(0.25, 0.25, 0.30), PELOS[1], false, false)
	var raiz: Node3D = per["raiz"]
	raiz.position = Vector3(pos.x, _altura(pos.x, pos.z) + 0.95, pos.z)
	raiz.rotation.y = atan2(_jugador.position.x - pos.x, _jugador.position.z - pos.z)
	add_child(raiz)
	var dest := _enc_destino(String(e["dest"]))
	_enc = {"nodo": raiz, "paga": int(e["paga"]), "dest": dest, "nombre": String(e["nombre"]), "activo": false, "d": per, "fase": 0.0}
	_sonar("aviso")
	_abrir_dialogo_opciones(String(e["nombre"]), String(e["texto"]), [
		{"t": "Te ayudo", "f": Callable(self, "_enc_aceptar")},
		{"t": "Lo siento, tengo prisa", "f": Callable(self, "_enc_pasar")}])
	print("ENCUENTRO ", String(e["nombre"]))

func _enc_destino(clave: String) -> Vector3:
	if clave != "portal":
		return _hist_dest(clave)
	var origen := Vector2(_jugador.position.x, _jugador.position.z)
	for intento in range(40):
		var p: Dictionary = _portales[_rng.randi_range(0, _portales.size() - 1)]
		var d := origen.distance_to(Vector2(float(p["x"]), float(p["z"])))
		if d > 120.0 and d < 420.0:
			return Vector3(float(p["x"]), 0, float(p["z"]))
	return _hist_dest("espolon")

func _enc_aceptar() -> void:
	_enc["activo"] = true
	var dest: Vector3 = _enc["dest"]
	_hist_fijar(dest, "Encuentro · acompaña a " + String(_enc["nombre"]))
	print("ENCUENTRO_ACEPTADO")

func _enc_pasar() -> void:
	_enc_prox = _tiempo + _rng.randf_range(90.0, 150.0)
	_enc_liberar()
	print("ENCUENTRO_PASADO")

func _enc_liberar() -> void:
	var nd: Node = _enc.get("nodo")
	if nd != null and is_instance_valid(nd):
		nd.queue_free()
	_enc = {}

func _enc_llegada() -> void:
	if not bool(_enc.get("activo", false)):
		return
	_dinero += int(_enc["paga"])
	_sonar("cobro")
	_aviso_set("Te dan las gracias: +" + str(int(_enc["paga"])) + " €", 5.0)
	print("ENCUENTRO_OK paga=", int(_enc["paga"]))
	_enc_prox = _tiempo + _rng.randf_range(150.0, 260.0)
	_enc_liberar()
	_hist_marcar()
	_actualizar_hud()

func _enc_cancelar() -> void:
	_enc_liberar()
	_hist_marcar()
	_aviso_set("Encuentro cancelado", 4.0)
	print("ENCUENTRO_CANCELADO")

func _contar_mallas(n: Node) -> int:
	var c := 1 if n is MeshInstance3D else 0
	for h in n.get_children():
		c += _contar_mallas(h)
	return c

func _probar_protagonistas() -> void:
	# E1+E2: el jugador y los cinco PJ de historia son de nivel
	# protagonista (rodillas, codos, ojos y boca) y están en el
	# registro de caras que parpadean y hablan.
	var bien := _rodilla_i != null and _codo_i != null and _caras.size() >= 6
	for id in _pjs.keys():
		var d: Dictionary = _pjs[id]["d"]
		if d.get("ri") == null or d.get("ojo_i") == null or d.get("boca") == null:
			bien = false
	# E3: la ropa en piezas suma mallas frente a ir «a pelo»:
	# el mono de trabajo, las bandas reflectantes y la chaqueta.
	var base3 := _contar_mallas(_hacer_persona(Color(0.4, 0.4, 0.4), Color(0.2, 0.2, 0.2), Color(0.1, 0.1, 0.1), true, false)["raiz"])
	var con_mono := _contar_mallas(_hacer_persona(Color(0.4, 0.4, 0.4), Color(0.2, 0.2, 0.2), Color(0.1, 0.1, 0.1), true, false, {"mono_trabajo": true})["raiz"])
	var con_refl := _contar_mallas(_hacer_persona(Color(0.4, 0.4, 0.4), Color(0.2, 0.2, 0.2), Color(0.1, 0.1, 0.1), true, false, {"reflectante": true})["raiz"])
	var con_chaq := _contar_mallas(_hacer_persona(Color(0.4, 0.4, 0.4), Color(0.2, 0.2, 0.2), Color(0.1, 0.1, 0.1), true, false, {"chaqueta": Color(0.2, 0.2, 0.3)})["raiz"])
	bien = bien and con_mono > base3 and con_refl > base3 and con_chaq > base3
	print("PROTAGONISTAS_OK pasa=", bien, " caras=", _caras.size(), " pjs=", _pjs.size(), " ropa=", base3, "/", con_mono, "/", con_refl, "/", con_chaq)

func _probar_historia() -> void:
	_historia_idx = 0
	_hist = {}
	_dinero = 1000
	_mis_coches[_coche_activo]["danio"] = 40
	var esperado := 0
	for m in HISTORIA:
		esperado += int(m["paga"]) + int(m.get("adelanto", 0))
	var frames := 0
	var ok := true
	while _historia_idx < HISTORIA.size() and frames < 30000:
		var m: Dictionary = HISTORIA[_historia_idx]
		var pjpos: Vector3 = _pjs[String(m["pj"])]["pos"]
		_jugador.position = Vector3(pjpos.x + 1.5, _altura(pjpos.x + 1.5, pjpos.z) + 0.95, pjpos.z)
		await get_tree().physics_frame
		frames += 1
		_hablar_cercano()
		while _dlg_abierto:
			_dlg_seguir()
		if _hist.is_empty():
			ok = false
			print("HISTORIA_PRUEBA_FALLO no empieza la mision ", _historia_idx + 1)
			break
		if String(m.get("esc", "")) != "":
			# El escolta tiene que andar tras el jugador, no quedarse
			# clavado: se le aleja 50 m y debe recuperar terreno.
			var nodo_e: Node3D = _pjs[String(m["pj"])]["nodo"]
			var pos_e0: Vector3 = nodo_e.position
			_jugador.position = Vector3(pos_e0.x + 50.0, _altura(pos_e0.x + 50.0, pos_e0.z) + 0.95, pos_e0.z)
			for f_e in 150:
				await get_tree().physics_frame
				frames += 1
			if nodo_e.position.distance_to(pos_e0) < 4.0:
				ok = false
				print("HISTORIA_PRUEBA_FALLO el escolta no sigue en la mision ", _historia_idx + 1)
				break
		_jugador.position = Vector3(_destino_libre.x, _altura(_destino_libre.x, _destino_libre.z) + 0.95, _destino_libre.z)
		while not _hist.is_empty() and String(_hist.get("fase", "")) == "ir" and frames < 30000:
			await get_tree().physics_frame
			frames += 1
		if _hist.is_empty() or String(_hist.get("fase", "")) != "volver":
			ok = false
			print("HISTORIA_PRUEBA_FALLO sin llegada en la mision ", _historia_idx + 1)
			break
		if _historia_idx == 3 and int(_mis_coches[_coche_activo]["danio"]) != 0:
			ok = false
			print("HISTORIA_PRUEBA_FALLO el taller no reparo")
			break
		var pjpos2: Vector3 = _pjs[String(m["pj"])]["pos"]
		_jugador.position = Vector3(pjpos2.x + 1.5, _altura(pjpos2.x + 1.5, pjpos2.z) + 0.95, pjpos2.z)
		await get_tree().physics_frame
		frames += 1
		var antes := _historia_idx
		_hablar_cercano()
		while _dlg_abierto:
			_dlg_seguir()
		if _historia_idx != antes + 1:
			ok = false
			print("HISTORIA_PRUEBA_FALLO no se completa la mision ", antes + 1)
			break
	var ganado := _dinero - 1000
	if ganado != esperado:
		ok = false
		print("HISTORIA_PRUEBA_FALLO cobro ", ganado, " != ", esperado)
	# Un encuentro completo como remate
	_lanzar_encuentro()
	if _dlg_opciones.size() == 2:
		var f0: Callable = _dlg_opciones[0]["f"]
		_dlg_elegir(f0)
		_jugador.position = Vector3(_destino_libre.x, _altura(_destino_libre.x, _destino_libre.z) + 0.95, _destino_libre.z)
		var f2 := 0
		while not _enc.is_empty() and f2 < 600:
			await get_tree().physics_frame
			f2 += 1
		if not _enc.is_empty():
			ok = false
			print("HISTORIA_PRUEBA_FALLO el encuentro no se cierra")
	else:
		ok = false
		print("HISTORIA_PRUEBA_FALLO el encuentro no ofrece opciones")
	print("HISTORIA_PRUEBA_OK pasa=", ok, " misiones=", _historia_idx, " ganado=", ganado)
	get_tree().quit()

# ============ FASE 14: CARRERAS ============
# Circuitos sobre el grafo real, contrarreloj con fantasma y carreras
# contra 3 rivales con el piloto de arco del autobús. Récords y fantasma
# se guardan con la partida.
const CIRCUITOS: Array = [
	{"id": "centro", "nombre": "Sprint del centro", "clase": "cualquiera", "cps": ["garaje", "portales", "ayto", "espolon", "garaje"], "oro": 115.0, "plata": 135.0, "bronce": 165.0, "rivales": [[3, 15.0], [6, 14.6], [0, 14.0]]},
	{"id": "puentes", "nombre": "Los tres puentes", "clase": "cualquiera", "cps": ["piedra", "hierro", "sagasta", "parque_ebro", "piedra"], "oro": 335.0, "plata": 395.0, "bronce": 485.0, "rivales": [[4, 15.0], [2, 14.6], [1, 14.0]]},
	{"id": "varea", "nombre": "Varea Express", "clase": "Familiar", "cps": ["garaje", "lejos", "hospital", "garaje"], "oro": 415.0, "plata": 490.0, "bronce": 600.0, "rivales": [[5, 18.0], [4, 17.2], [3, 16.2]]},
	{"id": "anillo", "nombre": "El anillo de Logroño", "clase": "Deportivo", "cps": ["espolon", "estacion", "toros", "ayto", "redonda", "espolon"], "oro": 150.0, "plata": 180.0, "bronce": 220.0, "rivales": [[9, 24.5], [8, 23.0], [5, 19.5]]},
]
const FACTORES_PUESTO: Array = [60, 30, 15, 5]

func _fmt_tiempo(t: float) -> String:
	var m := int(t) / 60
	var s := t - float(m * 60)
	var ss := "%.1f" % s
	if s < 10.0:
		ss = "0" + ss
	return str(m) + ":" + ss

func _carr_punto(clave: String) -> Vector3:
	match clave:
		"garaje":
			return Vector3(_lugares_coches["garaje"])
		"taller":
			return Vector3(_lugares_coches["taller"])
		"portales":
			return Vector3(_pjs["lucia"]["pos"])
		"piedra":
			return Vector3(-101.2, 0, -397.2)
		"sagasta":
			var mejor := Vector3(-560, 0, -260)
			var mejor_x := 1e18
			for pu in _puentes:
				var mid: Vector2 = (Vector2(pu["a"]) + Vector2(pu["b"])) * 0.5
				if mid.x < mejor_x:
					mejor_x = mid.x
					mejor = Vector3(mid.x, 0, mid.y)
			return mejor
		"estacion":
			return Vector3(-268.7, 0, 737.2)
	return _hist_dest(clave)

func _carr_ruta(cps: Array) -> Dictionary:
	var pts: Array = []
	var cp_s: Array = [0.0]
	var total := 0.0
	for k in range(cps.size() - 1):
		var a: Vector3 = cps[k]
		var b: Vector3 = cps[k + 1]
		var tramo := _calcular_ruta(a, b)
		if tramo.size() < 2:
			tramo = [a, b]
		for j in range(tramo.size()):
			if k > 0 and j == 0:
				continue
			var p: Vector3 = tramo[j]
			var p2 := Vector2(p.x, p.z)
			if not pts.is_empty():
				total += Vector2(pts[pts.size() - 1]).distance_to(p2)
			pts.append(p2)
		cp_s.append(total)
	var s_acum: Array = []
	var acc := 0.0
	for i in range(pts.size()):
		if i > 0:
			acc += Vector2(pts[i - 1]).distance_to(Vector2(pts[i]))
		s_acum.append(acc)
	return {"pts": pts, "s": s_acum, "total": total, "cp_s": cp_s}

func _punto_en_ruta(ruta: Dictionary, s: float) -> Vector2:
	var pts: Array = ruta["pts"]
	if pts.is_empty():
		return Vector2.ZERO
	s = clampf(s, 0.0, float(ruta["total"]))
	var sa: Array = ruta["s"]
	for i in range(pts.size() - 1):
		if float(sa[i + 1]) >= s:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var seg := float(sa[i + 1]) - float(sa[i])
			var t := 0.0 if seg <= 0.0 else (s - float(sa[i])) / seg
			return a.lerp(b, t)
	return Vector2(pts[pts.size() - 1])

func _seguir_ruta(est: Dictionary, delta: float) -> void:
	if bool(est.get("acabado", false)):
		return
	var ruta: Dictionary = est["ruta"]
	var nodo: Node3D = est["nodo"]
	var pos2 := Vector2(nodo.position.x, nodo.position.z)
	var s_ext := float(est["s"]) + 18.0
	var mira := _punto_en_ruta(ruta, s_ext)
	while s_ext < float(ruta["total"]) and mira.distance_to(pos2) < 9.0:
		s_ext += 6.0
		mira = _punto_en_ruta(ruta, s_ext)
	var hacia := mira - pos2
	var dir_obj := atan2(hacia.x, hacia.y)
	var dif := wrapf(dir_obj - nodo.rotation.y, -PI, PI)
	var vel_obj := float(est["vmax"]) * clampf(1.25 - absf(dif) * 0.95, 0.30, 1.0)
	var vel := float(est["vel"])
	vel = move_toward(vel, vel_obj, (14.0 if vel_obj > vel else 26.0) * delta)
	est["vel"] = vel
	nodo.rotation.y = nodo.rotation.y + clampf(dif, -2.4 * delta, 2.4 * delta)
	est["s"] = float(est["s"]) + vel * delta
	var np := _punto_en_ruta(ruta, float(est["s"]))
	var lat := float(est.get("lat", 0.0))
	if lat != 0.0:
		var d1 := _punto_en_ruta(ruta, float(est["s"]) + 6.0) - _punto_en_ruta(ruta, maxf(0.0, float(est["s"]) - 2.0))
		if d1.length() > 0.01:
			var perp := Vector2(d1.y, -d1.x).normalized()
			np += perp * lat
	nodo.position = Vector3(np.x, _altura(np.x, np.y), np.y)
	if float(est["s"]) >= float(ruta["total"]) - 1.0:
		est["acabado"] = true

func _abrir_panel_carr() -> void:
	if not _carr.is_empty():
		_aviso_set("Ya estás en una carrera: termina o abandona con la ×", 4.0)
		return
	_refrescar_panel_carr()
	_panel_carr.visible = true
	_panel_carr_abierto = true

func _cerrar_panel_carr() -> void:
	_panel_carr.visible = false
	_panel_carr_abierto = false

func _refrescar_panel_carr() -> void:
	for h in _panel_carr_lista.get_children():
		h.queue_free()
	for i in range(CIRCUITOS.size()):
		var c: Dictionary = CIRCUITOS[i]
		var rec: Dictionary = _records.get(String(c["id"]), {})
		var mejor := "sin tiempo"
		if rec.has("tt"):
			mejor = "tu mejor: " + _fmt_tiempo(float(rec["tt"]))
		var lab := Label.new()
		lab.text = String(c["nombre"]) + " · clase " + String(c["clase"]) + " · " + mejor
		lab.add_theme_font_size_override("font_size", 20)
		_panel_carr_lista.add_child(lab)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		var b1 := Button.new()
		b1.text = "Contrarreloj"
		b1.add_theme_font_size_override("font_size", 19)
		b1.pressed.connect(_carr_boton.bind(i, "tt"))
		fila.add_child(b1)
		var b2 := Button.new()
		b2.text = "Contra rivales"
		b2.add_theme_font_size_override("font_size", 19)
		b2.pressed.connect(_carr_boton.bind(i, "rivales"))
		fila.add_child(b2)
		_panel_carr_lista.add_child(fila)

func _carr_boton(idx: int, modo: String) -> void:
	_iniciar_carrera(idx, modo)

func _iniciar_carrera(idx: int, modo: String) -> void:
	if not _trabajo.is_empty() or not _esp.is_empty() or not _hist.is_empty() or not _enc.is_empty():
		_aviso_set("Termina primero lo que llevas entre manos", 4.0)
		return
	if _en_interior != "":
		_aviso_set("Sal del interior para correr", 4.0)
		return
	if _sentado:
		_alternar_sentarse()
	_cerrar_panel_carr()
	var circ: Dictionary = CIRCUITOS[idx]
	var cps: Array = []
	for k in circ["cps"]:
		cps.append(_carr_punto(String(k)))
	var ruta := _carr_ruta(cps)
	var mini_pts: Array = []
	var s_mini := 0.0
	while s_mini < float(ruta["total"]):
		mini_pts.append(_punto_en_ruta(ruta, s_mini))
		s_mini += 20.0
	mini_pts.append(_punto_en_ruta(ruta, float(ruta["total"])))
	# Rivales
	var rivales: Array = []
	if modo == "rivales":
		var lats: Array = [-1.6, 0.0, 1.6]
		for r in range(circ["rivales"].size()):
			var par: Array = circ["rivales"][r]
			var def: Dictionary = COCHES[int(par[0])]
			var nodo := _modelo_coche_fundido(def["color"], def["estilo"], def["dims"])
			add_child(nodo)
			var est := {"ruta": ruta, "s": 0.0, "vel": 0.0, "vmax": float(par[1]), "nodo": nodo, "lat": float(lats[r]), "color": def["color"], "acabado": false, "t_fin": -1.0}
			var p_ini := _punto_en_ruta(ruta, 0.0)
			nodo.position = Vector3(p_ini.x, _altura(p_ini.x, p_ini.y), p_ini.y)
			var p_dir := _punto_en_ruta(ruta, 20.0)
			nodo.rotation.y = atan2(p_dir.x - p_ini.x, p_dir.y - p_ini.y)
			rivales.append(est)
	# Fantasma (solo contrarreloj con récord previo)
	var ghost: Dictionary = {}
	var rec: Dictionary = _records.get(String(circ["id"]), {})
	if modo == "tt" and rec.has("ghost"):
		var defj: Dictionary = COCHES[int(_mis_coches[_coche_activo]["id"])]
		var gnodo := _modelo_coche_fundido(Color(0.45, 0.85, 1.0), defj["estilo"], defj["dims"])
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.45, 0.85, 1.0, 0.38)
		gnodo.material_override = mat
		add_child(gnodo)
		ghost = {"nodo": gnodo, "muestras": rec["ghost"]}
	# Colocar al jugador en la salida, dentro del coche
	var p0: Vector3 = cps[0]
	var p0l := _punto_libre(p0, 0.45)
	_coche.position = Vector3(p0l.x, _altura(p0l.x, p0l.z), p0l.z)
	var pd := _punto_en_ruta(ruta, 20.0)
	_coche_dir = atan2(pd.x - p0l.x, pd.y - p0l.z)
	_coche.rotation.y = _coche_dir
	_coche_vel = 0.0
	_en_coche = true
	_jugador.visible = false
	_jugador.position = _coche.position
	var defpj: Dictionary = COCHES[int(_mis_coches[_coche_activo]["id"])]
	_carr = {"idx": idx, "nombre": String(circ["nombre"]), "modo": modo, "fase": "cuenta",
		"cuenta": 3.2, "ultimo_num": 4, "t0": 0.0, "cp": 1, "cps": cps, "ruta": ruta,
		"rivales": rivales, "ghost": ghost, "grab": [], "grab_t": 0.0, "mini_pts": mini_pts,
		"yo": {"ruta": ruta, "s": 0.0, "vel": 0.0, "vmax": float(defpj["vmax"]) * 0.97, "nodo": _coche, "lat": 0.0, "acabado": false, "t_fin": -1.0}}
	_fijar_objetivo(cps[1])
	_minimapa_carrera(true)
	_objetivo_texto = "Carrera · " + String(circ["nombre"]) + " · ¡prepárate!"
	_actualizar_hud()
	print("CARRERA_INICIO ", String(circ["nombre"]), " modo=", modo, " ruta=", int(float(ruta["total"])), "m")

func _minimapa_carrera(on: bool) -> void:
	# En carrera el minimapa crece: el plano del circuito se lee
	# mejor en grande.
	if _minimapa == null:
		return
	_minimapa.offset_left = -276.0 if on else -208.0
	_minimapa.offset_bottom = 276.0 if on else 208.0

func _carr_puesto() -> int:
	var ruta: Dictionary = _carr["ruta"]
	var cp := int(_carr["cp"])
	var cps: Array = _carr["cps"]
	var cp_s: Array = ruta["cp_s"]
	var dist := Vector2(_coche.position.x - Vector3(cps[cp]).x, _coche.position.z - Vector3(cps[cp]).z).length()
	var leg := float(cp_s[cp]) - float(cp_s[cp - 1])
	var prog := float(cp_s[cp - 1]) + maxf(0.0, leg - dist)
	var puesto := 1
	for est in _carr["rivales"]:
		if float(est["t_fin"]) >= 0.0 or float(est["s"]) > prog:
			puesto += 1
	return puesto

func _actualizar_carrera(delta: float) -> void:
	if _carr.is_empty():
		return
	if String(_carr["fase"]) == "cuenta":
		_carr["cuenta"] = float(_carr["cuenta"]) - delta
		var n := int(ceil(float(_carr["cuenta"])))
		if n != int(_carr["ultimo_num"]) and n >= 1:
			_carr["ultimo_num"] = n
			_sonar("ding")
			_objetivo_texto = "Carrera · " + String(_carr["nombre"]) + " · " + str(n) + "…"
		if float(_carr["cuenta"]) <= 0.0:
			_carr["fase"] = "corriendo"
			_carr["t0"] = _tiempo
			_sonar("timbre")
			print("CARRERA_YA")
		return
	var t := _tiempo - float(_carr["t0"])
	# Grabación del fantasma (contrarreloj)
	if String(_carr["modo"]) == "tt":
		_carr["grab_t"] = float(_carr["grab_t"]) + delta
		if float(_carr["grab_t"]) >= 0.5:
			_carr["grab_t"] = 0.0
			var g: Array = _carr["grab"]
			g.append([_coche.position.x, _coche.position.z, _coche_dir])
	# Fantasma
	var ghost: Dictionary = _carr["ghost"]
	if not ghost.is_empty():
		var muestras: Array = ghost["muestras"]
		var gnodo: Node3D = ghost["nodo"]
		var fi := t / 0.5
		var i0 := int(fi)
		if i0 >= muestras.size() - 1:
			gnodo.visible = false
		else:
			var m0: Array = muestras[i0]
			var m1: Array = muestras[i0 + 1]
			var fr := fi - float(i0)
			var gx := lerpf(float(m0[0]), float(m1[0]), fr)
			var gz := lerpf(float(m0[1]), float(m1[1]), fr)
			gnodo.position = Vector3(gx, _altura(gx, gz), gz)
			gnodo.rotation.y = lerpf(float(m0[2]), float(m1[2]), fr)
	# Rivales
	for est in _carr["rivales"]:
		if not bool(est["acabado"]):
			_seguir_ruta(est, delta)
			if bool(est["acabado"]) and float(est["t_fin"]) < 0.0:
				est["t_fin"] = t
				print("CARRERA_RIVAL_FIN t=", snappedf(t, 0.1))
	# Puntos de control del jugador
	var cps: Array = _carr["cps"]
	var cp := int(_carr["cp"])
	if _en_coche or _carr_auto:
		var dest: Vector3 = cps[cp]
		var d := Vector2(_coche.position.x - dest.x, _coche.position.z - dest.z).length()
		if d < 15.0:
			cp += 1
			_carr["cp"] = cp
			if cp >= cps.size():
				_terminar_carrera(t)
				return
			_fijar_objetivo(cps[cp])
			_sonar("ding")
			print("CARRERA_CP ", cp, "/", cps.size() - 1)
	# Banda informativa
	var puntos := cps.size() - 1
	var texto := "Carrera · CP " + str(mini(cp, puntos)) + "/" + str(puntos) + " · " + _fmt_tiempo(t)
	if String(_carr["modo"]) == "rivales":
		texto += " · vas " + str(_carr_puesto()) + "º"
	_objetivo_texto = texto

func _carr_limpiar_nodos() -> void:
	for est in _carr.get("rivales", []):
		var nd: Node = est["nodo"]
		if is_instance_valid(nd):
			nd.queue_free()
	var ghost: Dictionary = _carr.get("ghost", {})
	if not ghost.is_empty():
		var gn: Node = ghost["nodo"]
		if is_instance_valid(gn):
			gn.queue_free()

func _terminar_carrera(t: float) -> void:
	var circ: Dictionary = CIRCUITOS[int(_carr["idx"])]
	var modo := String(_carr["modo"])
	var premio := 0
	var texto := ""
	if modo == "tt":
		var medalla := ""
		if t <= float(circ["oro"]):
			medalla = "oro"
			premio = 50
		elif t <= float(circ["plata"]):
			medalla = "plata"
			premio = 30
		elif t <= float(circ["bronce"]):
			medalla = "bronce"
			premio = 15
		var id := String(circ["id"])
		var rec: Dictionary = _records.get(id, {})
		var nuevo := false
		if not rec.has("tt") or t < float(rec["tt"]):
			nuevo = true
			rec["tt"] = t
			var muestras: Array = []
			for m in _carr["grab"]:
				muestras.append([snappedf(float(m[0]), 0.1), snappedf(float(m[1]), 0.1), snappedf(float(m[2]), 0.01)])
			rec["ghost"] = muestras
			_records[id] = rec
			_guardar()
		texto = String(circ["nombre"]) + ": " + _fmt_tiempo(t) + ". "
		if medalla != "":
			texto += "¡Medalla de " + medalla + "! "
		if nuevo:
			texto += "Nuevo récord personal. "
		texto += "Premio: " + str(premio) + " €."
		print("CARRERA_FIN t=", snappedf(t, 0.1), " medalla=", medalla, " premio=", premio, " record=", nuevo)
	else:
		var antes := 0
		for est in _carr["rivales"]:
			if float(est["t_fin"]) >= 0.0 and float(est["t_fin"]) < t:
				antes += 1
		var puesto := antes + 1
		premio = int(FACTORES_PUESTO[mini(puesto - 1, 3)])
		texto = String(circ["nombre"]) + ": has quedado " + str(puesto) + "º con " + _fmt_tiempo(t) + ". Premio: " + str(premio) + " €."
		print("CARRERA_FIN t=", snappedf(t, 0.1), " puesto=", puesto, " premio=", premio)
	if premio > 0:
		_dinero += premio
		_sonar("cobro")
	_carr_limpiar_nodos()
	_carr = {}
	_carr_auto = false
	_minimapa_carrera(false)
	_pilar_destino.visible = false
	_abrir_dialogo([["Carrera", texto]], Callable())
	_actualizar_hud()

func _cancelar_carrera() -> void:
	_carr_limpiar_nodos()
	_carr = {}
	_carr_auto = false
	_minimapa_carrera(false)
	_pilar_destino.visible = false
	_aviso_set("Carrera abandonada", 4.0)
	_actualizar_hud()
	print("CARRERA_CANCELADA")

func _probar_agua() -> void:
	_preparar_rio()
	var ok := true
	var centro := _punto_en_rio(_rio_total * 0.5, 0.0)
	if not _agua_profunda(centro):
		ok = false
		print("AGUA_FALLO el centro del rio no es profundo")
	if _agua_profunda(Vector2(-75.0, -324.0)):
		ok = false
		print("AGUA_FALLO el Puente de Piedra cuenta como agua")
	var orilla := _punto_en_rio(_rio_total * 0.5, 60.0)
	if _agua_profunda(orilla):
		ok = false
		print("AGUA_FALLO la orilla cuenta como agua")
	_coche.position = Vector3(centro.x, _altura(centro.x, centro.y), centro.y)
	_coche_dir = 0.0
	_coche.rotation.y = 0.0
	_en_coche = true
	_coche_vel = 6.0
	var antes := _coche.position
	_conducir(0.1)
	if _coche_vel != 0.0 or _coche.position.distance_to(antes) > 0.05:
		ok = false
		print("AGUA_FALLO el coche anda por el agua")
	_alternar_coche()
	if _en_coche or not _nadando:
		ok = false
		print("AGUA_FALLO al salir del coche no se queda a nado")
	_jugador.position = Vector3(orilla.x, _jugador.position.y, orilla.y)
	_nadar(0.016)
	if _nadando:
		ok = false
		print("AGUA_FALLO no sale del agua al llegar a la orilla")
	print("AGUA_PRUEBA_OK pasa=", ok)
	get_tree().quit()

func _probar_nadar() -> void:
	_preparar_rio()
	var ok := true
	# El canal norte del Puente de Hierro cubre de verdad
	# (medido junto al puente, no bajo su tablero).
	if _profundidad(Vector2(-340.0, -400.0)) < 0.5:
		ok = false
		print("NADAR_FALLO profundidad del canal ", _profundidad(Vector2(-340.0, -400.0)))
	if not _agua_profunda(Vector2(-340.0, -400.0)):
		ok = false
		print("NADAR_FALLO el canal no cuenta como profundo")
	# La barra de grava del sur se vadea, no se nada.
	if _agua_profunda(Vector2(-352.0, -444.0)):
		ok = false
		print("NADAR_FALLO la barra de grava cuenta como profunda")
	# Nadando hacia el oeste se avanza, tumbado y sin salirse.
	if not _agua_profunda(Vector2(-300.0, -402.0)):
		ok = false
		print("NADAR_FALLO el punto del rio no es profundo ", _profundidad(Vector2(-300.0, -402.0)))
	_jugador.position = Vector3(-300.0, _nivel_agua(Vector2(-300.0, -402.0)) + 0.30, -402.0)
	_nadando = true
	_joy_valor = Vector2(-1, 0)
	var x0 := _jugador.position.x
	for i in 90:
		_nadar(1.0 / 30.0)
		_tiempo += 1.0 / 30.0
	_joy_valor = Vector2.ZERO
	if _jugador.position.x > x0 - 2.0:
		ok = false
		print("NADAR_FALLO no avanza ", x0, " -> ", _jugador.position.x)
	if not _nadando:
		ok = false
		print("NADAR_FALLO salio del agua en pleno canal")
	if _jugador.rotation.x < 0.7:
		ok = false
		print("NADAR_FALLO no va tumbado ", _jugador.rotation.x)
	# Al hacer pie en la barra sale andando solo.
	_jugador.position = Vector3(-352.0, _altura(-352.0, -444.0) + 0.95, -444.0)
	_nadar(1.0 / 30.0)
	if _nadando:
		ok = false
		print("NADAR_FALLO no sale al hacer pie")
	# La piscina de Las Norias tambien es agua nadable.
	_construir_tile(_tile_de(Vector2(-1167, -862)))
	if not _agua_profunda(Vector2(-1167.0, -862.0)):
		ok = false
		print("NADAR_FALLO la piscina no cuenta como agua")
	_jugador.position = Vector3(-1167.0, _nivel_agua(Vector2(-1167.0, -862.0)) + 0.30, -878.0)
	_nadando = true
	_joy_valor = Vector2(0, -1)
	var z0 := _jugador.position.z
	for i in 60:
		_nadar(1.0 / 30.0)
		_tiempo += 1.0 / 30.0
	_joy_valor = Vector2.ZERO
	if _jugador.position.z > z0 - 1.2:
		ok = false
		print("NADAR_FALLO no avanza en la piscina ", z0, " -> ", _jugador.position.z)
	if not _nadando:
		ok = false
		print("NADAR_FALLO salio de la piscina a mitad")
	# Y al pisar la playa de la piscina, andando otra vez.
	_jugador.position = Vector3(-1167.0, _altura(-1167.0, -830.0) + 0.95, -830.0)
	_nadar(1.0 / 30.0)
	if _nadando:
		ok = false
		print("NADAR_FALLO no sale al salir de la piscina")
	# Hay nadadores haciendo largos en las piscinas.
	var n_largos := 0
	for est in _estaticos:
		if String(est.get("tipo", "")) == "largos":
			n_largos += 1
	if n_largos < 4:
		ok = false
		print("NADAR_FALLO faltan nadadores de largos ", n_largos)
	if ok:
		print("NADAR_OK largos=", n_largos)

func _probar_piraguas() -> void:
	_preparar_piraguas()
	var ok := true
	if _piraguas.size() != 2:
		ok = false
		print("PIRAGUAS_FALLO n=", _piraguas.size())
	if _piragua_total < 400.0:
		ok = false
		print("PIRAGUAS_FALLO circuito corto ", _piragua_total)
	_jugador.position = Vector3(-220, _altura(-220, -380) + 0.95, -380)
	var antes: Array = []
	for pg in _piraguas:
		antes.append((pg["grupo"] as Node3D).position)
	for i in 40:
		_mover_peatones(0.1)
		_tiempo += 0.1
	for k in _piraguas.size():
		var pg: Dictionary = _piraguas[k]
		var ahora: Vector3 = (pg["grupo"] as Node3D).position
		if ahora.distance_to(antes[k]) < 0.5:
			ok = false
			print("PIRAGUAS_FALLO la piragua ", k, " no se mueve ", antes[k], " -> ", ahora)
		if ahora.x < -420.0 or ahora.x > -20.0 or _nivel_agua(Vector2(ahora.x, ahora.z)) < -100.0:
			ok = false
			print("PIRAGUAS_FALLO la piragua ", k, " fuera del rio ", ahora)
	if ok:
		print("PIRAGUAS_OK circuito=", int(_piragua_total))

func _probar_enamorados() -> void:
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			_construir_tile(_tile_de(Vector2(-2311, 100)) + Vector2i(dx, dy))
	var ok := true
	var datos := _datos_enamorados()
	if datos.is_empty() or (datos["celdas"] as Array).size() < 500:
		ok = false
		print("ENAMORADOS_FALLO sin celdas de cesped")
	if not _enamorados_hecho or _pareja_enamorados.is_empty():
		ok = false
		print("ENAMORADOS_FALLO la gente del parque no se creo")
	var sentados := 0
	var bancos: Array = datos.get("bancos", [])
	if bancos.size() > 3:
		var b3: Array = bancos[3]
		for e in _estaticos:
			if String(e["tipo"]) == "sentado" and Vector2((e["raiz"] as Node3D).position.x, (e["raiz"] as Node3D).position.z).distance_to(Vector2(float(b3[0]), float(b3[1]))) < 3.0:
				sentados += 1
	if sentados != 2:
		ok = false
		print("ENAMORADOS_FALLO sentados en el banco=", sentados)
	_jugador.position = Vector3(-2311, _altura(-2311, 103) + 0.95, 103)
	var antes_a: Vector3 = (_pareja_enamorados["a"]["raiz"] as Node3D).position
	var antes_b: Vector3 = (_pareja_enamorados["b"]["raiz"] as Node3D).position
	for i in 40:
		_mover_peatones(0.1)
		_tiempo += 0.1
	var ahora_a: Vector3 = (_pareja_enamorados["a"]["raiz"] as Node3D).position
	var ahora_b: Vector3 = (_pareja_enamorados["b"]["raiz"] as Node3D).position
	if ahora_a.distance_to(antes_a) < 0.5 or ahora_b.distance_to(antes_b) < 0.5:
		ok = false
		print("ENAMORADOS_FALLO la pareja no anda ", antes_a, " -> ", ahora_a)
	if ahora_a.x < -2420.0 or ahora_a.x > -2200.0 or ahora_a.z < 35.0 or ahora_a.z > 175.0:
		ok = false
		print("ENAMORADOS_FALLO la pareja fuera del parque ", ahora_a)
	print("ENAMORADOS_PRUEBA_OK celdas=", (datos.get("celdas", []) as Array).size(), " sentados=", sentados, " pasa=", ok)

func _probar_carreras() -> void:
	_records = {}
	_mis_coches[_coche_activo]["danio"] = 0
	var ok := true
	_iniciar_carrera(0, "tt")
	_carr_auto = true
	var frames := 0
	while not _carr.is_empty() and frames < 60000:
		await get_tree().physics_frame
		frames += 1
	if not _carr.is_empty():
		ok = false
		print("CARRERAS_FALLO la contrarreloj no termina")
	while _dlg_abierto:
		_dlg_seguir()
	var rec: Dictionary = _records.get("centro", {})
	if not rec.has("tt") or not rec.has("ghost"):
		ok = false
		print("CARRERAS_FALLO sin record guardado")
	print("CARRERAS_TT tiempo=", snappedf(float(rec.get("tt", 0.0)), 0.1))
	_iniciar_carrera(0, "rivales")
	_carr_auto = true
	var dm := _datos_minimapa()
	if not dm.has("carrera") or (dm["carrera"]["puntos"] as Array).size() < 10 or (dm["carrera"]["rivales"] as Array).size() != 3:
		ok = false
		print("CARRERAS_FALLO el plano no trae recorrido o rivales")
	var pos0: Vector2 = dm["carrera"]["yo"]
	for i in 900:
		await get_tree().physics_frame
	if not _carr.is_empty() and _datos_minimapa()["carrera"]["yo"] == pos0:
		ok = false
		print("CARRERAS_FALLO el plano no se mueve con la carrera")
	frames = 0
	while not _carr.is_empty() and frames < 60000:
		await get_tree().physics_frame
		frames += 1
	if not _carr.is_empty():
		ok = false
		print("CARRERAS_FALLO la de rivales no termina")
	while _dlg_abierto:
		_dlg_seguir()
	print("CARRERAS_PRUEBA_OK pasa=", ok)
	get_tree().quit()

func _sonar(nombre: String) -> void:
	if _banco.has(nombre):
		var pl: AudioStreamPlayer = _banco[nombre]
		if pl != null:
			pl.play()

func _musica_para(conduce: bool) -> void:
	if _son_musica == null:
		return
	var destino := _mus_coche if conduce else _mus_menu
	if destino != null and _son_musica.stream != destino:
		_son_musica.stream = destino
		_son_musica.play()

func _volumen_zona(pl: AudioStreamPlayer, objetivo: float) -> void:
	if pl != null:
		pl.volume_db = lerpf(pl.volume_db, objetivo, 0.35)

func _actualizar_ambientes() -> void:
	if _jugador == null:
		return
	var pos := _coche.position if _en_coche else _jugador.position
	var p2 := Vector2(pos.x, pos.z)
	var d_rio := 1e9
	if _rio.size() > 1:
		for i in range(_rio.size() - 1):
			var a := Vector2(float(_rio[i][0]), float(_rio[i][1]))
			var b := Vector2(float(_rio[i + 1][0]), float(_rio[i + 1][1]))
			d_rio = minf(d_rio, p2.distance_to(Geometry2D.get_closest_point_to_segment(p2, a, b)))
	_volumen_zona(_son_rio, clampf(-13.0 - maxf(0.0, d_rio - 10.0) * 0.30, -36.0, -13.0))
	var d_centro := p2.distance_to(Vector2(-160.0, 160.0))
	_volumen_zona(_son_centro, clampf(-16.0 - maxf(0.0, d_centro - 60.0) * 0.07, -38.0, -16.0))
	_volumen_zona(_son_parque, clampf(-15.0 - maxf(0.0, d_centro - 30.0) * 0.22, -38.0, -15.0))
	var alt := _altura(pos.x, pos.z)
	_volumen_zona(_son_viento, clampf(-24.0 - maxf(0.0, 18.0 - alt) * 0.5, -34.0, -22.0))

# ---------- Fase 4: mobiliario, peatones y puente ----------

func _caja_en(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray,
		centro: Vector3, tam: Vector3, color: Color, rot_y: float) -> void:
	var hx := tam.x * 0.5
	var hy := tam.y * 0.5
	var hz := tam.z * 0.5
	var cr := cos(rot_y)
	var sr := sin(rot_y)
	var loc := [
		Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz),
		Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz), Vector3(hx, hy, hz), Vector3(-hx, hy, hz)]
	var p: Array = []
	for l in loc:
		p.append(centro + Vector3(l.x * cr + l.z * sr, l.y, -l.x * sr + l.z * cr))
	var caras := [
		[4, 7, 6], [4, 6, 5], [0, 1, 2], [0, 2, 3], [3, 2, 6], [3, 6, 7],
		[1, 0, 4], [1, 4, 5], [2, 1, 5], [2, 5, 6], [0, 3, 7], [0, 7, 4]]
	for c in caras:
		_tri(verts, normals, cols, p[c[0]], p[c[1]], p[c[2]], false, color)

func _caja_guiada(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray,
		uvs: PackedVector2Array, centro: Vector3, tam: Vector3, color: Color) -> void:
	# Como _caja_en, pero dejando la UV en un texel plano: para piezas que
	# van dentro de las mallas de edificios, que sí llevan textura.
	var hx := tam.x * 0.5
	var hy := tam.y * 0.5
	var hz := tam.z * 0.5
	var p := [
		centro + Vector3(-hx, -hy, -hz), centro + Vector3(hx, -hy, -hz), centro + Vector3(hx, -hy, hz), centro + Vector3(-hx, -hy, hz),
		centro + Vector3(-hx, hy, -hz), centro + Vector3(hx, hy, -hz), centro + Vector3(hx, hy, hz), centro + Vector3(-hx, hy, hz)]
	var caras := [
		[4, 7, 6], [4, 6, 5], [0, 1, 2], [0, 2, 3], [3, 2, 6], [3, 6, 7],
		[1, 0, 4], [1, 4, 5], [2, 1, 5], [2, 5, 6], [0, 3, 7], [0, 7, 4]]
	var uv_c := PackedVector2Array([Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)])
	for c in caras:
		_tri(verts, normals, cols, p[c[0]], p[c[1]], p[c[2]], false, color, uvs, uv_c)

func _caja_dir_guiada(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray,
		uvs: PackedVector2Array, centro: Vector3, tam: Vector3, color: Color, rot_y: float) -> void:
	# Como _caja_en (admite giro), pero dejando la UV en un texel plano:
	# para piezas que van dentro de las mallas de edificios con textura.
	var hx := tam.x * 0.5
	var hy := tam.y * 0.5
	var hz := tam.z * 0.5
	var cr := cos(rot_y)
	var sr := sin(rot_y)
	var loc := [
		Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz),
		Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz), Vector3(hx, hy, hz), Vector3(-hx, hy, hz)]
	var p: Array = []
	for l in loc:
		p.append(centro + Vector3(l.x * cr + l.z * sr, l.y, -l.x * sr + l.z * cr))
	var caras := [
		[4, 7, 6], [4, 6, 5], [0, 1, 2], [0, 2, 3], [3, 2, 6], [3, 6, 7],
		[1, 0, 4], [1, 4, 5], [2, 1, 5], [2, 5, 6], [0, 3, 7], [0, 7, 4]]
	var uv_c := PackedVector2Array([Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)])
	for c in caras:
		_tri(verts, normals, cols, p[c[0]], p[c[1]], p[c[2]], false, color, uvs, uv_c)

func _crear_mobiliario() -> void:
	var datos_c = JSON.parse_string(FileAccess.get_file_as_string("res://datos/calles.json"))
	if datos_c == null:
		return
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var n_farolas := 0
	var n_lineas := 0
	var n_papeleras := 0
	var col_poste := Color(0.16, 0.17, 0.19)
	var col_luz := Color(1.0, 0.86, 0.58)
	var col_linea := Color(0.88, 0.88, 0.85)
	var col_papelera := Color(0.15, 0.29, 0.17)
	for seg in datos_c["calles"]:
		var clase := String(seg["clase"])
		var ancho := float(seg["ancho"])
		var pts: Array = seg["puntos"]
		var con_farolas := clase in ["primary", "secondary", "tertiary", "residential", "unclassified"] and ancho >= 6.0
		var con_linea := clase in ["primary", "secondary", "tertiary"] and ancho >= 9.0
		if not con_farolas and not con_linea:
			continue
		for i in range(pts.size() - 1):
			var a := Vector2(float(pts[i][0]), float(pts[i][1]))
			var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			var largo := a.distance_to(b)
			if largo < 1.0:
				continue
			var dir := (b - a) / largo
			var perp := Vector2(-dir.y, dir.x)
			if con_linea:
				var d := 3.0
				while d < largo - 1.0:
					var pc := a + dir * d
					_caja_en(verts, normals, cols, Vector3(pc.x, _altura(pc.x, pc.y) + 0.06, pc.y), Vector3(0.18, 0.03, 2.2), col_linea, atan2(dir.x, dir.y))
					n_lineas += 1
					d += 6.0
			if con_farolas:
				var d2 := 15.0
				var lado := 1.0
				while d2 < largo:
					if _rng.randf() > 0.30:
						var pl := a + dir * d2 + perp * (lado * (ancho * 0.5 - 0.55))
						if not _choca(Vector2(pl.x, pl.y), 0.3):
							var yl := _altura(pl.x, pl.y)
							_caja_en(verts, normals, cols, Vector3(pl.x, yl + 2.3, pl.y), Vector3(0.13, 4.6, 0.13), col_poste, 0.0)
							_caja_en(verts, normals, cols, Vector3(pl.x, yl + 4.68, pl.y), Vector3(0.52, 0.14, 0.30), col_luz, atan2(dir.x, dir.y))
							n_farolas += 1
							if n_farolas % 4 == 0:
								var pp := pl + perp * (-lado * 0.7)
								_caja_en(verts, normals, cols, Vector3(pp.x, _altura(pp.x, pp.y) + 0.38, pp.y), Vector3(0.5, 0.76, 0.5), col_papelera, 0.0)
								n_papeleras += 1
					lado = -lado
					d2 += 30.0
	var n_bancos := 0
	var col_madera := Color(0.45, 0.31, 0.17)
	var col_hierro := Color(0.13, 0.13, 0.14)
	for poi in _pois_mapa:
		if absf(float(poi["x"])) > 900.0 or absf(float(poi["z"])) > 620.0:
			continue
		for k in 2:
			var ang := _rng.randf() * TAU
			var bp := Vector2(float(poi["x"]), float(poi["z"])) + Vector2(cos(ang), sin(ang)) * (3.0 + _rng.randf() * 2.0)
			if _choca(bp, 0.9):
				continue
			var yb := _altura(bp.x, bp.y)
			var rot := _rng.randf() * TAU
			var lat := Vector3(cos(rot), 0, -sin(rot))
			var detras := Vector3(-sin(rot), 0, -cos(rot))
			var cen := Vector3(bp.x, yb, bp.y)
			_caja_en(verts, normals, cols, cen + Vector3(0, 0.46, 0), Vector3(1.8, 0.10, 0.5), col_madera, rot)
			_caja_en(verts, normals, cols, cen + detras * 0.22 + Vector3(0, 0.78, 0), Vector3(1.8, 0.5, 0.09), col_madera, rot)
			_caja_en(verts, normals, cols, cen + lat * 0.7 + Vector3(0, 0.22, 0), Vector3(0.08, 0.44, 0.42), col_hierro, rot)
			_caja_en(verts, normals, cols, cen - lat * 0.7 + Vector3(0, 0.22, 0), Vector3(0.08, 0.44, 0.42), col_hierro, rot)
			_asientos.append({"pos": cen, "rot": rot})
			_registrar_solido(cen.x, cen.z, rot, 0.32, 0.95)
			n_bancos += 1
	var n_marq := 0
	var nombres_m := ["Ayuntamiento", "Teatro", "Mercado", "Redonda", "Biblioteca", "Espolón"]
	for poi in _pois_mapa:
		var nom := String(poi["n"])
		var vale := false
		for nm in nombres_m:
			if nom.contains(nm):
				vale = true
		if not vale:
			continue
		var ang2 := _rng.randf() * TAU
		var mp := Vector2(float(poi["x"]), float(poi["z"])) + Vector2(cos(ang2), sin(ang2)) * 6.0
		if _choca(mp, 1.3):
			continue
		var ym := _altura(mp.x, mp.y)
		var rotm := _rng.randf() * TAU
		var latm := Vector3(cos(rotm), 0, -sin(rotm))
		var detm := Vector3(-sin(rotm), 0, -cos(rotm))
		var cenm := Vector3(mp.x, ym, mp.y)
		_caja_en(verts, normals, cols, cenm + latm * 1.2 + Vector3(0, 1.15, 0), Vector3(0.09, 2.3, 0.09), col_hierro, rotm)
		_caja_en(verts, normals, cols, cenm - latm * 1.2 + Vector3(0, 1.15, 0), Vector3(0.09, 2.3, 0.09), col_hierro, rotm)
		_caja_en(verts, normals, cols, cenm + Vector3(0, 2.35, 0), Vector3(2.8, 0.1, 1.3), Color(0.20, 0.22, 0.25), rotm)
		_caja_en(verts, normals, cols, cenm + detm * 0.6 + Vector3(0, 1.15, 0), Vector3(2.8, 1.05, 0.05), Color(0.55, 0.65, 0.70), rotm)
		_caja_en(verts, normals, cols, cenm + Vector3(0, 0.55, 0), Vector3(2.3, 0.08, 0.4), col_madera, rotm)
		n_marq += 1
	add_child(_malla_de(verts, normals, cols, Color.WHITE))
	print("MOBILIARIO_OK farolas=", n_farolas, " papeleras=", n_papeleras, " lineas=", n_lineas, " bancos=", n_bancos, " marquesinas=", n_marq)

func _hacer_paloma() -> Node3D:
	# Una paloma en una sola malla fundida: cuerpo gris, cabeza con el
	# cuello verdoso, cola plana y patitas rojas.
	var r := Node3D.new()
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var gris := Color(0.56, 0.56, 0.60)
	_caja_en(v, n, c, Vector3(0, 0.11, 0), Vector3(0.15, 0.12, 0.23), gris, 0.0)
	_caja_en(v, n, c, Vector3(0, 0.115, 0.07), Vector3(0.08, 0.09, 0.08), Color(0.30, 0.45, 0.42), 0.0)
	_bola_en(v, n, c, Vector3(0, 0.185, 0.115), 0.052, Color(0.32, 0.36, 0.40), 3.7)
	_caja_en(v, n, c, Vector3(0, 0.145, -0.155), Vector3(0.11, 0.02, 0.13), gris.darkened(0.15), 0.0)
	_caja_en(v, n, c, Vector3(-0.03, 0.03, 0.01), Vector3(0.018, 0.06, 0.018), Color(0.75, 0.35, 0.25), 0.0)
	_caja_en(v, n, c, Vector3(0.03, 0.03, 0.01), Vector3(0.018, 0.06, 0.018), Color(0.75, 0.35, 0.25), 0.0)
	r.add_child(_malla_de(v, n, c, Color.WHITE))
	return r

func _crear_escena_palomas() -> void:
	# El anciano del Espolón: sentado en su banco echando migas a las
	# palomas (petición de Jon: «más palomas en el Espolón y algún
	# anciano dándoles de comer»).
	var centro := _poi_nom("Paseo del Espolón")
	if centro == Vector3.ZERO:
		centro = Vector3(-259, 0, 271)
	var base := _punto_libre(centro + Vector3(4.0, 0, -12.0), 0.4)
	_anciano_pos = base
	var hacia_c := Vector2(centro.x - base.x, centro.z - base.z).normalized()
	var rot_a := atan2(hacia_c.x, hacia_c.y)
	var yb := _altura(base.x, base.z)
	# Su banco, fundido en una malla
	var bv := PackedVector3Array()
	var bn := PackedVector3Array()
	var bc := PackedColorArray()
	var madera := Color(0.42, 0.33, 0.22)
	var hierro := Color(0.16, 0.16, 0.18)
	var eje := Vector2(cos(rot_a), -sin(rot_a))
	_caja_en(bv, bn, bc, Vector3(base.x, yb + 0.46, base.z), Vector3(1.9, 0.09, 0.52), madera, rot_a)
	_caja_en(bv, bn, bc, Vector3(base.x - hacia_c.x * 0.26, yb + 0.84, base.z - hacia_c.y * 0.26), Vector3(1.9, 0.55, 0.07), madera, rot_a)
	_caja_en(bv, bn, bc, Vector3(base.x - eje.x * 0.8, yb + 0.23, base.z - eje.y * 0.8), Vector3(0.09, 0.46, 0.46), hierro, rot_a)
	_caja_en(bv, bn, bc, Vector3(base.x + eje.x * 0.8, yb + 0.23, base.z + eje.y * 0.8), Vector3(0.09, 0.46, 0.46), hierro, rot_a)
	add_child(_malla_de(bv, bn, bc, Color.WHITE))
	# El anciano: pelo blanco, abrigo oscuro, la mano de echar migas baja
	var per := _hacer_persona(Color(0.23, 0.22, 0.26), Color(0.30, 0.27, 0.24), Color(0.86, 0.85, 0.82))
	var raiz: Node3D = per["raiz"]
	raiz.position = Vector3(base.x, yb + 0.52, base.z)
	raiz.rotation.y = rot_a
	add_child(raiz)
	(per["pi"] as Node3D).rotation.x = -1.25
	(per["pd"] as Node3D).rotation.x = -1.25
	(per["bd"] as Node3D).rotation.x = -0.55
	_estaticos.append({"d": per, "raiz": raiz, "tipo": "sentado", "fase": 1.3})
	# La bandada: doce palomas alrededor de sus pies
	var perp := Vector2(-hacia_c.y, hacia_c.x)
	for j in 12:
		var pal := _hacer_paloma()
		var frente := 1.1 + _rng.randf() * 1.6
		var lado := (_rng.randf() - 0.5) * 4.4
		var casa := base + Vector3(hacia_c.x * frente + perp.x * lado, 0, hacia_c.y * frente + perp.y * lado)
		casa = _punto_libre(casa, 0.15)
		pal.position = Vector3(casa.x, _altura(casa.x, casa.z), casa.z)
		pal.rotation.y = _rng.randf() * TAU
		add_child(pal)
		_palomas.append({"raiz": pal, "casa": casa, "fase": _rng.randf() * 6.0, "vuelo": 0.0, "ang": _rng.randf() * TAU, "radio": 10.0 + _rng.randf() * 9.0, "alto": 7.0 + _rng.randf() * 4.0, "centro": Vector2(centro.x, centro.z)})
	print("PALOMAS_OK n=", _palomas.size(), " anciano=", base)

func _mover_palomas(delta: float) -> void:
	if _palomas.is_empty() or _jugador == null:
		return
	var d_jug := Vector2(_jugador.position.x, _jugador.position.z).distance_to(Vector2(_anciano_pos.x, _anciano_pos.z))
	for pal in _palomas:
		var raiz: Node3D = pal["raiz"]
		pal["fase"] = float(pal["fase"]) + delta
		if float(pal["vuelo"]) > 0.0:
			# Volando en círculo sobre el Espolón, con banqueo
			pal["vuelo"] = float(pal["vuelo"]) - delta
			pal["ang"] = float(pal["ang"]) + delta * 0.55
			var ang := float(pal["ang"])
			var cen: Vector2 = pal["centro"]
			var nx := cen.x + cos(ang) * float(pal["radio"])
			var nz := cen.y + sin(ang) * float(pal["radio"])
			var ny := _altura(nx, nz) + float(pal["alto"]) + sin(float(pal["fase"]) * 3.0) * 0.4
			raiz.position = raiz.position.lerp(Vector3(nx, ny, nz), clampf(delta * 2.5, 0.0, 1.0))
			raiz.rotation.y = atan2(-sin(ang), cos(ang))
			raiz.rotation.z = 0.35
			raiz.rotation.x = 0.0
		else:
			# En el suelo: picotear las migas junto al anciano
			var casa: Vector3 = pal["casa"]
			var gy := _altura(casa.x, casa.z)
			raiz.position = raiz.position.lerp(Vector3(casa.x, gy, casa.z), clampf(delta * 3.0, 0.0, 1.0))
			raiz.rotation.z = 0.0
			var picoteo := 0.0
			if fmod(float(pal["fase"]), 3.0) < 1.6:
				picoteo = maxf(0.0, sin(float(pal["fase"]) * 2.2)) * 0.38
			raiz.rotation.x = picoteo
			if d_jug < 4.5 and not _en_coche:
				# Te acercas andando: la bandada echa a volar
				pal["vuelo"] = 5.0 + _rng.randf() * 4.0
				pal["ang"] = atan2(raiz.position.z - float(pal["centro"].y), raiz.position.x - float(pal["centro"].x))
			elif _rng.randf() < delta * 0.008:
				pal["vuelo"] = 4.0 + _rng.randf() * 3.0
				pal["ang"] = atan2(raiz.position.z - float(pal["centro"].y), raiz.position.x - float(pal["centro"].x))

func _crear_peatones() -> void:
	var camisas := [Color(0.75, 0.30, 0.25), Color(0.20, 0.55, 0.35), Color(0.85, 0.65, 0.20), Color(0.50, 0.30, 0.60), Color(0.90, 0.90, 0.88), Color(0.25, 0.25, 0.28), Color(0.80, 0.45, 0.60), Color(0.30, 0.50, 0.75)]
	var pelos := [Color(0.25, 0.17, 0.12), Color(0.10, 0.08, 0.06), Color(0.55, 0.40, 0.25), Color(0.75, 0.72, 0.68)]
	# Más gente en la calle (Jon: «no quiero una ciudad desierta» y
	# luego «quiero mucha más gente»): 78 paseantes, con el grueso en
	# el centro vivo (Espolón, Portales, Gran Vía), una capa por los
	# barrios y el resto repartido por el casco.
	for k in 78:
		var lim_x := 650.0
		var lim_z := 480.0
		if k % 5 < 3:
			lim_x = 430.0
			lim_z = 340.0
		elif k % 5 == 4:
			lim_x = 1150.0
			lim_z = 880.0
		var nodo := -1
		for intento in 60:
			var cand := _rng.randi() % _nodos.size()
			var np: Vector2 = _nodos[cand]
			var vale := absf(np.x) <= lim_x and absf(np.y) <= lim_z and _ady.has(cand) and not (_ady[cand] as Array).is_empty()
			if k >= 68:
				vale = vale and _es_pinchos(np)
			if vale:
				nodo = cand
				break
		if nodo < 0:
			continue
		# Cada paseante con lo suyo (E5): sexo, piel, talla,
		# complexión, pelo y pantalón de paleta, falda a veces.
		var fem_k := _rng.randf() < 0.5
		var estilos_k: Array = ["melena", "coleta", "mono", "corto"] if fem_k else ["corto", "corto", "calvo", "mono"]
		var opc_k := {
			"piel": [Color(0.93, 0.74, 0.60), Color(0.88, 0.64, 0.47), Color(0.96, 0.80, 0.66), Color(0.72, 0.50, 0.36), Color(0.58, 0.40, 0.28), Color(0.84, 0.60, 0.44)][_rng.randi() % 6],
			"talla": 0.93 + _rng.randf() * 0.12,
			"complexion": 0.94 + _rng.randf() * 0.12,
			"pelo_estilo": estilos_k[_rng.randi() % estilos_k.size()],
			"falda": fem_k and _rng.randf() < 0.35,
		}
		var persona := _hacer_persona(camisas[_rng.randi() % camisas.size()], [Color(0.16, 0.22, 0.38), Color(0.10, 0.10, 0.12), Color(0.35, 0.33, 0.30), Color(0.42, 0.36, 0.26), Color(0.20, 0.26, 0.20), Color(0.30, 0.20, 0.16), Color(0.55, 0.52, 0.48)][_rng.randi() % 7], pelos[_rng.randi() % pelos.size()], false, fem_k, opc_k)
		var raiz: Node3D = persona["raiz"]
		var np2: Vector2 = _nodos[nodo]
		raiz.position = Vector3(np2.x, _altura(np2.x, np2.y) + 0.95, np2.y)
		add_child(raiz)
		var vecinos: Array = _ady[nodo]
		var sig: int = vecinos[_rng.randi() % vecinos.size()][0]
		var dp: Vector2 = _nodos[sig]
		_peatones.append({"d": persona, "raiz": raiz, "nodo": sig, "destino": Vector3(dp.x, 0, dp.y), "fase": _rng.randf() * 6.0, "vel": 1.15 + _rng.randf() * 0.5})
	_crear_vida_calle(camisas, pelos)
	_crear_escena_palomas()
	print("PEATONES_OK n=", _peatones.size() + _estaticos.size(), " comportamientos=", _estaticos.size(), " perros=", _perros.size(), " pajaros=", _pajaros.size())

func _persona_gal(base: Vector3, desf: Vector2, camisa: Color, pelo: Color, fem: bool, escala: float) -> Dictionary:
	var per := _hacer_persona(camisa, Color(0.22, 0.23, 0.28), pelo, false, fem, {
		"piel": [Color(0.93, 0.74, 0.60), Color(0.88, 0.64, 0.47), Color(0.96, 0.80, 0.66)][_rng.randi() % 3],
		"pelo_estilo": ("coleta" if _rng.randf() < 0.5 else "melena") if fem else "corto",
		"falda": fem and escala > 0.9,
	})
	var rz: Node3D = per["raiz"]
	var sitio := _punto_libre(base + Vector3(desf.x, 0, desf.y), 0.4)
	rz.scale = Vector3.ONE * escala
	rz.position = Vector3(sitio.x, _altura(sitio.x, sitio.z) + 0.95 * escala, sitio.z)
	add_child(rz)
	return per

func _parque_gallarza() -> void:
	# Parque González Gallarza vivo (pedido de Jon): zona verde de
	# verdad, columpios con niños, abuelos cuidando y balón.
	var centro_parque := Vector3(-486, 0, 736)
	# Rejilla de nodos del grafo: para no pintar verde sobre los
	# caminos del parque ni pegarlo a las calles.
	var rej_nodos := {}
	for nd in _nodos:
		var cl := Vector2i(int(floor(nd.x / 8.0)), int(floor(nd.y / 8.0)))
		if not rej_nodos.has(cl):
			rej_nodos[cl] = []
		(rej_nodos[cl] as Array).append(nd)
	var cerca_camino := func(p: Vector2, dist: float) -> bool:
		var cl := Vector2i(int(floor(p.x / 8.0)), int(floor(p.y / 8.0)))
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				for nd in (rej_nodos.get(Vector2i(cl.x + dx, cl.y + dz), []) as Array):
					if (nd as Vector2).distance_to(p) < dist:
						return true
		return false
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var verdes := [Color(0.16, 0.42, 0.16), Color(0.19, 0.47, 0.19), Color(0.14, 0.38, 0.14)]
	var nverde := 0
	for gx in range(-546, -426, 4):
		for gz in range(678, 794, 4):
			var pc := Vector2(gx + 2.0, gz + 2.0)
			if _choca(pc, 1.0) or cerca_camino.call(pc, 2.3):
				continue
			var y := _altura(pc.x, pc.y)
			_caja_en(v, n, c, Vector3(pc.x, y + 0.02, pc.y), Vector3(4.06, 0.1, 4.06), verdes[(gx / 4 + gz / 4) % 3], 0.0)
			nverde += 1
	_gallarza_verde = nverde
	# Árboles del parque
	var narb := 0
	var intentos := 0
	while narb < 14 and intentos < 90:
		intentos += 1
		var tp := Vector2(-540.0 + _rng.randf() * 108.0, 684.0 + _rng.randf() * 104.0)
		if _choca(tp, 1.2) or cerca_camino.call(tp, 3.0):
			continue
		if tp.distance_to(Vector2(-512.7, 716.3)) < 6.5 or tp.distance_to(Vector2(-469.5, 730.0)) < 5.0:
			continue
		var ty := _altura(tp.x, tp.y)
		_caja_en(v, n, c, Vector3(tp.x, ty + 0.85, tp.y), Vector3(0.28, 1.7, 0.28), Color(0.36, 0.26, 0.17), 0.0)
		_caja_en(v, n, c, Vector3(tp.x, ty + 2.15, tp.y), Vector3(2.3, 1.1, 2.3), Color(0.13, 0.36, 0.13), 0.0)
		_caja_en(v, n, c, Vector3(tp.x, ty + 2.85, tp.y), Vector3(1.6, 0.8, 1.6), Color(0.16, 0.42, 0.16), 0.0)
		narb += 1
	# Banco frente a los columpios y estructura de los columpios
	var yb := _altura(-512.7, 721.8)
	_caja_en(v, n, c, Vector3(-512.7, yb + 0.24, 721.8), Vector3(2.2, 0.10, 0.55), Color(0.42, 0.30, 0.19), 0.0)
	_caja_en(v, n, c, Vector3(-512.7, yb + 0.62, 722.12), Vector3(2.2, 0.55, 0.09), Color(0.42, 0.30, 0.19), 0.0)
	for bx in [-1.0, 1.0]:
		_caja_en(v, n, c, Vector3(-512.7 + bx, yb + 0.12, 721.8), Vector3(0.09, 0.24, 0.5), Color(0.25, 0.25, 0.28), 0.0)
	var ys := _altura(-512.7, 716.3)
	var metal := Color(0.38, 0.40, 0.44)
	for sx in [-1.8, 1.8]:
		for sz in [-0.5, 0.5]:
			_caja_en(v, n, c, Vector3(-512.7 + sx, ys + 1.1, 716.3 + sz), Vector3(0.11, 2.2, 0.11), metal, 0.0)
		_caja_en(v, n, c, Vector3(-512.7 + sx, ys + 2.24, 716.3), Vector3(0.11, 0.11, 1.1), metal, 0.0)
	_caja_en(v, n, c, Vector3(-512.7, ys + 2.26, 716.3), Vector3(3.8, 0.13, 0.13), Color(0.75, 0.22, 0.18), 0.0)
	add_child(_malla_de(v, n, c, Color.WHITE))
	_registrar_rect(centro_parque, Vector2(-512.7 + 486.0, 721.8 - 736.0), Vector2(2.2, 0.6))
	_registrar_rect(centro_parque, Vector2(-512.7 + 486.0, 716.3 - 736.0), Vector2(3.9, 1.1))
	# Los dos columpios: pivotes en la barra, uno con niño
	var gris_cadena := Color(0.55, 0.56, 0.60)
	for i in 2:
		var piv := Node3D.new()
		piv.position = Vector3(-513.6 + i * 1.8, ys + 2.2, 716.3)
		for cx in [-0.20, 0.20]:
			piv.add_child(_pieza(Vector3(0.045, 1.45, 0.045), Vector3(cx, -0.72, 0), gris_cadena))
		piv.add_child(_pieza(Vector3(0.48, 0.05, 0.26), Vector3(0, -1.46, 0), Color(0.20, 0.22, 0.26)))
		add_child(piv)
		if i == 0:
			var nin := _hacer_persona(Color(0.85, 0.35, 0.20), Color(0.20, 0.24, 0.40), Color(0.15, 0.10, 0.07))
			var rz: Node3D = nin["raiz"]
			rz.scale = Vector3.ONE * 0.62
			rz.position = Vector3(0, -1.40, 0.03)
			(nin["pi"] as Node3D).rotation.x = -1.30
			(nin["pd"] as Node3D).rotation.x = -1.30
			(nin["bi"] as Node3D).rotation.x = -2.65
			(nin["bd"] as Node3D).rotation.x = -2.65
			piv.add_child(rz)
			_columpios.append({"pivote": piv, "d": nin, "fase": 0.0, "amp": 0.48})
		else:
			_columpios.append({"pivote": piv, "d": {}, "fase": 2.1, "amp": 0.16})
	# Niño esperando su turno junto a los columpios
	var esp := _persona_gal(Vector3(-510.2, 0, 718.8), Vector2.ZERO, Color(0.25, 0.55, 0.80), Color(0.30, 0.20, 0.12), false, 0.62)
	(esp["raiz"] as Node3D).rotation.y = -PI / 2.0
	_estaticos.append({"d": esp, "raiz": esp["raiz"], "tipo": "espera", "fase": _rng.randf() * 6.0})
	# Abuelos en el banco, mirando a los columpios
	var pelo_canas := Color(0.85, 0.84, 0.80)
	var abuelo := _persona_gal(Vector3(-513.2, 0, 721.8), Vector2.ZERO, Color(0.35, 0.32, 0.28), pelo_canas, false, 1.0)
	var abuela := _persona_gal(Vector3(-512.2, 0, 721.8), Vector2.ZERO, Color(0.55, 0.35, 0.45), pelo_canas, true, 1.0)
	for ab in [abuelo, abuela]:
		var rz2: Node3D = ab["raiz"]
		rz2.position.y = _altura(rz2.position.x, rz2.position.z) + 0.52
		rz2.rotation.y = PI
		(ab["pi"] as Node3D).rotation.x = -1.25
		(ab["pd"] as Node3D).rotation.x = -1.25
		_estaticos.append({"d": ab, "raiz": rz2, "tipo": "sentado", "fase": _rng.randf() * 6.0})
	# Un abuelo de pie charlando con su nieto
	var ab2 := _persona_gal(Vector3(-503.6, 0, 724.6), Vector2.ZERO, Color(0.30, 0.38, 0.30), pelo_canas, false, 1.0)
	var ni2 := _persona_gal(Vector3(-502.3, 0, 724.9), Vector2.ZERO, Color(0.90, 0.70, 0.20), Color(0.20, 0.13, 0.08), false, 0.62)
	var ra2: Node3D = ab2["raiz"]
	var rn2: Node3D = ni2["raiz"]
	ra2.rotation.y = atan2(rn2.position.x - ra2.position.x, rn2.position.z - ra2.position.z)
	rn2.rotation.y = atan2(ra2.position.x - rn2.position.x, ra2.position.z - rn2.position.z)
	_estaticos.append({"d": ab2, "raiz": ra2, "tipo": "hablar", "fase": _rng.randf() * 6.0})
	_estaticos.append({"d": ni2, "raiz": rn2, "tipo": "hablar", "fase": _rng.randf() * 6.0})
	# Dos niños pasándose el balón en el verde
	var nA := _persona_gal(Vector3(-473.0, 0, 730.0), Vector2.ZERO, Color(0.20, 0.65, 0.35), Color(0.12, 0.09, 0.06), false, 0.62)
	var nB := _persona_gal(Vector3(-466.5, 0, 730.6), Vector2.ZERO, Color(0.85, 0.55, 0.15), Color(0.35, 0.22, 0.12), false, 0.62)
	var rA: Node3D = nA["raiz"]
	var rB: Node3D = nB["raiz"]
	rA.rotation.y = atan2(rB.position.x - rA.position.x, rB.position.z - rA.position.z)
	rB.rotation.y = atan2(rA.position.x - rB.position.x, rA.position.z - rB.position.z)
	_estaticos.append({"d": nA, "raiz": rA, "tipo": "hablar", "fase": _rng.randf() * 6.0})
	_estaticos.append({"d": nB, "raiz": rB, "tipo": "hablar", "fase": _rng.randf() * 6.0})
	var balon := MeshInstance3D.new()
	var esf := SphereMesh.new()
	esf.radius = 0.17
	esf.height = 0.34
	balon.mesh = esf
	var mat_b := StandardMaterial3D.new()
	mat_b.albedo_color = Color(0.93, 0.93, 0.93)
	esf.material = mat_b
	add_child(balon)
	var pa := Vector3(rA.position.x, 0, rA.position.z) + (Vector3(rB.position.x, 0, rB.position.z) - Vector3(rA.position.x, 0, rA.position.z)).normalized() * 0.55
	var pb := Vector3(rB.position.x, 0, rB.position.z) + (Vector3(rA.position.x, 0, rA.position.z) - Vector3(rB.position.x, 0, rB.position.z)).normalized() * 0.55
	_balon_gal = {"nodo": balon, "a": pa, "b": pb, "t": 0.0, "y": _altura(-469.5, 730.3), "da": nA, "db": nB, "flick": 0.0}
	print("GALLARZA_OK verde=", nverde, " arboles=", narb, " columpios=", _columpios.size(), " ninos=5 abuelos=3")

func _poi_nom(nombre: String) -> Vector3:
	for poi in _pois:
		if String(poi["n"]) == nombre:
			return Vector3(float(poi["x"]), 0, float(poi["z"]))
	return Vector3.ZERO

func _persona_en(base: Vector3, desf: Vector2, camisa: Color, pelo: Color) -> Dictionary:
	var fem_e := _rng.randf() < 0.5
	var estilos_e: Array = ["melena", "coleta", "mono", "corto"] if fem_e else ["corto", "corto", "calvo", "mono"]
	var persona := _hacer_persona(camisa, Color(0.22, 0.23, 0.28), pelo, false, fem_e, {
		"piel": [Color(0.93, 0.74, 0.60), Color(0.88, 0.64, 0.47), Color(0.72, 0.50, 0.36), Color(0.84, 0.60, 0.44)][_rng.randi() % 4],
		"talla": 0.94 + _rng.randf() * 0.10,
		"complexion": 0.95 + _rng.randf() * 0.10,
		"pelo_estilo": estilos_e[_rng.randi() % estilos_e.size()],
		"falda": fem_e and _rng.randf() < 0.3,
	})
	var raiz: Node3D = persona["raiz"]
	var sitio := _punto_libre(base + Vector3(desf.x, 0, desf.y), 0.4)
	raiz.position = Vector3(sitio.x, _altura(sitio.x, sitio.z) + 0.95, sitio.z)
	add_child(raiz)
	return persona

func _crear_vida_calle(camisas: Array, pelos: Array) -> void:
	var k := 0
	# Sentados: dos en el Espolón y uno en la Redonda
	for datos_s in [["Paseo del Espolón", Vector2(2.5, 1.0)], ["Paseo del Espolón", Vector2(-3.0, 2.0)], ["Plaza de la Redonda", Vector2(1.5, -1.0)]]:
		var per := _persona_en(_poi_nom(String(datos_s[0])), datos_s[1], camisas[k % camisas.size()], pelos[k % pelos.size()])
		k += 1
		var raiz_s: Node3D = per["raiz"]
		raiz_s.position.y = _altura(raiz_s.position.x, raiz_s.position.z) + 0.52
		raiz_s.rotation.y = _rng.randf() * TAU
		(per["pi"] as Node3D).rotation.x = -1.25
		(per["pd"] as Node3D).rotation.x = -1.25
		_estaticos.append({"d": per, "raiz": raiz_s, "tipo": "sentado", "fase": _rng.randf() * 6.0})
	# Mirando el móvil: Ayuntamiento y Mercado de San Blas
	for nombre_m in ["Ayuntamiento de Logroño", "Plaza de Abastos - Mercado de San Blas"]:
		var per2 := _persona_en(_poi_nom(nombre_m), Vector2(1.0, 2.5), camisas[k % camisas.size()], pelos[k % pelos.size()])
		k += 1
		(per2["bd"] as Node3D).rotation.x = -0.95
		_estaticos.append({"d": per2, "raiz": per2["raiz"], "tipo": "movil", "fase": _rng.randf() * 6.0})
	# Parejas hablando: Espolón y Teatro Bretón
	for nombre_p in ["Paseo del Espolón", "Teatro Bretón de los Herreros"]:
		var base_p := _poi_nom(nombre_p)
		var dir_p := Vector2(1, 0.4).normalized()
		var perA := _persona_en(base_p, dir_p * 0.7 + Vector2(4.0, 3.0), camisas[k % camisas.size()], pelos[k % pelos.size()])
		k += 1
		var perB := _persona_en(base_p, -dir_p * 0.7 + Vector2(4.0, 3.0), camisas[k % camisas.size()], pelos[k % pelos.size()])
		k += 1
		var ra: Node3D = perA["raiz"]
		var rb: Node3D = perB["raiz"]
		ra.rotation.y = atan2(rb.position.x - ra.position.x, rb.position.z - ra.position.z)
		rb.rotation.y = atan2(ra.position.x - rb.position.x, ra.position.z - rb.position.z)
		_estaticos.append({"d": perA, "raiz": ra, "tipo": "hablar", "fase": _rng.randf() * 6.0})
		_estaticos.append({"d": perB, "raiz": rb, "tipo": "hablar", "fase": _rng.randf() * 6.0})
	# Ambiente de pinchos: tres parejas charlando en plena
	# callejuela (Laurel, San Juan y San Agustín).
	for base_z in [Vector2(-460, 170.5), Vector2(-160, 131.5), Vector2(-500, 123.5)]:
		var dir_z := Vector2(0.8, 0.6).normalized()
		var perC := _persona_en(Vector3(base_z.x, 0, base_z.y), dir_z * 0.7, camisas[k % camisas.size()], pelos[k % pelos.size()])
		k += 1
		var perD := _persona_en(Vector3(base_z.x, 0, base_z.y), -dir_z * 0.7, camisas[k % camisas.size()], pelos[k % pelos.size()])
		k += 1
		var rc: Node3D = perC["raiz"]
		var rd: Node3D = perD["raiz"]
		rc.rotation.y = atan2(rd.position.x - rc.position.x, rd.position.z - rc.position.z)
		rd.rotation.y = atan2(rc.position.x - rd.position.x, rc.position.z - rd.position.z)
		_estaticos.append({"d": perC, "raiz": rc, "tipo": "hablar", "fase": _rng.randf() * 6.0})
		_estaticos.append({"d": perD, "raiz": rd, "tipo": "hablar", "fase": _rng.randf() * 6.0})
	# Más vida quieta: sentados y una pareja en el Parque del Ebro
	for datos_e in [[Vector2(3.0, 1.0)], [Vector2(-2.0, 3.0)]]:
		var per_e := _persona_en(_poi_nom("Parque del Ebro"), datos_e[0], camisas[k % camisas.size()], pelos[k % pelos.size()])
		k += 1
		var raiz_e2: Node3D = per_e["raiz"]
		raiz_e2.position.y = _altura(raiz_e2.position.x, raiz_e2.position.z) + 0.52
		raiz_e2.rotation.y = _rng.randf() * TAU
		(per_e["pi"] as Node3D).rotation.x = -1.25
		(per_e["pd"] as Node3D).rotation.x = -1.25
		_estaticos.append({"d": per_e, "raiz": raiz_e2, "tipo": "sentado", "fase": _rng.randf() * 6.0})
	var base_e := _poi_nom("Parque del Ebro")
	var per_e1 := _persona_en(base_e, Vector2(6.0, -2.0), camisas[k % camisas.size()], pelos[k % pelos.size()])
	k += 1
	var per_e2 := _persona_en(base_e, Vector2(7.4, -1.6), camisas[k % camisas.size()], pelos[k % pelos.size()])
	k += 1
	var re1: Node3D = per_e1["raiz"]
	var re2: Node3D = per_e2["raiz"]
	re1.rotation.y = atan2(re2.position.x - re1.position.x, re2.position.z - re1.position.z)
	re2.rotation.y = atan2(re1.position.x - re2.position.x, re1.position.z - re2.position.z)
	_estaticos.append({"d": per_e1, "raiz": re1, "tipo": "hablar", "fase": _rng.randf() * 6.0})
	_estaticos.append({"d": per_e2, "raiz": re2, "tipo": "hablar", "fase": _rng.randf() * 6.0})
	# Gente esperando el autobús en las paradas: la flota urbana
	# pasa por la red real de paradas, y ahora hay quien la espere.
	var con_espera := 0
	for pi_p in range(_paradas_red.size()):
		if con_espera >= 8:
			break
		if pi_p % 25 != 0:
			continue
		var par: Dictionary = _paradas_red[pi_p]
		var pp := Vector2(float(par["x"]), float(par["z"]))
		if absf(pp.x) > 900.0 or absf(pp.y) > 700.0:
			continue
		var per_p := _persona_en(Vector3(pp.x, 0, pp.y), Vector2(0.4, 0.4), camisas[k % camisas.size()], pelos[k % pelos.size()])
		k += 1
		(per_p["raiz"] as Node3D).rotation.y = atan2(float(par["hx"]), float(par["hz"])) + PI / 2.0
		_estaticos.append({"d": per_p, "raiz": per_p["raiz"], "tipo": "espera", "fase": _rng.randf() * 6.0})
		con_espera += 1
	# Perros acompañando a los primeros paseantes
	var col_perros := [Color(0.55, 0.38, 0.22), Color(0.85, 0.82, 0.78), Color(0.20, 0.18, 0.16), Color(0.65, 0.50, 0.30)]
	for j in mini(7, _peatones.size()):
		var dog := _hacer_perro(col_perros[j % col_perros.size()])
		add_child(dog["raiz"])
		_perros.append({"raiz": dog["raiz"], "cola": dog["cola"], "dueno": j, "fase": _rng.randf() * 6.0})
	# Pájaros sobre el Espolón y el Parque del Ebro
	var centros := [_poi_nom("Paseo del Espolón"), _poi_nom("Parque del Ebro")]
	for j in 7:
		var cen: Vector3 = centros[j % 2]
		if cen == Vector3.ZERO:
			continue
		var ave := _hacer_pajaro()
		add_child(ave["raiz"])
		_pajaros.append({"raiz": ave["raiz"], "ai": ave["ai"], "ad": ave["ad"], "centro": Vector2(cen.x, cen.z), "radio": 9.0 + _rng.randf() * 8.0, "alto": 13.0 + _rng.randf() * 6.0, "ang": _rng.randf() * TAU, "vel": 0.25 + _rng.randf() * 0.2, "fase": _rng.randf() * 6.0, "ybase": _altura(cen.x, cen.z)})

func _hacer_perro(color: Color) -> Dictionary:
	var raiz := Node3D.new()
	# Cuerpo, cabeza, hocico y patas fundidos en una sola malla; la cola
	# queda como pieza propia porque es lo que se mueve.
	var partes: Array = [
		[Vector3(0, 0.42, 0), Vector3(0.28, 0.30, 0.62), color],
		[Vector3(0, 0.58, 0.40), Vector3(0.22, 0.24, 0.24), color],
		[Vector3(0, 0.50, 0.57), Vector3(0.10, 0.10, 0.16), Color(0.15, 0.12, 0.10)],
	]
	for sx in [-0.09, 0.09]:
		for sz in [-0.20, 0.20]:
			partes.append([Vector3(sx, 0.15, sz), Vector3(0.07, 0.30, 0.07), color.darkened(0.15)])
	raiz.add_child(_fundida(partes))
	var cola := Node3D.new()
	cola.position = Vector3(0, 0.52, -0.32)
	cola.add_child(_pieza(Vector3(0.07, 0.07, 0.34), Vector3(0, 0.05, -0.15), color))
	raiz.add_child(cola)
	return {"raiz": raiz, "cola": cola}

func _hacer_pajaro() -> Dictionary:
	var raiz := Node3D.new()
	var oscuro := Color(0.16, 0.15, 0.19)
	raiz.add_child(_pieza(Vector3(0.14, 0.10, 0.36), Vector3.ZERO, oscuro))
	var ai := Node3D.new()
	ai.add_child(_pieza(Vector3(0.55, 0.03, 0.16), Vector3(-0.30, 0, 0), oscuro))
	raiz.add_child(ai)
	var ad := Node3D.new()
	ad.add_child(_pieza(Vector3(0.55, 0.03, 0.16), Vector3(0.30, 0, 0), oscuro))
	raiz.add_child(ad)
	return {"raiz": raiz, "ai": ai, "ad": ad}

func _actualizar_visibilidad() -> void:
	# Presupuesto de objetos de la web (incidentes 21/22-nov): WebGL
	# deja de dibujar el mundo al pasar de ~1.000 objetos DIBUJADOS.
	# La ciudad puede tener toda la vida que quiera, pero solo se
	# dibuja lo que está cerca del jugador, como las baldosas en
	# streaming o los rótulos por proximidad. La lógica (caminar,
	# parar, esperar) sigue corriendo igual para todos.
	var ref := _bus.position if _en_bus else (_coche.position if _en_coche else _jugador.position)
	var r_per := 150.0 * 150.0
	var r_veh := 300.0 * 300.0
	for peat in _peatones:
		var rz: Node3D = peat["raiz"]
		rz.visible = rz.position.distance_squared_to(ref) < r_per
	for est in _estaticos:
		var rz2: Node3D = est["raiz"]
		rz2.visible = rz2.position.distance_squared_to(ref) < r_per
	for t in _trafico:
		var nd: Node3D = t["nodo3d"]
		nd.visible = nd.position.distance_squared_to(ref) < r_veh
	for bu in _buses_urbanos:
		var nb: Node3D = bu["nodo3d"]
		nb.visible = nb.position.distance_squared_to(ref) < r_veh
	for col in _columpios:
		var piv: Node3D = col["pivote"]
		piv.visible = piv.position.distance_squared_to(ref) < 200.0 * 200.0
	for sk in _skaters:
		var rz3: Node3D = sk["raiz"]
		rz3.visible = rz3.position.distance_squared_to(ref) < 200.0 * 200.0
	for pc in _parque_columpios:
		var piv3: Node3D = pc["pivote"]
		piv3.visible = piv3.position.distance_squared_to(ref) < 200.0 * 200.0
	if not _balon_gal.is_empty():
		var bn: Node3D = _balon_gal["nodo"]
		bn.visible = bn.position.distance_squared_to(ref) < 200.0 * 200.0

func _columpio_libre() -> Dictionary:
	# El columpio sin niño de Gallarza, si el jugador está
	# junto a su asiento.
	if _jugador == null or _columpios.size() < 2:
		return {}
	var col: Dictionary = _columpios[1]
	var piv: Node3D = col["pivote"]
	if Vector2(_jugador.position.x - piv.position.x, _jugador.position.z - piv.position.z).length() < 1.7:
		return col
	return {}

func _alternar_columpio() -> void:
	if _en_columpio:
		_bajar_columpio()
		return
	if _en_coche or _en_bus or _en_interior != "" or _sentado or _nadando:
		return
	if _columpio_libre().is_empty():
		return
	_en_columpio = true
	_columpios[1]["fase_propia"] = 0.0
	_aviso_set("¡A columpiarse! W para coger impulso, S para frenar, E para bajarte", 4.0)

func _bajar_columpio() -> void:
	if not _en_columpio:
		return
	_en_columpio = false
	var col: Dictionary = _columpios[1]
	# El balanceo libre continúa sin salto: la fase propia
	# se traduce a la fase del reloj global.
	col["fase"] = float(col.get("fase_propia", 0.0)) - _tiempo * 1.35
	col.erase("fase_propia")
	_jugador.position = Vector3(-510.2, _altura(-510.2, 716.3) + 0.95, 716.3)
	_dir_jugador = 0.0
	_jugador.rotation.y = 0.0
	_pierna_i.rotation.x = 0.0
	_pierna_d.rotation.x = 0.0
	_brazo_i.rotation.x = 0.0
	_brazo_d.rotation.x = 0.0
	if _rodilla_i != null:
		_rodilla_i.rotation.x = 0.0
		_rodilla_d.rotation.x = 0.0
	if _codo_i != null:
		_codo_i.rotation.x = 0.0
		_codo_d.rotation.x = 0.0

func _actualizar_columpio(_delta: float) -> void:
	# Sentado en el asiento: el sitio sale del pivote, como
	# el del niño del otro columpio, y la postura es la de
	# estar columpiándose (piernas al vaivén, manos a las
	# cadenas).
	var col: Dictionary = _columpios[1]
	var piv: Node3D = col["pivote"]
	_jugador.position = piv.to_global(Vector3(0, -1.40, 0.03))
	_jugador.rotation.y = 0.0
	var ond := sin(float(col.get("fase_propia", 0.0)))
	_pierna_i.rotation.x = -1.30 + ond * 0.35
	_pierna_d.rotation.x = -1.30 + ond * 0.35
	_brazo_i.rotation.x = -2.50
	_brazo_d.rotation.x = -2.50
	if _rodilla_i != null:
		_rodilla_i.rotation.x = 1.05
		_rodilla_d.rotation.x = 1.05
	if _codo_i != null:
		_codo_i.rotation.x = -0.35
		_codo_d.rotation.x = -0.35
	_aviso = "W · coger impulso — S · frenar — E · bajarte"
	_aviso_hasta = _tiempo + 0.6

func _mover_peatones(delta: float) -> void:
	for peat in _peatones:
		var raiz: Node3D = peat["raiz"]
		var dest: Vector3 = peat["destino"]
		var hacia := Vector2(dest.x - raiz.position.x, dest.z - raiz.position.z)
		if hacia.length() < 0.7:
			var actual: int = peat["nodo"]
			var vecinos: Array = _ady.get(actual, [])
			if vecinos.is_empty():
				continue
			var sig: int = vecinos[_rng.randi() % vecinos.size()][0]
			peat["nodo"] = sig
			var dp: Vector2 = _nodos[sig]
			peat["destino"] = Vector3(dp.x, 0, dp.y)
			continue
		var dir := hacia / hacia.length()
		var vel := float(peat["vel"])
		var paso_p := dir * vel * delta
		var base_pp := Vector2(raiz.position.x, raiz.position.z)
		for ang_p in [0.0, 0.7, -0.7, 1.4, -1.4]:
			var cand_p := base_pp + paso_p.rotated(ang_p)
			if not _choca(cand_p, 0.35) and not _choca_entidad(cand_p, 0.35, raiz):
				raiz.position.x = cand_p.x
				raiz.position.z = cand_p.y
				break
		raiz.position.y = _altura(raiz.position.x, raiz.position.z) + 0.95
		raiz.rotation.y = atan2(dir.x, dir.y)
		peat["fase"] = float(peat["fase"]) + delta * 8.0
		var a := sin(float(peat["fase"])) * 0.5
		var d: Dictionary = peat["d"]
		(d["pi"] as Node3D).rotation.x = a
		(d["pd"] as Node3D).rotation.x = -a
		(d["bi"] as Node3D).rotation.x = -a * 0.7
		(d["bd"] as Node3D).rotation.x = a * 0.7
		(d["cabeza"] as Node3D).rotation.y = sin(_tiempo * 0.45 + float(peat["fase"]) * 0.35) * 0.35
		raiz.position.y += absf(sin(float(peat["fase"]))) * 0.035
		raiz.rotation.z = sin(float(peat["fase"])) * 0.03
	# Fase 9: comportamientos quietos, perros y pájaros
	for est in _estaticos:
		var d2: Dictionary = est["d"]
		var f2 := float(est["fase"])
		var raiz_e: Node3D = est["raiz"]
		if not est.has("y0"):
			est["y0"] = raiz_e.position.y
		# Respiración: nadie está clavado; el cuerpo sube y baja un poco
		raiz_e.position.y = float(est["y0"]) + sin(_tiempo * 1.5 + f2) * 0.012
		var cab_e: Node3D = d2["cabeza"]
		match String(est["tipo"]):
			"movil":
				(d2["bd"] as Node3D).rotation.x = -0.95 + sin(_tiempo * 0.7 + f2) * 0.08
				cab_e.rotation.x = 0.42 + sin(_tiempo * 0.5 + f2) * 0.05
				cab_e.rotation.y = sin(_tiempo * 0.23 + f2) * 0.15
			"hablar":
				(d2["bi"] as Node3D).rotation.x = -0.10 + sin(_tiempo * 1.3 + f2) * 0.25
				(d2["bd"] as Node3D).rotation.x = -0.10 + cos(_tiempo * 1.1 + f2) * 0.25
				cab_e.rotation.x = 0.06 + sin(_tiempo * 2.0 + f2) * 0.07
				cab_e.rotation.y = sin(_tiempo * 0.6 + f2) * 0.12
				raiz_e.rotation.z = sin(_tiempo * 0.9 + f2) * 0.02
			"sentado":
				(d2["pi"] as Node3D).rotation.x = -1.25 + sin(_tiempo * 0.9 + f2) * 0.10
				(d2["pd"] as Node3D).rotation.x = -1.25 + cos(_tiempo * 0.8 + f2) * 0.10
				(d2["bi"] as Node3D).rotation.x = -0.15 + sin(_tiempo * 1.1 + f2) * 0.05
				(d2["bd"] as Node3D).rotation.x = -0.15 + cos(_tiempo * 1.0 + f2) * 0.05
				cab_e.rotation.y = sin(_tiempo * 0.3 + f2 * 1.7) * 0.45
			"tenis":
				var casa_t: Vector3 = est["casa"]
				var eje_t: Vector2 = est["eje"]
				var desp_t := sin(_tiempo * 0.85 + f2) * float(est.get("amp", 2.2))
				raiz_e.position.x = casa_t.x + eje_t.x * desp_t
				raiz_e.position.z = casa_t.z + eje_t.y * desp_t
				(d2["bd"] as Node3D).rotation.x = -0.4 + sin(_tiempo * 1.7 + f2) * 0.55
				(d2["bi"] as Node3D).rotation.x = -0.15 + cos(_tiempo * 0.85 + f2) * 0.12
				raiz_e.rotation.y = float(est["mira"])
			"nadar":
				raiz_e.position.y += sin(_tiempo * 1.9 + f2) * 0.05
				(d2["bi"] as Node3D).rotation.x = sin(_tiempo * 1.4 + f2) * 0.95
				(d2["bd"] as Node3D).rotation.x = sin(_tiempo * 1.4 + f2 + PI) * 0.95
				cab_e.rotation.x = -0.18
			"largos":
				# Haciendo largos en su calle: va y viene a
				# ritmo constante braceando a crol, y al
				# final de la calle se da la vuelta.
				var casa_l: Vector3 = est["casa"]
				var eje_l: Vector2 = est["eje"]
				var amp_l := float(est.get("amp", 20.0))
				var s_l := fmod(_tiempo * float(est.get("vel", 1.2)) + f2 * 11.0, 4.0 * amp_l)
				var desp_l := 0.0
				var sentido_l := 1.0
				if s_l < 2.0 * amp_l:
					desp_l = -amp_l + s_l
				else:
					desp_l = amp_l - (s_l - 2.0 * amp_l)
					sentido_l = -1.0
				raiz_e.position.x = casa_l.x + eje_l.x * desp_l
				raiz_e.position.z = casa_l.z + eje_l.y * desp_l
				raiz_e.position.y = float(est["y0"]) + sin(_tiempo * 2.1 + f2) * 0.04
				var mira_l := atan2(eje_l.x * sentido_l, eje_l.y * sentido_l)
				raiz_e.rotation.y = lerp_angle(raiz_e.rotation.y, mira_l, clampf(delta * 5.0, 0.0, 1.0))
				var fb_l := _tiempo * 5.0 + f2 * 3.0
				(d2["bi"] as Node3D).rotation.x = sin(fb_l) * 1.8
				(d2["bd"] as Node3D).rotation.x = sin(fb_l + PI) * 1.8
				(d2["pi"] as Node3D).rotation.x = sin(fb_l * 2.0) * 0.35
				(d2["pd"] as Node3D).rotation.x = sin(fb_l * 2.0 + PI) * 0.35
				cab_e.rotation.x = -0.5
				raiz_e.rotation.z = sin(fb_l) * 0.08
			"escalar":
				raiz_e.position.y = float(est["y0"]) + (sin(_tiempo * 0.22 + f2) * 0.5 + 0.5) * float(est.get("sube", 1.8))
				(d2["bi"] as Node3D).rotation.x = -2.5 + sin(_tiempo * 0.9 + f2) * 0.25
				(d2["bd"] as Node3D).rotation.x = -2.5 + cos(_tiempo * 0.8 + f2) * 0.25
				(d2["pi"] as Node3D).rotation.x = -0.7 + sin(_tiempo * 0.7 + f2) * 0.2
				(d2["pd"] as Node3D).rotation.x = -0.7 + cos(_tiempo * 0.6 + f2) * 0.2
	# Columpios de Gallarza: balanceo continuo, el ocupado con las
	# piernas siguiendo el vaivén; y el balón que va y viene.
	for col in _columpios:
		var piv_c: Node3D = col["pivote"]
		var ond := 0.0
		if col.has("fase_propia"):
			# Lo mueve el jugador montado: péndulo con su
			# propia fase; la W coge impulso, la S frena, y
			# el aire lo va calmando poco a poco.
			var fp := float(col["fase_propia"]) + delta * 2.6
			col["fase_propia"] = fp
			var amp_c := float(col["amp"])
			if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
				amp_c = minf(amp_c + delta * 0.22, 0.85)
			elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
				amp_c = maxf(amp_c - delta * 0.45, 0.0)
			amp_c = maxf(amp_c - delta * 0.015, 0.0)
			col["amp"] = amp_c
			ond = sin(fp)
		else:
			ond = sin(_tiempo * 1.35 + float(col["fase"]))
			if float(col["amp"]) > 0.16:
				col["amp"] = maxf(0.16, float(col["amp"]) - delta * 0.04)
		piv_c.rotation.x = ond * float(col["amp"])
		var dc: Dictionary = col["d"]
		if not dc.is_empty():
			(dc["pi"] as Node3D).rotation.x = -1.30 + ond * 0.35
			(dc["pd"] as Node3D).rotation.x = -1.30 + ond * 0.35
	# Los chavales del skate park de Las Norias: cada uno con
	# su circuito; la tabla va pegada a los pies y el cuerpo
	# se agacha al coger impulso y se recoge en el aire.
	for sk in _skaters:
		var dsk: Dictionary = sk["d"]
		var raiz_s: Node3D = sk["raiz"]
		var ys_s := float(sk["ys"])
		var tt := _tiempo + float(sk["fase"]) * 3.7
		var px := -899.0
		var pz := -735.0
		var surf := ys_s + 0.06
		var aire := 0.0
		var mira := 0.0
		var pitch := 0.0
		match int(sk["modo"]):
			0:
				var zz := -738.0 + sin(tt * 0.85) * 4.2
				pz = zz
				px = -910.0
				if zz > -742.0:
					surf = ys_s + 0.25 + clampf((zz + 742.0) / 8.0, 0.0, 1.0) * 1.8
				var va := cos(tt * 0.85)
				mira = 0.0 if va > 0.0 else PI
				var delante := zz + (0.7 if va > 0.0 else -0.7)
				var surf_d := ys_s + 0.06
				if delante > -742.0:
					surf_d = ys_s + 0.25 + clampf((delante + 742.0) / 8.0, 0.0, 1.0) * 1.8
				pitch = -atan2(surf_d - surf, 0.7) * (1.0 if mira == 0.0 else -1.0)
			1:
				var aa := tt * 0.55
				px = -899.0 + cos(aa) * 11.5
				pz = -735.0 + sin(aa) * 8.5
				mira = atan2(-sin(aa), cos(aa))
				aire = pow(maxf(0.0, sin(aa * 2.0 + 1.0)), 6.0) * 0.55
			2:
				var xx := -899.0 + sin(tt * 0.5) * 14.0
				px = xx
				pz = -726.5
				var dentro := minf(xx + 908.0, -900.0 - xx)
				var fr := clampf((dentro + 0.45) / 0.9, 0.0, 1.0)
				surf = lerpf(ys_s + 0.06, ys_s + 0.58, fr * fr * (3.0 - 2.0 * fr))
				aire = 0.38 * (exp(-pow((xx + 908.6) / 0.8, 2.0)) + exp(-pow((xx + 899.4) / 0.8, 2.0)))
				mira = PI * 0.5 if cos(tt * 0.5) > 0.0 else -PI * 0.5
		raiz_s.position = Vector3(px, surf + aire + 0.95, pz)
		raiz_s.rotation.y = mira
		raiz_s.rotation.x = pitch
		var agach := 0.25 + aire * 1.1
		(dsk["pi"] as Node3D).rotation.x = -0.50 - agach * 0.55
		(dsk["pd"] as Node3D).rotation.x = -0.28 - agach * 0.40
		(dsk["bi"] as Node3D).rotation.z = 0.50 + sin(tt * 2.1) * 0.10
		(dsk["bd"] as Node3D).rotation.z = -0.50 - cos(tt * 1.7) * 0.10
		(dsk["bi"] as Node3D).rotation.x = -0.15
		(dsk["bd"] as Node3D).rotation.x = -0.15
		(dsk["cabeza"] as Node3D).rotation.y = sin(tt * 0.6) * 0.2
		(sk["tabla"] as Node3D).rotation.x = -aire * 0.30
	# Los columpios de los parques infantiles: vaiven continuo
	# con su nino encima, como los de Gallarza pero sin jinete.
	for pc in _parque_columpios:
		var piv_p: Node3D = pc["pivote"]
		var ond_p := sin(_tiempo * 1.35 + float(pc["fase"]))
		piv_p.rotation.x = ond_p * float(pc["amp"])
		var dp2: Dictionary = pc["d"]
		if not dp2.is_empty():
			(dp2["pi"] as Node3D).rotation.x = -1.30 + ond_p * 0.35
			(dp2["pd"] as Node3D).rotation.x = -1.30 + ond_p * 0.35
	if not _balon_gal.is_empty():
		_balon_gal["t"] = float(_balon_gal["t"]) + delta / 1.15
		if float(_balon_gal["t"]) >= 1.0:
			_balon_gal["t"] = 0.0
			var tmp_p: Vector3 = _balon_gal["a"]
			_balon_gal["a"] = _balon_gal["b"]
			_balon_gal["b"] = tmp_p
			var tmp_d: Dictionary = _balon_gal["da"]
			_balon_gal["da"] = _balon_gal["db"]
			_balon_gal["db"] = tmp_d
			_balon_gal["flick"] = 0.28
		var tb := float(_balon_gal["t"])
		var pos_b: Vector3 = (_balon_gal["a"] as Vector3).lerp(_balon_gal["b"], tb)
		pos_b.y = float(_balon_gal["y"]) + 0.17 + sin(tb * PI) * 0.38
		(_balon_gal["nodo"] as Node3D).position = pos_b
		if float(_balon_gal.get("flick", 0.0)) > 0.0:
			_balon_gal["flick"] = float(_balon_gal["flick"]) - delta
			var dk: Dictionary = _balon_gal["da"]
			(dk["pd"] as Node3D).rotation.x = -1.0 * maxf(0.0, float(_balon_gal["flick"]) / 0.28)
	for dog in _perros:
		var dueno: Dictionary = _peatones[int(dog["dueno"])]
		var pos_d: Node3D = dueno["raiz"]
		var fwd := Vector3(sin(pos_d.rotation.y), 0, cos(pos_d.rotation.y))
		var lado_d := Vector3(fwd.z, 0, -fwd.x)
		var raiz_p: Node3D = dog["raiz"]
		var dest_p := pos_d.position - fwd * 0.55 + lado_d * 0.7
		raiz_p.position = Vector3(dest_p.x, _altura(dest_p.x, dest_p.z) + absf(sin(_tiempo * 9.0 + float(dog["fase"]))) * 0.03, dest_p.z)
		raiz_p.rotation.y = pos_d.rotation.y
		(dog["cola"] as Node3D).rotation.y = sin(_tiempo * 6.0 + float(dog["fase"])) * 0.4
	for ave in _pajaros:
		ave["ang"] = float(ave["ang"]) + float(ave["vel"]) * delta
		var ang_a := float(ave["ang"])
		var cen_a: Vector2 = ave["centro"]
		var cerca := _jugador != null and Vector2(_jugador.position.x, _jugador.position.z).distance_to(cen_a) < 15.0
		var radio_obj := float(ave["radio"]) + (9.0 if cerca else 0.0)
		var alto_obj := float(ave["alto"]) + (6.0 if cerca else 0.0)
		ave["radio_a"] = lerpf(float(ave.get("radio_a", ave["radio"])), radio_obj, clampf(delta * 1.5, 0.0, 1.0))
		ave["alto_a"] = lerpf(float(ave.get("alto_a", ave["alto"])), alto_obj, clampf(delta * 1.5, 0.0, 1.0))
		var raiz_a: Node3D = ave["raiz"]
		raiz_a.position = Vector3(cen_a.x + cos(ang_a) * float(ave["radio_a"]), float(ave["ybase"]) + float(ave["alto_a"]) + sin(_tiempo * 1.3 + float(ave["fase"])) * 0.6, cen_a.y + sin(ang_a) * float(ave["radio_a"]))
		raiz_a.rotation.y = -ang_a
		var aleteo := sin(_tiempo * 9.0 + float(ave["fase"])) * 0.55
		(ave["ai"] as Node3D).rotation.z = aleteo
		(ave["ad"] as Node3D).rotation.z = -aleteo
	# Los piraguistas del Ebro: su circuito entre el Puente
	# de Piedra y el de Hierro, remando sin parar con el
	# remo de doble pala (se balancea a un lado y a otro y
	# los brazos le siguen).
	if _piraguas.is_empty():
		_preparar_piraguas()
	for pg in _piraguas:
		var grupo: Node3D = pg["grupo"]
		var centro_k := _piragua_en(float(pg["s"]))
		if _jugador != null and Vector2(_jugador.position.x, _jugador.position.z).distance_to(centro_k) > 300.0:
			grupo.visible = false
			continue
		grupo.visible = true
		pg["s"] = fmod(float(pg["s"]) + float(pg["vel"]) * delta, _piragua_total)
		var pos_k := _piragua_en(float(pg["s"]))
		var pos_k2 := _piragua_en(float(pg["s"]) + 2.0)
		var dir_k := pos_k2 - pos_k
		grupo.position = Vector3(pos_k.x, _nivel_agua(pos_k) + 0.05 + sin(_tiempo * 1.7 + float(pg["fase"])) * 0.03, pos_k.y)
		if dir_k.length() > 0.01:
			grupo.rotation.y = lerp_angle(grupo.rotation.y, atan2(dir_k.x, dir_k.y), clampf(delta * 3.0, 0.0, 1.0))
		var f_r := _tiempo * 5.4 + float(pg["fase"])
		grupo.rotation.z = sin(f_r) * 0.06
		var remo: Node3D = pg["remo"]
		remo.rotation.z = sin(f_r) * 0.52
		remo.rotation.x = sin(f_r) * 0.10
		var dk: Dictionary = pg["d"]
		(dk["bi"] as Node3D).rotation.x = -0.85 + sin(f_r) * 0.22
		(dk["bd"] as Node3D).rotation.x = -0.85 + sin(f_r + PI) * 0.22
		if dk.get("ci") != null:
			(dk["ci"] as Node3D).rotation.x = -0.35
		if dk.get("cd") != null:
			(dk["cd"] as Node3D).rotation.x = -0.35
	# La pareja del Parque de los Enamorados, andando de la
	# mano: una elipse de paseo por el parque, los dos en
	# paso acompasado, los brazos de dentro inclinados el
	# uno hacia el otro y la cabeza un poco girada hacia
	# la pareja; los de fuera se balancean con el paso.
	if not _pareja_enamorados.is_empty():
		var cen_p := Vector2(-2311.0, 103.0)
		var per_pa: Dictionary = _pareja_enamorados["a"]
		var per_pb: Dictionary = _pareja_enamorados["b"]
		var raiz_pa: Node3D = per_pa["raiz"]
		var raiz_pb: Node3D = per_pb["raiz"]
		var cerca_p := _jugador == null or Vector2(_jugador.position.x, _jugador.position.z).distance_to(cen_p) < 320.0
		raiz_pa.visible = cerca_p
		raiz_pb.visible = cerca_p
		if cerca_p:
			var tita := float(_pareja_enamorados["tita"])
			var deriv := Vector2(-92.0 * sin(tita), 58.0 * cos(tita))
			tita = fmod(tita + 1.3 * delta / maxf(deriv.length(), 1.0), TAU)
			_pareja_enamorados["tita"] = tita
			_pareja_enamorados["fase"] = float(_pareja_enamorados["fase"]) + delta * 5.4
			var fase_p := float(_pareja_enamorados["fase"])
			var pos_p := cen_p + Vector2(92.0 * cos(tita), 58.0 * sin(tita))
			var tang := deriv.normalized()
			var ry_p := atan2(tang.x, tang.y)
			var lado_p := Vector2(cos(ry_p), -sin(ry_p))
			var sitios: Array = [pos_p + lado_p * 0.38, pos_p - lado_p * 0.38]
			var pers: Array = [per_pa, per_pb]
			for k in 2:
				var per_k: Dictionary = pers[k]
				var raiz_k: Node3D = per_k["raiz"]
				var sit: Vector2 = sitios[k]
				raiz_k.position = Vector3(sit.x, _altura(sit.x, sit.y) + 0.95, sit.y)
				raiz_k.rotation.y = ry_p
				(per_k["pi"] as Node3D).rotation.x = sin(fase_p) * 0.5
				(per_k["pd"] as Node3D).rotation.x = sin(fase_p + PI) * 0.5
			# Brazos de dentro (los que se dan la mano): fijos
			# e inclinados hacia la pareja; los de fuera,
			# balanceo suave contra la pierna cercana.
			(per_pa["bi"] as Node3D).rotation.z = 0.5
			(per_pa["bi"] as Node3D).rotation.x = -0.15
			(per_pb["bd"] as Node3D).rotation.z = -0.5
			(per_pb["bd"] as Node3D).rotation.x = -0.15
			(per_pa["bd"] as Node3D).rotation.x = sin(fase_p) * 0.3
			(per_pb["bi"] as Node3D).rotation.x = sin(fase_p + PI) * 0.3
			(per_pa["cabeza"] as Node3D).rotation.y = -0.3
			(per_pb["cabeza"] as Node3D).rotation.y = 0.3

func _cruce_seg(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> Vector2:
	var r := b - a
	var s := d - c
	var den := r.x * s.y - r.y * s.x
	if absf(den) < 0.000001:
		return Vector2.INF
	var t := ((c.x - a.x) * s.y - (c.y - a.y) * s.x) / den
	var u := ((c.x - a.x) * r.y - (c.y - a.y) * r.x) / den
	if t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0:
		return a + r * t
	return Vector2.INF

func _dist_rio(p: Vector2, rio2: Array) -> float:
	var mejor := 1e18
	for j in range(rio2.size() - 1):
		var cerca: Vector2 = Geometry2D.get_closest_point_to_segment(p, rio2[j], rio2[j + 1])
		mejor = minf(mejor, p.distance_to(cerca))
	return mejor

func _y_tablero(pu: Dictionary, p: Vector2) -> float:
	var a: Vector2 = pu["a"]
	var b: Vector2 = pu["b"]
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return lerpf(float(pu["ya"]), float(pu["yb"]), t) + sin(t * PI) * float(pu.get("bache", 0.5))

# Puentes sobre el Ebro: se detectan las calles que cruzan el río y se
# registra un corredor con la altura del tablero. _altura() usa esos
# corredores, así que coches, tráfico y peatones cruzan POR el tablero
# en vez de bajar al cauce. El tablero dibujado sigue el mismo eje.
func _crear_puentes() -> void:
	_puentes.clear()
	if _rio.size() < 2 or _calles_nombradas.is_empty():
		print("PUENTE_OK puentes=0")
		return
	var rio2: Array = []
	for p in _rio:
		rio2.append(Vector2(float(p[0]), float(p[1])))
	for calle in _calles_nombradas:
		var pts: Array = calle["p"]
		if pts.size() < 2:
			continue
		for i in range(pts.size() - 1):
			var a := Vector2(float(pts[i][0]), float(pts[i][1]))
			var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			var cruce := Vector2.INF
			for j in range(rio2.size() - 1):
				cruce = _cruce_seg(a, b, rio2[j], rio2[j + 1])
				if cruce != Vector2.INF:
					break
			if cruce == Vector2.INF:
				continue
			# Eje del puente: 55 m a cada lado del cruce, siguiendo la
			# dirección de la calle (vale igual para el puente entero
			# como vía corta o para una calle larga que lo cruza).
			var dir := b - a
			if dir.length() < 0.5:
				continue
			dir = dir.normalized()
			var ea: Vector2 = cruce - dir * 55.0
			var eb: Vector2 = cruce + dir * 55.0
			var duplicado := false
			for pu in _puentes:
				if ((Vector2(pu["a"]) + Vector2(pu["b"])) * 0.5).distance_to(cruce) < 60.0:
					duplicado = true
			if duplicado:
				continue
			_puentes.append({"a": ea, "b": eb, "ancho": 12.5, "n": String(calle.get("n", "")),
				"ya": _altura_terreno(ea.x, ea.y), "yb": _altura_terreno(eb.x, eb.y)})
	# La pasarela peatonal del Ebro no sale de las calles con
	# nombre (es un carril bici): se anade a mano con su eje real.
	var cen_pas := Vector2(-651.0, -366.0)
	var dir_pas := Vector2(79.0, 238.0).normalized()
	var pa_pas: Vector2 = cen_pas - dir_pas * 62.0
	var pb_pas: Vector2 = cen_pas + dir_pas * 62.0
	_puentes.append({"a": pa_pas, "b": pb_pas, "ancho": 5.0, "n": "Pasarela del Ebro",
		"ya": _altura_terreno(pa_pas.x, pa_pas.y), "yb": _altura_terreno(pb_pas.x, pb_pas.y)})
	# Dibujo de los tableros, siguiendo el mismo eje y las mismas alturas
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var piedra := Color(0.60, 0.53, 0.42)
	var piedra_osc := Color(0.50, 0.44, 0.35)
	for pu in _puentes:
		if String(pu.get("n", "")) in ["Puente de Práxedes Mateo Sagasta", "Pasarela del Ebro"]:
			continue  # estos dos se dibujan a medida en _puentes_medida
		var a: Vector2 = pu["a"]
		var b: Vector2 = pu["b"]
		var dir := (b - a).normalized()
		var rot := atan2(dir.x, dir.y)
		var n2 := Vector2(-dir.y, dir.x)
		var largo := a.distance_to(b)
		var pasos := int(ceil(largo / 6.0))
		var ant_t: Array = []
		var ant_b: Array = []
		for s in range(pasos + 1):
			var pc: Vector2 = a.lerp(b, float(s) / float(pasos))
			var yt := _y_tablero(pu, pc)
			ant_t.append(Vector3(pc.x + n2.x * 6.6, yt - 0.05, pc.y + n2.y * 6.6))
			ant_t.append(Vector3(pc.x - n2.x * 6.6, yt - 0.05, pc.y - n2.y * 6.6))
			ant_b.append(Vector3(pc.x + n2.x * 6.6, yt - 1.25, pc.y + n2.y * 6.6))
			ant_b.append(Vector3(pc.x - n2.x * 6.6, yt - 1.25, pc.y - n2.y * 6.6))
		for s in range(pasos):
			var t0: Vector3 = ant_t[s * 2]
			var t1: Vector3 = ant_t[s * 2 + 1]
			var t2: Vector3 = ant_t[s * 2 + 2]
			var t3: Vector3 = ant_t[s * 2 + 3]
			_tri(verts, normals, cols, t0, t1, t2, true, piedra)
			_tri(verts, normals, cols, t1, t3, t2, true, piedra)
			var b0: Vector3 = ant_b[s * 2]
			var b1: Vector3 = ant_b[s * 2 + 1]
			var b2: Vector3 = ant_b[s * 2 + 2]
			var b3: Vector3 = ant_b[s * 2 + 3]
			_tri(verts, normals, cols, t0, b0, t2, false, piedra_osc)
			_tri(verts, normals, cols, b0, b2, t2, false, piedra_osc)
			_tri(verts, normals, cols, t1, t3, b1, false, piedra_osc)
			_tri(verts, normals, cols, b1, t3, b3, false, piedra_osc)
		# Pretiles laterales y pilares en el cauce
		for s in range(pasos):
			var pc: Vector2 = a.lerp(b, (float(s) + 0.5) / float(pasos))
			var yt := _y_tablero(pu, pc)
			for lado in [-1.0, 1.0]:
				var lp: Vector2 = pc + n2 * (lado * 6.05)
				_caja_en(verts, normals, cols, Vector3(lp.x, yt + 0.42, lp.y), Vector3(0.4, 0.85, largo / pasos + 0.15), piedra_osc, rot)
		for s in range(1, pasos):
			var pc2: Vector2 = a.lerp(b, float(s) / float(pasos))
			if _dist_rio(pc2, rio2) < 24.0 and s % 3 == 0:
				var yt2 := _y_tablero(pu, pc2)
				var y_agua := _altura_terreno(pc2.x, pc2.y)
				var alto := (yt2 - 1.2) - (y_agua - 1.5)
				if alto > 2.0:
					_caja_en(verts, normals, cols, Vector3(pc2.x, y_agua - 1.5 + alto * 0.5, pc2.y), Vector3(9.5, alto, 3.0), piedra_osc, rot)
		# Farolas del puente
		for tt in [0.22, 0.5, 0.78]:
			for lado2 in [-1.0, 1.0]:
				var lp2: Vector2 = a.lerp(b, tt) + n2 * (lado2 * 5.6)
				var yt3 := _y_tablero(pu, lp2)
				_caja_en(verts, normals, cols, Vector3(lp2.x, yt3 + 1.3, lp2.y), Vector3(0.11, 2.6, 0.11), Color(0.16, 0.17, 0.19), 0.0)
				_caja_en(verts, normals, cols, Vector3(lp2.x, yt3 + 2.68, lp2.y), Vector3(0.44, 0.13, 0.26), Color(1.0, 0.86, 0.58), rot)
	if verts.size() > 0:
		add_child(_malla_de(verts, normals, cols, Color.WHITE))
	print("PUENTE_OK puentes=", _puentes.size())
	# El paso elevado de Republica Argentina sobre el ferrocarril:
	# no es un puente del rio, pero usa el mismo corredor de
	# alturas para que la avenida pase POR ENCIMA de las vias.
	# Antes era UNA cuerda recta de 110 m y la avenida real CURVA:
	# el tablero cortaba las calzadas en diagonal (visto por Jon).
	# Ahora el corredor sigue la polilínea real de la avenida
	# (las dos calzadas, cosidas por extremos coincidentes) con la
	# altura por distancia al cruce: 4,2 m sobre las vías y rampas
	# suaves hasta el suelo a ~95 m.
	var cruce_ra := Vector2(-649.0, 1075.0)
	var frags_ra: Array = []
	for calle_ra in _calles_nombradas:
		if String(calle_ra.get("n", "")) == "Avenida República Argentina":
			var pts_ra: Array = []
			for p_ra in calle_ra["p"]:
				pts_ra.append(Vector2(float(p_ra[0]), float(p_ra[1])))
			if pts_ra.size() >= 2:
				frags_ra.append(pts_ra)
	var cadena_ra: Array = []
	while not frags_ra.is_empty() and cadena_ra.is_empty():
		var semilla: Array = frags_ra[0]
		frags_ra.remove_at(0)
		var cadena_t: Array = semilla.duplicate()
		var progreso := true
		while progreso and not frags_ra.is_empty():
			progreso = false
			for i in range(frags_ra.size() - 1, -1, -1):
				var f: Array = frags_ra[i]
				var unido := true
				if (f[0] as Vector2).distance_to(cadena_t[cadena_t.size() - 1]) < 0.6:
					for j in range(1, f.size()):
						cadena_t.append(f[j])
				elif (f[f.size() - 1] as Vector2).distance_to(cadena_t[cadena_t.size() - 1]) < 0.6:
					for j in range(f.size() - 2, -1, -1):
						cadena_t.append(f[j])
				elif (f[f.size() - 1] as Vector2).distance_to(cadena_t[0]) < 0.6:
					# Anteponer f (sin su último punto, que es el
					# inicio actual) PRESERVANDO el orden: insert(0)
					# en bucle lo invertía y la cadena zigzagueaba.
					var nueva3: Array = []
					for j in range(f.size() - 1):
						nueva3.append(f[j])
					nueva3.append_array(cadena_t)
					cadena_t = nueva3
				elif (f[0] as Vector2).distance_to(cadena_t[0]) < 0.6:
					# Anteponer f DEL REVÉS (su inicio es el inicio
					# actual): de su último punto a su segundo.
					var nueva4: Array = []
					for j in range(f.size() - 1, 0, -1):
						nueva4.append(f[j])
					nueva4.append_array(cadena_t)
					cadena_t = nueva4
				else:
					unido = false
				if unido:
					frags_ra.remove_at(i)
					progreso = true
		var d_min := 1.0e9
		for p_c in cadena_t:
			d_min = minf(d_min, (p_c as Vector2).distance_to(cruce_ra))
		if d_min < 20.0:
			cadena_ra = cadena_t
	var n_ra := 0
	var n_series_ra := 0
	if cadena_ra.size() >= 2:
		# Tramos consecutivos dentro de la ventana del cruce; al
		# salir de la ventana se corta la serie (la cadena baja por
		# una calzada y vuelve por la otra: no se cose el salto).
		var serie: Array = []
		var series: Array = []
		for i in range(cadena_ra.size()):
			var p_s: Vector2 = cadena_ra[i]
			if p_s.distance_to(cruce_ra) < 105.0:
				serie.append(p_s)
			else:
				if serie.size() >= 2:
					series.append(serie)
				serie = []
		if serie.size() >= 2:
			series.append(serie)
		n_series_ra = series.size()
		for serie2 in series:
			# Tramos entre vértices consecutivos de la polilínea
			# real: el corredor sigue la curva de la avenida al
			# metro, sin cuerdas que corten las calzadas.
			var rem: Array = serie2
			for i in range(rem.size() - 1):
				var pa: Vector2 = rem[i]
				var pb: Vector2 = rem[i + 1]
				var ha := 4.2 * (1.0 - smoothstep(35.0, 95.0, pa.distance_to(cruce_ra)))
				var hb := 4.2 * (1.0 - smoothstep(35.0, 95.0, pb.distance_to(cruce_ra)))
				_puentes.append({"a": pa, "b": pb, "ancho": 10.5, "n": "República Argentina (ferrocarril)",
					"ya": _altura_terreno(pa.x, pa.y) + ha, "yb": _altura_terreno(pb.x, pb.y) + hb, "bache": 0.0})
				n_ra += 1
	print("PUENTE_RA_OK tramos=", n_ra, " cadena=", cadena_ra.size(), " series=", n_series_ra)

func _viga(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, p1: Vector3, p2: Vector3, lat: Vector2, grosor: float, alto: float, col: Color) -> void:
	# Una viga entre dos puntos 3D (para celosías y arcos): sección
	# rectangular con el ancho en la dirección lateral dada.
	var u := (p2 - p1).normalized()
	var wd := Vector3(lat.x, 0.0, lat.y)
	var hd := wd.cross(u).normalized()
	var c1 := p1 - wd * (grosor * 0.5) - hd * (alto * 0.5)
	var c2 := p1 + wd * (grosor * 0.5) - hd * (alto * 0.5)
	var c3 := p1 + wd * (grosor * 0.5) + hd * (alto * 0.5)
	var c4 := p1 - wd * (grosor * 0.5) + hd * (alto * 0.5)
	var d1 := p2 - wd * (grosor * 0.5) - hd * (alto * 0.5)
	var d2 := p2 + wd * (grosor * 0.5) - hd * (alto * 0.5)
	var d3 := p2 + wd * (grosor * 0.5) + hd * (alto * 0.5)
	var d4 := p2 - wd * (grosor * 0.5) + hd * (alto * 0.5)
	_tri(verts, normals, cols, c1, d1, d2, false, col)
	_tri(verts, normals, cols, c1, d2, c2, false, col)
	_tri(verts, normals, cols, c4, c3, d3, false, col)
	_tri(verts, normals, cols, c4, d3, d4, false, col)
	_tri(verts, normals, cols, c2, d2, d3, false, col)
	_tri(verts, normals, cols, c2, d3, c3, false, col)
	_tri(verts, normals, cols, c1, c4, d4, false, col)
	_tri(verts, normals, cols, c1, d4, d1, false, col)

func _crear_vias() -> void:
	# El ferrocarril Bilbao-Casetas cruzando la ciudad: balasto,
	# traviesas y los dos railes, fundidos en una sola malla.
	if not FileAccess.file_exists("res://datos/ciudad/ferrocarril.json"):
		print("VIAS_OK m=0")
		return
	var datos = JSON.parse_string(FileAccess.get_file_as_string("res://datos/ciudad/ferrocarril.json"))
	if datos == null or not datos.has("vias"):
		print("VIAS_OK m=0")
		return
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var balasto := Color(0.34, 0.32, 0.29)
	var traviesa := Color(0.30, 0.23, 0.16)
	var acero := Color(0.58, 0.59, 0.62)
	var total := 0.0
	for via in datos["vias"]:
		var pts: Array = via
		if pts.size() < 2:
			continue
		var dens: Array = []
		for i in range(pts.size() - 1):
			var a := Vector2(float(pts[i][0]), float(pts[i][1]))
			var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			var n := maxi(int(a.distance_to(b) / 7.0), 1)
			for k in range(n):
				dens.append(a.lerp(b, float(k) / float(n)))
		dens.append(Vector2(float(pts[pts.size() - 1][0]), float(pts[pts.size() - 1][1])))
		for i in range(dens.size() - 1):
			var a: Vector2 = dens[i]
			var b: Vector2 = dens[i + 1]
			var dir := b - a
			var seg := dir.length()
			if seg < 0.1:
				continue
			dir /= seg
			var n2 := Vector2(-dir.y, dir.x)
			var rot := atan2(dir.x, dir.y)
			var cen := (a + b) * 0.5
			var y := _altura_terreno(cen.x, cen.y)
			total += seg
			_caja_en(verts, normals, cols, Vector3(cen.x, y + 0.05, cen.y), Vector3(4.6, 0.10, seg + 0.15), balasto, rot)
			for lado in [-0.75, 0.75]:
				var lp: Vector2 = cen + n2 * lado
				_caja_en(verts, normals, cols, Vector3(lp.x, y + 0.20, lp.y), Vector3(0.10, 0.14, seg + 0.1), acero, rot)
		var resto := 1.3
		for i in range(pts.size() - 1):
			var a := Vector2(float(pts[i][0]), float(pts[i][1]))
			var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			var seg := a.distance_to(b)
			if seg < 0.1:
				continue
			var dir := (b - a) / seg
			var rot := atan2(dir.x, dir.y)
			var d := resto
			while d < seg:
				var tp: Vector2 = a + dir * d
				var yt := _altura_terreno(tp.x, tp.y)
				_caja_en(verts, normals, cols, Vector3(tp.x, yt + 0.13, tp.y), Vector3(2.4, 0.10, 0.5), traviesa, rot)
				d += 2.6
			resto = d - seg
	if verts.size() > 0:
		add_child(_malla_de(verts, normals, cols, Color.WHITE))
	print("VIAS_OK m=", int(total))

func _crear_parques_infantiles() -> void:
	# Los parques infantiles con nombre en el plano: hasta
	# ahora solo eran un punto dorado y al llegar no habia NI
	# un columpio (visto por Jon en el Parque Infantil de
	# columpios). Cada uno lleva su suelo de goma, un columpio
	# doble con un nino balanceandose, un tobogan, un
	# balancin y un adulto vigilando.
	var sitios: Array = [
		[Vector2(677, 1092), 0.0],
		[Vector2(-936, 1199), 0.7],
		[Vector2(-815, 655), -0.4],
		[Vector2(2370, 331), 0.3],
		[Vector2(1366, 1854), 0.9]]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var col_poste := Color(0.30, 0.55, 0.75)
	var camisas_p: Array = [Color(0.85, 0.35, 0.20), Color(0.25, 0.55, 0.80), Color(0.95, 0.75, 0.25), Color(0.35, 0.70, 0.40), Color(0.75, 0.40, 0.75)]
	var pelos_p: Array = [Color(0.16, 0.11, 0.07), Color(0.45, 0.30, 0.16), Color(0.70, 0.60, 0.35)]
	var k := 0
	for sitio in sitios:
		var cen: Vector2 = sitio[0]
		var ang := float(sitio[1])
		var gy := _altura_terreno(cen.x, cen.y)
		_caja_en(verts, normals, cols, Vector3(cen.x, gy + 0.03, cen.y), Vector3(19, 0.08, 14), Color(0.52, 0.40, 0.32), -ang)
		# El columpio doble: patas en A y barra, todo fundido
		var barra_c := cen + Vector2(0, -3.2).rotated(ang)
		for sx in [-2.3, 2.3]:
			for sz in [-0.75, 0.75]:
				var pie_p: Vector2 = cen + Vector2(sx, -3.2 + sz).rotated(ang)
				var top_p: Vector2 = cen + Vector2(sx, -3.2).rotated(ang)
				_viga(verts, normals, cols, Vector3(pie_p.x, gy + 0.05, pie_p.y), Vector3(top_p.x, gy + 2.2, top_p.y), Vector2(0, 1), 0.09, 0.09, col_poste)
		var b1: Vector2 = cen + Vector2(-2.3, -3.2).rotated(ang)
		var b2: Vector2 = cen + Vector2(2.3, -3.2).rotated(ang)
		_viga(verts, normals, cols, Vector3(b1.x, gy + 2.2, b1.y), Vector3(b2.x, gy + 2.2, b2.y), Vector2(0, 1), 0.10, 0.10, col_poste)
		# Los dos asientos colgando (pivotes, como en Gallarza)
		for i in 2:
			var wp: Vector2 = cen + Vector2(-1.15 + i * 2.3, -3.2).rotated(ang)
			var piv := Node3D.new()
			piv.position = Vector3(wp.x, gy + 2.2, wp.y)
			piv.rotation.y = -ang
			for cx in [-0.20, 0.20]:
				piv.add_child(_pieza(Vector3(0.045, 1.45, 0.045), Vector3(cx, -0.72, 0), Color(0.55, 0.56, 0.58)))
			piv.add_child(_pieza(Vector3(0.48, 0.05, 0.26), Vector3(0, -1.46, 0), Color(0.20, 0.22, 0.26)))
			add_child(piv)
			if i == 0:
				var nin := _hacer_persona(camisas_p[k % camisas_p.size()], Color(0.20, 0.24, 0.40), pelos_p[k % pelos_p.size()])
				var rz: Node3D = nin["raiz"]
				rz.scale = Vector3.ONE * 0.62
				rz.position = Vector3(0, -1.40, 0.03)
				(nin["pi"] as Node3D).rotation.x = -1.30
				(nin["pd"] as Node3D).rotation.x = -1.30
				(nin["bi"] as Node3D).rotation.x = -2.65
				(nin["bd"] as Node3D).rotation.x = -2.65
				piv.add_child(rz)
				_parque_columpios.append({"pivote": piv, "d": nin, "fase": _rng.randf() * 6.0, "amp": 0.42})
			else:
				_parque_columpios.append({"pivote": piv, "d": {}, "fase": _rng.randf() * 6.0, "amp": 0.15})
		# El tobogan: plataforma, rampa roja y escalones
		var plat: Vector2 = cen + Vector2(4.6, 1.9).rotated(ang)
		_caja_en(verts, normals, cols, Vector3(plat.x, gy + 0.50, plat.y), Vector3(1.1, 1.0, 1.1), col_poste, -ang)
		var r1: Vector2 = cen + Vector2(4.6, 2.6).rotated(ang)
		var r2: Vector2 = cen + Vector2(4.6, 5.6).rotated(ang)
		_viga(verts, normals, cols, Vector3(r1.x, gy + 1.02, r1.y), Vector3(r2.x, gy + 0.12, r2.y), Vector2(1, 0).rotated(ang), 0.55, 0.08, Color(0.80, 0.25, 0.20))
		for e in range(3):
			var ep: Vector2 = cen + Vector2(4.6, 1.15 - float(e) * 0.42).rotated(ang)
			_caja_en(verts, normals, cols, Vector3(ep.x, gy + 0.72 - float(e) * 0.24, ep.y), Vector3(0.7, 0.10, 0.34), Color(0.70, 0.71, 0.73), -ang)
		# El balancin, inclinado, esperando dos ninos
		var ful: Vector2 = cen + Vector2(-4.6, 2.8).rotated(ang)
		_caja_en(verts, normals, cols, Vector3(ful.x, gy + 0.25, ful.y), Vector3(0.35, 0.5, 0.35), col_poste, -ang)
		var s1: Vector2 = cen + Vector2(-6.4, 2.8).rotated(ang)
		var s2: Vector2 = cen + Vector2(-2.8, 2.8).rotated(ang)
		_viga(verts, normals, cols, Vector3(s1.x, gy + 0.68, s1.y), Vector3(s2.x, gy + 0.42, s2.y), Vector2(0, 1).rotated(ang), 0.35, 0.07, Color(0.25, 0.55, 0.85))
		# Un adulto vigilando junto al columpio
		var adulto := _persona_en(Vector3(cen.x, 0, cen.y), Vector2(3.4, -6.2).rotated(ang), camisas_p[(k + 2) % camisas_p.size()], pelos_p[k % pelos_p.size()])
		(adulto["raiz"] as Node3D).rotation.y = atan2(barra_c.x - (adulto["raiz"] as Node3D).position.x, barra_c.y - (adulto["raiz"] as Node3D).position.z)
		_estaticos.append({"d": adulto, "raiz": adulto["raiz"], "tipo": "espera", "fase": _rng.randf() * 6.0})
		k += 1
	add_child(_malla_de(verts, normals, cols, Color.WHITE))
	print("PARQUES_OK n=", sitios.size(), " columpios=", _parque_columpios.size())

func _hospital_gente() -> void:
	# La vida a la puerta del Hospital San Pedro (pedido de
	# Jon): dos medicos de bata blanca charlando, una
	# enfermera con un paciente en silla de ruedas y dos
	# madres con sus ninos esperando.
	var base := Vector3(1168, 0, 1768)
	var blanco := Color(0.95, 0.95, 0.97)
	var pelos_h: Array = [Color(0.16, 0.11, 0.07), Color(0.45, 0.30, 0.16), Color(0.85, 0.84, 0.80), Color(0.10, 0.08, 0.06)]
	var doc_a := _persona_en(base, Vector2(0, 0), blanco, pelos_h[0])
	var doc_b := _persona_en(base, Vector2(1.4, 0.5), blanco, pelos_h[2])
	var ra: Node3D = doc_a["raiz"]
	var rb: Node3D = doc_b["raiz"]
	ra.rotation.y = atan2(rb.position.x - ra.position.x, rb.position.z - ra.position.z)
	rb.rotation.y = atan2(ra.position.x - rb.position.x, ra.position.z - rb.position.z)
	_estaticos.append({"d": doc_a, "raiz": ra, "tipo": "hablar", "fase": _rng.randf() * 6.0})
	_estaticos.append({"d": doc_b, "raiz": rb, "tipo": "hablar", "fase": _rng.randf() * 6.0})
	# La silla de ruedas con su paciente (las ruedas, esta
	# vez, son cilindros de verdad)
	var silla := Node3D.new()
	var sp := _punto_libre(base + Vector3(7, 0, 3), 0.4)
	silla.position = Vector3(sp.x, _altura(sp.x, sp.z), sp.z)
	silla.rotation.y = -PI * 0.5
	silla.add_child(_pieza(Vector3(0.52, 0.07, 0.50), Vector3(0, 0.50, 0), Color(0.20, 0.22, 0.26)))
	silla.add_child(_pieza(Vector3(0.52, 0.55, 0.07), Vector3(0, 0.82, -0.24), Color(0.20, 0.22, 0.26)))
	silla.add_child(_pieza(Vector3(0.46, 0.06, 0.30), Vector3(0, 0.16, 0.30), Color(0.35, 0.36, 0.38)))
	for lado_s in [-0.29, 0.29]:
		var rueda := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.31
		cm.bottom_radius = 0.31
		cm.height = 0.05
		cm.radial_segments = 14
		var mat_r := StandardMaterial3D.new()
		mat_r.albedo_color = Color(0.12, 0.12, 0.13)
		cm.material = mat_r
		rueda.mesh = cm
		rueda.rotation.z = PI * 0.5
		rueda.position = Vector3(lado_s, 0.31, -0.06)
		silla.add_child(rueda)
		silla.add_child(_pieza(Vector3(0.05, 0.15, 0.15), Vector3(lado_s * 0.85, 0.08, 0.30), Color(0.12, 0.12, 0.13)))
	add_child(silla)
	var pac := _hacer_persona(Color(0.75, 0.72, 0.70), Color(0.40, 0.42, 0.48), pelos_h[1])
	var rp: Node3D = pac["raiz"]
	rp.position = Vector3(0, 0.55, 0.03)
	(pac["pi"] as Node3D).rotation.x = -1.30
	(pac["pd"] as Node3D).rotation.x = -1.30
	silla.add_child(rp)
	_estaticos.append({"d": pac, "raiz": rp, "tipo": "silla", "fase": _rng.randf() * 6.0})
	var enf := _persona_en(base, Vector2(8.6, 2.2), Color(0.55, 0.75, 0.85), pelos_h[3])
	(enf["raiz"] as Node3D).rotation.y = -PI * 0.5
	_estaticos.append({"d": enf, "raiz": enf["raiz"], "tipo": "espera", "fase": _rng.randf() * 6.0})
	# Dos madres con sus ninos
	var madres: Array = [
		[Vector2(-5, 6), Color(0.80, 0.40, 0.55), Color(0.30, 0.60, 0.85)],
		[Vector2(3, 9.5), Color(0.45, 0.65, 0.35), Color(0.90, 0.70, 0.25)]]
	for md in madres:
		var madre := _persona_en(base, md[0], md[1], pelos_h[_rng.randi() % pelos_h.size()])
		_estaticos.append({"d": madre, "raiz": madre["raiz"], "tipo": "espera", "fase": _rng.randf() * 6.0})
		var nin := _hacer_persona(md[2], Color(0.25, 0.30, 0.45), pelos_h[_rng.randi() % pelos_h.size()])
		var rn: Node3D = nin["raiz"]
		rn.scale = Vector3.ONE * 0.60
		var mp: Vector3 = (madre["raiz"] as Node3D).position
		rn.position = Vector3(mp.x + 0.62, _altura(mp.x + 0.62, mp.z + 0.25) + 0.57, mp.z + 0.25)
		rn.rotation.y = _rng.randf() * TAU
		add_child(rn)
		_estaticos.append({"d": nin, "raiz": rn, "tipo": "espera", "fase": _rng.randf() * 6.0})
	print("HOSPITAL_OK gente=8")

func _crear_colegios() -> void:
	# Los colegios e institutos de la ciudad (datos de OSM):
	# parcela con suelo propio, verja perimetral con puerta y
	# pistas deportivas al aire libre donde caben.
	var datos_txt := FileAccess.get_file_as_string("res://datos/ciudad/colegios.json")
	var datos: Dictionary = JSON.parse_string(datos_txt)
	# Las pistas ya vienen elegidas de fabrica (colegios_pistas.json,
	# horneado con banco/bake_colegios.py): buscarlas en el arranque
	# cargando las 63 baldosas costaba ~200 s en la web.
	var pistas_todas: Array = []
	var pj_txt := FileAccess.get_file_as_string("res://datos/ciudad/colegios_pistas.json")
	if pj_txt != "":
		var pj: Dictionary = JSON.parse_string(pj_txt)
		if pj.has("pistas"):
			pistas_todas = pj["pistas"]
	# La fachada de cada colegio (su edificio mayor y el borde
	# donde va el cartel grande) tambien viene horneada
	# (banco/bake_fachadas.py): buscarla en el arranque cargando
	# baldosas costaria lo mismo que las pistas.
	var fachadas_todas: Array = []
	var fj_txt := FileAccess.get_file_as_string("res://datos/ciudad/colegios_fachadas.json")
	if fj_txt != "":
		var fj: Dictionary = JSON.parse_string(fj_txt)
		if fj.has("fachadas"):
			fachadas_todas = fj["fachadas"]
	var n_fach := 0
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var n_pistas := 0
	var rotulos_col: Array = []
	var col_suelo := Color(0.55, 0.54, 0.50)
	var col_verja := Color(0.25, 0.30, 0.28)
	var lin2 := Color(0.92, 0.92, 0.90)
	for idx_col in range(datos["colegios"].size()):
		var col: Dictionary = datos["colegios"][idx_col]
		var poly := PackedVector2Array()
		for p in col["poly"]:
			poly.append(Vector2(float(p[0]), float(p[1])))
		if poly.size() < 3:
			continue
		var tris := Geometry2D.triangulate_polygon(poly)
		for t in range(0, tris.size() - 2, 3):
			var p1: Vector2 = poly[tris[t]]
			var p2: Vector2 = poly[tris[t + 1]]
			var p3: Vector2 = poly[tris[t + 2]]
			_tri(verts, normals, cols, Vector3(p1.x, _altura_terreno(p1.x, p1.y) + 0.05, p1.y), Vector3(p2.x, _altura_terreno(p2.x, p2.y) + 0.05, p2.y), Vector3(p3.x, _altura_terreno(p3.x, p3.y) + 0.05, p3.y), true, col_suelo)
		var i_largo := 0
		var l_max := 0.0
		for i in range(poly.size()):
			var la := poly[i].distance_to(poly[(i + 1) % poly.size()])
			if la > l_max:
				l_max = la
				i_largo = i
		for i in range(poly.size()):
			var a: Vector2 = poly[i]
			var b: Vector2 = poly[(i + 1) % poly.size()]
			var largo := a.distance_to(b)
			if largo < 1.0:
				continue
			var dir := (b - a) / largo
			var pasos := int(largo / 3.6)
			for s in range(pasos + 1):
				var pp := a + dir * (largo * float(s) / float(maxi(1, pasos)))
				if i == i_largo and pp.distance_to((a + b) * 0.5) < 2.6:
					continue
				var yp := _altura_terreno(pp.x, pp.y)
				_caja_en(verts, normals, cols, Vector3(pp.x, yp + 0.75, pp.y), Vector3(0.09, 1.5, 0.09), col_verja, 0.0)
			for nivel in [0.62, 1.32]:
				var y1: float = _altura_terreno(a.x, a.y) + nivel
				var y2: float = _altura_terreno(b.x, b.y) + nivel
				if i == i_largo:
					var mid := (a + b) * 0.5
					var ym: float = _altura_terreno(mid.x, mid.y) + nivel
					var g1 := mid - dir * 2.6
					var g2 := mid + dir * 2.6
					_viga(verts, normals, cols, Vector3(a.x, y1, a.y), Vector3(g1.x, ym, g1.y), dir, 0.05, 0.05, col_verja)
					_viga(verts, normals, cols, Vector3(g2.x, ym, g2.y), Vector3(b.x, y2, b.y), dir, 0.05, 0.05, col_verja)
				else:
					_viga(verts, normals, cols, Vector3(a.x, y1, a.y), Vector3(b.x, y2, b.y), dir, 0.05, 0.05, col_verja)
		# El letrero con el nombre sobre la puerta (la del lado
		# largo): dos postes en la línea de la verja y un panel
		# azul institucional, como los de los colegios de verdad.
		# El panel va en esta malla fundida; el texto, por el
		# sistema de rótulos (blanco sobre el panel).
		var ga: Vector2 = poly[i_largo]
		var gb: Vector2 = poly[(i_largo + 1) % poly.size()]
		var gmid := (ga + gb) * 0.5
		var gdir := (gb - ga).normalized()
		var gnorm := Vector2(-gdir.y, gdir.x)
		var centro_col := Vector2(float(col["c"][0]), float(col["c"][1]))
		if gnorm.dot(gmid - centro_col) < 0.0:
			gnorm = -gnorm
		var gy := _altura_terreno(gmid.x, gmid.y)
		var nombre_col := String(col["n"])
		var ancho_panel := clampf(float(nombre_col.length()) * 0.21, 5.4, 8.6)
		var rot_panel := atan2(-gdir.y, gdir.x)
		for lado_p in [-1.0, 1.0]:
			var pp2: Vector2 = gmid + gdir * (ancho_panel * 0.5 - 0.25) * lado_p
			_caja_en(verts, normals, cols, Vector3(pp2.x, _altura_terreno(pp2.x, pp2.y) + 1.52, pp2.y), Vector3(0.15, 3.04, 0.15), col_verja, 0.0)
		_caja_en(verts, normals, cols, Vector3(gmid.x, gy + 2.55, gmid.y), Vector3(ancho_panel, 0.95, 0.10), Color(0.14, 0.31, 0.53), rot_panel)
		_caja_en(verts, normals, cols, Vector3(gmid.x, gy + 3.06, gmid.y), Vector3(ancho_panel, 0.09, 0.11), Color(0.85, 0.88, 0.90), rot_panel)
		var pos_rot := gmid + gnorm * 0.12
		rotulos_col.append({"n": nombre_col, "h": gnorm, "w": ancho_panel, "g": 3.5, "p": Vector3(pos_rot.x, gy + 2.55, pos_rot.y)})
		_colegios_puertas[nombre_col] = {"pos": Vector3(gmid.x, gy, gmid.y), "n": gnorm, "dir": gdir}
		# El mismo nombre, en grande, sobre la fachada del
		# edificio principal: en los campus grandes la puerta
		# queda a mas de 100 m del edificio y el colegio parecia
		# no tener cartel (caso Alcaste, senalado por Jon).
		if idx_col < fachadas_todas.size() and fachadas_todas[idx_col] != null:
			var fa: Dictionary = fachadas_todas[idx_col]
			var fx := float(fa["x"])
			var fz := float(fa["z"])
			var fn := Vector2(float(fa["nx"]), float(fa["nz"]))
			var fdir := Vector2(-fn.y, fn.x)
			var fgy := _altura_terreno(fx, fz)
			var ancho_f := clampf(float(nombre_col.length()) * 0.30, 6.0, 12.0)
			# El cartel corona la fachada: su centro va justo
			# bajo la cornisa (plantas x 3 m menos el medio
			# panel), no a media pared — en los campus grandes
			# a media altura no se veia (Alcaste, Jon 2026-11-24).
			var alto_f := clampf(float(fa["plantas"]) * M_POR_PLANTA - 0.75, 2.0, 40.0)
			var rot_f := atan2(-fdir.y, fdir.x)
			var cen_f := Vector2(fx, fz) + fn * 0.18
			_caja_en(verts, normals, cols, Vector3(cen_f.x, fgy + alto_f, cen_f.y), Vector3(ancho_f, 1.1, 0.12), Color(0.14, 0.31, 0.53), rot_f)
			_caja_en(verts, normals, cols, Vector3(cen_f.x, fgy + alto_f + 0.60, cen_f.y), Vector3(ancho_f, 0.09, 0.13), Color(0.85, 0.88, 0.90), rot_f)
			var pos_f := cen_f + fn * 0.16
			rotulos_col.append({"n": nombre_col, "h": fn, "w": ancho_f, "g": 3.5, "p": Vector3(pos_f.x, fgy + alto_f, pos_f.y)})
			n_fach += 1
		var hechas: Array = []
		if idx_col < pistas_todas.size():
			for mp in pistas_todas[idx_col]:
				hechas.append(Vector2(float(mp[0]), float(mp[1])))
		for cand in hechas:
			var yp2 := _altura_terreno(cand.x, cand.y)
			_suelo(verts, normals, cols, cand.x, cand.y, yp2 + 0.09, 24, 15, Color(0.30, 0.42, 0.62))
			_suelo(verts, normals, cols, cand.x, cand.y, yp2 + 0.11, 0.3, 15, lin2)
			_suelo(verts, normals, cols, cand.x - 12, cand.y, yp2 + 0.11, 0.3, 15, lin2)
			_suelo(verts, normals, cols, cand.x + 12, cand.y, yp2 + 0.11, 0.3, 15, lin2)
			_suelo(verts, normals, cols, cand.x, cand.y - 7.5, yp2 + 0.11, 24, 0.3, lin2)
			_suelo(verts, normals, cols, cand.x, cand.y + 7.5, yp2 + 0.11, 24, 0.3, lin2)
			for lado in [-1.0, 1.0]:
				var gx3: float = cand.x + 12.0 * lado
				_caja_en(verts, normals, cols, Vector3(gx3, yp2 + 1.0, cand.y - 0.9), Vector3(0.08, 2.0, 0.08), lin2, 0.0)
				_caja_en(verts, normals, cols, Vector3(gx3, yp2 + 1.0, cand.y + 0.9), Vector3(0.08, 2.0, 0.08), lin2, 0.0)
				_caja_en(verts, normals, cols, Vector3(gx3, yp2 + 1.95, cand.y), Vector3(0.08, 0.08, 1.9), lin2, 0.0)
			n_pistas += 1
	_rotulos_datos["colegios"] = rotulos_col
	var malla := _malla_de(verts, normals, cols, Color.WHITE)
	add_child(malla)
	print("COLEGIOS_OK n=", datos["colegios"].size(), " pistas=", n_pistas, " letreros=", rotulos_col.size(), " fachadas=", n_fach)

func _puentes_medida() -> void:
	# Tanda 3 de los 50: los dos puentes históricos a medida sobre la
	# base genérica (el resto de puentes conserva el tablero de piedra).
	if _puentes.is_empty():
		return
	var piedra: Dictionary = {}
	var hierro: Dictionary = {}
	var dp := 1.0e9
	var dh := 1.0e9
	for pu in _puentes:
		var c: Vector2 = (Vector2(pu["a"]) + Vector2(pu["b"])) * 0.5
		var d1 := c.distance_to(Vector2(-89.0, -361.0))
		if d1 < dp:
			dp = d1
			piedra = pu
		var d2 := c.distance_to(Vector2(-352.0, -427.0))
		if d2 < dh:
			dh = d2
			hierro = pu
		# El nombre de la calle manda sobre la distancia
		if String(pu.get("n", "")) == "Puente de Piedra":
			piedra = pu
			dp = 0.0
		elif String(pu.get("n", "")) == "Puente de Hierro":
			hierro = pu
			dh = 0.0
	var sagasta: Dictionary = {}
	var pasarela: Dictionary = {}
	var pasos_ra: Array = []
	for pu in _puentes:
		match String(pu.get("n", "")):
			"Puente de Práxedes Mateo Sagasta":
				sagasta = pu
			"Pasarela del Ebro":
				pasarela = pu
			"República Argentina (ferrocarril)":
				pasos_ra.append(pu)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	if dp < 60.0 and not piedra.is_empty():
		_puente_piedra(verts, normals, cols, piedra)
		print("PUENTE_MEDIDA_OK piedra d=", int(dp))
	if dh < 60.0 and not hierro.is_empty() and hierro != piedra:
		_puente_hierro(verts, normals, cols, hierro)
		print("PUENTE_MEDIDA_OK hierro d=", int(dh))
	if not sagasta.is_empty():
		_puente_sagasta(verts, normals, cols, sagasta)
		print("PUENTE_MEDIDA_OK sagasta")
	if not pasarela.is_empty():
		_puente_pasarela(verts, normals, cols, pasarela)
		print("PUENTE_MEDIDA_OK pasarela")
	if not pasos_ra.is_empty():
		for pu_ra in pasos_ra:
			_paso_rep_argentina(verts, normals, cols, pu_ra)
		print("PUENTE_MEDIDA_OK rep_argentina tramos=", pasos_ra.size())
	if verts.size() > 0:
		add_child(_malla_de(verts, normals, cols, Color.WHITE))

func _puente_piedra(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, pu: Dictionary) -> void:
	# Los arcos del Puente de Piedra: en cada vano entre pilas, el
	# muro de enjuta baja desde el tablero hasta la curva del arco,
	# con su banda de arquivolta en piedra más oscura.
	var a: Vector2 = pu["a"]
	var b: Vector2 = pu["b"]
	var dir: Vector2 = (b - a).normalized()
	var n2 := Vector2(-dir.y, dir.x)
	var largo := a.distance_to(b)
	var pasos := int(ceil(largo / 6.0))
	var piedra := Color(0.60, 0.53, 0.42)
	var osc := Color(0.48, 0.41, 0.32)
	var estaciones: Array = []
	for s in range(0, pasos, 3):
		estaciones.append(s)
	if estaciones[-1] != pasos:
		estaciones.append(pasos)
	for e in range(estaciones.size() - 1):
		var s0: int = estaciones[e]
		var s1: int = estaciones[e + 1]
		for lado in [-1.0, 1.0]:
			var lat: float = 6.6 * lado
			var ant_t: Vector3
			var ant_b: Vector3
			var ant_at: Vector3
			var ant_ab: Vector3
			for k in range(7):
				var tt := float(s0 + (s1 - s0) * k / 6) / float(pasos)
				var pc: Vector2 = a.lerp(b, tt)
				var yt := _y_tablero(pu, pc) - 1.25
				var y_arc := yt - 4.6 + 3.5 * sin(PI * float(k) / 6.0)
				var base: Vector2 = pc + n2 * lat
				var p_t := Vector3(base.x, yt, base.y)
				var p_b := Vector3(base.x, y_arc, base.y)
				var base2: Vector2 = pc + n2 * (lat + 0.28 * lado)
				var p_at := Vector3(base2.x, y_arc + 0.85, base2.y)
				var p_ab := Vector3(base2.x, y_arc - 0.15, base2.y)
				if k > 0:
					_tri(verts, normals, cols, ant_t, p_t, p_b, false, piedra)
					_tri(verts, normals, cols, ant_t, p_b, ant_b, false, piedra)
					_tri(verts, normals, cols, ant_ab, p_ab, p_at, false, osc)
					_tri(verts, normals, cols, ant_ab, p_at, ant_at, false, osc)
				ant_t = p_t
				ant_b = p_b
				ant_at = p_at
				ant_ab = p_ab

func _puente_hierro(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, pu: Dictionary) -> void:
	# El Puente de Hierro de verdad: dos cerchas de celosia TUPIDA
	# (cruces en cada panel de 3 m), cordones paralelos, porticos
	# de entrada y las aceras voladas con barandilla fuera.
	var a: Vector2 = pu["a"]
	var b: Vector2 = pu["b"]
	var dir: Vector2 = (b - a).normalized()
	var n2 := Vector2(-dir.y, dir.x)
	var rot := atan2(dir.x, dir.y)
	var largo := a.distance_to(b)
	var pasos := int(ceil(largo / 3.0))
	var verde := Color(0.13, 0.38, 0.26)
	var verde_o := Color(0.09, 0.28, 0.19)
	for lado in [-1.0, 1.0]:
		var lat: float = 5.55 * lado
		var tops: Array = []
		var bots: Array = []
		for s in range(pasos + 1):
			var tt := float(s) / float(pasos)
			var pc: Vector2 = a.lerp(b, tt)
			var yt := _y_tablero(pu, pc)
			var base: Vector2 = pc + n2 * lat
			bots.append(Vector3(base.x, yt + 0.90, base.y))
			tops.append(Vector3(base.x, yt + 5.90, base.y))
		for s in range(pasos + 1):
			_viga(verts, normals, cols, bots[s], tops[s], n2, 0.20, 0.20, verde)
			if s < pasos:
				_viga(verts, normals, cols, bots[s], bots[s + 1], n2, 0.30, 0.45, verde)
				_viga(verts, normals, cols, tops[s], tops[s + 1], n2, 0.28, 0.40, verde)
				_viga(verts, normals, cols, bots[s], tops[s + 1], n2, 0.11, 0.11, verde_o)
				_viga(verts, normals, cols, tops[s], bots[s + 1], n2, 0.11, 0.11, verde_o)
		for s in range(pasos):
			var pc2: Vector2 = a.lerp(b, (float(s) + 0.5) / float(pasos))
			var yt2 := _y_tablero(pu, pc2)
			var lp: Vector2 = pc2 + n2 * (6.45 * lado)
			_caja_en(verts, normals, cols, Vector3(lp.x, yt2 + 0.02, lp.y), Vector3(1.9, 0.10, largo / pasos + 0.1), Color(0.45, 0.44, 0.42), rot)
		for s in range(pasos + 1):
			var pc3: Vector2 = a.lerp(b, float(s) / float(pasos))
			var yt3 := _y_tablero(pu, pc3)
			var lp3: Vector2 = pc3 + n2 * (7.30 * lado)
			_caja_en(verts, normals, cols, Vector3(lp3.x, yt3 + 0.55, lp3.y), Vector3(0.07, 1.1, 0.07), verde_o, 0.0)
			if s < pasos:
				var pc4: Vector2 = a.lerp(b, (float(s) + 0.5) / float(pasos))
				var yt4 := _y_tablero(pu, pc4)
				var lp4: Vector2 = pc4 + n2 * (7.30 * lado)
				_caja_en(verts, normals, cols, Vector3(lp4.x, yt4 + 1.08, lp4.y), Vector3(0.07, 0.09, largo / pasos + 0.1), verde_o, rot)
	for tt in [0.0, 1.0]:
		var pc: Vector2 = a.lerp(b, tt)
		var yt := _y_tablero(pu, pc)
		var p1: Vector2 = pc - n2 * 5.55
		var p2: Vector2 = pc + n2 * 5.55
		_viga(verts, normals, cols, Vector3(p1.x, yt + 5.90, p1.y), Vector3(p2.x, yt + 5.90, p2.y), dir, 0.28, 0.40, verde)
		_viga(verts, normals, cols, Vector3(p1.x, yt + 3.2, p1.y), Vector3(p2.x, yt + 5.90, p2.y), dir, 0.12, 0.12, verde_o)
		_viga(verts, normals, cols, Vector3(p2.x, yt + 3.2, p2.y), Vector3(p1.x, yt + 5.90, p1.y), dir, 0.12, 0.12, verde_o)

func _puente_sagasta(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, pu: Dictionary) -> void:
	# El puente de Sagasta, el de la foto: un gran arco blanco
	# atado en el plano central, pendolas que bajan a los dos
	# bordes del tablero y estribos de hormigon en cuna.
	var a: Vector2 = pu["a"]
	var b: Vector2 = pu["b"]
	var dir: Vector2 = (b - a).normalized()
	var n2 := Vector2(-dir.y, dir.x)
	var rot := atan2(dir.x, dir.y)
	var largo := a.distance_to(b)
	var blanco := Color(0.92, 0.93, 0.94)
	var hormigon := Color(0.78, 0.76, 0.72)
	var pasos := int(ceil(largo / 6.0))
	for s in range(pasos):
		var pc: Vector2 = a.lerp(b, (float(s) + 0.5) / float(pasos))
		var yt := _y_tablero(pu, pc)
		_caja_en(verts, normals, cols, Vector3(pc.x, yt - 0.55, pc.y), Vector3(15.5, 1.0, largo / pasos + 0.12), hormigon, rot)
		for lado in [-1.0, 1.0]:
			var lp: Vector2 = pc + n2 * (7.45 * lado)
			_caja_en(verts, normals, cols, Vector3(lp.x, yt + 0.45, lp.y), Vector3(0.35, 0.9, largo / pasos + 0.12), blanco, rot)
	var y0 := _y_tablero(pu, a)
	var y1 := _y_tablero(pu, b)
	var flecha := 21.0
	var np := 22
	var ant := Vector3.ZERO
	for i in range(np + 1):
		var tt := float(i) / float(np)
		var pc: Vector2 = a.lerp(b, tt)
		var ya := lerpf(y0, y1, tt) + sin(tt * PI) * 0.5
		var p := Vector3(pc.x, ya + 1.2 + flecha * 4.0 * tt * (1.0 - tt), pc.y)
		if i > 0:
			_viga(verts, normals, cols, ant, p, n2, 1.5, 1.9, blanco)
		ant = p
	for i in range(1, np):
		var tt := float(i) / float(np)
		var pc: Vector2 = a.lerp(b, tt)
		var ya := lerpf(y0, y1, tt) + sin(tt * PI) * 0.5
		var y_arco := ya + 1.2 + flecha * 4.0 * tt * (1.0 - tt)
		if y_arco - ya < 3.0:
			continue
		for lado in [-1.0, 1.0]:
			var lp: Vector2 = pc + n2 * (7.1 * lado)
			_viga(verts, normals, cols, Vector3(pc.x, y_arco - 0.6, pc.y), Vector3(lp.x, ya + 0.9, lp.y), n2, 0.14, 0.14, blanco)
	for tt in [0.02, 0.98]:
		var pc: Vector2 = a.lerp(b, tt)
		var yt := _y_tablero(pu, pc)
		var yb := _altura_terreno(pc.x, pc.y) - 1.5
		_caja_en(verts, normals, cols, Vector3(pc.x, (yt + yb) * 0.5, pc.y), Vector3(13.0, yt - yb, 7.0), hormigon, rot)
	for tt in [0.36, 0.64]:
		var pc: Vector2 = a.lerp(b, tt)
		var yt := _y_tablero(pu, pc)
		var yb := _altura_terreno(pc.x, pc.y) - 1.5
		if yt - yb > 3.0:
			_caja_en(verts, normals, cols, Vector3(pc.x, (yt + yb) * 0.5, pc.y), Vector3(10.0, yt - yb, 3.2), hormigon, rot)
	for tt in [0.25, 0.5, 0.75]:
		for lado in [-1.0, 1.0]:
			var lp: Vector2 = a.lerp(b, tt) + n2 * (6.9 * lado)
			var yt := _y_tablero(pu, lp)
			_farola_h(verts, normals, cols, lp.x, yt, lp.y)

func _puente_pasarela(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, pu: Dictionary) -> void:
	# La pasarela peatonal: tablero estrecho de madera, dos arcos
	# laterales blancos rebajados y barandilla fina.
	var a: Vector2 = pu["a"]
	var b: Vector2 = pu["b"]
	var dir: Vector2 = (b - a).normalized()
	var n2 := Vector2(-dir.y, dir.x)
	var rot := atan2(dir.x, dir.y)
	var largo := a.distance_to(b)
	var blanco := Color(0.90, 0.91, 0.92)
	var madera := Color(0.55, 0.42, 0.30)
	var pasos := int(ceil(largo / 5.0))
	for s in range(pasos):
		var pc: Vector2 = a.lerp(b, (float(s) + 0.5) / float(pasos))
		var yt := _y_tablero(pu, pc)
		_caja_en(verts, normals, cols, Vector3(pc.x, yt - 0.18, pc.y), Vector3(4.6, 0.32, largo / pasos + 0.1), madera, rot)
	for lado in [-1.0, 1.0]:
		var ant := Vector3.ZERO
		var np2 := 16
		for i in range(np2 + 1):
			var tt := float(i) / float(np2)
			var pc: Vector2 = a.lerp(b, tt)
			var yt := _y_tablero(pu, pc)
			var lp: Vector2 = pc + n2 * (2.25 * lado)
			var p := Vector3(lp.x, yt + 0.4 + 3.4 * (1.0 - pow(2.0 * tt - 1.0, 2.0)), lp.y)
			if i > 0:
				_viga(verts, normals, cols, ant, p, n2, 0.16, 0.22, blanco)
			ant = p
		for s in range(pasos + 1):
			var pc2: Vector2 = a.lerp(b, float(s) / float(pasos))
			var yt2 := _y_tablero(pu, pc2)
			var lp2: Vector2 = pc2 + n2 * (2.25 * lado)
			_caja_en(verts, normals, cols, Vector3(lp2.x, yt2 + 0.55, lp2.y), Vector3(0.06, 1.1, 0.06), blanco, 0.0)
	var pc3: Vector2 = a.lerp(b, 0.5)
	var yt3 := _y_tablero(pu, pc3)
	var yb3 := _altura_terreno(pc3.x, pc3.y) - 1.5
	_caja_en(verts, normals, cols, Vector3(pc3.x, (yt3 + yb3) * 0.5, pc3.y), Vector3(3.4, yt3 - yb3, 1.6), Color(0.75, 0.73, 0.70), rot)

func _paso_rep_argentina(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray, pu: Dictionary) -> void:
	# Los muros del paso elevado de Republica Argentina: pretiles
	# a ambos lados y faldones de hormigon que cierran el hueco
	# sobre las vias del tren.
	var a: Vector2 = pu["a"]
	var b: Vector2 = pu["b"]
	var dir: Vector2 = (b - a).normalized()
	var n2 := Vector2(-dir.y, dir.x)
	var rot := atan2(dir.x, dir.y)
	var largo := a.distance_to(b)
	var hormigon := Color(0.72, 0.70, 0.66)
	var pasos := int(ceil(largo / 6.0))
	for s in range(pasos):
		var tt := (float(s) + 0.5) / float(pasos)
		var pc: Vector2 = a.lerp(b, tt)
		var yt := _y_tablero(pu, pc)
		var yb := _altura_terreno(pc.x, pc.y) - 0.4
		var semi_ra := float(pu["ancho"]) * 0.5
		for lado in [-1.0, 1.0]:
			var lp: Vector2 = pc + n2 * ((semi_ra - 0.2) * lado)
			_caja_en(verts, normals, cols, Vector3(lp.x, yt + 0.5, lp.y), Vector3(0.35, 1.0, largo / pasos + 0.12), hormigon, rot)
			var lp2: Vector2 = pc + n2 * ((semi_ra - 0.4) * lado)
			_caja_en(verts, normals, cols, Vector3(lp2.x, (yt + yb) * 0.5, lp2.y), Vector3(0.3, yt - yb, largo / pasos + 0.12), hormigon, rot)

func _soportales() -> void:
	# Los soportales de la calle Portales: columnas de piedra cada
	# ~3,8 m a ambos lados y la losa corrida hacia la fachada.
	var pts: Array = []
	for calle in _calles_nombradas:
		if String(calle.get("n", "")) == "Calle Portales":
			pts = calle["p"]
			break
	if pts.size() < 2:
		print("PORTALES_OK columnas=0")
		return
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var piedra := Color(0.78, 0.70, 0.57)
	var piedra_o := Color(0.64, 0.56, 0.44)
	var ncols := 0
	for i in range(pts.size() - 1):
		var a := Vector2(float(pts[i][0]), float(pts[i][1]))
		var b: Vector2 = Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
		var dir: Vector2 = b - a
		var largo := dir.length()
		if largo < 1.0:
			continue
		dir /= largo
		var n2 := Vector2(-dir.y, dir.x)
		var pasos := maxi(int(largo / 3.8), 1)
		for lado in [-1.0, 1.0]:
			var off: float = 3.4 * lado
			var ant: Vector3
			for s in range(pasos + 1):
				var pc: Vector2 = a + dir * (largo * float(s) / float(pasos)) + n2 * off
				var y := _altura(pc.x, pc.y)
				_caja_en(verts, normals, cols, Vector3(pc.x, y + 1.7, pc.y), Vector3(0.36, 3.4, 0.36), piedra, 0.0)
				ncols += 1
				var pb: Vector2 = pc + n2 * (1.3 * lado)
				var top := Vector3(pb.x, y + 3.55, pb.y)
				if s > 0:
					_viga(verts, normals, cols, ant, top, n2, 2.6, 0.35, piedra_o)
				ant = top
	if verts.size() > 0:
		add_child(_malla_de(verts, normals, cols, Color.WHITE))
	print("PORTALES_OK columnas=", ncols)

func _probar_coches() -> void:
	# Estado limpio: la partida guardada no debe contaminar la prueba
	_mis_coches = [{"id": 0, "danio": 0, "motor": 0, "frenos": 0}]
	_coche_activo = 0
	_reconstruir_coche()
	_dinero = 20000
	var ok1 := _comprar_coche(4)
	var ok2 := _comprar_coche(9)
	print("PRUEBA_COMPRAS san_mateo=", ok1, " fardachon=", ok2, " coches=", _mis_coches.size(), " dinero=", _dinero)
	var tiempos := {}
	# La medición sigue la avenida real por el grafo (La Paz se curva hacia
	# el norte a partir de x≈730; en línea recta a z=365 se sale de la calle)
	var na2: Vector2 = _nodos[_nodo_cercano(Vector2(700, 330))]
	var nb2: Vector2 = _nodos[_nodo_cercano(Vector2(1150, 390))]
	var ruta_med := _calcular_ruta(Vector3(na2.x, 0, na2.y), Vector3(nb2.x, 0, nb2.y))
	for par in [[0, "Rioja"], [2, "Fardachon"]]:
		_usar_coche(int(par[0]))
		_coche.position = ruta_med[0]
		_coche.position.y = _altura(_coche.position.x, _coche.position.z)
		_coche_dir = atan2(ruta_med[1].x - ruta_med[0].x, ruta_med[1].z - ruta_med[0].z)
		_coche.rotation.y = _coche_dir
		_en_coche = true
		_coche_vel = 0.0
		_acel_forzado = 1.0
		var t := 0.0
		var recorrido := 0.0
		var prev := _coche.position
		var idx_r := 1
		while recorrido < 150.0 and t < 40.0:
			await get_tree().physics_frame
			t += get_physics_process_delta_time()
			recorrido += _coche.position.distance_to(prev)
			prev = _coche.position
			if idx_r < ruta_med.size():
				var wp: Vector3 = ruta_med[idx_r]
				if Vector2(_coche.position.x - wp.x, _coche.position.z - wp.z).length() < 5.0:
					idx_r += 1
				if idx_r < ruta_med.size():
					var wp2: Vector3 = ruta_med[idx_r]
					_coche_dir = atan2(wp2.x - _coche.position.x, wp2.z - _coche.position.z)
		tiempos[par[1]] = t
		print("MEDICION ", par[1], " 150 m en ", snappedf(t, 0.01), " s, vel=", snappedf(_coche_vel, 0.1))
		_acel_forzado = -1.0
		_en_coche = false
		_coche_vel = 0.0
	_mis_coches[_coche_activo]["danio"] = 55
	var antes_d := _dinero
	var okr := _reparar_coche()
	print("PRUEBA_REPARAR ok=", okr, " coste=", antes_d - _dinero, " danio=", int(_mis_coches[_coche_activo]["danio"]))
	var okm := _mejorar_coche("motor")
	print("PRUEBA_MEJORA ok=", okm, " nivel=", int(_mis_coches[_coche_activo]["motor"]))
	var antes_v := _dinero
	var okv := _vender_coche(1)
	print("PRUEBA_VENTA ok=", okv, " cobrado=", _dinero - antes_v, " coches=", _mis_coches.size())
	var pasa: bool = ok1 and ok2 and okr and okm and okv and float(tiempos["Fardachon"]) < float(tiempos["Rioja"])
	print("COCHES_PRUEBA_OK pasa=", pasa)
	get_tree().quit()

func _probar_encuentro() -> void:
	# La persona del encuentro tiene que SEGUIR al jugador andando y el
	# encuentro debe cobrarse al llegar al destino.
	_lanzar_encuentro()
	_dlg_abierto = false
	_enc_aceptar()
	# Destino lejano y fijo, para que la llegada no salte durante el paseo
	_enc["dest"] = Vector3(400, 0, 400)
	_hist_fijar(Vector3(400, 0, 400), "Encuentro · prueba")
	var raiz: Node3D = _enc["nodo"]
	var p0 := Vector2(raiz.position.x, raiz.position.z)
	var frames := 0
	while frames < 300:
		_jugador.position += Vector3(5.0 / 60.0, 0, 0)
		_jugador.position.y = _altura(_jugador.position.x, _jugador.position.z) + 0.95
		await get_tree().physics_frame
		frames += 1
	var p1 := Vector2(raiz.position.x, raiz.position.z)
	var dist_final := Vector2(_jugador.position.x, _jugador.position.z).distance_to(p1)
	var siguio := p1.distance_to(p0) > 12.0 and dist_final < 3.2
	# En coche: se monta al subir tú, se baja al bajar tú, y la
	# llegada en coche con él dentro también cobra.
	_coche.position = _jugador.position + Vector3(1.5, 0, 0)
	_coche.position.y = _altura(_coche.position.x, _coche.position.z) + 0.55
	_alternar_coche()
	var monto := _en_coche and bool(_enc.get("en_coche", false)) and not raiz.visible
	_alternar_coche()
	var bajo := not _en_coche and not bool(_enc.get("en_coche", false)) and raiz.visible
	_alternar_coche()
	var dinero0 := _dinero
	_coche.position = Vector3(_destino_libre.x, _altura(_destino_libre.x, _destino_libre.z) + 0.55, _destino_libre.z)
	for i in 90:
		await get_tree().physics_frame
	var cobro := _enc.is_empty() and _dinero > dinero0
	print("ENCUENTRO_PRUEBA_OK siguio=", siguio, " dist=", dist_final, " cobro=", cobro, " monto=", monto, " bajo=", bajo)
	get_tree().quit()

func _probar_controles() -> void:
	# Controles relativos a pie: A/D GIRAN (no desplazan), W anda hacia
	# donde mira el personaje y S NO retrocede: se da media vuelta y
	# anda en sentido contrario, como una persona.
	if _ayuda_abierta:
		_cerrar_ayuda()
	# En plena Gran Vía, sin paredes cerca: en el Espolón la
	# caminata de prueba resbalaba por un borde y el avance
	# salía «false» sin que el control fallara.
	_jugador.position = Vector3(-500, _altura(-500, 173) + 0.95, 173)
	_dir_jugador = 0.0
	_jugador.rotation.y = 0.0
	var pulsar := func(codigo: int, bajar: bool) -> void:
		var ev := InputEventKey.new()
		ev.keycode = codigo
		ev.pressed = bajar
		Input.parse_input_event(ev)
	pulsar.call(KEY_A, true)
	for i in 30:
		await get_tree().physics_frame
	pulsar.call(KEY_A, false)
	var giro_ok := absf(_dir_jugador) > 0.9
	var frente := Vector3(sin(_dir_jugador), 0, cos(_dir_jugador))
	var pos0 := _jugador.position
	pulsar.call(KEY_W, true)
	for i in 60:
		await get_tree().physics_frame
	pulsar.call(KEY_W, false)
	var desp := _jugador.position - pos0
	desp.y = 0
	var av_ok := desp.dot(frente) > 4.0 and absf(desp.dot(Vector3(frente.z, 0, -frente.x))) < 1.2
	var rumbo_antes := _dir_jugador
	var pos1 := _jugador.position
	pulsar.call(KEY_S, true)
	for i in 60:
		await get_tree().physics_frame
	pulsar.call(KEY_S, false)
	var desp2 := _jugador.position - pos1
	desp2.y = 0
	var frente2 := Vector3(sin(_dir_jugador), 0, cos(_dir_jugador))
	var re_ok := absf(absf(wrapf(_dir_jugador - rumbo_antes, -PI, PI)) - PI) < 0.3 and desp2.dot(frente2) > 2.0
	print("CONTROLES_OK giro=", giro_ok, " avance=", av_ok, " retro=", re_ok)
	get_tree().quit()

func _probar_interiores() -> void:
	_empleo_desbloqueado = false
	var entradas := 0
	for id in ["piso", "ayuntamiento", "gimnasio", "peluqueria", "tienda", "panaderia", "decathlon"]:
		var f: Vector3 = _interiores[id]["fuera"]
		_jugador.position = f + Vector3(0, 0.95, 0)
		_entrar_interior(id)
		if _en_interior == id:
			entradas += 1
		_salir_interior()
	print("PRUEBA_INTERIORES entradas=", entradas, " empleo=", _empleo_desbloqueado)
	_entrar_interior("piso")
	_minutos = 1350.0
	var dia0 := _dia
	_dormir()
	print("PRUEBA_DORMIR dia ", dia0, "->", _dia, " minutos=", int(_minutos))
	_salir_interior()
	_entrar_interior("peluqueria")
	var p0 := _pelo_idx
	_desde_tel_pelo()
	_salir_interior()
	_entrar_interior("tienda")
	var c0 := _camisa_idx
	_desde_tel_camiseta()
	_salir_interior()
	var dinero0 := _dinero
	_entrar_interior("panaderia")
	_comprar_pan()
	_salir_interior()
	_entrar_interior("piso")
	var cen_p: Vector3 = _interiores["piso"]["centro"]
	var tam_p: Vector2 = _interiores["piso"]["tam"]
	_jugador.position = cen_p + Vector3(0, 0.95, tam_p.y / 2.0 + 2.0)
	_comprobar_salida_interior()
	var salio_andando := _en_interior == "" and absf(_jugador.position.x) < 2700.0
	var pasa: bool = entradas == 7 and _empleo_desbloqueado and _dia == dia0 + 1 and int(_minutos) == 480 and _pelo_idx != p0 and _camisa_idx != c0 and _dinero == dinero0 - 2 and salio_andando
	# Tenderos: están en las tres tiendas; la panadera ofrece la barra
	# por diálogo al acercarte y la cobra (2 €).
	_dinero = 50
	_entrar_interior("panaderia")
	var hay_panadera: bool = _interiores["panaderia"].has("tendero")
	var traiz: Node3D = _interiores["panaderia"]["tendero"]
	_jugador.position = traiz.position + Vector3(0, 0, 2.0)
	_actualizar_tenderos(0.016)
	var ofrecio := _dlg_abierto
	var dinero_t := _dinero
	var teclas := false
	if ofrecio:
		# Como el jugador de verdad: bajar la elección con S, subirla
		# con W y confirmar con E (antes E no hacía nada aquí).
		var ev_s := InputEventKey.new()
		ev_s.keycode = KEY_S
		ev_s.pressed = true
		Input.parse_input_event(ev_s)
		await get_tree().process_frame
		var bajo := _dlg_sel == 1
		var ev_w := InputEventKey.new()
		ev_w.keycode = KEY_W
		ev_w.pressed = true
		Input.parse_input_event(ev_w)
		await get_tree().process_frame
		var subio := _dlg_sel == 0
		var ev_e := InputEventKey.new()
		ev_e.keycode = KEY_E
		ev_e.pressed = true
		Input.parse_input_event(ev_e)
		await get_tree().process_frame
		teclas = bajo and subio and not _dlg_abierto
	var cobro_t := _dinero == dinero_t - 2
	_salir_interior()
	var hay_tenderos: bool = _interiores["peluqueria"].has("tendero") and _interiores["tienda"].has("tendero")
	pasa = pasa and hay_panadera and ofrecio and cobro_t and hay_tenderos and teclas
	print("INTERIORES_PRUEBA_OK pasa=", pasa, " tenderos=", hay_tenderos, " ofrecio=", ofrecio, " cobro=", cobro_t, " teclas=", teclas)
	get_tree().quit()

func _capturar_si_toca() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_modo_libre = false  # en modos de captura/prueba la cámara no sigue al jugador
	var nombre := ""
	if args.has("capturar"):
		_cam.look_at_from_position(Vector3(0, 900, 900), Vector3.ZERO, Vector3.UP)
		nombre = "barrio_centro_3d.png"
	elif args.has("probar_radar"):
		if not _radares.is_empty():
			var rp0: Vector3 = _radares[0]
			_en_coche = true
			_coche.position = Vector3(rp0.x, _altura(rp0.x, rp0.z), rp0.z)
			_coche_vel = 15.0
			var antes_r := _dinero
			_comprobar_radares()
			print("RADAR_OK multa=", antes_r - _dinero)
		get_tree().quit()
		return
	elif args.has("capturar_colegio"):
		# La puerta del Colegio Las Gaunas desde la calle: el
		# letrero azul con el nombre sobre la verja.
		var pu_col: Dictionary = _colegios_puertas.get("Colegio Las Gaunas", {})
		if not pu_col.is_empty():
			var gp: Vector3 = pu_col["pos"]
			var gn: Vector2 = pu_col["n"]
			for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, -1)]:
				_construir_tile(_tile_de(Vector2(gp.x, gp.z)) + dt)
			_jugador.position = Vector3(gp.x + gn.x * 6.0, _altura(gp.x + gn.x * 6.0, gp.z + gn.y * 6.0) + 0.95, gp.z + gn.y * 6.0)
			_refrescar_rotulos()
			_cam.look_at_from_position(Vector3(gp.x + gn.x * 8.5, gp.y + 2.0, gp.z + gn.y * 8.5), Vector3(gp.x, gp.y + 2.3, gp.z), Vector3.UP)
		nombre = "colegio.png"
	elif args.has("capturar_alcaste"):
		# El cartel de Alcaste corona la fachada sur de su
		# edificio principal (3 plantas): camara desde el
		# campus, a la altura del letrero, para comprobar que
		# se lee desde el sur como pidio Jon.
		for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
			_construir_tile(_tile_de(Vector2(-661, -1448)) + dt)
		var fn_a := Vector2(-0.56, 0.83)
		var fp_a := Vector2(-661.2, -1448.4)
		_jugador.position = Vector3(fp_a.x + fn_a.x * 22.0, _altura(fp_a.x + fn_a.x * 22.0, fp_a.y + fn_a.y * 22.0) + 0.95, fp_a.y + fn_a.y * 22.0)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(fp_a.x + fn_a.x * 27.0, _altura(fp_a.x, fp_a.y) + 9.4, fp_a.y + fn_a.y * 27.0), Vector3(fp_a.x, _altura(fp_a.x, fp_a.y) + 7.9, fp_a.y), Vector3.UP)
		nombre = "alcaste.png"
	elif args.has("capturar_vuelo"):
		# Vuelo Madrid Manila desde la avenida Republica
		# Argentina (su direccion oficial): el nombre sobre la
		# fachada sur de su edificio mayor.
		for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, -1)]:
			_construir_tile(_tile_de(Vector2(-662, 940)) + dt)
		var fn_v := Vector2(-0.29, 0.96)
		var fp_v := Vector2(-661.9, 940.5)
		_jugador.position = Vector3(fp_v.x + fn_v.x * 13.0, _altura(fp_v.x + fn_v.x * 13.0, fp_v.y + fn_v.y * 13.0) + 0.95, fp_v.y + fn_v.y * 13.0)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(fp_v.x + fn_v.x * 15.0, _altura(fp_v.x, fp_v.y) + 3.2, fp_v.y + fn_v.y * 15.0), Vector3(fp_v.x, _altura(fp_v.x, fp_v.y) + 2.4, fp_v.y), Vector3.UP)
		nombre = "vuelo.png"
	elif args.has("capturar_marianistas"):
		# Marianistas ya existe: parcela, edificios y su
		# nombre en la fachada principal.
		for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, -1)]:
			_construir_tile(_tile_de(Vector2(2217, 1841)) + dt)
		var fn_m := Vector2(0.06, -1.0)
		var fp_m := Vector2(2253.7, 1810.2)
		_jugador.position = Vector3(fp_m.x + fn_m.x * 16.0, _altura(fp_m.x + fn_m.x * 16.0, fp_m.y + fn_m.y * 16.0) + 0.95, fp_m.y + fn_m.y * 16.0)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(fp_m.x + fn_m.x * 18.0, _altura(fp_m.x, fp_m.y) + 3.6, fp_m.y + fn_m.y * 18.0), Vector3(fp_m.x, _altura(fp_m.x, fp_m.y) + 2.6, fp_m.y), Vector3.UP)
		nombre = "marianistas.png"
	elif args.has("capturar_skate"):
		# El skate park de Las Norias con sus 3 chavales en
		# marcha (uno, en el aire).
		for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			_construir_tile(_tile_de(Vector2(-899, -735)) + dt)
		_tiempo = 3.1
		_mover_peatones(0.016)
		var ys_s := _altura(-899, -735)
		_cam.look_at_from_position(Vector3(-899 + 11.5, ys_s + 4.6, -735 + 10.5), Vector3(-899, ys_s + 0.7, -735), Vector3.UP)
		nombre = "skate.png"
	elif args.has("capturar_hospital"):
		# La puerta del Hospital San Pedro: medicos, enfermera
		# con la silla de ruedas y madres con ninos.
		for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			_construir_tile(_tile_de(Vector2(1168, 1768)) + dt)
		_cam.look_at_from_position(Vector3(1168 - 15.0, _altura(1153, 1778) + 4.0, 1768 + 10.0), Vector3(1172, _altura(1172, 1766) + 1.1, 1766), Vector3.UP)
		nombre = "hospital.png"
	elif args.has("capturar_parque"):
		# El Parque Infantil de columpios (677, 1092): antes
		# no habia ni un columpio.
		for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			_construir_tile(_tile_de(Vector2(677, 1092)) + dt)
		_tiempo = 2.4
		_mover_peatones(0.016)
		_cam.look_at_from_position(Vector3(677 + 10.5, _altura(687, 1102) + 4.2, 1092 + 10.5), Vector3(677, _altura(677, 1092) + 0.9, 1092), Vector3.UP)
		nombre = "parque.png"
	elif args.has("capturar_busurbano"):
		# Un autobus urbano de cerca: ruedas redondas,
		# ventanillas con sus pilares y gente sentada dentro.
		var bu0: Dictionary = _buses_urbanos[0]
		var nb0: Node3D = bu0["nodo3d"]
		var tb0 := _tile_de(Vector2(nb0.position.x, nb0.position.z))
		for dxb in [-1, 0, 1]:
			for dyb in [-1, 0, 1]:
				_construir_tile(Vector2i(tb0.x + dxb, tb0.y + dyb))
		var der0 := Vector3(cos(nb0.rotation.y), 0, -sin(nb0.rotation.y))
		var del0 := Vector3(sin(nb0.rotation.y), 0, cos(nb0.rotation.y))
		var ojo0 := nb0.position + der0 * 8.5 + del0 * 4.5 + Vector3(0, 2.1, 0)
		_cam.look_at_from_position(ojo0, nb0.position + Vector3(0, 1.3, 0), Vector3.UP)
		nombre = "busurbano.png"
	elif args.has("capturar_cantabria"):
		# Las ruinas romanas de la cima del Monte Cantabria.
		for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, -1)]:
			_construir_tile(_tile_de(Vector2(1350, -1345)) + dt)
		var gy_c := _altura(1350, -1345)
		_cam.look_at_from_position(Vector3(1350 + 19.0, gy_c + 7.5, -1345 + 17.0), Vector3(1350, gy_c + 1.6, -1345), Vector3.UP)
		nombre = "cantabria.png"
	elif args.has("capturar_cantabria_vista"):
		# La vista de Logrono desde la cima: la niebla suave
		# ya no lo lava todo de naranja.
		for txv in range(3, 8):
			for tzv in range(1, 6):
				_construir_tile(Vector2i(txv, tzv))
		var gy_v := _altura(1320, -1180)
		_jugador.position = Vector3(1320, gy_v + 0.95, -1180)
		_cam.look_at_from_position(Vector3(1320, gy_v + 3.5, -1180), Vector3(0, 12, 300), Vector3.UP)
		nombre = "cantabria_vista.png"
	elif args.has("capturar_corazon"):
		# La Tienda con Corazon (Caritas Chavicar) en Gonzalo
		# de Berceo 17: no estaba en OSM y no existia en el
		# juego; verificada a mano y en directorios.
		for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			_construir_tile(_tile_de(Vector2(-1200, 126)) + dt)
		_jugador.position = Vector3(-1195.5, _altura(-1195.5, 113.8) + 0.95, 113.8)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-1194.2, _altura(-1200, 126) + 2.4, 110.8), Vector3(-1199.7, _altura(-1200, 126) + 3.0, 126.1), Vector3.UP)
		nombre = "corazon.png"
	elif args.has("capturar_protagonistas"):
		# Retrato de familia en el Espolón: los cinco PJ y el
		# jugador en fila, de frente a cámara, sin etiquetas.
		for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			_construir_tile(_tile_de(Vector2(-256, 273)) + dt)
		var centro := Vector3(-256, 0, 268)
		var ids := ["carmen", "paco", "lucia", "elias", "marta"]
		for k in range(ids.size()):
			var pj: Dictionary = _pjs[ids[k]]
			var nodo_p: Node3D = pj["nodo"]
			var px := centro.x + (float(k) - 2.0) * 0.9 - 0.45
			nodo_p.position = Vector3(px, _altura(px, centro.z) + 0.95, centro.z)
			nodo_p.rotation.y = 0.0
			(pj["et"] as Label3D).visible = false
		_jugador.position = Vector3(centro.x + 2.25, _altura(centro.x + 2.25, centro.z) + 0.95, centro.z)
		_jugador.rotation.y = 0.0
		_cam.look_at_from_position(Vector3(centro.x, _altura(centro.x, centro.z + 4.2) + 1.5, centro.z + 4.2), Vector3(centro.x, _altura(centro.x, centro.z) + 0.9, centro.z), Vector3.UP)
		nombre = "protagonistas.png"
	elif args.has("capturar_paso"):
		# El jugador SENTADO en un banco del Espolón: muslos
		# horizontales y espinillas colgando en vertical. Es la
		# prueba del signo de la rodilla (la misma flexión que
		# al andar levanta el talón por detrás).
		for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			_construir_tile(_tile_de(Vector2(-256, 273)) + dt)
		_jugador.position = Vector3(-256, _altura(-256, 268) + 0.47, 268)
		_jugador.rotation.y = 0.0
		_sentado = true
		_pierna_i.rotation.x = -1.25
		_pierna_d.rotation.x = -1.25
		_rodilla_i.rotation.x = 1.2
		_rodilla_d.rotation.x = 1.2
		_brazo_i.rotation.x = -0.15
		_codo_i.rotation.x = -0.5
		_brazo_d.rotation.x = -0.15
		_codo_d.rotation.x = -0.5
		_cam.look_at_from_position(Vector3(-254.4, _altura(-254.4, 270.8) + 1.0, 270.8), Vector3(-256, _altura(-256, 268) + 0.55, 268), Vector3.UP)
		nombre = "paso.png"
	elif args.has("capturar_carretera"):
		# Vista de conducción por la Av. de Madrid hacia el sur: el
		# firme tiene que verse plano, sin cuñas ni altibajos.
		for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, -1), Vector2i(1, -1)]:
			_construir_tile(_tile_de(Vector2(-430, 1450)) + dt)
		_coche.position = Vector3(-428.0, _altura(-428.0, 1440.0), 1440.0)
		_cam.look_at_from_position(Vector3(-431.0, _altura(-431.0, 1408.0) + 4.2, 1408.0), Vector3(-424.0, _altura(-424.0, 1520.0) + 1.0, 1520.0), Vector3.UP)
		nombre = "carretera.png"
	elif args.has("capturar_farmacia"):
		# La esquina de la Farmacia María Cristina (-239.6, 177.2),
		# vista desde el suroeste como en la captura de Jon.
		_construir_tile(_tile_de(Vector2(-240, 177)))
		_construir_tile(_tile_de(Vector2(-240, 177)) + Vector2i(-1, 0))
		var y_f := _altura(-242.0, 176.0)
		_cam.look_at_from_position(Vector3(-242.0, y_f + 42.0, 175.9), Vector3(-242.0, y_f, 176.0), Vector3.UP)
		nombre = "farmacia.png"
	elif args.has("capturar_cebra"):
		# Cruce real de 6 tramos y calle de 10 m (verificado en los datos)
		var nc := Vector2(189, 143)
		_construir_tile(_tile_de(nc))
		var y_n := _altura(nc.x, nc.y)
		_cam.look_at_from_position(Vector3(nc.x + 10, y_n + 6.5, nc.y + 10), Vector3(nc.x, y_n, nc.y), Vector3.UP)
		nombre = "cebra.png"
	elif args.has("capturar_hierro"):
		_construir_tile(_tile_de(Vector2(-341, -264)))
		_construir_tile(_tile_de(Vector2(-341, -330)))
		_jugador.position = Vector3(-341, _altura(-341, -250) + 0.95, -250)
		_dir_jugador = PI
		_jugador.rotation.y = PI
		var des := _jugador.position - Vector3(sin(PI), 0, cos(PI)) * 7.5 + Vector3(0, 4.5, 0)
		var suelo := _altura(des.x, des.z) + 2.0
		if des.y < suelo:
			des.y = suelo
		if des.y < _jugador.position.y + 3.0:
			des.y = _jugador.position.y + 3.0
		print("HIERRO jugador=", _jugador.position, " altura=", _altura(-341, -264), " cam=", des, " choca_cam=", _choca(Vector2(des.x, des.z), 0.3))
		_cam.look_at_from_position(des, _jugador.position + Vector3(0, 1.5, 0), Vector3.UP)
		nombre = "hierro.png"
	elif args.has("capturar_salida"):
		_construir_tile(_tile_de(Vector2(958, 365)))
		_construir_tile(_tile_de(Vector2(744, 204)))
		_coche.position = Vector3(958.5, _altura(958.5, 365.0), 365.0)
		_coche_dir = PI / 2.0
		_coche.rotation.y = _coche_dir
		_en_coche = true
		_jugador.visible = false
		_alternar_coche()
		print("SALIDA en_coche=", _en_coche, " jugador=", _jugador.position, " dentro=", _choca(Vector2(_jugador.position.x, _jugador.position.z), 0.45))
		_modo_libre = true
		for i in 420:
			await get_tree().physics_frame
		print("CAMTRAS cam=", _cam.position, " jug=", _jugador.position, " dir=", _dir_jugador, " cam_dentro=", _choca(Vector2(_cam.position.x, _cam.position.z), 0.3))
		nombre = "salida.png"
	elif args.has("capturar_atrapado"):
		_construir_tile(_tile_de(Vector2(744, 204)))
		_jugador.position = Vector3(744.6, _altura(744.6, 204.6) + 0.95, 204.6)
		print("ATRAPADO dentro=", _choca(Vector2(744.6, 204.6), 0.4))
		for i in 60:
			_mover(_jugador, Vector3(0.8, 0, 0), 0.4)
		print("TRAS_ANDAR jugador=", _jugador.position, " dentro=", _choca(Vector2(_jugador.position.x, _jugador.position.z), 0.4))
		_jugador.position = Vector3(744.6, _altura(744.6, 204.6) + 0.95, 204.6)
		_modo_libre = true
		for i in 90:
			await get_tree().physics_frame
		nombre = "atrapado.png"
	elif args.has("capturar_puente2"):
		_construir_tile(_tile_de(Vector2(-101, -397)))
		var mejor_p: Dictionary = {}
		var mejor_d := 1e18
		for pu in _puentes:
			var mp: Vector2 = (Vector2(pu["a"]) + Vector2(pu["b"])) * 0.5
			if mp.distance_to(Vector2(-101, -397)) < mejor_d:
				mejor_d = mp.distance_to(Vector2(-101, -397))
				mejor_p = pu
		var a_p: Vector2 = mejor_p["a"]
		var b_p: Vector2 = mejor_p["b"]
		var mid: Vector2 = (a_p + b_p) * 0.5
		_coche.position = Vector3(mid.x, _altura(mid.x, mid.y), mid.y)
		_coche_dir = atan2((b_p - a_p).x, (b_p - a_p).y)
		_coche.rotation.y = _coche_dir
		_en_coche = true
		_jugador.visible = false
		print("PUENTE2 coche_y=", _coche.position.y, " terreno_y=", _altura_terreno(mid.x, mid.y), " eje=", a_p, " -> ", b_p)
		_modo_libre = true
		for i in 420:
			await get_tree().physics_frame
		nombre = "puente2.png"
	elif args.has("capturar_borde"):
		_construir_tile(_tile_de(Vector2(958, 365)))
		_coche.position = Vector3(958.5, _altura(958.5, 365.0), 365.0)
		_coche_dir = PI / 2.0
		_coche.rotation.y = _coche_dir
		_en_coche = true
		_jugador.visible = false
		_modo_libre = true
		for i in 420:
			await get_tree().physics_frame
		nombre = "borde.png"
	elif args.has("capturar_chica"):
		_personaje = 1
		_pelo_idx = 5
		var posc := _jugador.position
		_jugador.queue_free()
		_jugador = _crear_personaje()
		add_child(_jugador)
		_jugador.position = posc
		_jugador.rotation.y = 0.0
		_cam.position = _jugador.position + Vector3(1.25, 0.92, -1.30)
		_cam.look_at(_jugador.position + Vector3(0, 0.62, 0), Vector3.UP)
		for i in 12:
			await get_tree().physics_frame
		_cam.position = _jugador.position + Vector3(1.25, 0.92, -1.30)
		_cam.look_at(_jugador.position + Vector3(0, 0.62, 0), Vector3.UP)
		nombre = "chica.png"
	elif args.has("capturar_personaje"):
		_jugador.rotation.y = 0.0
		_cam.position = _jugador.position + Vector3(0.38, 0.86, 1.55)
		_cam.look_at(_jugador.position + Vector3(0, 0.70, 0), Vector3.UP)
		for i in 12:
			await get_tree().physics_frame
		_cam.position = _jugador.position + Vector3(0.38, 0.86, 1.55)
		_cam.look_at(_jugador.position + Vector3(0, 0.70, 0), Vector3.UP)
		nombre = "personaje.png"
	elif args.has("probar_coches"):
		_probar_coches()
		return
	elif args.has("capturar_concesionario"):
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				_construir_tile(Vector2i(5 + dx, 3 + dz))
		var pc: Vector3 = _lugares_coches["concesionario"]
		_jugador.position = pc + Vector3(0, 0.95, 0)
		_dinero = 5000
		_abrir_panel_coches("concesionario")
		_cam.look_at_from_position(pc + Vector3(3.5, 3.4, 6.5), pc + Vector3(0, 1.2, 0), Vector3.UP)
		nombre = "concesionario.png"
	elif args.has("capturar_coches"):
		_dinero = 20000
		_comprar_coche(9)
		_usar_coche(1)
		_construir_tile(Vector2i(5, 3))
		_coche.position = Vector3(950, _altura(950, 365), 365)
		_coche.rotation.y = PI / 2.0
		_jugador.position = _coche.position + Vector3(2.2, 0.95, 1.8)
		_cam.look_at_from_position(_coche.position + Vector3(-7.5, 2.8, 5.0), _coche.position + Vector3(0, 0.7, 0), Vector3.UP)
		nombre = "coches.png"
	elif args.has("probar_interiores"):
		_probar_interiores()
	elif args.has("probar_encuentro"):
		_probar_encuentro()
	elif args.has("probar_controles"):
		_probar_controles()
		return
	elif args.has("probar_bus"):
		_probar_bus()
		return
	elif args.has("probar_bus9"):
		_probar_bus_desde(8)
		return
	elif args.has("probar_bus_b"):
		_probar_bus_b()
		return
	elif args.has("probar_bus_b13"):
		_probar_bus_desde(12, 1)
		return
	elif args.has("probar_furgo"):
		_probar_furgo()
		return
	elif args.has("probar_camalote"):
		_probar_camalote()
		return
	elif args.has("probar_gimnasio"):
		_probar_gimnasio()
		return
	elif args.has("capturar_piso"):
		_entrar_interior("piso")
		var cp: Vector3 = _interiores["piso"]["centro"]
		_cam.look_at_from_position(cp + Vector3(6.8, 3.4, 5.0), cp + Vector3(-1, 0.6, -2.0), Vector3.UP)
		nombre = "piso.png"
	elif args.has("capturar_ayuntamiento"):
		_entrar_interior("ayuntamiento")
		var ca: Vector3 = _interiores["ayuntamiento"]["centro"]
		_cam.look_at_from_position(ca + Vector3(7.6, 3.6, 5.4), ca + Vector3(0, 0.8, -1.2), Vector3.UP)
		nombre = "ayuntamiento.png"
	elif args.has("capturar_peluqueria"):
		_entrar_interior("peluqueria")
		var cq: Vector3 = _interiores["peluqueria"]["centro"]
		_cam.look_at_from_position(cq + Vector3(4.4, 2.8, 3.8), cq + Vector3(-1.2, 0.8, -3.0), Vector3.UP)
		nombre = "peluqueria.png"
	elif args.has("capturar_bus"):
		_empleo_desbloqueado = true
		_iniciar_bus(0)
		_jugador.position = _bus.position + Vector3(5.5, 0, -2.5)
		_jugador.position.y = _altura(_jugador.position.x, _jugador.position.z) + 0.95
		var tb := _tile_de(Vector2(_bus.position.x, _bus.position.z))
		for dxb in [-1, 0, 1]:
			for dyb in [-1, 0, 1]:
				_construir_tile(Vector2i(tb.x + dxb, tb.y + dyb))
		_actualizar_hud()
		_cam.look_at_from_position(_bus.position + Vector3(14.0, 5.0, -12.0), _bus.position + Vector3(0, 1.2, 0), Vector3.UP)
		nombre = "bus.png"
	elif args.has("capturar_camalote"):
		_empleo_desbloqueado = true
		_iniciar_camalote()
		var nm: Node3D = _masas[5]["nodo"]
		_jugador.position = Vector3(nm.position.x + 2.0, 0, nm.position.z + 2.0)
		_jugador.position.y = _altura(_jugador.position.x, _jugador.position.z) + 0.95
		await get_tree().physics_frame
		await get_tree().physics_frame
		_actualizar_hud()
		var tc := _tile_de(Vector2(nm.position.x, nm.position.z))
		for dxc in [-1, 0, 1]:
			for dyc in [-1, 0, 1]:
				_construir_tile(Vector2i(tc.x + dxc, tc.y + dyc))
		_cam.look_at_from_position(nm.position + Vector3(8.0, 3.0, -6.0), nm.position + Vector3(2.5, 0.2, 0), Vector3.UP)
		nombre = "camalote.png"
	elif args.has("capturar_gimnasio"):
		_empleo_desbloqueado = true
		_iniciar_gimnasio()
		_entrar_interior("gimnasio")
		_actualizar_gimnasio(0.0)
		var cg: Vector3 = _interiores["gimnasio"]["centro"]
		_cam.look_at_from_position(cg + Vector3(6.4, 3.2, 5.6), cg + Vector3(-1.5, 0.7, -2.5), Vector3.UP)
		nombre = "gimnasio.png"
	elif args.has("capturar_furgo"):
		_empleo_desbloqueado = true
		_dinero = 20000
		_comprar_coche(10)
		_usar_coche(_mis_coches.size() - 1)
		_iniciar_furgo()
		_construir_tile(Vector2i(5, 3))
		_coche.position = Vector3(950, _altura(950, 365), 365)
		_coche.rotation.y = PI / 2.0
		_jugador.position = _coche.position + Vector3(2.2, 0.95, 1.8)
		_jugador.position.y = _altura(_jugador.position.x, _jugador.position.z) + 0.95
		_actualizar_hud()
		_cam.look_at_from_position(_coche.position + Vector3(-7.5, 2.8, 5.0), _coche.position + Vector3(0, 0.7, 0), Vector3.UP)
		nombre = "furgo.png"
	elif args.has("probar_historia"):
		_probar_historia()
		_probar_protagonistas()
		return
	elif args.has("capturar_historia"):
		_historia_idx = 0
		_hist = {}
		var cpos: Vector3 = _pjs["carmen"]["pos"]
		_jugador.position = Vector3(cpos.x + 0.4, _altura(cpos.x + 0.4, cpos.z + 2.2) + 0.95, cpos.z + 2.2)
		_jugador.rotation.y = atan2(cpos.x - _jugador.position.x, cpos.z - _jugador.position.z)
		var cnod: Node3D = _pjs["carmen"]["nodo"]
		cnod.rotation.y = atan2(_jugador.position.x - cpos.x, _jugador.position.z - cpos.z)
		_hablar_cercano()
		_cam.look_at_from_position(cpos + Vector3(1.2, 1.7, 7.5), cpos + Vector3(0, 0.9, 0), Vector3.UP)
		nombre = "historia.png"
	elif args.has("capturar_encuentro"):
		_jugador.position = Vector3(-252, _altura(-252, 264) + 0.95, 264)
		_dir_jugador = PI
		_jugador.rotation.y = PI
		_lanzar_encuentro()
		_cam.look_at_from_position(_jugador.position + Vector3(2.6, 1.8, -3.6), _jugador.position + Vector3(0, 0.9, -2.0), Vector3.UP)
		nombre = "encuentro.png"
	elif args.has("probar_carreras"):
		_probar_carreras()
	elif args.has("probar_agua"):
		_probar_agua()
	elif args.has("probar_nadar"):
		_probar_nadar()
	elif args.has("probar_piraguas"):
		_probar_piraguas()
	elif args.has("probar_bici"):
		_probar_bici()
	elif args.has("probar_coche"):
		_probar_coche()
	elif args.has("probar_pan"):
		_probar_pan()
	elif args.has("probar_mapa"):
		_probar_mapa()
	elif args.has("probar_multitud"):
		_probar_multitud()
	elif args.has("probar_protagonistas"):
		_probar_protagonistas()
	elif args.has("probar_gallarza"):
		_probar_gallarza()
	elif args.has("probar_buses"):
		_probar_buses()
	elif args.has("probar_lineas"):
		_probar_lineas()
	elif args.has("probar_enamorados"):
		_probar_enamorados()
	elif args.has("probar_ra"):
		_probar_ra()
	elif args.has("probar_decathlon"):
		_probar_decathlon()
		return
	elif args.has("censar"):
		# Censo de objetos para el presupuesto web (incidente 21/22-nov:
		# WebGL deja de dibujar al pasar de ~1.000 objetos en el mapa).
		var pila: Array = [get_tree().root]
		var n_mi := 0
		var n_lab := 0
		var n_nodos := 0
		while not pila.is_empty():
			var nd: Node = pila.pop_back()
			n_nodos += 1
			if nd is MeshInstance3D:
				n_mi += 1
			elif nd is Label3D:
				n_lab += 1
			for h in nd.get_children():
				pila.append(h)
		print("CENSO_OK mesh=", n_mi, " label3d=", n_lab, " nodos=", n_nodos, " peatones=", _peatones.size(), " trafico=", _trafico.size(), " buses=", _buses_urbanos.size())
		get_tree().quit()
		return
	elif args.has("probar_berceo"):
		_probar_berceo()
		return
	elif args.has("medir_circuitos"):
		var refs: Array = [15.0, 15.0, 20.0, 29.0]
		for i in range(CIRCUITOS.size()):
			var circ: Dictionary = CIRCUITOS[i]
			var cpsm: Array = []
			for k in circ["cps"]:
				cpsm.append(_carr_punto(String(k)))
			var rutam := _carr_ruta(cpsm)
			var dummy := Node3D.new()
			add_child(dummy)
			var p_ini := _punto_en_ruta(rutam, 0.0)
			dummy.position = Vector3(p_ini.x, 0, p_ini.y)
			var p_dir := _punto_en_ruta(rutam, 20.0)
			dummy.rotation.y = atan2(p_dir.x - p_ini.x, p_dir.y - p_ini.y)
			var estm := {"ruta": rutam, "s": 0.0, "vel": 0.0, "vmax": refs[i] * 0.97, "nodo": dummy, "lat": 0.0, "acabado": false, "t_fin": -1.0}
			var pasos := 0
			while not bool(estm["acabado"]) and pasos < 90000:
				_seguir_ruta(estm, 1.0 / 60.0)
				pasos += 1
			print("MEDIR ", String(circ["nombre"]), " ruta=", int(float(rutam["total"])), "m sim=", snappedf(pasos / 60.0, 0.1), "s")
			dummy.queue_free()
		get_tree().quit()
		return
	elif args.has("capturar_carrera"):
		_iniciar_carrera(0, "rivales")
		var fw := Vector3(sin(_coche_dir), 0, cos(_coche_dir))
		_cam.look_at_from_position(_coche.position + fw * 9.5 + Vector3(0, 2.4, 0) + Vector3(fw.z, 0, -fw.x) * 1.8, _coche.position + Vector3(0, 0.6, 0), Vector3.UP)
		nombre = "carrera.png"
	elif args.has("capturar_carrera2"):
		_iniciar_carrera(0, "rivales")
		var pasos2 := 0
		while float(_carr["yo"]["s"]) < 520.0 and pasos2 < 6000:
			_seguir_ruta(_carr["yo"], 1.0 / 60.0)
			for est2 in _carr["rivales"]:
				_seguir_ruta(est2, 1.0 / 60.0)
			pasos2 += 1
		_coche_dir = _coche.rotation.y
		_carr["fase"] = "corriendo"
		_carr["t0"] = _tiempo - pasos2 / 60.0
		var cps_s2: Array = _carr["ruta"]["cp_s"]
		var cp2 := 1
		while cp2 < cps_s2.size() - 1 and float(_carr["yo"]["s"]) >= float(cps_s2[cp2]):
			cp2 += 1
		_carr["cp"] = cp2
		_fijar_objetivo(Vector3(_carr["cps"][cp2]))
		_actualizar_carrera(0.0)
		_actualizar_hud()
		for ddx in range(-1, 2):
			for ddz in range(-1, 2):
				_construir_tile(_tile_de(Vector2(_coche.position.x, _coche.position.z)) + Vector2i(ddx, ddz))
		var fw2 := Vector3(sin(_coche_dir), 0, cos(_coche_dir))
		_cam.look_at_from_position(_coche.position - fw2 * 10.0 + Vector3(0, 3.6, 0), _coche.position + fw2 * 8.0 + Vector3(0, 0.6, 0), Vector3.UP)
		nombre = "carrera2.png"
	elif args.has("capturar_pendiente"):
		# La calle del Puente de Hierro baja al Ebro y sube la otra orilla:
		# las cintas tienen que seguir la pendiente, no volar ni hundirse.
		for dt in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			_construir_tile(_tile_de(Vector2(-341, -300)) + dt)
		_coche.position = Vector3(-341.0, _altura(-341.0, -208.0), -208.0)
		_coche_dir = PI
		_coche.rotation.y = _coche_dir
		_en_coche = true
		_jugador.visible = false
		_cam.look_at_from_position(Vector3(-352.0, _altura(-352.0, -176.0) + 7.0, -176.0), Vector3(-340.0, _altura(-340.0, -270.0) + 1.0, -270.0), Vector3.UP)
		nombre = "pendiente.png"
	elif args.has("capturar_rotonda"):
		# La rotonda junto a la plaza de toros: el anillo y sus cintas
		# tienen que sentarse sobre el terreno.
		for dt in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			_construir_tile(_tile_de(Vector2(498, -452)) + dt)
		var cr := Vector2(545, -448)
		_cam.look_at_from_position(Vector3(503.0, _altura(503.0, -404.0) + 9.0, -404.0), Vector3(cr.x, _altura(cr.x, cr.y), cr.y), Vector3.UP)
		nombre = "rotonda.png"
	elif args.has("capturar_fachada"):
		# Calle del casco a pie de acera: puertas con número, balcones,
		# zócalos y cornisas de las fachadas nuevas.
		for dt in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			_construir_tile(_tile_de(Vector2(-162, 62)) + dt)
		_cam.look_at_from_position(Vector3(-162.0, _altura(-162.0, 71.0) + 1.8, 71.0), Vector3(-162.0, _altura(-162.0, 59.0) + 5.0, 59.0), Vector3.UP)
		nombre = "fachada.png"
	elif args.has("capturar_portal"):
		# Primer plano del portal 14 de la calle Portales: puerta y número.
		for dt in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			_construir_tile(_tile_de(Vector2(-307, 322)) + dt)
		_cam.look_at_from_position(Vector3(-239.2, _altura(-239.2, 120.8) + 1.7, 120.8), Vector3(-237.5, _altura(-237.5, 117.9) + 2.45, 117.9), Vector3.UP)
		nombre = "portal.png"
	elif args.has("capturar_sananton"):
		# La calle San Antón desde el sur: tiendas a ambos lados
		for dt in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			_construir_tile(_tile_de(Vector2(-320, 560)) + dt)
		_cam.look_at_from_position(Vector3(-316.0, _altura(-316.0, 655.0) + 2.6, 655.0), Vector3(-326.0, _altura(-326.0, 520.0) + 2.2, 520.0), Vector3.UP)
		nombre = "sananton.png"
	elif args.has("capturar_glera"):
		# La Asociación Juvenil Glera (San Antón 9), desde enfrente
		for dt in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			_construir_tile(_tile_de(Vector2(-320, 560)) + dt)
		_jugador.position = Vector3(-326.0, _altura(-326.0, 558.0) + 0.95, 558.0)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-322.5, _altura(-322.5, 552.0) + 1.9, 552.0), Vector3(-313.0, _altura(-313.0, 547.0) + 2.2, 547.0), Vector3.UP)
		nombre = "glera.png"
	elif args.has("capturar_ibiza"):
		# El bar-restaurante Ibiza, en el extremo norte del Espolón
		_jugador.position = Vector3(-260.0, _altura(-260.0, 205.0) + 0.95, 205.0)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-263.5, _altura(-263.5, 203.0) + 2.2, 203.0), Vector3(-268.3, _altura(-268.3, 184.5) + 1.9, 184.5), Vector3.UP)
		nombre = "ibiza.png"
	elif args.has("capturar_gasolinera"):
		# La gasolinera de Las Gaunas (Repsol, Av. de Madrid 25)
		for dt in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			_construir_tile(_tile_de(Vector2(-424, 1553)) + dt)
		_jugador.position = Vector3(-440.0, _altura(-440.0, 1560.0) + 0.95, 1560.0)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-439.0, _altura(-439.0, 1559.0) + 2.3, 1559.0), Vector3(-423.5, _altura(-423.5, 1552.5) + 1.7, 1552.5), Vector3.UP)
		nombre = "gasolinera.png"
	elif args.has("capturar_labrador"):
		# La estatua del Labrador en su glorieta, desde el sur
		_jugador.position = Vector3(-139.0, _altura(-139.0, 512.0) + 0.95, 512.0)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-141.0, _altura(-141.0, 506.0) + 2.4, 506.0), Vector3(-139.4, _altura(-139.4, 487.2) + 2.6, 487.2), Vector3.UP)
		nombre = "labrador.png"
	elif args.has("capturar_kiosco"):
		# El Café Kiosco La Fundación del Parque del Carmen, desde el parque
		for dt in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			_construir_tile(_tile_de(Vector2(24, 630)) + dt)
		_jugador.position = Vector3(38.0, _altura(38.0, 668.0) + 0.95, 668.0)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(57.0, _altura(57.0, 656.0) + 2.0, 656.0), Vector3(45.0, _altura(45.0, 637.0) + 1.7, 637.0), Vector3.UP)
		nombre = "kiosco.png"
	elif args.has("capturar_bartolome"):
		# San Bartolomé y su torre, desde la plaza del sureste
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-67, -22)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-56.0, _altura(-56.0, 6.0) + 2.2, 6.0), Vector3(-70.0, _altura(-70.0, -24.0) + 10.0, -24.0), Vector3.UP)
		nombre = "bartolome.png"
	elif args.has("capturar_palacio"):
		# Santa María de Palacio y su aguja, desde el noreste
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-124, -130)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-78.0, _altura(-78.0, -64.0) + 18.0, -64.0), Vector3(-148.0, _altura(-148.0, -133.0) + 12.0, -133.0), Vector3.UP)
		nombre = "palacio.png"
	elif args.has("capturar_santiago"):
		# Santiago, su plaza, el Juego de la Oca y la Fuente del Peregrino
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-390, -85)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-361.0, _altura(-362.0, -82.0) + 26.0, -81.0), Vector3(-362.0, _altura(-362.0, -82.0) + 0.2, -82.0), Vector3.UP)
		nombre = "santiago.png"
	elif args.has("capturar_revellin"):
		# El Cubo y la muralla del Revellín, desde el sureste
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-604, -9)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-655.0, _altura(-655.0, -60.0) + 9.0, -60.0), Vector3(-604.0, _altura(-604.0, -9.0) + 6.0, -9.0), Vector3.UP)
		nombre = "revellin.png"
	elif args.has("capturar_chapiteles"):
		# El Palacio de los Chapiteles desde la calle Portales
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-78, 51)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-75.0, _altura(-75.0, 68.0) + 3.5, 68.0), Vector3(-75.0, _altura(-75.0, 56.0) + 15.0, 56.0), Vector3.UP)
		nombre = "chapiteles.png"
	elif args.has("capturar_espartero"):
		# El Monumento a Espartero desde el Espolón
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-247, 261)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-226.0, _altura(-226.0, 248.0) + 4.5, 248.0), Vector3(-247.0, _altura(-247.0, 261.0) + 6.0, 261.0), Vector3.UP)
		nombre = "espartero.png"
	elif args.has("capturar_sagasta"):
		# El Instituto Sagasta y la Glorieta del Doctor Zubía
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-4, 150)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(34.0, _altura(34.0, 208.0) + 13.0, 208.0), Vector3(-4.0, _altura(-4.0, 148.0) + 3.0, 148.0), Vector3.UP)
		nombre = "sagasta.png"
	elif args.has("capturar_ayto2"):
		# La torre del reloj del Ayuntamiento
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(261, 64)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(296.0, _altura(296.0, 78.0) + 12.0, 78.0), Vector3(266.0, _altura(266.0, 55.0) + 12.0, 55.0), Vector3.UP)
		nombre = "ayto2.png"
	elif args.has("capturar_breton"):
		# El pórtico del Teatro Bretón desde su calle
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-472, 231)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-472.0, _altura(-472.0, 198.0) + 18.0, 198.0), Vector3(-472.0, _altura(-472.0, 216.0) + 5.0, 216.0), Vector3.UP)
		nombre = "breton.png"
	elif args.has("capturar_sanblas"):
		# La cubierta del Mercado de San Blas
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-363, 144)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-398.0, _altura(-398.0, 182.0) + 16.0, 182.0), Vector3(-363.0, _altura(-363.0, 144.0) + 10.0, 144.0), Vector3.UP)
		nombre = "sanblas.png"
	elif args.has("capturar_museo"):
		# La fachada del Museo de La Rioja a la Plaza de San Agustín
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-510, 140)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-556.5, _altura(-556.5, 137.0) + 2.5, 137.0), Vector3(-547.8, _altura(-547.8, 137.0) + 5.5, 137.0), Vector3.UP)
		nombre = "museo.png"
	elif args.has("capturar_piedra"):
		# Los arcos del Puente de Piedra desde la orilla este
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-89, -361)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-25.0, _altura(-25.0, -300.0) + 3.5, -300.0), Vector3(-80.0, _altura(-80.0, -345.0) + 4.0, -345.0), Vector3.UP)
		nombre = "piedra.png"
	elif args.has("capturar_hierro"):
		# La celosía verde del Puente de Hierro desde el noreste
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-352, -427)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-400.0, _altura(-400.0, -406.0) + 5.0, -406.0), Vector3(-352.0, _altura(-352.0, -428.0) + 6.0, -428.0), Vector3.UP)
		nombre = "hierro.png"
	elif args.has("capturar_casa"):
		# La Casa de las Ciencias desde la ribera
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-234, -446)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-236.0, _altura(-236.0, -398.0) + 3.0, -398.0), Vector3(-236.0, _altura(-236.0, -448.0) + 7.0, -448.0), Vector3.UP)
		nombre = "casa.png"
	elif args.has("capturar_franco"):
		# Franco-Españolas: su puerta y el cartel nuevo de la
		# nave, desde el sureste y cerca (el jugador va alli
		# para que los rotulos se activen).
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-360, -555)) + Vector2i(dx, dy))
		_jugador.position = Vector3(-336.0, _altura(-336.0, -486.0) + 0.95, -486.0)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-324.0, _altura(-324.0, -484.0) + 7.5, -484.0), Vector3(-360.0, _altura(-360.0, -538.0) + 4.6, -538.0), Vector3.UP)
		nombre = "franco.png"
	elif args.has("capturar_nadar"):
		# El jugador nadando a crol en el Ebro, entre los dos
		# puentes: se le deja bracear un par de segundos y se
		# le mira de lado desde la orilla sur.
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-300, -402)) + Vector2i(dx, dy))
		_jugador.position = Vector3(-294.0, _nivel_agua(Vector2(-294.0, -402.0)) + 0.30, -402.0)
		_nadando = true
		_joy_valor = Vector2(-1, 0)
		for i in 50:
			_nadar(1.0 / 30.0)
			_tiempo += 1.0 / 30.0
		_joy_valor = Vector2.ZERO
		var na_n := _nivel_agua(Vector2(_jugador.position.x, _jugador.position.z))
		_cam.look_at_from_position(Vector3(_jugador.position.x + 3.0, na_n + 1.7, _jugador.position.z + 9.0), Vector3(_jugador.position.x, na_n + 0.3, _jugador.position.z), Vector3.UP)
		nombre = "nadar.png"
	elif args.has("capturar_piscina"):
		# La piscina de largos de Las Norias con sus
		# nadadores en las calles, desde el sureste.
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-1167, -862)) + Vector2i(dx, dy))
		_tiempo = 41.0
		for i in 6:
			_mover_peatones(0.1)
		var yp2 := _altura_terreno(-1155.0, -870.0)
		_cam.look_at_from_position(Vector3(-1146.0, yp2 + 7.0, -826.0), Vector3(-1167.0, yp2 + 0.3, -866.0), Vector3.UP)
		nombre = "piscina.png"
	elif args.has("capturar_mapa_labrador"):
		_aceptar_trabajo(0)
		_abrir_mapa()
		_mapa.set("_zoom", 3.5)
		_mapa.set("_centro", Vector2(-350, 350))
		_mapa.queue_redraw()
		nombre = "mapa_labrador.png"
	elif args.has("capturar_ruedas"):
		# Un coche del trafico de cerca: las ruedas tienen que
		# verse redondas, con su buje.
		var coche_r: Node3D = _trafico[0]["nodo3d"]
		_jugador.position = Vector3(coche_r.position.x + 3.0, _altura(coche_r.position.x, coche_r.position.z) + 0.95, coche_r.position.z + 3.0)
		_cam.look_at_from_position(coche_r.position + Vector3(4.2, 1.1, 3.4), coche_r.position + Vector3(0, 0.35, 0), Vector3.UP)
		nombre = "ruedas.png"
	elif args.has("capturar_placas"):
		# La esquina de Avenida Juan XXIII con Doctores
		# Castroviejo: dos placas en el mismo punto, ahora
		# apiladas en vertical y legibles.
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(11, 470)) + Vector2i(dx, dy))
		_jugador.position = Vector3(20.0, _altura(20.0, 458.0) + 0.95, 458.0)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(20.0, _altura(20.0, 458.0) + 2.4, 458.0), Vector3(11.0, _altura_terreno(11.0, 470.0) + 3.1, 470.0), Vector3.UP)
		nombre = "placas.png"
	elif args.has("capturar_enamorados"):
		# La pareja del Parque de los Enamorados andando de la
		# mano, con el cesped y los arboles del parque.
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-2311, 100)) + Vector2i(dx, dy))
		_jugador.position = Vector3(-2311, _altura(-2311, 103) + 0.95, 103)
		for i in 12:
			_mover_peatones(0.1)
		var pos_pj: Vector3 = (_pareja_enamorados["a"]["raiz"] as Node3D).position
		_cam.look_at_from_position(pos_pj + Vector3(-6.0, 2.1, -6.5), pos_pj + Vector3(0, 0.4, 0), Vector3.UP)
		nombre = "enamorados.png"
	elif args.has("capturar_enamorados_banco"):
		# La pareja sentada en el banco del parque.
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-2311, 100)) + Vector2i(dx, dy))
		_jugador.position = Vector3(-2311, _altura(-2311, 103) + 0.95, 103)
		var datos_b := _datos_enamorados()
		var b3: Array = datos_b["bancos"][3]
		var pb := Vector3(float(b3[0]), _altura(float(b3[0]), float(b3[1])), float(b3[1]))
		var frente_b := Vector3(sin(float(b3[2])), 0, cos(float(b3[2])))
		_cam.look_at_from_position(pb + frente_b * 4.2 + Vector3(0, 1.5, 0), pb + Vector3(0, 0.7, 0), Vector3.UP)
		nombre = "enamorados_banco.png"
	elif args.has("capturar_piraguas"):
		# Los piraguistas entre los dos puentes, vistos desde
		# el Puente de Piedra hacia el de Hierro.
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-220, -395)) + Vector2i(dx, dy))
		_jugador.position = Vector3(-150.0, _altura(-150.0, -370.0) + 0.95, -370.0)
		_preparar_piraguas()
		_tiempo = 25.0
		for i in 10:
			_mover_peatones(0.1)
		var pos_pg: Vector3 = (_piraguas[0]["grupo"] as Node3D).position
		_cam.look_at_from_position(pos_pg + Vector3(6.5, 1.9, 5.0), pos_pg + Vector3(0, 0.5, 0), Vector3.UP)
		nombre = "piraguas.png"
	elif args.has("capturar_giro"):
		# Un bus de la L4 rodeando ENTERA la rotonda de su
		# cabecera este (Madre de Dios), a mitad del anillo.
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(2174, -581)) + Vector2i(dx, dy))
		_jugador.position = Vector3(1900.0, _altura(1900.0, -300.0) + 0.95, -300.0)
		var lin_g: Dictionary = _lineas_bus[3]
		var bu_g: Dictionary = _buses_urbanos[0]
		var bus_g: Node3D = bu_g["nodo3d"]
		var anillo_g: Array = lin_g["giro_fin"]
		bu_g["linea"] = 3
		bu_g["parada_t"] = 0.0
		bu_g["espera"] = 99999.0
		bu_g["giro"] = anillo_g
		bu_g["giro_i"] = 6
		bu_g["giro_fin_dir"] = -1
		bu_g["vel_act"] = float(bu_g["vel"])
		var p_ini: Vector2 = anillo_g[6]
		bus_g.position = Vector3(p_ini.x, _altura(p_ini.x, p_ini.y), p_ini.y)
		for i in 12:
			_mover_buses(0.12)
		_cam.look_at_from_position(Vector3(2174 + 55, _altura(2174, -581) + 42, -581 + 75), Vector3(2174, _altura(2174, -581) + 1, -581), Vector3.UP)
		nombre = "giro.png"
	elif args.has("capturar_puerta"):
		# La Puerta del Ebro desde la ribera
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(305, -274)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(332.0, _altura(332.0, -238.0) + 3.0, -238.0), Vector3(305.0, _altura(305.0, -274.0) + 5.0, -274.0), Vector3.UP)
		nombre = "puerta.png"
	elif args.has("capturar_danza"):
		# El Bosque de la Danza en La Ribera
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-120, -430)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-84.0, _altura(-84.0, -394.0) + 17.0, -394.0), Vector3(-120.0, _altura(-120.0, -430.0) + 1.0, -430.0), Vector3.UP)
		nombre = "danza.png"
	elif args.has("capturar_riojanos"):
		# La Fuente de los Riojanos Ilustres
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-824, 253)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-792.0, _altura(-792.0, 288.0) + 4.0, 288.0), Vector3(-824.0, _altura(-824.0, 253.0) + 3.0, 253.0), Vector3.UP)
		nombre = "riojanos.png"
	elif args.has("capturar_portales"):
		# Bajo los soportales de Portales, mirando al oeste
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-230, 78)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-177.0, _altura(-177.0, 65.6) + 2.1, 65.6), Vector3(-265.0, _altura(-265.0, 66.2) + 2.3, 66.2), Vector3.UP)
		nombre = "portales.png"
	elif args.has("capturar_mercado"):
		# La Plaza del Mercado y su fuente, con La Redonda detrás
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-234, 13)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-226.0, _altura(-226.0, 40.0) + 34.0, 40.0), Vector3(-235.0, _altura(-235.0, 11.0) + 0.5, 11.0), Vector3.UP)
		nombre = "mercado.png"
	elif args.has("capturar_calado"):
		# El portal del Calado y sus toneles en Ruavieja
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-216, -140)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-197.0, _altura(-197.0, -123.0) + 2.1, -123.0), Vector3(-217.0, _altura(-217.0, -141.0) + 1.9, -141.0), Vector3.UP)
		nombre = "calado.png"
	elif args.has("capturar_tabacalera"):
		# La Tabacalera y su chimenea, con la plaza del Parlamento
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-565, 40)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-540.0, _altura(-540.0, 108.0) + 36.0, 108.0), Vector3(-582.0, _altura(-582.0, 60.0) + 2.0, 60.0), Vector3.UP)
		nombre = "tabacalera.png"
	elif args.has("capturar_trevijano"):
		# La puerta de las Escuelas Trevijano
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(_tile_de(Vector2(-676, 252)) + Vector2i(dx, dy))
		_cam.look_at_from_position(Vector3(-638.0, _altura(-638.0, 220.0) + 13.0, 220.0), Vector3(-677.0, _altura(-677.0, 253.0) + 1.5, 253.0), Vector3.UP)
		nombre = "trevijano.png"
	elif args.has("capturar_carmen"):
		# Carmen junto al portal de casa, vista desde donde apareces
		var pc: Vector3 = _pjs["carmen"]["pos"]
		print("CARMEN_CAM pos=", pc)
		_cam.look_at_from_position(pc + Vector3(-2.2, 1.8, 2.6), pc + Vector3(0, 1.0, 0), Vector3.UP)
		nombre = "carmen.png"
	elif args.has("capturar_espolon"):
		# La fila de cafeterías del Espolón, desde el paseo
		_cam.look_at_from_position(Vector3(-306.0, _altura(-306.0, 246.0) + 2.4, 246.0), Vector3(-338.0, _altura(-338.0, 246.0) + 1.8, 246.0), Vector3.UP)
		nombre = "espolon.png"
	elif args.has("capturar_palomas"):
		# El anciano y sus palomas en el Espolón
		var pa := _anciano_pos
		_cam.look_at_from_position(Vector3(pa.x + 4.6, _altura(pa.x + 4.6, pa.z + 3.8) + 2.6, pa.z + 3.8), Vector3(pa.x, _altura(pa.x, pa.z) + 0.6, pa.z), Vector3.UP)
		nombre = "palomas.png"
	elif args.has("capturar_digitos"):
		# La cámara se coloca sola: 3 m por delante de la puerta del portal
		# de casa (Miguel Villanueva 1), sobre su normal exterior.
		for dt in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			_construir_tile(_tile_de(Vector2(-307, 322)) + dt)
		var pp := Vector2(-307.2, 322.2)
		var md := 3.0
		var m_a := Vector2.ZERO
		var m_b := Vector2.ZERO
		var m_c := Vector2.ZERO
		var m_p := Vector2.ZERO
		for pl in _poligonos:
			var cen := Vector2.ZERO
			for q in pl:
				cen += q
			cen /= pl.size()
			if cen.distance_squared_to(pp) > 2025.0:
				continue
			for ei in pl.size():
				var ea: Vector2 = pl[ei]
				var eb: Vector2 = pl[(ei + 1) % pl.size()]
				var seg := Geometry2D.get_closest_point_to_segment(pp, ea, eb)
				var dd := seg.distance_to(pp)
				if dd < md:
					md = dd
					m_a = ea
					m_b = eb
					m_c = cen
					m_p = seg
		var de := (m_b - m_a).normalized()
		var n2 := Vector2(-de.y, de.x)
		if n2.dot(m_p - m_c) < 0.0:
			n2 = -n2
		var base_d := _altura_terreno(pp.x, pp.y) - 0.10
		print("DIGITOS_CAM puerta=", m_p, " normal=", n2, " dist=", md)
		_cam.look_at_from_position(Vector3(m_p.x + n2.x * 3.2, base_d + 1.7, m_p.y + n2.y * 3.2), Vector3(m_p.x, base_d + 1.8, m_p.y), Vector3.UP)
		nombre = "digitos.png"
	elif args.has("capturar_tejados"):
		# El casco desde el aire: tejados inclinados entre azoteas planas.
		for dt in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
			_construir_tile(_tile_de(Vector2(-160, 130)) + dt)
		_cam.look_at_from_position(Vector3(-330.0, _altura(-330.0, 300.0) + 150.0, 300.0), Vector3(-140.0, _altura(-140.0, 120.0), 120.0), Vector3.UP)
		nombre = "tejados.png"
	elif args.has("capturar_panaderia"):
		# Dentro de la panadería, frente al mostrador: la panadera ofrece.
		_entrar_interior("panaderia")
		var cen_pb: Vector3 = _interiores["panaderia"]["centro"]
		_jugador.position = cen_pb + Vector3(0, 0.95, -1.2)
		_actualizar_tenderos(0.016)
		_cam.look_at_from_position(cen_pb + Vector3(2.2, 2.0, 1.8), cen_pb + Vector3(0, 1.1, -3.0), Vector3.UP)
		nombre = "panaderia.png"
	elif args.has("capturar_ayuda"):
		# Ventana corta como la de Jon: el panel tiene que caber entero.
		get_window().size = Vector2i(880, 700)
		await get_tree().process_frame
		await get_tree().process_frame
		_abrir_ayuda()
		await get_tree().process_frame
		await get_tree().process_frame
		nombre = "ayuda.png"
	elif args.has("capturar_minimapa"):
		# Regresión del minimapa: conduciendo lejos de donde subiste, el
		# minimapa debe mostrar las calles de donde está el coche
		var destino_mm := Vector3(-256, 0, 273)
		_coche.position = Vector3(destino_mm.x, _altura(destino_mm.x, destino_mm.z), destino_mm.z)
		_coche_dir = 0.6
		_coche.rotation.y = _coche_dir
		_en_coche = true
		_jugador.visible = false
		for ddx2 in range(-1, 2):
			for ddz2 in range(-1, 2):
				_construir_tile(_tile_de(Vector2(destino_mm.x, destino_mm.z)) + Vector2i(ddx2, ddz2))
		_minimapa.call("actualizar", _datos_minimapa())
		_actualizar_hud()
		var fw3 := Vector3(sin(_coche_dir), 0, cos(_coche_dir))
		_cam.look_at_from_position(_coche.position - fw3 * 9.0 + Vector3(0, 3.4, 0), _coche.position + fw3 * 6.0, Vector3.UP)
		nombre = "minimapa.png"
	elif args.has("capturar_bancos"):
		# La fila de bancos de Miguel Villanueva, a pie de calle
		_construir_tile(_tile_de(Vector2(-283, 315)))
		var y_b := _altura(-283, 303)
		_cam.look_at_from_position(Vector3(-283, y_b + 1.9, 309), Vector3(-283, y_b + 2.6, 330), Vector3.UP)
		nombre = "bancos.png"
	elif args.has("capturar_terraza"):
		_construir_tile(_tile_de(Vector2(-326, 67)))
		var y_t := _altura(-306, 67)
		_cam.look_at_from_position(Vector3(-311, y_t + 1.9, 67), Vector3(-331, y_t + 1.3, 67), Vector3.UP)
		nombre = "terraza.png"
	elif args.has("capturar_sentado"):
		_construir_tile(_tile_de(Vector2(_jugador.position.x, _jugador.position.z)))
		if not _asientos.is_empty():
			var a0: Dictionary = _asientos[0]
			var ap: Vector3 = a0["pos"]
			_jugador.position = Vector3(ap.x + 1.2, ap.y + 0.95, ap.z)
			_alternar_sentarse()
			var frente := Vector3(sin(_dir_jugador), 0, cos(_dir_jugador))
			var pc := _jugador.position - frente * 3.4 + Vector3(0, 0.9, 0)
			_cam.look_at_from_position(pc, _jugador.position + Vector3(0, 0.35, 0), Vector3.UP)
		nombre = "sentado.png"
	elif args.has("capturar_vida"):
		var pe := _poi_nom("Paseo del Espolón")
		pe.y = _altura(pe.x, pe.z)
		_cam.look_at_from_position(pe + Vector3(8, 3.4, 8), pe + Vector3(0, 1.0, 0), Vector3.UP)
		nombre = "vida.png"
	elif args.has("capturar_mision"):
		var medio := (_origen + _destino) * 0.5
		_cam.look_at_from_position(medio + Vector3(190, 240, 190), medio, Vector3.UP)
		nombre = "mision_v1.png"
	elif args.has("capturar_escolta"):
		_historia_idx = 1
		_hist = {}
		_hist_marcar()
		var pe: Vector3 = _pjs["elias"]["pos"]
		_jugador.position = Vector3(pe.x + 1.5, _altura(pe.x + 1.5, pe.z) + 0.95, pe.z)
		await get_tree().physics_frame
		_hablar_cercano()
		while _dlg_abierto:
			_dlg_seguir()
		_jugador.position = Vector3(pe.x + 13.0, _altura(pe.x + 13.0, pe.z - 9.0) + 0.95, pe.z - 9.0)
		_dir_jugador = atan2(-13.0, 9.0)
		for f_s in 240:
			await get_tree().physics_frame
		var jp := _jugador.position
		_cam.look_at_from_position(jp + Vector3(5.5, 3.2, 5.5), jp + Vector3(-1.5, 0.8, -1.0), Vector3.UP)
		nombre = "escolta.png"
	elif args.has("capturar_laurel"):
		for tt in [Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(3, 4), Vector2i(4, 4)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-505.0, _altura(-505.0, 173.0), 173.0)
		_dir_jugador = PI * 0.5
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-513, _altura(-513, 173) + 3.2, 173), Vector3(-499, _altura(-499, 173) + 1.0, 173), Vector3.UP)
		nombre = "laurel.png"
	elif args.has("capturar_sanjuan"):
		for tt in [Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(3, 4), Vector2i(4, 4)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-190.0, _altura(-190.0, 134.0), 134.0)
		_refrescar_rotulos()
		_dir_jugador = PI * 0.5
		nombre = "sanjuan.png"
	elif args.has("capturar_agua"):
		for tt in [Vector2i(3, 2), Vector2i(4, 2), Vector2i(3, 3), Vector2i(4, 3)]:
			_construir_tile(tt)
		var pr_a := _punto_en_rio(_rio_total * 0.46, 2.0)
		var mejor_d := 1.0e9
		for tt2 in range(101):
			var cand_a := _punto_en_rio(_rio_total * float(tt2) / 100.0, 0.0)
			var dd_a := cand_a.distance_to(Vector2(-520, -355))
			if dd_a < mejor_d:
				mejor_d = dd_a
				pr_a = cand_a
		_coche.position = Vector3(pr_a.x, _nivel_agua(pr_a) - 0.25, pr_a.y)
		_coche_dir = 1.2
		_coche.rotation.y = _coche_dir
		_jugador.position = _coche.position + Vector3(1.5, 0.95, 0)
		_en_coche = true
		_alternar_coche()
		_dir_jugador = atan2(_coche.position.x - _jugador.position.x, _coche.position.z - _jugador.position.z)
		_cam.look_at_from_position(_jugador.position + Vector3(7.0, 3.5, 0), _coche.position + Vector3(0, 0.6, 0), Vector3.UP)
		nombre = "agua.png"
	elif args.has("capturar_norias"):
		for tt in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2)]:
			_construir_tile(tt)
		print("NORIAS_NODOS ", get_tree().get_node_count())
		_cam.look_at_from_position(Vector3(-1155, _altura(-1155, -870) + 120.0, -640), Vector3(-1155, _altura(-1155, -870), -880), Vector3.UP)
		nombre = "norias.png"
	elif args.has("capturar_norias_pistas"):
		for tt in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2)]:
			_construir_tile(tt)
		_cam.look_at_from_position(Vector3(-1050, _altura(-1050, -545) + 26.0, -545), Vector3(-1065, _altura(-1065, -620), -620), Vector3.UP)
		nombre = "norias_pistas.png"
	elif args.has("capturar_unir"):
		for tt in [Vector2i(6, 3), Vector2i(5, 3), Vector2i(6, 2), Vector2i(6, 4)]:
			_construir_tile(tt)
		_jugador.position = Vector3(1500.0, _altura(1500.0, 560.0), 560.0)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(1395, _altura(1395, 655) + 30.0, 655), Vector3(1528, _altura(1528, 521) + 8.0, 521), Vector3.UP)
		nombre = "unir.png"
	elif args.has("capturar_sagasta"):
		for tt in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), Vector2i(2, 0)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-1478.0, _altura(-1478.0, -1010.0), -1010.0)
		_dir_jugador = -2.845
		_cam.look_at_from_position(Vector3(-1475.7, _altura(-1475.7, -1002.4) + 3.0, -1002.4), Vector3(-1493, _altura(-1493, -1059) + 12.0, -1059), Vector3.UP)
		nombre = "sagasta.png"
	elif args.has("capturar_hierro"):
		for tt in [Vector2i(3, 2), Vector2i(4, 2), Vector2i(3, 3), Vector2i(4, 3)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-352.0, _altura(-352.0, -300.0), -300.0)
		_dir_jugador = 3.03
		nombre = "hierro.png"
	elif args.has("capturar_ra"):
		for tt in [Vector2i(3, 4), Vector2i(2, 4), Vector2i(3, 3)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-667.0, _altura(-667.0, 1018.0), 1018.0)
		_dir_jugador = 0.305
		_cam.look_at_from_position(Vector3(-669.7, _altura(-669.7, 1009.4) + 3.5, 1009.4), Vector3(-649, _altura(-649, 1075) + 3.0, 1075), Vector3.UP)
		nombre = "ra.png"
	elif args.has("capturar_colegio"):
		for tt in [Vector2i(5, 3), Vector2i(4, 3), Vector2i(5, 2), Vector2i(4, 2)]:
			_construir_tile(tt)
		_cam.look_at_from_position(Vector3(520, _altura(520, 330) + 55.0, 330), Vector3(609, _altura(609, 439), 439), Vector3.UP)
		nombre = "colegio.png"
	elif args.has("capturar_gaunas_fans"):
		for tt in [Vector2i(2, 5), Vector2i(1, 5), Vector2i(2, 4)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-975.0, _altura(-975.0, 1538.0), 1538.0)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-985, _altura(-985, 1505) + 3.5, 1505), Vector3(-945, _altura(-945, 1540) + 2.0, 1540), Vector3.UP)
		nombre = "gaunas_fans.png"
	elif args.has("capturar_bici"):
		for tt in [Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 4), Vector2i(4, 4)]:
			_construir_tile(tt)
		_mis_coches = [{"id": 12, "danio": 0, "motor": 0, "frenos": 0}]
		_coche_activo = 0
		_reconstruir_coche()
		_coche.position = Vector3(-500, _altura(-500, 173), 173)
		_coche_dir = PI * 0.5
		_coche.rotation.y = _coche_dir
		_jugador.position = _coche.position + Vector3(-2.0, 0.95, 0)
		_alternar_coche()
		_coche_vel = 5.0
		_actualizar_camara(0.016)
		_cam.look_at_from_position(_coche.position + Vector3(-7.0, 2.4, 0), _coche.position + Vector3(3.0, 0.8, 0), Vector3.UP)
		nombre = "bici.png"
	elif args.has("capturar_mtb"):
		for tt in [Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 4), Vector2i(4, 4)]:
			_construir_tile(tt)
		_mis_coches = [{"id": 13, "danio": 0, "motor": 0, "frenos": 0}]
		_coche_activo = 0
		_reconstruir_coche()
		_coche.position = Vector3(-500, _altura(-500, 173), 173)
		_coche_dir = PI * 0.5
		_coche.rotation.y = _coche_dir
		_jugador.position = _coche.position + Vector3(-2.0, 0.95, 0)
		_alternar_coche()
		_coche_vel = 5.0
		_actualizar_camara(0.016)
		_cam.look_at_from_position(_coche.position + Vector3(-7.0, 2.4, 0), _coche.position + Vector3(3.0, 0.8, 0), Vector3.UP)
		nombre = "mtb.png"
	elif args.has("capturar_vel"):
		for tt in [Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 4), Vector2i(4, 4)]:
			_construir_tile(tt)
		_coche.position = Vector3(-500, _altura(-500, 173), 173)
		_coche_dir = PI * 0.5
		_coche.rotation.y = _coche_dir
		_jugador.position = _coche.position + Vector3(-2.0, 0.95, 0)
		_alternar_coche()
		_coche_vel = 13.9
		_conducir(0.016)
		_cam.look_at_from_position(_coche.position + Vector3(-8.0, 2.8, 0), _coche.position + Vector3(3.0, 0.8, 0), Vector3.UP)
		nombre = "vel.png"
	elif args.has("capturar_berceo"):
		_entrar_interior("berceo")
		var cb0: Vector3 = _interiores["berceo"]["centro"]
		_cam.look_at_from_position(cb0 + Vector3(27, 10, 27), cb0 + Vector3(-10, 0.5, -8), Vector3.UP)
		nombre = "berceo_dentro.png"
	elif args.has("capturar_berceo_alta"):
		_entrar_interior("berceo")
		_cambiar_planta(true)
		var cb1: Vector3 = _interiores["berceo1"]["centro"]
		_cam.look_at_from_position(cb1 + Vector3(27, 10, 27), cb1 + Vector3(-18, 0.5, -9), Vector3.UP)
		nombre = "berceo_alta.png"
	elif args.has("capturar_eje_placa"):
		for tt in [Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 4), Vector2i(4, 4)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-366.9, _altura(-366.9, 426.3) + 0.95, 426.3)
		_dir_jugador = PI
		_jugador.rotation.y = PI
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-366.9, _altura(-366.9, 426.3) + 1.7, 426.3), Vector3(-369.1, _altura(-369.1, 432.9) + 2.6, 432.9), Vector3.UP)
		nombre = "eje_placa.png"
	elif args.has("capturar_bloque7"):
		for tt in [Vector2i(4, 3), Vector2i(3, 3), Vector2i(4, 2), Vector2i(3, 2), Vector2i(5, 3), Vector2i(4, 4)]:
			_construir_tile(tt)
		_jugador.position = Vector3(334.2, _altura(334.2, 199.3) + 0.95, 199.3)
		_dir_jugador = atan2(0.953, 0.303)
		_jugador.rotation.y = _dir_jugador
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(337.6, _altura(337.6, 200.3) + 2.4, 200.3), Vector3(343.7, _altura(343.7, 202.0) + 1.4, 202.0), Vector3.UP)
		nombre = "bloque7.png"
	elif args.has("capturar_gallarza"):
		for tt in [Vector2i(3, 4), Vector2i(2, 4), Vector2i(3, 3), Vector2i(2, 3), Vector2i(4, 4), Vector2i(3, 5)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-474.6, _altura(-474.6, 698.7) + 0.95, 698.7)
		_dir_jugador = 0.0
		_jugador.rotation.y = 0.0
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-420.0, _altura(-420.0, 790.0) + 55.0, 790.0), Vector3(-500.0, _altura(-500.0, 720.0), 720.0), Vector3.UP)
		nombre = "gallarza.png"
	elif args.has("capturar_columpio"):
		# El jugador montado en el columpio libre de Gallarza
		for tt in [Vector2i(3, 4), Vector2i(2, 4), Vector2i(3, 3), Vector2i(2, 3), Vector2i(4, 4), Vector2i(3, 5)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-511.2, _altura(-511.2, 716.3) + 0.95, 716.3)
		_alternar_columpio()
		_columpios[1]["amp"] = 0.55
		_columpios[1]["fase_propia"] = 1.15
		_mover_peatones(0.05)
		_actualizar_columpio(0.05)
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-508.0, _altura(-508.0, 720.5) + 1.8, 720.5), Vector3(-512.2, _altura(-512.2, 716.3) + 1.2, 716.3), Vector3.UP)
		nombre = "columpio.png"
	elif args.has("capturar_lineas"):
		# El plano abierto con las 5 líneas pintadas
		_abrir_mapa()
		nombre = "lineas.png"
	elif args.has("capturar_casco"):
		# Dentro de Decathlon, junto a los cascos: el botón de
		# acción tiene que decir «Casco de ciclismo · 35 €» y
		# caber en la pantalla.
		_entrar_interior("decathlon")
		var accs_c: Dictionary = _interiores["decathlon"]["acciones"]
		_jugador.position = (accs_c["comprar:dec_casco"] as Vector3) + Vector3(0.6, 0.95, 0.6)
		_jugador.rotation.y = -2.2
		_actualizar_hud()
		_cam.look_at_from_position(_jugador.position + Vector3(2.6, 1.6, 2.6), _jugador.position + Vector3(0, 0.8, 0), Vector3.UP)
		nombre = "casco.png"
	elif args.has("capturar_bolsa"):
		# E4: el jugador con el balón bajo el brazo izquierdo
		# y la bolsa de la compra en la mano derecha, en la
		# puerta del Decathlon.
		for dt in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			_construir_tile(_tile_de(Vector2(-2455, 1564)) + dt)
		_jugador.position = Vector3(-2452.0, _altura(-2452.0, 1564.0) + 0.95, 1564.0)
		_jugador.rotation.y = PI / 2.0
		_balon_en_mano = true
		_bolsa_en_mano = true
		_refrescar_pan()
		_brazo_i.rotation.x = -0.22
		_brazo_d.rotation.x = -0.15
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-2448.6, _altura(-2448.6, 1562.6) + 1.5, 1562.6), Vector3(-2452.0, _altura(-2452.0, 1564.0) + 1.0, 1564.0), Vector3.UP)
		nombre = "bolsa.png"
	elif args.has("capturar_ra"):
		for tt in [Vector2i(3, 4), Vector2i(2, 4), Vector2i(3, 5), Vector2i(2, 5), Vector2i(3, 3), Vector2i(4, 4)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-652.7, _altura(-652.7, 1086.1) + 0.95, 1086.1)
		_dir_jugador = 0.0
		_jugador.rotation.y = 0.0
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-610.0, _altura(-610.0, 1140.0) + 42.0, 1140.0), Vector3(-652.0, _altura(-652.0, 1062.0), 1062.0), Vector3.UP)
		nombre = "rep_argentina.png"
	elif args.has("capturar_decathlon"):
		_entrar_interior("decathlon")
		var cen_d: Vector3 = _interiores["decathlon"]["centro"]
		_jugador.position = cen_d + Vector3(0, 0.95, 7.0)
		_dir_jugador = PI
		_jugador.rotation.y = PI
		_cam.look_at_from_position(cen_d + Vector3(7.5, 5.5, 8.5), cen_d + Vector3(-3.0, 0.8, -2.0), Vector3.UP)
		nombre = "decathlon.png"
	elif args.has("capturar_eje_galdos"):
		for tt in [Vector2i(2, 4), Vector2i(2, 3), Vector2i(1, 4)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-1145, _altura(-1145, 655) + 0.95, 655)
		_dir_jugador = 0.0
		_jugador.rotation.y = 0.0
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-1145, _altura(-1145, 640) + 2.2, 640), Vector3(-1158, _altura(-1158, 690) + 1.2, 690), Vector3.UP)
		nombre = "eje_galdos.png"
	elif args.has("capturar_eje_sananton"):
		for tt in [Vector2i(3, 3), Vector2i(3, 4)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-302, _altura(-302, 610) + 0.95, 610)
		_dir_jugador = PI
		_jugador.rotation.y = PI
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-302, _altura(-302, 618) + 2.0, 618), Vector3(-322, _altura(-322, 555) + 1.5, 555), Vector3.UP)
		nombre = "eje_sananton.png"
	elif args.has("capturar_eje_portugal"):
		for tt in [Vector2i(3, 3), Vector2i(2, 3)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-660, _altura(-660, 130) + 0.95, 130)
		_dir_jugador = 0.8
		_jugador.rotation.y = 0.8
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-668, _altura(-668, 118) + 2.4, 118), Vector3(-600, _altura(-600, 165) + 1.0, 165), Vector3.UP)
		nombre = "eje_portugal.png"
	elif args.has("capturar_b6_mercadona"):
		for tt in [Vector2i(0, 4), Vector2i(1, 4), Vector2i(0, 3)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-2131.5, _altura(-2131.5, 1082) + 0.95, 1082)
		_dir_jugador = PI
		_jugador.rotation.y = PI
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-2131.5, _altura(-2131.5, 1080) + 2.0, 1080), Vector3(-2131.8, _altura(-2131.8, 1094.2) + 1.8, 1094.2), Vector3.UP)
		nombre = "b6_mercadona.png"
	elif args.has("capturar_b6_eroski"):
		for tt in [Vector2i(0, 4), Vector2i(0, 3)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-2261, _altura(-2261, 626) + 0.95, 626)
		_dir_jugador = PI
		_jugador.rotation.y = PI
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-2261, _altura(-2261, 628.4) + 2.0, 628.4), Vector3(-2264.8, _altura(-2264.8, 617.0) + 1.8, 617.0), Vector3.UP)
		nombre = "b6_eroski.png"
	elif args.has("capturar_carrera_mapa"):
		for tt in [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3)]:
			_construir_tile(tt)
		_iniciar_carrera(0, "rivales")
		_carr_auto = true
		for f_c in 1500:
			await get_tree().physics_frame
		var cp2 := _coche.position
		_minimapa.call("actualizar", _datos_minimapa())
		_cam.look_at_from_position(cp2 + Vector3(-sin(_coche_dir) * 11.0, 5.0, -cos(_coche_dir) * 11.0), cp2 + Vector3(sin(_coche_dir) * 8.0, 1.0, cos(_coche_dir) * 8.0), Vector3.UP)
		nombre = "carrera_mapa.png"
	elif args.has("capturar_gaunas"):
		for tt in [Vector2i(2, 4), Vector2i(3, 4), Vector2i(2, 5), Vector2i(3, 5)]:
			_construir_tile(tt)
		_cam.look_at_from_position(Vector3(-864, _altura(-864, 1150) + 170.0, 1150), Vector3(-864, _altura(-864, 1540) + 0.0, 1540), Vector3.UP)
		nombre = "gaunas.png"
	elif args.has("capturar_gaunas_calle"):
		for tt in [Vector2i(2, 4), Vector2i(3, 4), Vector2i(2, 5), Vector2i(3, 5)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-1005.0, _altura(-1005.0, 1538.0), 1538.0)
		_dir_jugador = -PI * 0.5
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-1002, _altura(-1002, 1538) + 2.5, 1538), Vector3(-935, _altura(-935, 1538) + 11.0, 1538), Vector3.UP)
		nombre = "gaunas_calle.png"
	elif args.has("capturar_berceo"):
		for tt in [Vector2i(6, 2), Vector2i(7, 2), Vector2i(6, 3), Vector2i(7, 3)]:
			_construir_tile(tt)
		_cam.look_at_from_position(Vector3(1863, _altura(1863, 60) + 120.0, 60), Vector3(1850, _altura(1850, 440) + 0.0, 440), Vector3.UP)
		nombre = "berceo.png"
	elif args.has("capturar_carrefour"):
		for tt in [Vector2i(6, 3), Vector2i(7, 3)]:
			_construir_tile(tt)
		_jugador.position = Vector3(1882.0, _altura(1882.0, 448.0), 448.0)
		_dir_jugador = PI
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(1835, _altura(1835, 565) + 48.0, 565), Vector3(1885, _altura(1885, 408) + 5.0, 408), Vector3.UP)
		nombre = "carrefour.png"
	elif args.has("capturar_prioja"):
		for tt in [Vector2i(0, 4), Vector2i(1, 4), Vector2i(0, 5), Vector2i(1, 5)]:
			_construir_tile(tt)
		_cam.look_at_from_position(Vector3(-2135, _altura(-2135, 1230) + 130.0, 1230), Vector3(-2200, _altura(-2200, 1650) + 0.0, 1650), Vector3.UP)
		nombre = "prioja.png"
	elif args.has("capturar_decathlon"):
		for tt in [Vector2i(0, 5), Vector2i(1, 5)]:
			_construir_tile(tt)
		_jugador.position = Vector3(-2415.0, _altura(-2415.0, 1564.0), 1564.0)
		_dir_jugador = -PI * 0.5
		_refrescar_rotulos()
		_cam.look_at_from_position(Vector3(-2398, _altura(-2398, 1564) + 3.0, 1564), Vector3(-2462, _altura(-2462, 1564) + 5.0, 1564), Vector3.UP)
		nombre = "decathlon.png"
	elif args.has("capturar_paseo"):
		for tt in [Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)]:
			_construir_tile(tt)
		_cam.look_at_from_position(Vector3(1230, _altura(1230, -1010) + 85.0, -1010), Vector3(150, _altura(150, -700) + 0.0, -700), Vector3.UP)
		nombre = "paseo.png"
	elif args.has("capturar_ribera"):
		for tt in [Vector2i(4, 1), Vector2i(4, 2)]:
			_construir_tile(tt)
		_cam.look_at_from_position(Vector3(456, _altura(456, -655) + 2.6, -655), Vector3(450, _altura(450, -775) + 1.0, -775), Vector3.UP)
		nombre = "ribera.png"
	elif args.has("capturar_florida"):
		for tt in [Vector2i(4, 1), Vector2i(4, 2)]:
			_construir_tile(tt)
		_cam.look_at_from_position(Vector3(243, _altura(243, -342) + 15.0, -342), Vector3(276, _altura(276, -408) + 0.0, -408), Vector3.UP)
		nombre = "florida.png"
	elif args.has("capturar_toros"):
		for tt in [Vector2i(4, 2), Vector2i(5, 2), Vector2i(4, 3), Vector2i(5, 3)]:
			_construir_tile(tt)
		_cam.look_at_from_position(Vector3(516, _altura(516, -414) + 46.0, -414), Vector3(458, _altura(458, -487) + 2.0, -487), Vector3.UP)
		nombre = "toros.png"
	elif args.has("capturar_rioja"):
		for tt in [Vector2i(4, 2), Vector2i(5, 2), Vector2i(4, 3), Vector2i(5, 3)]:
			_construir_tile(tt)
		_cam.look_at_from_position(Vector3(945, _altura(945, -640) + 3.0, -640), Vector3(965, _altura(965, -566) + 6.0, -566), Vector3.UP)
		nombre = "rioja.png"
	elif args.has("capturar_frente"):
		_jugador.position = Vector3(-424.0, _altura(-424.0, 1544.0), 1544.0)
		_dir_jugador = 0.0
		_jugador.rotation.y = 0.0
		var jf := _jugador.position
		_cam.look_at_from_position(jf + Vector3(0, 1.45, 2.2), jf + Vector3(0, 1.0, 0), Vector3.UP)
		nombre = "frente.png"
	elif args.has("capturar_espalda"):
		if _personaje == 1:
			_cambiar_personaje()
		_jugador.position = Vector3(-424.0, _altura(-424.0, 1544.0), 1544.0)
		_dir_jugador = 0.0
		_jugador.rotation.y = 0.0
		var je := _jugador.position
		_cam.look_at_from_position(je + Vector3(0, 1.45, -2.2), je + Vector3(0, 1.0, 0), Vector3.UP)
		nombre = "espalda.png"
	elif args.has("capturar_espalda_ella"):
		if _personaje == 0:
			_cambiar_personaje()
		_jugador.position = Vector3(-424.0, _altura(-424.0, 1544.0), 1544.0)
		_dir_jugador = 0.0
		_jugador.rotation.y = 0.0
		var je2 := _jugador.position
		_cam.look_at_from_position(je2 + Vector3(0, 1.45, -2.2), je2 + Vector3(0, 1.0, 0), Vector3.UP)
		nombre = "espalda_ella.png"
	elif args.has("capturar_coche"):
		var cp := _coche.position
		_cam.look_at_from_position(cp + Vector3(2, 30, 2), cp + Vector3(0, 1, 0), Vector3.UP)
		nombre = "coche_v1.png"
	elif args.has("capturar_ayuda"):
		_abrir_ayuda()
		nombre = "ayuda.png"
	elif args.has("capturar_trabajos"):
		_abrir_panel()
		nombre = "trabajos.png"
	elif args.has("capturar_mapa"):
		_aceptar_trabajo(0)
		_abrir_mapa()
		nombre = "mapa.png"
	elif args.has("capturar_mapa_unir"):
		_aceptar_trabajo(0)
		_abrir_mapa()
		_mapa.set("_zoom", 3.0)
		_mapa.set("_centro", Vector2(1500, 500))
		_mapa.queue_redraw()
		nombre = "mapa_unir.png"
	elif args.has("capturar_mapa_l5"):
		_aceptar_trabajo(0)
		_abrir_mapa()
		_mapa.set("_zoom", 3.0)
		_mapa.set("_centro", Vector2(1000, -300))
		_mapa.queue_redraw()
		nombre = "mapa_l5.png"
	elif args.has("capturar_mapa_rotonda"):
		_aceptar_trabajo(0)
		_abrir_mapa()
		_mapa.set("_zoom", 4.0)
		_mapa.set("_centro", Vector2(2174, -581))
		_mapa.queue_redraw()
		nombre = "mapa_rotonda.png"
	elif args.has("capturar_pilar"):
		_aceptar_trabajo(0)
		var pp := _jugador.position
		var dd := _destino_libre
		var dirp := Vector3(dd.x - pp.x, 0, dd.z - pp.z).normalized()
		var cam_p := pp - dirp * 10.0 + Vector3(0, 3.5, 0)
		cam_p.y = _altura(cam_p.x, cam_p.z) + 3.5
		_cam.look_at_from_position(cam_p, Vector3(dd.x, _altura(dd.x, dd.z) + 8.0, dd.z), Vector3.UP)
		nombre = "pilar.png"
	elif args.has("capturar_ciudad"):
		for ti in range(-1, 10):
			for tj in range(-1, 8):
				_construir_tile(Vector2i(ti, tj))
		_cam.look_at_from_position(Vector3(0, 3100, 1500), Vector3(0, 0, -200), Vector3.UP)
		nombre = "ciudad.png"
	elif args.has("capturar_lejos"):
		var dest := Vector3(1240, 0, -450)
		for p in _pois:
			if String(p["n"]).contains("Toros"):
				dest = Vector3(float(p["x"]), 0, float(p["z"]))
				break
		var ct2 := _tile_de(Vector2(dest.x, dest.z))
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(Vector2i(ct2.x + dx, ct2.y + dy))
		dest.y = _altura(dest.x, dest.z)
		_cam.look_at_from_position(dest + Vector3(55, 15, 85), dest + Vector3(0, 4, 0), Vector3.UP)
		nombre = "lejos.png"
	elif args.has("capturar_puente"):
		var pc := Vector3(-101.4, 0, -396.7)
		pc.y = _altura(pc.x, pc.z)
		_cam.look_at_from_position(pc + Vector3(55, 16, 120), pc + Vector3(0, 5, 0), Vector3.UP)
		nombre = "puente.png"
	elif args.has("capturar_layout"):
		_aceptar_trabajo(0)
		_alternar_coche()
		var cp2 := _coche.position
		var atras := Vector3(sin(_coche_dir), 0, cos(_coche_dir))
		var cam_l := cp2 - atras * 13.0 + Vector3(0, 5.5, 0)
		cam_l.y = _altura(cam_l.x, cam_l.z) + 5.5
		_cam.look_at_from_position(cam_l, cp2 + Vector3(0, 1.5, 0), Vector3.UP)
		_actualizar_hud()
		if _minimapa != null:
			_minimapa.call("actualizar", _datos_minimapa())
		nombre = "layout.png"
	elif args.has("capturar_tactil"):
		_aceptar_trabajo(0)
		_alternar_coche()
		_capa_tactil.visible = true
		nombre = "tactil.png"
	elif args.has("capturar_mirador"):
		var datos_m = JSON.parse_string(FileAccess.get_file_as_string("res://datos/entorno.json"))
		var dest := Vector3.ZERO
		for p in datos_m["pois"]:
			if String(p["n"]).contains("Redonda"):
				dest = Vector3(float(p["x"]), 0, float(p["z"]))
		dest.y = _altura(dest.x, dest.z)
		_cam.look_at_from_position(dest + Vector3(-58, 24, 30), dest + Vector3(8, 11, 0), Vector3.UP)
		nombre = "mirador_redonda.png"
	elif args.has("probar_portal"):
		# Sonda ligera: ¿qué muros cercan el portal de San Bernabé 2?
		# Dos barridos de colisión (vertical y horizontal) por el portal.
		var portal_p := Vector2(428.1, -328.0)
		var centro_pt := _tile_de(portal_p)
		for dxp in range(-2, 3):
			for dyp in range(-2, 3):
				_construir_tile(centro_pt + Vector2i(dxp, dyp))
		var salida := "PORTAL libre=" + str(not _choca(portal_p, 0.45)) + "\n"
		var scan := ""
		var zz := -180.0
		while zz >= -600.0:
			scan += ("X" if _choca(Vector2(428.0, zz), 0.45) else ".")
			zz -= 4.0
		salida += "SCAN_V x=428 z=-180..-600 paso4: " + scan + "\n"
		var scan2 := ""
		var xx := 280.0
		while xx <= 580.0:
			scan2 += ("X" if _choca(Vector2(xx, -328.0), 0.45) else ".")
			xx += 4.0
		salida += "SCAN_H z=-328 x=280..580 paso4: " + scan2 + "\n"
		var scan3 := ""
		var zz3 := -260.0
		while zz3 >= -460.0:
			scan3 += ("X" if _choca(Vector2(470.0, zz3), 0.45) else ".")
			zz3 -= 4.0
		salida += "SCAN_V2 x=470 z=-260..-460 paso4: " + scan3 + "\n"
		var fa := FileAccess.open("/tmp/portal_scan.txt", FileAccess.WRITE)
		if fa != null:
			fa.store_string(salida)
			fa.close()
		print(salida)
		get_tree().quit()
		return
	elif args.has("verificar"):
		var coche_pos0 := _coche.position
		var jug_pos0 := _jugador.position
		_coche.position = jug_pos0 + Vector3(120, 0, 45)
		var esperado_c := Vector2(_coche.position.x, _coche.position.z)
		_en_coche = true
		var centro_coche: Vector2 = _datos_minimapa()["jugador"]
		_en_coche = false
		_coche.position = coche_pos0
		var centro_pie: Vector2 = _datos_minimapa()["jugador"]
		print("MINIMAPA_OK sigue_coche=", centro_coche.distance_to(esperado_c) < 0.01, " sigue_a_pie=", centro_pie.distance_to(Vector2(jug_pos0.x, jug_pos0.z)) < 0.01)
		var centro_t := _tile_de(Vector2(_jugador.position.x, _jugador.position.z))
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				_construir_tile(Vector2i(centro_t.x + dx, centro_t.y + dy))
		var banco_ok := false
		if not _asientos.is_empty():
			var a0p: Vector3 = _asientos[0]["pos"]
			banco_ok = _choca_entidad(Vector2(a0p.x, a0p.z), 0.4, _jugador)
		var libre_ok := not _choca_entidad(Vector2(_jugador.position.x, _jugador.position.z), 0.4, _jugador)
		print("SOLIDOS_OK n=", _solidos.size(), " banco_bloquea=", banco_ok, " spawn_libre=", libre_ok)
		_refrescar_rotulos()
		var rot_ok := not _rotulos_activos.is_empty()
		# Cada rotulo activo tiene que llevar el pixel_size de
		# la formula y caber en SU panel: el tope fijo de 4,7 m
		# era de cuando solo habia rotulos normales cerca del
		# spawn; los grandes (colegios, g=3,5) se miden contra
		# el ancho de su propio cartel.
		var esperados := {}
		for clave in _rotulos_datos:
			for r in _rotulos_datos[clave]:
				var rp2: Vector3 = r["p"]
				esperados[clave + "|" + str(int(rp2.x)) + "," + str(int(rp2.z)) + "|" + String(r["n"])] = r
		for r in _placas_datos:
			var rp3: Vector3 = r["p"]
			esperados["placa|" + str(int(rp3.x)) + "," + str(int(rp3.z)) + "|" + String(r["n"])] = r
		for id_r in _rotulos_activos:
			var et_r: Label3D = _rotulos_activos[id_r]
			var rr: Dictionary = esperados.get(id_r, {})
			if rr.is_empty():
				rot_ok = false
				continue
			var ps_esp := minf(0.0052 * float(rr.get("g", 1.0)), float(rr.get("w", 4.6)) / (float(maxi(1, et_r.text.length())) * 48.0))
			if absf(et_r.pixel_size - ps_esp) > 0.0001 or et_r.text.length() * 48.0 * et_r.pixel_size > float(rr.get("w", 4.6)) + 0.05:
				rot_ok = false
		print("ROTULOS_OK pasa=", rot_ok, " n=", _rotulos_activos.size())
		print("BLOQUE7_PRUEBA_OK placas=", _placas_datos.size(), " paradas=", _b7_paradas, " contenedores=", _b7_contenedores, " pasa=", _placas_datos.size() >= 1000 and _b7_paradas >= 190 and _b7_contenedores >= 75)
		# Bloque G: si la recta nodo->portal está bloqueada por un edificio,
		# el tramo transitable tiene que rodearla sin chocar en ningún tramo.
		var tramo_casos := 0
		var tramo_fallos := 0
		for p in _portales:
			var pp := Vector2(float(p["x"]), float(p["z"]))
			if pp.distance_to(Vector2(_origen_libre.x, _origen_libre.z)) > 350.0:
				continue
			var libre3 := _punto_libre(Vector3(pp.x, 0, pp.y), 0.4)
			var dest2 := Vector2(libre3.x, libre3.z)
			var nodo: Vector2 = _nodos[_nodo_cercano(dest2)]
			if _segmento_libre(nodo, dest2, 0.35):
				continue
			var tramo := _tramo_transitable(nodo, dest2)
			var bien := tramo.size() >= 2
			var ant := nodo
			if bien:
				for tp in tramo:
					if not _segmento_libre(ant, Vector2(tp.x, tp.z), 0.35):
						bien = false
						break
					ant = Vector2(tp.x, tp.z)
			if bien:
				tramo_casos += 1
			else:
				tramo_fallos += 1
				print("TRAMO_FALLO portal=", p["calle"], " ", p["numero"], " en=", pp, " nodo=", nodo, " tramo=", tramo.size())
			if tramo_casos >= 5:
				break
		print("TRAMO_OK casos=", tramo_casos, " fallos=", tramo_fallos)
		print("CATEDRAL_OK partes=", _catedral_partes, " torres=", _catedral_torres)
		print("IGLESIAS_OK partes=", _igl_partes, " torres=", _igl_torres)
		print("SING_OK partes=", _sing_partes)
		_construir_tile(Vector2i(4, 2))
		_construir_tile(Vector2i(5, 2))
		_construir_tile(Vector2i(1, 1))
		_construir_tile(Vector2i(2, 1))
		_construir_tile(Vector2i(2, 2))
		_construir_tile(Vector2i(6, 3))
		_construir_tile(Vector2i(0, 5))
		_construir_tile(Vector2i(0, 5))
		_construir_tile(Vector2i(1, 5))
		_construir_tile(Vector2i(7, 3))
		_construir_tile(Vector2i(6, 3))
		_construir_tile(Vector2i(2, 5))
		print("ESPECIALES_OK n=", _especiales)
		print("FACHADAS_OK puertas=", _fach_puertas, " tejados=", _fach_tejados, " balcones=", _fach_balcones, " digitos=", _fach_digitos)
		print("LOCALES_OK locales=", _locales_total, " terrazas=", _terrazas_total, " asientos=", _asientos.size())
		# Tanda 7: el skate park de Las Norias tiene sus 3
		# chavales, alguno salta de verdad y ninguno se sale
		# de la pista.
		var skate_ok := _skaters.size() == 3
		var aire_max := 0.0
		for paso_t in [0.0, 1.3, 2.9, 4.4, 6.1, 7.8]:
			_tiempo = paso_t
			_mover_peatones(0.016)
			for sk in _skaters:
				var rp: Vector3 = (sk["raiz"] as Node3D).position
				aire_max = maxf(aire_max, rp.y - float(sk["ys"]) - 0.95)
				if absf(rp.x + 899.0) > 20.0 or absf(rp.z + 735.0) > 16.0:
					skate_ok = false
		print("SKATE_OK pasa=", skate_ok and aire_max > 0.30, " n=", _skaters.size(), " aire=", snappedf(aire_max, 0.01))
		# Tanda 7: las paredes dibujadas de la UNIR chocan (su
		# huella OSM quedaba 12 m dentro del dibujo y Jon las
		# atravesaba).
		var unir_dentro := _choca_entidad(Vector2(1521.6, 543.1), 0.35, _jugador)
		var unir_fuera := _choca_entidad(Vector2(1520.2, 547.4), 0.35, _jugador)
		print("UNIR_COL_OK pasa=", unir_dentro and not unir_fuera)
		# Tanda 7: las lineas de autobus van SOLO por nodos del
		# grafo (sin excursiones rodeando edificios: las quejas
		# de Jon en las lineas roja, verde y azul).
		var claves_nodo := {}
		for nv in _nodos:
			claves_nodo[str(snappedf(nv.x, 0.1)) + "," + str(snappedf(nv.y, 0.1))] = true
		var pts_fuera := 0
		for lin in _lineas_bus:
			for p3 in lin["pts"]:
				var pv: Vector2 = p3
				if not claves_nodo.has(str(snappedf(pv.x, 0.1)) + "," + str(snappedf(pv.y, 0.1))):
					pts_fuera += 1
		print("LINEAS_GRAFO_OK pasa=", pts_fuera == 0, " fuera=", pts_fuera)
		# Tanda 7: las ruinas romanas del Monte Cantabria.
		_construir_tile(Vector2i(6, 1))
		print("CANTABRIA_OK pasa=", _ruinas)
		get_tree().quit()
		return
	else:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var ruta := ProjectSettings.globalize_path("res://") + "../datos/procesado/" + nombre
	img.save_png(ruta)
	print("CAPTURA_OK ", ruta)
	get_tree().quit()

func _malla_de(verts: PackedVector3Array, normals: PackedVector3Array,
		cols: PackedColorArray, color: Color,
		m_uvs := PackedVector2Array(), textura: Texture2D = null) -> MeshInstance3D:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	if not cols.is_empty():
		arrays[Mesh.ARRAY_COLOR] = cols
	if not m_uvs.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = m_uvs
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not cols.is_empty():
		mat.vertex_color_use_as_albedo = true
	if textura != null:
		mat.albedo_texture = textura
		# La repetición de textura viene activada por defecto en 4.3:
		# las UV de fachada mayores que 1 se repiten solas.
	malla.surface_set_material(0, mat)
	var inst := MeshInstance3D.new()
	inst.mesh = malla
	return inst

func _tri(verts: PackedVector3Array, normals: PackedVector3Array, cols: PackedColorArray,
		a: Vector3, b: Vector3, c: Vector3, forzar_arriba: bool, color: Color,
		m_uvs := PackedVector2Array(), p_uvs := PackedVector2Array()) -> void:
	var n := (b - a).cross(c - a)
	if n.length() < 0.000001:
		return
	n = n.normalized()
	if forzar_arriba and n.y < 0.0:
		var tmp := b
		b = c
		c = tmp
		n = -n
	verts.append(a)
	verts.append(b)
	verts.append(c)
	normals.append(n)
	normals.append(n)
	normals.append(n)
	cols.append(color)
	cols.append(color)
	cols.append(color)
	if p_uvs.size() == 3:
		m_uvs.append(p_uvs[0])
		m_uvs.append(p_uvs[1])
		m_uvs.append(p_uvs[2])
