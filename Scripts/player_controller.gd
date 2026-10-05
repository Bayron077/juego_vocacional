extends CharacterBody2D

@export var speed = 100
var moveDirection = Vector2.ZERO
var lastDirection = Vector2.DOWN

## Cuadro de reposo de cada dirección (primer cuadro de cada fila de la hoja).
const FRAME_QUIETO := {
	Vector2.DOWN: 0,
	Vector2.UP: 9,
	Vector2.LEFT: 18,
	Vector2.RIGHT: 27,
}

@onready var animationTree = $AnimationTree

func _ready():
	animationTree.active = true
	animationTree["parameters/walking/blend_position"] = lastDirection

func validateInput():
	moveDirection = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = moveDirection * speed

func animatePLayer():
	if moveDirection != Vector2.ZERO:
		# Solo se actualiza la dirección si hay movimiento, nunca se envía (0, 0)
		if abs(moveDirection.x) > abs(moveDirection.y):
			lastDirection = Vector2(signf(moveDirection.x), 0.0)
		else:
			lastDirection = Vector2(0.0, signf(moveDirection.y))
		animationTree["parameters/walking/blend_position"] = lastDirection
		animationTree.active = true
	else:
		# Quieto: se detiene la animación y se muestra el cuadro de reposo
		animationTree.active = false
		$Sprite2D.frame = FRAME_QUIETO.get(lastDirection, 0)

func _physics_process(_delta):
	validateInput()
	animatePLayer()
	move_and_slide()
