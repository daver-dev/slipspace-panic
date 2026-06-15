extends Node2D

@onready var raycast = $RayCast2D
@onready var target: CharacterBody2D = get_tree().get_first_node_in_group('boss_target')
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group('player')
@onready var boss: CharacterBody2D = get_tree().get_first_node_in_group('boss')
@onready var left_ship: SideShip = $"../../LeftShip/LeftShipChargePath2D5/LeftShipPathFollow2D5/LeftShipCharacterBody"
@onready var right_ship: SideShip = $"../../RightShip/RightShipChargePath2D5/RightShipPathFollow2D5/RightShipCharacterBody"

const explosion:PackedScene = preload("res://Enemies/enemy_explosion.tscn")
const red_explosion:PackedScene = preload("res://Enemies/enemy_explosion_red.tscn")

const START_HP = 30000
const DAMAGED_HP = 200
const DELAY_BETWEEN_EXPLOSION = 0.5
var radius = 4
var speed = 2
var angle = 0
var common
var hp = START_HP
var damaged
var dead
var shield_enabled
var sprite_children
#var can_become_damaged
var chain_exploded = false
var done_shaking = false
var shake_x_offset = 0.0
var shake_y_offset = 0.0
var has_minions_and_side_ships_deadified = false
var death_sequence_started := false

var explosions_array = [
	Vector2(-90.0,80.0),
	Vector2(60.0,40.0),
	Vector2(33.0,-90.0),
	Vector2(-83.0,-20.0),
	Vector2(0.0,100.0),
	Vector2(-90.0,80.0),
	Vector2(60.0,40.0),
	Vector2(33.0,-90.0),
	Vector2(-83.0,-20.0),
	Vector2(0.0,100.0),
	]
	
func _ready():
	common = get_tree().get_first_node_in_group("enemy_shared")
	damaged = false
	dead = false
	shield_enabled = true
	sprite_children = get_child(2).get_children()
#	var can_become_damaged = true

func _physics_process(delta):
	# these cases handle circular wobble and rotation
	var aim_position = global_position.direction_to(target.global_position)
	if boss.state == boss.states.INTRO:
#		no rotation
		angle -= speed * delta
		var x = cos(angle)
		var y = sin(angle)
		position.x = radius * x
		position.y = radius * y
#	if boss.state == boss.states.DEAD:
#		global_rotation = lerpf(global_rotation, aim_position.angle() - PI/2, 0.08)
#		angle -= speed * delta
#		var x = cos(angle)
#		var y = sin(angle)
#		position.x = lerpf(position.x, radius * x, 0.5)
#		position.y = lerpf(position.y, radius * y, 0.5)
	elif boss.state in [
		boss.states.IDLE, 
		boss.states.MINIONS, 
		boss.states.SIDE_SHIPS_SHOOTING,
		boss.states.SIDE_SHIPS_CHARGE,
		boss.states.SIDE_SHIPS_SHOOTING_AND_MINIONS,
		boss.states.LIGHTNING_AND_MINIONS, #Moved here for testing with rotation
		]:
			if !done_shaking:
	#			global_rotation = lerpf(global_rotation, aim_position.angle() - PI/2, 0.02)
				global_rotation = lerpf(global_rotation, aim_position.angle() - PI/2, 0.08)
				angle -= speed * delta
				var x = cos(angle)
				var y = sin(angle)
				position.x = radius * x
				position.y = radius * y
	#			$ShieldEmitterLeft.emitting = false
	#			$ShieldEmitterRight.emitting = false
	elif boss.state in [
		boss.states.LIGHTNING,
#		boss.states.LIGHTNING_AND_MINIONS, 
		boss.states.LIGHTNING_AND_SIDE_SHIPS_SHOOTING, 
		boss.states.LIGHTNING_AND_SIDE_SHIPS_CHARGE
		]:
			# TODO: revisit with slow computer
			global_rotation = lerpf(global_rotation, 0, 0.02)
			# Lerp the aim position from the current  to point straight down
#----------------------------------------
	if !left_ship.damaged:
		$ShieldEmitterLeft.global_position = left_ship.get_origin_marker_location()
		$ShieldEmitterLeft.look_at(self.global_position)
	else:
		$ShieldEmitterLeft.emitting = false
	if !right_ship.damaged:
		$ShieldEmitterRight.global_position = right_ship.get_origin_marker_location()
		$ShieldEmitterRight.look_at(self.global_position)
	else:
		$ShieldEmitterRight.emitting = false
		
	
	if hp < DAMAGED_HP && !damaged:
		become_damaged()
	if hp < 1 && !dead:
		hp = 0
		die()

func take_damage(dmg):
	if !dead && hp > 0:
		hp -= dmg
		get_child(1).self_modulate = Color.RED
		$ElectricityBeams/ShipWithLightningAnimation.self_modulate = Color.RED
		for child in sprite_children:
			child.self_modulate = Color.RED
		$DamageVisualRevertTimer.start()
		common.play_damage_sound2()

func flash_forcefield():
	$ForceFieldArea2D/ForceFieldAnimatedSprite2D.visible = true
	$ForceFieldArea2D/ForceFieldAnimatedSprite2D.play()
	common.play_ping_sound()

func reset_sprite_modulate():
	$ElectricityBeams/ShipWithLightningAnimation.self_modulate = Color.WHITE
	get_child(1).self_modulate = Color.WHITE
	for child in sprite_children:
		child.self_modulate = Color.WHITE
	
func _on_force_field_area_2d_area_entered(area):
	if area.is_in_group("missile"):
		flash_forcefield()
		area.explode()
		area.die()
	elif area.is_in_group("crescent"):
		flash_forcefield()
		area.get_parent().queue_free()
	elif area.is_in_group("bullet"):
		flash_forcefield()
		area.queue_free()

