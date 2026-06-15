extends Node2D
const SPEED = 400
var first_segment:CentipedeBodySegment = null
var last_segment:CentipedeBodySegment = null
var direction:Vector2 = Vector2.RIGHT
var prev_position

# Called when the node enters the scene tree for the first time.
func _ready():
	first_segment = $BodySegmentHolder/CentipedeBodySegment1
	$BodySegmentHolder/CentipedeBodySegment1.next_segment = $BodySegmentHolder/CentipedeBodySegment2
	$BodySegmentHolder/CentipedeBodySegment2.prev_segment = $BodySegmentHolder/CentipedeBodySegment1
	$BodySegmentHolder/CentipedeBodySegment2.next_segment = $BodySegmentHolder/CentipedeBodySegment3
	$BodySegmentHolder/CentipedeBodySegment3.prev_segment = $BodySegmentHolder/CentipedeBodySegment2
	$BodySegmentHolder/CentipedeBodySegment3.next_segment = $BodySegmentHolder/CentipedeBodySegment4
	$BodySegmentHolder/CentipedeBodySegment4.prev_segment = $BodySegmentHolder/CentipedeBodySegment3
	$BodySegmentHolder/CentipedeBodySegment4.next_segment = $BodySegmentHolder/CentipedeBodySegment5
	$BodySegmentHolder/CentipedeBodySegment5.prev_segment = $BodySegmentHolder/CentipedeBodySegment4
	$BodySegmentHolder/CentipedeBodySegment5.next_segment = $BodySegmentHolder/CentipedeBodySegment6
	$BodySegmentHolder/CentipedeBodySegment6.prev_segment = $BodySegmentHolder/CentipedeBodySegment5
	$BodySegmentHolder/CentipedeBodySegment6.next_segment = $BodySegmentHolder/CentipedeBodySegment7
	$BodySegmentHolder/CentipedeBodySegment7.prev_segment = $BodySegmentHolder/CentipedeBodySegment6
	last_segment = $BodySegmentHolder/CentipedeBodySegment7

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	prev_position = $CentipedeHead.position
	$CentipedeHead.position.x += SPEED * direction.x * delta
	$CentipedeHead.position.y += SPEED * direction.y * delta
	if $BodySegmentHolder.get_child_count() > 0:
		first_segment.prev_position = first_segment.position
		first_segment.position += ($CentipedeHead.position - prev_position)
		if first_segment == last_segment:
			pass
		else:
			var current = first_segment.next_segment
			current.prev_position = current.position
			current.position += (current.prev_segment.position - current.prev_segment.prev_position)
			while current != last_segment:
				current.next_segment.prev_position = current.next_segment.position
				current.next_segment.position += (current.position - current.prev_position)
				current = current.next_segment
		$CentipedeTail.position += (last_segment.position - last_segment.prev_position)
	else:
		$CentipedeTail.position += ($CentipedeHead.position - prev_position)
