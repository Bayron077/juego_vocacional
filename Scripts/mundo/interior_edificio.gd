extends Control

## Interior reutilizable para las 17 áreas (por ahora un esqueleto).
## Aquí van luego los 3 NPCs: Fortaleza 1, Fortaleza 2 y Objetivo profesional.

@onready var etiqueta_titulo: Label = $EtiquetaTitulo
@onready var etiqueta_info: Label = $EtiquetaInfo


func _ready() -> void:
	etiqueta_titulo.text = "Interior: " + GameState.area_elegida
	etiqueta_info.text = "(Aquí irán los 3 NPCs: Fortaleza 1, Fortaleza 2 y Objetivo profesional)"


func _on_boton_salir_pressed() -> void:
	GameState.ir_a_escena("res://escenas/mundo/mapa_area.tscn")
