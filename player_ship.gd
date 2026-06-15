extends CharacterBody2D
class_name PlayerShip

@export var bullet_scene : PackedScene
@export var crescent_bullet_scene: PackedScene
@export var homing_missile_scene : PackedScene
@export var god_mode : bool

const CREDITS_SHIFT := Vector2(-400.0, 40.0)
const END_CREDITS_SHIFT := Vector2(0, -1200.0)
const START_SPEED = 550.0
#const SPEED_PER_LEVEL = 40
#const MAX_SPEED_LEVEL = 10
const MAX_THRUSTER_VOLUME = -8.0
const MAX_THRUSTER_VOLUME_BOOSTED = -0.0
const ZERO_THRUSTER_VOLUME = -80.0
const MIN_THRUSTER_VOLUME = -30.0
const DIFF_THRUSTER_VOLUME = absf(MIN_THRUSTER_VOLUME - MAX_THRUSTER_VOLUME)
const THROTTLE_PARTICLES_PER_LEVEL = 5
const THROTTLE_PARTICLES_LIFETIME_PER_LEVEL = 0.01
const BULLET_ROTATION = PI/100.0
const TURBO_COOLDOWN = 0.05
const THRUSTER_PITCH_NORMAL = 1.0
const THRUSTER_PITCH_BOOSTED_MAX = 3.3
const BOOST_MODIFIER = 2.5
const POST_BOOST_GRACE_PERIOD = 0.35
const KAMIKAZI_DAMAGE = 50
const MAX_GUN_LEVEL = 5
const HOMING_COOLDOWN_PER_LEVEL = 0.15
const MAX_HOMING_LEVEL = 4
const MAX_SHIELD_LEVEL = 10
const START_GUN_COOLDOWN = 0.2
const HIVE_SLOWDOWN_PER = 0.85
const SHIELD_DAMAGE_PER_LEVEL = 150
const STUN_DURATION = 0.8
const STUN_START_SPEED = -200
const KNOCKBACK_DISTANCE = 50
const HOMING_BURST_INTERVAL = 0.2
const CRESCENT_INTERVAL := 0.05
const DEFAULT_SPEED_LEAD_LENGTH_SCALE := 0.05
const SHIELD_FULL_ALPHA := 0.51372549
const SHIELD_PARTICLE_VELOCITY := 212.64
const SPINNER_BASH_DAMAGE_MULT := 10.0
const CREDS_VELOCITY_MIN := 50.0
const CREDS_VELOCITY_MAX := 420.0

var speed = START_SPEED
# use this to know what to move speed value back to after boost is over
var unboosted_speed = speed
var throttle_particles = 20
var cooldown = START_GUN_COOLDOWN
#var cooldown = TURBO_COOLDOWN
var curr_bullet_scene
var can_shoot = true
var can_homing_missile = true
var lerp_rotation = 12.0
var dead = false
var gun_level = 1
var speed_level = 0
var homing_level = 0
var remaining_homing_in_burst = homing_level
var shield_level = 1
var on_left_homing_missile = true
var controls_enabled = false
var is_alive = true
var paused = false
var prev_rotation = 0
var num_boosts = 0
var boosting = false
var invincible = false
var boost_shield_particle_speed = 0
var boost_particle_alpha = 0
var level
var miniboss_colliding_with_1
var miniboss_colliding_with_2
var boss_colliding_with_1
var boss_colliding_with_2
var shield_damage_cooling
#var enemies_area_currently_shield_bashing = []
var common
var boss
var camera
var lightning_jitter_tween:Tween
var being_shocked
var invert_material: ShaderMaterial
var on_left_cres = true if randi_range(0,1) == 1 else false
var can_crescent = true
var ship
var last_move:Vector2
var winding_down_controls = false
var last_aim_normal:Vector2
#var credits_triggered = false
#var credits_playing = false
var move
var aim
var prev_position:Vector2
var actual_speed:= 0.0
var killed_by := 0

@export var cooldown_per_level:float
@export var delay_for_death_music:float

@onready var shift_assets = [$Ship, $LeftJetExhaust, $RightJetExhaust, $BoostRamNode2D]

signal I_DIED

