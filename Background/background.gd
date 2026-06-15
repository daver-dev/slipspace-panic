extends Node2D
const STAR_FADE_DURATION := 0.4

# Called when the node enters the scene tree for the first time.
func _ready():
	var tween = create_tween()
	tween.tween_property($ParallaxBackground/ParallaxLayerBack, "modulate:a", 1.0, STAR_FADE_DURATION)
	tween.parallel().tween_property($ParallaxBackground/ParallaxLayerMid, "modulate:a", 1.0, STAR_FADE_DURATION)
	tween.parallel().tween_property($ParallaxBackground/ParallaxLayerFront, "modulate:a", 1.0, STAR_FADE_DURATION)
