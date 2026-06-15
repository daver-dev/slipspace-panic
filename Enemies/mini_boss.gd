extends Node2D

@export var orb_scene : PackedScene
const MAX_SPEED = 6.0
const MAX_CHARGE_SPEED = 30.0
const ROTATION_SPEED = 5.2
const ROTATION_SPEED_AIMING = 9.0
const ROTATION_SPEED_CHARGING = 1.2
const SLOWDOWN_ACCELERATION = -3.0
const STRONG_THRUST = 3.0
const CHARGE_THRUST = 250.0
const START_HP = 10000
const ZERO_ANGLE_WINDOW = PI/15.0
const NUM_EVADES_UNTIL_CHARGE = 3
const VIBRATION_ROTATION_MAX = .1
const PARTS_EXPLODE_SPEED = 6.0
const ORB_EXPLODE_SPEED = 9.6
const PARTS_ROT_SPEED_LIMIT = 5.0
const ORB_SLOWDOWN_WEIGHT = .002
var num_evades_until_charge_remain = NUM_EVADES_UNTIL_CHARGE
var speed = 0.0
var acceleration = 0.0
var player
var level
var chase_destination
var nav_points = []
var upper_spawn_point:Marker2D
var lower_spawn_point:Marker2D
var top_left:Marker2D
var top_right:Marker2D
var bottom_right:Marker2D
var bottom_left:Marker2D
var top_wall
var bottom_wall
var left_wall
var right_wall
var rotation_goal = 0.0
var targeting_nodes = [] #dont delete, for homing missile tracking
enum states {SPAWNING=0, EVADING=1, CHARGE_AIMING=2, CHARGE_SHAKING=3, CHARGE=4, DYING=5, EXPLODING=6, DEAD=7}
var state = states.SPAWNING
var started = false
var hp = START_HP
var path_is_clear = false
var bomb_num = 0
var common
var shooting = true
var num_evading_since_charging = 0
var can_shake = false
var has_exploded = false
var done_dying = false
var explosions_array = []
var part1_rot_speed
var part2_rot_speed
var part3_rot_speed
var part4_rot_speed
var velocity5
var slowing_orb = false
var orb_slowing_factor = 1.0
var orb_vibrating = false
var dead = false
var camera
var adds_timer = 0.0
var adds_spawned = 0
var enemies_node: Node2D
var add_should_spawn_boost = false
var curr_nav_point:Marker2D
var should_check_for_other_miniboss = false
var timer_to_check_for_other_miniboss = 0.0
var SECONDS_PER_ADD = 1.0
var should_give_extra_boosts = false

# Called when the node enters the scene tree for the first time.
func _ready():
	camera = get_tree().get_first_node_in_group("camera")
	common = get_tree().get_first_node_in_group("enemy_shared")
	player = get_tree().get_first_node_in_group("player")
	level = get_tree().get_first_node_in_group("level")
	enemies_node = level.find_child("EnemiesNode2D")
	upper_spawn_point = level.find_child("IntermediateCenterMarker1")
	lower_spawn_point = level.find_child("IntermediateCenterMarker3")
	top_left = level.find_child("CornerMarker1")
	top_right = level.find_child("CornerMarker2")
	bottom_right = level.find_child("CornerMarker3")
	bottom_left = level.find_child("CornerMarker4")
	#save walls for distance checking to find out which way to turn
	top_wall = level.find_child("TopWall")
	left_wall = level.find_child("LeftWall")
	right_wall = level.find_child("RightWall")
	bottom_wall = level.find_child("BottomWall")
	chase_destination = Vector2(0.0,0.0)
	explosions_array = [
	$EnemyParts/expl1, $EnemyParts/expl2, $EnemyParts/expl3, $EnemyParts/expl4, $EnemyParts/expl5, $EnemyParts/expl6
	]
	explosions_array.shuffle()
	$SpawnSound.play()
	
	var marker_array = $".".find_children("Marker2D*")
	for m in marker_array:
		nav_points.append(m)
	curr_nav_point = nav_points[0]
	if global_position.y > 0:
		$EnemyParts.rotation_degrees = -90