func _ready():
	prev_position = global_position
	#for non-gravity games (I think)
	last_aim_normal = Vector2()
	ship = $Ship
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	level = get_tree().get_first_node_in_group("level")
	camera = get_tree().get_first_node_in_group("camera")
	common = get_tree().get_first_node_in_group("enemy_shared")
	$PostBoostGracePeriod.wait_time = POST_BOOST_GRACE_PERIOD
	boost_shield_particle_speed = SHIELD_PARTICLE_VELOCITY
	boost_particle_alpha = SHIELD_FULL_ALPHA
	$BoostRamNode2D/RamAreaParticles2D.process_material.color.a = 0
	$BoostRamNode2D/SpeedLinesParticles.process_material.color.a = 0
	$BoostRamNode2D/SpeedLinesParticles2.process_material.color.a = 0
	curr_bullet_scene = bullet_scene
	$GunCooldown.wait_time = cooldown
	$GunCooldown.start()
	$ThrusterSound.volume_db = MIN_THRUSTER_VOLUME
	$LeftJetExhaust.amount = throttle_particles
	$RightJetExhaust.amount = throttle_particles
	miniboss_colliding_with_1 = null
	miniboss_colliding_with_2 = null
	boss_colliding_with_1 = null
	boss_colliding_with_2 = null
	shield_damage_cooling = false
	being_shocked = false
	# Create and store the shader material
	invert_material = ShaderMaterial.new()
	var shader = load("res://player_ship.gdshader")
	invert_material.shader = shader
	$CrescentCooldown1.wait_time = CRESCENT_INTERVAL

func set_killed_by(by:int):
	if killed_by == 0:
		killed_by = by

func get_speed_lead_target_position(_origin_position:Vector2, _length_mod:float = DEFAULT_SPEED_LEAD_LENGTH_SCALE):
#	actual_speed = prev_position.distance_to(global_position)
	return global_position + (Vector2.UP.rotated(rotation) * actual_speed)

#func _unhandled_input(event):
#	if event is InputEventKey:
#		if event.pressed and event.keycode == KEY_G:
#			upgrade_gun()
#		if event.pressed and event.keycode == KEY_M:
#			upgrade_homing()
			
func stop_thrusters():
	$LeftJetExhaust.emitting=false
	$RightJetExhaust.emitting=false
			
func wind_down_controls():
	if $LeftJetExhaust.emitting:
		winding_down_controls = true
		get_tree().create_tween().tween_property($ThrusterSound, "volume_db", ZERO_THRUSTER_VOLUME, 5.0)
		get_tree().create_tween().tween_property($ThrusterSound, "pitch_scale", THRUSTER_PITCH_NORMAL, 2.0).connect("finished", stop_thrusters)
		get_tree().create_tween().tween_property(self, "velocity", Vector2(), 2.0).connect("finished", func(): winding_down_controls = false)
		get_tree().create_tween().tween_property($Ship, "frame", 4, 0.2)
	boosting = false
	
#	boost_cam_tween.tween_property($Camera2D, 'offset', Vector2(400, 40), 0.5).set_ease(Tween.EASE_OUT)
#	boost_cam_tween.tween_property($Camera2D, 'offset', Vector2(400, 0), 0.5).set_ease(Tween.EASE_IN)
func start_credits_shift_x():
#	var is_right = global_position.x >= 0.0
#	var is_left_of_dest = global_position.x <= CREDITS_SHIFT.x
	var shift_tween = create_tween()
	shift_tween.tween_interval(1.0)
	shift_tween.tween_callback(localize_particles)
#	shift_tween.set_trans(Tween.TRANS_SINE)
	var distance_to_shift_dest = position.distance_to(CREDITS_SHIFT)
	for item in shift_assets:
		shift_tween.parallel().tween_property(item, "position",  CREDITS_SHIFT + item.position, distance_to_shift_dest / 300.0)
	shift_tween.parallel().tween_property(self, "position:x", 0.0,
#		0.0 if is_right 
#		else CREDITS_SHIFT.x if is_left_of_dest 
#		else CREDITS_SHIFT.x/2.0, 
	distance_to_shift_dest / 300.0)
	
func end_credits_shift_y():
#	var is_right = global_position.x >= 0.0
#	var is_left_of_dest = global_position.x <= CREDITS_SHIFT.x
	var shift_tween = create_tween()
	shift_tween.tween_callback(localize_particles)
#	shift_tween.set_trans(Tween.TRANS_SINE)
	var distance_to_shift_dest = position.distance_to(END_CREDITS_SHIFT)
	for item in shift_assets:
		shift_tween.parallel().tween_property(item, "position",  END_CREDITS_SHIFT + item.position, 1)
	shift_tween.parallel().tween_property(self, "position:x", 0.0,
#		0.0 if is_right 
#		else CREDITS_SHIFT.x if is_left_of_dest 
#		else CREDITS_SHIFT.x/2.0, 
	1)

