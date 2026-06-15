extends Node2D
var seek_pos:Vector2
var player
var started
const LEAD_DIST = 100
const LERP_WEIGHT = 0.03

func _ready():
	started = false
	player = get_parent().get_parent().get_player()
	
func start():
	started = true
	position = seek_pos
	$TargetSprite2DStart.visible = true
	$TargetSprite2DStart.play()

func attempt_predict_player_pos(delta):
	#almost there, need an array to store old positions to add a delay, need to ensure the array is updated the same per millisecond across machines.
	var player_dir_vec:Vector2 = Vector2.UP.rotated(player.rotation)
	var veloc_vec:Vector2 = player.velocity.rotated(0)
#	print(player.speed)
	seek_pos.x = lerpf(seek_pos.x, player.position.x + veloc_vec.x * LEAD_DIST * delta, LERP_WEIGHT)
	seek_pos.y = lerpf(seek_pos.y, player.position.y + veloc_vec.y * LEAD_DIST * delta, LERP_WEIGHT)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if started:
		if !$TargetSprite2DStart.is_playing():
			$TargetSprite2DStart.visible = false
			$TargetSprite2D.visible = true
			$TargetSprite2D.play()
	attempt_predict_player_pos(delta)
