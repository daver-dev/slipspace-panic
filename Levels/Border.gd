extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func blow_up_top():
	$BaseBorder.play()
	$WallExplodeSound.play()
	
	$"../Camera2D".screen_shake(100)
	
	$GPUParticles2D.emitting = true
	$GPUParticles2D2.emitting = true
	$GPUParticles2D3.emitting = true
	$GPUParticles2D4.emitting = true
	$GPUParticles2D5.emitting = true
	$GPUParticles2D6.emitting = true
	$GPUParticles2D7.emitting = true
	
	$ExplosionChunk1.visible = true
	get_tree().create_tween().tween_property($ExplosionChunk1, "position",$ExplosionChunk1TargetLocation.position,2.0)
	get_tree().create_tween().tween_property($ExplosionChunk1, "rotation",2.5*PI,2.0)
	
	$ExplosionChunk2.visible = true
	get_tree().create_tween().tween_property($ExplosionChunk2, "position",$ExplosionChunk2TargetLocation.position,2.0)
	get_tree().create_tween().tween_property($ExplosionChunk2, "rotation",3*PI,2.0)
	
	$ExplosionChunk3.visible = true
	get_tree().create_tween().tween_property($ExplosionChunk3, "position",$ExplosionChunk3TargetLocation.position,2.0)
	get_tree().create_tween().tween_property($ExplosionChunk3, "rotation",-4*PI,2.0)
	
	$ExplosionChunk4.visible = true
	get_tree().create_tween().tween_property($ExplosionChunk4, "position",$ExplosionChunk4TargetLocation.position,2.0)
	get_tree().create_tween().tween_property($ExplosionChunk4, "rotation",-3*PI,2.0)