func localize_particles():
	$LeftJetExhaust.local_coords = true
	$RightJetExhaust.local_coords = true
	$LeftJetExhaust.process_material.initial_velocity_min = CREDS_VELOCITY_MIN
	$LeftJetExhaust.process_material.initial_velocity_max = CREDS_VELOCITY_MAX
	$RightJetExhaust.process_material.initial_velocity_min = CREDS_VELOCITY_MIN
	$RightJetExhaust.process_material.initial_velocity_max = CREDS_VELOCITY_MAX


func _physics_process(delta):
	if paused:
		return
	actual_speed = global_position.distance_to(prev_position) / delta
	prev_position = global_position
	if !dead and winding_down_controls:
		move_and_slide()
			
	if !dead and controls_enabled:
		if !level.credits_triggered:
			move = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
			aim = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var to_mouse := get_global_mouse_position() - global_position
				if to_mouse.length() > 0:
					aim = to_mouse.normalized()
		else:
			#Credits controls override
			var movement_tween = create_tween()
			movement_tween.tween_property(self, "move", Vector2.UP, 1)
			aim = Vector2.ZERO
		
		prev_rotation = rotation
		
		if Input.is_action_just_pressed("boost"):
			if num_boosts == 3:
				boost()
				num_boosts -=1
				$HUD.hide_boost_shield3()
			elif num_boosts == 2:
				boost()
				num_boosts -=1
				$HUD.hide_boost_shield2()
			elif num_boosts == 1:
				boost()
				num_boosts -=1
				$HUD.hide_boost_shield1()
#		if !boosting and can_boost and Input.is_action_just_pressed("boost"):
#			boost()
		if aim.length() > 0:
			$Gun1.global_rotation = aim.rotated(PI/2).angle()
			shoot(aim.normalized())
			last_aim_normal = aim.normalized()
		#This code sucks ass, I'm sorry. Basically we need to do things if boosting or trying to move, then we need to 
		#do things only if not boosting, or only if boosting and depending on whether we have boosted thruster volume and pitch.
		#its ok :3
		if move.length() > 0 or boosting:
			if !$ThrusterSound.playing:
				$ThrusterSound.play()
			$LeftJetExhaust.emitting=true
			$RightJetExhaust.emitting=true
			if !boosting and $ThrusterSound.volume_db < MAX_THRUSTER_VOLUME:
				var volume_db = (20.0 * log(move.length())/log(10.0)) + MAX_THRUSTER_VOLUME;
				volume_db = clampf(volume_db, MIN_THRUSTER_VOLUME, MAX_THRUSTER_VOLUME)
				$ThrusterSound.volume_db = lerpf($ThrusterSound.volume_db, volume_db, 0.2)
			if move.length() == 0:
				move = Vector2(sin(rotation), -cos(rotation))
			if boosting:
				pass
#				move = move.normalized()
		if move.length() > 0:
			rotation = lerp_angle(rotation, move.rotated(PI/2).angle(), delta*lerp_rotation)
		else:
			$LeftJetExhaust.emitting=false
			$RightJetExhaust.emitting=false
			$ThrusterSound.volume_db = lerp($ThrusterSound.volume_db, ZERO_THRUSTER_VOLUME, 0.3)
		if $ThrusterSound.pitch_scale > THRUSTER_PITCH_NORMAL and !boosting:
			$ThrusterSound.pitch_scale -= delta * 3
			if $ThrusterSound.pitch_scale < THRUSTER_PITCH_NORMAL:
				$ThrusterSound.pitch_scale = THRUSTER_PITCH_NORMAL
		if $ThrusterSound.volume_db > MAX_THRUSTER_VOLUME and !boosting:
			$ThrusterSound.volume_db -= delta * 3
		if !boosting and speed > unboosted_speed:
			speed = lerpf(speed, unboosted_speed, delta * 6)
		if move.x:
			velocity.x = move.x * speed
		else:
			velocity.x = lerpf(velocity.x, 0, delta * 10)
		if move.y:
			velocity.y = move.y * speed
		else:
			velocity.y = lerpf(velocity.y, 0, delta * 10)
		#If hive enemies are stuck on
		if !invincible:
			for node in $".".get_children():
				if node.is_in_group("hive") and !node.dead:
					velocity = velocity * HIVE_SLOWDOWN_PER
					$HomingMissileCooldown.stop()
					can_homing_missile = false
					$HomingMissileCooldown.start()
		else:
			for node in $".".get_children():
				if node.is_in_group("hive"):
					node.take_damage(SHIELD_DAMAGE_PER_LEVEL*shield_level)
		#	move_and_slide()
		var collision = move_and_collide(velocity * delta)
		if collision:
			if collision.get_collider().is_in_group("enemies"):
