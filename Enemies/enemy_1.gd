extends CharacterBody2D

const SPEED = 300.0
#const DISTANCE_TO_ENABLE_RETREAT = 300
const DISTANCE_TO_ENABLE_RETREAT = 400 #was 500 TODO:review
#const WEAPON_COOLDOWN_SHORT = 0.27
const WEAPON_COOLDOWN_SHORT = 0.3
#const SHOT_RANDOMIZER_VALUE = 0.03
const WEAPON_COOLDOWN_LONG = WEAPON_COOLDOWN_SHORT * 3.0
const SHOT_RANDOMIZER_VALUE = 0.5
const NUM_BURST_SHOTS = 1
const ANIMATION_STEP_PER_FRAME := 0.1
var hp = 50
var lerp_rotation = 100.0
var dead = false
var shoot_angle_window = PI/10.0
var max_ship_rotation = PI
var spawning = true
var spawn_time = 0.5
var shots_until_long_cooldown = NUM_BURST_SHOTS
var targeting_nodes = []
var chase_position
var retreating = false
var can_shoot = false
var thing_to_chase:Area2D
@onready var float_ani_frame:float = $Sprite2D.frame
@onready var common = get_tree().get_first_node_in_group("enemy_shared")
@export var enemy_bullet_1_scene : PackedScene
	
func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	#save ref of retreat target before moving the node to the Level tree
	thing_to_chase = $ThingToChase
	move_thing_to_chase_to_level()
	#store ship position for chasing
	chase_position = get_parent().get_parent().get_last_ship_pos()
	#make enemies spawn facing player
	look_at(chase_position)
	#set initial delay to start firing at player plus a randomizer so multiple enemies spawned at the same time dont shoot at identical times
	$WeaponCooldown.wait_time = WEAPON_COOLDOWN_LONG + randf_range(-SHOT_RANDOMIZER_VALUE, SHOT_RANDOMIZER_VALUE)
	$WeaponCooldown.start()
	common.play_spawn_sound_1()

#move retreat chase object to level
func move_thing_to_chase_to_level():
	thing_to_chase.get_parent().remove_child(thing_to_chase)
	get_tree().get_first_node_in_group("level").add_child(thing_to_chase)
	
func take_damage(damage):
	$Sprite2D.modulate = Color.RED
	$DamageVisualRevertTimer.start()
	hp -= damage
	if hp <= 0:
		die()

#method for taking damage and possibly dying (bad name I suppose)
func die():
	if !dead:
		get_parent().child_died(self)
		if targeting_nodes.size() > 0:
			for target in targeting_nodes:
				if (is_instance_valid(target)):
					target.notify_target_null()
		thing_to_chase.queue_free()
		$DamageVisualRevertTimer.stop()
		$CollisionPolygon2D.set_deferred("disabled", true)
		$ThrusterParticles.emitting = false
		
		var shatter_particles = $ShatterParticles
		shatter_particles.reparent(get_parent().get_parent())
		var explosion_particles = $EnemyExplosion
		explosion_particles.reparent(get_parent().get_parent())
		shatter_particles.emitting = true
		explosion_particles.emitting = true
		
		
		common.play_explode_sound_1()
		dead = true

#store a reference of a missile targeting enemy, for notifying that missile when we die, so it can track a new enemy
func set_targeting_node(t_node:Node2D):
	targeting_nodes.append(t_node)
	
func shoot():
	var b1 = enemy_bullet_1_scene.instantiate()
	b1.add_to_group("blueguy_bullet")
	get_tree().root.add_child(b1)
	b1.start($GunMarker.global_position, Vector2(cos(rotation), sin(rotation)))
	common.play_shoot_sound_1()

func _on_damage_visual_revert_timer_timeout():
	$Sprite2D.modulate = Color.WHITE

func _on_retreat_timer_timeout():
	retreating = false

func _on_weapon_cooldown_timeout():
	can_shoot = true

func _physics_process(delta):
	if !spawning:
		if !dead:
			if retreating:
				chase_position = thing_to_chase.global_position
			else:
#				chase_position = get_parent().get_last_ship_pos()
				var ship:PlayerShip = get_parent().get_parent().get_player()
				chase_position = ship.get_speed_lead_target_position(global_position)
			#for adding some rubber banding for enemy to turn toward target to seem less robotic...still needs tuning,
			#and for knowing whether the enemy has a chance to hit the player with their shot so they dont just fire at walls like dipshits
			var angle_diff_to_chase_position = get_angle_to(chase_position)
			if abs(angle_diff_to_chase_position) > max_ship_rotation * delta:
				if angle_diff_to_chase_position < 0:
					angle_diff_to_chase_position = -max_ship_rotation * delta
				else:
					angle_diff_to_chase_position = max_ship_rotation * delta
			rotation = lerp_angle(rotation, rotation + angle_diff_to_chase_position, lerp_rotation * delta)
			velocity = Vector2(SPEED,0).rotated(rotation)
			#choose animation frame
#			var last_frame = $Sprite2D.frame
			if abs(angle_diff_to_chase_position) > 0.025:
				if angle_diff_to_chase_position < 0.0:
