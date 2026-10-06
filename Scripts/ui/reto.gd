class_name Reto
extends CanvasLayer
## Minijuego opcional de 20 a 40 segundos. Se usa así:
##   var reto := Reto.new()
##   add_child(reto)
##   reto.iniciar(tipo, titulo, texto, ficha)
## Pausa el juego mientras está abierto y emite "terminado" al cerrarse.
## Nunca se puede perder: si fallas, vuelves a intentarlo.

signal terminado(completado: bool)

const TAM_TITULO := 12
const TAM_TEXTO := 9
const TAM_SIMBOLO := 14

const LARGO_SECUENCIA := 4
const COLOR_ACENTO_DEFECTO := Color(1.0, 0.85, 0.25)

# Celdas de la cruz: 0 = arriba, 1 = abajo, 2 = izquierda, 3 = derecha.
const ACCION_A_CELDA := {"ui_up": 0, "ui_down": 1, "ui_left": 2, "ui_right": 3}
# Botones del mando Xbox en su disposición real: Y arriba, A abajo, X izquierda, B derecha.
const BOTON_A_CELDA := {JOY_BUTTON_Y: 0, JOY_BUTTON_A: 1, JOY_BUTTON_X: 2, JOY_BUTTON_B: 3}
const FLECHAS := ["↑", "↓", "←", "→"]
const LETRAS_XBOX := ["Y", "A", "X", "B"]
const COLORES_XBOX := [
	Color(0.85, 0.7, 0.1),   # Y amarillo
	Color(0.25, 0.65, 0.3),  # A verde
	Color(0.25, 0.45, 0.85), # X azul
	Color(0.8, 0.25, 0.25),  # B rojo
]
const COLOR_CELDA := Color(0.15, 0.17, 0.25)
const TAM_CELDA := Vector2(40, 28)
# Posiciones dentro de la zona (300 de ancho): arriba, abajo, izquierda, derecha.
const POS_CELDAS := [Vector2(130, 0), Vector2(130, 64), Vector2(86, 32), Vector2(174, 32)]
const POS_CENTRO := Vector2(130, 32)

const ANCHO_PISTA := 280.0
const ALTO_PISTA := 18.0
const ANCHOS_ZONA := [90.0, 64.0, 44.0]   # una ronda por valor, cada vez más estrecha
const VELOCIDADES := [0.7, 0.95, 1.2]     # recorridos de la barra por segundo

enum Fase { INTRO, JUGANDO, FINAL }

var _tipo: FichaArea.TipoReto = FichaArea.TipoReto.SECUENCIA
var _ficha: FichaArea = null
var _fase: Fase = Fase.INTRO
var _acento: Color = COLOR_ACENTO_DEFECTO

var _fondo_imagen: TextureRect
var _oscurecer: ColorRect
var _marco: PanelContainer
var _titulo: Label
var _texto: Label
var _zona: Control
var _pista: Label

# --- Secuencia ---
var _secuencia: Array[int] = []
var _celdas: Array[Panel] = []
var _estilos: Array[StyleBoxFlat] = []
var _base: Array[Color] = []
var _luz: Array[Color] = []
var _centro: Label
var _indice := 0
var _aceptando := false

# --- Timing ---
var _pista_fondo: Control
var _zona_verde: Control
var _marcador: Control
var _pos := 0.0
var _dir := 1.0
var _ronda := 0
var _activo := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

	_fondo_imagen = TextureRect.new()
	_fondo_imagen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo_imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fondo_imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fondo_imagen.visible = false
	add_child(_fondo_imagen)

	_oscurecer = ColorRect.new()
	_oscurecer.color = Color(0, 0, 0, 0.75)
	_oscurecer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_oscurecer)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	_marco = PanelContainer.new()
	_marco.custom_minimum_size = Vector2(340, 0)
	centro.add_child(_marco)

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 10)
	_marco.add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)
	margen.add_child(caja)

	_titulo = _crear_label(TAM_TITULO)
	caja.add_child(_titulo)

	_texto = _crear_label(TAM_TEXTO)
	caja.add_child(_texto)

	_zona = Control.new()
	_zona.custom_minimum_size = Vector2(300, 94)
	caja.add_child(_zona)

	_pista = _crear_label(TAM_TEXTO)
	_pista.modulate = Color(1, 1, 1, 0.75)
	caja.add_child(_pista)