#				print("collision with enemy")
				if !invincible:
					if collision.get_collider().is_in_group("blue_guy"):
						set_killed_by(G.BLUE_GUY_COLLISION)
					elif collision.get_collider().is_in_group("rammer"):
						set_killed_by(G.RAMMER_COLLISION)
					elif collision.get_collider().is_in_group("spinner"):
						set_killed_by(G.SPINNER_COLLISION)
					elif collision.get_collider().is_in_group("wanderer"):
						set_killed_by(G.WANDERER_COLLISION)
					elif collision.get_collider().is_in_group("minion"):
						if collision.get_collider().boss_spawn:
							set_killed_by(G.BOSS_MINION_COLLISION)
						else:
							set_killed_by(G.MINION_COLLISION)
					elif collision.get_collider().is_in_group("boss"):
						set_killed_by(G.BOSS_SIDESHIP_COLLISION)
					die()
					collision.get_collider().take_damage(KAMIKAZI_DAMAGE)
				else:
					collision.get_collider().take_damage(SHIELD_DAMAGE_PER_LEVEL*shield_level)
			elif collision.get_collider().is_in_group("enemy"):
				if !invincible:
					die()
					collision.get_collider().take_damage(KAMIKAZI_DAMAGE)
				else:
					collision.get_collider().take_damage(SHIELD_DAMAGE_PER_LEVEL*shield_level)
			elif collision.get_collider().is_in_group("enemy_body"):
				if !invincible:
					die()
					collision.get_collider().get_parent().take_damage(KAMIKAZI_DAMAGE)
				else:
					collision.get_collider().get_parent().take_damage(SHIELD_DAMAGE_PER_LEVEL*shield_level)
			elif collision.get_collider().is_in_group("ram"):
				if !invincible:
					die()
					collision.get_collider().get_parent().take_damage(KAMIKAZI_DAMAGE)
				else:
					collision.get_collider().get_parent().take_damage(SHIELD_DAMAGE_PER_LEVEL*shield_level)
			elif collision.get_collider().is_in_group("BossArena"):
				move_and_slide()		
			elif collision.get_collider().is_in_group("Walls"):
				if collision.get_collider().is_in_group("HorizontalWalls"):
					velocity.x = move.x * speed
					velocity.y = 0
					move_and_slide()
				else:
					velocity.y = move.y * speed
					velocity.x = 0
					move_and_slide()
			elif collision.get_collider().is_in_group("lightning"):
				handle_lightning_hit()
		#choose animation frame
		var rotation_diff = rotation - prev_rotation
		if abs(rotation_diff) > 0.06:
			if rotation_diff < 0.0:
				$Ship.frame = 0
			else:
				$Ship.frame = 8
		elif abs(rotation_diff) > 0.04:
			if rotation_diff < 0.0:
				$Ship.frame = 1
			else:
				$Ship.frame = 7
		elif abs(rotation_diff) > 0.01:
			if rotation_diff < 0.0:
				$Ship.frame = 2
			else:
				$Ship.frame = 6
		elif abs(rotation_diff) > 0.001:
			if rotation_diff < 0.0:
				$Ship.frame = 3
			else:
				$Ship.frame = 5
		else:
			$Ship.frame = 4
		
		get_parent().set_last_ship_pos(position)
		if !boosting and invincible:
			var current_particle_alpha = $BoostRamNode2D/RamAreaParticles2D.process_material.color.a
			$BoostRamNode2D/RamAreaParticles2D.process_material.color.a = lerpf(current_particle_alpha, 0, delta * 12)
			var current_particle_velocity = $BoostRamNode2D/RamAreaParticles2D.process_material.initial_velocity_min
			$BoostRamNode2D/RamAreaParticles2D.process_material.initial_velocity_min = lerpf(current_particle_velocity, 0, delta * 10)
			$BoostRamNode2D/RamAreaParticles2D.process_material.initial_velocity_max = lerpf(current_particle_velocity, 0, delta * 10)
		
		handle_shield_bashing()
		
	if dead:
		if Input.is_action_just_pressed("skip_death_screen"):
			await get_tree().create_timer(0.3).timeout
			for bullet in get_tree().get_nodes_in_group("bullet"):
				bullet.hide()
				bullet.queue_free()
			for missile in get_tree().get_nodes_in_group("missile"):
				missile.hide()
				missile.queue_free()
			get_tree().reload_current_scene()

