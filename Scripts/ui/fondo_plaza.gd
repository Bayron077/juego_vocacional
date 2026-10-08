class_name FondoPlaza
extends TextureRect
## Fondo de la plaza para las pantallas de menú: ocupa toda la pantalla,
## lleva nubes que se mueven y un velo oscuro opcional para leer mejor el texto.

const RUTA_TEXTURA := "res://assets/fondos/fondo_plaza.png"
const COLOR_VELO := Color(0.04, 0.06, 0.18)

const NUBES := [
	{"ruta": "res://assets/fondos/nubes/nube_2.png", "x": 30.0,  "y": 10.0, "vel": 5.0, "espejo": false},
	{"ruta": "res://assets/fondos/nubes/nube_3.png", "x": 190.0, "y": 36.0, "vel": 8.0, "espejo": false},
	{"ruta": "res://assets/fondos/nubes/nube_4.png", "x": 330.0, "y": 22.0, "vel": 6.0, "espejo": false},
	{"ruta": "res://assets/fondos/nubes/nube_2.png", "x": 420.0, "y": 28.0, "vel": 4.0, "espejo": true},
]

## Qué tanto se oscurece el fondo (0 = nada, 1 = negro).
@export_range(0.0, 1.0, 0.05) var oscurecimiento: float = 0.35
@export var con_nubes: bool = true

var _nubes: Array[TextureRect] = []
var _posiciones: Array[float] = []
var _velocidades: Array[float] = []


func _ready() -> void:
	texture = load(RUTA_TEXTURA)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	if con_nubes:
		_crear_nubes()
	if oscurecimiento > 0.0:
		_crear_velo()
	set_process(con_nubes)


func _crear_velo() -> void:
	var velo := ColorRect.new()
	velo.color = Color(COLOR_VELO.r, COLOR_VELO.g, COLOR_VELO.b, oscurecimiento)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(velo)


func _crear_nubes() -> void:
	for datos in NUBES:
		var nube := TextureRect.new()
		nube.texture = load(datos["ruta"])
		nube.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nube.flip_h = datos["espejo"]
		nube.position = Vector2(datos["x"], datos["y"])
		add_child(nube)
		_nubes.append(nube)
		_posiciones.append(datos["x"])
		_velocidades.append(datos["vel"])


func _process(delta: float) -> void:
	for i in _nubes.size():
		_posiciones[i] += _velocidades[i] * delta
		var nube := _nubes[i]
		if _posiciones[i] > size.x:
			_posiciones[i] = -nube.size.x
		nube.position.x = roundf(_posiciones[i])
