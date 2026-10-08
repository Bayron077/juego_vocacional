extends Control

## Una ilustración por cada frase de la historia (mismo orden que "dialogos").
const RUTAS_FONDOS: Array[String] = [
	"res://assets/fondos/historia_1.png",
	"res://assets/fondos/historia_2.png",
	"res://assets/fondos/historia_3.png",
	"res://assets/fondos/historia_4.png",
]

const RUTA_LEVY := "res://assets/levy.png"
const RUTA_EDA := "res://assets/Eda.png"

## Cuadro de la hoja de sprites que se muestra. 9 = el personaje de espaldas,
## mirando al paisaje. Si se ve de frente y lo quieres de espaldas (o al revés),
## cambia este número: 0 = de frente, 9 = de espaldas, 18 = izquierda, 27 = derecha.
const FRAME_PERSONAJE := 9
## Dónde pisa el personaje (sus pies), sobre el hueco de la ilustración.
const POSICION_PERSONAJE := Vector2(258, 180)
## A partir de qué frase (0 = la primera) aparece el personaje.
const PERSONAJE_DESDE := 2

const SEGUNDOS_POR_LETRA := 0.03
const DURACION_FUNDIDO := 0.25

var dialogos: Array[String] = [
	"La ciudad universitaria ha quedado fragmentada en distritos aislados.",
	"Cada distrito representa un área del conocimiento distinta.",
	"Tu misión es explorar, descubrir tus fortalezas y tus objetivos,",
	"y con eso, ayudar a reconstruir el campus, un área a la vez."
]

var indice_actual: int = 0

var _fondo: TextureRect
var _personaje: Sprite2D
var _escribiendo: bool = false
var _tween_texto: Tween

@onready var _texto: Label = $TextoDialogo
@onready var _boton: Button = $BotonSiguiente


func _ready() -> void:
	_crear_fondo()
	_crear_personaje()
	_crear_panel()
	_acomodar_interfaz()
	_mostrar_dialogo(true)
	GameState.enfocar_primer_boton(self)


## Reemplaza el fondo de color de la escena por una imagen a pantalla completa.
func _crear_fondo() -> void:
	var viejo := get_node_or_null("Fondo")
	if viejo != null:
		remove_child(viejo)
		viejo.queue_free()

	_fondo = TextureRect.new()
	_fondo.name = "Fondo"
	_fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fondo.stretch_mode = TextureRect.STRETCH_SCALE
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fondo)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.offset_left = 0.0
	_fondo.offset_top = 0.0
	_fondo.offset_right = 0.0
	_fondo.offset_bottom = 0.0
	move_child(_fondo, 0)


## El personaje elegido, de pie en el hueco de la ilustración (solo en las últimas escenas).
func _crear_personaje() -> void:
	var ruta := RUTA_EDA if GameState.personaje_elegido == "femenino" else RUTA_LEVY
	var textura: Texture2D = load(ruta)

	_personaje = Sprite2D.new()
	_personaje.name = "Personaje"
	_personaje.texture = textura
	_personaje.hframes = 9
	_personaje.vframes = 4
	_personaje.frame = FRAME_PERSONAJE
	# El punto de anclaje queda en los pies del personaje.
	var alto_cuadro := textura.get_height() / 4.0
	_personaje.offset = Vector2(0, -alto_cuadro / 2.0)
	_personaje.position = POSICION_PERSONAJE
	_personaje.visible = false
	add_child(_personaje)
	move_child(_personaje, 1)


## Caja de texto en la franja oscura de abajo (usa el estilo de Panel de tu tema).
func _crear_panel() -> void:
	var panel := Panel.new()
	panel.name = "PanelTexto"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	panel.position = Vector2(8, 214)
	panel.size = Vector2(464, 52)
	move_child(panel, 2)


## Coloca el texto y el botón dentro de la caja.
func _acomodar_interfaz() -> void:
	_texto.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_texto.position = Vector2(18, 218)
	_texto.size = Vector2(366, 44)
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.remove_theme_font_size_override("font_size")

	_boton.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_boton.position = Vector2(394, 228)
	_boton.size = Vector2(70, 26)


func _mostrar_dialogo(primera_vez: bool = false) -> void:
	_cambiar_fondo(RUTAS_FONDOS[indice_actual], primera_vez)
	_personaje.visible = indice_actual >= PERSONAJE_DESDE
	_boton.text = "Comenzar" if indice_actual == dialogos.size() - 1 else "Siguiente"
	_escribir_texto(dialogos[indice_actual])


## Cambia la ilustración con un fundido corto (la primera vez, sin fundido).
func _cambiar_fondo(ruta: String, sin_fundido: bool) -> void:
	if not ResourceLoader.exists(ruta):
		push_warning("Falta la imagen de la historia: " + ruta)
		return
	var textura: Texture2D = load(ruta)
	if sin_fundido:
		_fondo.texture = textura
		return
	var fundido := create_tween()
	fundido.tween_property(_fondo, "modulate:a", 0.0, DURACION_FUNDIDO)
	fundido.tween_callback(func() -> void: _fondo.texture = textura)
	fundido.tween_property(_fondo, "modulate:a", 1.0, DURACION_FUNDIDO)


## Efecto máquina de escribir.
func _escribir_texto(frase: String) -> void:
	if _tween_texto != null and _tween_texto.is_valid():
		_tween_texto.kill()
	_texto.text = frase
	_texto.visible_ratio = 0.0
	_escribiendo = true
	_tween_texto = create_tween()
	_tween_texto.tween_property(_texto, "visible_ratio", 1.0, frase.length() * SEGUNDOS_POR_LETRA)
	_tween_texto.finished.connect(func() -> void: _escribiendo = false)


func _on_boton_siguiente_pressed() -> void:
	# Si todavía está escribiendo, el primer clic completa la frase.
	if _escribiendo:
		if _tween_texto != null and _tween_texto.is_valid():
			_tween_texto.kill()
		_texto.visible_ratio = 1.0
		_escribiendo = false
		return

	indice_actual += 1
	if indice_actual < dialogos.size():
		_mostrar_dialogo()
	else:
		GameState.ir_a_escena("res://escenas/ui/selector_area.tscn")