#	#see which point player is closest too, and spawn boss at the other point
#	if upper_spawn_point.global_position.distance_to(player.global_position) > lower_spawn_point.global_position.distance_to(player.global_position):
#		$EnemyParts.global_position = upper_spawn_point.global_position
#	else:
#		$EnemyParts.global_position = lower_spawn_point.global_position
#		$EnemyParts.rotation_degrees = -90

func get_quadrant_in():
	var center_marker = level.find_child("CenterMarker")
	if $EnemyParts.global_position.x > center_marker.global_position.x:
		if $EnemyParts.global_position.y > center_marker.global_position.y:
			return 3
		else:
			return 2
	else:
		if $EnemyParts.global_position.y > center_marker.global_position.y:
			return 4
		else:
			return 1

func choose_evasion_dest():
	nav_points.shuffle()
	for nav_point in nav_points:
		if curr_nav_point != nav_point:
			curr_nav_point = nav_point
			chase_destination = curr_nav_point.position
			break
	
func handle_wall_hit():
	camera.screen_shake_rough(30)
	$WallHit.play()
	speed = -speed/4.0
	
#func get_angle_to_player():
#	var angle_to_player = $EnemyParts.global_position.direction_to(player.global_position).angle()
#	return angle_to_player
	
func hide_body_and_show_chunks():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	$StateLabel.text = states.keys()[state]
	spawn_adds(delta)
	
	if state == states.SPAWNING:
		#start up the full sized orb animation and change state to 
		#evading after spawn is complete and small orb animation has reached full size
		if !$EnemyParts/OrbSpriteStart.is_playing() and started:
			$EnemyParts/OrbSpriteStart.visible = false
			$EnemyParts/OrbSprite.visible = true
			$EnemyParts/OrbSprite.play()
			state = states.EVADING
			$EnemyParts/ThrusterParticlesLeft2.emitting = true
			$EnemyParts/ThrusterParticlesLeft1.emitting = true
			$EnemyParts/ThrusterParticlesRight1.emitting = true
			$EnemyParts/ThrusterParticlesRight2.emitting = true
			$EnemyParts/BodyCollisionShape2D.disabled = false
			$EvasionPhaseTimer.start()
			$ShotTimer.start()
			$ShootingTimer.start()
			
	elif state == states.EVADING:
		acceleration = STRONG_THRUST
		if !path_is_clear:
			choose_evasion_dest()
			path_is_clear = true
		if $EnemyParts.global_position.distance_to(chase_destination) < 150:
			path_is_clear = false
		#apply thrust acceleration and speed times delta (will also need a way to slow down
		speed += acceleration * delta
		speed = clampf(speed, 0, MAX_SPEED)
		var angle_to_dest = $EnemyParts.global_position.direction_to(chase_destination).angle() - $EnemyParts.global_rotation
		while angle_to_dest > PI:
			angle_to_dest += -2.0*PI
		while angle_to_dest < -PI:
			angle_to_dest += 2.0*PI
		$EnemyParts.rotation = lerpf($EnemyParts.rotation, $EnemyParts.rotation + angle_to_dest, delta * ROTATION_SPEED)
			
	elif state == states.CHARGE_AIMING:
		chase_destination = player.position
		#Slow down in straight direction until stopped
		if speed > 0:
			acceleration = SLOWDOWN_ACCELERATION
			speed += acceleration * delta
			if speed < 0.0:
				speed = 0.0
		
		#Rotate toward enemy while angle_to less than tolerance
		var angle_to_dest = $EnemyParts.global_position.direction_to(chase_destination).angle() - $EnemyParts.global_rotation
		while angle_to_dest >= PI:
			angle_to_dest += -2.0*PI
		while angle_to_dest <= -PI:
			angle_to_dest += 2.0*PI
		var aimed_at_player = absf(angle_to_dest) < ZERO_ANGLE_WINDOW
		$EnemyParts.global_rotation = lerpf($EnemyParts.global_rotation, $EnemyParts.global_rotation + angle_to_dest, delta * ROTATION_SPEED_AIMING)
		if (aimed_at_player):
			if state != states.DYING and state != states.EXPLODING:
				state = states.CHARGE_SHAKING
			$ShakeTimer.start()
			$ChargeUpSound.play(.04)
	
	elif state == states.CHARGE_SHAKING:
		chase_destination = player.position
		#Slow down in straight direction until stopped
		if speed > 0:
			acceleration = SLOWDOWN_ACCELERATION
			speed += acceleration * delta
			if speed < 0.0:
				speed = 0.0
		#Rotate toward enemy while angle_to less than tolerance
		var angle_to_dest = $EnemyParts.global_position.direction_to(chase_destination).angle() - $EnemyParts.global_rotation
		while angle_to_dest >= PI:
			angle_to_dest += -2.0*PI
		while angle_to_dest <= -PI:
			angle_to_dest += 2.0*PI
