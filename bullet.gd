extends Area2D
@export var speed = 2000
const DAMAGE = 50
var x_speed = 0
var y_speed = 0

func start(pos, dir:Vector2):
	position = pos
	rotation = dir.rotated(PI/2).angle()
	x_speed = dir.x * speed
	y_speed = dir.y * speed

func _physics_process(delta):
	position.x += x_speed * delta
	position.y += y_speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemies") || body.is_in_group("miniboss"):
		queue_free()
		body.take_damage(DAMAGE)
	elif body.is_in_group("Walls"):
#		get_tree().get_first_node_in_group("level")
		queue_free()
	elif body.is_in_group("ram"):
		get_tree().get_first_node_in_group("enemy_shared").play_ping_sound()
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("enemy_body"):
		area.get_parent().take_damage(DAMAGE)
		queue_free()
	elif area.is_in_group("hive"):
		area.take_damage(DAMAGE)
		queue_free()
