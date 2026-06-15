
class_name LineDistributor

static func get_positions(
	point_a_pos: Vector2,
	point_b_pos: Vector2,
	node_count: int) -> Array[Vector2]:
	var distance_vector: Vector2 = point_b_pos - point_a_pos
	var distance_between_points: Vector2 = distance_vector / (node_count - 1)
	
	var positions: Array[Vector2] = []
	
	for i in range(node_count):
		positions.push_back(point_a_pos + (distance_between_points * i))
		
	return positions
