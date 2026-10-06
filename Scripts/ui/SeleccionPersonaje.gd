extends Control

## Selección de personaje: cada botón muestra el sprite de su personaje.
## El que tiene el foco (o el mouse encima) camina de frente; el otro está quieto.

const TEXTURA_MASCULINO: Texture2D = preload("res://assets/levy.png")
const TEXTURA_FEMENINO: Texture2D = preload("res://assets/Eda.png")

# Disposición de las hojas de sprites de los personajes: 9 columnas x 4 filas.
# La fila 0 es el personaje de frente: cuadro 0 = quieto, 1 a 8 = caminando.
const COLUMNAS := 9
const FILAS := 4
const CUADROS_POR_SEGUNDO := 10.0
const TAMANO_BOTON := Vector2(96, 110)

var _atlas_por_boton: Dictionary = {}
var _tiempo: float = 0.0


func _ready() -> void:
	_preparar_boton("BotonMasculino", TEXTURA_MASCULINO)
	_preparar_boton("BotonFemenino", TEXTURA_FEMENINO)
	GameState.enfocar_primer_boton(self)


func _process(delta: float) -> void:
	_tiempo += delta
	# Ciclo de caminar: cuadros 1 a 8 (el 0 es el de reposo).
	var cuadro_caminando := 1 + int(_tiempo * CUADROS_POR_SEGUNDO) % (COLUMNAS - 1)

	for boton in _atlas_por_boton.keys():
		var activo: bool = boton.has_focus() or boton.is_hovered()
		_mostrar_cuadro(_atlas_por_boton[boton], cuadro_caminando if activo else 0)


func _preparar_boton(nombre: String, textura: Texture2D) -> void:
	var boton := find_child(nombre, true, false) as Button
	if boton == null:
		push_warning("No se encontró el botón '%s' en SeleccionPersonaje." % nombre)
		return

	var atlas := AtlasTexture.new()
	atlas.atlas = textura
	_mostrar_cuadro(atlas, 0)

	boton.icon = atlas
	boton.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boton.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP  # sprite arriba, texto debajo
	boton.custom_minimum_size = TAMANO_BOTON
	boton.mouse_entered.connect(boton.grab_focus)  # el mouse también resalta

	_atlas_por_boton[boton] = atlas


func _mostrar_cuadro(atlas: AtlasTexture, cuadro: int) -> void:
	var tamano_hoja := atlas.atlas.get_size()
	var ancho := tamano_hoja.x / COLUMNAS
	var alto := tamano_hoja.y / FILAS
	atlas.region = Rect2(cuadro * ancho, 0, ancho, alto)


func _on_boton_masculino_pressed() -> void:
	GameState.elegir_personaje("masculino")
	GameState.ir_a_escena("res://escenas/ui/contexto.tscn")


func _on_boton_femenino_pressed() -> void:
	GameState.elegir_personaje("femenino")
	GameState.ir_a_escena("res://escenas/ui/contexto.tscn")
