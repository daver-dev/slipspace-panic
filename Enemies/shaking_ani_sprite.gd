extends AnimatedSprite2D
class_name ShakeAnimatedSprite

# Shake parameters
var shake_duration = 0.0
var shake_max_duration = 0.0  # To store the initial duration
var shake_max_intensity = 0.0
var shake_current_intensity = 0.0
var original_position = Vector2.ZERO
var noise = null
var noise_i = 0.0
var is_shaking = false

# Called when the node enters the scene tree for the first time.
func _ready():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.5


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !is_shaking:
		original_position = position
	
	# Apply shake if active
	if is_shaking:
		# Decrease shake duration
		shake_duration -= delta
		
		# Calculate progress as a normalized value (0 to 1)
		var progress = 1.0 - (shake_duration / shake_max_duration)
		
		# Apply ease-in for first 30% of animation
		if progress < 0.3:
			# This will start at 0 and increase to max_intensity
			shake_current_intensity = shake_max_intensity * (progress / 0.3)
		# Apply full intensity for middle section
		elif progress < 0.7:
			shake_current_intensity = shake_max_intensity
		# Apply ease-out for final 30%
		else:
			shake_current_intensity = shake_max_intensity * (1.0 - ((progress - 0.7) / 0.3))
		
		# Calculate shake offset
		noise_i += 1.0
		var this_offset = Vector2(
			noise.get_noise_2d(noise_i, 0.0) * shake_current_intensity,
			noise.get_noise_2d(0.0, noise_i) * shake_current_intensity
		)
		
		# Apply offset relative to where character would be without shake
		position = original_position + this_offset
		
		# Reset when done
		if shake_duration <= 0:
			is_shaking = false

func start_shake(duration = 1.5, intensity = 6.0):
	shake_duration = duration
	shake_max_duration = duration  # Store for progress calculation
	shake_max_intensity = intensity
	shake_current_intensity = 0.0  # Start with zero intensity
	is_shaking = true
