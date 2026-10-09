extends CharacterBody2D

@export var speed = 100

## Zona muerta del stick: por debajo de este valor se ignora (evita temblor y drift).
const ZONA_MUERTA := 0.6

## Cuánto debe dominar un eje sobre el otro para que el personaje cambie
## hacia dónde mira. Evita el parpadeo al caminar en diagonal con el stick.
const FACTOR_CAMBIO_EJE := 1.5

## Cuadro de reposo de cada dirección (primer cuadro de cada fila de la hoja).
const FRAME_QUIETO := {
	Vector2.DOWN: 0,
	Vector2.UP: 9,
	Vector2.LEFT: 18,
	Vector2.RIGHT: 27,
}

var moveDirection = Vector2.ZERO
var lastDirection = Vector2.DOWN

@onready var animationTree = $AnimationTree


func _ready():
	animationTree.active = true
	animationTree["parameters/walking/blend_position"] = lastDirection


func validateInput():
	moveDirection = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down", ZONA_MUERTA)
	# Velocidad constante: no importa cuánto se incline el stick, camina igual
	# que con la cruceta, para que el desplazamiento coincida con la animación.
	if moveDirection != Vector2.ZERO:
		moveDirection = moveDirection.normalized()
	velocity = moveDirection * speed


func actualizarDireccion():
	var ax = absf(moveDirection.x)
	var ay = absf(moveDirection.y)
	var mira_horizontal = lastDirection.x != 0.0

	# Solo se cambia de eje si el otro domina con claridad.
	if mira_horizontal and ay > ax * FACTOR_CAMBIO_EJE:
		mira_horizontal = false
	elif not mira_horizontal and ax > ay * FACTOR_CAMBIO_EJE:
		mira_horizontal = true

	if mira_horizontal:
		lastDirection = Vector2(signf(moveDirection.x), 0.0)
	else:
		lastDirection = Vector2(0.0, signf(moveDirection.y))


func animatePLayer():
	if moveDirection != Vector2.ZERO:
		# Solo se actualiza la dirección si hay movimiento, nunca se envía (0, 0)
		actualizarDireccion()
		animationTree["parameters/walking/blend_position"] = lastDirection
		animationTree.active = true
	else:
		# Quieto: se detiene la animación y se muestra el cuadro de reposo
		animationTree.active = false
		$Sprite2D.frame = FRAME_QUIETO.get(lastDirection, 0)


func _physics_process(delta):
	validateInput()
	animatePLayer()
	move_and_slide()
	# Sonido de pasos: solo suena mientras el personaje realmente se mueve.
	Audio.pasos(get_real_velocity().length() > 5.0, delta)