func upgrade_gun():
	if gun_level < MAX_GUN_LEVEL:
		gun_level += 1
#	if gun_level in [1,5]:
		cooldown -= cooldown_per_level
	$GunCooldown.wait_time = cooldown

func upgrade_homing():
	if homing_level < MAX_HOMING_LEVEL:
		homing_level += 1

func add_shield():
	if num_boosts == 3: #force consume boost if inventory full of 3 shields
		boost()
	elif num_boosts == 2:
		num_boosts +=1
		$HUD.show_boost_shield3()
	elif num_boosts == 1:
		num_boosts +=1
		$HUD.show_boost_shield2()
	elif num_boosts == 0:
		num_boosts +=1
		$HUD.show_boost_shield1()

func die():
	if !invincible && !god_mode:
		level.state = level.states.DEATH
		I_DIED.emit()
		get_tree().create_timer(delay_for_death_music, false).timeout.connect(play_death_music)
		$HUD.update_pb(level.clock)
		QuitHandler.game_clock_sec = 0.0
		camera.screen_shake_rough()
		$Ship.queue_free()
		$CollisionPolygon2D.queue_free()
#		$BoostAreaCollisionShape2D.queue_free()
		$Gun1.queue_free()
		$ThrusterSound.stop()
		$ThrusterSound.queue_free()
		$LeftJetExhaust.queue_free()
		$RightJetExhaust.queue_free()
		$BoostRamNode2D.queue_free()
		$ExplodeParticles.emitting = true
		$ExplodeSound.play()
		$ThrusterSound.stop()
		velocity.x = 0
		velocity.y = 0
		dead = true
		$HUD.show_you_died()
		is_alive = false
		for node in $".".get_children():
			if node.is_in_group("hive"):
				if is_instance_valid(node):
					node.reset_speed_and_radius()
					
func play_death_music():
	$DeathAmbientSong.play()
	$DeathAmbientSong/DeathSongLoopTimer.start()
					
func launch_homing_with_delay(delay:float):
	await get_tree().create_timer(delay).timeout
	var direction = last_aim_normal.rotated(PI/2)
	if on_left_homing_missile:
		var h1 = homing_missile_scene.instantiate()
		get_tree().root.add_child(h1)
		h1.start($LeftMissileMarker.global_position, direction, speed/6.0, homing_level)
		on_left_homing_missile = false
		$HomingSound.play()
	else:
		var h1 = homing_missile_scene.instantiate()
		get_tree().root.add_child(h1)
		h1.start($RightMissileMarker.global_position, direction, speed/6.0, homing_level)
		on_left_homing_missile = true
		$HomingSound.play()
	
