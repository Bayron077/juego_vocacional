class_name DialogoNpc
extends CanvasLayer

## Panel de diálogo reutilizable para los 3 NPC y para la decisión final.
## Funciona con teclado, mouse y mando (el foco se pone en el primer botón).

signal respuesta_elegida(tipo: int, valor: String)
signal cerrado
signal decision_tomada(ver_resultados: bool)

const TAM_TITULO := 12
const TAM_BOTON := 10

var tipo_actual: int = Npc.Tipo.FORTALEZA_1
var categoria_actual: String = ""
var en_decision: bool = false

@onready var titulo: Label = $Marco/Margen/Caja/Titulo
@onready var lista: VBoxContainer = $Marco/Margen/Caja/Lista


func _ready() -> void:
	# Debe seguir funcionando mientras el juego está en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	titulo.add_theme_font_size_override("font_size", TAM_TITULO)
	visible = false


func abrir(tipo: int) -> void:
	tipo_actual = tipo
	en_decision = false
	visible = true
	get_tree().paused = true  # congela al jugador mientras se responde
	_mostrar_categorias()


func abrir_decision() -> void:
	en_decision = true
	visible = true
	get_tree().paused = true
	_limpiar_lista()
	titulo.text = "¡Tu perfil está listo!\n¿Qué quieres hacer?"

	var ver := _crear_boton("Ver mis resultados")
	ver.pressed.connect(_on_decision.bind(true))
	var seguir := _crear_boton("Seguir explorando")
	seguir.pressed.connect(_on_decision.bind(false))
	ver.grab_focus.call_deferred()


func cerrar() -> void:
	visible = false
	get_tree().paused = false
	cerrado.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or en_decision:
		return
	# Escape o botón B del mando: volver atrás o cerrar.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if categoria_actual != "":
			_mostrar_categorias()
		else:
			cerrar()


func _mostrar_categorias() -> void:
	categoria_actual = ""
	_limpiar_lista()
	titulo.text = CatalogoDialogo.titulo_para(tipo_actual) + "\n" + CatalogoDialogo.pregunta_para(tipo_actual)

	var primero: Button = null
	for categoria in CatalogoDialogo.categorias_para(tipo_actual):
		var boton := _crear_boton(categoria)
		boton.pressed.connect(_on_categoria_elegida.bind(categoria))
		if primero == null:
			primero = boton
	primero.grab_focus.call_deferred()


func _mostrar_opciones() -> void:
	_limpiar_lista()
	titulo.text = categoria_actual

	# La segunda fortaleza no puede repetir la primera (y viceversa).
	var bloqueado := _valor_bloqueado()
	var primero: Button = null
	for valor in CatalogoDialogo.categorias_para(tipo_actual)[categoria_actual]:
		if valor == bloqueado:
			continue
		var boton := _crear_boton(valor)
		boton.pressed.connect(_on_opcion_elegida.bind(valor))
		if primero == null:
			primero = boton

	var volver := _crear_boton("← Volver")
	volver.pressed.connect(_mostrar_categorias)
	if primero == null:
		primero = volver
	primero.grab_focus.call_deferred()


func _valor_bloqueado() -> String:
	match tipo_actual:
		Npc.Tipo.FORTALEZA_1:
			return GameState.fortaleza_2
		Npc.Tipo.FORTALEZA_2:
			return GameState.fortaleza_1
	return ""


func _crear_boton(texto: String) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.add_theme_font_size_override("font_size", TAM_BOTON)
	lista.add_child(boton)
	return boton


func _limpiar_lista() -> void:
	for hijo in lista.get_children():
		lista.remove_child(hijo)
		hijo.queue_free()


func _on_categoria_elegida(categoria: String) -> void:
	categoria_actual = categoria
	_mostrar_opciones()


func _on_opcion_elegida(valor: String) -> void:
	GameState.guardar_respuesta(tipo_actual, valor)
	cerrar()
	# Se emite DESPUÉS de cerrar, para que quien escuche pueda abrir otro panel.
	respuesta_elegida.emit(tipo_actual, valor)


func _on_decision(ver_resultados: bool) -> void:
	en_decision = false
	visible = false
	get_tree().paused = false
	decision_tomada.emit(ver_resultados)
