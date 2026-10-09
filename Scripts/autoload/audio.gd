extends Node
## Autoload "Audio": música de fondo según la pantalla, efectos de sonido y pasos.
## Si falta algún archivo de audio, simplemente no suena (el juego no se rompe).
## Tecla M: silenciar / activar todo el sonido (útil en el stand).

const CARPETA_MUSICA := "res://assets/audio/musica/"
const CARPETA_SFX := "res://assets/audio/sfx/"
const EXTENSIONES := [".ogg", ".wav", ".mp3"]

## Volúmenes en decibeles: 0 = original, -6 ≈ la mitad, -12 ≈ un cuarto.
const VOLUMEN_MUSICA_DB := -9.0
const VOLUMEN_SFX_DB := -3.0
const VOLUMEN_PASOS_DB := -9.0

## Segundos que dura el cambio suave entre una canción y otra.
const FUNDIDO := 0.7
## Segundos entre un paso y el siguiente.
const INTERVALO_PASOS := 0.3
## Después de cambiar de pantalla, los botones no suenan este tiempo (evita el
## "tic" que haría el primer botón al recibir el foco).
const SILENCIO_AL_CAMBIAR_MS := 600

## Qué canción suena en cada pantalla (nombre del archivo .tscn sin extensión).
## Las pantallas que no aparezcan aquí dejan sonar la canción actual.
const MUSICA_POR_ESCENA := {
	"inicio": "musica_menu",
	"SeleccionPersonaje": "musica_menu",
	"contexto": "musica_menu",
	"selector_area": "musica_menu",
	"mapa_area": "musica_explorar",
	"interior_edificio": "musica_explorar",
	"resultados": "musica_resultados",
}

const EFECTOS := [
	"ui_mover", "ui_aceptar", "paso_1", "paso_2",
	"reto_cerca", "sello", "exito", "error",
]
const CANALES_EFECTOS := 6

var _musica: Array[AudioStreamPlayer] = []
var _musica_activa: int = 0
var _pista_actual: String = ""
var _fundido: Tween

var _efectos: Dictionary = {}
var _canales: Array[AudioStreamPlayer] = []
var _siguiente_canal: int = 0

var _reproductor_pasos: AudioStreamPlayer
var _tiempo_pasos: float = 0.0
var _paso_alterno: bool = false

var _silencio_ui_hasta: int = 0
var _silenciado: bool = false


func _ready() -> void:
	# Sigue sonando aunque el juego esté en pausa (diálogos y retos).
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -60.0
		add_child(p)
		_musica.append(p)

	for i in CANALES_EFECTOS:
		var p := AudioStreamPlayer.new()
		p.volume_db = VOLUMEN_SFX_DB
		add_child(p)
		_canales.append(p)

	_reproductor_pasos = AudioStreamPlayer.new()
	_reproductor_pasos.volume_db = VOLUMEN_PASOS_DB
	add_child(_reproductor_pasos)

	for nombre in EFECTOS:
		var flujo := _cargar(CARPETA_SFX + nombre)
		if flujo != null:
			_efectos[nombre] = flujo

	# Sonido automático en TODOS los botones del juego, sin tocar cada escena.
	get_tree().node_added.connect(_on_nodo_agregado)

	# Revisa cada cuarto de segundo qué pantalla está activa para elegir la música.
	var reloj := Timer.new()
	reloj.wait_time = 0.25
	reloj.autostart = true
	reloj.timeout.connect(_revisar_escena)
	add_child(reloj)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		_silenciado = not _silenciado
		AudioServer.set_bus_mute(0, _silenciado)


## Reproduce un efecto por su nombre (ver EFECTOS). "variacion" cambia un poco el
## tono al azar para que no suene idéntico cada vez.
func sfx(nombre: String, variacion: float = 0.0) -> void:
	if not _efectos.has(nombre):
		return
	var canal := _canales[_siguiente_canal]
	_siguiente_canal = (_siguiente_canal + 1) % _canales.size()
	canal.stream = _efectos[nombre]
	canal.pitch_scale = 1.0 + randf_range(-variacion, variacion)
	canal.play()