func shoot(dir_aim:Vector2): #using markers 1,2,3,6,7,8,9,10,11,21
	if homing_level && can_homing_missile:
		can_homing_missile = false
		$HomingMissileCooldown.start()
		remaining_homing_in_burst = homing_level
		for i in range(remaining_homing_in_burst):
			launch_homing_with_delay(HOMING_BURST_INTERVAL * i)
	if !can_shoot:
		return
	if gun_level in [0,1]:
		var b1 = curr_bullet_scene.instantiate()
		get_tree().root.add_child(b1)
		b1.start($Gun1/GunMarker1.global_position, dir_aim)
	elif gun_level == 2:
		var b1 = curr_bullet_scene.instantiate()
		get_tree().root.add_child(b1)
		b1.start($Gun1/GunMarker2.global_position, dir_aim)
		var b2 = curr_bullet_scene.instantiate()
		get_tree().root.add_child(b2)
		b2.start($Gun1/GunMarker3.global_position, dir_aim)
	elif gun_level == 3:
		var b1 = curr_bullet_scene.instantiate()
		get_tree().root.add_child(b1)
		b1.start($Gun1/GunMarker1.global_position, dir_aim)
		var b2 = curr_bullet_scene.instantiate()
		get_tree().root.add_child(b2)
		b2.start($Gun1/GunMarker6.global_position, dir_aim)
		var b3 = curr_bullet_scene.instantiate()
		get_tree().root.add_child(b3)
		b3.start($Gun1/GunMarker7.global_position, dir_aim)
	elif gun_level in [4,5]:
		var b1 = curr_bullet_scene.instantiate()
		get_tree().root.add_child(b1)
		b1.start($Gun1/GunMarker4.global_position, dir_aim)
		var b2 = curr_bullet_scene.instantiate()
		get_tree().root.add_child(b2)
		b2.start($Gun1/GunMarker5.global_position, dir_aim)
		var b3 = curr_bullet_scene.instantiate()
		get_tree().root.add_child(b3)
		b3.start($Gun1/GunMarker8.global_position, dir_aim)
		var b4 = curr_bullet_scene.instantiate()
		get_tree().root.add_child(b4)
		b4.start($Gun1/GunMarker9.global_position, dir_aim)
		
	if gun_level > 4 and can_crescent:
		on_left_cres = !on_left_cres
		var b6 = crescent_bullet_scene.instantiate()
		get_tree().root.add_child(b6)
		b6.rotation = dir_aim.angle() + PI/2.0
		b6.start($Gun1/GunMarker10.global_position, dir_aim, on_left_cres, velocity.x, velocity.y)
		can_crescent = false
		$CrescentCooldown1.start()
	$ShootSound.play()
	can_shoot = false
	$GunCooldown.start()
	
func reset_boost_timers():
#	$BoostCooldown.stop()
	$BoostEffectDuration.stop()
	$PostBoostGracePeriod.stop()
	
func boost():
	$BoostRamNode2D/SecondBoostShieldArea2D/BoostAreaCollisionShape2D.set_deferred("disabled", false)
	reset_boost_timers()
	speed = unboosted_speed * BOOST_MODIFIER
	boosting = true
	invincible = true
	$BoostRamNode2D/SecondBoostShieldArea2D.set_collision_mask_value(15, true)
	set_collision_mask_value(7, false)
	set_collision_mask_value(9, false)
	set_collision_mask_value(12, false)
	set_collision_layer_value(12, false)
	$ThrusterSound.pitch_scale = THRUSTER_PITCH_BOOSTED_MAX
	$ThrusterSound.volume_db = MAX_THRUSTER_VOLUME_BOOSTED
	$BoostRamNode2D/RamAreaParticles2D.emitting = true
	$BoostRamNode2D/SpeedLinesParticles.emitting = true
	$BoostRamNode2D/SpeedLinesParticles2.emitting = true
	
	$BoostRamNode2D/RamAreaParticles2D.process_material.color.a = boost_particle_alpha
	$BoostRamNode2D/SpeedLinesParticles.process_material.color.a = boost_particle_alpha
	$BoostRamNode2D/SpeedLinesParticles2.process_material.color.a = boost_particle_alpha
	$BoostRamNode2D/RamAreaParticles2D.process_material.initial_velocity_min = boost_shield_particle_speed
	$BoostRamNode2D/RamAreaParticles2D.process_material.initial_velocity_max = boost_shield_particle_speed
	$BoostEffectDuration.start()
	camera.screen_shake_rough(15)
	
func get_quadrant_in():
	var center_marker = level.find_child("CenterMarker")
	if global_position.x > center_marker.global_position.x:
		if global_position.y > center_marker.global_position.y:
			return 3
		else:
			return 2
	else:
		if global_position.y > center_marker.global_position.y:
			return 4
		else:
			return 1
	
func _on_gun_cooldown_timeout():
	can_shoot = true
	
func _on_homing_missile_cooldown_timeout():
	can_homing_missile = true
	
func play_speed_upgrade_sound():
	$SpeedUpgradeSound.play()
	
func play_shield_upgrade_sound():
	$ShieldUpgradeSound.play()
	
func play_gun_upgrade_sound():
	$GunUpgradeSound.play()
	
func play_homing_upgrade_sound():
	$HomingUpgradeSound.play()
	
