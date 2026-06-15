extends CanvasLayer

var menu_choice = 0
var _hovered_button := -1

# Set to true to hide highlighted button and show selected/pressed button.
var selecting = false

# Variables for determining the action at the end of PauseButtonsTimer.
var quitting = false
var resuming = false
var returning_to_menu = false
var going_to_settings = false
var in_settings = false
# Called when the node enters the scene tree for the first time.
func _ready():
	$CanvasModulate.color = Color(1,1,1,0)
	_setup_mouse_areas()


func _setup_mouse_areas() -> void:
	_make_button_area($ResumeButton,   Vector2(120, 28), Vector2(0, -35), 0)
	_make_button_area($SettingsButton, Vector2(120, 26), Vector2(0, -35), 1)
	_make_button_area($MenuButton,     Vector2(120, 26), Vector2(0,   6), 2)
	_make_button_area($QuitButton,     Vector2(120, 26), Vector2(0,  46), 3)


func _make_button_area(parent: Node2D, size: Vector2, offset: Vector2, choice: int) -> void:
	var area := Area2D.new()
	area.position = parent.position + offset * parent.scale
	area.z_index = 100
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size * parent.scale
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	area.mouse_entered.connect(_on_button_hover.bind(choice))
	area.mouse_exited.connect(_on_button_exit.bind(choice))


func _on_button_hover(choice: int) -> void:
	if not get_parent().paused or in_settings or selecting:
		return
	_hovered_button = choice
	if menu_choice == choice:
		return
	menu_choice = choice
	$SelectionChange.play()


func _on_button_exit(choice: int) -> void:
	if _hovered_button == choice:
		_hovered_button = -1


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	if not get_parent().paused or in_settings or selecting or _hovered_button == -1:
		return
	match menu_choice:
		0:
			selecting = true
			resuming = true
			$ResumeHighlight.hide()
			$ResumeButton.hide()
			$ResumePress.show()
			$ButtonClick.play()
			$PauseButtonsTimer.start()
		1:
			selecting = true
			going_to_settings = true
			$SettingsHighlight.hide()
			$SettingsButton.hide()
			$SettingsPress.show()
			$ButtonClick.play()
			$PauseButtonsTimer.start()
			$PauseFader.play("fade_out")
		2:
			selecting = true
			returning_to_menu = true
			$MenuHighlight.hide()
			$MenuButton.hide()
			$MenuPress.show()
			$ButtonClick.play()
			$PauseButtonsTimer.start()
			$PauseFader.play("fade_out")
		3:
			selecting = true
			quitting = true
			$QuitHighlight.hide()
			$QuitButton.hide()
			$QuitPress.show()
			$ButtonClick.play()
			$PauseButtonsTimer.start()
			$PauseFader.play("fade_out")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if get_parent().paused && in_settings == false:
		show()
		if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
			$SelectionChange.play()
			menu_choice -= 1
			if menu_choice == -1:
				menu_choice = 3
		elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
			menu_choice += 1
			$SelectionChange.play()
			if menu_choice == 4:
				menu_choice = 0
		if Input.is_action_just_pressed("ui_select") and !Input.is_action_just_pressed("b_start"):
			if menu_choice == 0:
				selecting = true
				resuming = true
				$ResumeHighlight.hide()
				$ResumeButton.hide()
				$ResumePress.show()
				$ButtonClick.play()
				$PauseButtonsTimer.start()
		
		if Input.is_action_just_pressed("ui_select"):
			if menu_choice == 1:
				selecting = true
				going_to_settings = true
				$SettingsHighlight.hide()
				$SettingsButton.hide()
				$SettingsPress.show()
				$ButtonClick.play()
				$PauseButtonsTimer.start()
				$PauseFader.play("fade_out")
			if menu_choice == 2:
				selecting = true
				returning_to_menu = true
				$MenuHighlight.hide()
				$MenuButton.hide()
				$MenuPress.show()
				$ButtonClick.play()
				$PauseButtonsTimer.start()
				$PauseFader.play("fade_out")
			elif menu_choice == 3:
				selecting = true
				quitting = true
				$QuitHighlight.hide()
				$QuitButton.hide()
				$QuitPress.show()
				$ButtonClick.play()
				$PauseButtonsTimer.start()
				$PauseFader.play("fade_out")
		
		if menu_choice == 0 && !selecting:
			$ResumeHighlight.show()
			$MenuButton.show()
			$QuitButton.show()
						
			$MenuHighlight.hide()
			$QuitHighlight.hide()
			$SettingsHighlight.hide()
			$SettingsButton.show()
			
			$ResumeButton.hide()
			
		elif menu_choice == 1 && !selecting: 
			$SettingsHighlight.show()
			$ResumeButton.show()
			$MenuButton.show()
			$QuitButton.show()
			
			$ResumeHighlight.hide()
			$MenuHighlight.hide()
			$QuitHighlight.hide()
			$SettingsButton.hide()
			
		elif menu_choice == 2 && !selecting: 
			$ResumeButton.show()
			$MenuHighlight.show()
			$QuitButton.show()
			$SettingsButton.show()
			
			$QuitHighlight.hide()
			$ResumeHighlight.hide()
			$MenuButton.hide()
			$SettingsHighlight.hide()
			
		elif menu_choice == 3 && !selecting:
			$ResumeHighlight.hide()
			$MenuHighlight.hide()
			$QuitHighlight.show()
			
			$ResumeButton.show()
			$MenuButton.show()
			$QuitButton.hide()		
	else:
		hide()
		reset_pause_buttons()
		$CanvasModulate.set_color(Color(1,1,1,1))
#		menu_choice = 0

func exit_sound_settings():
	$SettingsButton.visible = false
	$SettingsHighlight.visible = true
	$SettingsPress.visible = false
	reset_vars()
	$PauseFader.play("fade_in")

func is_in_settings():
	return in_settings

func reset_vars():
	quitting = false
	resuming = false
	returning_to_menu = false
	going_to_settings = false
	in_settings = false

func reset_pause_buttons():
	$ResumeHighlight.hide()
	$MenuHighlight.hide()
	$QuitHighlight.hide()
	$ResumePress.hide()
	$MenuPress.hide()
	$QuitPress.hide()
	
	$ResumeButton.show()
	$MenuButton.show()
	$QuitButton.show()

func play_button_click():
	$ButtonClick.play()

func play_selection_change():
	$SelectionChange.play()

# Take an action after a button is selected and a short timer runs out, 
# 	allowing for the button-press to be on screen for a moment.
func _on_timer_timeout():
	if resuming:
		get_tree().get_first_node_in_group("player").unpause()
		resuming = false
		selecting = false
	if going_to_settings:
#		print("timer timeout going to settings")
		resuming = false
		selecting = false
		in_settings = true
		
		$SettingsMenu.fade_in(self)
	if returning_to_menu:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://game.tscn")
		resuming = false
		selecting = false
	if quitting:
		QuitHandler.quit(0.0)
