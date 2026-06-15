extends CharacterBody2D

const TURN_STRENGTH = 7.0
const SPEED = 80000.0
const TURN_TOLERANCE_TO_STOP = 0.001
const PIXELS_FROM_WALL_TO_SWITCH_VERTICAL_DIRECTION = 240
var current_turn = 0.0
var direction:Vector2 = Vector2.RIGHT
var future_direction:Vector2
var future_rotation
var started = false
var turning = false
var going_up = false
var horizontal_walls = []

func _ready():
	horizontal_walls = get_tree().get_nodes_in_group("HorizontalWalls")

func _physics_process(delta):
	if started:
		if turning:
			var prev_rotation = rotation
			if !going_up:
				var amount_to_rotate = abs(lerpf(rotation, future_rotation, TURN_STRENGTH * delta)) - abs(rotation)
				rotate(amount_to_rotate)
				direction = direction.rotated(amount_to_rotate)
				if abs(amount_to_rotate) < TURN_TOLERANCE_TO_STOP:
					rotation = future_rotation
					direction = future_direction
					turning = false
			else:
#				print("global_rotation:")
				print(global_rotation)
#				print("rotation:")
				print(rotation)
#				print("future_rotation:")
				print(future_rotation)
				var amount_to_rotate = lerpf(rotation, -future_rotation, TURN_STRENGTH * delta) - rotation
#				var amount_to_rotate = abs(lerpf(rotation, future_rotation, TURN_STRENGTH * delta)) - abs(rotation)
#				print("amount_to_rotate")
				print(amount_to_rotate)
				rotate(amount_to_rotate)
#				print("rotation after rotate:")
				print(rotation)
#				print("direction before rotation")
				print(direction.angle())
				direction = direction.rotated(amount_to_rotate)
#				print("direction after rotation")
				print(direction.angle())
				if abs(amount_to_rotate) < TURN_TOLERANCE_TO_STOP:
					rotation = future_rotation
					direction = future_direction
					turning = false
#					print("STOPPING TURNING")
		velocity.x = direction.x * SPEED * delta
		velocity.y = direction.y * SPEED * delta
	move_and_slide()

func turn_around():
#	print("*********************WALL COLLISION*********************")
	future_direction = direction.rotated(PI)
	future_rotation = rotation + PI
	turning = true
	for wall in horizontal_walls:
		if abs(global_position.y - wall.global_position.y) < PIXELS_FROM_WALL_TO_SWITCH_VERTICAL_DIRECTION:
			going_up = !going_up

func _on_timer_timeout():
	started = true
	$"../TurnToggleTimer".start()

func _on_turn_toggle_timer_timeout():
	if current_turn > 0.0:
		current_turn = 0.0
	else:
		current_turn = TURN_STRENGTH

func _on_area_2d_body_entered(body):
	if body.is_in_group("Walls") and !turning:
		turn_around()
