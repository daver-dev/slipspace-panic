extends Node2D

var death_powerup:Dictionary = {} #using with get_instance_id() of enemy to determine action upond death

func _ready():
	pass
#	child_exiting_tree.connect(check_for_powerup)

#func _process(delta):
#	$"../Label".text = "NODES: " + str(get_child_count(false))

func check_for_powerup(node:Node2D):
	if death_powerup.has(node.get_instance_id()):
		var powerup:Node2D = death_powerup.get(node.get_instance_id()).instantiate()
		powerup.global_position = node.global_position
		if node.is_in_group("miniboss"):
			powerup.global_position = node.get_death_position()
			await get_tree().create_timer(2.0, false).timeout
		get_parent().call_deferred("add_child", powerup)

func add_powerup_upon_death(enemy:Node2D, powerup:Resource):
	death_powerup[enemy.get_instance_id()] = powerup

func child_died(node:Node2D):
	check_for_powerup(node)
