extends Node
## TEMPORAL: diagnóstico del mando. Se agrega como autoload (nombre: MandoDebug),
## se ejecuta el juego y se mira la pestaña Salida. Luego se quita.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_conexion)
	var ids := Input.get_connected_joypads()
	print("MANDO: conectados al iniciar -> ", ids)
	for id in ids:
		print("MANDO: id ", id, " nombre: ", Input.get_joy_name(id), " | guid: ", Input.get_joy_guid(id))
		print("MANDO: id ", id, " info: ", Input.get_joy_info(id))


func _on_conexion(id: int, conectado: bool) -> void:
	print("MANDO: id ", id, " conectado=", conectado, " nombre: ", Input.get_joy_name(id))


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		print("MANDO: botón ", event.button_index, " (dispositivo ", event.device, ")")
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		print("MANDO: eje ", event.axis, " = ", snappedf(event.axis_value, 0.01), " (dispositivo ", event.device, ")")
