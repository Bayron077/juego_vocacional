class_name Reto
extends CanvasLayer
## Minijuego opcional de 20 a 40 segundos. Se usa así:
##   var reto := Reto.new()
##   add_child(reto)
##   reto.iniciar(tipo, titulo, texto)
## Pausa el juego mientras está abierto y emite "terminado" al cerrarse.
## Nunca se puede perder: si fallas, vuelves a intentarlo.

signal terminado(completado: bool)

const TAM_TITULO := 12
const TAM_TEXTO := 9
const TAM_FLECHA := 22

const ACCIONES := ["ui_up", "ui_down", "ui_left", "ui_right"]
const FLECHAS := {"ui_up": "↑", "ui_down": "↓", "ui_left": "←", "ui_right": "→"}
const LARGO_SECUENCIA := 4

const ANCHO_PISTA := 280.0
const ALTO_PISTA := 18.0
const ANCHOS_ZONA := [90.0, 64.0, 44.0]   # una ronda por valor, cada vez más estrecha
const VELOCIDADES := [0.7, 0.95, 1.2]     # recorridos de la barra por segundo

enum Fase { INTRO, JUGANDO, FINAL }

var _tipo: FichaArea.TipoReto = FichaArea.TipoReto.SECUENCIA
var _fase: Fase = Fase.INTRO

var _titulo: Label
var _texto: Label
var _zona: Control
var _pista: Label

# --- Secuencia ---
var _secuencia: Array[String] = []
var _slots: Array[Label] = []
var _indice := 0
var _aceptando := false

# --- Timing ---
var _pista_fondo: ColorRect
var _zona_verde: ColorRect
var _marcador: ColorRect
var _pos := 0.0
var _dir := 1.0
var _ronda := 0
var _activo := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.75)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var marco := PanelContainer.new()
	marco.custom_minimum_size = Vector2(340, 0)
	centro.add_child(marco)

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 10)
	marco.add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)
	margen.add_child(caja)

	_titulo = _crear_label(TAM_TITULO)
	caja.add_child(_titulo)

	_texto = _crear_label(TAM_TEXTO)
	caja.add_child(_texto)

	_zona = Control.new()
	_zona.custom_minimum_size = Vector2(300, 70)
	caja.add_child(_zona)

	_pista = _crear_label(TAM_TEXTO)
	_pista.modulate = Color(1, 1, 1, 0.75)
	caja.add_child(_pista)


func iniciar(tipo: FichaArea.TipoReto, titulo: String, texto: String) -> void:
	_tipo = tipo
	_titulo.text = titulo
	_texto.text = texto
	_pista.text = "A: empezar   |   B: salir"
	_fase = Fase.INTRO
	get_tree().paused = true


func _crear_label(tam: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.add_theme_font_size_override("font_size", tam)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.custom_minimum_size = Vector2(300, 0)
	return etiqueta


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout


# ---------------------------------------------------------------- Entrada

func _input(event: InputEvent) -> void:
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
			if _tipo == FichaArea.TipoReto.SECUENCIA:
				for accion in ACCIONES:
					if event.is_action_pressed(accion):
						get_viewport().set_input_as_handled()
						_pulsar_flecha(accion)
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
	if _tipo == FichaArea.TipoReto.SECUENCIA:
		_empezar_secuencia()
	else:
		_empezar_timing()


# ------------------------------------------------------ Mecánica: secuencia

func _empezar_secuencia() -> void:
	_slots.clear()
	var fila := HBoxContainer.new()
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 10)
	_zona.add_child(fila)

	for i in LARGO_SECUENCIA:
		var slot := Label.new()
		slot.custom_minimum_size = Vector2(44, 44)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_theme_font_size_override("font_size", TAM_FLECHA)
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.15, 0.17, 0.25)
		estilo.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("normal", estilo)
		fila.add_child(slot)
		_slots.append(slot)

	_secuencia.clear()
	for i in LARGO_SECUENCIA:
		_secuencia.append(ACCIONES.pick_random())

	_mostrar_secuencia()


func _limpiar_slots() -> void:
	for slot in _slots:
		slot.text = "?"


func _mostrar_secuencia() -> void:
	_aceptando = false
	_indice = 0
	_pista.text = "Memoriza la secuencia..."
	_limpiar_slots()
	await _esperar(0.6)
	for i in LARGO_SECUENCIA:
		if _fase != Fase.JUGANDO:
			return
		_slots[i].text = FLECHAS[_secuencia[i]]
		await _esperar(0.7)
	if _fase != Fase.JUGANDO:
		return
	_limpiar_slots()
	_pista.text = "¡Ahora repítela con la cruceta!"
	_aceptando = true


func _pulsar_flecha(accion: String) -> void:
	if not _aceptando:
		return
	if accion == _secuencia[_indice]:
		_slots[_indice].text = FLECHAS[accion]
		_indice += 1
		if _indice >= LARGO_SECUENCIA:
			_aceptando = false
			_ganar()
	else:
		_aceptando = false
		_pista.text = "¡Casi! Mírala otra vez"
		await _esperar(0.9)
		if _fase == Fase.JUGANDO:
			_mostrar_secuencia()


# --------------------------------------------------------- Mecánica: timing

func _empezar_timing() -> void:
	_pista_fondo = ColorRect.new()
	_pista_fondo.color = Color(0.15, 0.17, 0.25)
	_pista_fondo.position = Vector2((300.0 - ANCHO_PISTA) / 2.0, 26.0)
	_pista_fondo.size = Vector2(ANCHO_PISTA, ALTO_PISTA)
	_zona.add_child(_pista_fondo)

	_zona_verde = ColorRect.new()
	_zona_verde.color = Color(0.25, 0.75, 0.4)
	_zona_verde.size = Vector2(60.0, ALTO_PISTA)
	_pista_fondo.add_child(_zona_verde)

	_marcador = ColorRect.new()
	_marcador.color = Color.WHITE
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
	_pista.text = "Pulsa A cuando la barra blanca esté en la zona verde (%d/%d)" % [_ronda, ANCHOS_ZONA.size()]
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
	estrella.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	estrella.text = "★"
	_zona.add_child(estrella)


func _cerrar(completado: bool) -> void:
	_fase = Fase.FINAL
	_activo = false
	_aceptando = false
	get_tree().paused = false
	terminado.emit(completado)
	queue_free()
