extends Node2D

## Interior reutilizable para las 17 áreas: un cuarto con 3 NPC y una salida.

const ANCHO_CUARTO := 480
const ALTO_CUARTO := 270
const GROSOR_PARED := 16
const POSICION_INICIAL_JUGADOR := Vector2(240, 180)

const ESCENA_MAPA := "res://escenas/mundo/mapa_area.tscn"
const ESCENA_SELECTOR := "res://escenas/ui/selector_area.tscn"
const ESCENA_RESULTADOS := "res://escenas/ui/resultados.tscn"
const ESCENA_PERSONAJE_MASCULINO: PackedScene = preload("res://personajes/player_levy.tscn")
const ESCENA_PERSONAJE_FEMENINO: PackedScene = preload("res://personajes/Eda.tscn")

var jugador: CharacterBody2D
var npc_cercano: Npc = null
var jugador_en_salida: bool = false

@onready var salida: Area2D = $Salida
@onready var dialogo: DialogoNpc = $DialogoNpc
@onready var etiqueta_titulo: Label = $CapaUI/EtiquetaTitulo
@onready var etiqueta_prompt: Label = $CapaUI/EtiquetaPrompt


func _ready() -> void:
	_crear_paredes()
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


## ENTER/Espacio (o botón A del mando): habla con el NPC cercano o sale.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept") or event.is_echo():
		return
	if npc_cercano != null:
		_hablar_con(npc_cercano)
	elif jugador_en_salida:
		GameState.ir_a_escena(ESCENA_MAPA)


func _hablar_con(npc: Npc) -> void:
	etiqueta_prompt.visible = false
	dialogo.abrir(npc.tipo)


func _actualizar_titulo() -> void:
	etiqueta_titulo.text = "Interior: %s  (%d/3)" % [GameState.area_elegida, GameState.respuestas_dadas()]


func _actualizar_prompt() -> void:
	if npc_cercano != null:
		etiqueta_prompt.text = "Presiona ENTER para hablar"
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
	# La pantalla de resultados todavía no existe (próxima parte): por ahora, consola.
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
