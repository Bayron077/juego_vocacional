extends Control

## Pantalla final: top 3 de programas con mayor afinidad.
## Las tarjetas se construyen por código a partir de MotorResultados.

const ESCENA_INICIO := "res://escenas/ui/inicio.tscn"

## Texto corrido: Pixelify Sans (la fuente del tema), nítida en 12 y 16.
## Título y botón: Jersey 10 (fuente_titulo.ttf), nítida en 10, 20 y 30.
const RUTA_FUENTE_TITULO := "res://assets/fuentes/fuente_titulo.ttf"
const TAM_TITULO := 20
const TAM_NOMBRE := 12
const TAM_TEXTO := 12
const TAM_BOTON := 20
const MEDALLAS := [
	"res://assets/ui/medalla_1.png",
	"res://assets/ui/medalla_2.png",
	"res://assets/ui/medalla_3.png",
]
const RUTA_MAPA_AREA := "res://Scripts/mundo/mapa_area.gd"
## Qué tan oscuro se ve el arte del fondo (0 = nada, 1 = negro).
const OSCURECER_FONDO := 0.78

const LINEAS_NOMBRE := 3
const LINEAS_FACULTAD := 2
const LINEAS_LEYENDA := 4

## Cada cuántos segundos la leyenda pasa sola a la siguiente carrera, y cuántos
## segundos se queda quieta después de que el jugador use la cruceta.
const SEGUNDOS_ROTACION := 6.0
const SEGUNDOS_PAUSA_MANUAL := 12.0

var _tarjetas: Array[PanelContainer] = []
var _estilo_normal: StyleBoxFlat
var _estilo_activo: StyleBoxFlat
var _leyendas: Array[String] = []
var _etiqueta_leyenda: Label
var _seleccion: int = 0
var _ultimo_input_ms: int = -100000

const COLOR_ORO := Color(1.0, 0.85, 0.25)
const COLOR_APAGADO := Color(0.72, 0.75, 0.88)


func _ready() -> void:
	var top := MotorResultados.calcular_top(
		GameState.area_elegida,
		GameState.fortaleza_1,
		GameState.fortaleza_2,
		GameState.objetivo
	)
	Registro.enviar_resultado(top)
	_poner_fondo_arte()
	_poner_confeti()
	_construir(top)


## Usa el mapa del área que eligió el jugador como fondo, oscurecido para que
## el texto se lea. Si no hay arte para esa área, queda el azul de siempre.
func _poner_fondo_arte() -> void:
	var fichas: Dictionary = load(RUTA_MAPA_AREA).get_script_constant_map().get("FICHAS_POR_AREA", {})
	var archivo: String = fichas.get(GameState.area_elegida, "")
	var datos: Dictionary = DatosMapas.MAPAS.get(archivo.get_basename(), {})
	if datos.is_empty() or not ResourceLoader.exists(datos["imagen"]):
		return

	var arte := TextureRect.new()
	arte.texture = load(datos["imagen"])
	arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arte)
	arte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var velo := ColorRect.new()
	velo.color = Color(0.05, 0.06, 0.2, OSCURECER_FONDO)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Confeti suave que cae desde arriba.
func _poner_confeti() -> void:
	var confeti := CPUParticles2D.new()
	confeti.position = Vector2(240, -6)
	confeti.amount = 36
	confeti.lifetime = 5.0
	confeti.preprocess = 5.0
	confeti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confeti.emission_rect_extents = Vector2(250, 2)
	confeti.direction = Vector2.DOWN
	confeti.spread = 12.0
	confeti.gravity = Vector2(0, 14)
	confeti.initial_velocity_min = 10.0
	confeti.initial_velocity_max = 28.0
	confeti.angular_velocity_min = -90.0
	confeti.angular_velocity_max = 90.0
	confeti.scale_amount_min = 1.0
	confeti.scale_amount_max = 2.5
	var colores := Gradient.new()
	colores.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	colores.colors = PackedColorArray([
		Color(1.0, 0.85, 0.25), Color(1, 1, 1),
		Color(0.4, 0.85, 1.0), Color(1.0, 0.5, 0.6)])
	confeti.color_initial_ramp = colores
	add_child(confeti)


