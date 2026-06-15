extends CharacterBody2D

const MAX_SPEED = 3200.0
const ACCEL_FACTOR = 4000
const MAX_THRUSTER_VOLUME = -4.0
const MIN_THRUSTER_VOLUME = -14.0
const ANIMATION_STEP_PER_FRAME := 0.15
const ROTATION_LERP_WEIGHT := 100.0
const CHARGING_ROTATE_DIVISOR := 12.0
const CHARGING_ROTATION_LERP_WEIGHT := 7.0 #speed to get up to full rotation allowed per frame (MAX_CHARGING_ROTATION)
const MAX_CHARGING_ROTATION := 0.1 #functions much like a limit on how far it can turn the steering wheel per say

var hp = 150
var speed = 0.0
var dead = false
var max_ship_rotation = PI/1.7
var can_rotate = true
var spawning = true
var spawn_time = 0.5
var targeting_nodes = []
var charging = false
var raw_angle_diff
var camera
var collision_imminent = false
var bounce_back_speed_tween:Tween
@onready var common = get_tree().get_first_node_in_group("enemy_shared")
@onready var float_ani_frame:float = $BodySprite2D.frame

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	camera = get_tree().get_first_node_in_group("camera")
#	var player_position = get_parent().get_last_ship_pos()
#	rotation = randf_range(0.0, 2 * PI)
	look_at(get_parent().get_parent().get_last_ship_pos())
	$ThrusterSound.volume_db = MIN_THRUSTER_VOLUME
	rotation = fmod(rotation, 2 * PI)
	raw_angle_diff = 0.0
	common.play_spawn_sound_2()
	
	
func take_damage(damage):
	$BodySprite2D.modulate = Color.RED
	$DamageVisualRevertTimer.start()
	hp -= damage
	if hp <= 0:
		die()
	else:
		common.play_damage_sound()
	
func die():
	if !dead:
		get_parent().child_died(self)
		common.play_explode_sound_3()
		if targeting_nodes.size() > 0:
			for target in targeting_nodes:
				if (is_instance_valid(target)):
					target.notify_target_null()
		$DamageVisualRevertTimer.stop()
		$CollisionPolygon2D.set_deferred("disabled", true)
		$BodyArea2D/BodyCollisionShape2D.set_deferred("disabled", true)
		$ThrusterParticlesMain.emitting = false
		
		#reparent particles two nodes up
		var shatter_particles = $ShatterParticles
		shatter_particles.reparent(get_parent().get_parent())
		var explosion_particles = $EnemyExplosion
		explosion_particles.reparent(get_parent().get_parent())
		shatter_particles.emitting = true
		explosion_particles.emitting = true
		
		
		$ThrusterSound.playing = false
		dead = true

func _on_damage_visual_revert_timer_timeout():
	$BodySprite2D.modulate = Color.WHITE

func _on_body_area_2d_body_entered(body):
	if body.is_in_group("player"):
		if !body.invincible:
			take_damage(body.KAMIKAZI_DAMAGE)
			body.set_killed_by(G.RAMMER_COLLISION)
			body.die()

func set_targeting_node(t_node:Node2D):
	targeting_nodes.append(t_node)

func start_charge():
	if !charging:
		$ThrusterParticlesMain.emitting = true
		can_rotate = false
		common.play_spawn_sound_4()
		charging = true	
	
func handle_wall_hit():
	camera.screen_shake_rough(10)
	$WallThud.play()
	if bounce_back_speed_tween:
		bounce_back_speed_tween.kill()
	speed = -speed/4.0
	bounce_back_speed_tween = create_tween()
	bounce_back_speed_tween.tween_property(self, "speed", 0.0, 1.2).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT).connect("finished", done_bouncing)
	can_rotate = false
	charging = false
	$BodySprite2D.frame = 4
	$RammerSprite2D.frame = 4
	
func done_bouncing():
	can_rotate = true
	
func _physics_process(delta):
	rotation = fmod(rotation, 2 * PI)
	if !spawning:
		if !dead and get_tree().get_first_node_in_group("player").is_alive == true:
			var player_position = get_parent().get_parent().get_last_ship_pos()
			var angle_diff_to_player = get_angle_to(player_position)
			raw_angle_diff = angle_diff_to_player
			if abs(angle_diff_to_player) < 0.01:
				$ThrusterParticlesLeft.emitting = false
				$ThrusterParticlesRight.emitting = false
				$ThrusterParticlesMain.emitting = true
				can_rotate = false
				start_charge()
			elif angle_diff_to_player < -0.0 and can_rotate:
				if angle_diff_to_player < -(max_ship_rotation * delta):
					angle_diff_to_player = -(max_ship_rotation * delta)
				angle_diff_to_player = -max_ship_rotation * delta
				$ThrusterParticlesLeft.emitting = true
				$ThrusterParticlesRight.emitting = false
				$ThrusterParticlesMain.emitting = false
				rotation = lerp_angle(rotation, rotation + angle_diff_to_player, ROTATION_LERP_WEIGHT * delta)
			elif angle_diff_to_player > 0.0 and can_rotate:
				if angle_diff_to_player > max_ship_rotation * delta:
					angle_diff_to_player = max_ship_rotation * delta
				$ThrusterParticlesLeft.emitting = false
				$ThrusterParticlesRight.emitting = true
				$ThrusterParticlesMain.emitting = false