#		var aimed_at_player = absf(angle_to_dest) < ZERO_ANGLE_WINDOW
		$EnemyParts.global_rotation = lerpf($EnemyParts.global_rotation, $EnemyParts.global_rotation + angle_to_dest, delta * ROTATION_SPEED_AIMING)
		if can_shake:
			var vibration_rand = randf_range(-VIBRATION_ROTATION_MAX,VIBRATION_ROTATION_MAX)
			$EnemyParts/BodySprite.rotation = vibration_rand * (2.0 - $CanShakeTimer.time_left)
			$EnemyParts/OrbSprite.rotation = vibration_rand * (2.0 - $CanShakeTimer.time_left)
		
#		$EnemyParts/BodySprite.rotation += vibration_rand * delta
#		$EnemyParts/OrbSprite.rotation += vibration_rand * delta
#		if $EnemyParts/BodySprite.rotation < -VIBRATION_ROTATION_MAX:
#			$EnemyParts/BodySprite.rotation += -($EnemyParts/BodySprite.rotation + VIBRATION_ROTATION_MAX)
#			$EnemyParts/OrbSprite.rotation += -($EnemyParts/OrbSprite.rotation + VIBRATION_ROTATION_MAX)
#		elif $EnemyParts/BodySprite.rotation > VIBRATION_ROTATION_MAX:
#			$EnemyParts/BodySprite.rotation -= ($EnemyParts/BodySprite.rotation - VIBRATION_ROTATION_MAX)
#			$EnemyParts/OrbSprite.rotation -= ($EnemyParts/OrbSprite.rotation - VIBRATION_ROTATION_MAX)
		
	elif state == states.CHARGE:
		#TURNING LOGIC
		acceleration = CHARGE_THRUST
		speed += acceleration * delta
		speed = clampf(speed, 0, MAX_CHARGE_SPEED)
		var angle_to_dest = $EnemyParts.global_position.direction_to(chase_destination).angle() - $EnemyParts.global_rotation
		while angle_to_dest >= PI:
			angle_to_dest += -2.0*PI
		while angle_to_dest <= -PI:
			angle_to_dest += 2.0*PI
		$EnemyParts.global_rotation = lerpf($EnemyParts.global_rotation, $EnemyParts.global_rotation + angle_to_dest, delta * ROTATION_SPEED_CHARGING)
#		#apply thrust acceleration and speed times delta (will also need a way to slow down
#		speed += acceleration * delta
#		speed = clampf(speed, 0, MAX_CHARGE_SPEED)
		acceleration = CHARGE_THRUST
