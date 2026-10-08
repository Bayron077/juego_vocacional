extends Control

## Ancho de cada botón de área (en píxeles del juego). El texto más largo,
## "Electricidad, electrónica y automatización", cabe con holgura en 320.
const ANCHO_BOTON := 320.0
const SEPARACION := 4

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
	# Solo scroll vertical; la lista ocupa todo el ancho para poder centrar los botones.
	$ContenedorScroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var lista: VBoxContainer = $ContenedorScroll/ListaAreas
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", SEPARACION)

	for area in areas_interes:
		var boton := Button.new()
		boton.text = area
		boton.custom_minimum_size = Vector2(ANCHO_BOTON, 0)
		boton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		boton.pressed.connect(_on_area_elegida.bind(area))
		lista.add_child(boton)

	# Con el D-pad la lista debe desplazarse sola hacia el botón enfocado.
	$ContenedorScroll.follow_focus = true
	GameState.enfocar_primer_boton(self)


func _on_area_elegida(area: String) -> void:
	GameState.elegir_area(area)
	GameState.ir_a_escena("res://escenas/mundo/mapa_area.tscn")
