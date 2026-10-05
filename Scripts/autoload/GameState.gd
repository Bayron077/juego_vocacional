extends Node

var personaje_elegido: String = ""
var area_elegida: String = ""

# Respuestas del test: se guardan el texto EXACTO de la matriz.
var fortaleza_1: String = ""
var fortaleza_2: String = ""
var objetivo: String = ""


func ir_a_escena(ruta: String) -> void:
	get_tree().change_scene_to_file(ruta)


func elegir_personaje(valor: String) -> void:
	personaje_elegido = valor


func elegir_area(valor: String) -> void:
	area_elegida = valor


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