## Llamar en cada _physics_process del jugador: suena un paso a intervalos
## mientras se mueve.
func pasos(moviendo: bool, delta: float) -> void:
	if not moviendo:
		# Al arrancar, el primer paso suena casi de inmediato.
		_tiempo_pasos = INTERVALO_PASOS * 0.6
		return
	_tiempo_pasos += delta
	if _tiempo_pasos < INTERVALO_PASOS:
		return
	_tiempo_pasos = 0.0
	_paso_alterno = not _paso_alterno
	var flujo: AudioStream = _efectos.get("paso_1" if _paso_alterno else "paso_2")
	if flujo == null:
		return
	_reproductor_pasos.stream = flujo
	_reproductor_pasos.pitch_scale = randf_range(0.92, 1.08)
	_reproductor_pasos.play()


## Cambia la música con un fundido. Pasar "" la detiene.
func musica(pista: String) -> void:
	if pista == _pista_actual:
		return
	_pista_actual = pista

	var anterior := _musica[_musica_activa]
	_musica_activa = 1 - _musica_activa
	var siguiente := _musica[_musica_activa]

	# Se cancela el fundido anterior y se crea uno nuevo SOLO si hay algo que animar
	# (un Tween sin animaciones daba un error en el depurador).
	if _fundido != null:
		_fundido.kill()
		_fundido = null

	if pista != "":
		var flujo := _cargar(CARPETA_MUSICA + pista)
		if flujo != null:
			_activar_bucle(flujo)
			siguiente.stream = flujo
			siguiente.volume_db = -60.0
			siguiente.play()
			_fundido = create_tween().set_parallel(true)
			_fundido.tween_property(siguiente, "volume_db", VOLUMEN_MUSICA_DB, FUNDIDO)

	if anterior.playing:
		if _fundido == null:
			_fundido = create_tween().set_parallel(true)
		_fundido.tween_property(anterior, "volume_db", -60.0, FUNDIDO)
		_fundido.chain().tween_callback(anterior.stop)


func _revisar_escena() -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return
	var nombre := escena.scene_file_path.get_file().get_basename()
	if MUSICA_POR_ESCENA.has(nombre):
		musica(MUSICA_POR_ESCENA[nombre])


func _on_nodo_agregado(nodo: Node) -> void:
	# Un nodo nuevo cuyo padre es la raíz es una escena recién cargada.
	if nodo.get_parent() == get_tree().root and nodo != self:
		_silencio_ui_hasta = Time.get_ticks_msec() + SILENCIO_AL_CAMBIAR_MS
	if nodo is BaseButton:
		nodo.focus_entered.connect(_on_boton_foco)
		nodo.pressed.connect(_on_boton_presionado)


func _on_boton_foco() -> void:
	if Time.get_ticks_msec() >= _silencio_ui_hasta:
		sfx("ui_mover")


func _on_boton_presionado() -> void:
	sfx("ui_aceptar")


## Busca el archivo con cualquiera de las extensiones permitidas.
func _cargar(ruta_sin_extension: String) -> AudioStream:
	for extension in EXTENSIONES:
		var ruta: String = ruta_sin_extension + extension
		if ResourceLoader.exists(ruta):
			return load(ruta) as AudioStream
	push_warning("Audio: no se encontró '%s'." % ruta_sin_extension)
	return null


## Hace que la canción se repita sin parar.
func _activar_bucle(flujo: AudioStream) -> void:
	if flujo is AudioStreamOggVorbis:
		flujo.loop = true
	elif flujo is AudioStreamMP3:
		flujo.loop = true
	elif flujo is AudioStreamWAV:
		var bytes_por_muestra := 2 if flujo.format == AudioStreamWAV.FORMAT_16_BITS else 1
		if flujo.stereo:
			bytes_por_muestra *= 2
		flujo.loop_mode = AudioStreamWAV.LOOP_FORWARD
		flujo.loop_begin = 0
		flujo.loop_end = flujo.data.size() / bytes_por_muestra