#		$EnemyParts.global_rotation = lerpf($EnemyParts.global_rotation, $EnemyParts.global_rotation + angle_to_dest, delta * ROTATION_SPEED_CHARGING)
			
	elif state == states.DYING:
		$ChunksNode2D.rotation = $EnemyParts.rotation
		$ChunksNode2D.position = $EnemyParts.position
		
		if $ChunksNode2D/CharacterBody2D5/OrbSpriteStart.frame == 12:
			$ChunksNode2D/CharacterBody2D5/OrbSpriteStart.visible = false
			$ChunksNode2D/CharacterBody2D5/OrbSpriteFinish.visible = true
			$ChunksNode2D/CharacterBody2D5/OrbSpriteFinish.play()
		
		if $EnemyParts/DyingBodySpriteStart.frame == 4:
			$EnemyParts/DyingBodySpriteStart.visible = false
			$EnemyParts/DyingBodySpriteFinish.visible = true
			$EnemyParts/DyingBodySpriteFinish.play()
			$EnemyParts/DyingBodySpriteStart.frame = 0
		if speed > 0:
			acceleration = SLOWDOWN_ACCELERATION
			speed += acceleration * delta
			if speed < 0.0:
				speed = 0.0
		elif can_shake:
			var vibration_rand = randf_range(-VIBRATION_ROTATION_MAX,VIBRATION_ROTATION_MAX)
			$EnemyParts/DyingBodySpriteFinish.rotation = vibration_rand * (2.0 - $CanShakeTimer.time_left)
			$ChunksNode2D/CharacterBody2D5/OrbSpriteFinish.rotation = vibration_rand * (2.0 - $CanShakeTimer.time_left)
		
		elif done_dying:
			#once flashing/shaking animation done, show/play explosion sprite
			#move and rotate chunks node to match miniboss position and rotation
			
			$EnemyParts/DyingBodySpriteFinish.visible = false
			$EnemyParts/BodyCollisionShape2D.disabled = true
			
			$ChunksNode2D/CharacterBody2D/Sprite2D.visible = true
			$ChunksNode2D/CharacterBody2D2/Sprite2D.visible = true
			$ChunksNode2D/CharacterBody2D3/Sprite2D.visible = true
			$ChunksNode2D/CharacterBody2D4/Sprite2D.visible = true
