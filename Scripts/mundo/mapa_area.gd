extends Node2D

## Tamaño del mundo jugable de cada área (en píxeles).
const ANCHO_MUNDO := 640.0
const ALTO_MUNDO := 360.0

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

## Al volver del interior (en mapas SIN arte), el jugador aparece a esta distancia
## de la posición del edificio, justo debajo de la zona de entrada.
const DESPLAZAMIENTO_REGRESO := Vector2(0, 65)

## Tamaño del personaje en el mapa. 1.0 = tamaño original. Con 0.8 se ve un
## poco más pequeño y encaja mejor con los edificios; sube o baja este número
## (por ejemplo 0.75 o 0.85) hasta que te guste.
const ESCALA_JUGADOR := 0.8

var ficha: FichaArea
## Datos del mapa con arte (de DatosMapas). Vacío si esta área aún no tiene arte.
var datos_arte: Dictionary = {}
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


## Carga la ficha (Resource) del área que el jugador eligió en el selector
## y, si ese mapa ya tiene arte, sus datos.
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

	datos_arte = DatosMapas.MAPAS.get(nombre_archivo.get_basename(), {})
	if not datos_arte.is_empty() and not ResourceLoader.exists(datos_arte["imagen"]):
		push_warning("Falta la imagen del mapa: " + datos_arte["imagen"])
		datos_arte = {}


## Instancia el personaje elegido y configura su cámara para que siga
## al jugador sin salirse de los bordes del mundo.
func _instanciar_jugador() -> void:
	var escena_personaje: PackedScene = ESCENA_PERSONAJE_MASCULINO
	if GameState.personaje_elegido == "femenino":
		escena_personaje = ESCENA_PERSONAJE_FEMENINO

	jugador = escena_personaje.instantiate()
	if GameState.regreso_de_interior:
		# Viene de salir del edificio: aparece frente a la puerta.
		jugador.position = datos_arte.get("regreso", ficha.posicion_edificio + DESPLAZAMIENTO_REGRESO)
		GameState.regreso_de_interior = false
	else:
		jugador.position = datos_arte.get("inicio", ficha.posicion_jugador_inicial)
	add_child(jugador)
	_reducir_jugador()

	camara = jugador.get_node("Camera2D")
	camara.make_current()
	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = ANCHO_MUNDO
	camara.limit_bottom = ALTO_MUNDO


## Achica solo el dibujo y el cuadro de colisión del personaje (no el nodo entero,
## para no afectar a la cámara ni a la física). El dibujo y la colisión se achican juntos, así los pies siguen alineados.
func _reducir_jugador() -> void:
	var sprite: Sprite2D = jugador.get_node("Sprite2D")
	sprite.scale = Vector2.ONE * ESCALA_JUGADOR
	var colision: CollisionShape2D = jugador.get_node("CollisionShape2D")
	colision.scale = Vector2.ONE * ESCALA_JUGADOR
	colision.position *= ESCALA_JUGADOR


## Pinta el mundo con los datos de la ficha. Con arte: imagen, edificio dibujado,
## colisiones; sin arte: el bloque de color de siempre.
func _aplicar_ficha_al_mundo() -> void:
	# El nombre del edificio ya no se escribe sobre el mapa.
	etiqueta_edificio.visible = false
	if datos_arte.is_empty():
		fondo.color = ficha.color_zona
		edificio.position = ficha.posicion_edificio
		return
	_aplicar_arte()


func _aplicar_arte() -> void:
	# Imagen del mapa al fondo de todo.
	fondo.visible = false
	var arte := Sprite2D.new()
	arte.name = "FondoArte"
	arte.texture = load(datos_arte["imagen"])
	arte.centered = false
	add_child(arte)
	move_child(arte, 0)

	# El edificio ya está dibujado: solo queda la zona de entrada.
	edificio.position = datos_arte["edificio"]
	var visual_edificio := edificio.get_node_or_null("Visual")
	if visual_edificio != null:
		visual_edificio.visible = false

	# Colisiones del edificio y de los obstáculos del mapa.
	_crear_colision_poligono(datos_arte["huella"])
	for rect in datos_arte["obstaculos"]:
		_crear_colision_rect(rect)


func _crear_colision_rect(rect: Rect2) -> void:
	var cuerpo := StaticBody2D.new()
	var colision := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = rect.size
	colision.shape = forma
	cuerpo.position = rect.position + rect.size / 2.0
	cuerpo.add_child(colision)
	add_child(cuerpo)


func _crear_colision_poligono(puntos: Array) -> void:
	var cuerpo := StaticBody2D.new()
	var colision := CollisionPolygon2D.new()
	colision.polygon = PackedVector2Array(puntos)
	cuerpo.add_child(colision)
	add_child(cuerpo)


## Mientras el jugador esté en la zona de entrada, ENTER/Espacio
## (o el botón A del mando) lo manda al interior del edificio.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
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
