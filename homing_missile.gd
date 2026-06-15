extends Area2D

@export var explosion_scene : PackedScene

const MAX_SPEED = 1200.0
const DAMAGE_PER = 250
const RADIUS = 80.0
#const EXTRA_RADIUS_PER_LEVEL = 10.0
var speed = 0.0
var speed_mod = 600.0
var x_speed = 0.0
var y_speed = 0.0
var dead = false
var weapon_cooldown_start = 0.2
var weapon_cooldown = weapon_cooldown_start * 4
var shoot_randomizer = 0.03
var enemy:Node2D = null
var aim_to_process = false
var lerp_rotation = 12.0
var all_smoke_emitting = false
#var missile_level

func die():
	dead = true
	$CollisionShape2D.queue_free()
	$MissileSprite.queue_free()
	$FlameSprite.queue_free()
	$SmokeCloudParticles.emitting = false
	$SmokeCloudParticles2.emitting = false
	$SmokeCloudParticles3.emitting = false
	$SmokeCloudParticles4.emitting = false
	$SmokeCloudParticles5.emitting = false
	$SmokeTimer.stop()
	$SmokeTimer.queue_free()
	$QueueFreeTimer.start()
	
func _ready():
	$SmokeTimer.start()
	$MissileSprite.play()

func notify_target_null():
	enemy = null

func start(pos, rot:Vector2, start_speed, _level):
	position = pos
	rotation = rot.rotated(-PI/2).angle()
#	missile_level = level
	speed = start_speed
	x_speed =  rot.rotated(-PI/2).x * speed
	y_speed = rot.rotated(-PI/2).y * speed

func explode():
	var e = explosion_scene.instantiate()
	e.global_position = global_position
	e.set_radius_and_damage(RADIUS, DAMAGE_PER)
	get_tree().root.call_deferred("add_child", e)

func _physics_process(delta):
	if !dead:
		if enemy != null:
			if enemy.dead == false:
				rotation = lerp_angle(rotation, (enemy.global_position - global_position).normalized().angle(), lerp_rotation * delta)
	#		look_at(enemy.global_position)
		if abs(speed) < MAX_SPEED:
			speed += delta * speed_mod
		var dir = Vector2(cos(rotation), sin(rotation))
		x_speed = dir.x * speed
		y_speed = dir.y * speed
		position.x += x_speed * delta
		position.y += y_speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemies") || body.is_in_group("miniboss"):
		explode()
		die()
	elif body.is_in_group("Walls"):
		#should missiles blow up at walls?
		#explode()
		die()

func _on_heat_seeking_area_2d_body_entered(body):
	if enemy == null && body.is_in_group("trackable"):
		enemy = body
		body.set_targeting_node(self)

func _on_area_entered(area):
	if area.is_in_group("ram") or area.is_in_group("enemy_body") or area.is_in_group("hive") or area.is_in_group("forcefield"):
		explode()
		die()

func _on_heat_seeking_area_2d_area_entered(area):
	if enemy == null && area.is_in_group("trackable"):
		enemy = area.get_parent()
		area.get_parent().set_targeting_node(self)

func _on_smoke_timer_timeout():
	$SmokeTimer.stop()
	if !$SmokeCloudParticles2.emitting:
		$SmokeCloudParticles2.emitting = true
	elif !$SmokeCloudParticles3.emitting:
		$SmokeCloudParticles3.emitting = true
	elif !$SmokeCloudParticles4.emitting:
		$SmokeCloudParticles4.emitting = true
	elif !$SmokeCloudParticles5.emitting:
		$SmokeCloudParticles5.emitting = true
		all_smoke_emitting = true
	if !all_smoke_emitting:
		$SmokeTimer.start()

func _on_queue_free_timer_timeout():
	queue_free()
	