#			$ChunksNode2D/CharacterBody2D5/OrbSprite.frame = $EnemyParts/OrbSprite.frame
			
			
			$ChunksNode2D/CharacterBody2D/CollisionPolygon2D.disabled = false
			$ChunksNode2D/CharacterBody2D2/CollisionPolygon2D.disabled = false
			$ChunksNode2D/CharacterBody2D3/CollisionPolygon2D.disabled = false
			$ChunksNode2D/CharacterBody2D4/CollisionPolygon2D.disabled = false
			$ChunksNode2D/CharacterBody2D5/CollisionShape2D.disabled = false
			$ChunksNode2D/CharacterBody2D5/DeadlyOrbArea2D/CollisionShape2D.disabled = false
			
			
			part1_rot_speed = randf_range(-PARTS_ROT_SPEED_LIMIT, PARTS_ROT_SPEED_LIMIT)
			part2_rot_speed = randf_range(-PARTS_ROT_SPEED_LIMIT, PARTS_ROT_SPEED_LIMIT)
			part3_rot_speed = randf_range(-PARTS_ROT_SPEED_LIMIT, PARTS_ROT_SPEED_LIMIT)
			part4_rot_speed = randf_range(-PARTS_ROT_SPEED_LIMIT, PARTS_ROT_SPEED_LIMIT)
			
			$ChunksNode2D/ShatterParticlesBoss.set_emitting(true)
			$ExplodeSound.play()
			
			velocity5 = Vector2(ORB_EXPLODE_SPEED, 0).rotated($ChunksNode2D.rotation)
			$ChunksNode2D/CharacterBody2D5/StartSlowingDownBounce.start()
			
			state = states.EXPLODING
			$ChunksNode2D/RedShockwaveNode2D.start()
			
		
		
	elif state == states.EXPLODING:

		#assign random velocity, direction and rotation to each chunk
		$ChunksNode2D/CharacterBody2D/Sprite2D.rotate(part1_rot_speed*delta)
		$ChunksNode2D/CharacterBody2D/CollisionPolygon2D.rotate(part1_rot_speed*delta)
		var collision1 = $ChunksNode2D/CharacterBody2D.move_and_collide(Vector2(PARTS_EXPLODE_SPEED, 0).rotated($ChunksNode2D.rotation + PI*1.75))
		if collision1:
			if collision1.get_collider().is_in_group("Walls"):
				$ChunksNode2D/CharacterBody2D/Sprite2D.visible = false
				$ChunksNode2D/CharacterBody2D/EnemyExplosion.global_position = $ChunksNode2D/CharacterBody2D/Sprite2D.global_position
				$ChunksNode2D/CharacterBody2D/CollisionPolygon2D.disabled = true
				$ChunksNode2D/CharacterBody2D/EnemyExplosion.set_emitting(true)
				$ExplodeSound2.play()
		$ChunksNode2D/CharacterBody2D2/Sprite2D.rotate(part2_rot_speed*delta)
		$ChunksNode2D/CharacterBody2D2/CollisionPolygon2D.rotate(part2_rot_speed*delta)
		var collision2 = $ChunksNode2D/CharacterBody2D2.move_and_collide(Vector2(PARTS_EXPLODE_SPEED, 0).rotated($ChunksNode2D.rotation + PI*1.25))
		if collision2:
			if collision2.get_collider().is_in_group("Walls"):
				$ChunksNode2D/CharacterBody2D2/Sprite2D.visible = false
				$ChunksNode2D/CharacterBody2D2/EnemyExplosion.global_position = $ChunksNode2D/CharacterBody2D2/Sprite2D.global_position
				$ChunksNode2D/CharacterBody2D2/CollisionPolygon2D.disabled = true
				$ChunksNode2D/CharacterBody2D2/EnemyExplosion.set_emitting(true)
				$ExplodeSound2.play()
		$ChunksNode2D/CharacterBody2D3/Sprite2D.rotate(part3_rot_speed*delta)
		$ChunksNode2D/CharacterBody2D3/CollisionPolygon2D.rotate(part3_rot_speed*delta)
		var collision3 = $ChunksNode2D/CharacterBody2D3.move_and_collide(Vector2(PARTS_EXPLODE_SPEED, 0).rotated($ChunksNode2D.rotation + PI*0.75))
		if collision3:
			if collision3.get_collider().is_in_group("Walls"):
				$ChunksNode2D/CharacterBody2D3/Sprite2D.visible = false
				$ChunksNode2D/CharacterBody2D3/EnemyExplosion.global_position = $ChunksNode2D/CharacterBody2D3/Sprite2D.global_position
				$ChunksNode2D/CharacterBody2D3/CollisionPolygon2D.disabled = true
				$ChunksNode2D/CharacterBody2D3/EnemyExplosion.set_emitting(true)
				$ExplodeSound2.play()
		$ChunksNode2D/CharacterBody2D4/Sprite2D.rotate(part4_rot_speed*delta)
		$ChunksNode2D/CharacterBody2D4/CollisionPolygon2D.rotate(part4_rot_speed*delta)
		var collision4 = $ChunksNode2D/CharacterBody2D4.move_and_collide(Vector2(PARTS_EXPLODE_SPEED, 0).rotated($ChunksNode2D.rotation + PI*0.25))
		if collision4:
			if collision4.get_collider().is_in_group("Walls"):
				$ChunksNode2D/CharacterBody2D4/Sprite2D.visible = false
				$ChunksNode2D/CharacterBody2D4/CollisionPolygon2D.disabled = true
				$ChunksNode2D/CharacterBody2D4/EnemyExplosion.set_emitting(true)
				$ExplodeSound2.play()
				
		var collision5 = $ChunksNode2D/CharacterBody2D5.move_and_collide(velocity5)
		if collision5:
			if collision5.get_collider().is_in_group("Walls"):
				velocity5 = velocity5.bounce(collision5.get_normal())
			elif collision5.get_collider().is_in_group("player"):
				collision5.get_collider().set_killed_by(G.MINIBOSS_ORB_COLLISION)
				collision5.get_collider().die()
				
		if slowing_orb:
			orb_slowing_factor -= delta * ORB_SLOWDOWN_WEIGHT
			clampf(orb_slowing_factor,0,1.0)
			velocity5.x = velocity5.x * orb_slowing_factor
			velocity5.y = velocity5.y * orb_slowing_factor
		
		if orb_vibrating:
			var scale_increase_ratio = (3.5 - $ChunksNode2D/CharacterBody2D5/ExplodeTimer.time_left)/1.75
			$ChunksNode2D/CharacterBody2D5.scale.x = 1 + scale_increase_ratio
			$ChunksNode2D/CharacterBody2D5.scale.y = 1 + scale_increase_ratio
			if can_shake:
				var vibration_rand_x = randf_range(-VIBRATION_ROTATION_MAX,VIBRATION_ROTATION_MAX)*40.0
				var vibration_rand_y = randf_range(-VIBRATION_ROTATION_MAX,VIBRATION_ROTATION_MAX)*40.0
				$ChunksNode2D/CharacterBody2D5/OrbSpriteFinish.position.x = vibration_rand_x * (2.0 - $CanShakeTimer.time_left)
				$ChunksNode2D/CharacterBody2D5/OrbSpriteFinish.position.y = vibration_rand_y * (2.0 - $CanShakeTimer.time_left)
			
