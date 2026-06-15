extends Node2D
class_name DamageVisuals

@export var damage_flash_color:Color = Color.RED
@export var damage_flash_duration:float = 0.05

@onready var parent_normal_modulate:Color = get_parent().modulate

var other_damage_actions:Array[Callable]

func _ready():
	$DamageModulateRevertTimer.wait_time = damage_flash_duration
	
func add_damage_action(action:Callable):
	other_damage_actions.push_back(action)

func start_visuals():
	get_parent().modulate = damage_flash_color
	$DamageModulateRevertTimer.start()
	
func _on_damage_modulate_revert_timer_timeout():
	get_parent().modulate = parent_normal_modulate
