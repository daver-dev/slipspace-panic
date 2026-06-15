extends SideShip

@onready var target: CharacterBody2D = get_tree().get_first_node_in_group('left_ship_target')
@onready var smoke_and_ember = [$LeftShipShootingAnimation/SmokeParticles, $LeftShipShootingAnimation/EmberParticles]

var radius = 15
var wobble_speed = 3
var path_speed = 0.0
var angle = 90
var total_delta = 0.0
var rotation_added_at_kickback = 0.0

func _physics_process(delta):
	if hp >=0:
		$HPLabel.text = str(hp)
	else:
		$HPLabel.text = str(0)
	$HPLabel.position.x = position.x
	$HPLabel.position.y = position.y -135
	$StateLabel.position.x = position.x
	$StateLabel.position.y = position.y -165
	$StateLabel.text = str(states.keys()[state])
	if state == states.INTRO:
		angle += wobble_speed * get_process_delta_time()
		var x = cos(angle)
		var y = sin(angle)
		position.x = radius * x
		position.y = radius * y

	elif state == states.IDLE:
		var aim_position = global_position.direction_to(target.global_position)
		
		#handles rotation transition from intro static direction to aiming at aim_obj
		total_delta += delta
		var weight = clampf(FOLLOW_SPEED*total_delta, 0.0, 1.0)
		var eased_weight = ease(weight, -3.0)
		global_rotation = lerpf(global_rotation, aim_position.angle() - PI/2, eased_weight)
		
		angle += wobble_speed * get_process_delta_time()
		var x = cos(angle)
		var y = sin(angle)
		position.x = radius * x
		position.y = radius * y
		
	elif state == states.CHARGE:
		charge(delta)
			
	if shakey_time:
		start_shake_timer()
		# reset last shaken position
		position.x = position.x - shake_x_offset
		position.y = position.y - shake_y_offset
		shake_y_offset = randf_range(-3.0, 3.0)
		shake_x_offset = randf_range(-3.0, 3.0)

func idle():
	state = states.IDLE
	
func start_shake_timer():
	await get_tree().create_timer(0.3).timeout
	shakey_time = false
	
func start_charge():
	$ThrusterSound.play()
	$GPUParticles2D.emitting = true
#	$LeftShipSprite.start_shake()
	$LeftShipShootingAnimation.start_shake()
	#Rotate to the charge starting position
	var tween = create_tween()
	tween.tween_property(self, "global_rotation", 0, 0.5)
	tween.finished.connect(set_charge_state)

func charge(delta):
	if get_parent().progress_ratio < DECEL_PROGRESS_RATIO:
		path_speed += PATH_ACCELERATION * delta
		path_speed = clampf(path_speed, 0, MAX_PATH_SPEED)
	else:
		path_speed = lerpf(path_speed, 0.01, 0.0157)
	get_parent().progress_ratio += delta * path_speed
	
#	if get_parent().progress_ratio >= 0.8:
#		var aim_position = global_position.direction_to(target.global_position)
		
	if get_parent().progress_ratio == 1.0:
		$GPUParticles2D.emitting = false
		target.global_position = $DefaultShipAimLocationMarker.global_position
#		rotation = 0
		idle()
		$"..".progress = 0.0
#		print("left ship rot after reparent: " + str(self.rotation))
#		get_parent().progress_ratio = 0.0

func set_charge_state():
	state = states.CHARGE

func _on_damage_visual_revert_timer_timeout():
	reset_sprite_modulate()
