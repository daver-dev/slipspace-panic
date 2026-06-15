extends CharacterBody2D

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group('player')
@onready var boss: CharacterBody2D = get_tree().get_first_node_in_group('boss')

@export var speed_multiplier = 2

var end_position
var position_should_freeze = false
var position_frozen = false
var target_position
var speed
var distance


func _ready():
	position = player.global_position

func _physics_process(_delta):
	if !position_should_freeze:
		# This stuff makes the target of the boss slightly behind the player
		target_position = global_position.direction_to(player.global_position)
		distance = global_position.distance_to(player.global_position) 
		speed = distance 
		velocity = target_position * speed * speed_multiplier
	elif !position_frozen:
		var ending_tween = create_tween()
		position_frozen = true
		ending_tween.tween_property(self, "velocity", target_position, 1)
	move_and_slide()
