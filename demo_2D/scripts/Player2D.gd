extends CharacterBody2D

@export var movementSpeed := 1.5
@onready var sprite_2d: Sprite2D = $Sprite2D

func _process(_delta:float) -> void:
	var directionOfMovement := Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		directionOfMovement.x += 1
		sprite_2d.scale.x = 1
	if Input.is_action_pressed("move_left"):
		directionOfMovement.x -= 1
		sprite_2d.scale.x = -1
	if Input.is_action_pressed("move_up"):
		directionOfMovement.y -= 1
	if Input.is_action_pressed("move_down"):
		directionOfMovement.y += 1
	directionOfMovement = directionOfMovement.normalized()*movementSpeed
	move_and_collide(directionOfMovement)
