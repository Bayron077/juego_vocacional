extends CanvasLayer
## Contador de FPS. Autoload (nombre: FpsDebug). Tecla F3: mostrar / ocultar.
## Sirve para saber si el "lento" es de imagen (FPS bajos) o de la TV (retraso).

var _etiqueta: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_etiqueta = Label.new()
	_etiqueta.position = Vector2(4, 4)
	_etiqueta.add_theme_font_size_override("font_size", 12)
	_etiqueta.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	_etiqueta.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_etiqueta.add_theme_constant_override("outline_size", 3)
	_etiqueta.visible = false
	add_child(_etiqueta)


func _process(_delta: float) -> void:
	if _etiqueta.visible:
		_etiqueta.text = "FPS: %d" % Engine.get_frames_per_second()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_etiqueta.visible = not _etiqueta.visible
	
