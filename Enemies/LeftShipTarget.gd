extends ShipTarget

func _ready():
	position = Vector2(-400, player.global_position.y)
	destination = Vector2(-400, player.global_position.y)
	is_left_ship = true


#Other stuff has been moved to ship_target.gd to avoid duplication of code
