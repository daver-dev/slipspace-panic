extends CharacterBody2D

@export var minion_scene : PackedScene
@export var side_ship_bullet_scene: PackedScene
@export var number_of_lightning_loops : int
const CHARGE_THRUST = 600.0
const MAX_CHARGE_SPEED = 2.0
const SECONDS_PER_ADD = 1.5
const SECONDS_PER_WANDERER = 3.1
const SECONDS_BETWEEN_WANDERERS = 0.2
# Measures the seconds elapsed since the instantiation of the scene
var seconds_elapsed = 0.0
var shooting_movement_started = false
# vvvvvvvvv Minion variables vvvvvv

# Used as a counter for the number of minions spawned during a single minion spawning phase.
var minions_spawned_during_this_minion_attack = 0
const MINIONS_PER_BURST = 30
const interval_between_each_minion_seconds = 0.03
# timestamp, relative to the start of the scene instantiation, that the last minion spawned.
var timestamp_of_last_minion_spawned = 0.0
#boolean to check if a minion should spawn in a given physics process.
var should_spawn_minion_this_physics_process = false
var add_should_spawn_boost = false

var x_cap = 600

enum states {
	INTRO=0, 
	IDLE=1, 
	LIGHTNING=2, 
	MINIONS=3, 
	SIDE_SHIPS_SHOOTING = 4, 
	SIDE_SHIPS_CHARGE=5, 
	LIGHTNING_AND_MINIONS=6, 
	LIGHTNING_AND_SIDE_SHIPS_SHOOTING=7, 
	LIGHTNING_AND_SIDE_SHIPS_CHARGE=8,
	SIDE_SHIPS_SHOOTING_AND_MINIONS=9,
	DEAD=10
	}
var state = states.INTRO

const phase_1_states = [
	states.MINIONS,
	states.SIDE_SHIPS_SHOOTING,
	states.SIDE_SHIPS_CHARGE
	]
var last_state_idx_used = -1 #dummy value to start

var phase = 1

const phase_2_states = [
	states.SIDE_SHIPS_SHOOTING_AND_MINIONS, 
	states.LIGHTNING_AND_SIDE_SHIPS_CHARGE
	]

const phase_3_states = []

const idle_speed = 3.0
const lightning_speed = 10.0
const side_ship_shoot_speed = 1.0

const DEFAULT_DELAY = 3.0

### START MINION PHASE STUFF ###
const num_glow_animations_before_launch = 2
const num_siren_plays_per_minions_cycle = 2
const MINIONS_SPEED = 3.0
const MINION_Y_SPAWN_OFFSET = 100
const CLEARED_BOSS_MOUTH_Y_OFFSET = 200
var num_glow_animations_played = 0
var num_siren_played = 0
var minion_attack_started = false
### END MINION PHASE STUFF ^ ###

var current_speed
var time_to_fade_in = false
var charge_speed = 0.0
var idle_time_seconds = 5.0
var second_side_ship_wait_time = 1.0

var is_lightning_animation_playing = false
var lightning_loop_count = 0
var lightning_charge_finished = false
var lightning_sound_should_be_looping = false
var frames_per_lightning_sound = 25
var frames_elapsed_during_lightning_sound = 0
var lightning_complete = false
var can_lightning = false

var seconds_elapsed_during_side_ship_shooting = 0.0
#var side_ships_should_be_charging_to_shoot = false
var side_ships_can_shoot = false
var side_ships_should_shoot_this_frame = true
var shooting_started_from_left := false
var shooting_started := false
var phase_2_sweeps_so_far := 0
var minion_attack_complete = false
var charge_started = false
var time_in_current_state := 0.0
var num_side_ships_alive = 2
var level
var minion_movement_started = false
var saved_pos_for_death
var save_pos_flag = true
var adds_timer = 0.0
var wanderers_timer = 0.0
var adds_spawned = 0
var enemies_node: Node2D
#MINION POOL
var minion_pool:Array[Minion] = []
const MINION_POOL_TARGET_SIZE := 20
const MINIONS_TO_CREATE_PER_FRAME := 5

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group('player')

@onready var center_ship = $CenterShip/CenterShipCharacterBody
@onready var left_ship = $LeftShip/LeftShipChargePath2D5/LeftShipPathFollow2D5/LeftShipCharacterBody
@onready var left_ship_shooting_animation_player = $LeftShip/LeftShipChargePath2D5/LeftShipPathFollow2D5/LeftShipCharacterBody/LeftShipShootingAnimation
@onready var left_bullet_spawnpoint = $LeftShip/LeftShipChargePath2D5/LeftShipPathFollow2D5/LeftShipCharacterBody/LeftShipShootingAnimation/LeftShipBulletSpawnLocation

@onready var right_ship = $RightShip/RightShipChargePath2D5/RightShipPathFollow2D5/RightShipCharacterBody
@onready var right_ship_shooting_animation_player = $RightShip/RightShipChargePath2D5/RightShipPathFollow2D5/RightShipCharacterBody/RightShipShootingAnimation
@onready var right_bullet_spawnpoint = $RightShip/RightShipChargePath2D5/RightShipPathFollow2D5/RightShipCharacterBody/RightShipShootingAnimation/RightShipBulletSpawnLocation

