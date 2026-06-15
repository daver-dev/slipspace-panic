extends Path2D

@export var wave_amplitude: float = 10.0  # Height of the waves
@export var wave_color: Color = Color.WHITE
@export var line_width: float = 3.0
@export var wave_speed: float = 2.0  # Speed of wave animation

@export_group("Pixelation")
@export var pixelate_enabled: bool = true
@export var pixel_size: int = 1  # Size of each "pixel"
@export var pixel_line_width: bool = true  # Also pixelate line width
@export var pixel_line_style: bool = true  # Use blocky line segments

var line2d: Line2D
var time_offset: float = 0.0

func _ready():
	# Create Line2D as a child node
	line2d = Line2D.new()
	add_child(line2d)
	line2d.default_color = wave_color
	
	# Configure for pixelated look
	line2d.antialiased = false
	
	# Set line properties
	update_line_style()
	
	# Initial update
	update_wave_line()

func _process(delta):
	if wave_speed > 0:
		time_offset += delta * wave_speed
		update_wave_line()

func update_line_style():
	# Pixelate line width if enabled
	if pixelate_enabled and pixel_line_width:
		line2d.width = max(1, round(line_width / pixel_size) * pixel_size)
	else:
		line2d.width = line_width
	
	# Set line style
	if pixelate_enabled and pixel_line_style:
		line2d.joint_mode = Line2D.LINE_JOINT_SHARP
		line2d.begin_cap_mode = Line2D.LINE_CAP_NONE
		line2d.end_cap_mode = Line2D.LINE_CAP_NONE
	else:
		line2d.joint_mode = Line2D.LINE_JOINT_ROUND
		line2d.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line2d.end_cap_mode = Line2D.LINE_CAP_ROUND

func update_wave_line():
	if curve == null or curve.point_count < 2:
		return
	
	var points = []
	var path_length = curve.get_baked_length()
	var wave_width = path_length * 0.05  # 5% of path length
	
	# Adjust segments for pixelation
	var segment_length = pixel_size if pixelate_enabled else 5
	var segments = int(path_length / segment_length)
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var offset = t * path_length
		
		# Get position along the curve
		var pos = curve.sample_baked(offset)
		
		# Get the normal at this point (perpendicular to the curve)
		var next_offset = min(offset + 1.0, path_length)
		var next_pos = curve.sample_baked(next_offset)
		var direction = (next_pos - pos).normalized()
		var normal = Vector2(-direction.y, direction.x)
		
		# Calculate wave offset with animation
		var wave_phase = (offset / wave_width + time_offset) * TAU
		var wave_offset = sin(wave_phase) * wave_amplitude
		
		# Pixelate the wave offset if enabled
		if pixelate_enabled:
			wave_offset = round(wave_offset / pixel_size) * pixel_size
		
		# Apply wave offset along the normal
		var final_pos = pos + normal * wave_offset
		
		# Pixelate the position if enabled
		if pixelate_enabled:
			final_pos = pixelate_position(final_pos)
		
		points.append(final_pos)
	
	# Update Line2D points
	line2d.points = points
	update_line_style()

func pixelate_position(pos: Vector2) -> Vector2:
	var pixelated_x = round(pos.x / pixel_size) * pixel_size
	var pixelated_y = round(pos.y / pixel_size) * pixel_size
	return Vector2(pixelated_x, pixelated_y)

# Optional: Call this when the curve changes in the editor
func _on_curve_changed():
	update_wave_line()
