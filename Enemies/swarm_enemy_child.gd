extends Area2D

const DISTANCE_FOR_RETARGET = 0.1
const START_RADIUS = 120.0
const START_SPEED = 350.0
const STUCK_RADIUS = 33.0
const STUCK_SPEED = 10.0
#const SWARM_RADIUS = 120.0
var swarm_radius = START_RADIUS
#const SWARM_SPEED = 700.0
var swarm_speed = START_SPEED
var hp = 50
var dead = false
var spawning = true
var stuck_to_ship = false
var spawn_time = 0.5
var targeting_nodes = []
var hive_mother
var chase_position
var enemy_shared
var player_ship

func _ready():
	#for non-gravity games (I think)
#	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	$Sprite2D.modulate.a = 0
	enemy_shared = get_tree().get_first_node_in_group("enemy_shared")
	var rand_pos_vector = Vector2(randi_range(swarm_radius/3.0,swarm_radius/2.0), 0).rotated(randf_range(0.0, 2*PI))
	position.x = rand_pos_vector.x
	position.y = rand_pos_vector.y
	chase_position = Vector2(randi_range(swarm_radius/3.0,swarm_radius), 0).rotated(randf_range(0.0, 2*PI))
	look_at(chase_position)
	
func reset_speed_and_radius():
	swarm_radius = START_RADIUS
	swarm_speed = START_SPEED

func take_damage(damage):
	if !dead:
		enemy_shared.play_damage_sound()
		$Sprite2D.modulate = Color.RED
		if $DamageVisualRevertTimer.is_stopped():
			$DamageVisualRevertTimer.start()
		hp -= damage
		if hp <= 0:
			die()

#store a reference of a missile targeting enemy, for notifying that missile when we die, so it can track a new enemy
func set_targeting_node(t_node:Node2D):
	targeting_nodes.append(t_node)

func die():
	if !dead:
		dead = true
		if targeting_nodes.size() > 0:
			for target in targeting_nodes:
				if (is_instance_valid(target)):
					target.notify_target_null()
		$DamageVisualRevertTimer.stop()
		$Sprite2D.visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		$ShatterParticles.emitting = true
		$EnemyExplosion.emitting = true
		#different sound needed
		enemy_shared.play_explode_sound_4()

func _on_damage_visual_revert_timer_timeout():
	$Sprite2D.modulate = Color.WHITE
	
func reset_positions_after_stick():
	swarm_radius = STUCK_RADIUS
	swarm_speed = STUCK_SPEED
	if position.length() > swarm_radius:
		position = Vector2(randi_range(swarm_radius/3.0,swarm_radius), 0).rotated(randf_range(0.0, 2*PI))
	if chase_position.length() > swarm_radius:
		chase_position = Vector2(randi_range(swarm_radius/3.0,swarm_radius), 0).rotated(randf_range(0.0, 2*PI))

func _physics_process(delta):
	if !spawning:
		if !dead:
#			global_position = parent.global_position + Vector2(randi_range(0,SWARM_RADIUS), 0).rotated(randf_range(0.0, 2*PI))
			position.x = move_toward(position.x, chase_position.x, delta * swarm_speed)
			position.y = move_toward(position.y, chase_position.y, delta * swarm_speed)
			look_at(chase_position)
			if (chase_position - position).length() < DISTANCE_FOR_RETARGET:
				chase_position = Vector2(randi_range(swarm_radius/3.0,swarm_radius), 0).rotated(randf_range(0.0, 2*PI))
		else:
			hive_mother.children.erase(self)
			if !$ShatterParticles.emitting and !$EnemyExplosion.emitting:
				queue_free()
	else:
		spawn_time -= delta
		if spawn_time < 0 && spawning:
			spawning = false
			$CollisionShape2D.disabled = false
			$Sprite2D.visible = true
			var mod_tween = create_tween()
			mod_tween.tween_property($Sprite2D, 'modulate:a', 1.0, 0.5)
			

func _on_body_entered(body):
#	if body.is_in_group("player") and body.invincible:
	if body.is_in_group("player"):
		if body.invincible:
			die()
		elif !stuck_to_ship:
			stuck_to_ship = true
			call_deferred("reparent", player_ship)
			call_deferred("reset_positions_after_stick")	
