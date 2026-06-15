extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $"..".dead:
		scale.x += delta*0.04
		position.x -= delta*0.8
		scale.y += delta*0.04
		position.y -= delta*0.8
