extends Node

## Registro opcional del estudiante y envío del resultado del test a Google Sheets.
##
## - Cada vez que aparece la pantalla de inicio se genera un código corto (K7P2).
##   El QR del inicio lleva a un formulario (Apps Script) con ese código.
## - Al terminar el test, el juego envía el resultado con el mismo código y la hoja
##   une registro + resultado en una sola fila.
## - Si no hay internet, el resultado se guarda en el disco y se reenvía solo.
## - Si falta data/registro_config.json, el registro queda desactivado y el juego
##   funciona igual que antes (sin QR).

signal codigo_cambiado(codigo: String)

const RUTA_CONFIG := "res://data/registro_config.json"
const RUTA_COLA := "user://registro_pendientes.json"

## Solo letras y números que no se confunden entre sí (sin S/5, B/8, Z/2, G/6, U/V, D/O/0, I/L/1, Q).
const ALFABETO := "ACEFHJKMNPRTWXY3479"
const LARGO_CODIGO := 4

const SEGUNDOS_REINTENTO := 30.0
const TIMEOUT_SEGUNDOS := 20.0
const MAX_PENDIENTES := 500
## Tras tantos fallos seguidos, un resultado pasa al final de la fila para no bloquear a los demás.
const FALLOS_ANTES_DE_ROTAR := 10

var codigo_actual: String = ""

var _url_base := ""
var _token := ""
var _cola: Array = []
var _enviando := false
var _codigo_ya_enviado := ""
var _http: HTTPRequest


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cargar_config()
	nuevo_codigo()
	if not habilitado():
		return

	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_SEGUNDOS
	_http.request_completed.connect(_on_respuesta)
	add_child(_http)

	var reloj := Timer.new()
	reloj.wait_time = SEGUNDOS_REINTENTO
	reloj.autostart = true
	reloj.timeout.connect(_intentar_envio)
	add_child(reloj)

	_cargar_cola()
	_intentar_envio.call_deferred()


func habilitado() -> bool:
	return _url_base != "" and _token != ""


## Genera un código nuevo. Se llama cada vez que aparece la pantalla de inicio.
func nuevo_codigo() -> String:
	var c := ""
	for i in LARGO_CODIGO:
		c += ALFABETO[randi() % ALFABETO.length()]
	codigo_actual = c
	codigo_cambiado.emit(c)
	return c


## Dirección que va dentro del QR.
func url_formulario() -> String:
	return "%s?c=%s" % [_url_base, codigo_actual]


## Se llama una vez al llegar a la pantalla de resultados. `top` es la lista de
## MotorResultados.calcular_top (cada elemento con "nombre" y "afinidad").
func enviar_resultado(top: Array) -> void:
	if not habilitado() or codigo_actual == "" or codigo_actual == _codigo_ya_enviado:
		return
	_codigo_ya_enviado = codigo_actual

	var p := {
		"c": codigo_actual,
		"area": GameState.area_elegida,
		"pj": GameState.personaje_elegido,
	}
	for i in mini(top.size(), 3):
		p["t%d" % (i + 1)] = str(top[i].get("nombre", ""))
		p["p%d" % (i + 1)] = str(top[i].get("afinidad", ""))

	_cola.append({"p": p, "intentos": 0})
	while _cola.size() > MAX_PENDIENTES:
		_cola.pop_front()
	_guardar_cola()
	_intentar_envio()


# ------------------------------------------------------------------ configuración

func _cargar_config() -> void:
	if not FileAccess.file_exists(RUTA_CONFIG):
		push_warning("Registro: no existe %s. El registro queda desactivado." % RUTA_CONFIG)
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_CONFIG))
	if not datos is Dictionary:
		push_warning("Registro: %s no es un JSON válido. El registro queda desactivado." % RUTA_CONFIG)
		return
	var url := str(datos.get("url", "")).strip_edges()
	var token := str(datos.get("token", "")).strip_edges()
	var local := url.begins_with("http://127.0.0.1") or url.begins_with("http://localhost")
	if token == "" or "?" in url or not (url.begins_with("https://") or local):
		push_warning("Registro: la 'url' debe ser https://.../exec (sin '?') y el 'token' no puede ir vacío.")
		return
	_url_base = url
	_token = token


# ------------------------------------------------------------------------ envío

func _url_resultado(p: Dictionary) -> String:
	var partes: Array = ["accion=resultado", "token=" + _token.uri_encode()]
	for clave in p:
		partes.append("%s=%s" % [clave, str(p[clave]).uri_encode()])
	return "%s?%s" % [_url_base, "&".join(partes)]


func _intentar_envio() -> void:
	if _enviando or _cola.is_empty() or not habilitado():
		return
	var err := _http.request(_url_resultado(_cola[0]["p"]))
	if err != OK:
		push_warning("Registro: no se pudo iniciar el envío (error %d). Se reintenta." % err)
		return
	_enviando = true


func _on_respuesta(resultado: int, codigo_http: int, _cabeceras: PackedStringArray, cuerpo: PackedByteArray) -> void:
	_enviando = false
	var ok := false
	var rechazado := false
	if resultado == HTTPRequest.RESULT_SUCCESS and codigo_http == 200:
		var r: Variant = JSON.parse_string(cuerpo.get_string_from_utf8())
		if r is Dictionary:
			ok = bool(r.get("ok", false))
			# El servidor lo recibió pero lo rechazó (token o código malos): reintentar no sirve.
			rechazado = not ok and str(r.get("error", "")) in ["token", "codigo"]

	if ok or rechazado:
		var enviado: Dictionary = _cola.pop_front()
		_guardar_cola()
		if rechazado:
			push_warning("Registro: el servidor rechazó el resultado %s." % str(enviado["p"].get("c", "?")))
		elif OS.is_debug_build():
			print("Registro: resultado enviado (código %s)." % str(enviado["p"].get("c", "?")))
		if not _cola.is_empty():
			_intentar_envio.call_deferred()
		return

	# Sin internet o respuesta rara: se queda en la fila y el reloj lo reintenta.
	_cola[0]["intentos"] = int(_cola[0].get("intentos", 0)) + 1
	if _cola[0]["intentos"] >= FALLOS_ANTES_DE_ROTAR and _cola.size() > 1:
		_cola.append(_cola.pop_front())
	_guardar_cola()
	push_warning("Registro: envío fallido (resultado %d, HTTP %d). Pendientes: %d." % [resultado, codigo_http, _cola.size()])


# ------------------------------------------------------------ fila en el disco

func _guardar_cola() -> void:
	var archivo := FileAccess.open(RUTA_COLA, FileAccess.WRITE)
	if archivo == null:
		push_warning("Registro: no se pudo guardar la fila de pendientes.")
		return
	archivo.store_string(JSON.stringify(_cola))
	archivo.close()


func _cargar_cola() -> void:
	if not FileAccess.file_exists(RUTA_COLA):
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_COLA))
	if not datos is Array:
		return
	for item in datos:
		if item is Dictionary and item.get("p") is Dictionary:
			_cola.append(item)