func _construir(top: Array) -> void:
	var margen := MarginContainer.new()
	add_child(margen)
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 6)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 3)
	margen.add_child(caja)

	var titulo := _crear_etiqueta("Tus 3 carreras con más afinidad", TAM_TITULO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", COLOR_ORO)
	_usar_fuente_titulo(titulo)
	caja.add_child(titulo)

	var fila := HBoxContainer.new()
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_theme_constant_override("separation", 4)
	caja.add_child(fila)
	_crear_estilos()
	for i in top.size():
		fila.add_child(_crear_tarjeta(i, top[i]))
		_leyendas.append("%s — %s" % [top[i]["modalidad"], top[i]["descripcion"]])

	# Leyenda: la descripción completa de la carrera seleccionada.
	var panel_leyenda := PanelContainer.new()
	panel_leyenda.add_theme_stylebox_override("panel", _estilo_normal)
	caja.add_child(panel_leyenda)
	var margen_leyenda := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen_leyenda.add_theme_constant_override("margin_" + lado, 3)
	panel_leyenda.add_child(margen_leyenda)
	_etiqueta_leyenda = _crear_etiqueta("", TAM_TEXTO, true)
	_etiqueta_leyenda.max_lines_visible = LINEAS_LEYENDA
	_etiqueta_leyenda.custom_minimum_size = Vector2(0, 16 * 3)
	margen_leyenda.add_child(_etiqueta_leyenda)
	_seleccionar(0)

	var reloj := Timer.new()
	reloj.wait_time = SEGUNDOS_ROTACION
	reloj.autostart = true
	reloj.timeout.connect(_rotar_leyenda)
	add_child(reloj)

	# Fila inferior: sellos a la derecha, botón centrado.
	var pie := HBoxContainer.new()
	caja.add_child(pie)

	var izquierda := Control.new()
	izquierda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(izquierda)

	var boton := Button.new()
	boton.text = "Jugar de nuevo"
	boton.add_theme_font_size_override("font_size", TAM_BOTON)
	_usar_fuente_titulo(boton)
	boton.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	boton.pressed.connect(_on_jugar_de_nuevo)
	pie.add_child(boton)

	var sellos := _crear_etiqueta("", TAM_TEXTO)
	if not GameState.sellos.is_empty():
		sellos.text = "Sellos: %d" % GameState.sellos.size()
	sellos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sellos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sellos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sellos.clip_text = true
	sellos.add_theme_color_override("font_color", COLOR_ORO)
	pie.add_child(sellos)

	boton.grab_focus.call_deferred()  # para poder confirmar con el mando


func _crear_tarjeta(indice: int, programa: Dictionary) -> PanelContainer:
	var tarjeta := PanelContainer.new()
	tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tarjeta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tarjeta.clip_contents = true  # si algo no cabe, se corta en vez de salirse
	# Panel un poco transparente para que se vea el arte de fondo.
	tarjeta.add_theme_stylebox_override("panel", _estilo_normal)
	_tarjetas.append(tarjeta)

	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 4)
	tarjeta.add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 2)
	margen.add_child(caja)

	var afinidad: int = programa["afinidad"]
	# Cabecera: medalla + nivel y porcentaje.
	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 4)
	caja.add_child(cabecera)
	var medalla := TextureRect.new()
	medalla.texture = load(MEDALLAS[indice])
	medalla.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	medalla.stretch_mode = TextureRect.STRETCH_KEEP
	cabecera.add_child(medalla)
	var nivel := _crear_etiqueta("%s · %d%%" % [_nivel(afinidad), afinidad], TAM_TEXTO)
	nivel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nivel.add_theme_color_override("font_color", COLOR_ORO)
	cabecera.add_child(nivel)

	caja.add_child(_crear_etiqueta(programa["nombre"], TAM_NOMBRE, true, LINEAS_NOMBRE))

	var barra := ProgressBar.new()
	barra.max_value = 100
	barra.value = afinidad
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 6)
	caja.add_child(barra)

	var facultad := _crear_etiqueta(programa["facultad"], TAM_TEXTO, true, LINEAS_FACULTAD)
	facultad.add_theme_color_override("font_color", COLOR_APAGADO)
	caja.add_child(facultad)


	return tarjeta


