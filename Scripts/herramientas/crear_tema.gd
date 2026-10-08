@tool
extends EditorScript
## Genera res://recursos/tema_juego.tres con la apariencia de todos los menús.
## Se ejecuta desde el editor: con este script abierto, menú Archivo → Ejecutar
## (Ctrl+Shift+X). Cambia los colores de arriba y vuelve a ejecutarlo cuando
## quieras ajustar el estilo.

const RUTA_SALIDA := "res://recursos/tema_juego.tres"
const RUTA_FUENTE := "res://assets/fuentes/fuente_pixel.ttf"

## Tamaño de letra por defecto (donde un script no fija el suyo).
const TAM_FUENTE := 12

const COLOR_PANEL := Color(0.09, 0.1, 0.19, 0.96)
const COLOR_BORDE := Color(0.36, 0.41, 0.68)
const COLOR_BOTON := Color(0.16, 0.18, 0.33)
const COLOR_BOTON_HOVER := Color(0.24, 0.27, 0.48)
const COLOR_BOTON_PRESIONADO := Color(0.1, 0.12, 0.23)
const COLOR_BOTON_DESACTIVADO := Color(0.12, 0.13, 0.2)
const COLOR_ACENTO := Color(1.0, 0.85, 0.25)
const COLOR_TEXTO := Color(1, 1, 1)
const COLOR_TEXTO_APAGADO := Color(0.6, 0.62, 0.72)


func _run() -> void:
	var tema := Theme.new()
	_fuente(tema)
	_etiquetas(tema)
	_botones(tema)
	_paneles(tema)
	_barras(tema)

	var error := ResourceSaver.save(tema, RUTA_SALIDA)
	if error == OK:
		print("Tema guardado en ", RUTA_SALIDA)
	else:
		push_error("No se pudo guardar el tema: " + error_string(error))


func _caja(fondo: Color, borde: Color, grosor: int, radio: int, margen_h: int, margen_v: int) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde
	caja.set_border_width_all(grosor)
	caja.set_corner_radius_all(radio)
	caja.content_margin_left = margen_h
	caja.content_margin_right = margen_h
	caja.content_margin_top = margen_v
	caja.content_margin_bottom = margen_v
	return caja


func _fuente(tema: Theme) -> void:
	tema.default_font_size = TAM_FUENTE
	if ResourceLoader.exists(RUTA_FUENTE):
		tema.default_font = load(RUTA_FUENTE) as Font
	else:
		print("Aviso: no hay fuente en ", RUTA_FUENTE, ". Se usa la fuente por defecto.")


func _etiquetas(tema: Theme) -> void:
	tema.set_color("font_color", "Label", COLOR_TEXTO)
	# Sombra suave: ayuda a leer a distancia en la TV.
	tema.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	tema.set_constant("shadow_offset_x", "Label", 1)
	tema.set_constant("shadow_offset_y", "Label", 1)


func _botones(tema: Theme) -> void:
	tema.set_stylebox("normal", "Button", _caja(COLOR_BOTON, COLOR_BORDE, 1, 3, 8, 5))
	tema.set_stylebox("hover", "Button", _caja(COLOR_BOTON_HOVER, COLOR_BORDE, 1, 3, 8, 5))
	tema.set_stylebox("pressed", "Button", _caja(COLOR_BOTON_PRESIONADO, COLOR_ACENTO, 1, 3, 8, 5))
	tema.set_stylebox("hover_pressed", "Button", _caja(COLOR_BOTON_PRESIONADO, COLOR_ACENTO, 1, 3, 8, 5))
	tema.set_stylebox("disabled", "Button", _caja(COLOR_BOTON_DESACTIVADO, COLOR_BORDE, 1, 3, 8, 5))

	# Foco (el botón elegido con el mando o el teclado): borde grueso dorado,
	# dibujado sobre el botón. Es lo que más ayuda a ver qué opción está marcada.
	var foco := _caja(Color(0, 0, 0, 0), COLOR_ACENTO, 3, 3, 8, 5)
	foco.draw_center = false
	tema.set_stylebox("focus", "Button", foco)

	tema.set_color("font_color", "Button", COLOR_TEXTO)
	tema.set_color("font_hover_color", "Button", COLOR_TEXTO)
	tema.set_color("font_focus_color", "Button", COLOR_ACENTO)
	tema.set_color("font_pressed_color", "Button", COLOR_ACENTO)
	tema.set_color("font_hover_pressed_color", "Button", COLOR_ACENTO)
	tema.set_color("font_disabled_color", "Button", COLOR_TEXTO_APAGADO)


func _paneles(tema: Theme) -> void:
	var panel := _caja(COLOR_PANEL, COLOR_BORDE, 2, 4, 0, 0)
	tema.set_stylebox("panel", "PanelContainer", panel)
	tema.set_stylebox("panel", "Panel", panel)


func _barras(tema: Theme) -> void:
	tema.set_stylebox("background", "ProgressBar", _caja(Color(0.05, 0.06, 0.12), COLOR_BORDE, 1, 2, 0, 0))
	tema.set_stylebox("fill", "ProgressBar", _caja(COLOR_ACENTO, COLOR_ACENTO, 0, 2, 0, 0))

	# Barras de desplazamiento más anchas y visibles (listas largas del selector).
	for barra in ["VScrollBar", "HScrollBar"]:
		tema.set_stylebox("scroll", barra, _caja(Color(0.05, 0.06, 0.12, 0.8), Color(0, 0, 0, 0), 0, 3, 4, 4))
		tema.set_stylebox("grabber", barra, _caja(COLOR_BORDE, Color(0, 0, 0, 0), 0, 3, 4, 4))
		tema.set_stylebox("grabber_highlight", barra, _caja(COLOR_ACENTO.darkened(0.2), Color(0, 0, 0, 0), 0, 3, 4, 4))
		tema.set_stylebox("grabber_pressed", barra, _caja(COLOR_ACENTO, Color(0, 0, 0, 0), 0, 3, 4, 4))
