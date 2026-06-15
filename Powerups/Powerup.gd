extends Area2D
class_name Powerup

const MAX_SPEED = 200
const MIN_SPEED = 150
const GROW_SHRINK_TIME = 0.25
const DO_NOTHING_TIME = 0.75
const TIME_UNTIL_FAST_PULSE = 8.0
const TIME_UNTIL_SPRITE_TOGGLE_FLASH = 4.0
const TIME_BETWEEN_SPRITE_TOGGLE_FLASH = 0.07
const TIME_UNTIL_DISAPPEAR_COMPLETELY = 2.0
var speed
var x_speed
var y_speed
var angle
var direction:Vector2
var start_modulate
var modulate_range
var start_scale
var scale_range

func _ready():
#	G.HUD.hud_print('pls' + str(self.get_class()))
	angle = randf_range(0.0, 2 * PI)
	direction = Vector2(cos(angle), sin(angle))
	speed = randi_range(MIN_SPEED, MAX_SPEED)
	x_speed = direction.x * speed
	y_speed = direction.y * speed
	start_modulate = $Animation.modulate.a
	modulate_range = 1 - start_modulate
	start_scale = $".".scale.x
	scale_range = 1 - start_scale
	$GrowTimer.wait_time = GROW_SHRINK_TIME
	$ShrinkTimer.wait_time = GROW_SHRINK_TIME
	$DoNothingTimer.wait_time = DO_NOTHING_TIME
	$DoNothingTimer.start()
	$DisappearWarningTimer.wait_time = TIME_UNTIL_FAST_PULSE
	$DisappearFinalWarningTimer.wait_time = TIME_UNTIL_SPRITE_TOGGLE_FLASH
	$HideSpriteToggleTimer.wait_time = TIME_BETWEEN_SPRITE_TOGGLE_FLASH
	$DisappearTimer.wait_time = TIME_UNTIL_DISAPPEAR_COMPLETELY

func _physics_process(delta):
	position.x += x_speed * delta
	position.y += y_speed * delta
	if !$GrowTimer.is_stopped():
		$Animation.modulate.a = start_modulate + (modulate_range)*(1 - $GrowTimer.time_left / GROW_SHRINK_TIME)
		$".".scale.x = start_scale + scale_range*(1 - $GrowTimer.time_left / GROW_SHRINK_TIME)
		$".".scale.y = start_scale + scale_range*(1 - $GrowTimer.time_left / GROW_SHRINK_TIME)
	elif !$ShrinkTimer.is_stopped():
		$Animation.modulate.a = 1 - (modulate_range)*(1 - $ShrinkTimer.time_left / GROW_SHRINK_TIME)
		$".".scale.x = 1 - scale_range*(1 - $ShrinkTimer.time_left / GROW_SHRINK_TIME)
		$".".scale.y = 1 - scale_range*(1 - $ShrinkTimer.time_left / GROW_SHRINK_TIME)

func _on_do_nothing_timer_timeout():
	$GrowTimer.start()

func _on_grow_timer_timeout():
	$ShrinkTimer.start()

func _on_shrink_timer_timeout():
	$DoNothingTimer.start()

func _on_disappear_warning_timer_timeout():
	$GrowTimer.wait_time /= 3.0
	$ShrinkTimer.wait_time /= 3.0
	$DoNothingTimer.wait_time /= 3.0
	$DisappearFinalWarningTimer.start()

func _on_disappear_final_warning_timer_timeout():
	$HideSpriteToggleTimer.start()
	$DisappearTimer.start()

func _on_hide_sprite_toggle_timer_timeout():
	$Animation.visible = !$Animation.visible

func _on_disappear_timer_timeout():
	queue_free()