func _crear_estilos() -> void:
	# Panel un poco transparente para que se vea el arte de fondo. Los dos estilos
	# tienen el mismo borde (3 px) para que al cambiar la selección nada se mueva.
	_estilo_normal = StyleBoxFlat.new()
	_estilo_normal.bg_color = Color(0.09, 0.1, 0.19, 0.9)
	_estilo_normal.border_color = Color(0.36, 0.41, 0.68)
	_estilo_normal.set_border_width_all(3)
	_estilo_normal.set_corner_radius_all(4)

	_estilo_activo = _estilo_normal.duplicate() as StyleBoxFlat
	_estilo_activo.bg_color = Color(0.14, 0.16, 0.3, 0.95)
	_estilo_activo.border_color = COLOR_ORO


## Resalta una carrera y muestra su leyenda.
func _seleccionar(indice: int) -> void:
	_seleccion = clampi(indice, 0, _tarjetas.size() - 1)
	for i in _tarjetas.size():
		_tarjetas[i].add_theme_stylebox_override("panel", _estilo_activo if i == _seleccion else _estilo_normal)
	_etiqueta_leyenda.text = _leyendas[_seleccion]


func _rotar_leyenda() -> void:
	if Time.get_ticks_msec() - _ultimo_input_ms < int(SEGUNDOS_PAUSA_MANUAL * 1000.0):
		return
	_seleccionar((_seleccion + 1) % _tarjetas.size())


## Izquierda/derecha (cruceta, stick o flechas) cambian de carrera.
func _input(event: InputEvent) -> void:
	if _tarjetas.is_empty() or event.is_echo():
		return
	var cambio := 0
	if event.is_action_pressed("ui_left"):
		cambio = -1
	elif event.is_action_pressed("ui_right"):
		cambio = 1
	if cambio != 0:
		_ultimo_input_ms = Time.get_ticks_msec()
		_seleccionar(_seleccion + cambio)


## Mismos cortes que la hoja DASHBOARD del Excel.
func _nivel(afinidad: int) -> String:
	if afinidad >= 80:
		return "Alta"
	if afinidad >= 50:
		return "Media"
	return "Baja"


## max_lineas = 0 significa sin límite.
## Pone la fuente de títulos (si existe) en un Label o un Button.
func _usar_fuente_titulo(control: Control) -> void:
	if ResourceLoader.exists(RUTA_FUENTE_TITULO):
		control.add_theme_font_override("font", load(RUTA_FUENTE_TITULO))


func _crear_etiqueta(texto: String, tamano: int, ajustar: bool = false, max_lineas: int = 0) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_constant_override("line_spacing", 0)
	# Sin sombra ni contorno: a este tamaño empastan las letras.
	etiqueta.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	etiqueta.add_theme_constant_override("shadow_offset_x", 0)
	etiqueta.add_theme_constant_override("shadow_offset_y", 0)
	etiqueta.add_theme_constant_override("outline_size", 0)
	if ajustar:
		etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if max_lineas > 0:
		etiqueta.max_lines_visible = max_lineas
		etiqueta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return etiqueta


func _on_jugar_de_nuevo() -> void:
	GameState.reiniciar_respuestas()
	GameState.ir_a_escena(ESCENA_INICIO)