#	if state in [states.EVADING, states.CHARGE]:		
	var velocity = Vector2(speed, 0).rotated($EnemyParts.rotation)
	$EnemyParts.velocity = velocity / delta
	$EnemyParts.move_and_slide()
	if $EnemyParts.get_slide_collision_count():
		var collision = $EnemyParts.get_slide_collision(0)
	#	var collision = $EnemyParts.move_and_collide(velocity)
		if collision:
			if collision.get_collider().is_in_group("player"):
				if !collision.get_collider().invincible:
					collision.get_collider().set_killed_by(G.MINIBOSS_COLLISION)
					collision.get_collider().die()
#					start_evading()
#					shooting = false
			elif collision.get_collider().is_in_group("Walls") && state == states.DYING:
				speed = 0.0
				#break thrust into x and y components using a normalized vector for direction and move enemy
	#			var direction_vec = Vector2.RIGHT.rotated($EnemyParts.rotation).normalized()
	#			$EnemyParts.position.x += direction_vec.x * speed
	#			$EnemyParts.position.y += direction_vec.y * speed
	
	### Stuff to do each phase regardless of state ###
	if hp >=0:
		$HPLabel.text = str(hp)
	else:
		$HPLabel.text = str(0)
	$HPLabel.position.x = $EnemyParts.position.x
	$HPLabel.position.y = $EnemyParts.position.y -135
	$StateLabel.position.x = $EnemyParts.position.x
	$StateLabel.position.y = $EnemyParts.position.y -160
	$ShootingLabel.text = "shooting: " + str(shooting)
	$ShootingLabel.position.x = $EnemyParts.position.x
	$ShootingLabel.position.y = $EnemyParts.position.y -185
	