#					$Sprite2D.frame = 0
					float_ani_frame = move_toward(float_ani_frame, 0.0, ANIMATION_STEP_PER_FRAME)
				else:
#					$Sprite2D.frame = 8
					float_ani_frame = move_toward(float_ani_frame, 8.0, ANIMATION_STEP_PER_FRAME)
			elif abs(angle_diff_to_chase_position) > 0.018:
				if angle_diff_to_chase_position  < 0.0:
#					$Sprite2D.frame = 1
					float_ani_frame = move_toward(float_ani_frame, 1.0, ANIMATION_STEP_PER_FRAME)
				else:
#					$Sprite2D.frame = 7
					float_ani_frame = move_toward(float_ani_frame, 7.0, ANIMATION_STEP_PER_FRAME)
			elif abs(angle_diff_to_chase_position) > 0.012:
				if angle_diff_to_chase_position < 0.0:
#					$Sprite2D.frame = 2
					float_ani_frame = move_toward(float_ani_frame, 2.0, ANIMATION_STEP_PER_FRAME)
				else:
#					$Sprite2D.frame = 6
					float_ani_frame = move_toward(float_ani_frame, 6.0, ANIMATION_STEP_PER_FRAME)
			elif abs(angle_diff_to_chase_position) > 0.008:
				if angle_diff_to_chase_position < 0.0:
#					$Sprite2D.frame = 3
					float_ani_frame = move_toward(float_ani_frame, 3.0, ANIMATION_STEP_PER_FRAME)
				else:
#					$Sprite2D.frame = 5
					float_ani_frame = move_toward(float_ani_frame, 5.0, ANIMATION_STEP_PER_FRAME)
			else:
#				$Sprite2D.frame = 4
				float_ani_frame = move_toward(float_ani_frame, 4.0, ANIMATION_STEP_PER_FRAME)
			$Sprite2D.frame = int(float_ani_frame)
#			assert($Sprite2D.frame == last_frame || $Sprite2D.frame == last_frame +1 || $Sprite2D.frame == last_frame -1, "prev_frame: " + str(last_frame) + ", this_frame: " + str($Sprite2D.frame))
			#multiple checks before firing a bullet
			if can_shoot and !retreating and shots_until_long_cooldown > 0 and abs(get_angle_to(chase_position)) < shoot_angle_window and get_tree().get_first_node_in_group("player").is_alive == true:
				shoot()
				shots_until_long_cooldown -= 1
				#two different cooldowns which allows burst shooting
				if shots_until_long_cooldown > 0:
					$WeaponCooldown.wait_time = WEAPON_COOLDOWN_SHORT + randf_range(-SHOT_RANDOMIZER_VALUE, SHOT_RANDOMIZER_VALUE)
					$WeaponCooldown.start()
					can_shoot = false
				else:
					can_shoot = false
					$WeaponCooldown.wait_time = WEAPON_COOLDOWN_LONG + randf_range(-SHOT_RANDOMIZER_VALUE, SHOT_RANDOMIZER_VALUE)
					$WeaponCooldown.start()
					shots_until_long_cooldown = NUM_BURST_SHOTS
			#check for getting close to player to enable retreat, aka targeting thing_to_chase that is bouncing around the map invisibly
			if !retreating and self.global_position.distance_to(get_parent().get_parent().get_last_ship_pos()) < DISTANCE_TO_ENABLE_RETREAT:
				retreating = true
				$WeaponCooldown.stop()
				can_shoot = true
				#fill burst shots again so it doesn't come out of retreat and have less than a full burst number
				shots_until_long_cooldown = NUM_BURST_SHOTS
				$RetreatTimer.start()
				#move thing_to_chase behind enemy ship at marker2d position as long as its in the play area. This prevents most cases of the enemy from retreating toward the player by coincidence if the thing_to_chase is behind the player ship
				var play_area = get_tree().get_first_node_in_group("PlayArea")
				if $RetreatMarker2D.global_position.x >= play_area.global_position.x - (play_area.get_child(0).get_shape().get_rect().size.x)/2.0 and $RetreatMarker2D.global_position.x <= play_area.global_position.x + (play_area.get_child(0).get_shape().get_rect().size.x)/2.0:
					if $RetreatMarker2D.global_position.y >= play_area.global_position.y - (play_area.get_child(0).get_shape().get_rect().size.y)/2.0 and $RetreatMarker2D.global_position.y <= play_area.global_position.y + (play_area.get_child(0).get_shape().get_rect().size.y)/2.0:
						thing_to_chase.global_position = $RetreatMarker2D.global_position
		
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
					collision.get_collider().set_killed_by(G.BLUE_GUY_COLLISION)
					collision.get_collider().die()
			else:
				move_and_slide()
	else:
		#spawning logic
		spawn_time -= delta
		if spawn_time < 0 && is_instance_valid(self):
			spawning = false
			$CollisionPolygon2D.disabled = false
			$Sprite2D.visible = true
			$SpawnParticles.emitting = false
			$ThrusterParticles.emitting = true
