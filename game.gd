extends Node2D
const LEVEL_1 = preload("res://Levels/level_1.tscn")
func start_game():
#	get_tree().change_scene_to_file("res://Levels/level_1.tscn")
	get_tree().call_deferred("change_scene_to_packed", LEVEL_1)