#booster can_boost reset timer callback
#func _on_boost_cooldown_timeout():
#	#changed to one-shot, shouldn't need .stop() anymore
##	$BoostCooldown.stop()
#	if shield_level < 9:
#		can_boost = true
#		$HUD.show_boost_shield1()
#	elif  shield_level == 9:
#		if can_boost:
#			can_boost2 = true
#			$HUD.show_boost_shield2()
#		else:
#			can_boost = true
#			$HUD.show_boost_shield1()
#			$BoostCooldown.start()
#	elif shield_level == 10:
#		if can_boost:
#			if can_boost2:
#				can_boost3 = true
#				$HUD.show_boost_shield3()
#			else:
#				can_boost2 = true
#				$HUD.show_boost_shield2()
#				$BoostCooldown.start()
#		else:
#			can_boost = true
#			$HUD.show_boost_shield1()
#			$BoostCooldown.start()
	
	#TODO: add sound and visual effect for boost ready
	
#boost duration timer callback
func _on_boost_effect_duration_timeout():
	boosting = false
	$BoostRamNode2D/SpeedLinesParticles.emitting = false
	$BoostRamNode2D/SpeedLinesParticles2.emitting = false
#	$LeftJetExhaust.amount = throttle_particles
#	$RightJetExhaust.amount = throttle_particles
#	$BoostEffectDuration.stop()
#	$PostBoostGracePeriod.stop()
	$PostBoostGracePeriod.start()
	
func reset_boost_vals():
	invincible = false
	$BoostRamNode2D/SecondBoostShieldArea2D.set_collision_mask_value(15, false)
	set_collision_mask_value(7, true)
	set_collision_mask_value(9, true)
	set_collision_mask_value(12, true)
	set_collision_layer_value(12, true)
	$BoostRamNode2D/SecondBoostShieldArea2D/BoostAreaCollisionShape2D.disabled = true
	$BoostRamNode2D/RamAreaParticles2D.emitting = false
	
#	$BoostAreaCollisionShape2D.disabled = true
	
func _on_post_boost_grace_period_timeout():
#	$PostBoostGracePeriod.stop()
	reset_boost_vals()
	
func unpause():
	paused = false
	level.show_all()
	get_tree().paused = false
	
func _input(event):
	if event.is_action_pressed("b_start"):
		if paused:
			if get_tree().get_first_node_in_group("pausemenu").menu_choice == 0:
				paused = false
				level.show_all()
				get_tree().paused = false
		else:
			if !level.credits_triggered:
				paused = true
				level.hide_all_but_stars()
				get_tree().paused = true

func handle_shield_bashing():
#	if enemies_area_currently_shield_bashing.size() > 0:
#		for i in range(enemies_area_currently_shield_bashing.size()):
#			if is_instance_valid(enemies_area_currently_shield_bashing[i]):
#				if !enemies_area_currently_shield_bashing[i].get_parent().dead:
#					if invincible and !shield_damage_cooling:
##						print('shield bashing enemy 3')
##						print('\twith damage' + str(SPINNER_BASH_DAMAGE_MULT * SHIELD_DAMAGE_PER_LEVEL*shield_level))
#						enemies_area_currently_shield_bashing[i].get_parent().take_damage(SPINNER_BASH_DAMAGE_MULT * SHIELD_DAMAGE_PER_LEVEL*shield_level)
#						$ShieldDamageSound.play()
#						common.play_damage_sound()
#						shield_damage_cooling = true
#						$ShieldDamageCooldown.start()
#			else:
#				call_deferred("filter_out_shield_bashing_enemy", enemies_area_currently_shield_bashing[i])
	if miniboss_colliding_with_1 != null and invincible and !shield_damage_cooling:
		shield_damage_cooling = true
		$ShieldDamageCooldown.start()
		miniboss_colliding_with_1.get_parent().take_damage_parent(SHIELD_DAMAGE_PER_LEVEL*shield_level)
		$ShieldDamageSound.play()
	if miniboss_colliding_with_2 != null and invincible and !shield_damage_cooling:
		shield_damage_cooling = true
		$ShieldDamageCooldown.start()
		miniboss_colliding_with_2.get_parent().take_damage_parent(SHIELD_DAMAGE_PER_LEVEL*shield_level)
		$ShieldDamageSound.play()
	if boss_colliding_with_1 != null and invincible and !shield_damage_cooling:
		shield_damage_cooling = true
		$ShieldDamageCooldown.start()
		boss_colliding_with_1.take_damage(SHIELD_DAMAGE_PER_LEVEL*shield_level)
		$ShieldDamageSound.play()
	if boss_colliding_with_2 != null and invincible and !shield_damage_cooling:
		shield_damage_cooling = true
		$ShieldDamageCooldown.start()
		boss_colliding_with_2.take_damage(SHIELD_DAMAGE_PER_LEVEL*shield_level)
		$ShieldDamageSound.play()

