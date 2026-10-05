class_name Npc
extends StaticBody2D

## NPC genérico reutilizable. Se pone 3 veces en el interior del edificio y a
## cada copia se le cambia "Tipo" en el Inspector para decidir qué pregunta hace.

enum Tipo { FORTALEZA_1, FORTALEZA_2, OBJETIVO }

signal jugador_cerca(npc: Npc)
signal jugador_lejos(npc: Npc)

@export var tipo: Tipo = Tipo.FORTALEZA_1

const NOMBRES := {
	Tipo.FORTALEZA_1: "Fortaleza 1",
	Tipo.FORTALEZA_2: "Fortaleza 2",
	Tipo.OBJETIVO: "Objetivo",
}

# Cada tipo tiene su color para distinguirlos mientras no hay arte.
const COLORES := {
	Tipo.FORTALEZA_1: Color(0.25, 0.6, 0.85),
	Tipo.FORTALEZA_2: Color(0.3, 0.75, 0.45),
	Tipo.OBJETIVO: Color(0.85, 0.45, 0.6),
}

@onready var visual: ColorRect = $Visual
@onready var etiqueta: Label = $Etiqueta
@onready var zona: Area2D = $ZonaInteraccion


func _ready() -> void:
	visual.color = COLORES[tipo]
	etiqueta.text = NOMBRES[tipo]
	zona.body_entered.connect(_on_zona_body_entered)
	zona.body_exited.connect(_on_zona_body_exited)


func _on_zona_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		jugador_cerca.emit(self)


func _on_zona_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		jugador_lejos.emit(self)
