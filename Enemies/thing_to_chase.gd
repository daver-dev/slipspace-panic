extends Area2D
const MAX_SPEED = 400
const MIN_SPEED = 300
var speed
var x_speed
var y_speed
var angle
var direction:Vector2

#func start(pos, dir:Vector2):
#	position = pos
#	rotation = dir.rotated(PI/2).angle()
#	x_speed = dir.x * speed
#	y_speed = dir.y * speed

func _ready():
	randomize_speed_and_direction()

func _on_change_speed_and_direction_timer_timeout():
	$ChangeSpeedAndDirectionTimer.stop()
	randomize_speed_and_direction()
	$ChangeSpeedAndDirectionTimer.start()

func randomize_speed_and_direction():
	angle = randf_range(0.0, 2 * PI)
	direction = Vector2(cos(angle), sin(angle))
	speed = randi_range(MIN_SPEED, MAX_SPEED)
	x_speed = direction.x * speed
	y_speed = direction.y * speed

func _on_body_entered(body):
	if body.is_in_group("Walls"):
		direction = direction.reflect(body.get_normal())
		x_speed = direction.x * speed
		y_speed = direction.y * speed

func _physics_process(delta):
	position.x += x_speed * delta
	position.y += y_speed * delta
