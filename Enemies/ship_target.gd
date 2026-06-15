extends CharacterBody2D
class_name ShipTarget

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group('player')
@onready var level = get_tree().get_first_node_in_group("level")
@onready var left_aimpoint = level.find_child("BossAimTgtLeft", false, true)
@onready var right_aimpoint = level.find_child("BossAimTgtRight", false, true)
@onready var far_left_aimpoint = level.find_child("CornerMarker4", false, true)
@onready var far_right_aimpoint = level.find_child("CornerMarker3", false, true)
@onready var center_aimpoint = level.find_child("BossAimTgtCenter", false, true)

const SWEEP_ATTACK_SPEED_MULT = 0.3
const SWEEP_ATTACK_Y = 700
const IDLE_SPEED_MULT = 4.0
const DIST_ARRIVED = 2.0
const SWEEP_START_X_OFFSET = 1000
const SWEEP_DEST_X_OFFSET = 700
const L_R_ADDITIONAL_SWEEP_OFFSET = 300
enum SHOOT_STATES {NOT=0, PRESHOOT=1, SHOOTING=2, DONE_SHOOTING=3}

var shoot_state = SHOOT_STATES.NOT

var direction_to_travel
var distance_to_destination
var destination
var speed
#var speed_mult = 4.0
#var frames_elapsed = 0
#var time_elapsed = 0.0
var shooting_target_has_swept = false
var is_left_ship
var sweeping_from_left = false

func _physics_process(_delta):
	if shoot_state == SHOOT_STATES.DONE_SHOOTING: #pointless, remove extra state unless a one-time cleanup is needed
		shoot_state = SHOOT_STATES.NOT
	if shoot_state == SHOOT_STATES.NOT:
		move_and_slide()

#ready() still in respective RightShipTarget and LeftShipTarget
func idle_movement():
	destination = Vector2((player.global_position.x + -400.0) if is_left_ship else (player.global_position.x + 400.0), player.global_position.y)
	direction_to_travel = global_position.direction_to(destination)
	distance_to_destination = global_position.distance_to(destination) 
	speed = distance_to_destination * IDLE_SPEED_MULT
	velocity = direction_to_travel * speed
	
func move_for_shooting_sweep_phase_1(_delta, is_sweeping_from_left:bool, seconds_to_travel:float):
	if shoot_state == SHOOT_STATES.NOT:
		shoot_state = SHOOT_STATES.PRESHOOT
	sweeping_from_left = is_sweeping_from_left
	destination = far_left_aimpoint.global_position if is_sweeping_from_left else far_right_aimpoint.global_position
	get_tree().create_tween().tween_property(self, "global_position", destination, seconds_to_travel)

func enable_shooting_movement_phase_1(seconds_to_travel:float):
	if shoot_state == SHOOT_STATES.PRESHOOT:
		shoot_state = SHOOT_STATES.SHOOTING
	destination = right_aimpoint.global_position if sweeping_from_left else left_aimpoint.global_position
	get_tree().create_tween().tween_property(self, "global_position", destination, seconds_to_travel)

func enable_shooting_movement_phase_2(seconds_to_travel:float):
	if shoot_state == SHOOT_STATES.PRESHOOT:
		shoot_state = SHOOT_STATES.SHOOTING
	destination = center_aimpoint.global_position
	get_tree().create_tween().tween_property(self, "global_position", destination, seconds_to_travel)
