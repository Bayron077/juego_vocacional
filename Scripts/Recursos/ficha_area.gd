class_name FichaArea
extends Resource

## Nombre del área que aparece en el selector.
@export var nombre_area: String = ""

## Nombre del edificio que representa el área dentro del mapa.
@export var nombre_edificio: String = "Edificio"

## Color de fondo de la zona, para diferenciar cada área mientras no hay arte.
@export var color_zona: Color = Color(0.5, 0.5, 0.5, 1)

## Dónde aparece el jugador al entrar al mapa de esta área.
@export var posicion_jugador_inicial: Vector2 = Vector2(320, 260)

## Dónde se dibuja el edificio (y su zona de entrada) dentro del mapa.
@export var posicion_edificio: Vector2 = Vector2(450, 150)

# --- Reto ---

## SECUENCIA: repetir flechas con la cruceta.
## TIMING: detener la barra en la zona verde.
## SECUENCIA_BOTONES: repetir con los botones del mando (Y, A, X, B).
## (Los valores nuevos siempre van al final para no cambiar los ya guardados.)
enum TipoReto { SECUENCIA, TIMING, SECUENCIA_BOTONES }

@export_group("Reto")
@export var tipo_reto: TipoReto = TipoReto.SECUENCIA
@export var titulo_reto: String = "Reto del área"
@export_multiline var texto_reto: String = "Supera el reto para ganar el sello de esta área."

## Arte opcional. Si un campo está vacío, el reto usa bloques de color.
@export_group("Arte del reto (opcional)")
@export var color_acento_reto: Color = Color(1.0, 0.85, 0.25)
@export var fondo_reto: Texture2D
@export var icono_arriba: Texture2D
@export var icono_abajo: Texture2D
@export var icono_izquierda: Texture2D
@export var icono_derecha: Texture2D
@export var textura_pista: Texture2D
@export var textura_zona: Texture2D
@export var textura_marcador: Texture2D
