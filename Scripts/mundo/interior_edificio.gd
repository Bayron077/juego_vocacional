extends Node2D

## Interior reutilizable para las 17 áreas: un cuarto con 3 NPC, una mesa de reto
## opcional y una salida.

const ANCHO_CUARTO := 480
const ALTO_CUARTO := 270
const GROSOR_PARED := 16
const POSICION_INICIAL_JUGADOR := Vector2(240, 180)
## Dónde está la mesa del reto: centrada sobre la mesa y la alfombra del dibujo.
const POSICION_MESA_RETO := Vector2(405, 172)
## Zona de salida, sobre el tapete con la flecha del dibujo.
const POSICION_SALIDA := Vector2(415, 255)
const RUTA_FICHAS := "res://recursos/areas/"

## Muebles del dibujo que bloquean el paso (coordenadas del cuarto, 480x270).
## Si el jugador atraviesa algo o se atora sin motivo, ajusta estos rectángulos
## (x, y, ancho, alto). Para verlos: menú Depurar > Formas de colisión visibles.
const OBSTACULOS: Array[Rect2] = [
	Rect2(0, 0, 480, 88),       # pared del fondo (ventanas, pizarrón, estantes)
	Rect2(0, 86, 34, 40),       # lavamanos, esquina izquierda
	Rect2(0, 123, 84, 76),      # mesón de laboratorio y estantes
	Rect2(106, 86, 38, 15),     # mueble bajo junto a la planta
	Rect2(84, 172, 24, 27),     # maceta del lado izquierdo
	Rect2(0, 208, 64, 62),      # plantas de la esquina inferior izquierda
	Rect2(58, 230, 70, 40),     # escritorio pequeño y dispensador de agua
	Rect2(362, 86, 36, 15),     # cajas arriba a la derecha
	Rect2(397, 86, 53, 30),     # escritorio con computador
	Rect2(408, 100, 28, 28),    # silla
	Rect2(450, 86, 30, 72),     # estante de la derecha
	Rect2(458, 160, 22, 56),    # cajas del lado derecho
	Rect2(384, 154, 44, 36),    # mesa del reto
]

const ESCENA_MAPA := "res://escenas/mundo/mapa_area.tscn"
const ESCENA_SELECTOR := "res://escenas/ui/selector_area.tscn"
const ESCENA_RESULTADOS := "res://escenas/ui/resultados.tscn"
const ESCENA_PERSONAJE_MASCULINO: PackedScene = preload("res://personajes/player_levy.tscn")
const ESCENA_PERSONAJE_FEMENINO: PackedScene = preload("res://personajes/Eda.tscn")

## Aspecto de la mesa del reto: dorado y llamativo mientras está pendiente,
## verde y tranquilo cuando ya se ganó el sello.
const COLOR_ORO := Color(1.0, 0.82, 0.2)
const COLOR_ORO_BORDE := Color(0.45, 0.22, 0.0)
const COLOR_VERDE := Color(0.45, 0.9, 0.5)
const COLOR_VERDE_BORDE := Color(0.05, 0.3, 0.1)
## Tamaño de letra del rótulo sobre la mesa (la fuente Jersey 15 se ve bien en múltiplos de 15).
const TAM_ROTULO := 15

var jugador: CharacterBody2D
var npc_cercano: Npc = null
var jugador_en_salida: bool = false
var jugador_en_mesa_reto: bool = false

var _ficha: FichaArea = null
var _aura: Polygon2D
var _marcador: Node2D
var _flecha: Node2D
var _rotulo_mesa: Label
var _chispas: CPUParticles2D
var _animaciones: Array[Tween] = []

@onready var salida: Area2D = $Salida
@onready var dialogo: DialogoNpc = $DialogoNpc
@onready var etiqueta_titulo: Label = $CapaUI/EtiquetaTitulo
@onready var etiqueta_prompt: Label = $CapaUI/EtiquetaPrompt


func _ready() -> void:
	_crear_paredes()
	_ubicar_salida()
	# La mesa se crea ANTES del jugador para que el jugador se dibuje encima de ella.
	_crear_mesa_reto()
	_instanciar_jugador()

	_actualizar_titulo()
	etiqueta_prompt.visible = false

	salida.body_entered.connect(_on_salida_body_entered)
	salida.body_exited.connect(_on_salida_body_exited)
	dialogo.cerrado.connect(_on_dialogo_cerrado)
	dialogo.respuesta_elegida.connect(_on_respuesta_elegida)
	dialogo.decision_tomada.connect(_on_decision_tomada)

	# Conecta automáticamente a todos los NPC que haya en el cuarto.
	for hijo in get_children():
		if hijo is Npc:
			hijo.jugador_cerca.connect(_on_npc_jugador_cerca)
			hijo.jugador_lejos.connect(_on_npc_jugador_lejos)


