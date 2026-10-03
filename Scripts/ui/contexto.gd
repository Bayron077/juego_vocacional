extends Control

var dialogos: Array[String] = [
	"La ciudad universitaria ha quedado fragmentada en distritos aislados.",
	"Cada distrito representa un área del conocimiento distinta.",
	"Tu misión es explorar, descubrir tus fortalezas y tus objetivos,",
	"y con eso, ayudar a reconstruir el campus, un área a la vez."
]

var indice_actual: int = 0

func _ready() -> void:
	mostrar_dialogo_actual()

func mostrar_dialogo_actual() -> void:
	$TextoDialogo.text = dialogos[indice_actual]

func _on_boton_siguiente_pressed() -> void:
	indice_actual += 1
	if indice_actual < dialogos.size():
		mostrar_dialogo_actual()
	else:
		GameState.ir_a_escena("res://escenas/ui/selector_area.tscn")
