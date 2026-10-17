extends Control

# Nubes que se desplazan despacio por el cielo (de izquierda a derecha).
# "y" es la altura en píxeles, "vel" los píxeles por segundo y "x" la posición inicial.
const NUBES := [
	{"ruta": "res://assets/fondos/nubes/nube_2.png", "x": 30.0,  "y": 10.0, "vel": 5.0, "espejo": false},
	{"ruta": "res://assets/fondos/nubes/nube_3.png", "x": 190.0, "y": 36.0, "vel": 8.0, "espejo": false},
	{"ruta": "res://assets/fondos/nubes/nube_4.png", "x": 330.0, "y": 22.0, "vel": 6.0, "espejo": false},
	{"ruta": "res://assets/fondos/nubes/nube_2.png", "x": 420.0, "y": 28.0, "vel": 4.0, "espejo": true},
]

# Registro opcional: si existe data/registro_config.json, se muestra arriba a la
# derecha un QR para registrarse desde el celular y el código de la partida.
# El jugador puede pulsar "Iniciar juego" sin escanear nada.
# Cada módulo del QR mide 2 px en el juego (480x270). Con la TV a 1080p son 8 px
# por módulo: se lee bien desde 1 a 2 metros.
const PIXELES_POR_MODULO := 2
# Margen blanco alrededor del QR, en módulos (el estándar pide 4; con 3 se lee igual).
const MODULOS_BORDE := 3
# Separación del panel respecto al borde derecho y superior de la pantalla.
const MARGEN_PANEL := 8
# Textos del panel con la fuente normal de Godot (no la pixelada del tema): así el
# código se lee sin confusión desde lejos.
const TAM_INVITACION := 14
const TAM_CODIGO := 16
# El texto del código se achica solo, hasta este tamaño, si no cabe en el ancho del QR.
# Así el panel nunca se ensancha ni se mete sobre el cartel UTP.
const TAM_CODIGO_MINIMO := 10
const COLOR_ORO := Color(1.0, 0.85, 0.25)

var _nubes: Array[TextureRect] = []
var _posiciones: Array[float] = []
var _velocidades: Array[float] = []


func _ready() -> void:
	_ajustar_fondo()
	_crear_nubes()
	_ubicar_boton()
	GameState.enfocar_primer_boton(self)
	# Código nuevo en cada pantalla de inicio y, si el registro está activo, su QR.
	Registro.nuevo_codigo()
	if Registro.habilitado():
		_construir_panel_registro()


func _ajustar_fondo() -> void:
	# Fuerza al fondo a ocupar exactamente la pantalla, sin importar el tamaño
	# de la imagen (si no, un TextureRect adopta el tamaño de su textura).
	var fondo: TextureRect = $Fondo
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_SCALE
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.offset_left = 0.0
	fondo.offset_top = 0.0
	fondo.offset_right = 0.0
	fondo.offset_bottom = 0.0


func _ubicar_boton() -> void:
	# Abajo al centro, sobre el camino de piedra entre las dos bancas.
	var boton: Button = $BotonIniciar
	boton.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	boton.offset_left = -52.0
	boton.offset_right = 52.0
	boton.offset_top = -44.0
	boton.offset_bottom = -16.0


func _crear_nubes() -> void:
	# Contenedor que recorta lo que se sale de la pantalla.
	var capa := Control.new()
	capa.name = "Nubes"
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.clip_contents = true
	add_child(capa)
	# Justo encima del fondo y debajo del botón.
	move_child(capa, $Fondo.get_index() + 1)

	for datos in NUBES:
		var nube := TextureRect.new()
		nube.texture = load(datos["ruta"])
		nube.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nube.flip_h = datos["espejo"]
		nube.position = Vector2(datos["x"], datos["y"])
		capa.add_child(nube)
		_nubes.append(nube)
		_posiciones.append(datos["x"])
		_velocidades.append(datos["vel"])


func _process(delta: float) -> void:
	var ancho := size.x
	for i in _nubes.size():
		_posiciones[i] += _velocidades[i] * delta
		var nube := _nubes[i]
		if _posiciones[i] > ancho:
			# Sale por la derecha y reaparece por la izquierda.
			_posiciones[i] = -nube.size.x
		# Redondeado a píxel entero para que no tiemble.
		nube.position.x = roundf(_posiciones[i])


func _construir_panel_registro() -> void:
	var qr := QRCodigo.crear(Registro.url_formulario())
	if qr == null:
		push_warning("Inicio: no se pudo generar el QR de registro.")
		return
	var imagen := qr.a_imagen(PIXELES_POR_MODULO, MODULOS_BORDE)
	var lado := imagen.get_width()

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.09, 0.1, 0.19, 0.95)
	estilo.border_color = Color(0.36, 0.41, 0.68)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(4)
	estilo.set_content_margin_all(4)

	var panel := PanelContainer.new()
	panel.name = "PanelRegistro"
	panel.add_theme_stylebox_override("panel", estilo)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Anclado a la esquina superior derecha; crece hacia adentro según su contenido.
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_right = -MARGEN_PANEL
	panel.offset_top = MARGEN_PANEL
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_END
	add_child(panel)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 2)
	panel.add_child(caja)

	var invitacion := _crear_etiqueta("Regístrate", TAM_INVITACION, false)
	invitacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	invitacion.custom_minimum_size = Vector2(lado, 0)
	invitacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(invitacion)

	var cuadro := TextureRect.new()
	cuadro.texture = ImageTexture.create_from_image(imagen)
	cuadro.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cuadro.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cuadro.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cuadro.custom_minimum_size = Vector2(lado, lado)  # 1 a 1: sin escalar, nítido
	cuadro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(cuadro)

	var codigo := _crear_etiqueta("Código: %s" % Registro.codigo_actual, TAM_CODIGO, true)
	codigo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	codigo.add_theme_color_override("font_color", COLOR_ORO)
	codigo.custom_minimum_size = Vector2(lado, 0)
	codigo.clip_text = true  # sin esto, un texto ancho ensancharía todo el panel
	_ajustar_al_ancho(codigo, lado)
	caja.add_child(codigo)


## Baja el tamaño de letra de la etiqueta hasta que su texto quepa en `ancho` píxeles.
func _ajustar_al_ancho(etiqueta: Label, ancho: int) -> void:
	var fuente := etiqueta.get_theme_font("font")
	var tamano := etiqueta.get_theme_font_size("font_size")
	while tamano > TAM_CODIGO_MINIMO and fuente.get_string_size(etiqueta.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x > ancho:
		tamano -= 1
	etiqueta.add_theme_font_size_override("font_size", tamano)


func _crear_etiqueta(texto: String, tamano: int, negrita: bool) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	# Fuente integrada de Godot, con más separación entre letras (y en negrita el código).
	var fuente := FontVariation.new()
	fuente.base_font = ThemeDB.fallback_font
	fuente.spacing_glyph = 1
	if negrita:
		fuente.variation_embolden = 0.6
		fuente.spacing_glyph = 2
	etiqueta.add_theme_font_override("font", fuente)
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	etiqueta.add_theme_constant_override("outline_size", 0)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return etiqueta


func _on_boton_iniciar_pressed() -> void:
	GameState.ir_a_escena("res://escenas/ui/SeleccionPersonaje.tscn")
