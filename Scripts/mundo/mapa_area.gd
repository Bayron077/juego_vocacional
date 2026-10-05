extends Node2D

## Tamaño del mundo jugable de cada área (en píxeles).
const ANCHO_MUNDO := 640
const ALTO_MUNDO := 360

## Carpeta donde viven las fichas de datos de cada área.
const RUTA_FICHAS := "res://recursos/areas/"

## Qué archivo de ficha corresponde a cada área elegida en el selector.
## El texto de la izquierda debe coincidir EXACTO con selector_area.gd.
const FICHAS_POR_AREA := {
	"Tecnología y computación": "tecnologia_y_computacion.tres",
	"Matemáticas y ciencias exactas": "matematicas_y_ciencias_exactas.tres",
	"Ciencias naturales y experimentales": "ciencias_naturales_y_experimentales.tres",
	"Ingeniería y tecnología aplicada": "ingenieria_y_tecnologia_aplicada.tres",
	"Electricidad, electrónica y automatización": "electricidad_electronica_y_automatizacion.tres",
	"Industria, manufactura y producción": "industria_manufactura_y_produccion.tres",
	"Medio ambiente y sostenibilidad": "medio_ambiente_y_sostenibilidad.tres",
	"Agro, territorio y naturaleza": "agro_territorio_y_naturaleza.tres",
	"Administración, negocios y emprendimiento": "administracion_negocios_y_emprendimiento.tres",
	"Educación y enseñanza": "educacion_y_ensenanza.tres",
	"Comunicación, medios y creatividad": "comunicacion_medios_y_creatividad.tres",
	"Turismo, cultura y servicios": "turismo_cultura_y_servicios.tres",
	"Salud y cuidado": "salud_y_cuidado.tres",
	"Artes, música y expresión creativa": "artes_musica_y_expresion_creativa.tres",
	"Sociedad, cultura y humanidades": "sociedad_cultura_y_humanidades.tres",
	"Deporte, actividad física y recreación": "deporte_actividad_fisica_y_recreacion.tres",
	"Idiomas, lenguas y comunicación intercultural": "idiomas_lenguas_y_comunicacion_intercultural.tres",
}

const ESCENA_PERSONAJE_MASCULINO: PackedScene = preload("res://personajes/player_levy.tscn")
const ESCENA_PERSONAJE_FEMENINO: PackedScene = preload("res://personajes/Eda.tscn")
const ESCENA_INTERIOR := "res://escenas/mundo/interior_edificio.tscn"

var ficha: FichaArea
var jugador: CharacterBody2D
var camara: Camera2D
var jugador_en_zona_edificio: bool = false

@onready var fondo: ColorRect = $Fondo
@onready var edificio: Node2D = $Edificio
@onready var area_entrada: Area2D = $Edificio/AreaEntrada
@onready var etiqueta_edificio: Label = $EtiquetaEdificio
@onready var etiqueta_prompt: Label = $CapaUI/EtiquetaPrompt


func _ready() -> void:
	_cargar_ficha_area()
	_instanciar_jugador()
	_aplicar_ficha_al_mundo()
	etiqueta_prompt.visible = false
	area_entrada.body_entered.connect(_on_area_entrada_body_entered)
	area_entrada.body_exited.connect(_on_area_entrada_body_exited)


## Carga la ficha (Resource) del área que el jugador eligió en el selector.
## Si la ficha no existe todavía, usa valores por defecto en vez de fallar,
## así el mapa siempre se puede probar aunque falten fichas por crear.
func _cargar_ficha_area() -> void:
	var nombre_archivo: String = FICHAS_POR_AREA.get(GameState.area_elegida, "")
	var ruta: String = RUTA_FICHAS + nombre_archivo
	if nombre_archivo != "" and ResourceLoader.exists(ruta):
		ficha = load(ruta) as FichaArea
	else:
		push_warning("No hay ficha para el área: '" + GameState.area_elegida + "'. Usando valores por defecto.")
		ficha = FichaArea.new()
		ficha.nombre_area = GameState.area_elegida


## Instancia el personaje elegido y configura su cámara para que siga
## al jugador sin salirse de los bordes del mundo.
func _instanciar_jugador() -> void:
	var escena_personaje: PackedScene = ESCENA_PERSONAJE_MASCULINO
	if GameState.personaje_elegido == "femenino":
		escena_personaje = ESCENA_PERSONAJE_FEMENINO

	jugador = escena_personaje.instantiate()
	jugador.position = ficha.posicion_jugador_inicial
	add_child(jugador)

	camara = jugador.get_node("Camera2D")
	camara.make_current()
	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = ANCHO_MUNDO
	camara.limit_bottom = ALTO_MUNDO


## Pinta el mundo con los datos de la ficha: color, posición del edificio y su nombre.
func _aplicar_ficha_al_mundo() -> void:
	fondo.color = ficha.color_zona
	edificio.position = ficha.posicion_edificio
	etiqueta_edificio.text = ficha.nombre_edificio
	etiqueta_edificio.position = ficha.posicion_edificio + Vector2(-50, -90)


## Mientras el jugador esté en la zona de entrada, ENTER/Espacio
## (o el botón A del mando) lo manda al interior del edificio.
func _unhandled_input(event: InputEvent) -> void:
	if jugador_en_zona_edificio and event.is_action_pressed("ui_accept"):
		GameState.ir_a_escena(ESCENA_INTERIOR)


func _on_area_entrada_body_entered(body: Node) -> void:
	if body == jugador:
		jugador_en_zona_edificio = true
		etiqueta_prompt.visible = true


func _on_area_entrada_body_exited(body: Node) -> void:
	if body == jugador:
		jugador_en_zona_edificio = false
		etiqueta_prompt.visible = false
