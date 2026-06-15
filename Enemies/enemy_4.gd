extends CharacterBody2D

@onready var common = get_tree().get_first_node_in_group("enemy_shared")

var dead = false
var hp = 50
var spawning = true
var spawn_time = 0.5
var speed = 300
var targeting_nodes = []

func _ready():
	var spin_choice = ["spin_left","spin_right"].pick_random()
	var initial_direction = randf_range(0, 2*PI)
	velocity = Vector2.from_angle(initial_direction) * speed
	$AnimationPlayer.play(spin_choice)
	common.play_spawn_sound_1()
	
func _physics_process(delta):
	if !spawning:
		if !dead:
			var collision = move_and_collide(velocity * delta)
			if collision:
				if collision.get_collider().is_in_group("player"):
					if !collision.get_collider().invincible:
						collision.get_collider().set_killed_by(G.WANDERER_COLLISION)
						collision.get_collider().die()
					die()
				if collision.get_collider().is_in_group("Walls") || collision.get_collider().is_in_group("BossArena"):
					velocity = velocity.bounce(collision.get_normal())
				else:
					move_and_slide()
		else:
			queue_free()
	else:
		#spawning logic
		spawn_time -= delta
		if spawn_time < 0:
			spawning = false
			if is_instance_valid(self):
				$CollisionPolygon2D.disabled = false
				$AnimatedSprite2D.visible = true
				$SpawnParticles.emitting = false

func set_targeting_node(t_node:Node2D):
	targeting_nodes.append(t_node)
	
func take_damage(damage):
	# not sure if this should be a one shot kill or not yet
#	$AnimatedSprite2D.modulate = Color.RED
#	$DamageVisualRevertTimer.start()
	hp -= damage
	if hp <= 0:
		if targeting_nodes.size() > 0:
			for target in targeting_nodes:
				if (is_instance_valid(target)):
					target.notify_target_null()
		die()

func die():
	if !dead:
		get_parent().child_died(self)
#		$AnimatedSprite2D.queue_free()
		$DamageVisualRevertTimer.stop()
#		$DamageVisualRevertTimer.queue_free()
		$CollisionPolygon2D.set_deferred("disabled", true)
		#reparent particles two nodes up
		var shatter_particles = $ShatterParticles
		shatter_particles.reparent(get_parent().get_parent())
		var explosion_particles = $EnemyExplosion
		explosion_particles.reparent(get_parent().get_parent())
		shatter_particles.emitting = true
		explosion_particles.emitting = true
		
		common.play_explode_sound_1()
		dead = true

func _on_damage_visual_revert_timer_timeout():
	$Sprite2D.modulate = Color.WHITE
