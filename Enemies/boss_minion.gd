extends CharacterBody2D
class_name Minion

const LAUNCH_SPEED = 1400.0
const NORMAL_SPEED = 500.0
#const DISTANCE_TO_ENABLE_RETREAT = 300
const DISTANCE_TO_ENABLE_RETREAT = 500
#const WEAPON_COOLDOWN_SHORT = 0.27
const WEAPON_COOLDOWN_SHORT = 0.3
#const SHOT_RANDOMIZER_VALUE = 0.03
const WEAPON_COOLDOWN_LONG = WEAPON_COOLDOWN_SHORT * 3.0
const SHOT_RANDOMIZER_VALUE = 0.5
const NUM_BURST_SHOTS = 1
const INITIAL_CHASE_POS_Y_OFFSET = 250
const WOBBLE_RATE_SCALAR = 4.0
var hp = 50
var lerp_rotation = 100.0
var dead = false
var shoot_angle_window = PI/10.0
var max_ship_rotation = PI
var spawning = false
var spawn_time = 1
var shots_until_long_cooldown = NUM_BURST_SHOTS
var targeting_nodes = []
var chase_position
var can_shoot = false
var past_boss_mouth = false
var boss_mouth_y_pos = 0.0
var speed = 0.0
var boss
# x offset of where the minion aims, so they dont converge on one point.
var actual_target_position_x_offset = randi_range(-50,50)
var time_elapsed = 0.0
var rand_angle_offset:float
var rand_speed_modifier:float
var dummy_vector:Vector2
var level
# determines logic for if a non-boss vs spawning from a boss
var boss_spawn = true

@export var enemy_bullet_1_scene : PackedScene
@onready var PLAYER:PlayerShip = get_tree().get_first_node_in_group('player')
@onready var common = get_tree().get_first_node_in_group("enemy_shared")
	
func _ready():
	if !boss_spawn:
		spawning = true
		speed = 0.0
	else:
		speed = LAUNCH_SPEED
		$CollisionPolygon2D.disabled = false
		$Sprite2D.visible = true
		$ThrusterParticles.emitting = true
		$SpawnParticles.emitting = false
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	rand_angle_offset = randf_range(-PI/2, PI/2)
	rand_speed_modifier = randf_range(-NORMAL_SPEED*0.2,NORMAL_SPEED*0.2)
	dummy_vector = (Vector2.UP *10000).rotated(randf_range(-PI, PI))
	#save ref of retreat target before moving the node to the Level tree
#	thing_to_chase = $ThingToChase
	#store ship position for chasing
#	chase_position = get_parent().get_last_ship_pos()
#	chase_position.x += actual_target_position_x_offset
	chase_position = Vector2()
	chase_position.x = position.x
	chase_position.y = position.y + INITIAL_CHASE_POS_Y_OFFSET
	level = get_tree().get_first_node_in_group("level")
	common.play_spawn_sound_1()
	
	#make enemies spawn facing player
	look_at(chase_position)


