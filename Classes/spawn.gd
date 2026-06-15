extends Node
class_name Spawn

#var location
var location_generator:Callable
var enemy:Resource
var delay:float
var enemy_instance:Node2D
var powerup:Resource = null
var parent_wave:Wave = null

func set_values(l,e:Resource,d:float,p:Resource):
	location_generator = l
	enemy = e
	delay = d
	powerup = p

#func set_parent_wave(_wave:Wave):
#	parent_wave = _wave
#
#func get_pos_within_circle(_pos:int) -> Vector2:
#	print("attempting to grab my position from the circle position generator, my pos is: ", _pos)
#	print("data in parent is: ", parent_wave.data)
#	return parent_wave.data["circle_positions"][_pos]
