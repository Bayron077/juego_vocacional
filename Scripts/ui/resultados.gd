extends Control

## Pantalla final: top 3 de programas con mayor afinidad.
## Las tarjetas se construyen por código a partir de MotorResultados.

const ESCENA_INICIO := "res://escenas/ui/inicio.tscn"

const TAM_TITULO := 12
const TAM_NOMBRE := 9
const TAM_TEXTO := 7
const TAM_BOTON := 9
const MEDALLAS := ["1°", "2°", "3°"]

const LINEAS_NOMBRE := 3
const LINEAS_DESCRIPCION := 4


func _ready() -> void:
	var top := MotorResultados.calcular_top(
		GameState.area_elegida,
		GameState.fortaleza_1,
		GameState.fortaleza_2,
		GameState.objetivo
	)
	_construir(top)


func _construir(top: Array) -> void:
	var margen := MarginContainer.new()
	add_child(margen)
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 8)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 5)
	margen.add_child(caja)

	var titulo := _crear_etiqueta("Tus 3 carreras con más afinidad", TAM_TITULO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)

	var fila := HBoxContainer.new()
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_theme_constant_override("separation", 5)
	caja.add_child(fila)
	for i in top.size():
		fila.add_child(_crear_tarjeta(i, top[i]))

	var boton := Button.new()
	boton.text = "Jugar de nuevo"
	boton.add_theme_font_size_override("font_size", TAM_BOTON)
	boton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	boton.pressed.connect(_on_jugar_de_nuevo)
	caja.add_child(boton)
	boton.grab_focus.call_deferred()  # para poder confirmar con el mando


func _crear_tarjeta(indice: int, programa: Dictionary) -> PanelContainer:
	var tarjeta := PanelContainer.new()
	tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tarjeta.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 5)
	tarjeta.add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 3)
	margen.add_child(caja)

	var afinidad: int = programa["afinidad"]
	caja.add_child(_crear_etiqueta(
		"%s  ·  %s  ·  %d%%" % [MEDALLAS[indice], _nivel(afinidad), afinidad], TAM_TEXTO))
	caja.add_child(_crear_etiqueta(programa["nombre"], TAM_NOMBRE, true, LINEAS_NOMBRE))

	var barra := ProgressBar.new()
	barra.max_value = 100
	barra.value = afinidad
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 5)
	caja.add_child(barra)

	caja.add_child(_crear_etiqueta(programa["facultad"] + "\n" + programa["modalidad"], TAM_TEXTO, true, 4))
	caja.add_child(_crear_etiqueta(programa["descripcion"], TAM_TEXTO, true, LINEAS_DESCRIPCION))
	return tarjeta


## Mismos cortes que la hoja DASHBOARD del Excel.
func _nivel(afinidad: int) -> String:
	if afinidad >= 80:
		return "Alta"
	if afinidad >= 50:
		return "Media"
	return "Baja"


## max_lineas = 0 significa sin límite.
func _crear_etiqueta(texto: String, tamano: int, ajustar: bool = false, max_lineas: int = 0) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_constant_override("line_spacing", -2)
	if ajustar:
		etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if max_lineas > 0:
		etiqueta.max_lines_visible = max_lineas
		etiqueta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return etiqueta


func _on_jugar_de_nuevo() -> void:
	GameState.reiniciar_respuestas()
	GameState.ir_a_escena(ESCENA_INICIO)