@onready var right_ship_particles_1 = $RightShip/RightShipChargePath2D5/RightShipPathFollow2D5/RightShipCharacterBody/RightShipChargeupParticles
@onready var right_ship_particles_2 = $RightShip/RightShipChargePath2D5/RightShipPathFollow2D5/RightShipCharacterBody/RightShipChargeupParticles2
@onready var left_ship_particles_1 = $LeftShip/LeftShipChargePath2D5/LeftShipPathFollow2D5/LeftShipCharacterBody/LeftShipChargeupParticles
@onready var left_ship_particles_2 = $LeftShip/LeftShipChargePath2D5/LeftShipPathFollow2D5/LeftShipCharacterBody/LeftShipChargeupParticles2

@onready var lightning_animation = $CenterShip/CenterShipCharacterBody/ElectricityBeams/ShipWithLightningAnimation
@onready var lightning_itself_animation = $CenterShip/CenterShipCharacterBody/ElectricityBeams/LightningAnimation
@onready var hud = get_tree().get_first_node_in_group("hud")
@onready var camera = get_tree().get_first_node_in_group("camera")

func notify_sideship_dead():
	num_side_ships_alive -=1
	if num_side_ships_alive == 0:
		#TODO: some animation for forcefield down?
		$CenterShip/CenterShipCharacterBody/ForceFieldArea2D/CollisionShape2D.disabled = true
		$CenterShip/CenterShipCharacterBody/CenterShipCollisionArea2D/CenterShipCollisionPolygon2D.disabled = false
		phase = 2

func get_capped_x_position():
	@warning_ignore("incompatible_ternary")
	return x_cap if global_position.x > x_cap && player.global_position.x > x_cap else -1.0 * x_cap if global_position.x < -1.0 * x_cap && player.global_position.x < -1.0 * x_cap else player.global_position.x

func attack_cycle():
	pass

func _ready():
	$AttackCycleTimer.start()
	current_speed = idle_speed
	level = get_tree().get_first_node_in_group("level")
	enemies_node = level.find_child("EnemiesNode2D")
	$ShipHoverSound.play()
	$ShipHoverSound2.play()
	
func get_last_ship_position():
	level.get_last_ship_pos()

func _physics_process(delta):
	if !(state in [states.DEAD, states.INTRO]) && $CenterShip/CenterShipCharacterBody.hp > 0:
		spawn_adds(delta)
		spawn_wanderers(delta)
	check_minion_pool()
#	print(get_tree().get_node_count())
#	print_orphan_nodes()
#	print(position)
#	print(global_position)
	handle_state(delta)
	# seconds elapsed is measured with delta, because delta measures the time passed in between physics processes.
	# Counting up by delta every physics_process essentially creates a timer.
	seconds_elapsed += delta
	time_in_current_state += delta
	if $CenterShip/CenterShipCharacterBody.hp <= 0:
		for enemy in enemies_node.get_children():
			if self != enemy && is_instance_valid(enemy):
				enemy.die()
		if save_pos_flag:
			saved_pos_for_death = global_position
			save_pos_flag = false
		global_position = saved_pos_for_death
		
#	if boss.state == boss.states.IDLE:
#		speed_multiplier = 2
#	if boss.state == boss.states.LIGHTNING:
#		speed_multiplier = 100

func check_minion_pool():
	if minion_pool.size() < MINION_POOL_TARGET_SIZE:
		for i in range(MINIONS_TO_CREATE_PER_FRAME):
			minion_pool.push_back(minion_scene.instantiate())
		

func handle_state(delta):
	match state:
		states.INTRO:
			make_boss_do_intro(delta)
		states.IDLE:
			make_boss_do_idle()
			$LeftShipTarget.idle_movement()
			$RightShipTarget.idle_movement()
		states.LIGHTNING:
			make_boss_do_lightning()
		states.MINIONS:
			make_boss_do_minions()
			$LeftShipTarget.idle_movement()
			$RightShipTarget.idle_movement()
		states.SIDE_SHIPS_CHARGE:
			make_side_ships_charge()
			state = states.IDLE
			choose_random_state_with_delay(6.0)
		states.SIDE_SHIPS_SHOOTING:
			make_side_ships_shoot(delta)
		states.SIDE_SHIPS_SHOOTING_AND_MINIONS:
			make_side_ships_shoot(delta)
			if time_in_current_state > 10.0: #use this to delay sister-state for phase 2
				make_boss_do_minions()
		states.LIGHTNING_AND_SIDE_SHIPS_CHARGE:
			make_boss_do_lightning()
			if time_in_current_state > 1.0 and !charge_started:
				make_side_ships_charge()
				charge_started = true
				$IdleTimer.start() #Delay going to idle because IDLE movement conflicts with Lighting
				choose_random_state_with_delay(7.0)
		states.LIGHTNING_AND_MINIONS:
			if time_in_current_state > 1.0:#delaying lightning with this and used in make_boss_do_lightning_and_minions()
				can_lightning = true
			#TODO:added these idle movement calls to fix side ship drift
			$LeftShipTarget.idle_movement()
			$RightShipTarget.idle_movement()
			make_boss_do_lightning_and_minions()
		