## Coloca la zona de salida sobre el tapete del dibujo y oculta el rectángulo de prueba.
func _ubicar_salida() -> void:
	salida.position = POSICION_SALIDA
	var visual := salida.get_node_or_null("Visual")
	if visual != null:
		visual.visible = false


## Crea las paredes invisibles alrededor del cuarto y las colisiones de los muebles.
func _crear_paredes() -> void:
	var rectangulos: Array[Rect2] = [
		Rect2(-GROSOR_PARED, -GROSOR_PARED, ANCHO_CUARTO + GROSOR_PARED * 2, GROSOR_PARED), # arriba
		Rect2(-GROSOR_PARED, ALTO_CUARTO, ANCHO_CUARTO + GROSOR_PARED * 2, GROSOR_PARED), # abajo
		Rect2(-GROSOR_PARED, 0, GROSOR_PARED, ALTO_CUARTO), # izquierda
		Rect2(ANCHO_CUARTO, 0, GROSOR_PARED, ALTO_CUARTO), # derecha
	]
	rectangulos.append_array(OBSTACULOS)
	for rect in rectangulos:
		var cuerpo := StaticBody2D.new()
		var colision := CollisionShape2D.new()
		var forma := RectangleShape2D.new()
		forma.size = rect.size
		colision.shape = forma
		cuerpo.position = rect.position + rect.size / 2.0
		cuerpo.add_child(colision)
		add_child(cuerpo)


func _normalizar(texto: String) -> String:
	return texto.strip_edges().to_lower()


## Busca la ficha del área elegida. Ignora mayúsculas y espacios sobrantes.
func _buscar_ficha() -> FichaArea:
	var buscado := _normalizar(GameState.area_elegida)
	for archivo in ResourceLoader.list_directory(RUTA_FICHAS):
		if not archivo.ends_with(".tres"):
			continue
		var ficha := load(RUTA_FICHAS + archivo) as FichaArea
		if ficha == null:
			continue
		if _normalizar(ficha.nombre_area) == buscado:
			return ficha
	push_warning("No se encontró ficha para el área '%s'." % GameState.area_elegida)
	return null


## Crea por código la mesa del reto: una zona de interacción (más grande que la mesa,
## que es sólida) con un aura, una flecha que rebota, un rótulo y chispas.
func _crear_mesa_reto() -> void:
	_ficha = _buscar_ficha()

	var mesa := Area2D.new()
	mesa.position = POSICION_MESA_RETO

	var colision := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = Vector2(68, 52)
	colision.shape = forma
	mesa.add_child(colision)

	# Aura: una elipse luminosa sobre la mesa que late.
	_aura = Polygon2D.new()
	_aura.polygon = _elipse(34.0, 20.0)
	_aura.position = Vector2(0, 2)
	mesa.add_child(_aura)

	# Chispas que suben desde la mesa.
	_chispas = CPUParticles2D.new()
	_chispas.position = Vector2(0, 4)
	_chispas.amount = 10
	_chispas.lifetime = 1.4
	_chispas.preprocess = 1.4
	_chispas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_chispas.emission_rect_extents = Vector2(22, 6)
	_chispas.direction = Vector2(0, -1)
	_chispas.spread = 15.0
	_chispas.gravity = Vector2.ZERO
	_chispas.initial_velocity_min = 12.0
	_chispas.initial_velocity_max = 22.0
	_chispas.scale_amount_min = 1.5
	_chispas.scale_amount_max = 2.5
	var degradado := Gradient.new()
	degradado.set_color(0, Color(1.0, 0.95, 0.55, 1.0))
	degradado.set_color(1, Color(1.0, 0.7, 0.1, 0.0))
	_chispas.color_ramp = degradado
	mesa.add_child(_chispas)

	# Marcador sobre la mesa: flecha dorada + rótulo. Sube y baja suavemente.
	_marcador = Node2D.new()
	_marcador.position = Vector2(0, -26)
	mesa.add_child(_marcador)

	_flecha = Node2D.new()
	_marcador.add_child(_flecha)
	var contorno := Polygon2D.new()
	contorno.name = "Contorno"
	contorno.polygon = _puntos_flecha(1.0)
	_flecha.add_child(contorno)
	var relleno := Polygon2D.new()
	relleno.name = "Relleno"
	relleno.polygon = _puntos_flecha(0.0)
	_flecha.add_child(relleno)

	_rotulo_mesa = Label.new()
	_rotulo_mesa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo_mesa.custom_minimum_size = Vector2(80, 0)
	_rotulo_mesa.position = Vector2(-40, -22)
	_rotulo_mesa.add_theme_font_size_override("font_size", TAM_ROTULO)
	_rotulo_mesa.add_theme_constant_override("outline_size", 4)
	_marcador.add_child(_rotulo_mesa)

	add_child(mesa)
	mesa.body_entered.connect(_on_mesa_body_entered)
	mesa.body_exited.connect(_on_mesa_body_exited)
	_actualizar_mesa()


