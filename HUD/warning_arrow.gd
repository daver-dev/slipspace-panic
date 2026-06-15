extends Node2D
class_name WarningArrow

var player: Node2D
var enemy: Node2D
var camera = Camera2D
var enemy_visibility_notifier = VisibleOnScreenNotifier2D.new()
var viewport_size
var viewport_center: Vector2

const X_BUFFER_SCALE = 1.1
const Y_BUFFER_SCALE = 1
const Y_SHIFT = 50

func set_values(p: Node2D, e: Node2D, c: Camera2D):
	player = p
	enemy = e
	camera = c

# Called when the node enters the scene tree for the first time.
func _ready():
	enemy.add_child(enemy_visibility_notifier)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_instance_valid(enemy):
		if !enemy_visibility_notifier.is_on_screen(): 
			show()
			viewport_center = get_canvas_transform().affine_inverse() * get_viewport_rect().get_center()
			
			var x_min_max = get_viewport_rect().get_center().x * X_BUFFER_SCALE
			var y_min_max = get_viewport_rect().get_center().y * Y_BUFFER_SCALE
			var clamped_x = clampf(enemy.global_position.x, viewport_center.x -x_min_max, viewport_center.x + x_min_max)
			var clamped_y = clampf(enemy.global_position.y, viewport_center.y -y_min_max, viewport_center.y + y_min_max - Y_SHIFT)

			global_position.x = clamped_x
			global_position.y = clamped_y
			
			rotation = viewport_center.angle_to_point(enemy.global_position)
		else:
			hide()
	else:
		queue_free()
