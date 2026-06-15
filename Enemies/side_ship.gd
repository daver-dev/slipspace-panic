extends CharacterBody2D
class_name SideShip

const explosion:PackedScene = preload("res://Enemies/enemy_explosion.tscn")
const red_explosion:PackedScene = preload("res://Enemies/enemy_explosion_red.tscn")

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group('player')
@onready var level : Node2D = get_tree().get_first_node_in_group("level")
const KICK_RETURN_TIME = 0.06
const KICK_SCALAR = 8
const MIN_RAND_ROT = 0.01
const MAX_RAND_ROT = 0.03
const MAX_PATH_SPEED = 1.2
const PATH_ACCELERATION = 0.4
const PATH_DECELERATION = - 0.7
const DECEL_PROGRESS_RATIO = 0.63
const TIME_TO_LERP_ROTATION = 0.25
const FOLLOW_SPEED = 0.8
const START_HP = 10000
const DELAY_BETWEEN_EXPLOSION = 0.4

enum states {INTRO=0, IDLE=1, SHOOTING=2, CHARGE=3, DEAD=4}
var state = states.INTRO
var hp = START_HP
var common
var damage_sprite
var boss_root
var damaged
var shakey_time = false
var shake_x_offset = 0.0
var shake_y_offset = 0.0

var explosions_array = [
	Vector2(-33.0,20.0),
	Vector2(20.0,40.0),
	Vector2(33.0,-20.0),
	Vector2(-23.0,-20.0),
	Vector2(0.0,55.0),
	]

func _ready():
	damaged = false
	boss_root = get_tree().get_first_node_in_group("boss_root")
	common = get_tree().get_first_node_in_group("enemy_shared")
	damage_sprite = find_child("DamagedSprite2D")

func get_origin_marker_location():
	return get_child(3).get_child(4).global_position

func take_damage(dmg):
	if hp > 0:
		hp -= dmg
#		get_child(0).modulate = Color.RED
		get_child(3).modulate = Color.RED
		$DamageVisualRevertTimer.start()
		common.play_damage_sound2()
		if hp <= 0:
			damage_sprite.visible = true
			damaged = true
			hp = 0
			boss_root.call_deferred("notify_sideship_dead")
			get_child(3).get_child(2).emitting = true
			get_child(3).get_child(3).emitting = true
			
			chain_explosions()
	else:
		common.play_ping_sound()
	
func reset_sprite_modulate():
	get_child(3).modulate = Color.WHITE
	
func chain_explosions():
	for i in range(explosions_array.size()):
		single_explosion(explosions_array[i], i * DELAY_BETWEEN_EXPLOSION + randf_range(-0.2,0.2))
	
func single_explosion(location:Vector2, delay:float):
	await get_tree().create_timer(delay).timeout
	shakey_time = true
	var explosion_instance = explosion.instantiate()
	var red_explosion_instance = red_explosion.instantiate()
	add_child(explosion_instance)
	add_child(red_explosion_instance)
	explosion_instance.position = location
	explosion_instance.emitting = true
	red_explosion_instance.position = location
	red_explosion_instance.emitting = true
	common.play_explode_sound_5()
	get_tree().create_timer(0.7).timeout.connect(Callable(explosion_instance, "queue_free"))
	get_tree().create_timer(1).timeout.connect(Callable(red_explosion_instance, "queue_free"))

func randomize_rot():
	var shooting_sprite = get_child(3)
	var random_rot = randf_range(MIN_RAND_ROT, MAX_RAND_ROT) * (-1 if randi_range(0,1) == 0 else 1)
	shooting_sprite.rotation = random_rot

func recoil():
	var shooting_sprite = get_child(3)
	shooting_sprite.position = Vector2.UP.rotated(shooting_sprite.rotation) * KICK_SCALAR
	create_tween().tween_property(shooting_sprite, "position", Vector2(), KICK_RETURN_TIME).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)

func reset_rotation():
	var shooting_sprite = get_child(3)
	create_tween().tween_property(shooting_sprite, "rotation", 0.0, KICK_RETURN_TIME).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)

func disable_collision():
	get_child(0).disabled = true