func iniciar(tipo: FichaArea.TipoReto, titulo: String, texto: String, ficha: FichaArea = null) -> void:
	_tipo = tipo
	_ficha = ficha
	_titulo.text = titulo
	_texto.text = texto
	_pista.text = "A: empezar   |   B: salir"
	_fase = Fase.INTRO
	if _es_secuencia():
		_zona.custom_minimum_size = Vector2(300, 94)
	else:
		_zona.custom_minimum_size = Vector2(300, 70)
	_aplicar_arte()
	get_tree().paused = true


func _es_secuencia() -> bool:
	return _tipo != FichaArea.TipoReto.TIMING


func _es_botones() -> bool:
	return _tipo == FichaArea.TipoReto.SECUENCIA_BOTONES


## Aplica el color de acento y el fondo de la ficha, si los tiene.
func _aplicar_arte() -> void:
	_acento = COLOR_ACENTO_DEFECTO
	if _ficha != null:
		_acento = _ficha.color_acento_reto
		if _ficha.fondo_reto != null:
			_fondo_imagen.texture = _ficha.fondo_reto
			_fondo_imagen.visible = true
			_oscurecer.color = Color(0, 0, 0, 0.5)

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.08, 0.09, 0.16, 0.95)
	estilo.border_color = _acento
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(4)
	_marco.add_theme_stylebox_override("panel", estilo)


