extends Node2D

var damage
var enemies_damaged

# Called when the node enters the scene tree for the first time.
func _ready():
	$ExplosionParticles.emitting = true
	$ExplosionParticles2.emitting = true
	$ExplosionSound.play()
	enemies_damaged = []

func set_radius_and_damage(rad:float, dmg):
	damage = dmg
	$CollisionArea2D/CollisionShape2D.shape.radius = int(round(rad))
	$ExplosionParticles.process_material.set_emission_sphere_radius(rad)
	$ExplosionParticles.process_material.scale_max = rad/10.0
		
func _physics_process(_delta):
	if !$ExplosionParticles.emitting and !$ExplosionSound.playing:
		$CollisionArea2D/CollisionShape2D.disabled = true
		queue_free()

func _on_collision_area_2d_body_entered(body):
	if (body.is_in_group("enemies") || body.is_in_group("miniboss")) and !enemies_damaged.has(body):
		body.take_damage(damage)
		enemies_damaged.append(body)

func _on_collision_area_2d_area_entered(area):
	if area.is_in_group("enemy_body") and !enemies_damaged.has(area.get_parent()):
		area.get_parent().take_damage(damage)
		enemies_damaged.append(area.get_parent())
	elif area.is_in_group("hive") and !enemies_damaged.has(area):
		area.take_damage(damage)
		enemies_damaged.append(area)
