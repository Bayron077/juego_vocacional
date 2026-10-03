extends Control

func _ready() -> void:
	$InfoTexto.text = "Aquí irá el mapa del área: " + GameState.area_elegida + "\n(Personaje: " + GameState.personaje_elegido + ")"
