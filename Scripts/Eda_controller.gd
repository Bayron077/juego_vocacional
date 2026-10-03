extends CharacterBody2D

@export var speed = 100
var moveDirection = Vector2.ZERO
var lastDirection = Vector2.DOWN

@onready var animationTree = $AnimationTree

func _ready():
	animationTree.active = true
	animationTree["parameters/walking/blend_position"] = lastDirection

func validateInput():
	moveDirection = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = moveDirection * speed

func animatePLayer():
	# Solo se actualiza la dirección si hay movimiento, nunca se envía (0, 0)
	if moveDirection != Vector2.ZERO:
		if abs(moveDirection.x) > abs(moveDirection.y):
			lastDirection = Vector2(signf(moveDirection.x), 0.0)
		else:
			lastDirection = Vector2(0.0, signf(moveDirection.y))
		animationTree["parameters/walking/blend_position"] = lastDirection

func _physics_process(delta):
	validateInput()
	animatePLayer()
	move_and_slide()