# spawns 2 minions then a blue guy on repeat
func spawn_adds(delta):
	timer_to_check_for_other_miniboss += delta
	# check for other miniboss every second and make the adds timer longer, 
	# if its the sole miniboss make the timer shorter.
	if timer_to_check_for_other_miniboss > 1.0:
		timer_to_check_for_other_miniboss = 0.0
		var enemies_children = enemies_node.get_children()
		var number_of_minibosses = 0
		for enemy in enemies_children:
			if enemy.is_in_group("miniboss") && !enemy.dead:
				number_of_minibosses += 1
		if number_of_minibosses > 1:
			should_give_extra_boosts = true
			SECONDS_PER_ADD = 3
		else:
			should_give_extra_boosts = false
			SECONDS_PER_ADD = 1.0
	
	adds_timer += delta
	if adds_spawned > 2:
		adds_spawned = 0
	# if adds_timer > time between adds
	if adds_timer > SECONDS_PER_ADD:
		adds_timer = 0
		if adds_spawned < 2 && !dead:
			adds_spawned += 1
			var minion_spawn = level.minion.instantiate()
			minion_spawn.global_position = level.get_a_vector_not_near_player()
			minion_spawn.make_non_boss_spawn()
			enemies_node.add_child(minion_spawn)
			if adds_spawned == 1:
				if add_should_spawn_boost:
					enemies_node.add_powerup_upon_death(minion_spawn, level.boost_powerup_scene)
				add_should_spawn_boost = !add_should_spawn_boost
			level.create_warning_arrow(level.find_child("PlayerShip"), minion_spawn, level.find_child("Camera2D"))
		elif adds_spawned == 2 && !dead: 
			adds_spawned += 1
			var blue_guy_spawn = level.blue_guy.instantiate()
			blue_guy_spawn.global_position = level.get_a_vector_not_near_player()
			enemies_node.add_child(blue_guy_spawn)
			if should_give_extra_boosts:
				enemies_node.add_powerup_upon_death(blue_guy_spawn, level.boost_powerup_scene)
			level.create_warning_arrow(level.find_child("PlayerShip"), blue_guy_spawn, level.find_child("Camera2D"))

func take_damage_parent(dmg):
	$EnemyParts/BodySprite.modulate = Color.RED
	$DamageVisualRevertTimer.start()
	hp -= dmg
	common.play_damage_sound2()
	if hp <= 0 and !dead:
		get_parent().child_died(self)
		PlaySession.set_beat_miniboss()
		dead = true
		$EnemyParts.dead = true
		die()

func get_death_position() -> Vector2:
	return $EnemyParts.global_position
		
func set_targeting_node_parent(t_node:Node2D):
	targeting_nodes.append(t_node)
		
func die():
	if targeting_nodes.size() > 0:
		for target in targeting_nodes:
			if (is_instance_valid(target)):
				target.notify_target_null()
	#explode
	state = states.DYING
	$DyingExplosionCloudTimer.start()
	$DeathSequenceTimer.start()
	
	$CanShakeTimer.start()
	can_shake = true
	
	#hide body sprite and orb sprite
	$EnemyParts/BodySprite.visible = false
	$EnemyParts/DyingBodySpriteStart.visible = true
	$EnemyParts/DyingBodySpriteStart.play()
	
	$ChunksNode2D.rotation = $EnemyParts.rotation
	$ChunksNode2D.position = $EnemyParts.position
	$EnemyParts/OrbSprite.visible = false
	$ChunksNode2D/CharacterBody2D5/OrbSpriteStart.visible = true
	$ChunksNode2D/CharacterBody2D5/OrbSpriteStart.play()
	
	
	shooting = false
	$ShotTimer.stop()
	$ShootingTimer.stop()
	$DontShootTimer.stop()
	$EvasionPhaseTimer.stop()
	$EnemyParts/ThrusterParticlesLeft2.emitting = false
	$EnemyParts/ThrusterParticlesLeft1.emitting = false
	$EnemyParts/ThrusterParticlesRight1.emitting = false
	$EnemyParts/ThrusterParticlesRight2.emitting = false
	#free assets

func _on_start_animation_timer_timeout():
	$EnemyParts/BodySprite.visible = true
	$EnemyParts/SpawnParticles.emitting = false
	$EnemyParts/SpawnParticles2.emitting = false
	$SpawnParticlesProbablyDone.start()