func choose_random_state():
	time_in_current_state = 0.0
	shooting_started = false
	minion_movement_started = false
	if phase == 1:
		minion_attack_complete = false
#		print("choosing random phase 1 state not including state index: " + str(last_state_idx_used))
		var potential_states = phase_1_states.filter(func(val): return val != last_state_idx_used)
		var next_state = potential_states.pick_random() if $CenterShip/CenterShipCharacterBody.hp > 1 else states.IDLE
#		print("chose next state, index: " + str(next_state))
#		print("state index: " + str(next_state) + " is state: " + str(states.keys()[next_state]))
		state = states.values()[next_state]
		last_state_idx_used = next_state
	elif phase == 2:
		minion_attack_complete = false
		charge_started = false
		lightning_complete = false
#		print("choosing random phase 1 state not including state index: " + str(last_state_idx_used))
		var potential_states = phase_2_states.filter(func(val): return val != last_state_idx_used)
		if state == states.SIDE_SHIPS_SHOOTING:
#			print("manually excluding phase 2 shooting state to avoid going from a phase 1 shooting state to a phase two shooting state")
			potential_states = potential_states.filter(func(val): return val != 9)
		var next_state = potential_states.pick_random() if $CenterShip/CenterShipCharacterBody.hp > 1 else states.IDLE
#		print("chose next state, index: " + str(next_state))
#		print("state index: " + str(next_state) + " is state: " + states.keys()[next_state])
		state = states.values()[next_state]
		last_state_idx_used = next_state
		
func make_boss_do_intro(delta):
	player.controls_enabled = false
	player.wind_down_controls()
	var acceleration = CHARGE_THRUST
	charge_speed += acceleration * delta
	charge_speed = clampf(charge_speed, 0, MAX_CHARGE_SPEED)
	var collision = move_and_collide(Vector2(0,charge_speed))
	if collision:
		send_player_to_start_position()
		camera.screen_shake_rough()
		$"../../Border".blow_up_top()
		get_parent().get_parent().find_child("Camera2D").postboss()
		get_parent().get_parent().find_child("BossArena").reveal_shield()
		$CollisionShape2D.disabled = true
		charge_speed = charge_speed / 2.0
		velocity = Vector2(0,charge_speed)
		move_and_slide()
	elif position.y > -100:
		player.controls_enabled = true #boss is in place, allow controls again
		state = states.IDLE
		choose_random_state_with_delay(1.5)
		left_ship.idle()
		right_ship.idle()
		position.y = -100
		level.start_boss_music()
	
func make_boss_do_idle():
	$target_for_boss.speed_multiplier = 2
	current_speed = lerpf(current_speed, idle_speed, 0.03)
#	if($IdleTimer.is_stopped()):
#		$IdleTimer.start()
#	player.controls_enabled = true
	# Need to make speed multiplied by a number * distance from x = 0
	var ship_pos_x = global_position.direction_to(Vector2(get_capped_x_position(), 0.0))
	var distance = global_position.distance_to(Vector2(player.global_position.x, 0.0)) 
	var speed = 0 if get_capped_x_position() == x_cap || get_capped_x_position() == -1 * x_cap else distance * current_speed
	velocity = ship_pos_x * speed
	move_and_slide()
	
func get_marker_closest_player():
	var closest_marker:Marker2D = $PathChoiceMarker2D1
	if player.global_position.distance_to($PathChoiceMarker2D2.global_position) < player.global_position.distance_to(closest_marker.global_position):
		closest_marker = $PathChoiceMarker2D2
	if player.global_position.distance_to($PathChoiceMarker2D3.global_position) < player.global_position.distance_to(closest_marker.global_position):
		closest_marker = $PathChoiceMarker2D3
	if player.global_position.distance_to($PathChoiceMarker2D4.global_position) < player.global_position.distance_to(closest_marker.global_position):
		closest_marker = $PathChoiceMarker2D4
	if player.global_position.distance_to($PathChoiceMarker2D5.global_position) < player.global_position.distance_to(closest_marker.global_position):
		closest_marker = $PathChoiceMarker2D5
	return closest_marker
	
func show_lightning_sprite():
	$CenterShip/CenterShipCharacterBody/ElectricityBeams/BeamsAiming.visible = true
	
