extends Node2D
@export var enemy_bullet_1_scene : PackedScene

const MAX_ANG_VELOCITY = PI * 3.3
const GUN_ROTATION_DEG = 184
const POINT_VALUE = 500
const SPIN_SOUND_MAX_PITCH = 1.5

var health = 1000
var current_gun_rotation = 0
var ang_velocity = 0.0
var phase = 1
var gun_can_rotate = true
var can_shoot = true
var dead = false
var spawning = true
var spawn_time = 0.5
var targeting_nodes = []
@onready var common = get_tree().get_first_node_in_group("enemy_shared")

# Called when the node enters the scene tree for the first time.
func _ready():
	$SoundTimer.wait_time = spawn_time
	$SoundTimer.start()
	common.play_spawn_sound_3()

func die():
	take_damage(10000)
	
func take_damage(damage):
	health -= damage
	$DamageVisualsNode2D.start_visuals()
	if health <= 0:
		if !dead:
			get_parent().child_died(self)
			if targeting_nodes.size() > 0:
				for target in targeting_nodes:
					if (is_instance_valid(target)):
						target.notify_target_null()
			$Gun1Node2D/Gun1Sprite2D.visible = false
			$Gun1Node2D/Gun1HingeSprite2D.visible = false
			$Gun2Node2D/Gun2Sprite2D.visible = false
			$Gun2Node2D/Gun2HingeSprite2D.visible = false
			$Gun3Node2D/Gun3Sprite2D.visible = false
			$Gun3Node2D/Gun3HingeSprite2D.visible = false
			$Gun4Node2D/Gun4Sprite2D.visible = false
			$Gun4Node2D/Gun4HingeSprite2D.visible = false
			$Gun5Node2D/Gun5Sprite2D.visible = false
			$Gun5Node2D/Gun5HingeSprite2D.visible = false
			$BodyNode2D/BodySprite2D.visible = false
			$BodyArea2D/BodyCollisionShape2D.set_deferred("disabled", true)
#			$Gun1Node2D/Area2D.queue_free()
#			$Gun2Node2D/Area2D.queue_free()
#			$Gun3Node2D/Area2D.queue_free()
#			$Gun4Node2D/Area2D.queue_free()
#			$Gun5Node2D/Area2D.queue_free()
#			$BodyArea2D.queue_free()
			
			$SpinSound.stop()
			
			#reparent particles two nodes up
			var explosion_particles = $ExplosionParticles
			var enemy_explosion = $EnemyExplosion
			explosion_particles.reparent(get_parent().get_parent())
			enemy_explosion.reparent(get_parent().get_parent())
			explosion_particles.emitting = true
			enemy_explosion.emitting = true
			
			$GunCooldown.stop()
#			$GunCooldown.queue_free()
			can_shoot = false
			common.play_explode_sound_3()
			dead = true
	else:
		common.play_damage_sound()

func deploy_guns():
	$Gun1Node2D.rotation_degrees += GUN_ROTATION_DEG
	$Gun2Node2D.rotation_degrees += GUN_ROTATION_DEG
	$Gun3Node2D.rotation_degrees += GUN_ROTATION_DEG
	$Gun4Node2D.rotation_degrees += GUN_ROTATION_DEG
	$Gun5Node2D.rotation_degrees += GUN_ROTATION_DEG

func shoot():
	var b1 = enemy_bullet_1_scene.instantiate()
	get_tree().root.add_child(b1)
	b1.start($Gun1Node2D/Gun1Marker2D.global_position, Vector2(-cos($Gun1Node2D.global_rotation), -sin($Gun1Node2D.global_rotation)))
	var b2 = enemy_bullet_1_scene.instantiate()
	get_tree().root.add_child(b2)
	b2.start($Gun2Node2D/Gun2Marker2D.global_position, Vector2(-cos($Gun2Node2D.global_rotation), -sin($Gun2Node2D.global_rotation)))
	var b3 = enemy_bullet_1_scene.instantiate()
	get_tree().root.add_child(b3)
	b3.start($Gun3Node2D/Gun3Marker2D.global_position, Vector2(-cos($Gun3Node2D.global_rotation), -sin($Gun3Node2D.global_rotation)))
	var b4 = enemy_bullet_1_scene.instantiate()
	get_tree().root.add_child(b4)
	b4.start($Gun4Node2D/Gun4Marker2D.global_position, Vector2(-cos($Gun4Node2D.global_rotation), -sin($Gun4Node2D.global_rotation)))
	var b5 = enemy_bullet_1_scene.instantiate()
	get_tree().root.add_child(b5)
	b5.start($Gun5Node2D/Gun5Marker2D.global_position, Vector2(-cos($Gun5Node2D.global_rotation), -sin($Gun5Node2D.global_rotation)))
	common.play_shoot_sound_1()
	can_shoot = false
	$GunCooldown.start()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if spawning:
		spawn_time -= delta
		if spawn_time < 0:
			spawning = false
			
			$BodyArea2D/BodyCollisionShape2D.disabled = false
			$Gun1Node2D/Gun1Sprite2D.visible = true
			$Gun1Node2D/Gun1HingeSprite2D.visible = true
			$Gun2Node2D/Gun2Sprite2D.visible = true
			$Gun2Node2D/Gun2HingeSprite2D.visible = true
			$Gun3Node2D/Gun3Sprite2D.visible = true
			$Gun3Node2D/Gun3HingeSprite2D.visible = true
			$Gun4Node2D/Gun4Sprite2D.visible = true
			$Gun4Node2D/Gun4HingeSprite2D.visible = true
			$Gun5Node2D/Gun5Sprite2D.visible = true
			$Gun5Node2D/Gun5HingeSprite2D.visible = true
			$BodyNode2D/BodySprite2D.visible = true
			$Gun1Node2D/Area2D/GunCollisionShape2D.disabled = false
			$Gun2Node2D/Area2D/GunCollisionShape2D.disabled = false
			$Gun3Node2D/Area2D/GunCollisionShape2D.disabled = false
			$Gun4Node2D/Area2D/GunCollisionShape2D.disabled = false
			$Gun5Node2D/Area2D/GunCollisionShape2D.disabled = false
			$SpawnParticles.emitting = false
	elif dead:
		queue_free()
	else:
		if phase == 1:
			ang_velocity -= delta * 2.0
			$SpinSound.pitch_scale = 0.5 + (abs(ang_velocity)/MAX_ANG_VELOCITY)*SPIN_SOUND_MAX_PITCH
			if ang_velocity < -MAX_ANG_VELOCITY:
				ang_velocity = -MAX_ANG_VELOCITY
				phase = 2
		elif phase == 2:
			deploy_guns()
#			$SpinSound.stop()
			phase = 3
		elif phase == 3:
			if can_shoot:
				shoot()
		elif phase == 4:
#			$BodyArea2D/BodyCollisionShape2D.disabled = true
			phase = 5
		rotate(ang_velocity * delta)
	
func set_targeting_node(t_node:Node2D):
	targeting_nodes.append(t_node)

func _on_gun_cooldown_timeout():
	can_shoot = true

func _on_bullet_storm_timer_timeout():
	phase = 4

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		if !body.invincible:
			take_damage(body.KAMIKAZI_DAMAGE)
			body.set_killed_by(G.SPINNER_COLLISION)
			body.die()
#		else:
			#do nothing here because damage is handled per bash timer timeout when shield bashing

func _on_sound_timer_timeout():
	$SpinSound.play()
