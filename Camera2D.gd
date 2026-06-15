extends Camera2D

const LEFT_LIMIT = -1380
const TOP_LIMIT = -960
const RIGHT_LIMIT = 1380
const BOTTOM_LIMIT = 950
const CAM_Y_FIXED_BOSS_DEST = -300
const MOVE_SPEED = 700
const ZOOM_FACTOR = 0.85

var speed = 0.0
var before_reparent_pos:Vector2

enum states {NORMAL=0, BOSS=1, POSTBOSS=2, CREDITS=3}
var state = states.NORMAL
var follow_speed = 0.1
var total_delta = 0.0

# Screen shake (intro)
var shake_strength = 0.0
var shake_decay = 2.0 # How quickly it fades out
var noise = FastNoiseLite.new()
var noise_offset = Vector2.ZERO

# Screen shake rough (explosions)
var shake_strength_rough = 0.0
var shake_decay_rough = 5.0
var rng = RandomNumberGenerator.new()
#var credits_tween_created = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if state == states.NORMAL:
		global_position = $"../PlayerShip".global_position
	elif state == states.BOSS:
		pass
#		global_position.y = lerpf(global_position.y, $"../PlayerShip".global_position.y, delta/3.0)
#		global_position.x = lerpf(global_position.x, $"../PlayerShip".global_position.x, delta/3.0)
	elif state == states.POSTBOSS:
		total_delta += delta
		var weight = clampf(follow_speed*total_delta, 0.0, 1.0)
		var eased_weight = ease(weight, -3.0)
		global_position.x = lerpf(global_position.x, $"../PlayerShip".global_position.x, eased_weight)
		global_position.y = lerpf(global_position.y, $"../PlayerShip".global_position.y, eased_weight)
	elif state == states.CREDITS:
		global_position = $"../PlayerShip".global_position
#		if !credits_tween_created:
#			credits_tween_created = true
#			var cam_tween = create_tween()
#			cam_tween.tween_property(self, 'limit_left', -3000, 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
#			cam_tween.parallel().tween_property(self, 'limit_right', 3000, 3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
#			cam_tween.parallel().tween_property(self, 'offset', Vector2(400,0), 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if shake_strength > 0.0 && !state == states.CREDITS:
		# Decay shake strength
		shake_strength = lerpf(shake_strength, 0.0, shake_decay * delta)
		
		noise_offset.x += 1.0
		noise_offset.y += 1.0
		
		var x = noise.get_noise_2d(noise_offset.x, 0) * shake_strength
		var y = noise.get_noise_2d(0,noise_offset.y) * shake_strength
		
		offset = Vector2(x,y)
		
	if shake_strength_rough > 0:
#		if state == states.CREDITS:
#			print('bloop')
#			print(state)
		# Decay shake strength
		shake_strength_rough = lerpf(shake_strength_rough, 0.0, 0.02)
		
		offset = randomize_offset()
		
func randomize_offset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength_rough, shake_strength_rough), rng.randf_range(-shake_strength_rough, shake_strength_rough))

func normal():
#	print("calling normal")
	state = states.NORMAL
func preboss():
	before_reparent_pos = get_screen_center_position()
	limit_top = -99999
	global_position = before_reparent_pos
	var tween = create_tween()
	var duration = 2.0
	tween.tween_property(self, "position", Vector2(0, CAM_Y_FIXED_BOSS_DEST), duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "zoom", Vector2(0.7, 0.7), duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	state = states.BOSS
	
func postboss():
	var zoomin_tween = create_tween()
	zoomin_tween.tween_property(self, "zoom", Vector2(0.85, 0.85), 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	state = states.POSTBOSS

func credits():
	state = states.CREDITS

func screen_shake(strength = 100.0):
	shake_strength = strength
	
func screen_shake_rough(strength = 100.0):
	shake_strength_rough = strength