func make_boss_do_lightning():
	if $CenterShip/CenterShipCharacterBody.hp <= 0:
		$CenterShip/CenterShipCharacterBody/ElectricityBeams.visible = false
		$CenterShip/CenterShipCharacterBody/AllButMouth.visible = true
		$CenterShip/CenterShipCharacterBody/ElectricityBeams/ElectrivityBeamsBody/LeftBeamCollision.disabled = true
		$CenterShip/CenterShipCharacterBody/ElectricityBeams/ElectrivityBeamsBody/RightBeamCollision.disabled = true
		return
	if !lightning_complete:
		x_cap = 1200
		$target_for_boss.speed_multiplier = 12
	#	$target_for_boss.speed_multiplier = 100 #This was in target_for_boss script
		var ship_pos_x = global_position.direction_to(Vector2(get_capped_x_position(), 0.0))
		var distance = global_position.distance_to(Vector2(player.global_position.x, 0.0)) 
		var speed = 0 if get_capped_x_position() == x_cap || get_capped_x_position() == -1 * x_cap else distance * current_speed
		velocity = ship_pos_x * speed
		$CenterShip/CenterShipCharacterBody/ElectricityBeams.visible = true
		$CenterShip/CenterShipCharacterBody/AllButMouth.visible = false
		if lightning_sound_should_be_looping == true:
			loop_lightning_sound()
		
		if is_lightning_animation_playing == false:
			lightning_animation.play("lightning_charge")
			$CenterShip/CenterShipCharacterBody/ElectricityBeams/LightningCharge.play()
			is_lightning_animation_playing = true
		if lightning_charge_finished == true:
			current_speed = lerpf(current_speed, 0, 0.03)
			velocity.x = lerpf(velocity.x, 0, 0.03)
			$CenterShip/CenterShipCharacterBody/ElectricityBeams/ElectrivityBeamsBody/LeftBeamCollision.disabled = false
			$CenterShip/CenterShipCharacterBody/ElectricityBeams/ElectrivityBeamsBody/RightBeamCollision.disabled = false
		else:
			velocity = ship_pos_x * speed
			current_speed = lerpf(current_speed, lightning_speed, 0.03)
		move_and_slide()
	
func make_boss_do_lightning_and_minions():
	if !lightning_complete and can_lightning:
		x_cap = 1200
		$target_for_boss.speed_multiplier = 12
	#	$target_for_boss.speed_multiplier = 100 #This was in target_for_boss script
		var ship_pos_x = global_position.direction_to(Vector2(get_capped_x_position(), 0.0))
		var distance = global_position.distance_to(Vector2(player.global_position.x, 0.0)) 
		var speed = 0 if get_capped_x_position() == x_cap || get_capped_x_position() == -1 * x_cap else distance * current_speed
		velocity = ship_pos_x * speed
		$CenterShip/CenterShipCharacterBody/ElectricityBeams.visible = true
		$CenterShip/CenterShipCharacterBody/AllButMouth.visible = false
		if lightning_sound_should_be_looping == true:
			loop_lightning_sound()
		
		if is_lightning_animation_playing == false:
			lightning_animation.play("lightning_charge")
			$CenterShip/CenterShipCharacterBody/ElectricityBeams/LightningCharge.play()
			is_lightning_animation_playing = true
		if lightning_charge_finished == true:
			current_speed = lerpf(current_speed, 0, 0.03)
			velocity.x = lerpf(velocity.x, 0, 0.03)
			$CenterShip/CenterShipCharacterBody/ElectricityBeams/ElectrivityBeamsBody/LeftBeamCollision.disabled = false
			$CenterShip/CenterShipCharacterBody/ElectricityBeams/ElectrivityBeamsBody/RightBeamCollision.disabled = false
		else:
			velocity = ship_pos_x * speed
			current_speed = lerpf(current_speed, lightning_speed, 0.03)
		move_and_slide()
	else:
		$target_for_boss.speed_multiplier = 2
		current_speed = lerpf(current_speed, MINIONS_SPEED, 0.03)
		var ship_pos_x = global_position.direction_to(Vector2(get_capped_x_position(), 0.0))
		var distance = global_position.distance_to(Vector2(player.global_position.x, 0.0)) 
		var speed = 0 if get_capped_x_position() == x_cap || get_capped_x_position() == -1 * x_cap else distance * current_speed
		velocity = ship_pos_x * speed
		move_and_slide()
		
		
	if !minion_movement_started:
		minion_center_movement(1.7)
		minion_movement_started = true

	if !minion_attack_complete:
		if !$CenterShip/CenterShipCharacterBody/WarningGlowSprite.visible:
			$CenterShip/CenterShipCharacterBody/WarningGlowSprite.visible = true
			$CenterShip/CenterShipCharacterBody/WarningGlowSprite.play()
			$CenterShip/CenterShipCharacterBody/MinionSiren.play(1.37)
		if !minion_attack_started:
			if num_glow_animations_played >= num_glow_animations_before_launch:
				minion_attack_started = true
				
		if minion_attack_started:
			if (seconds_elapsed - timestamp_of_last_minion_spawned > interval_between_each_minion_seconds):
				timestamp_of_last_minion_spawned = seconds_elapsed
				should_spawn_minion_this_physics_process = true
			
			if (should_spawn_minion_this_physics_process && $CenterShip/CenterShipCharacterBody.hp > 0):
				spawn_minion()
			
			if (minions_spawned_during_this_minion_attack >= MINIONS_PER_BURST):
				minions_spawned_during_this_minion_attack = 0
				$CenterShip/CenterShipCharacterBody/WarningGlowSprite.visible = false
				$CenterShip/CenterShipCharacterBody/WarningGlowSprite.stop()
				$CenterShip/CenterShipCharacterBody/MinionSiren.stop()
				minion_attack_started = false
				num_glow_animations_played = 0
				num_siren_played = 0
				if phase == 1:
					state = states.IDLE
					choose_random_state_with_delay(0.3)
				else:
					minion_attack_complete = true
					choose_random_state_with_delay(2.0)
