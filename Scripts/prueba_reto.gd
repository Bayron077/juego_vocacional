extends Node

func _ready() -> void:
	var reto := Reto.new()
	add_child(reto)
	reto.iniciar(
		FichaArea.TipoReto.SECUENCIA,   # cambia a TIMING para probar la otra
		"Reto de prueba",
		"Memoriza las flechas y repítelas en el mismo orden."
	)
	reto.terminado.connect(func(ok): print("Reto terminado. Completado = ", ok))
