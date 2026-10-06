extends Control


var areas_interes: Array[String] = [
	"Tecnología y computación",
	"Matemáticas y ciencias exactas",
	"Ciencias naturales y experimentales",
	"Ingeniería y tecnología aplicada",
	"Electricidad, electrónica y automatización",
	"Industria, manufactura y producción",
	"Medio ambiente y sostenibilidad",
	"Agro, territorio y naturaleza",
	"Administración, negocios y emprendimiento",
	"Educación y enseñanza",
	"Comunicación, medios y creatividad",
	"Turismo, cultura y servicios",
	"Salud y cuidado",
	"Artes, música y expresión creativa",
	"Sociedad, cultura y humanidades",
	"Deporte, actividad física y recreación",
	"Idiomas, lenguas y comunicación intercultural"
]

func _ready() -> void:
	$ContenedorScroll.offset_bottom = 0.0
	for area in areas_interes:
		var boton := Button.new()
		boton.text = area
		boton.pressed.connect(_on_area_elegida.bind(area))
		$ContenedorScroll/ListaAreas.add_child(boton)

	# Con el D-pad la lista debe desplazarse sola hacia el botón enfocado.
	$ContenedorScroll.follow_focus = true
	GameState.enfocar_primer_boton(self)


func _on_area_elegida(area: String) -> void:
	GameState.elegir_area(area)
	GameState.ir_a_escena("res://escenas/mundo/mapa_area.tscn")