func _crear_label(tam: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.add_theme_font_size_override("font_size", tam)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.custom_minimum_size = Vector2(300, 0)
	return etiqueta


## Espera usando un Timer hijo: si el reto se cierra a mitad de espera, el Timer
## se libera junto con él y no queda ninguna función "huérfana".
func _esperar(segundos: float) -> void:
	var temporizador := Timer.new()
	temporizador.one_shot = true
	add_child(temporizador)
	temporizador.start(segundos)
	await temporizador.timeout
	temporizador.queue_free()


# ---------------------------------------------------------------- Entrada

func _input(event: InputEvent) -> void:
	# Variante de botones: mientras se juega, la B del mando es una respuesta
	# (no "salir"). Para salir se usa Start (o Esc en el teclado).
	if _fase == Fase.JUGANDO and _es_botones():
		var boton := event as InputEventJoypadButton
		if boton != null and boton.pressed:
			if boton.button_index == JOY_BUTTON_START:
				get_viewport().set_input_as_handled()
				_cerrar(false)
				return
			if BOTON_A_CELDA.has(boton.button_index):
				get_viewport().set_input_as_handled()
				_pulsar_celda(BOTON_A_CELDA[boton.button_index])
				return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cerrar(_fase == Fase.FINAL)
		return

	match _fase:
		Fase.INTRO:
			if event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				_empezar()
		Fase.JUGANDO:
			if _es_secuencia():
				for accion in ACCION_A_CELDA:
					if event.is_action_pressed(accion):
						get_viewport().set_input_as_handled()
						_pulsar_celda(ACCION_A_CELDA[accion])
						return
			elif event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				_pulsar_timing()
		Fase.FINAL:
			if event.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				_cerrar(true)


func _empezar() -> void:
	_fase = Fase.JUGANDO
	_pista.text = ""
	for hijo in _zona.get_children():
		hijo.queue_free()
	if _es_secuencia():
		_empezar_secuencia()
	else:
		_empezar_timing()


# ------------------------------------------------ Mecánica: secuencia (en cruz)

func _empezar_secuencia() -> void:
	_celdas.clear()
	_estilos.clear()
	_base.clear()
	_luz.clear()
	var botones := _es_botones()

	for i in 4:
		var base: Color = COLOR_CELDA
		var luz: Color = _acento
		if botones:
			base = COLORES_XBOX[i]
			luz = base.lightened(0.55)

		var estilo := StyleBoxFlat.new()
		estilo.bg_color = base
		estilo.set_corner_radius_all(4)

		var celda := Panel.new()
		celda.position = POS_CELDAS[i]
		celda.size = TAM_CELDA
		celda.add_theme_stylebox_override("panel", estilo)
		celda.add_child(_crear_simbolo(i, botones))
		_zona.add_child(celda)

		_celdas.append(celda)
		_estilos.append(estilo)
		_base.append(base)
		_luz.append(luz)

	_centro = Label.new()
	_centro.position = POS_CENTRO
	_centro.size = TAM_CELDA
	_centro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_centro.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_centro.add_theme_font_size_override("font_size", TAM_TEXTO)
	_centro.modulate = Color(1, 1, 1, 0.7)
	_zona.add_child(_centro)

	_secuencia.clear()
	for i in LARGO_SECUENCIA:
		_secuencia.append(randi() % 4)

	_mostrar_secuencia()


## Símbolo de una celda: la imagen de la ficha si existe; si no, flecha o letra.
func _crear_simbolo(i: int, botones: bool) -> Control:
	var textura: Texture2D = null
	if _ficha != null:
		var texturas: Array = [_ficha.icono_arriba, _ficha.icono_abajo, _ficha.icono_izquierda, _ficha.icono_derecha]
		textura = texturas[i]

	if textura != null:
		var imagen := TextureRect.new()
		imagen.texture = textura
		imagen.set_anchors_preset(Control.PRESET_FULL_RECT)
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return imagen

	var letra := Label.new()
	letra.text = LETRAS_XBOX[i] if botones else FLECHAS[i]
	letra.set_anchors_preset(Control.PRESET_FULL_RECT)
	letra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letra.add_theme_font_size_override("font_size", TAM_SIMBOLO)
	return letra


func _destello(i: int, color: Color, segundos: float) -> void:
	_estilos[i].bg_color = color
	await _esperar(segundos)
	_estilos[i].bg_color = _base[i]


func _mostrar_secuencia() -> void:
	_aceptando = false
	_indice = 0
	_centro.text = "0/%d" % LARGO_SECUENCIA
	_pista.text = "Memoriza la secuencia..."
	await _esperar(0.6)
	for celda in _secuencia:
		if _fase != Fase.JUGANDO:
			return
		await _destello(celda, _luz[celda], 0.5)
		await _esperar(0.2)
	if _fase != Fase.JUGANDO:
		return
	if _es_botones():
		_pista.text = "¡Ahora repítela con los botones del mando!"
	else:
		_pista.text = "¡Ahora repítela con la cruceta!"
	_aceptando = true


func _pulsar_celda(i: int) -> void:
	if not _aceptando:
		return
	if i == _secuencia[_indice]:
		_destello(i, _luz[i], 0.2)
		_indice += 1
		_centro.text = "%d/%d" % [_indice, LARGO_SECUENCIA]
		if _indice >= LARGO_SECUENCIA:
			_aceptando = false
			await _esperar(0.35)
			if _fase == Fase.JUGANDO:
				_ganar()
	else:
		_aceptando = false
		_destello(i, Color(0.9, 0.2, 0.2), 0.4)
		_pista.text = "¡Casi! Mírala otra vez"
		await _esperar(0.9)
		if _fase == Fase.JUGANDO:
			_mostrar_secuencia()


# --------------------------------------------------------- Mecánica: timing

## Crea un bloque de color o, si hay textura, una imagen estirada.
func _crear_visual(textura: Texture2D, color: Color) -> Control:
	if textura != null:
		var imagen := TextureRect.new()
		imagen.texture = textura
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_SCALE
		return imagen
	var bloque := ColorRect.new()
	bloque.color = color
	return bloque


func _empezar_timing() -> void:
	var t_pista: Texture2D = null
	var t_zona: Texture2D = null
	var t_marcador: Texture2D = null
	if _ficha != null:
		t_pista = _ficha.textura_pista
		t_zona = _ficha.textura_zona
		t_marcador = _ficha.textura_marcador

	_pista_fondo = _crear_visual(t_pista, Color(0.15, 0.17, 0.25))
	_pista_fondo.position = Vector2((300.0 - ANCHO_PISTA) / 2.0, 26.0)
	_pista_fondo.size = Vector2(ANCHO_PISTA, ALTO_PISTA)
	_zona.add_child(_pista_fondo)

	_zona_verde = _crear_visual(t_zona, Color(0.25, 0.75, 0.4))
	_zona_verde.size = Vector2(60.0, ALTO_PISTA)
	_pista_fondo.add_child(_zona_verde)

	_marcador = _crear_visual(t_marcador, Color.WHITE)
	_marcador.size = Vector2(6.0, ALTO_PISTA + 10.0)
	_marcador.position = Vector2(0.0, -5.0)
	_pista_fondo.add_child(_marcador)

	_ronda = 0
	_nueva_ronda_timing()


func _nueva_ronda_timing() -> void:
	var ancho: float = ANCHOS_ZONA[_ronda]
	_zona_verde.size.x = ancho
	_zona_verde.position.x = randf_range(20.0, ANCHO_PISTA - ancho - 20.0)
	_pos = 0.0
	_dir = 1.0
	_pista.text = "Pulsa A cuando la barra esté en la zona verde (%d/%d)" % [_ronda, ANCHOS_ZONA.size()]
	_activo = true


func _process(delta: float) -> void:
	if not _activo:
		return
	var velocidad: float = VELOCIDADES[mini(_ronda, VELOCIDADES.size() - 1)]
	_pos += _dir * velocidad * delta
	if _pos >= 1.0:
		_pos = 1.0
		_dir = -1.0
	elif _pos <= 0.0:
		_pos = 0.0
		_dir = 1.0
	_marcador.position.x = _pos * (ANCHO_PISTA - _marcador.size.x)


func _pulsar_timing() -> void:
	if not _activo:
		return
	var centro := _marcador.position.x + _marcador.size.x / 2.0
	var inicio := _zona_verde.position.x
	if centro >= inicio and centro <= inicio + _zona_verde.size.x:
		_activo = false
		_ronda += 1
		if _ronda >= ANCHOS_ZONA.size():
			_ganar()
		else:
			_pista.text = "¡Bien! Ahora más difícil..."
			await _esperar(0.8)
			if _fase == Fase.JUGANDO:
				_nueva_ronda_timing()
	else:
		_pista.text = "¡Casi! Inténtalo otra vez"


# ------------------------------------------------------------- Final / cierre

func _ganar() -> void:
	_fase = Fase.FINAL
	_activo = false
	_aceptando = false
	_titulo.text = "¡Reto superado!"
	_texto.text = "Ganaste el sello de esta área."
	_pista.text = "A: continuar"

	for hijo in _zona.get_children():
		hijo.queue_free()
	var estrella := Label.new()
	estrella.set_anchors_preset(Control.PRESET_FULL_RECT)
	estrella.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estrella.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	estrella.add_theme_font_size_override("font_size", 40)
	estrella.add_theme_color_override("font_color", _acento)
	estrella.text = "★"
	_zona.add_child(estrella)


func _cerrar(completado: bool) -> void:
	_fase = Fase.FINAL
	_activo = false
	_aceptando = false
	get_tree().paused = false
	terminado.emit(completado)
	queue_free()
