extends RigidBody2D
class_name CentipedeBodySegment

var prev_segment:CentipedeBodySegment = null
var next_segment:CentipedeBodySegment = null
var prev_position

func _ready():
	prev_position = position
