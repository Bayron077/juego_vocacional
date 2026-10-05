extends Control

func _ready() -> void:
	GameState.enfocar_primer_boton(self)


func _on_boton_masculino_pressed() -> void:
	GameState.elegir_personaje("masculino")
	GameState.ir_a_escena("res://escenas/ui/contexto.tscn")


func _on_boton_femenino_pressed() -> void:
	GameState.elegir_personaje("femenino")
	GameState.ir_a_escena("res://escenas/ui/contexto.tscn")