func _on_second_boost_shield_area_2d_body_entered(body):
	if body.is_in_group('miniboss'):
		if miniboss_colliding_with_1 != null:
			miniboss_colliding_with_2 = body
		else:
			miniboss_colliding_with_1 = body
	if body.is_in_group('boss'):
		if boss_colliding_with_1 != null:
			boss_colliding_with_2 = body
		else:
			boss_colliding_with_1 = body
	if body.is_in_group('enemy'):
		body.die()

func _on_second_boost_shield_area_2d_body_exited(body):
	if body.is_in_group('miniboss'):
		if body == miniboss_colliding_with_1:
			miniboss_colliding_with_1 = null
		else:
			miniboss_colliding_with_2 = null
	if body.is_in_group('boss'):
		if body == boss_colliding_with_1:
			boss_colliding_with_1 = null
		else:
			boss_colliding_with_2 = null
			
func _on_shield_damage_cooldown_timeout():
	shield_damage_cooling = false

	
func handle_lightning_hit():
	print("handling lightning hit")
#	$WallThud.play() #replace with lightning jitter sound	if bounce_back_speed_tween:
	controls_enabled = false
	being_shocked = true
	if boosting:
		boosting = false
		reset_boost_vals()
	camera.screen_shake_rough(50)
#	get_tree().create_timer(STUN_DURATION).timeout.connect(enable_controls)
#	speed = STUN_START_SPEED
	if lightning_jitter_tween:
		lightning_jitter_tween.kill()
	lightning_jitter_tween = create_tween()
#	bounce_back_speed_tween.tween_property(self, "speed", 0.0, 1.2).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT).connect("finished", done_bouncing)
	lightning_jitter_tween.tween_property(self, "position", position + (position.rotated(PI).normalized() * KNOCKBACK_DISTANCE), STUN_DURATION).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT).connect("finished", shock_complete)
	$Ship.material = invert_material
	$ShockSound.play()
	$ShockTimer.start()

func shock_complete():
	being_shocked = false
	$ShockTimer.stop()
	if is_instance_valid(ship):
		if ship.material:
			ship.material = null
	speed = START_SPEED
	controls_enabled = true

func play_credits():
	$HUD.play_credits()

func _on_shock_timer_timeout():
	if is_instance_valid(ship):
		if !ship.material:
			ship.material = invert_material
		else:
			ship.material = null
	
func _on_crescent_cooldown_1_timeout():
	can_crescent = true

func _on_second_boost_shield_area_2d_area_entered(area):
	if area.is_in_group("enemy_body"):
		area.get_parent().die()
	elif area.is_in_group("hive"):
		area.take_damage(1000)
	if area.is_in_group('shield_powerup'):
		add_shield()
		play_shield_upgrade_sound()
		area.queue_free()
	if area.is_in_group('missile_powerup'):
		upgrade_homing()
		play_homing_upgrade_sound()
		area.queue_free()
	if area.is_in_group('gun_powerup'):
		upgrade_gun()
		play_gun_upgrade_sound()
		area.queue_free()
#	if area.is_in_group("spinner"):
#		call_deferred("add_shield_bashing_enemy", area)

#func _on_second_boost_shield_area_2d_area_exited(area):
#	if area.is_in_group("spinner"):
#		if enemies_area_currently_shield_bashing.has(area):
#			call_deferred("filter_out_shield_bashing_enemy", area)

#func add_shield_bashing_enemy(enemy):
#	if is_instance_valid(enemy) && !enemies_area_currently_shield_bashing.has(enemy):
#		print("bashing before add:", enemies_area_currently_shield_bashing)
#		enemies_area_currently_shield_bashing.push_back(enemy)
#		print("bashing after add:", enemies_area_currently_shield_bashing)
#
#func filter_out_shield_bashing_enemy(enemy):
#	print("bashing before remove:", enemies_area_currently_shield_bashing)
#	if enemies_area_currently_shield_bashing.has(enemy):
#		enemies_area_currently_shield_bashing = enemies_area_currently_shield_bashing.filter(func(el): return el != enemy)
#	print("bashing after remove:", enemies_area_currently_shield_bashing)

func _on_death_song_loop_timer_timeout():
	play_death_music()
