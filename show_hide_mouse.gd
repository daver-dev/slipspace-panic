extends Node

var crosshair_texture: Texture2D
var hotspot: Vector2

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	crosshair_texture = load("res://Art/Player/crosshair.png")
	hotspot = Vector2(crosshair_texture.get_width() / 2.0, crosshair_texture.get_height() / 2.0)
	_hide_cursor()
	get_tree().create_timer(0.05).timeout.connect(_hide_cursor)

func _input(event: InputEvent):
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_hide_cursor()
	elif event is InputEventKey and (event.is_action("aim_left") or event.is_action("aim_right") or event.is_action("aim_up") or event.is_action("aim_down")):
		_hide_cursor()
	elif event is InputEventMouseMotion:
		_show_cursor()

func _show_cursor():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_custom_mouse_cursor(crosshair_texture, Input.CURSOR_ARROW, hotspot)

func _hide_cursor():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