func _on_spawn_particles_probably_done_timeout():
	$EnemyParts/OrbSpriteStart.visible = true
	$EnemyParts/OrbSpriteStart.play()
	started = true
	$EnemyParts/SpawnParticles.queue_free()
	$EnemyParts/SpawnParticles2.queue_free()

func _on_damage_visual_revert_timer_timeout():
	$EnemyParts/BodySprite.modulate = Color.WHITE

func _on_detection_area_2d_body_entered(body):
	if body.is_in_group("player"):
		path_is_clear = false
	elif body.is_in_group("dest"):
		path_is_clear = false


func _on_shot_timer_timeout():
	if shooting and state == states.EVADING:
		var aimer = orb_scene.instantiate()
		aimer.set_parent(self)
		aimer.orb = $EnemyParts/OrbSprite
		level.add_child(aimer)

func _on_shooting_timer_timeout():
	shooting = false
	$DontShootTimer.start()

func _on_dont_shoot_timer_timeout():
	shooting = true
	$ShootingTimer.start()
	
func start_evading():
	state = states.EVADING
	$ShootingTimer.start()
	$EvasionPhaseTimer.start()
	shooting = true

func _on_evasion_phase_timer_timeout():
	num_evading_since_charging += 1
	if randi_range(0,12) + num_evading_since_charging > 6:
		if state != states.DYING and state != states.EXPLODING:
			state = states.CHARGE_AIMING
		shooting = false
#		$TemporaryTimer.start()
		$ShootingTimer.stop()
		$DontShootTimer.stop()
		num_evading_since_charging = 0
	else:
		start_evading()


func _on_enemy_parts_area_2d_body_entered(body):
	if state == states.CHARGE and body.is_in_group("Walls"):
		#boom sound effect scaled by speed
		#camera shake
		handle_wall_hit()
		speed = 0
		acceleration = 0
		start_evading()


func _on_can_shake_timer_timeout():
	can_shake = !can_shake

func _on_shake_timer_timeout():
	$ChargeUpSound.stop()
	$BlastSound.play(0.08)
	$EnemyParts/BodySprite.rotation = 0
	$EnemyParts/OrbSprite.rotation = 0
	if state != states.DYING and state != states.EXPLODING:
		state = states.CHARGE

func _on_death_sequence_timer_timeout():
	done_dying = true


func _on_dying_explosion_cloud_timer_timeout():
	if state == states.DYING:
		if !$EnemyParts/EnemyExplosion.emitting:
			common.play_explode_sound_2()
			var first = explosions_array.pop_front()
			explosions_array.push_back(first)
			$EnemyParts/EnemyExplosion.global_position = explosions_array[0].global_position
			$EnemyParts/EnemyExplosion.set_emitting(true)


func _on_start_slowing_down_bounce_timeout():
	slowing_orb = true
	$ChunksNode2D/CharacterBody2D5/StartVibratingTimer.start()


func _on_start_vibrating_timer_timeout():
	orb_vibrating = true
	$ChargeUpSound.play()
	$ChunksNode2D/CharacterBody2D5/ExplodeTimer.start()


func _on_explode_timer_timeout():
	$ChargeUpSound.stop()
	$ExplodeSound.play()
	$ChunksNode2D/CharacterBody2D5/OrbSpriteFinish.visible = false
	$ChunksNode2D/CharacterBody2D5/CollisionShape2D.disabled = true
	$ChunksNode2D/CharacterBody2D5/DeadlyOrbArea2D/CollisionShape2D.disabled = true
	$ChunksNode2D/CharacterBody2D5/RedShockwaveNode2D.start()
	$ChunksNode2D/CharacterBody2D5/ShatterParticlesOrange.set_emitting(true)
	$Timer.start()
	

func _on_deadly_orb_area_2d_body_entered(body):
	if body.is_in_group("player"):
		body.die()


func _on_timer_timeout():
	queue_free()
