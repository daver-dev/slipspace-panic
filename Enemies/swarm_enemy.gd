extends CharacterBody2D

#const MAX_SPEED = 1200.0
#const ACCEL_FACTOR = 800
#const SLOWDOWN_FACTOR = 0.8
#const LERP_ROTATION =0.6
#const THRUST_ANGLE_WINDOW = PI/10.0
const MAX_SPEED = 1000.0
const ACCEL_FACTOR = 1200
const SLOWDOWN_FACTOR = 2.0
const LERP_ROTATION =0.8
const THRUST_ANGLE_WINDOW = PI/10.0
var speed = 0.0
var hp = 150
var dead = false
var max_ship_rotation = PI*1.6
var spawning = true
var spawn_time = 0.5
var targeting_nodes = []
var chase_position
var enemy_shared
var last_child_pos : Vector2
var children = []

func _ready():
	#for non-gravity games (I think)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	#store ship position for chasing
	chase_position = get_parent().get_parent().get_last_ship_pos()
	#make enemies spawn facing player
	look_at(chase_position)
	enemy_shared = get_tree().get_first_node_in_group("enemy_shared")
	var ship = get_tree().get_first_node_in_group("player")
	for node in $ChildrenHolder.get_children():
		children.append(node)
		node.hive_mother = self
		node.player_ship = ship
	enemy_shared.play_spawn_sound_3()

func get_last_ship_pos():
	return get_parent().get_last_ship_pos()

#store a reference of a missile targeting enemy, for notifying that missile when we die, so it can track a new enemy
func set_targeting_node(t_node:Node2D):
	targeting_nodes.append(t_node)

func die():
	if !dead:
		get_parent().child_died(self)
		dead = true
		global_position = last_child_pos
		if targeting_nodes.size() > 0:
			for target in targeting_nodes:
				if (is_instance_valid(target)):
					target.notify_target_null()

func _physics_process(delta):
	if !spawning:
		if !dead:
			if children.size() == 1:
				last_child_pos = children[0].global_position
			if children.is_empty():
				die()
			else:
				chase_position = get_parent().get_parent().get_last_ship_pos()
				var chase_rotation = get_angle_to(chase_position)
				if abs(chase_rotation) > max_ship_rotation * delta:
					if chase_rotation < 0:
						chase_rotation = -max_ship_rotation * delta
					else:
						chase_rotation = max_ship_rotation * delta
				#using this to make enemy turn slower when going faster
				var speed_to_max_diff_ratio = 1 - (speed / MAX_SPEED)
				rotation = lerp_angle(rotation, rotation + (speed_to_max_diff_ratio * chase_rotation), LERP_ROTATION)
				chase_rotation = get_angle_to(chase_position)
				#apply thrust if facing enemy within margin, else slow down
				if chase_rotation > 0:
					if chase_rotation < THRUST_ANGLE_WINDOW:
						speed += ACCEL_FACTOR * delta
						if speed > MAX_SPEED:
							speed = MAX_SPEED
	#							velocity = Vector2(speed,0).rotated(rotation)
					else:
						speed = lerpf(speed, 0, delta * SLOWDOWN_FACTOR)
	#							velocity = Vector2(speed,0).rotated(rotation)
				else:
					if chase_rotation > -THRUST_ANGLE_WINDOW:
						speed += ACCEL_FACTOR * delta
						if speed > MAX_SPEED:
							speed = MAX_SPEED
	#							velocity = Vector2(speed,0).rotated(rotation)
					else:
						
						speed = lerpf(speed, 0, delta * SLOWDOWN_FACTOR)
	#							velocity = Vector2(speed,0).rotated(rotation)
			
				velocity = Vector2(speed,0).rotated(rotation)
	#			Have to have collision checking from both enemy and ship side because enemy colliding with ship wasn't triggering ship collision code
	#			move_and_slide()
				var collision = move_and_collide(velocity * delta)
				if collision:
					if collision.get_collider().is_in_group("Walls"):
						var move = Vector2.RIGHT.rotated(rotation)
						if collision.get_collider().is_in_group("HorizontalWalls"):
							velocity.x = move.x * speed
							velocity.y = 0
							move_and_slide()
						else:
							velocity.y = move.y * speed
							velocity.x = 0
							move_and_slide()
					else:
						move_and_slide()
		else:
			if $Timer.is_stopped():
				$Timer.start()
	else:
		#spawning logic
		spawn_time -= delta
		if spawn_time < 0:
			spawning = false
			$CollisionShape2D.disabled = false
#			$Sprite2D.visible = true
			$SpawnParticles.emitting = false

func _on_timer_timeout():
	queue_free()
