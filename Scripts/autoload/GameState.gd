extends Node

var personaje_elegido: String = ""
var area_elegida: String = ""


func ir_a_escena(ruta: String) -> void:
	get_tree().change_scene_to_file(ruta)
	
func elegir_personaje(valor: String) -> void:
	personaje_elegido = valor
func elegir_area(valor: String) -> void:
	area_elegida = valor
