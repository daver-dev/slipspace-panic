extends Powerup
class_name SpeedPowerup

func _on_body_entered(body):
	if body.is_in_group("player"):
#		print("I dont do anything")
#		body.upgrade_speed()
		body.play_speed_upgrade_sound()
		queue_free()
	elif body.is_in_group("Walls"):
		direction = direction.reflect(body.get_normal())
		x_speed = direction.x * speed
		y_speed = direction.y * speed