## Puntos de una elipse (para el aura).
func _elipse(radio_x: float, radio_y: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in 28:
		var ang := TAU * float(i) / 28.0
		puntos.append(Vector2(cos(ang) * radio_x, sin(ang) * radio_y))
	return puntos


## Flecha que apunta hacia abajo. "margen" la agranda para dibujar el contorno.
func _puntos_flecha(margen: float) -> PackedVector2Array:
	var m := margen
	return PackedVector2Array([
		Vector2(-4 - m, -9 - m), Vector2(4 + m, -9 - m), Vector2(4 + m, -3 - m),
		Vector2(8 + m, -3 - m), Vector2(0, 7 + m), Vector2(-8 - m, -3 - m),
		Vector2(-4 - m, -3 - m),
	])


## Hace oscilar una propiedad entre dos valores sin parar.
func _oscilar(objeto: Object, propiedad: NodePath, desde: Variant, hasta: Variant, segundos: float) -> void:
	var anim := create_tween().set_loops()
	anim.tween_property(objeto, propiedad, hasta, segundos).from(desde) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	anim.tween_property(objeto, propiedad, desde, segundos) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_animaciones.append(anim)


## Cambia el aspecto de la mesa según el reto esté pendiente o ya superado.
func _actualizar_mesa() -> void:
	for anim in _animaciones:
		anim.kill()
	_animaciones.clear()
	# Deja todo en su posición de reposo antes de volver a animar.
	_aura.modulate.a = 1.0
	_aura.scale = Vector2.ONE
	_marcador.position.y = -26.0

	var completo := GameState.tiene_sello(GameState.area_elegida)
	var color := COLOR_VERDE if completo else COLOR_ORO
	var borde := COLOR_VERDE_BORDE if completo else COLOR_ORO_BORDE

	_aura.color = Color(color.r, color.g, color.b, 0.28)
	_rotulo_mesa.text = "¡LISTO!" if completo else "¡RETO!"
	_rotulo_mesa.add_theme_color_override("font_color", color)
	_rotulo_mesa.add_theme_color_override("font_outline_color", borde)
	_flecha.get_node("Relleno").color = color
	_flecha.get_node("Contorno").color = borde
	_flecha.visible = not completo
	_chispas.emitting = not completo

	# El rótulo queda justo encima de la flecha (o solo, si el reto ya se superó).
	_rotulo_mesa.position.y = -26 if not completo else -12

	if completo:
		_oscilar(_aura, "modulate:a", 0.6, 1.0, 1.6)
		return

	_oscilar(_aura, "modulate:a", 0.35, 1.0, 0.55)
	_oscilar(_aura, "scale", Vector2(0.92, 0.92), Vector2(1.12, 1.12), 0.55)
	_oscilar(_marcador, "position:y", -26.0, -31.0, 0.45)


## Instancia el personaje elegido y fija su cámara al tamaño del cuarto.
func _instanciar_jugador() -> void:
	var escena: PackedScene = ESCENA_PERSONAJE_MASCULINO
	if GameState.personaje_elegido == "femenino":
		escena = ESCENA_PERSONAJE_FEMENINO

	jugador = escena.instantiate()
	jugador.position = POSICION_INICIAL_JUGADOR
	add_child(jugador)

	var camara: Camera2D = jugador.get_node("Camera2D")
	camara.make_current()
	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = ANCHO_CUARTO
	camara.limit_bottom = ALTO_CUARTO


## ENTER/Espacio (o botón A del mando): habla con el NPC, abre el reto o sale.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept") or event.is_echo():
		return
	if npc_cercano != null:
		_hablar_con(npc_cercano)
	elif jugador_en_mesa_reto:
		_abrir_reto()
	elif jugador_en_salida:
		GameState.regreso_de_interior = true
		GameState.ir_a_escena(ESCENA_MAPA)


func _hablar_con(npc: Npc) -> void:
	etiqueta_prompt.visible = false
	dialogo.abrir(npc.tipo)


func _abrir_reto() -> void:
	etiqueta_prompt.visible = false

	var tipo: FichaArea.TipoReto = FichaArea.TipoReto.SECUENCIA
	var titulo := "Reto del área"
	var texto := "Supera el reto para ganar el sello de esta área."
	if _ficha != null:
		tipo = _ficha.tipo_reto
		titulo = _ficha.titulo_reto
		texto = _ficha.texto_reto

	var reto := Reto.new()
	add_child(reto)
	reto.terminado.connect(_on_reto_terminado)
	reto.iniciar(tipo, titulo, texto, _ficha)


func _on_reto_terminado(completado: bool) -> void:
	if completado:
		GameState.agregar_sello(GameState.area_elegida)
		Audio.sfx("sello")
	_actualizar_mesa()
	_actualizar_titulo()
	_actualizar_prompt()


func _actualizar_titulo() -> void:
	var sello := "  ★" if GameState.tiene_sello(GameState.area_elegida) else ""
	etiqueta_titulo.text = "Interior: %s  (%d/3)%s" % [GameState.area_elegida, GameState.respuestas_dadas(), sello]


func _actualizar_prompt() -> void:
	if npc_cercano != null:
		etiqueta_prompt.text = "Presiona ENTER para hablar"
		etiqueta_prompt.visible = true
	elif jugador_en_mesa_reto:
		if GameState.tiene_sello(GameState.area_elegida):
			etiqueta_prompt.text = "Presiona ENTER para repetir el reto"
		else:
			etiqueta_prompt.text = "Presiona ENTER para el reto"
		etiqueta_prompt.visible = true
	elif jugador_en_salida:
		etiqueta_prompt.text = "Presiona ENTER para salir"
		etiqueta_prompt.visible = true
	else:
		etiqueta_prompt.visible = false


func _on_dialogo_cerrado() -> void:
	_actualizar_titulo()
	_actualizar_prompt()


func _on_respuesta_elegida(_tipo: int, _valor: String) -> void:
	# Al tener las 3 respuestas, se ofrece la decisión.
	if GameState.respuestas_completas():
		dialogo.abrir_decision()


func _on_decision_tomada(ver_resultados: bool) -> void:
	if not ver_resultados:
		# Vuelve al selector para probar otra área; las respuestas se conservan.
		GameState.ir_a_escena(ESCENA_SELECTOR)
		return

	var top := MotorResultados.calcular_top(
		GameState.area_elegida,
		GameState.fortaleza_1,
		GameState.fortaleza_2,
		GameState.objetivo
	)
	if ResourceLoader.exists(ESCENA_RESULTADOS):
		GameState.ir_a_escena(ESCENA_RESULTADOS)
	else:
		for i in top.size():
			print("%d. %s — %d%%" % [i + 1, top[i]["nombre"], top[i]["afinidad"]])


func _on_npc_jugador_cerca(npc: Npc) -> void:
	npc_cercano = npc
	_actualizar_prompt()


func _on_npc_jugador_lejos(npc: Npc) -> void:
	if npc_cercano == npc:
		npc_cercano = null
	_actualizar_prompt()


func _on_salida_body_entered(body: Node) -> void:
	if body == jugador:
		jugador_en_salida = true
		_actualizar_prompt()


func _on_salida_body_exited(body: Node) -> void:
	if body == jugador:
		jugador_en_salida = false
		_actualizar_prompt()


func _on_mesa_body_entered(body: Node) -> void:
	if body == jugador:
		jugador_en_mesa_reto = true
		if not GameState.tiene_sello(GameState.area_elegida):
			Audio.sfx("reto_cerca")
		_actualizar_prompt()


func _on_mesa_body_exited(body: Node) -> void:
	if body == jugador:
		jugador_en_mesa_reto = false
		_actualizar_prompt()
