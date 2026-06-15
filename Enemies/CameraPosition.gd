extends CharacterBody2D

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group('player')
@onready var boss: Node2D = get_tree().get_first_node_in_group('boss')

func _process(delta):
	var halfway_positionx = (player.global_position.x + boss.global_position.x) * 0.5
	var halfway_positiony = (player.global_position.y + boss.global_position.y) * 0.5
	
	var quarterway_positionx = (player.global_position.x + halfway_positionx) * 0.5
	var quarterway_positiony = (player.global_position.y + halfway_positiony) * 0.5
	
	var thirdway_positionx = (quarterway_positionx + halfway_positionx) * 0.5
	var thirdway_positiony = (quarterway_positiony + halfway_positiony) * 0.5
	global_position = Vector2(halfway_positionx,halfway_positiony)