#				prev_rotation = rotation
				rotation = lerp_angle(rotation, rotation + angle_diff_to_player, ROTATION_LERP_WEIGHT * delta)
#			velocity = Vector2(SPEED,0).rotated(rotation)
#			if !can_rotate:
#			var prev_ani_frame = $BodySprite2D.frame
			if charging:
				#CHARGE ROTATION
				rotation = lerp_angle(rotation, rotation + clampf(angle_diff_to_player, -MAX_CHARGING_ROTATION, MAX_CHARGING_ROTATION), CHARGING_ROTATION_LERP_WEIGHT * delta)
				speed += delta * ACCEL_FACTOR
				if speed > MAX_SPEED:
					speed = MAX_SPEED
				$ThrusterSound.volume_db = MAX_THRUSTER_VOLUME
#				$BodySprite2D.frame = 4
#				$RammerSprite2D.frame = 4
				float_ani_frame = move_toward(float_ani_frame, 4.0, ANIMATION_STEP_PER_FRAME)
			elif can_rotate:
				$ThrusterSound.volume_db = MIN_THRUSTER_VOLUME
				#choose animation frame
				if abs(raw_angle_diff) > 0.15:
					if raw_angle_diff < 0.0:
#						$BodySprite2D.frame = 0
#						$RammerSprite2D.frame = 0
						float_ani_frame = move_toward(float_ani_frame, 0.0, ANIMATION_STEP_PER_FRAME)
					else:
#						$BodySprite2D.frame = 8
#						$RammerSprite2D.frame = 8
						float_ani_frame = move_toward(float_ani_frame, 8.0, ANIMATION_STEP_PER_FRAME)
				elif abs(raw_angle_diff) > 0.1:
					if raw_angle_diff < 0.0:
#						$BodySprite2D.frame = 1
#						$RammerSprite2D.frame = 1
						float_ani_frame = move_toward(float_ani_frame, 1.0, ANIMATION_STEP_PER_FRAME)
					else:
#						$BodySprite2D.frame = 7
#						$RammerSprite2D.frame = 7
						float_ani_frame = move_toward(float_ani_frame, 7.0, ANIMATION_STEP_PER_FRAME)
				elif abs(raw_angle_diff) > 0.08:
					if raw_angle_diff < 0.0:
#						$BodySprite2D.frame = 2
#						$RammerSprite2D.frame = 2
						float_ani_frame = move_toward(float_ani_frame, 2.0, ANIMATION_STEP_PER_FRAME)
					else:
#						$BodySprite2D.frame = 6
#						$RammerSprite2D.frame = 6
						float_ani_frame = move_toward(float_ani_frame, 6.0, ANIMATION_STEP_PER_FRAME)
				elif abs(raw_angle_diff) > 0.05:
					if raw_angle_diff < 0.0:
#						$BodySprite2D.frame = 3
#						$RammerSprite2D.frame = 3
						float_ani_frame = move_toward(float_ani_frame, 3.0, ANIMATION_STEP_PER_FRAME)
					else:
#						$BodySprite2D.frame = 5
#						$RammerSprite2D.frame = 5
						float_ani_frame = move_toward(float_ani_frame, 5.0, ANIMATION_STEP_PER_FRAME)
				else:
#					$BodySprite2D.frame = 4
#					$RammerSprite2D.frame = 4
					float_ani_frame = move_toward(float_ani_frame, 4.0, ANIMATION_STEP_PER_FRAME)
			$BodySprite2D.frame = int(float_ani_frame)
			$RammerSprite2D.frame = int(float_ani_frame)
#			print("last frame:", prev_ani_frame, ", this frame:", $BodySprite2D.frame)
#			assert($BodySprite2D.frame == prev_ani_frame || $BodySprite2D.frame == prev_ani_frame -1 || $BodySprite2D.frame == prev_ani_frame +1)
		
		else:
			$ThrusterParticlesLeft.emitting = false
			$ThrusterParticlesRight.emitting = false

		if dead:
			queue_free()
#			if !$ShatterParticles.emitting and !$EnemyExplosion.emitting:
#				queue_free()
		$ThrusterSound.pitch_scale = 1.5 + (speed / MAX_SPEED) * 3
		velocity = Vector2(speed,0).rotated(rotation)
		
	else:
		spawn_time -= delta
		if spawn_time < 0:
			spawning = false
			start_charge()
			$CollisionPolygon2D.disabled = false
			$WallDetectArea2D/CollisionShape2D.disabled = false
			$BodyArea2D/BodyCollisionShape2D.disabled = false
			$BodySprite2D.visible = true
			$RammerSprite2D.visible = true
			$SpawnParticles.emitting = false
	

	var collision = move_and_collide(velocity * delta)
	if collision:
		if collision.get_collider().is_in_group("player"):
#			collision.get_collider().die()
			if !collision.get_collider().invincible:
				collision.get_collider().set_killed_by(G.RAMMER_COLLISION)
				collision.get_collider().die()
			else:
				die()
		elif collision.get_collider().is_in_group("Walls"):
			if collision_imminent:
				handle_wall_hit()
				collision_imminent = false
			else:
				move_and_slide()

# Disconnected
#func _on_ram_area_2d_body_entered(body):
#	if body.is_in_group("player"):
#		if !body.get_collider().invincible:
#				body.get_collider().die()
#		else:
#			die()


func _on_wall_detect_area_2d_body_entered(_body):
	if charging: #is charging
		collision_imminent = true
