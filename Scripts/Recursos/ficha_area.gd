class_name  FichaArea
extends  Resource
#nombre del area que aparece en el selector
@export var nombre_area: String = ""

##nombre del edificio que representa el area dentro del mapa
@export var nombre_edificio: String = "Edificio"

## Color de fondo de la zona, para diferenciar cada área mientras no hay arte.
@export var color_zona: Color = Color(0.5, 0.5, 0.5, 1)

## Dónde aparece el jugador al entrar al mapa de esta área.
@export var posicion_jugador_inicial: Vector2 = Vector2(100, 220)

## Dónde se dibuja el edificio (y su zona de entrada) dentro del mapa.
@export var posicion_edificio: Vector2 = Vector2(450, 150)
