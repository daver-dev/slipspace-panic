## CircleDistributor.gd
## Static utility for distributing points evenly on a circle arc clipped to a rectangle.
## Register as an Autoload (Project > Project Settings > Autoload) or call statically.

class_name CircleDistributor


## Returns an Array[Vector2] of world positions evenly spread on the largest arc
## of a circle (centered on player_pos, with given radius) that fits within
## playfield_rect shrunk by edge_margin on all sides.
##
## Arguments:
##   player_pos  — center of the circle in global coordinates
##   radius      — spawn circle radius
##   node_count  — number of positions to generate
##   playfield   — the bounding rectangle in global coordinates
##   edge_margin — fixed inset from each edge; keeps nodes away from boundaries
static func get_positions(
		player_pos: Vector2,
		radius: float,
		node_count: int,
		playfield: Rect2,
		edge_margin: float
		) -> Array[Vector2]:
	var shrunk := playfield.grow(-edge_margin)

	# Early out: circle's AABB fits entirely inside the shrunk rect, no clipping possible
	if shrunk.position.x <= player_pos.x - radius \
	and shrunk.position.y <= player_pos.y - radius \
	and shrunk.end.x      >= player_pos.x + radius \
	and shrunk.end.y      >= player_pos.y + radius:
		return _spread_on_arc(player_pos, radius, node_count, 0.0, TAU)

	var intersections := _circle_rect_intersections(player_pos, radius, shrunk)
	var arc_start: float
	var arc_end: float

	if intersections.is_empty():
		arc_start = 0.0
		arc_end = TAU
	else:
		intersections.sort()
		var best_span := -1.0
		var count := intersections.size()
		for i in range(count):
			var a_start: float = intersections[i]
			var a_end: float = intersections[(i + 1) % count]
			if a_end <= a_start:
				a_end += TAU
			var mid_angle := (a_start + a_end) / 2.0
			var mid_point := player_pos + Vector2(cos(mid_angle), sin(mid_angle)) * radius
			if shrunk.has_point(mid_point):
				var span := a_end - a_start
				if span > best_span:
					best_span = span
					arc_start = a_start
					arc_end = a_end

	return _spread_on_arc(player_pos, radius, node_count, arc_start, arc_end)


static func _spread_on_arc(
		center: Vector2,
		radius: float,
		count: int,
		arc_start: float,
		arc_end: float
) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var span := arc_end - arc_start
	# Full circle: divide by count to avoid placing nodes at both 0° and 360°
	# Partial arc: divide by count - 1 so nodes land on both endpoints
	var is_full_circle := absf(span - TAU) < 0.0001
	var divisions := count if is_full_circle else count - 1
	for i in range(count):
		var t := float(i) / float(max(divisions, 1))
		var angle := arc_start + t * span
		positions.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return positions


static func _circle_rect_intersections(
		center: Vector2,
		radius: float,
		rect: Rect2
) -> Array[float]:
	var angles: Array[float] = []

	var edges = [
		[Vector2(rect.position.x, rect.position.y), Vector2(rect.end.x,      rect.position.y), true ],  # top
		[Vector2(rect.position.x, rect.end.y      ), Vector2(rect.end.x,      rect.end.y      ), true ],  # bottom
		[Vector2(rect.position.x, rect.position.y), Vector2(rect.position.x, rect.end.y      ), false],  # left
		[Vector2(rect.end.x,      rect.position.y), Vector2(rect.end.x,      rect.end.y      ), false],  # right
	]

	for edge in edges:
		var p1: Vector2 = edge[0]
		var p2: Vector2 = edge[1]
		var horizontal: bool = edge[2]

		if horizontal:
			var dy := p1.y - center.y
			if abs(dy) > radius:
				continue
			var dx := sqrt(radius * radius - dy * dy)
			for x_hit in [center.x - dx, center.x + dx]:
				if x_hit >= p1.x and x_hit <= p2.x:
					angles.append(_normalize_angle(atan2(dy, x_hit - center.x)))
		else:
			var dx := p1.x - center.x
			if abs(dx) > radius:
				continue
			var dy_val := sqrt(radius * radius - dx * dx)
			for y_hit in [center.y - dy_val, center.y + dy_val]:
				if y_hit >= p1.y and y_hit <= p2.y:
					angles.append(_normalize_angle(atan2(y_hit - center.y, dx)))

	return angles


static func _normalize_angle(a: float) -> float:
	while a < 0.0:
		a += TAU
	while a >= TAU:
		a -= TAU
	return a
