extends Node2D
const SOUND_FADE_DURATION := 0.3
var main_menu_option = 0
var active_color
var inactive_color
var starting = false
var quitting = false
var quit_handler_called := false
var in_settings = false
var _hovered_option := -1
const THRUSTER_PITCH_BOOSTED_MAX = 3.3
const MAX_THRUSTER_VOLUME_BOOSTED = -0.0

func _ready():
	$CanvasModulate.color = Color.BLACK
	$MenuBackground.play()
	$Thrusters.play()
	$Siren.play()
	$MainMenuFader.play("fade_in")
	_setup_mouse_areas()


func _setup_mouse_areas() -> void:
	_make_button_area($Attack, Vector2(46, 28), Vector2(-77, 102), 0)
	_make_button_area($Quit, Vector2(46, 28), Vector2(83, 104), 1)
	_make_button_area($SettingsHighlight, Vector2(82, 34), Vector2(-207, 91), 2)


func _make_button_area(parent: Node2D, size: Vector2, offset: Vector2, option: int) -> void:
	var area := Area2D.new()
	area.position = offset
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	area.add_child(shape)
	parent.add_child(area)
	area.mouse_entered.connect(_on_button_hover.bind(option))
	area.mouse_exited.connect(_on_button_exit.bind(option))


func _on_button_hover(option: int) -> void:
	if starting or in_settings:
		return
	_hovered_option = option
	if main_menu_option == option:
		return
	main_menu_option = option
	update_menu_colors()
	$ChangeSelection.play()


func _on_button_exit(option: int) -> void:
	if _hovered_option == option:
		_hovered_option = -1


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	if starting or in_settings or _hovered_option == -1:
		return
	match main_menu_option:
		0:
			starting = true
			$AttackPress.modulate.a = 1
			$Attack.modulate.a = 0
			$AttackHighlight.modulate.a = 0
			$Select.play()
			$Camera2D.apply_game_start_shake()
			zoom_transition()
		1:
			quitting = true
			$QuitPress.modulate.a = 1
			$Quit.modulate.a = 0
			$QuitHighlight.modulate.a = 0
			$Select.play()
			$MainMenuFader.play("fade_out")
		2:
			$SettingsMenu.fade_in(self)
			in_settings = true
			$Select.play()

func _process(_delta):
	if !$Siren.playing:
		$Siren.play()
	if !$Thrusters.playing:
		$Thrusters.play()
	if $MenuBackground.get_frame() == 83:
		$Camera2D.apply_interval_shake()
		$Boom.play()
	if !starting:
		if !in_settings:
			if Input.is_action_just_pressed("ui_left"):
				decrement_main_menu()
			elif Input.is_action_just_pressed("ui_right"):
				increment_main_menu()
			elif Input.is_action_just_pressed("ui_select") and main_menu_option == 0:
				starting = true
				$AttackPress.modulate.a = 1
				$Attack.modulate.a = 0
				$AttackHighlight.modulate.a = 0
				$Select.play()
				$Camera2D.apply_game_start_shake()
#				$MainMenuFader.play("fade_out")
				zoom_transition()
			elif Input.is_action_just_pressed("ui_select") and main_menu_option == 1:
				quitting = true
				$QuitPress.modulate.a = 1
				$Quit.modulate.a = 0
				$QuitHighlight.modulate.a = 0
				$Select.play()
				$MainMenuFader.play("fade_out")
			elif Input.is_action_just_pressed("ui_select") and main_menu_option == 2:
				$SettingsMenu.fade_in(self)
				in_settings = true
				$Select.play()

func zoom_transition():
	play_chargeup_sound()
	await get_tree().create_timer(0.5).timeout
	var zoom_tween = create_tween()
	zoom_tween.tween_property($".", "scale", Vector2(0.95,0.95), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	zoom_tween.tween_callback(play_blastoff_sound)
	zoom_tween.tween_property($".", "scale", Vector2.ONE*300, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	zoom_tween.tween_interval(0.85)
	zoom_tween.tween_property($Siren, "volume_db", -40, SOUND_FADE_DURATION)
	zoom_tween.parallel().tween_property($Thrusters, "volume_db", -40, SOUND_FADE_DURATION)
	zoom_tween.parallel().tween_property($Boom, "volume_db", -40, SOUND_FADE_DURATION)
	
#	zoom_tween.tween_callback(stop_particles)
	await zoom_tween.finished
#	await await get_tree().create_timer(0.5).timeout
	get_parent().start_game()

#func stop_particles():
#	print("stopping particles")
#	$SmallStars.get_child(0).emitting = false
#	$Stars.get_child(0).emitting = false

func play_button_click():
	$ButtonClick.play()

func play_selection_change():
	$SelectionChange.play()

func is_in_settings():
	return in_settings

func exit_sound_settings():
	#TODO:start cockpit fade-in here...
	in_settings = false
	$SettingsMenu.hide()

func increment_main_menu():
	if main_menu_option == 2:
		main_menu_option = 0
	else:
		main_menu_option += 1
	update_menu_colors()
	$ChangeSelection.play()
		
func decrement_main_menu():
	if main_menu_option == 0:
		main_menu_option = 2
	else:
		main_menu_option -= 1
	update_menu_colors()
	$ChangeSelection.play()

func update_menu_colors():
	if main_menu_option == 0:
		$AttackHighlight.modulate.a = 1
		$QuitHighlight.modulate.a = 0
		$SettingsHighlight.modulate.a = 0
	elif main_menu_option == 1:
		$AttackHighlight.modulate.a = 0
		$QuitHighlight.modulate.a = 1
		$SettingsHighlight.modulate.a = 0
	elif main_menu_option == 2:
		$AttackHighlight.modulate.a = 0
		$QuitHighlight.modulate.a = 0
		$SettingsHighlight.modulate.a = 1

func play_blastoff_sound():
	$BlastOff.play()
	$AnimationPlayer.play("boost_pitch")
	$ChargeUp.volume_db = -20
func play_chargeup_sound():
	$ChargeUp.play()
	$AnimationPlayer.play("chargeup_pitch")
	
func _on_main_menu_fader_animation_finished(_anim_name):
#	print("MAIN MENU ANIMATION FINISHED")
#	if starting:
#		get_parent().start_game()
	if quitting && !quit_handler_called:
		quit_handler_called = true
		QuitHandler.quit(0.0)
