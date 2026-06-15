extends CharacterBody2D

var dead = false

func take_damage(dmg):
	$"..".take_damage_parent(dmg)

func set_targeting_node(t_node:Node2D):
	$"..".set_targeting_node_parent(t_node)
