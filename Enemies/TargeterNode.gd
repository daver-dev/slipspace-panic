extends Node2D
var seek_pos:Vector2
var player
var started = false
var orb
var origin_vec
var original_dist
var original_dist_vec
var arc_height
var projectile_speed
var exploding
var level
var top_left
var bottom_right
var miniboss

const SPEED_MODIFIER = 1500
const LEAD_DIST_MIN = 110
const LEAD_DIST_MAX = 170
const POS_RANDOMIZER = 60

const LERP_WEIGHT = 0.035
const BASE_PROJECTILE_SPEED = 900
const MAX_DISTANCE_MODIFIER = 2500
const ARC_HEIGHT_MAX = 750
const ARC_HEIGHT_MIN = 5

func _ready():
	player = get_parent().get_player()
	seek_pos = player.position
	$Timer.start()
	exploding = false
	level = get_tree().get_first_node_in_group("level")
	top_left = level.find_child("CornerMarker1")
	bottom_right = level.find_child("CornerMarker3")
	
func set_parent(parent):
	miniboss = parent
	
func start():
	if miniboss.hp > 0:
		started = true
		position = seek_pos
		$TargetSprite2DStart.visible = true
		$TargetSprite2DStart.play()
		$StartProjectileTimer.start()
		$TargetSpawnSound.play()
	else:
		queue_free()
	
func start_projectile():
	
	if miniboss.hp > 0:
		$ProjectileNode2d.global_position = orb.global_position
		$ProjectileNode2d/ProjectileSprite2D.visible = true
		origin_vec = $ProjectileNode2d.global_position
		original_dist_vec = global_position - origin_vec
		original_dist = origin_vec.distance_to(global_position)
		arc_height = (clampf(abs(original_dist_vec.x), 0, MAX_DISTANCE_MODIFIER) / MAX_DISTANCE_MODIFIER) * (ARC_HEIGHT_MAX - ARC_HEIGHT_MIN) + ARC_HEIGHT_MIN
		projectile_speed = BASE_PROJECTILE_SPEED + (clampf(abs(original_dist), 0, MAX_DISTANCE_MODIFIER)/MAX_DISTANCE_MODIFIER)* SPEED_MODIFIER
	else:
		queue_free()

func attempt_predict_player_pos(delta):
	#almost there, need an array to store old positions to add a delay, need to ensure the array is updated the same per millisecond across machines.
#	var player_dir_vec:Vector2 = Vector2.UP.rotated(player.rotation)
	var veloc_vec:Vector2 = player.velocity.rotated(0)
#	print(player.speed)
	seek_pos.x = lerpf(seek_pos.x, player.position.x + veloc_vec.x * randi_range(LEAD_DIST_MIN, LEAD_DIST_MAX) * delta, LERP_WEIGHT)
	seek_pos.y = lerpf(seek_pos.y, player.position.y + veloc_vec.y * randi_range(LEAD_DIST_MIN, LEAD_DIST_MAX) * delta, LERP_WEIGHT)
	seek_pos.x += randi_range(-POS_RANDOMIZER, POS_RANDOMIZER)
	seek_pos.y += randi_range(-POS_RANDOMIZER, POS_RANDOMIZER)
	if seek_pos.y < top_left.position.y:
		seek_pos.y = top_left.position.y
	elif seek_pos.y > bottom_right.position.y:
		seek_pos.y = bottom_right.position.y
	if seek_pos.x < top_left.position.x:
		seek_pos.x = top_left.position.x
	elif seek_pos.x > bottom_right.position.x:
		seek_pos.x = bottom_right.position.x
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	attempt_predict_player_pos(delta)
	if started:
		if !$TargetSprite2DStart.is_playing() and $ShockwaveSprite2D.visible == false:
			$TargetSprite2DStart.visible = false
			$TargetSprite2D.visible = true
			$TargetSprite2D.play()
		if $ProjectileNode2d/ProjectileSprite2D.visible:
			var vec_to_tgt = ($".".global_position - $ProjectileNode2d.global_position).normalized()
			$ProjectileNode2d.global_position.x = move_toward($ProjectileNode2d.global_position.x, $".".global_position.x, delta*projectile_speed*abs(vec_to_tgt.x))
			$ProjectileNode2d.global_position.y = move_toward($ProjectileNode2d.global_position.y, $".".global_position.y, delta*projectile_speed*abs(vec_to_tgt.y))
			var distance_covered_ratio = origin_vec.distance_to($ProjectileNode2d.global_position)/original_dist
			$ProjectileNode2d/ProjectileSprite2D.global_position.y = $ProjectileNode2d.global_position.y - abs(sin(distance_covered_ratio*PI)*arc_height)
			if distance_covered_ratio == 1:
				$ProjectileNode2d/ProjectileSprite2D.visible = false
				$ShockwaveSprite2D.visible = true
				$ShockwaveSprite2D.play()
				exploding = true
				$TargetSprite2D.stop()
				$TargetSprite2D.visible = false
				$ProjectileNode2d/Area2D/CollisionShape2D.disabled = false
				$ExplosionSound.play()
		if exploding:
			var frame_num = $ShockwaveSprite2D.get_frame()
			if frame_num == 2:
				$ProjectileNode2d/Area2D/CollisionShape2D.shape.radius = 46
			elif frame_num == 4: 
				$ProjectileNode2d/Area2D/CollisionShape2D.shape.radius = 75
			elif frame_num >= 5: 
				$ProjectileNode2d/Area2D/CollisionShape2D.shape.radius = 98
				if frame_num >= 8:
					$ProjectileNode2d/Area2D/CollisionShape2D.disabled = true
		if exploding and $ShockwaveSprite2D.get_frame() == 14:
			queue_free()
			
func _on_timer_timeout():
	start()

func _on_start_projectile_timer_timeout():
	if miniboss.hp > 0:
		start_projectile()
		$BombFireSound.play()
	else:
		queue_free()
	
func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		body.set_killed_by(G.MINIBOSS_BOMB)
		body.die()
