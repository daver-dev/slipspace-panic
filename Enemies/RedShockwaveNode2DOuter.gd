extends Node2D

var exploding = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if exploding:
		var frame_num = $ShockwaveSprite2D.get_frame()
		if frame_num == 2:
			$Area2D/CollisionShape2D.shape.radius = 77
		elif frame_num == 4: 
			$Area2D/CollisionShape2D.shape.radius = 125
		elif frame_num >= 5: 
			$Area2D/CollisionShape2D.shape.radius = 164
			if frame_num >= 8:
				$Area2D/CollisionShape2D.disabled = true
		if $ShockwaveSprite2D.get_frame() == 14:
			queue_free()


func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		body.set_killed_by(G.MINIBOSS_ORB_EXPLOSION)
		body.die()
		
func start():
	$ShockwaveSprite2D.visible = true
	$ShockwaveSprite2D.play()
	exploding = true
	$Area2D/CollisionShape2D.disabled = false
