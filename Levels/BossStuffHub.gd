extends Node2D

@export var boss_scene : PackedScene
@onready var camera = $"../Camera2D"
@onready var boss_arena = $"../Camera2D"
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func spawn_boss():
#	$BossArena/BossArenaCollision.disabled = false
	$"../BossArena/WaveyShield".show()
	$"../BossArena/WaveyShield2".show()
	$"../BossArena/WaveyShield3".show()
#	$"../BossArena/BossArenaCollision".disabled = false
	var enemy = boss_scene.instantiate()
	enemy.position = Vector2(0.0,-1800.0)
	$"..".add_child_and_update_enemies_on_field(enemy)
	$"..".boss_is_alive = true
	camera.preboss()
	$"../BossArena/ArenaCollisionPolygon2D".disabled = false
