extends Area2D
#@export var speed = 800 #changing per Davey's recomm
@export var speed = 560
var x_speed = 0
var y_speed = 0

func _on_body_entered(body):
	if body.is_in_group("player"):
		if !body.invincible:
			if is_in_group("blueguy_bullet"):
				body.set_killed_by(G.BLUE_GUY_BULLET)
			else:
				body.set_killed_by(G.SPINNER_BULLET)
			body.die()
		queue_free()
	elif body.is_in_group("Walls"):
		queue_free()
		
func start(pos, dir:Vector2):
	position = pos
	rotation = dir.rotated(PI/2).angle()
	x_speed = dir.x * speed
	y_speed = dir.y * speed
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x += x_speed * delta
	position.y += y_speed * delta
