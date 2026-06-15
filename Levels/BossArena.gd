extends StaticBody2D

var curve:Curve2D
var curve_points: PackedVector2Array

# Called when the node enters the scene tree for the first time.
func _ready():
	curve = $CollisionCurvePath.curve
	curve_points = curve.get_baked_points()
	$ArenaCollisionPolygon2D.polygon = curve_points

func reveal_shield():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 2.0) 

func get_normal_from_shield_to_me(me: Node2D) -> Vector2:
#	var path = $CollisionCurvePath
#	var local_pos = me.global_position - position
#	var offset = curve.get_closest_offset(local_pos)
#	var closest_point = curve.sample_baked(offset)
#	print("closest point: ", closest_point)
#	print("powerup: ", local_pos)
#	return (local_pos - closest_point).normalized()
	
	var path = $CollisionCurvePath
	var local_pos = path.to_local(me.global_position)
	var offset = curve.get_closest_offset(local_pos)
	var closest_point = curve.sample_baked(offset)

	var normal = (local_pos - closest_point).normalized()
	normal = path.global_transform.basis_xform(normal).normalized()

	return normal