func minion_center_movement(delay:float):
	if $CenterShip/CenterShipCharacterBody.hp > 0:
		var my_sign = 1 if randi_range(0, 1) else -1
		await get_tree().create_timer(delay).timeout
		var trans_time = 1.2
		var movement_tween = create_tween()
		movement_tween.tween_property($CenterShip, "position:x", my_sign * 250, trans_time).set_trans(Tween.TRANS_QUAD)
		movement_tween.parallel().tween_property($CenterShip, "position:y", -250, trans_time).set_trans(Tween.TRANS_LINEAR)
		movement_tween.tween_property($CenterShip, "position:x", my_sign * -250, trans_time).set_trans(Tween.TRANS_QUAD)
		movement_tween.tween_property($CenterShip, "position:x", 0, trans_time).set_trans(Tween.TRANS_QUAD)
		movement_tween.parallel().tween_property($CenterShip, "position:y", 0, trans_time).set_trans(Tween.TRANS_LINEAR)

func spawn_minion():
#	var scene = minion_scene.instantiate()
	var scene = minion_pool.pop_back()
	if scene:
		var x_position_offset = randi_range(-100, 100) #ok
		scene.boss_mouth_y_pos = global_position.y + CLEARED_BOSS_MOUTH_Y_OFFSET
		scene.boss = $CenterShip/CenterShipCharacterBody
#		$CenterShip/CenterShipCharacterBody.add_child(scene)
		get_parent().add_child(scene)
		# I checked here to make sure its on the correct node (EnemiesNode2D)
		var starting_point = Vector2()
		starting_point.x += x_position_offset
		starting_point.y = MINION_Y_SPAWN_OFFSET #
		starting_point = starting_point.rotated($CenterShip/CenterShipCharacterBody.global_rotation)
		scene.global_position = starting_point + $CenterShip/CenterShipCharacterBody.global_position
		minions_spawned_during_this_minion_attack += 1
		should_spawn_minion_this_physics_process = false
	

func make_boss_do_minions():
	$target_for_boss.speed_multiplier = 2
	current_speed = lerpf(current_speed, MINIONS_SPEED, 0.03)
	var ship_pos_x = global_position.direction_to(Vector2(get_capped_x_position(), 0.0))
	var distance = global_position.distance_to(Vector2(player.global_position.x, 0.0)) 
	var speed = 0 if get_capped_x_position() == x_cap || get_capped_x_position() == -1 * x_cap else distance * current_speed
	velocity = ship_pos_x * speed
	move_and_slide()
	
	if !minion_movement_started:
		minion_center_movement(0.6)
		minion_movement_started = true

	if !minion_attack_complete:
		if !$CenterShip/CenterShipCharacterBody/WarningGlowSprite.visible && $CenterShip/CenterShipCharacterBody.hp > 0:
			$CenterShip/CenterShipCharacterBody/WarningGlowSprite.visible = true
			$CenterShip/CenterShipCharacterBody/WarningGlowSprite.play()
			$CenterShip/CenterShipCharacterBody/MinionSiren.play(1.37)
		if !minion_attack_started:
			if num_glow_animations_played >= num_glow_animations_before_launch:
				minion_attack_started = true
				
		if minion_attack_started:
			if (seconds_elapsed - timestamp_of_last_minion_spawned > interval_between_each_minion_seconds):
				timestamp_of_last_minion_spawned = seconds_elapsed
				should_spawn_minion_this_physics_process = true
			
			if (should_spawn_minion_this_physics_process && $CenterShip/CenterShipCharacterBody.hp > 0):
				spawn_minion()
			
			if (minions_spawned_during_this_minion_attack >= MINIONS_PER_BURST):
				minions_spawned_during_this_minion_attack = 0
				$CenterShip/CenterShipCharacterBody/WarningGlowSprite.visible = false
				$CenterShip/CenterShipCharacterBody/WarningGlowSprite.stop()
				$CenterShip/CenterShipCharacterBody/MinionSiren.stop()
				minion_attack_started = false
				num_glow_animations_played = 0
				num_siren_played = 0
				if state == states.MINIONS:
					state = states.IDLE
					choose_random_state_with_delay(1.5)
				if phase == 1:
					pass
					#TODO: need minion_attack_complete=true here?
				else:
					minion_attack_complete = true

func _on_attack_cycle_timer_timeout():
	pass
	
func choose_random_state_with_delay(delay:float):
	get_tree().create_timer(delay).timeout.connect(choose_random_state)

