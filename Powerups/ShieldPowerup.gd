extends Powerup
class_name BoostPowerup

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.add_shield()
		body.play_shield_upgrade_sound()
		queue_free()
	elif body.is_in_group("Walls"):
		direction = direction.reflect(body.get_normal())
		x_speed = direction.x * speed
		y_speed = direction.y * speed
	elif body.is_in_group("BossArena"):
		var normal:Vector2 = body.get_normal_from_shield_to_me(self)
		direction = direction.bounce(normal)
		x_speed = direction.x * speed
		y_speed = direction.y * speed
