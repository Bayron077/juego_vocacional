extends Node2D

## Interior reutilizable para las 17 áreas: un cuarto con 3 NPC, una mesa de reto
## opcional y una salida.

const ANCHO_CUARTO := 480
const ALTO_CUARTO := 270
const GROSOR_PARED := 16
const POSICION_INICIAL_JUGADOR := Vector2(240, 180)
## Dónde está la mesa del reto. Si estorba con la salida u otro objeto, cámbiala aquí.
const POSICION_MESA_RETO := Vector2(430, 135)
const RUTA_FICHAS := "res://recursos/areas/"

const ESCENA_MAPA := "res://escenas/mundo/mapa_area.tscn"
const ESCENA_SELECTOR := "res://escenas/ui/selector_area.tscn"
const ESCENA_RESULTADOS := "res://escenas/ui/resultados.tscn"
const ESCENA_PERSONAJE_MASCULINO: PackedScene = preload("res://personajes/player_levy.tscn")
const ESCENA_PERSONAJE_FEMENINO: PackedScene = preload("res://personajes/Eda.tscn")

const COLOR_MESA_PENDIENTE := Color(1.0, 0.8, 0.2)
const COLOR_MESA_COMPLETA := Color(0.4, 0.7, 0.4)

var jugador: CharacterBody2D
var npc_cercano: Npc = null
var jugador_en_salida: bool = false
var jugador_en_mesa_reto: bool = false

var _ficha: FichaArea = null
var _visual_mesa: ColorRect

@onready var salida: Area2D = $Salida
@onready var dialogo: DialogoNpc = $DialogoNpc
@onready var etiqueta_titulo: Label = $CapaUI/EtiquetaTitulo
@onready var etiqueta_prompt: Label = $CapaUI/EtiquetaPrompt


func _ready() -> void:
	_crear_paredes()
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


## Crea las 4 paredes invisibles alrededor del cuarto para que el jugador no salga.
func _crear_paredes() -> void:
	var rectangulos: Array[Rect2] = [
		Rect2(-GROSOR_PARED, -GROSOR_PARED, ANCHO_CUARTO + GROSOR_PARED * 2, GROSOR_PARED), # arriba
		Rect2(-GROSOR_PARED, ALTO_CUARTO, ANCHO_CUARTO + GROSOR_PARED * 2, GROSOR_PARED), # abajo
		Rect2(-GROSOR_PARED, 0, GROSOR_PARED, ALTO_CUARTO), # izquierda
		Rect2(ANCHO_CUARTO, 0, GROSOR_PARED, ALTO_CUARTO), # derecha
	]
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
			print("RETO: no se pudo cargar ", archivo)
			continue
		if _normalizar(ficha.nombre_area) == buscado:
			print("RETO: ficha encontrada -> ", archivo, " | tipo=", ficha.tipo_reto, " | titulo=", ficha.titulo_reto)
			return ficha
	print("RETO: NO se encontró ficha para '", GameState.area_elegida, "'")
	return null


## Crea por código la mesa del reto: un bloque dorado con su zona de interacción.
func _crear_mesa_reto() -> void:
	_ficha = _buscar_ficha()

	var mesa := Area2D.new()
	mesa.position = POSICION_MESA_RETO

	var colision := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = Vector2(36, 24)
	colision.shape = forma
	mesa.add_child(colision)

	_visual_mesa = ColorRect.new()
	_visual_mesa.size = Vector2(36, 24)
	_visual_mesa.position = -_visual_mesa.size / 2.0
	mesa.add_child(_visual_mesa)

	var etiqueta := Label.new()
	etiqueta.text = "Reto"
	etiqueta.add_theme_font_size_override("font_size", 8)
	etiqueta.position = Vector2(-12, -26)
	mesa.add_child(etiqueta)

	add_child(mesa)
	mesa.body_entered.connect(_on_mesa_body_entered)
	mesa.body_exited.connect(_on_mesa_body_exited)
	_actualizar_mesa()


func _actualizar_mesa() -> void:
	if GameState.tiene_sello(GameState.area_elegida):
		_visual_mesa.color = COLOR_MESA_COMPLETA
	else:
		_visual_mesa.color = COLOR_MESA_PENDIENTE


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
	print("RETO: algo entró a la mesa -> ", body.name)
	if body == jugador:
		jugador_en_mesa_reto = true
		_actualizar_prompt()


func _on_mesa_body_exited(body: Node) -> void:
	if body == jugador:
		jugador_en_mesa_reto = false
		_actualizar_prompt()
