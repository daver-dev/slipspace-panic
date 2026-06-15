extends Node2D
const DAMAGE = 50
#const VERTICAL_RANGE = 200
#const HORIZONTAL_RANGE = 400
const ROTATION_SPEED = 25
const INCLUDE_SHIP_VELOCITY := true #true prevents compression in one direction and stretching in the other from ship movement
const Y_SPEED := 2000.0 #pixels per second (i think) to move away from ship
const CYCLING_SPEED_MODIFIER := 9.0 # multiplied by elapsed delta to speed up cycles per second
const AMPLITUDE := 200.0 #pixels above and below centerline for helix
var x_speed = 0
var y_speed = 0
var start_pos:Vector2
var aim_dir:float
var delta_elapsed = 0.0
var is_left_cres
var rot_speed
var start_vel = Vector2()


func start(pos:Vector2, dir:Vector2, is_left:bool, x_vel:float, y_vel:float):
	position = pos
	start_pos = pos #since using an equation to determine distance from time, need to retain origin
	start_vel.x = x_vel #these allow use to maintain the same shape of bullet spread regardless of
	start_vel.y = y_vel #player speed (bullet gets ship velocity at time of instantiation)
	aim_dir = dir.rotated(PI/2).angle()
	is_left_cres = is_left #alternate left/right
	var neg = 1 if is_left_cres else -1 #use to make negative from bool
	rot_speed = neg * ROTATION_SPEED #alternate rotation dir of crescent
	$Area2D/Sprite2D.flip_h = is_left #maybe have sprite that is shaped different at one end?

func _physics_process(delta):
	delta_elapsed += delta
#	var y_modifier = VERTICAL_RANGE * (1 - 5 * pow((delta_elapsed - .4472), 2)) #https://www.desmos.com/calculator: 1. 1-5\left(x-.4472\right)^{2}
#	var x_modifier = HORIZONTAL_RANGE * sin(2*delta_elapsed) #https://www.desmos.com/calculator: 2. \sin\left(2x\right)
	var y_modifier = -delta_elapsed * Y_SPEED
	var x_modifier = sin(delta_elapsed * CYCLING_SPEED_MODIFIER) * AMPLITUDE
	if is_left_cres:
		x_modifier *= -1
	var pos_mod = Vector2(x_modifier, y_modifier)
	start_pos += start_vel * delta
	position = start_pos + pos_mod.rotated(aim_dir)
	
	if INCLUDE_SHIP_VELOCITY:
		rotation += rot_speed * delta


func _on_area_2d_area_entered(area):
	if area.is_in_group("enemy_body"):
		area.get_parent().take_damage(DAMAGE)
		queue_free()
	elif area.is_in_group("hive"):
		area.take_damage(DAMAGE)
		queue_free()

func _on_area_2d_body_entered(body):
	if body.is_in_group("enemies") || body.is_in_group("miniboss"):
		queue_free()
		body.take_damage(DAMAGE)
	elif body.is_in_group("Walls"):
		queue_free()
	elif body.is_in_group("ram"):
		get_tree().get_first_node_in_group("enemy_shared").play_ping_sound()
		queue_free()