func become_damaged():
	damaged = true

func die():
	if !death_sequence_started:
		PlaySession.set_beat_boss()
		get_parent().get_parent().get_parent().get_parent().fade_out_boss_music()
		death_sequence_started = true
	target.position_should_freeze = true
	$AllButMouth.visible = false
	$"6-mouth".visible = false
	$ElectricityBeams.visible = false
	$WarningGlowSprite.visible = false
	if !has_minions_and_side_ships_deadified:
		left_ship.disable_collision()
		right_ship.disable_collision()
		get_tree().call_group('minion', 'take_damage')
		has_minions_and_side_ships_deadified = true
	# reset last shaken position
	position.x = position.x - shake_x_offset
	position.y = position.y - shake_y_offset
	shake_y_offset = randf_range(-4.0, 4.0)
	shake_x_offset = randf_range(-4.0, 4.0)
	if !chain_exploded:
		chain_explosions()
		get_tree().create_timer(5.0).timeout.connect(func(): done_shaking = true)
		# need to start particle emitting slightly before the explosion for 1 and 2 while keeping them invis
		# because the effect looks weird for the first half second
		get_tree().create_timer(4.9).timeout.connect(show_final_explosion)
	chain_exploded = true
	if !done_shaking:
		# apply new shaken position
		position.x = position.x + shake_x_offset
		position.y = position.y + shake_y_offset
	else:
		# final explosion
		# see emit_ring_explosion connection on timer above for explanation of this visibility stuff
		$"../DeathSplosion".modulate = Color(1,1,1,1)
		$"../DeathSplosion2".modulate = Color(1,1,1,1)
		$"../DeathSplosion3".emitting = true
		$"../DeathSplosion4".emitting = true
		$"../DeathSplosion5".emitting = true
		$"../DeathSplosion6".emitting = true
		$"../DeathSplosion7".emitting = true
		
		$MinionSiren.volume_db = -80
		$DeathSound.play()
		$DeathSound2.play()
		common.play_explode_sound_5()
		get_tree().get_first_node_in_group("level").fade_out_forcefield()
		left_ship.state = left_ship.states.DEAD
		right_ship.state = right_ship.states.DEAD
		for effect in left_ship.smoke_and_ember:
			effect.visible = false
		for effect in right_ship.smoke_and_ember:
			effect.visible = false
			
		$"../../ShipHoverSound".stop()	
		$"../../ShipHoverSound2".stop()
		disperse_chunks([1,2,3,5,6,7,8,10,11,12,13,15])
		var ship_tween = create_tween()
		ship_tween.tween_property(left_ship, 'position:y', 1500, 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ship_tween.parallel().tween_property(right_ship, 'position:y', -1500, 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ship_tween.parallel().tween_property(right_ship, 'global_rotation', right_ship.global_rotation + 12, 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ship_tween.parallel().tween_property(left_ship, 'global_rotation', right_ship.global_rotation - 12, 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		$CenterShipCollisionArea2D/CenterShipCollisionPolygon2D.disabled = true
		get_tree().get_first_node_in_group("camera").normal()
		dead = true
		$"../..".hud.boss_defeated_stuff()

# Disperse all chunk numbers in the given range to their targets
func disperse_chunks(my_range):
	var chunk_tween = create_tween()
	for i in my_range:
		var chunk_node = get_node("ExplodedChunks/Sprites/Chunk%d" % i)
		var marker_node = get_node("ExplodedChunks/DestinationMarkers/Marker%d" % i)
		var random_seconds = randi_range(3,10)
		chunk_tween.parallel().tween_property(chunk_node, "position", marker_node.position, random_seconds ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		var random_rot = randi_range(1, 50) * (randi() % 2 * 2 - 1)
		
		chunk_tween.parallel().tween_property(chunk_node, "rotation", random_rot, random_seconds + 200 ).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
func show_final_explosion():
	$"../DeathSplosion".emitting = true
	$"../DeathSplosion2".emitting = true
	
func chain_explosions():
	for i in range(explosions_array.size()):
		single_explosion(explosions_array[i], i * DELAY_BETWEEN_EXPLOSION + randf_range(-0.2,0.2), i)
	
func single_explosion(location:Vector2, delay:float, explosion_number):
	$ExplodedChunks.visible = true
	await get_tree().create_timer(delay).timeout
	var explosion_instance = explosion.instantiate()
	var red_explosion_instance = red_explosion.instantiate()
	explosion_instance.amount = 100
	explosion_instance.transform.scaled(Vector2(1.5, 1.5))
	red_explosion_instance.transform.scaled(Vector2(2, 2))
	add_child(explosion_instance)
	add_child(red_explosion_instance)
	explosion_instance.position = location
	explosion_instance.emitting = true
	red_explosion_instance.position = location
	red_explosion_instance.emitting = true
	if explosion_number == 3:
		disperse_chunks([14])
	if explosion_number == 5:
		disperse_chunks([9])
	if explosion_number == 7:
		disperse_chunks([4])
	common.play_explode_sound_5()
	get_tree().create_timer(0.7).timeout.connect(Callable(explosion_instance, "queue_free"))
	get_tree().create_timer(1).timeout.connect(Callable(red_explosion_instance, "queue_free"))
	
func _on_force_field_animated_sprite_2d_animation_finished():
	$ForceFieldArea2D/ForceFieldAnimatedSprite2D.visible = false
	
func _on_center_ship_collision_area_2d_area_entered(area):
	if area.is_in_group("missile"):
		area.explode()
		area.die()
	elif area.is_in_group("crescent"):
		area.get_parent().queue_free()
	elif area.is_in_group("bullet"):
		area.queue_free()

func _on_damage_visual_revert_timer_timeout():
	reset_sprite_modulate()
