extends Control

func _ready() -> void:
	GameState.enfocar_primer_boton(self)


func _on_boton_iniciar_pressed() -> void:
	GameState.ir_a_escena("res://escenas/ui/SeleccionPersonaje.tscn")
