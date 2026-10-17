extends Node

## Registro del estudiante y envío del resultado del test a Google Sheets, usando Google Forms.
##
## - Cada vez que aparece la pantalla de inicio se genera un código corto (K7P2).
##   El QR del inicio abre el Form de REGISTRO con ese código ya escrito.
## - Al terminar el test, el juego envía el resultado al Form de RESULTADOS con el mismo
##   código (POST directo a "formResponse"). Cada Form cae en su pestaña del mismo Sheet.
## - Si no hay internet, el resultado se guarda en el disco y se reenvía solo.
## - No hay token ni servidor propio: los Forms son públicos por diseño.

signal codigo_cambiado(codigo: String)

const RUTA_COLA := "user://registro_pendientes.json"

## Form de REGISTRO (el que abre el celular al escanear el QR).
const FORM_REGISTRO := "https://docs.google.com/forms/d/e/1FAIpQLSc1IGHszz1TIgxAjKnnKukMK3sWtn6CRfiQLcLcL2jor7AhIQ/viewform"
const CAMPO_REGISTRO_CODIGO := "entry.1901447343"

## Form de RESULTADOS (el juego le envía los datos por POST).
const FORM_RESULTADO := "https://docs.google.com/forms/d/e/1FAIpQLSckR4Qskyo0NzYPKCO3bucp4may1OlTZYrkPTM4uarouDLJxA/formResponse"
const CAMPOS_RESULTADO := {
	"c": "entry.1249317865",
	"area": "entry.1918119877",
	"t1": "entry.375879812",
	"p1": "entry.536228958",
	"t2": "entry.1519094436",
	"p2": "entry.704308209",
	"t3": "entry.119252018",
	"p3": "entry.96112473",
}

## Solo letras y números que no se confunden entre sí (sin S/5, B/8, Z/2, G/6, U/V, D/O/0, I/L/1, Q).
const ALFABETO := "ACEFHJKMNPRTWXY3479"
const LARGO_CODIGO := 4

const SEGUNDOS_REINTENTO := 30.0
const TIMEOUT_SEGUNDOS := 20.0
const MAX_PENDIENTES := 500
## Tras tantos fallos seguidos, un resultado pasa al final de la fila para no bloquear a los demás.
const FALLOS_ANTES_DE_ROTAR := 10

var codigo_actual: String = ""

var _url_resultado_form := FORM_RESULTADO
var _cola: Array = []
var _enviando := false
var _codigo_ya_enviado := ""
var _http: HTTPRequest


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Solo para pruebas en el editor: un servidor local en lugar de Google.
	if OS.has_feature("editor") and OS.get_environment("REGISTRO_URL_PRUEBA") != "":
		_url_resultado_form = OS.get_environment("REGISTRO_URL_PRUEBA")
	nuevo_codigo()

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
	return true


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
	return "%s?usp=pp_url&%s=%s" % [FORM_REGISTRO, CAMPO_REGISTRO_CODIGO, codigo_actual]


## Se llama una vez al llegar a la pantalla de resultados. `top` es la lista de
## MotorResultados.calcular_top (cada elemento con "nombre" y "afinidad").
func enviar_resultado(top: Array) -> void:
	if codigo_actual == "" or codigo_actual == _codigo_ya_enviado:
		return
	_codigo_ya_enviado = codigo_actual

	var p := {
		"c": codigo_actual,
		"area": GameState.area_elegida,
	}
	for i in mini(top.size(), 3):
		p["t%d" % (i + 1)] = str(top[i].get("nombre", ""))
		p["p%d" % (i + 1)] = str(top[i].get("afinidad", ""))

	_cola.append({"p": p, "intentos": 0})
	while _cola.size() > MAX_PENDIENTES:
		_cola.pop_front()
	_guardar_cola()
	_intentar_envio()


# ------------------------------------------------------------------------ envío

## Cuerpo del POST: "entry.123=valor&entry.456=valor...".
func _cuerpo_resultado(p: Dictionary) -> String:
	var partes: Array = []
	for clave in CAMPOS_RESULTADO:
		if p.has(clave):
			partes.append("%s=%s" % [CAMPOS_RESULTADO[clave], str(p[clave]).uri_encode()])
	return "&".join(partes)


func _intentar_envio() -> void:
	if _enviando or _cola.is_empty():
		return
	var cabeceras := PackedStringArray(["Content-Type: application/x-www-form-urlencoded"])
	var err := _http.request(_url_resultado_form, cabeceras, HTTPClient.METHOD_POST, _cuerpo_resultado(_cola[0]["p"]))
	if err != OK:
		push_warning("Registro: no se pudo iniciar el envío (error %d). Se reintenta." % err)
		return
	_enviando = true


func _on_respuesta(resultado: int, codigo_http: int, _cabeceras: PackedStringArray, _cuerpo: PackedByteArray) -> void:
	_enviando = false
	# Google responde 200 (página "respuesta registrada"). Un 400/404 significa que el Form
	# no acepta el dato (mal configurado): reintentar no sirve.
	var ok := resultado == HTTPRequest.RESULT_SUCCESS and codigo_http == 200
	var rechazado := resultado == HTTPRequest.RESULT_SUCCESS and codigo_http in [400, 401, 403, 404]

	if ok or rechazado:
		var enviado: Dictionary = _cola.pop_front()
		_guardar_cola()
		if rechazado:
			push_warning("Registro: el Form rechazó el resultado %s (HTTP %d)." % [str(enviado["p"].get("c", "?")), codigo_http])
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
