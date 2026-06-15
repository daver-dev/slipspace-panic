extends CanvasLayer

const SAVE_PATH := "user://sound_settings.save"
const DEFAULT_SFX_VOLUME := 0.5
const DEFAULT_MUSIC_VOLUME := 0.5
const VOLUME_INTERVAL := 0.1
const FADE_DURATION := 0.2
const SFX_BUSNAME := "SFX"
const MUSIC_BUSNAME := "Music"
var sfx_bus_index:int
var music_bus_index:int
var sfx_volume:float
var music_volume:float
var which_setting:int = 0
var is_fading:= false
var caller:Node #save who called the menu to fade in so we know who to notify when player exits menu
var _hovered_setting := -1

func _ready():
	sfx_bus_index = AudioServer.get_bus_index(SFX_BUSNAME)
	music_bus_index = AudioServer.get_bus_index(MUSIC_BUSNAME)
	load_sound_settings()
	apply_volume_changes()
	$RootNode2D.modulate.a = 0.0
	_setup_mouse_areas()


func _setup_mouse_areas() -> void:
	_make_hover_area($RootNode2D/FxSlider,    Vector2(128, 20), Vector2.ZERO,  0)
	_make_hover_area($RootNode2D/MusicSlider, Vector2(128, 20), Vector2.ZERO,  1)
	_make_hover_area($RootNode2D/DoneButton,  Vector2(120, 30), Vector2(0, 4), 2)


func _make_hover_area(parent: Node2D, size: Vector2, offset: Vector2, which: int) -> void:
	var area := Area2D.new()
	area.position = offset
	area.z_index = 100
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	area.add_child(shape)
	parent.add_child(area)
	area.mouse_entered.connect(_on_setting_hover.bind(which))
	area.mouse_exited.connect(_on_setting_exit.bind(which))


func _on_setting_hover(which: int) -> void:
	if is_fading or caller == null or not caller.is_in_settings():
		return
	_hovered_setting = which
	if which_setting == which:
		return
	which_setting = which
	get_parent().play_selection_change()


func _on_setting_exit(which: int) -> void:
	if _hovered_setting == which:
		_hovered_setting = -1


func _input(event: InputEvent) -> void:
	if is_fading or caller == null or not caller.is_in_settings() or _hovered_setting == -1:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var mouse_x := get_viewport().get_mouse_position().x
	match _hovered_setting:
		0:
			sfx_volume = clampf((mouse_x - ($RootNode2D/FxSlider.position.x - 128.0)) / 256.0, 0.0, 1.0)
			apply_volume_changes()
			get_parent().play_selection_change()
		1:
			music_volume = clampf((mouse_x - ($RootNode2D/MusicSlider.position.x - 128.0)) / 256.0, 0.0, 1.0)
			apply_volume_changes()
			get_parent().play_selection_change()
		2:
			get_parent().play_button_click()
			$RootNode2D/DoneButtonHighlight.visible = false
			$RootNode2D/DoneButton.visible = false
			$RootNode2D/DoneButtonPress.visible = true
			is_fading = true
			save_and_reset()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if null != caller:
		if caller.is_in_settings():
			show()
		else:
			hide()
	
		#change settings only if visible
		if visible && !is_fading:
			#change menu items
			if Input.is_action_just_pressed("move_up"):
				get_parent().play_selection_change()
				which_setting = which_setting -1
				if which_setting == -1:
					which_setting = 2
			elif Input.is_action_just_pressed("move_down"):
				get_parent().play_selection_change()
				which_setting = (which_setting + 1) % 3
				
			#change volume sliders
			elif Input.is_action_just_pressed("move_right"):
				get_parent().play_selection_change()
				match which_setting:
					0:
						sfx_volume = clampf(sfx_volume + VOLUME_INTERVAL, 0.0, 1.0)
					1:
						music_volume = clampf(music_volume + VOLUME_INTERVAL, 0.0, 1.0)
			elif Input.is_action_just_pressed("move_left"):
				get_parent().play_selection_change()
				match which_setting:
					0:
						sfx_volume = clampf(sfx_volume - VOLUME_INTERVAL, 0.0, 1.0)
					1:
						music_volume = clampf(music_volume - VOLUME_INTERVAL, 0.0, 1.0)
			
			#apply volume changes if any
			apply_volume_changes()
			
			#change visible highlights
			match which_setting:
				0:
					$RootNode2D/FxSliderHighlight.visible = true
					$RootNode2D/MusicSliderHighlight.visible = false
					$RootNode2D/DoneButtonHighlight.visible = false
				1:
					$RootNode2D/FxSliderHighlight.visible = false
					$RootNode2D/MusicSliderHighlight.visible = true
					$RootNode2D/DoneButtonHighlight.visible = false
				2:
					$RootNode2D/FxSliderHighlight.visible = false
					$RootNode2D/MusicSliderHighlight.visible = false
					$RootNode2D/DoneButtonHighlight.visible = true
			
			#adjust slider knobs after changing values	
			$RootNode2D/FxPath/PathFollow2D.progress_ratio = sfx_volume
			$RootNode2D/MusicPath/PathFollow2D.progress_ratio = music_volume
			
			if Input.is_action_just_pressed("ui_select"):
				if which_setting == 2:
					get_parent().play_button_click()
					$RootNode2D/DoneButtonHighlight.visible = false
					$RootNode2D/DoneButton.visible = false
					$RootNode2D/DoneButtonPress.visible = true
					is_fading = true
					save_and_reset()
			
			#logic for actual volume bus change here
			#CODE ME!

func apply_volume_changes():
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_volume))
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(music_volume))

func fade_in(my_caller:Node):
	assert(my_caller.has_method("exit_sound_settings"), "ERROR, caller must have method exit_sound_settings() for notifying caller when user is done with sound settings")
	assert(my_caller.has_method("is_in_settings"), "ERROR, caller must have method is_in_settings() to check whether parent is in sound settings")
	caller = my_caller
	if !is_fading:
		var tween = create_tween()
		tween.tween_property($RootNode2D, "modulate:a", 1.0, FADE_DURATION)
		tween.finished.connect(func(): is_fading = false)

func fade_out():
		var tween = create_tween()
		tween.tween_property($RootNode2D, "modulate:a", 0.0, FADE_DURATION)
		tween.finished.connect(reset_and_trigger_parent_fade_in)

func save_and_reset():
	save_sound_settings()
	fade_out()

func reset_and_trigger_parent_fade_in():
	reset_menu()
	is_fading = false
	caller.exit_sound_settings()
#	get_parent().trigger_not_in_sound_settings()

func reset_menu():
	which_setting = 0
	$RootNode2D/DoneButtonPress.visible = false
	$RootNode2D/DoneButton.visible = true
	
	#TODO: fade parent back in

func load_sound_settings():
	if not FileAccess.file_exists(SAVE_PATH): #We don't have a save to load.
#		print("loading default volume settings")
		sfx_volume = DEFAULT_SFX_VOLUME
		music_volume = DEFAULT_MUSIC_VOLUME
		apply_volume_changes()
		return
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	sfx_volume = save_file.get_float()
	music_volume = save_file.get_float()
	
	$RootNode2D/FxPath/PathFollow2D.progress_ratio = sfx_volume
	$RootNode2D/MusicPath/PathFollow2D.progress_ratio = music_volume

func save_sound_settings():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_float(sfx_volume)
	file.store_float(music_volume)
