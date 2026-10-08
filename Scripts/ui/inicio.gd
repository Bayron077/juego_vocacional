extends Control

# Nubes que se desplazan despacio por el cielo (de izquierda a derecha).
# "y" es la altura en píxeles, "vel" los píxeles por segundo y "x" la posición inicial.
const NUBES := [
	{"ruta": "res://assets/fondos/nubes/nube_2.png", "x": 30.0,  "y": 10.0, "vel": 5.0, "espejo": false},
	{"ruta": "res://assets/fondos/nubes/nube_3.png", "x": 190.0, "y": 36.0, "vel": 8.0, "espejo": false},
	{"ruta": "res://assets/fondos/nubes/nube_4.png", "x": 330.0, "y": 22.0, "vel": 6.0, "espejo": false},
	{"ruta": "res://assets/fondos/nubes/nube_2.png", "x": 420.0, "y": 28.0, "vel": 4.0, "espejo": true},
]

var _nubes: Array[TextureRect] = []
var _posiciones: Array[float] = []
var _velocidades: Array[float] = []


func _ready() -> void:
	_ajustar_fondo()
	_crear_nubes()
	_ubicar_boton()
	GameState.enfocar_primer_boton(self)


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


func _on_boton_iniciar_pressed() -> void:
	GameState.ir_a_escena("res://escenas/ui/SeleccionPersonaje.tscn")