func _physics_process(delta):	
	if !spawning:
		time_elapsed += delta
		if !dead:
			if past_boss_mouth:
				chase_position = level.get_last_ship_pos() if !PLAYER.dead else dummy_vector
				var direction_to_chase_position = self.global_position.direction_to(chase_position)
	#			var angle_diff_to_chase_position = get_angle_to(chase_position)
				velocity = direction_to_chase_position.rotated(0.8 * sin((time_elapsed + rand_angle_offset) * WOBBLE_RATE_SCALAR)) * (speed + rand_speed_modifier)
				var animation_angle_diff = velocity.angle() - rotation
				rotation = velocity.angle()

	#			if abs(angle_diff_to_chase_position) > max_ship_rotation * delta:
	#				if angle_diff_to_chase_position < 0:
	#					angle_diff_to_chase_position = -max_ship_rotation * delta
	#				else:
	#					angle_diff_to_chase_position = max_ship_rotation * delta
	#			rotation = lerp_angle(rotation, rotation + angle_diff_to_chase_position, lerp_rotation * delta)
	##			velocity = Vector2((SPEED + rand_speed_modifier),0).rotated(rotation)
	#			speed = lerpf(speed, (SPEED + rand_speed_modifier), delta * 10)
				
	#			print("angle_diff: ", animation_angle_diff)
				if abs(animation_angle_diff) > 0.018:
					if animation_angle_diff  < 0.0:
						$Sprite2D.frame = 0
	#					print("0")
					else:
						$Sprite2D.frame = 6
	#					print("6")
				elif abs(animation_angle_diff) > 0.012:
					if animation_angle_diff < 0.0:
						$Sprite2D.frame = 1
	#					print("1")
					else:
						$Sprite2D.frame = 5
	#					print("5")
				elif abs(animation_angle_diff) > 0.004:
					if animation_angle_diff < 0.0:
						$Sprite2D.frame = 2
	#					print("2")
					else:
						$Sprite2D.frame = 4
	#					print("4")
				else:
					$Sprite2D.frame = 3
	#				print("3")
			else:
				global_rotation = get_parent().global_rotation + PI/2.0
				var tween = create_tween()
				tween.tween_property(self, "speed", NORMAL_SPEED, 0.5).set_ease(Tween.EASE_IN)
				velocity = Vector2(speed,0).rotated(rotation)
		else:
			queue_free()
		
	#		move_and_slide()
		var collision = move_and_collide(velocity * delta)
		if collision:
			if collision.get_collider().is_in_group("player"):
				if collision.get_collider().invincible:
					die()
				else:
					take_damage(collision.get_collider().KAMIKAZI_DAMAGE)
					if boss_spawn:
						collision.get_collider().set_killed_by(G.BOSS_MINION_COLLISION)
					else:
						collision.get_collider().set_killed_by(G.MINION_COLLISION)
					collision.get_collider().die()
			else:
				move_and_slide()
	else:
		#spawning logic
		spawn_time -= delta
		if spawn_time < 0 && spawning:
			spawning = false
			var tween = create_tween()
			tween.tween_property(self, "speed", NORMAL_SPEED, 0.5).set_ease(Tween.EASE_IN)
			$CollisionPolygon2D.disabled = false
			$Sprite2D.visible = true
			$SpawnParticles.emitting = false
			$ThrusterParticles.emitting = true

func take_damage(damage = 50):
#	$Sprite2D.modulate = Color.RED
#	$DamageVisualRevertTimer.start()
	hp -= damage
	if hp <= 0:
		call_deferred('die')

#method for taking damage and possibly dying (bad name I suppose)
func die():
	if !dead:
		get_parent().child_died(self)
		#for heat seeking missiles
		if targeting_nodes.size() > 0:
			for target in targeting_nodes:
				if (is_instance_valid(target)):
					target.notify_target_null()
		$DamageVisualRevertTimer.stop()
	#	$DamageVisualRevertTimer.queue_free()
		$Sprite2D.visible = false
		$CollisionPolygon2D.set_deferred("disabled", true)
		$ThrusterParticles.emitting = false
		
		#reparent particles two nodes up
		var shatter_particles = $ShatterParticles
		shatter_particles.reparent(get_parent().get_parent())
		var explosion_particles = $EnemyExplosion
		explosion_particles.reparent(get_parent().get_parent())
		shatter_particles.emitting = true
		explosion_particles.emitting = true
		
	
		get_tree().get_first_node_in_group("enemy_shared").play_explode_sound_1()
		dead = true

#store a reference of a missile targeting enemy, for notifying that missile when we die, so it can track a new enemy
func set_targeting_node(t_node:Node2D):
	targeting_nodes.append(t_node)
	

func _on_damage_visual_revert_timer_timeout():
	$Sprite2D.modulate = Color.WHITE

func _on_weapon_cooldown_timeout():
	can_shoot = true
	
func make_non_boss_spawn():
	boss_spawn = false
	past_boss_mouth = true
	spawning = true
	$Sprite2D.hide()
	$ThrusterParticles.emitting = false

func past_mouth_true():
	past_boss_mouth = true
