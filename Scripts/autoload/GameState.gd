extends Node

const ESCENA_INICIO := "res://escenas/ui/inicio.tscn"

## Segundos sin tocar nada tras los cuales el juego vuelve al inicio (para el stand).
const TIEMPO_INACTIVIDAD := 90.0
## Un movimiento de stick menor a esto no cuenta como actividad (evita falsos positivos por drift).
const UMBRAL_STICK := 0.5

var personaje_elegido: String = ""
var area_elegida: String = ""

# Respuestas del test: se guarda el texto EXACTO de la matriz.
var fortaleza_1: String = ""
var fortaleza_2: String = ""
var objetivo: String = ""

## Verdadero cuando el jugador sale del interior de un edificio hacia el mapa:
## el mapa lo coloca frente a la puerta en vez de en el punto inicial.
var regreso_de_interior: bool = false

var _segundos_inactivo: float = 0.0
# Sellos ganados en los retos (uno por área, sin repetir)
var sellos: Array[String] = []

func agregar_sello(area: String) -> void:
	if not sellos.has(area):
		sellos.append(area)

func tiene_sello(area: String) -> bool:
	return sellos.has(area)

func _ready() -> void:
	# Debe seguir contando aunque el juego esté en pausa (diálogo abierto).
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion and absf(event.axis_value) < UMBRAL_STICK:
		return
	_segundos_inactivo = 0.0


func _process(delta: float) -> void:
	var escena := get_tree().current_scene
	# En la pantalla de inicio no hay nada que reiniciar.
	if escena == null or escena.scene_file_path == ESCENA_INICIO:
		_segundos_inactivo = 0.0
		return

	# Un stick sostenido sin cambios no genera eventos nuevos, pero sí es actividad.
	if Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").length() > UMBRAL_STICK:
		_segundos_inactivo = 0.0
		return

	_segundos_inactivo += delta
	if _segundos_inactivo >= TIEMPO_INACTIVIDAD:
		_reiniciar_por_inactividad()


func _reiniciar_por_inactividad() -> void:
	print("Inactividad: volviendo al inicio.")
	_segundos_inactivo = 0.0
	reiniciar_respuestas()
	regreso_de_interior = false
	get_tree().paused = false
	ir_a_escena(ESCENA_INICIO)


func ir_a_escena(ruta: String) -> void:
	get_tree().change_scene_to_file(ruta)


func elegir_personaje(valor: String) -> void:
	personaje_elegido = valor


func elegir_area(valor: String) -> void:
	area_elegida = valor
	regreso_de_interior = false


func guardar_respuesta(tipo: int, valor: String) -> void:
	match tipo:
		Npc.Tipo.FORTALEZA_1:
			fortaleza_1 = valor
		Npc.Tipo.FORTALEZA_2:
			fortaleza_2 = valor
		Npc.Tipo.OBJETIVO:
			objetivo = valor


func respuestas_dadas() -> int:
	var total := 0
	for valor in [fortaleza_1, fortaleza_2, objetivo]:
		if valor != "":
			total += 1
	return total


func respuestas_completas() -> bool:
	return respuestas_dadas() == 3


func reiniciar_respuestas() -> void:
	fortaleza_1 = ""
	fortaleza_2 = ""
	objetivo = ""
	sellos.clear()


## Pone el foco en el primer botón que encuentre dentro de `raiz`.
## Con el foco puesto, el D-pad / stick mueven la selección y A (o Enter) la pulsa.
func enfocar_primer_boton(raiz: Node) -> void:
	var botones := raiz.find_children("*", "Button", true, false)
	if botones.is_empty():
		return
	var primero := botones[0] as Button
	primero.grab_focus.call_deferred()
