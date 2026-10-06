class_name Npc
extends StaticBody2D

## NPC genérico reutilizable. Se pone 3 veces en el interior del edificio y a
## cada copia se le cambia "Tipo" en el Inspector para decidir qué pregunta hace.
##
## Con "Textura" asignada: está quieto en su cuadro de reposo; cuando el jugador
## entra en su zona, reproduce su animación una vez y da un pasito hacia él.
## Al alejarse el jugador, vuelve a su sitio.

enum Tipo { FORTALEZA_1, FORTALEZA_2, OBJETIVO }

signal jugador_cerca(npc: Npc)
signal jugador_lejos(npc: Npc)

@export var tipo: Tipo = Tipo.FORTALEZA_1

@export_group("Sprite")
@export var textura: Texture2D
## Cuadros por fila de la imagen.
@export var cuadros: int = 9
## Filas de la imagen (1 si es una sola tira).
@export var filas: int = 1
## Fila que se usa para la animación (0 = la primera).
@export var fila_animacion: int = 0
## Cuadro (dentro de la fila) que se muestra cuando está quieto.
@export var cuadro_reposo: int = 0
@export var cuadros_por_segundo: float = 10.0

@export_group("Pasito")
@export var distancia_paso: float = 6.0
@export var duracion_paso: float = 0.35

const NOMBRES := {
	Tipo.FORTALEZA_1: "Fortaleza 1",
	Tipo.FORTALEZA_2: "Fortaleza 2",
	Tipo.OBJETIVO: "Objetivo",
}

# Color de respaldo mientras un NPC no tenga imagen.
const COLORES := {
	Tipo.FORTALEZA_1: Color(0.25, 0.6, 0.85),
	Tipo.FORTALEZA_2: Color(0.3, 0.75, 0.45),
	Tipo.OBJETIVO: Color(0.85, 0.45, 0.6),
}

var _tiempo: float = 0.0
var _reproduciendo: bool = false
var _posicion_reposo: Vector2
var _tween: Tween

@onready var visual: ColorRect = $Visual
@onready var sprite: Sprite2D = $Sprite
@onready var etiqueta: Label = $Etiqueta
@onready var zona: Area2D = $ZonaInteraccion


func _ready() -> void:
	etiqueta.text = NOMBRES[tipo]
	set_process(false)

	if textura != null:
		sprite.texture = textura
		sprite.hframes = cuadros
		sprite.vframes = filas
		_posicion_reposo = sprite.position
		_mostrar_cuadro(cuadro_reposo)
		visual.visible = false
	else:
		sprite.visible = false
		visual.color = COLORES[tipo]

	zona.body_entered.connect(_on_zona_body_entered)
	zona.body_exited.connect(_on_zona_body_exited)


func _process(delta: float) -> void:
	_tiempo += delta
	var cuadro := int(_tiempo * cuadros_por_segundo)
	if cuadro >= cuadros:
		# Terminó la animación: se queda en el cuadro de reposo.
		_reproduciendo = false
		set_process(false)
		_mostrar_cuadro(cuadro_reposo)
	else:
		_mostrar_cuadro(cuadro)


func _mostrar_cuadro(cuadro: int) -> void:
	sprite.frame = fila_animacion * cuadros + cuadro


func _acercarse(jugador: Node2D) -> void:
	if textura == null:
		return
	var direccion := (jugador.global_position - global_position).normalized()

	_tiempo = 0.0
	_reproduciendo = true
	set_process(true)

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(sprite, "position", _posicion_reposo + direccion * distancia_paso, duracion_paso) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _alejarse() -> void:
	if textura == null:
		return
	_reproduciendo = false
	set_process(false)
	_mostrar_cuadro(cuadro_reposo)

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(sprite, "position", _posicion_reposo, duracion_paso) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_zona_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		jugador_cerca.emit(self)
		_acercarse(body)


func _on_zona_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		jugador_lejos.emit(self)
		_alejarse()
