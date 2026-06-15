extends Camera2D

@export var strength: float = 3
@export var shakeFade: float = 4
var rng = RandomNumberGenerator.new()

var shake_strength: float = 0.0
var starting_game = false

func apply_interval_shake():
	shake_strength = strength
	
func apply_game_start_shake():
	var game_start_shake_tween = create_tween()
	game_start_shake_tween.tween_property(self, 'shake_strength', 5, 1.5)
	await game_start_shake_tween.finished
	shake_strength = 0
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength,0,shakeFade * delta)
		offset = random_offset()
		
func random_offset() -> Vector2:
		return Vector2(rng.randf_range(-shake_strength,shake_strength),rng.randf_range(-shake_strength,shake_strength))
func auto_shake():
	while true:
		await get_tree().create_timer(5.5).timeout
		apply_interval_shake()