func send_player_to_start_position():
	get_tree().create_tween().tween_property(player, "position", $PlayerStartPositionMarker.position, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	get_tree().create_tween().tween_property(player, "rotation", (6.0 * PI) * pow(-1, randi() % 2), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func start_shooting_animations():
	if !right_ship_shooting_animation_player.is_playing():
		right_ship_shooting_animation_player.play()
	if !left_ship_shooting_animation_player.is_playing():
		left_ship_shooting_animation_player.play()

func make_side_ships_shoot(delta):
	$target_for_boss.speed_multiplier = 1
	current_speed = lerpf(current_speed, side_ship_shoot_speed, 0.03)
	var ship_pos_x = global_position.direction_to(Vector2(get_capped_x_position(), 0.0))
	var distance = global_position.distance_to(Vector2(player.global_position.x, 0.0)) 
	var speed = 0 if get_capped_x_position() == x_cap || get_capped_x_position() == -1 * x_cap else distance * current_speed
	velocity = ship_pos_x * speed
	move_and_slide()
	seconds_elapsed_during_side_ship_shooting += delta
	
	if phase == 2 and state != states.SIDE_SHIPS_SHOOTING:
		if seconds_elapsed_during_side_ship_shooting > 5:
			side_ships_can_shoot = false
			$LeftShipTarget.shoot_state = ShipTarget.SHOOT_STATES.DONE_SHOOTING
			$RightShipTarget.shoot_state = ShipTarget.SHOOT_STATES.DONE_SHOOTING
			left_ship.reset_rotation()
			right_ship.reset_rotation()
			left_ship_shooting_animation_player.frame = 5
			left_ship_shooting_animation_player.play_backwards()
			right_ship_shooting_animation_player.frame =5
			right_ship_shooting_animation_player.play_backwards()
			#TODO: reset all shooting counters and stuff, make new func called end_shooting() or something?
			#Reset animation rotations
			seconds_elapsed_during_side_ship_shooting = 0.0
			phase_2_sweeps_so_far += 1
			
#			state = states.IDLE #call get_random_state() here instead eventually
	#	elif seconds_elapsed_during_side_ship_shooting > 2:
		elif seconds_elapsed_during_side_ship_shooting > 2:
			right_ship_particles_1.emitting = false
			right_ship_particles_2.emitting = false
			left_ship_particles_1.emitting = false
			left_ship_particles_2.emitting = false
			side_ships_can_shoot = true
				
		elif seconds_elapsed_during_side_ship_shooting > 0.5:
			right_ship_particles_1.emitting = true
			right_ship_particles_2.emitting = true
			left_ship_particles_1.emitting = true
			left_ship_particles_2.emitting = true
		else:
#			right_ship_sprite.visible = false
#			right_ship_shooting_animation_player.visible = true
			if !right_ship_shooting_animation_player.is_playing():
				right_ship_shooting_animation_player.play()
#			left_ship_sprite.visible = false
#			left_ship_shooting_animation_player.visible = true
			if !left_ship_shooting_animation_player.is_playing():
				left_ship_shooting_animation_player.play()
		if side_ships_can_shoot:
			if phase_2_sweeps_so_far != 2:
				$LeftShipTarget.enable_shooting_movement_phase_1(1.95)
				$RightShipTarget.enable_shooting_movement_phase_1(1.95)
			else:
				$LeftShipTarget.enable_shooting_movement_phase_2(2.2)
				$RightShipTarget.enable_shooting_movement_phase_2(2.2)
			if side_ships_should_shoot_this_frame && $CenterShip/CenterShipCharacterBody.hp > 0:
				sideships_fire_bullet()
				$GunSound.play()
				$BulletCooldown.start()
		else:
			if !shooting_started:
				shooting_started_from_left = player.global_position.x < 0
				shooting_started = true
#			$LeftShipTarget.move_for_shooting_sweep_phase_1(delta, shooting_started_from_left)
#			$RightShipTarget.move_for_shooting_sweep_phase_1(delta, shooting_started_from_left)
			if phase_2_sweeps_so_far == 0:
				var sweeping_from_left = shooting_started_from_left
				$LeftShipTarget.move_for_shooting_sweep_phase_1(delta, sweeping_from_left, 0.5)
				$RightShipTarget.move_for_shooting_sweep_phase_1(delta, sweeping_from_left, 0.5)
			elif phase_2_sweeps_so_far == 1:
				var sweeping_from_left = !shooting_started_from_left
				$LeftShipTarget.move_for_shooting_sweep_phase_1(delta, sweeping_from_left, 0.5)
				$RightShipTarget.move_for_shooting_sweep_phase_1(delta, sweeping_from_left, 0.5)
			elif phase_2_sweeps_so_far == 2:
				$LeftShipTarget.move_for_shooting_sweep_phase_1(delta, true, 0.5)
				$RightShipTarget.move_for_shooting_sweep_phase_1(delta, false, 0.5)
			elif phase_2_sweeps_so_far == 3:
				#TODO: figure out different logic with Minons+Shooting to go to idle
				state = states.IDLE
				shooting_started = false
				phase_2_sweeps_so_far = 0
				choose_random_state()
	
	else:
		if seconds_elapsed_during_side_ship_shooting > 4.7:
			side_ships_can_shoot = false
			$LeftShipTarget.shoot_state = ShipTarget.SHOOT_STATES.DONE_SHOOTING
			$RightShipTarget.shoot_state = ShipTarget.SHOOT_STATES.DONE_SHOOTING
			left_ship.reset_rotation()
			right_ship.reset_rotation()
			left_ship_shooting_animation_player.frame = 5
			left_ship_shooting_animation_player.play_backwards()
			right_ship_shooting_animation_player.frame =5
			right_ship_shooting_animation_player.play_backwards()
			seconds_elapsed_during_side_ship_shooting = 0.0
			state = states.IDLE
			choose_random_state_with_delay(0.3)
		elif seconds_elapsed_during_side_ship_shooting > 2:
			right_ship_particles_1.emitting = false
			right_ship_particles_2.emitting = false
			left_ship_particles_1.emitting = false
			left_ship_particles_2.emitting = false
			side_ships_can_shoot = true
		elif seconds_elapsed_during_side_ship_shooting > 0.5:
			right_ship_particles_1.emitting = true
			right_ship_particles_2.emitting = true
			left_ship_particles_1.emitting = true
			left_ship_particles_2.emitting = true
		else:
			if !right_ship_shooting_animation_player.is_playing():
				right_ship_shooting_animation_player.play()
			if !left_ship_shooting_animation_player.is_playing():
				left_ship_shooting_animation_player.play()
		if side_ships_can_shoot:
			$LeftShipTarget.enable_shooting_movement_phase_1(1.95)
			$RightShipTarget.enable_shooting_movement_phase_1(1.95)
			if side_ships_should_shoot_this_frame && $CenterShip/CenterShipCharacterBody.hp > 0:
				sideships_fire_bullet()
				$GunSound.play()
				$BulletCooldown.start()
		else:
			if !shooting_started:
				shooting_started_from_left = player.global_position.x < 0
				shooting_started = true
				$LeftShipTarget.move_for_shooting_sweep_phase_1(delta, shooting_started_from_left, 0.5)
				$RightShipTarget.move_for_shooting_sweep_phase_1(delta, shooting_started_from_left, 0.5)

func sideships_fire_bullet():
	var left_bullet = side_ship_bullet_scene.instantiate()
	var right_bullet = side_ship_bullet_scene.instantiate()
	
	left_ship.randomize_rot()
	left_bullet.start(left_bullet_spawnpoint.global_position, Vector2.DOWN.rotated(left_ship_shooting_animation_player.global_rotation))
	left_ship.recoil()
	level.add_child(left_bullet)
	
	right_ship.randomize_rot()
	right_bullet.start(right_bullet_spawnpoint.global_position, Vector2.DOWN.rotated(right_ship_shooting_animation_player.global_rotation))
	right_ship.recoil()
	level.add_child(right_bullet)
	
	side_ships_should_shoot_this_frame = false

func _on_bullet_cooldown_timeout():
	side_ships_should_shoot_this_frame = true
	
func make_side_ships_charge():
	var first_ship_to_charge = randi_range(0, 1)
	if (first_ship_to_charge == 0):
		pick_ship_paths(left_ship)
		left_ship.start_charge() 
		$CenterShip/CenterShipCharacterBody/ShieldEmitterLeft.emitting = false
		var right_ship_charge_delay_timer: Timer = Timer.new()
		right_ship_charge_delay_timer.one_shot = true
		right_ship_charge_delay_timer.wait_time = second_side_ship_wait_time
		add_child(right_ship_charge_delay_timer)
		right_ship_charge_delay_timer.timeout.connect(func(): make_other_ship_charge_and_free_queue(right_ship, right_ship_charge_delay_timer))
		right_ship_charge_delay_timer.timeout.connect(func(): $CenterShip/CenterShipCharacterBody/ShieldEmitterRight.emitting = false)
		# this is pretty dumb but im tired, this disables/enables shield emitters when charging
		$CenterShip/CenterShipCharacterBody/ShieldEmitterLeftChargeTimer.timeout.connect(func(): $CenterShip/CenterShipCharacterBody/ShieldEmitterLeft.emitting = true)
		$CenterShip/CenterShipCharacterBody/ShieldEmitterLeftChargeTimer2.timeout.connect(func(): $CenterShip/CenterShipCharacterBody/ShieldEmitterRight.emitting = true)
		$CenterShip/CenterShipCharacterBody/ShieldEmitterLeftChargeTimer.start()
		$CenterShip/CenterShipCharacterBody/ShieldEmitterLeftChargeTimer2.start()
		right_ship_charge_delay_timer.start()
	else:
		pick_ship_paths(right_ship)
		right_ship.start_charge() 
		$CenterShip/CenterShipCharacterBody/ShieldEmitterRight.emitting = false
		var left_ship_charge_delay_timer: Timer = Timer.new()
		left_ship_charge_delay_timer.one_shot = true
		left_ship_charge_delay_timer.wait_time = second_side_ship_wait_time
		add_child(left_ship_charge_delay_timer)
		left_ship_charge_delay_timer.timeout.connect(func(): make_other_ship_charge_and_free_queue(left_ship, left_ship_charge_delay_timer))
		left_ship_charge_delay_timer.timeout.connect(func(): $CenterShip/CenterShipCharacterBody/ShieldEmitterLeft.emitting = false)
		# this is pretty dumb but im tired, this disables/enables shield emitters when charging
		$CenterShip/CenterShipCharacterBody/ShieldEmitterRightChargeTimer.timeout.connect(func(): $CenterShip/CenterShipCharacterBody/ShieldEmitterRight.emitting = true)
		$CenterShip/CenterShipCharacterBody/ShieldEmitterRightChargeTimer2.timeout.connect(func(): $CenterShip/CenterShipCharacterBody/ShieldEmitterLeft.emitting = true)
		$CenterShip/CenterShipCharacterBody/ShieldEmitterRightChargeTimer.start()
		$CenterShip/CenterShipCharacterBody/ShieldEmitterRightChargeTimer2.start()
		left_ship_charge_delay_timer.start()
		
func make_other_ship_charge_and_free_queue(second_ship, timer):
	pick_ship_paths(second_ship)
	second_ship.start_charge()
	timer.queue_free()

func pick_ship_paths(ship):
	var ship_string = "LeftShip" if ship == left_ship else "RightShip"
	var which_path_idx = get_marker_closest_player().name.substr(get_marker_closest_player().name.length() -1,1)
#	var new_rand_path_str = "LeftShip/LeftShipChargePath2D" + which_path_rand + "/LeftShipPathFollow2D" + which_path_rand
	var new_rand_path_str = ship_string + "/" + ship_string + "ChargePath2D" + which_path_idx + "/" + ship_string +"PathFollow2D" + which_path_idx
	var new_rand_path = get_node(new_rand_path_str)
	ship.reparent(new_rand_path)
		
func _on_idle_timer_timeout():
	state = states.IDLE
	
func _on_second_ship_charge_delay_timer_timeout():
	pass # Replace with function body.

func _on_ship_with_lightning_animation_finished():
	if lightning_animation.animation == "lightning_charge":
		lightning_sound_should_be_looping = true
		lightning_animation.play("lightning_fire")
		lightning_itself_animation.visible = true
		lightning_itself_animation.play()
		lightning_charge_finished = true

func _on_ship_with_lightning_animation_looped():
	if lightning_animation.animation == "lightning_fire":
		lightning_loop_count += 1
		if lightning_loop_count == number_of_lightning_loops:
			lightning_sound_should_be_looping = false
			lightning_charge_finished = false
			$CenterShip/CenterShipCharacterBody/ElectricityBeams/ElectrivityBeamsBody/LeftBeamCollision.disabled = true
			$CenterShip/CenterShipCharacterBody/ElectricityBeams/ElectrivityBeamsBody/RightBeamCollision.disabled = true
			lightning_animation.stop()
			lightning_itself_animation.stop()
			lightning_itself_animation.visible = false
			lightning_animation.animation = "lightning_charge"
			$CenterShip/CenterShipCharacterBody/ElectricityBeams.visible = false
			$CenterShip/CenterShipCharacterBody/AllButMouth.visible = true
			is_lightning_animation_playing = false
			lightning_loop_count = 0
#			state = states.IDLE
			lightning_complete = true

func loop_lightning_sound():
	if (frames_elapsed_during_lightning_sound == 0):
		$CenterShip/CenterShipCharacterBody/ElectricityBeams/LightningStrike.play()
	frames_elapsed_during_lightning_sound += 1
	if (frames_elapsed_during_lightning_sound == frames_per_lightning_sound):
		frames_elapsed_during_lightning_sound = 0

func _on_warning_glow_sprite_animation_looped():
	num_glow_animations_played +=1

func _on_minion_spawn_box_area_2d_body_exited(body):
	if body.is_in_group("minion"):
		body.call_deferred("reparent", get_parent())
		body.call_deferred("past_mouth_true")

func spawn_adds(delta):
	adds_timer += delta
	if adds_spawned > 2:
		adds_spawned = 0
	# if adds_timer > time between adds
	if adds_timer > SECONDS_PER_ADD:
		adds_timer = 0
		if adds_spawned < 2 && !(state in [states.DEAD, states.INTRO]):
			adds_spawned += 1
			var minion_spawn = level.minion.instantiate()
			minion_spawn.global_position = level.get_boss_adds_spawn_location_not_near_player()
			minion_spawn.make_non_boss_spawn()
			enemies_node.add_child(minion_spawn)
			if adds_spawned == 1:
				if add_should_spawn_boost:
					enemies_node.add_powerup_upon_death(minion_spawn, level.boost_powerup_scene)
				add_should_spawn_boost = !add_should_spawn_boost
			level.create_warning_arrow(level.find_child("PlayerShip"), minion_spawn, level.find_child("Camera2D"))
		elif adds_spawned == 2 && !(state in [states.DEAD, states.INTRO]): 
			adds_spawned += 1
			var blue_guy_spawn = level.blue_guy.instantiate()
			blue_guy_spawn.global_position = level.get_boss_adds_spawn_location_not_near_player()
			enemies_node.add_child(blue_guy_spawn)
			level.create_warning_arrow(level.find_child("PlayerShip"), blue_guy_spawn, level.find_child("Camera2D"))

func spawn_wanderers(delta):
	# spawn a cluster of x wanderers in succession, on the opposite side of the player in the boss arena
	# they should bounce off the play area
	wanderers_timer += delta
	if wanderers_timer > SECONDS_PER_WANDERER:
		for i in range(3):
			var wanderer_spawn = level.wanderer.instantiate()
			var offset = (Vector2.RIGHT * randi_range(0, 200)).rotated(randf_range(-PI, PI))
			wanderer_spawn.global_position = level.get_boss_adds_spawn_location_not_near_player() + offset
			
			level.create_warning_arrow(level.find_child("PlayerShip"), wanderer_spawn, level.find_child("Camera2D"))
			@warning_ignore("redundant_await")
			await get_tree().create_timer(SECONDS_BETWEEN_WANDERERS)
			enemies_node.add_child(wanderer_spawn)
		wanderers_timer = 0.0
