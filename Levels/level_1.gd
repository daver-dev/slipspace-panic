extends Node2D

const FIRST_WAVE_DELAY := 1.3
const MIN_WAVE_TIME := 2.0
const DEBUG_STARTING_WAVE := 0
const BOSS_SPAWN_FADE_THEME_SONG_DURATION := 3.0
const BOSS_DEFEATED_FADE_OUT_MUSIC_DURATION := 2.0
#@export var blue_guy_scene : PackedScene
#@export var rammer_scene : PackedScene
#@export var bullet_spinner_scene : PackedScene
#@export var swarmer_scene : PackedScene
#@export var miniboss_scene : PackedScene
#@export var minion_scene : PackedScene
#@export var wanderer_scene : PackedScene

var blue_guy = load("res://Enemies/enemy_1.tscn")
var wanderer = load("res://Enemies/enemy_4.tscn")
var rammer = load("res://Enemies/enemy_2.tscn")
var spinner = load("res://Enemies/enemy_3.tscn")
var swarmer = load("res://Enemies/swarm_enemy.tscn")
var miniboss = load("res://Enemies/mini_boss.tscn")
var minion = load("res://Enemies/boss_minion.tscn")
var boss = load("res://Enemies/boss.tscn")

@export var gun_powerup_scene : PackedScene
@export var missile_powerup_scene : PackedScene
@export var boost_powerup_scene : PackedScene
@export var theme_song_volume_db:float 
@export var theme_song_delay_to_start:float
@export var warning_arrow:PackedScene
@export var sandbox_mode : bool

const DEFAULT_PLAYER_ENEMY_MIN_SPACE = 100

#func set_params(l:Vector2,e:Resource,d:float):
var waves_arr:Array[Wave]

var last_ship_pos
var last_enemy_pos
var rand = RandomNumberGenerator.new()

var scale_speed = 0.0
var clock = 0.0
var enemies_killed = 0
var current_killcount_powerup_checked = false
var enemies_instantiated = 0

var one_thru_four = []
var waves_array = []
var enemies_on_field = []
var action
var boss_is_alive = true
var credits_triggered = false

var boss_is_instantiated = false
var boss_cam

enum states {STARTING=0, MAIN_GAME=1, BOSS_FIGHT=2, VICTORY=3, DEATH=4}
var state = states.STARTING

var waves_have_started := false
var playfield_rect2:Rect2

var wave_counter := -1
var active_wave := -1

signal ADVANCE_WAVE

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	playfield_rect2 = Rect2(
		$PlayArea.global_position - $PlayArea/CollisionShape2D.shape.size / 2.0,
		$PlayArea/CollisionShape2D.shape.size
	)
	last_ship_pos = Vector2.ZERO
	build_waves()
	for wave in waves_arr:
		$WaveObjNode.add_child(wave)
		for spawn in wave.spawns:
			wave.add_child(spawn)

	$ThemeSong.volume_db = theme_song_volume_db
	$PlayerShip.I_DIED.connect(player_died_stuff)
	get_tree().create_timer(theme_song_delay_to_start, false).timeout.connect(play_theme)
	scale.x = .01
	scale.y = .01
	reset_one_thru_four()

#	spawn_single_enemy_center(miniboss_scene, time_start + 2.0)
	if sandbox_mode:
		pass
	
	else:
		spawn_waves(waves_arr)

func _physics_process(delta):
	#Zoom in effect
	if state == states.STARTING:
		scale_speed += delta * 0.01
		scale.x += scale_speed
		scale.y += scale_speed
		if scale.x > 1:
			scale.x = 1
			scale.y = 1
			state = states.MAIN_GAME
			$PlayerShip.controls_enabled = true
			
	elif state == states.MAIN_GAME:
		# The zoom-in/scaling causes the credits area to be entered right at the start, 
		# so wait til its zoomed in
		if $CreditsTriggerArea/CreditsTriggerCollision.disabled:
			$CreditsTriggerArea/CreditsTriggerCollision.disabled = false
		clock += delta
		QuitHandler.game_clock_sec = clock
		check_if_enemies_cleared()
		
	elif state == states.BOSS_FIGHT:
		clock += delta

func check_if_enemies_cleared():
	if waves_have_started:
		if !$EnemiesNode2D.get_child_count(false):
			ADVANCE_WAVE.emit()
		else:
			if $EnemiesNode2D.get_child_count(false) == 1:
				if $EnemiesNode2D.get_child(0).is_in_group("miniboss") && $EnemiesNode2D.get_child(0).dead:
					#prevent boss spawn while waiting for orb explosion
					if active_wave < 16:
						ADVANCE_WAVE.emit()

# func get_pos_within_circle(my_index:int, positions_arr:Array[Vector2]) -> Vector2:
# 	return positions_arr[my_index]

#func create_circle_of_spawns(
#		enemy_scene_arr:Array[PackedScene] = [blue_guy, wanderer], 
#		radius:float = 100.0
#	) -> Array[Spawn]:
#
#	var spawn_arr:Array[Spawn] = []
#	for scene in enemy_scene_arr:
#		var spawn = create_spawn(
#			func(): return $PlayerShip.position + Vector2(34.2, 47.9),
#			scene,
#			0.1
#		)
#		spawn_arr.push_back(spawn)
#	return spawn_arr

func dummy_func():
	pass

func get_wave_counter():
	wave_counter += 1
	return wave_counter

func build_waves():	
	create_wave([
		create_spawn(return_vec.bind($CenterCornerMarker1.global_position), wanderer, 0.0),
		create_spawn(return_vec.bind($CenterCornerMarker2.global_position), wanderer, 0.2),
		create_spawn(return_vec.bind($CenterCornerMarker3.global_position), wanderer, 0.2),
		create_spawn(return_vec.bind($CenterCornerMarker4.global_position), wanderer, 0.2)
	], 5, 0.0)

	create_wave([
		create_spawn(return_vec.bind($IntermediateCornerMarker1.global_position), wanderer, 0.0),
		create_spawn(return_vec.bind($IntermediateCenterMarker2.global_position), blue_guy, 0.2),
		create_spawn(return_vec.bind($IntermediateCornerMarker4.global_position), wanderer, 0.2),
		create_spawn(return_vec.bind($IntermediateCornerMarker2.global_position), wanderer, 0.2),
		create_spawn(return_vec.bind($IntermediateCenterMarker4.global_position), blue_guy, 0.2),
		create_spawn(return_vec.bind($IntermediateCornerMarker3.global_position), wanderer, 0.2)
	], 10.0, 0.0)

	create_wave([
		create_spawn(return_vec.bind($IntermediateCornerMarker1.global_position), blue_guy, 0.0),
		create_spawn(return_vec.bind($IntermediateCenterMarker4.global_position), blue_guy, 0.1),
		create_spawn(return_vec.bind($IntermediateCornerMarker4.global_position), blue_guy, 0.1),
		create_spawn(return_vec.bind($IntermediateCornerMarker2.global_position), blue_guy, 0.1),
		create_spawn(return_vec.bind($IntermediateCenterMarker2.global_position), blue_guy, 0.1),
		create_spawn(return_vec.bind($IntermediateCornerMarker3.global_position), blue_guy, 0.1, gun_powerup_scene)
	], 8.0, 0.0)
	# 1 gun

	create_wave([
		create_spawn(return_vec.bind($CenterMarker.global_position), rammer, 0.0, boost_powerup_scene),
	], 10.0, 0.0)

	create_wave([
		create_spawn(return_vec.bind($IntermediateCenterMarker4.global_position), rammer, 1.0),
		create_spawn(return_vec.bind($IntermediateCenterMarker2.global_position), rammer, 0.5),
		create_spawn(return_vec.bind($IntermediateCenterMarker1.global_position), blue_guy, 0.5),
		create_spawn(return_vec.bind($IntermediateCenterMarker3.global_position), blue_guy, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker1.global_position), wanderer, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker2.global_position), wanderer, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker3.global_position), wanderer, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker4.global_position), wanderer, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker1.global_position), wanderer, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker2.global_position), wanderer, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker3.global_position), wanderer, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker4.global_position), wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.5),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.5),
	], 10.0, 0.0)

	create_wave([
		create_spawn(return_vec.bind($CenterMarker.global_position), swarmer, 0.0),
		create_spawn(return_vec.bind($CenterCornerMarker1.global_position), wanderer, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker2.global_position), wanderer, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker3.global_position), wanderer, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker4.global_position), wanderer, 0.1),
		create_spawn(return_vec.bind($IntermediateCornerMarker1.global_position), blue_guy, 0.1),
		create_spawn(return_vec.bind($IntermediateCornerMarker2.global_position), blue_guy, 0.1),
		create_spawn(return_vec.bind($IntermediateCornerMarker3.global_position), blue_guy, 1),
		create_spawn(return_vec.bind($IntermediateCornerMarker4.global_position), blue_guy, 1),
		create_spawn(return_vec.bind($CenterMarker.global_position), rammer, 2.0),
	], 10.0, 0.5)

	create_wave([
		create_spawn(return_vec.bind($CenterMarker.global_position), spinner, 0.0, missile_powerup_scene),
		create_spawn(return_vec.bind($IntermediateCornerMarker1.global_position), blue_guy, 0.1),
		create_spawn(return_vec.bind($IntermediateCornerMarker2.global_position), blue_guy, 0.1),
		create_spawn(return_vec.bind($IntermediateCornerMarker3.global_position), blue_guy, 0.1),
		create_spawn(return_vec.bind($IntermediateCornerMarker4.global_position), blue_guy, 0.1),
	], 10.0, 0.0)
	# 1 missile 

	# wave 6
	create_wave([
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1, boost_powerup_scene),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(return_vec.bind($IntermediateCenterMarker5.global_position), minion, 0.5),
		create_spawn(return_vec.bind($IntermediateCenterMarker1.global_position), minion, 0.1),
		create_spawn(return_vec.bind($IntermediateCenterMarker6.global_position), minion, 0.1),
		create_spawn(return_vec.bind($IntermediateCenterMarker3.global_position), minion, 0.1),
		create_spawn(return_vec.bind($IntermediateCenterMarker5.global_position), minion, 0.5),
		create_spawn(return_vec.bind($IntermediateCenterMarker1.global_position), minion, 0.1),
		create_spawn(return_vec.bind($IntermediateCenterMarker6.global_position), minion, 0.1),
		create_spawn(return_vec.bind($IntermediateCenterMarker3.global_position), minion, 0.1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.1),
		create_spawn(get_a_vector_not_near_player, minion, 0.5),
		create_spawn(get_a_vector_not_near_player, minion, 0.5),
		create_spawn(get_a_vector_not_near_player, minion, 1.0),
		create_spawn(get_a_vector_not_near_player, minion, 1.0),
		create_spawn(get_a_vector_not_near_player, minion, 1.0),
		# 3 sec break after 4 minions
		create_spawn(return_vec.bind($CenterMarker.global_position), swarmer, 2.0, gun_powerup_scene),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.1),
		create_spawn(return_vec.bind($IntermediateCenterMarker3.global_position), minion, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker4.global_position), minion, 0.1),
		create_spawn(return_vec.bind($IntermediateCenterMarker5.global_position), minion, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker1.global_position), minion, 0.1),
		create_spawn(return_vec.bind($IntermediateCenterMarker1.global_position), minion, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker2.global_position), minion, 0.1),
		create_spawn(return_vec.bind($IntermediateCenterMarker6.global_position), minion, 0.1),
		create_spawn(return_vec.bind($CenterCornerMarker3.global_position), minion, 0.1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.1),
		create_spawn(get_a_vector_not_near_player, minion, 0.5, boost_powerup_scene),
		create_spawn(get_a_vector_not_near_player, minion, 0.5),
		create_spawn(get_a_vector_not_near_player, minion, 0.3),
		create_spawn(get_a_vector_not_near_player, minion, 0.3),
	], 8.0, 1.0)
	# 2 gun 1 missile

	create_circle_wave(6, blue_guy, 0.015, 3.0, 1.0, 500.0, boost_powerup_scene, 0)

	create_circle_wave(8, blue_guy, 0.015, 3.0, 1.0, 500.0, boost_powerup_scene, 3)

	create_circle_wave(10, blue_guy, 0.015, 3.0, 0.5, 500.0, boost_powerup_scene, 2)

	create_circle_wave(12, blue_guy, 0.015, 3.0, 0.5, 500.0, 2)
	
	create_circle_wave(20, blue_guy, 0.005, 3.0, 0.5, 500.0, boost_powerup_scene, 2)

	create_wave([
		create_spawn(return_vec.bind($IntermediateCenterMarker4.global_position), spinner, 1, missile_powerup_scene),
		create_spawn(return_vec.bind($IntermediateCenterMarker2.global_position), spinner, 0.5),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.5),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.5),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.5),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.5),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08, boost_powerup_scene),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
		create_spawn(get_a_vector_not_near_player, wanderer, 0.1),
	], 15, 0.0)
	# 2 gun 2 missile
	create_wave([
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft1.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft2.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft3.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft4.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft5.global_position), minion, 0.08, boost_powerup_scene),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft6.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft7.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft8.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft9.global_position), minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, rammer, 2, boost_powerup_scene),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight1.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight2.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight3.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight4.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight5.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight6.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight7.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight8.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight9.global_position), minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, rammer, 1, boost_powerup_scene),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight1.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight2.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight3.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight4.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight5.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight6.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight7.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight8.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight9.global_position), minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, rammer, 1),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomLeft1.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomLeft2.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomLeft3.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomLeft4.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomLeft5.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomLeft6.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomLeft7.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomLeft8.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomLeft9.global_position), minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, rammer, 1, boost_powerup_scene),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft1.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft2.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft3.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft4.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft5.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft6.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft7.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft8.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopLeft9.global_position), minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, rammer, 2, boost_powerup_scene),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight1.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight2.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight3.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight4.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight5.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight6.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight7.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight8.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/TopRight9.global_position), minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, rammer, 1),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight1.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight2.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight3.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight4.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight5.global_position), minion, 0.08, boost_powerup_scene),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight6.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight7.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight8.global_position), minion, 0.08),
		create_spawn(return_vec.bind($QuadrantMarkers/BottomRight9.global_position), minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, rammer, 1)

	], 15, 0.0)

	create_wave([
		create_spawn(return_vec.bind($CenterMarker.global_position), miniboss, 1, gun_powerup_scene),
	], 35, 0.0)
	# 3 gun 2 missile

	create_wave([
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.08),
		create_spawn(get_a_vector_not_near_player, minion, 0.08),
		create_spawn(get_a_vector_not_near_player, blue_guy, 0.08),
		create_spawn(get_position_relative_to_player.bind(0, -500), rammer, 5.0, boost_powerup_scene),
		create_spawn(get_position_relative_to_player.bind(500, 0), rammer, 1.0),
		create_spawn(get_position_relative_to_player.bind(0, 500), rammer, 1.0),
		create_spawn(get_position_relative_to_player.bind(-500, 0), rammer, 1.0, boost_powerup_scene)
	], 5.0, 0.0)

	create_wave([
		create_spawn(get_a_vector_not_near_player.bind(150,600), minion, 0.08, boost_powerup_scene),
		create_spawn(get_a_vector_not_near_player.bind(150,600), minion, 0.08),
		create_spawn(get_a_vector_not_near_player.bind(150,600), minion, 0.08),
		create_spawn(get_position_relative_to_player.bind(0, -500), rammer, 0.0, boost_powerup_scene),
		create_spawn(get_position_relative_to_player.bind(500, 0), rammer, 0.7),
		create_spawn(get_position_relative_to_player.bind(0, 500), rammer, 0.7),
		create_spawn(get_position_relative_to_player.bind(-500, 0), rammer, 0.7, boost_powerup_scene),
		create_spawn(get_position_relative_to_player.bind(0, -500), rammer, 0.7),
		create_spawn(get_position_relative_to_player.bind(500, 0), rammer, 0.7),
		create_spawn(get_a_vector_not_near_player.bind(150,600), minion, 0.0),
		create_spawn(get_a_vector_not_near_player.bind(150,600), minion, 0.0, boost_powerup_scene),
		create_spawn(get_a_vector_not_near_player.bind(150,600), minion, 0.08),
		create_spawn(get_a_vector_not_near_player.bind(150,600), minion, 0.08),
		create_spawn(get_position_relative_to_player.bind(-500, -500), rammer, 3.0),
		create_spawn(get_position_relative_to_player.bind(500, -500), rammer, 0.6),
		create_spawn(get_position_relative_to_player.bind(500, 500), rammer, 0.6),
		create_spawn(get_position_relative_to_player.bind(-500, 500), rammer, 0.6),
		create_spawn(get_position_relative_to_player.bind(-500, -500), rammer, 0.6),
		create_spawn(get_position_relative_to_player.bind(500, -500), rammer, 0.6, boost_powerup_scene),
		create_spawn(get_position_relative_to_player.bind(500, 500), rammer, 0.6),
		create_spawn(get_position_relative_to_player.bind(-500, 500), rammer, 0.6),
		create_spawn(get_position_relative_to_player.bind(-500, -500), rammer, 0.6),
		create_spawn(get_position_relative_to_player.bind(-500, 500), rammer, 0.6, missile_powerup_scene),
		create_spawn(get_a_vector_not_near_player.bind(150,600), minion, 0.0),
		create_spawn(get_a_vector_not_near_player.bind(150,600), minion, 0.0),
		create_spawn(get_a_vector_not_near_player.bind(150,600), minion, 0.08),
		create_spawn(get_a_vector_not_near_player.bind(150,600), minion, 0.08, gun_powerup_scene),
	], 20, 1.0)
	# 3 gun 3 missile

	# rammers on left then right
	create_line_wave_between_points($CornerMarker1.global_position, $CornerMarker4.global_position, 7, rammer, 0.05, 10.0, 1.0, boost_powerup_scene, [6])

	create_line_wave_between_points($CornerMarker2.global_position, $CornerMarker3.global_position, 7, rammer, 0.05, 10.0, 1.0, boost_powerup_scene, [6])


	create_line_wave_between_points($CornerMarker1.global_position, $CornerMarker2.global_position, 7, minion, 0.05, 0.0, 1.0, boost_powerup_scene, [6])

	create_line_wave_between_points($CornerMarker3.global_position, $CornerMarker4.global_position, 7, minion, 0.05, 0.0, 0.0, boost_powerup_scene, [6])

	create_wave([
		create_spawn(return_vec.bind($CornerMarker1.global_position), swarmer, 0.08),
		create_spawn(return_vec.bind($CornerMarker2.global_position), swarmer, 0.08),
		create_spawn(return_vec.bind($CornerMarker3.global_position), swarmer, 0.08),
		create_spawn(return_vec.bind($CornerMarker4.global_position), swarmer, 0.08),
	], 0.0, 1.0)

	create_line_wave_between_points($CornerMarker2.global_position, $CornerMarker3.global_position, 7, minion, 0.05, 0.0, 0.0)

	create_line_wave_between_points($CornerMarker4.global_position, $CornerMarker1.global_position, 7, minion, 0.05, 0.0, 0.0)

	create_wave([
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 2, boost_powerup_scene),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0, boost_powerup_scene),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0, boost_powerup_scene),
		create_spawn(get_a_vector_not_near_player.bind(150,600), blue_guy, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1, boost_powerup_scene),
		create_spawn(get_a_vector_not_near_player.bind(150,600), blue_guy, 0.01),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(get_a_vector_not_near_player.bind(150,600), blue_guy, 0.01),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 2),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(get_a_vector_not_near_player.bind(150,600), blue_guy, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(get_a_vector_not_near_player.bind(150,600), blue_guy, 0.01),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(get_a_vector_not_near_player.bind(150,600), blue_guy, 0.01),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(get_a_vector_not_near_player.bind(150,600), swarmer, 0.2),
		create_spawn(get_a_vector_not_near_player.bind(150,600), swarmer, 0.2),
		create_spawn(get_a_vector_not_near_player.bind(150,600), blue_guy, 0.2),
		create_spawn(get_a_vector_not_near_player.bind(150,600), blue_guy, 0.2),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(get_a_vector_not_near_player.bind(150,600), blue_guy, 0.01),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(get_a_vector_not_near_player.bind(150,600), blue_guy, 0.01),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker1.global_position + add_small_offset()), minion, 0.1),
		create_spawn(return_vec.bind($CornerMarker2.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker3.global_position + add_small_offset()), minion, 0.0),
		create_spawn(return_vec.bind($CornerMarker4.global_position + add_small_offset()), minion, 0.0),
		create_spawn(get_a_vector_not_near_player.bind(150,600), blue_guy, 0.01),
	], 20, 1.0)

	create_wave([
		create_spawn(return_vec.bind($IntermediateCenterMarker1.global_position), miniboss, 3, boost_powerup_scene),
		create_spawn(return_vec.bind($IntermediateCenterMarker3.global_position), miniboss, 1.0),
	], 9999999, 0.0)

	create_wave([create_spawn(return_vec.bind(Vector2(0.0,-1800.0)), boss, 0.0)], 0.0, 0.1, pre_spawn_boss)
	
#	# 3 gun 2 missile
func add_small_offset():
	return (Vector2.UP * randf_range(1, 100)).rotated(randf_range(-PI, PI))

func get_position_relative_to_player(offset_x: int, offset_y:):
	var offset = Vector2(offset_x, offset_y)
	var player_position = get_player_position()
	var play_area_rect = $PlayArea/CollisionShape2D.shape.get_rect()
	var slightly_smaller_than_play_area_rect = play_area_rect.grow(-200)
	var spawn_position_x = player_position.x + (offset.x if slightly_smaller_than_play_area_rect.has_point(Vector2(player_position.x + offset.x, 0)) else -offset.x)
	var spawn_position_y = player_position.y + (offset.y if slightly_smaller_than_play_area_rect.has_point(Vector2(0, player_position.y + offset.y)) else -offset.y)
	return Vector2(spawn_position_x,spawn_position_y)

func create_line_wave_between_points(
	point_a: Vector2,
	point_b: Vector2,
	num_enemies:int, 
	which_enemy:PackedScene, 
	delay_between_each_enemy: float, 
	wave_time: float, 
	start_delay: float,
	item_to_drop = null, 
	enemy_indexes_to_drop_item = []):
	var this_wave = create_wave([], wave_time, start_delay, line_setup.bind(point_a, point_b, num_enemies))
	for i in range(num_enemies):
		var spawn
		if i in enemy_indexes_to_drop_item:
			spawn = create_spawn(get_pos_within_line.bind(i, this_wave), which_enemy, delay_between_each_enemy, item_to_drop)
		else:
			spawn = create_spawn(get_pos_within_line.bind(i, this_wave), which_enemy, delay_between_each_enemy)
		this_wave.spawns.push_back(spawn)

func line_setup(pos_a: Vector2, pos_b: Vector2, node_count:int = 6): 
	# this is a setup function for a wave that creates an array of positions in a circle around the player 
	# and stores it in the wave's data dict for the spawns to access when they spawn
	var data_dict = {}
	data_dict["line_positions"] = LineDistributor.get_positions(
		pos_a,
		pos_b,
		node_count,                  # node_count
	)
	return data_dict
	
func get_pos_within_line(enemy_index:int, wave:Wave) -> Vector2:
	return wave.data.get("line_positions")[enemy_index]

func create_circle_wave(
	num_enemies:int, 
	which_enemy:PackedScene, 
	delay_between_each_enemy:float, 
	wave_time: float,
	start_delay:float,
	radius: float = 300.0,
	item_to_drop = null,
	enemy_index_to_drop_item = null) -> Wave:
	var return_wave = create_wave([], wave_time, start_delay, circle_setup.bind(radius, num_enemies, get_player_position))
	for i in range(num_enemies):
		var spawn
		if i == enemy_index_to_drop_item:
			spawn = create_spawn(get_pos_within_circle.bind(i, return_wave), which_enemy, i*delay_between_each_enemy, item_to_drop)
		else:
			spawn = create_spawn(get_pos_within_circle.bind(i, return_wave), which_enemy, i*delay_between_each_enemy)
		return_wave.spawns.push_back(spawn)
	return return_wave

func circle_setup(radius:float = 150.0, child_count:int = 6, center_offset_getter:Callable = func(): return Vector2.ZERO): 
	# this is a setup function for a wave that creates an array of positions in a circle around the player 
	# and stores it in the wave's data dict for the spawns to access when they spawn
	var data_dict = {}
	data_dict["circle_positions"] = CircleDistributor.get_positions(
		center_offset_getter.call(),  # center
		radius,                       # radius
		child_count,                  # node_count
		playfield_rect2,              # playfield
		50.0                          # edge_margin
	)
	return data_dict

func get_pos_within_circle(enemy_index:int, wave:Wave) -> Vector2:
	return wave.data.get("circle_positions")[enemy_index]

#TODO: Make this accept an item optionally that the enemy drops
func create_spawn(location:Callable, enemy:Resource,delay:float, powerup:Resource=null) -> Spawn:
	var spawn = Spawn.new()
	spawn.set_values(location, enemy, delay, powerup)
	# print("spawn:",spawn)
	return spawn

func create_wave(spawns:Array[Spawn], time_length_sec:float, start_delay:float, setup:Callable = func(): return {}) -> Wave:
	var wave = Wave.new()
	@warning_ignore("narrowing_conversion")
	wave.set_values(spawns, time_length_sec, start_delay, get_wave_counter(), setup)
	# print("wave",wave)
	waves_arr.push_back(wave)
	return wave
	
func spawn_waves(waves:Array[Wave]):
	await get_tree().create_timer(FIRST_WAVE_DELAY, false).timeout
	for wave in waves:
		if $PlayerShip.dead:
			return
		await spawn_enemy_wave(wave)
		if wave.id == DEBUG_STARTING_WAVE:
			waves_have_started = true
#		G.HUD.hud_print('spawned enemy wave ' + str(wave.id))
		if wave.time_length_sec != 0:
			await ADVANCE_WAVE
#		print('ADVANCE_WAVE received ', wave.id)

func advance_wave():
	ADVANCE_WAVE.emit()

func spawn_enemy_wave(wave:Wave):
#	assert(wave.time_length_sec > MIN_WAVE_TIME, "FUCK YOU! Too short of a wave. MUST BE " + str(MIN_WAVE_TIME) + "SECONDS")
	await get_tree().create_timer(wave.time_delay_start, false).timeout
	$WaveAdvanceTimer.wait_time = wave.time_length_sec #TODO: Got two warnings about this should be >0
	$WaveAdvanceTimer.start()
	wave.call_setup()
	for spawn in wave.spawns:
		await get_tree().create_timer(spawn.delay, false).timeout
		var new_enemy: Node2D = spawn.enemy.instantiate()
		if new_enemy.has_method("make_non_boss_spawn"):
			new_enemy.make_non_boss_spawn()
		if spawn.powerup:
			$EnemiesNode2D.add_powerup_upon_death(new_enemy, spawn.powerup)
		spawn.enemy_instance = new_enemy
#		if spawn.location is String && spawn.location == "random":
#			new_enemy.position = get_a_vector_not_near_player()
#		else:
#			new_enemy.position = spawn.location
		new_enemy.position = spawn.location_generator.call()
		$EnemiesNode2D.add_child(new_enemy)
		if !new_enemy.is_in_group("boss"):
			create_warning_arrow($PlayerShip, new_enemy, $Camera2D)
		else:
			var music_tween = create_tween()
			music_tween.tween_property($ThemeSong, "volume_db", -80.0, BOSS_SPAWN_FADE_THEME_SONG_DURATION)
			await music_tween.finished
			$ThemeSong.stop()
			
	wave.started = true
	active_wave = wave.id
#	wave.COMPLETED.connect(recieved_wave_signal)

func start_boss_music():
	$BossSongIntro.play()
	$IntroSongTimer.start()

func fade_out_boss_music():
	var music_tween = create_tween()
	music_tween.tween_property($BossSongLoop, "volume_db", -80.0, BOSS_DEFEATED_FADE_OUT_MUSIC_DURATION)
	await music_tween.finished
	$BossSongLoop.stop()

func create_warning_arrow(player: Node2D, enemy: Node2D, camera: Camera2D):
	var arrow = warning_arrow.instantiate()
	arrow.set_values(player, enemy, camera)
	add_child(arrow)

func recieved_wave_signal(id: int, caller: String):
#	print('signal received: ', id, caller)
	$Label.text += str("\n RECEIVED_SIGNAL:TRUE, ID: ", id, caller)
	
func player_died_stuff():
	$IntroSongTimer.stop()
	$ThemeSong.stop()
	$BossSongIntro.stop()
	$BossSongLoop.stop()

func add_child_and_update_enemies_on_field(enemy):
	enemies_on_field.append(enemy)
	$EnemiesNode2D.add_child(enemy)
	enemies_instantiated += 1

func return_vec(vec:Vector2): #dummy method to save location as a Callable
	return vec
	
func get_a_vector_not_near_player(offset_from_edge = 150, offset_from_player = 200):
	var pos = Vector2(rand.randi_range(-$PlayArea/CollisionShape2D.shape.get_rect().size.x/2 + offset_from_edge, $PlayArea/CollisionShape2D.shape.get_rect().size.x/2 - offset_from_edge), rand.randi_range(-$PlayArea/CollisionShape2D.shape.get_rect().size.y/2 + offset_from_edge, $PlayArea/CollisionShape2D.shape.get_rect().size.y/2 - offset_from_edge))
	if abs(pos.x - last_ship_pos.x) < offset_from_player and abs(pos.y - last_ship_pos.y) < offset_from_player:
		return get_a_vector_not_near_player(offset_from_edge, offset_from_player)
	else:
		return pos
		
func get_boss_adds_spawn_location_not_near_player():
	if $PlayerShip.global_position.x >= 0:
		return $BossAddsMarkerLeft.global_position
	else:
		return $BossAddsMarkerRight.global_position

func _unhandled_input(event):
	if event is InputEventKey and sandbox_mode:
		if event.pressed and event.keycode == KEY_Z:
			sandbox_spawn_powerup("gun")
		elif event.pressed and event.keycode == KEY_X:
			sandbox_spawn_powerup("missile")
		elif event.pressed and event.keycode == KEY_C:
			sandbox_spawn_powerup("shield")
		elif event.pressed and event.keycode == KEY_1:
			spawn_single_enemy_random(blue_guy, 150, 200)
		elif event.pressed and event.keycode == KEY_2:
			spawn_single_enemy_random(rammer, 150, 400)
		elif event.pressed and event.keycode == KEY_3:
			spawn_single_enemy_random(spinner, 150, 200)
		elif event.pressed and event.keycode == KEY_4:
			spawn_single_enemy_random(wanderer, 150, 200)
		elif event.pressed and event.keycode == KEY_5:
			spawn_single_enemy_random(swarmer, 150, 200)
		elif event.pressed and event.keycode == KEY_7:
			spawn_single_enemy(miniboss, $CenterMarker)
			
		elif event.pressed and event.keycode == KEY_9:
			$BossStuffHub.spawn_boss()
			state = states.BOSS_FIGHT

		elif event.pressed and event.keycode == KEY_0:
			spawn_minion()

func pre_spawn_boss() -> Dictionary:
#	$BossArena/BossArenaCollision.disabled = false
	$BossArena/WaveyShield.show()
	$BossArena/WaveyShield2.show()
	$BossArena/WaveyShield3.show()
#	$"../BossArena/BossArenaCollision".disabled = false
#	var enemy = boss.instantiate()
#	enemy.position = Vector2(0.0,-1800.0)
#	add_child(enemy)
#	$EnemiesNode2D.add_child(enemy)
#	$"..".add_child_and_update_enemies_on_field(enemy)
	boss_is_alive = true
	$Camera2D.preboss()
	$BossArena/ArenaCollisionPolygon2D.disabled = false
	state = states.BOSS_FIGHT
	return {}

func sandbox_spawn_powerup(powerup):
	match powerup:
		"gun":
			var gun_powerup = gun_powerup_scene.instantiate()
			gun_powerup.position = get_a_vector_not_near_player(200,100)
			add_child(gun_powerup)
#		"speed":
#			var gun_powerup = ship_speed_scene.instantiate()
#			gun_powerup.position = get_a_vector_not_near_player(200,100)
#			add_child(gun_powerup)
		"shield":
			var boost_powerup = boost_powerup_scene.instantiate()
			boost_powerup.position = get_a_vector_not_near_player(200,100)
			add_child(boost_powerup)
		"missile":
			var missile_powerup = missile_powerup_scene.instantiate()
			missile_powerup.position = get_a_vector_not_near_player(200,100)
			add_child(missile_powerup)

func sort_waves_array():
	waves_array.sort_custom(func(a, b): return a.get("time") < b.get("time"))

func reset_one_thru_four():
	one_thru_four.push_back(1)
	one_thru_four.push_back(2)
	one_thru_four.push_back(3)
	one_thru_four.push_back(4)
	one_thru_four.shuffle()
		
func spawn_single_enemy_center(enemy_scene, start_timestamp):
	action = func():
		spawn_single_enemy(enemy_scene, $CenterMarker)
	waves_array.push_back( {"time": start_timestamp, "action": action } )

func spawn_single_enemy_center_look(enemy_scene, start_timestamp):
	action = func():
		spawn_single_enemy_look(enemy_scene, $CenterMarker)
	waves_array.push_back( {"time": start_timestamp, "action": action } )

func spawn_single_enemy(enemy_scene, point):
	var enemy = enemy_scene.instantiate()
	enemy.position = point.position
	add_child_and_update_enemies_on_field(enemy)
	
func spawn_single_enemy_look(enemy_scene, point):
	var enemy = enemy_scene.instantiate()
	enemy.position = point.position
	add_child_and_update_enemies_on_field(enemy)
	enemy.look_at(last_ship_pos)
	
func spawn_multiple_enemies_random(enemy_scene, num_enemies, start_timestamp, time_between, _offset_from_edge, offset_from_player):
	for i in num_enemies:
		action = func():
			spawn_single_enemy_random(enemy_scene, 50, offset_from_player)
		waves_array.push_back( {"time": start_timestamp + i*time_between, "action": action } )

func spawn_med_blob_of_small_enemies_random(enemy_scene, start_timestamp, offset_from_edge, offset_from_player):
	var pos = get_a_vector_not_near_player(offset_from_edge, offset_from_player)
	spawn_med_blob_of_small_enemies(enemy_scene, start_timestamp, pos)
	
func spawn_med_blob_of_small_enemies(enemy_scene, start_timestamp, point):
	action = func():
		spawn_ring_of_enemies_around_point_simultaneous(enemy_scene, 4, point, 60)
		spawn_ring_of_enemies_around_point_simultaneous(enemy_scene, 9, point, 150)
	waves_array.push_back( {"time": start_timestamp, "action": action } )
	
func spawn_lg_blob_of_small_enemies_random(enemy_scene, start_timestamp, offset_from_edge, offset_from_player):
	var pos = get_a_vector_not_near_player(offset_from_edge, offset_from_player)
	spawn_lg_blob_of_small_enemies(enemy_scene, start_timestamp, pos)
	
func spawn_lg_blob_of_small_enemies(enemy_scene, start_timestamp, point):
	action = func():
		spawn_ring_of_enemies_around_point_simultaneous(enemy_scene, 4, point, 60)
		spawn_ring_of_enemies_around_point_simultaneous(enemy_scene, 9, point, 150)
		spawn_ring_of_enemies_around_point_simultaneous(enemy_scene, 15, point, 240)
	waves_array.push_back( {"time": start_timestamp, "action": action } )

func spawn_outside_corners_simul(enemy_scene, start_timestamp):
	action = func():
		spawn_single_enemy_corner(enemy_scene, 1)
		spawn_single_enemy_corner(enemy_scene, 2)
		spawn_single_enemy_corner(enemy_scene, 3)
		spawn_single_enemy_corner(enemy_scene, 4)
	waves_array.push_back( {"time": start_timestamp, "action": action } )
	
func spawn_inside_corners_simul(enemy_scene, start_timestamp):
	action = func():
		spawn_single_enemy_inside_corner(enemy_scene, 1)
		spawn_single_enemy_inside_corner(enemy_scene, 2)
		spawn_single_enemy_inside_corner(enemy_scene, 3)
		spawn_single_enemy_inside_corner(enemy_scene, 4)
	waves_array.push_back( {"time": start_timestamp, "action": action } )
	
#THIS WAVE SPAWNS 2 ENEMIES IN RANDOM OF ORDER OF TOP AND BOTTOM INTERMEDIATE POINTS WITHOUT REPEATING A POINT
func spawn_interm_top_and_bottom_random(enemy_scene, start_timestamp, time_between):
	#start top
	if randi_range(0,1):
		#first enemy
		action = func(): 
			spawn_single_enemy_intermediate_center(enemy_scene, 1)
		waves_array.push_back( {"time": start_timestamp, "action": action } )
		#second enemy
		action = func(): 
			spawn_single_enemy_intermediate_center(enemy_scene, 3)
		waves_array.push_back( {"time": start_timestamp + time_between, "action": action} )
	#else start bottom
	else:
		#first enemy
		action = func(): 
			spawn_single_enemy_intermediate_center(enemy_scene, 3)
		waves_array.push_back( {"time": start_timestamp, "action": action } )
		#second enemy
		action = func(): 
			spawn_single_enemy_intermediate_center(enemy_scene, 1)
		waves_array.push_back( {"time": start_timestamp + time_between, "action": action} )

#THIS WAVE SPAWNS 4 ENEMIES IN RANDOM OF 4 INTERMEDIATE POINTS WITHOUT REPEATING A POINT
func spawn_four_interm_corners(enemy_scene, start_timestamp, time_between):
	#first enemy
	var which_corner = one_thru_four.pop_back()
	action = func(): 
		spawn_single_enemy_intermediate_corner(enemy_scene, which_corner)
	waves_array.push_back( {"time": start_timestamp, "action": action } )
	#second enemy
	which_corner = one_thru_four.pop_back()
	action = func(): 
		spawn_single_enemy_intermediate_corner(enemy_scene, which_corner)
	waves_array.push_back( {"time": start_timestamp + time_between, "action": action } )
	#third enemy
	which_corner = one_thru_four.pop_back()
	action = func(): 
		spawn_single_enemy_intermediate_corner(enemy_scene, which_corner)
	waves_array.push_back( {"time": start_timestamp + time_between * 2.0, "action": action } )
	#fourth enemy
	which_corner = one_thru_four.pop_back()
	reset_one_thru_four()
	action = func():
		spawn_single_enemy_intermediate_corner(enemy_scene, which_corner)
	waves_array.push_back( {"time": start_timestamp + time_between * 3.0, "action": action } )
	
#THIS WAVE SPAWNS 4 ENEMIES IN RANDOM OF 4 OUTSIDE POINTS WITHOUT REPEATING A POINT
func spawn_four_outside_corners(enemy_scene, start_timestamp, time_between):
	#first enemy
	var which_corner = one_thru_four.pop_back()
	action = func(): 
		spawn_single_enemy_outside_corner(enemy_scene, which_corner)
	waves_array.push_back( {"time": start_timestamp, "action": action } )
	#second enemy
	which_corner = one_thru_four.pop_back()
	action = func(): 
		spawn_single_enemy_outside_corner(enemy_scene, which_corner)
	waves_array.push_back( {"time": start_timestamp + time_between, "action": action } )
	#third enemy
	which_corner = one_thru_four.pop_back()
	action = func(): 
		spawn_single_enemy_outside_corner(enemy_scene, which_corner)
	waves_array.push_back( {"time": start_timestamp + time_between * 2.0, "action": action } )
	#fourth enemy
	which_corner = one_thru_four.pop_back()
	reset_one_thru_four()
	action = func():
		spawn_single_enemy_outside_corner(enemy_scene, which_corner)
	waves_array.push_back( {"time": start_timestamp + time_between * 3.0, "action": action } )
	
func spawn_two_interm_columns_consec_left_and_right_random(enemy_scene, start_timestamp, num_enemies, delay_between_enemies, delay_between_columns):
	if randi_range(0,1):
		#start with left
		action = func():
			spawn_intermediate_left_column_consecutive(enemy_scene, num_enemies, delay_between_enemies)
		waves_array.push_back( {"time": start_timestamp, "action": action })
		action = func():
			spawn_intermediate_right_column_consecutive(enemy_scene, num_enemies, delay_between_enemies)
		waves_array.push_back( {"time": start_timestamp + delay_between_columns, "action": action })
	else:
		#start with right
		action = func():
			spawn_intermediate_right_column_consecutive(enemy_scene, num_enemies, delay_between_enemies)
		waves_array.push_back( {"time": start_timestamp, "action": action })
		action = func():
			spawn_intermediate_left_column_consecutive(enemy_scene, num_enemies, delay_between_enemies)
		waves_array.push_back( {"time": start_timestamp + delay_between_columns, "action": action })

func spawn_two_interm_columns_consec_left_and_right_random_two_enemies(minority_enemy_scene, majority_enemy_scene, start_timestamp, num_enemies, delay_between_enemies, delay_between_columns):
	if randi_range(0,1):
		#start with left
		action = func():
			spawn_intermediate_left_column_consecutive_two_enemies(minority_enemy_scene, majority_enemy_scene, num_enemies, delay_between_enemies)
		waves_array.push_back( {"time": start_timestamp, "action": action })
		action = func():
			spawn_intermediate_right_column_consecutive_two_enemies(minority_enemy_scene, majority_enemy_scene, num_enemies, delay_between_enemies)
		waves_array.push_back( {"time": start_timestamp + delay_between_columns, "action": action })
	else:
		#start with right
		action = func():
			spawn_intermediate_right_column_consecutive_two_enemies(minority_enemy_scene, majority_enemy_scene, num_enemies, delay_between_enemies)
		waves_array.push_back( {"time": start_timestamp, "action": action })
		action = func():
			spawn_intermediate_left_column_consecutive_two_enemies(minority_enemy_scene, majority_enemy_scene, num_enemies, delay_between_enemies)
		waves_array.push_back( {"time": start_timestamp + delay_between_columns, "action": action })

func spawn_two_interm_rows_consec_top_and_bottom_random(enemy_scene, start_timestamp, num_enemies, delay_between_enemies, delay_between_rows):
	if randi_range(0,1):
		#start with top
		action = func():
			spawn_intermediate_top_row_consecutive(enemy_scene, num_enemies, delay_between_enemies)
		waves_array.push_back( {"time": start_timestamp, "action": action })
		action = func():
			spawn_intermediate_bottom_row_consecutive(enemy_scene, num_enemies, delay_between_enemies)
		waves_array.push_back( {"time": start_timestamp + delay_between_rows, "action": action })
	else:
		#start with bottom
		action = func():
			spawn_intermediate_bottom_row_consecutive(enemy_scene, num_enemies, delay_between_enemies)
		waves_array.push_back( {"time": start_timestamp, "action": action })
		action = func():
			spawn_intermediate_top_row_consecutive(enemy_scene, num_enemies, delay_between_enemies)
		waves_array.push_back( {"time": start_timestamp + delay_between_rows, "action": action })

func spawn_single_enemy_intermediate_corner(enemy_scene, coordinate):
	var enemy = enemy_scene.instantiate()
	match coordinate:
		1:
			enemy.position = $IntermediateCornerMarker1.position
		2:
			enemy.position = $IntermediateCornerMarker2.position
		3:
			enemy.position = $IntermediateCornerMarker3.position
		4:
			enemy.position = $IntermediateCornerMarker4.position
	add_child_and_update_enemies_on_field(enemy)

func spawn_single_enemy_outside_corner(enemy_scene, coordinate):
	var enemy = enemy_scene.instantiate()
	match coordinate:
		1:
			enemy.position = $CornerMarker1.position
		2:
			enemy.position = $CornerMarker2.position
		3:
			enemy.position = $CornerMarker3.position
		4:
			enemy.position = $CornerMarker4.position
	add_child_and_update_enemies_on_field(enemy)

func spawn_single_enemy_inside_corner(enemy_scene, coordinate):
	var enemy = enemy_scene.instantiate()
	match coordinate:
		1:
			enemy.position = $CenterCornerMarker1.position
		2:
			enemy.position = $CenterCornerMarker2.position
		3:
			enemy.position = $CenterCornerMarker3.position
		4:
			enemy.position = $CenterCornerMarker4.position
	add_child_and_update_enemies_on_field(enemy)

func spawn_single_enemy_corner(enemy_scene, coordinate):
	var enemy = enemy_scene.instantiate()
	match coordinate:
		1:
			enemy.position = $CornerMarker1.position
		2:
			enemy.position = $CornerMarker2.position
		3:
			enemy.position = $CornerMarker3.position
		4:
			enemy.position = $CornerMarker4.position
	add_child_and_update_enemies_on_field(enemy)
	
func spawn_single_enemy_intermediate_center(enemy_scene, coordinate):
	var enemy = enemy_scene.instantiate()
	match coordinate:
		1:
			enemy.position = $IntermediateCenterMarker1.position
		2:
			enemy.position = $IntermediateCenterMarker2.position
		3:
			enemy.position = $IntermediateCenterMarker3.position
		4:
			enemy.position = $IntermediateCenterMarker4.position
	add_child_and_update_enemies_on_field(enemy)

func spawn_single_enemy_random(enemy_scene, offset_from_edge, offset_from_player):
	var pos = get_a_vector_not_near_player(offset_from_edge, offset_from_player)
	var enemy = enemy_scene.instantiate()
	enemy.position.x = pos.x
	enemy.position.y = pos.y
	add_child_and_update_enemies_on_field(enemy)
		
func spawn_row_of_enemies_top_simultaneous(enemy_scene, num_enemies):
	spawn_row_of_enemies_simultaneous(enemy_scene, num_enemies, $CornerMarker1, $CornerMarker2)
	
func spawn_row_of_enemies_bottom_simultaneous(enemy_scene, num_enemies):
	spawn_row_of_enemies_simultaneous(enemy_scene, num_enemies, $CornerMarker4, $CornerMarker3)

func spawn_row_of_enemies_simultaneous(enemy_scene, num_enemies, left_point:Marker2D, right_point:Marker2D):
	var num_enemies_between_endpoints = num_enemies - 2
	var x_gap = round( (right_point.position.x - left_point.position.x) / float(num_enemies - 1))
	#create and add endpoint enemies
	var enemy = enemy_scene.instantiate()
	enemy.position = left_point.position
	add_child_and_update_enemies_on_field(enemy)
	enemy = enemy_scene.instantiate()
	enemy.position = right_point.position
	add_child_and_update_enemies_on_field(enemy)
	#create and add in between enemies
	for i in num_enemies_between_endpoints:
		enemy = enemy_scene.instantiate()
		enemy.position.x = left_point.position.x + (i+1) * x_gap
		enemy.position.y = left_point.position.y
		add_child_and_update_enemies_on_field(enemy)
		
func spawn_column_of_enemies_left_simultaneous(enemy_scene, num_enemies):
	spawn_column_of_enemies_simultaneous(enemy_scene, num_enemies, $CornerMarker1, $CornerMarker4)
	
func spawn_column_of_enemies_right_simultaneous(enemy_scene, num_enemies):
	spawn_column_of_enemies_simultaneous(enemy_scene, num_enemies, $CornerMarker2, $CornerMarker3)

func spawn_column_of_enemies_simultaneous(enemy_scene, num_enemies, top_point:Marker2D, bottom_point:Marker2D):
	var num_enemies_between_endpoints = num_enemies - 2
	var y_gap = round( (bottom_point.position.y - top_point.position.y) / float(num_enemies - 1))
	#create and add endpoint enemies
	var enemy = enemy_scene.instantiate()
	enemy.position = top_point.position
	add_child_and_update_enemies_on_field(enemy)
	enemy = enemy_scene.instantiate()
	enemy.position = bottom_point.position
	add_child_and_update_enemies_on_field(enemy)
	#create and add in between enemies
	for i in num_enemies_between_endpoints:
		enemy = enemy_scene.instantiate()
		enemy.position.y = top_point.position.y + (i+1) * y_gap
		enemy.position.x = top_point.position.x
		add_child_and_update_enemies_on_field(enemy)

func spawn_row_of_enemies_consecutive(enemy_scene, num_enemies, delay, start_point:Marker2D, end_point:Marker2D):
	var x_gap = round( (end_point.position.x - start_point.position.x) / float(num_enemies - 1))
	var enemy
	for i in num_enemies:
		await get_tree().create_timer(delay, false).timeout
		enemy = enemy_scene.instantiate()
		enemy.position.x = start_point.position.x + (i) * x_gap
		enemy.position.y = start_point.position.y
		add_child_and_update_enemies_on_field(enemy)

func spawn_intermediate_top_row_consecutive(enemy_scene, num_enemies, delay):
	#top
	if randi_range(0,1):
		#start at left
		spawn_row_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCornerMarker1, $IntermediateCornerMarker2)
	else:
		#start at right
		spawn_row_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCornerMarker2, $IntermediateCornerMarker1)

func spawn_intermediate_bottom_row_consecutive(enemy_scene, num_enemies, delay):
	if randi_range(0,1):
		#start at left
		spawn_row_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCornerMarker4, $IntermediateCornerMarker3)
	else:
		#start at right
		spawn_row_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCornerMarker3, $IntermediateCornerMarker4)

func spawn_intermediate_top_or_bottom_row_consecutive_random(enemy_scene, num_enemies, delay):
	if randi_range(0,1):
		#top
		spawn_intermediate_top_row_consecutive(enemy_scene, num_enemies, delay)
	else:
		#bottom
		spawn_intermediate_bottom_row_consecutive(enemy_scene, num_enemies, delay)

func spawn_column_of_enemies_consecutive(enemy_scene, num_enemies, delay, start_point:Marker2D, end_point:Marker2D):
	var y_gap = round( (end_point.position.y - start_point.position.y) / float(num_enemies - 1))
	var enemy
	for i in num_enemies:
		await get_tree().create_timer(delay, false).timeout
		enemy = enemy_scene.instantiate()
		enemy.position.y = start_point.position.y + (i) * y_gap
		enemy.position.x = start_point.position.x
		add_child_and_update_enemies_on_field(enemy)
	
func spawn_column_of_enemies_consecutive_two_enemies(minority_enemy_scene, majority_enemy_scene, num_enemies, delay, start_point:Marker2D, end_point:Marker2D):
	var y_gap = round( (end_point.position.y - start_point.position.y) / float(num_enemies - 1))
	var enemy
	for i in num_enemies:
		await get_tree().create_timer(delay).timeout
		enemy = minority_enemy_scene.instantiate() if (i+1) % 2 else majority_enemy_scene.instantiate()
		enemy.position.y = start_point.position.y + (i) * y_gap
		enemy.position.x = start_point.position.x
		add_child_and_update_enemies_on_field(enemy)

func spawn_intermediate_left_column_consecutive(enemy_scene, num_enemies, delay):
	if randi_range(0,1):
		#start at top
		spawn_column_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCornerMarker1, $IntermediateCornerMarker4)
	else:
		#start at bottom
		spawn_column_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCornerMarker4, $IntermediateCornerMarker1)

func spawn_intermediate_left_column_consecutive_two_enemies(minority_enemy_scene, majority_enemy_scene, num_enemies, delay):
	if randi_range(0,1):
		#start at top
		spawn_column_of_enemies_consecutive_two_enemies(minority_enemy_scene, majority_enemy_scene, num_enemies, delay, $IntermediateCornerMarker1, $IntermediateCornerMarker4)
	else:
		#start at bottom
		spawn_column_of_enemies_consecutive_two_enemies(minority_enemy_scene, majority_enemy_scene, num_enemies, delay, $IntermediateCornerMarker4, $IntermediateCornerMarker1)

func spawn_intermediate_right_column_consecutive(enemy_scene, num_enemies, delay):
	if randi_range(0,1):
	#start at top
		spawn_column_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCornerMarker2, $IntermediateCornerMarker3)
	else:
	#start at bottom
		spawn_column_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCornerMarker3, $IntermediateCornerMarker2)

func spawn_intermediate_right_column_consecutive_two_enemies(minority_enemy_scene, majority_enemy_scene, num_enemies, delay):
	if randi_range(0,1):
	#start at top
		spawn_column_of_enemies_consecutive_two_enemies(minority_enemy_scene, majority_enemy_scene, num_enemies, delay, $IntermediateCornerMarker2, $IntermediateCornerMarker3)
	else:
	#start at bottom
		spawn_column_of_enemies_consecutive_two_enemies(minority_enemy_scene, majority_enemy_scene, num_enemies, delay, $IntermediateCornerMarker3, $IntermediateCornerMarker2)

func spawn_intermediate_left_or_right_column_consecutive_random(enemy_scene, num_enemies, delay):
	if randi_range(0,1):
		#left side
		spawn_intermediate_left_column_consecutive(enemy_scene, num_enemies, delay)
	else:
		#right side
		spawn_intermediate_right_column_consecutive(enemy_scene, num_enemies, delay)
			
func spawn_intermediate_left_right_or_center_column_consecutive_random(enemy_scene, num_enemies, delay):
	var column = randi_range(0,2)
	if column == 0:
		#left side
		if randi_range(0,1):
			#start at top
			spawn_column_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCornerMarker1, $IntermediateCornerMarker4)
		else:
			#start at bottom
			spawn_column_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCornerMarker4, $IntermediateCornerMarker1)
	elif column == 1:
		#center
		if randi_range(0,1):
			#start at top
			spawn_column_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCenterMarker1, $IntermediateCenterMarker3)
		else:
			#start at bottom
			spawn_column_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCenterMarker3, $IntermediateCenterMarker1)
	else:
		#right side
		if randi_range(0,1):
			#start at top
			spawn_column_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCornerMarker2, $IntermediateCornerMarker3)
		else:
			#start at bottom
			spawn_column_of_enemies_consecutive(enemy_scene, num_enemies, delay, $IntermediateCornerMarker3, $IntermediateCornerMarker2)
			
func intersection_horizontal_line_with_circe(p1:Vector2, p2:Vector2, circle_origin:Vector2, radius:float):
	#if top of circle is below line
	if circle_origin.y - radius > p1.y:
		return false
	#if bottom of circle is above line
	if circle_origin.y + radius < p1.y:
		return false
	#if right side of circle is left of first point
	if circle_origin.x + radius < p1.x:
		return false
	#if left side of circle is right of second point
	if circle_origin.x - radius > p2.x:
		return false
	return true

func circle_walls_intersect(c_pos:Vector2, radius):
	#checking to see which border walls a circle surrounding the ship intersects with--if any. Geometry2D.segment_intersects_circle() returns -1.0 for no intersection 
	var intersect_length_with_top_1 = Geometry2D.segment_intersects_circle($TopLeftSpawnLimitMarker2d.global_position, $TopRightSpawnLimitMarker2d.global_position, c_pos, radius)
	var intersect_length_with_right_1 = Geometry2D.segment_intersects_circle($TopRightSpawnLimitMarker2d.global_position, $BottomRightSpawnLimitMarker2d.global_position, c_pos, radius)
	var intersect_length_with_bottom_1 = Geometry2D.segment_intersects_circle($BottomLeftSpawnLimitMarker2d.global_position, $BottomRightSpawnLimitMarker2d.global_position, c_pos, radius)
	var intersect_length_with_left_1 = Geometry2D.segment_intersects_circle($TopLeftSpawnLimitMarker2d.global_position, $BottomLeftSpawnLimitMarker2d.global_position, c_pos, radius)

	#no intersections with border walls
	if intersect_length_with_top_1 == -1 and intersect_length_with_right_1 == -1 and intersect_length_with_bottom_1 == -1 and intersect_length_with_left_1 == -1:
		return null
		
	var intersect1
	var intersect2
	var intersect_key = 0
	#all this crap is for figuring out which two points are on a circle surrounding the ship that intersect with the border walls because Godot doesn't have a function 
	#for returning both points that intersect with a line segment, but only has a function to return the length along the line segment where it first intersects with 
	#the circle. I basically had to run that function twice in different directions on the same line(only intersecting with top/bottom wall) or once on each line for 
	#intersecting with top & left lines, top & right, etc. I also had to add an intersection key for applying different rules to the theta circle trig math stuff because
	#i couldn't really figure out why Godot sometimes chooses negative values for theta and sometimes chooses values that are over 2 PI...so I basically just have some trial
	#and error rules in spawn_ring_of_enemies_around_ship_simultaneous() to make it all act right. This code sucks. 
	#Explanation of intersect key values:
	#0: no intersections
	#1: intersect with top only
	#2: intersect with top and right
	#3: intersect with right only
	#4: intersect with bottom and right
	#5: intersect with bottom only
	#6: intersect with bottom and left
	#7: intersect with left only
	#8: intersect with top and left
	if intersect_length_with_top_1 > -1:
		intersect1 = Vector2($TopLeftSpawnLimitMarker2d.global_position.x + ($TopRightSpawnLimitMarker2d.global_position.x - $TopLeftSpawnLimitMarker2d.global_position.x) * intersect_length_with_top_1, $TopLeftSpawnLimitMarker2d.global_position.y)
		if intersect_length_with_left_1 > -1:
			intersect_key = 8
			intersect2 = Vector2($TopLeftSpawnLimitMarker2d.global_position.x, $TopLeftSpawnLimitMarker2d.global_position.y + ($BottomLeftSpawnLimitMarker2d.global_position.y - $TopLeftSpawnLimitMarker2d.global_position.y) * intersect_length_with_left_1)
		elif intersect_length_with_right_1 > -1:
			intersect_key = 2
			intersect2 = Vector2($TopRightSpawnLimitMarker2d.global_position.x, $TopRightSpawnLimitMarker2d.global_position.y + ($BottomRightSpawnLimitMarker2d.global_position.y - $TopRightSpawnLimitMarker2d.global_position.y) * intersect_length_with_right_1)
		else:
			var intersect_length_with_top_2 = Geometry2D.segment_intersects_circle($TopRightSpawnLimitMarker2d.global_position, $TopLeftSpawnLimitMarker2d.global_position, c_pos, radius)
			intersect_key = 1
			intersect2 = Vector2($TopRightSpawnLimitMarker2d.global_position.x + ($TopLeftSpawnLimitMarker2d.global_position.x - $TopRightSpawnLimitMarker2d.global_position.x) * intersect_length_with_top_2, $TopRightSpawnLimitMarker2d.global_position.y)
	elif intersect_length_with_bottom_1 > -1:
		intersect1 = Vector2($BottomLeftSpawnLimitMarker2d.global_position.x + ($BottomRightSpawnLimitMarker2d.global_position.x - $BottomLeftSpawnLimitMarker2d.global_position.x) * intersect_length_with_bottom_1, $BottomLeftSpawnLimitMarker2d.global_position.y)
		if intersect_length_with_left_1 > -1:
			intersect_key = 6
			intersect2 = Vector2($TopLeftSpawnLimitMarker2d.global_position.x, $TopLeftSpawnLimitMarker2d.global_position.y + ($BottomLeftSpawnLimitMarker2d.global_position.y - $TopLeftSpawnLimitMarker2d.global_position.y) * intersect_length_with_left_1)
		elif intersect_length_with_right_1 > -1:
			intersect_key = 4
			intersect2 = Vector2($TopRightSpawnLimitMarker2d.global_position.x, $TopRightSpawnLimitMarker2d.global_position.y + ($BottomRightSpawnLimitMarker2d.global_position.y - $TopRightSpawnLimitMarker2d.global_position.y) * intersect_length_with_right_1)
		else:
			var intersect_length_with_bottom_2 = Geometry2D.segment_intersects_circle($BottomRightSpawnLimitMarker2d.global_position, $BottomLeftSpawnLimitMarker2d.global_position, c_pos, radius)
			intersect_key = 5
			intersect2 = Vector2($BottomRightSpawnLimitMarker2d.global_position.x + ($BottomLeftSpawnLimitMarker2d.global_position.x - $BottomRightSpawnLimitMarker2d.global_position.x) * intersect_length_with_bottom_2, $BottomRightSpawnLimitMarker2d.global_position.y)
	elif intersect_length_with_left_1 > -1:
		intersect_key = 7
		intersect1 = Vector2($TopLeftSpawnLimitMarker2d.global_position.x, $TopLeftSpawnLimitMarker2d.global_position.y + ($BottomLeftSpawnLimitMarker2d.global_position.y - $TopLeftSpawnLimitMarker2d.global_position.y) * intersect_length_with_left_1)
		var intersect_length_with_left_2 = Geometry2D.segment_intersects_circle($BottomLeftSpawnLimitMarker2d.global_position, $TopLeftSpawnLimitMarker2d.global_position, c_pos, radius)
		intersect2 = Vector2($BottomLeftSpawnLimitMarker2d.global_position.x, $BottomLeftSpawnLimitMarker2d.global_position.y + ($TopLeftSpawnLimitMarker2d.global_position.y - $BottomLeftSpawnLimitMarker2d.global_position.y) * intersect_length_with_left_2)
	elif intersect_length_with_right_1 > -1:
		intersect_key = 3
		intersect1 = Vector2($TopRightSpawnLimitMarker2d.global_position.x, $TopRightSpawnLimitMarker2d.global_position.y + ($BottomRightSpawnLimitMarker2d.global_position.y - $TopRightSpawnLimitMarker2d.global_position.y) * intersect_length_with_right_1)
		var intersect_length_with_right_2 = Geometry2D.segment_intersects_circle($BottomRightSpawnLimitMarker2d.global_position, $TopRightSpawnLimitMarker2d.global_position, c_pos, radius)
		intersect2 = Vector2($BottomRightSpawnLimitMarker2d.global_position.x, $BottomRightSpawnLimitMarker2d.global_position.y + ($TopRightSpawnLimitMarker2d.global_position.y - $BottomRightSpawnLimitMarker2d.global_position.y) * intersect_length_with_right_2)
	return [intersect1, intersect2, intersect_key]

func spawn_ring_of_enemies_around_ship_simultaneous(enemy_scene, num_enemies, radius):
	var enemy
	var intersections = circle_walls_intersect(last_ship_pos, radius)
	if intersections == null:
		var angle_between_enemies = (2.0 * PI) / num_enemies
		var random_start_offset = randf_range(0.0, angle_between_enemies)
	#	x = cx + r * cos(a)
	#	y = cy + r * sin(a)
	#	...where r is the radius, cx,cy the origin, and a the angle.
		for i in num_enemies:
			enemy = enemy_scene.instantiate()
			enemy.global_position.x = last_ship_pos.x + radius * cos(random_start_offset + angle_between_enemies * (i))
			enemy.global_position.y = last_ship_pos.y + radius * sin(random_start_offset + angle_between_enemies * (i))
			add_child_and_update_enemies_on_field(enemy)
	else:
		#atan2(y - cy, x - cx)
		#to get angle to point on circle
		var start_theta = atan2(intersections[1].y - last_ship_pos.y, intersections[1].x - last_ship_pos.x)
		var end_theta = atan2(intersections[0].y - last_ship_pos.y, intersections[0].x - last_ship_pos.x)
		var angle_between_enemies
		const BUFFER_FROM_WALL = 0.05 
		if intersections[2] == 1 or intersections[2] == 2 or intersections[2] == 3:
			end_theta += 2.0*PI
			angle_between_enemies = ((end_theta - start_theta)*(1.0-2.0*BUFFER_FROM_WALL))/(num_enemies-1)
			start_theta += (end_theta - start_theta)*BUFFER_FROM_WALL
		elif intersections[2] == 4 or intersections[2] == 5:
			end_theta -= 2.0*PI
			angle_between_enemies = ((end_theta - start_theta)*(1.0-2.0*BUFFER_FROM_WALL))/(num_enemies-1)
			start_theta += (end_theta - start_theta)*BUFFER_FROM_WALL
		elif intersections[2] == 6 or intersections[2] == 7 or intersections[2] == 8:
			start_theta += 2.0*PI
			end_theta += 2.0*PI
			angle_between_enemies = ((end_theta - start_theta)*(1.0-2.0*BUFFER_FROM_WALL))/(num_enemies-1)
			start_theta += (end_theta - start_theta)*BUFFER_FROM_WALL

		for i in (num_enemies):
			enemy = enemy_scene.instantiate()
			enemy.global_position.x = last_ship_pos.x + radius * cos(start_theta + angle_between_enemies * i)
			enemy.global_position.y = last_ship_pos.y + radius * sin(start_theta + angle_between_enemies * i)
			add_child_and_update_enemies_on_field(enemy)

func spawn_minion():
	var enemy = minion.instantiate()
	enemy.make_non_boss_spawn()
	enemy.position = Vector2(0.0,-100.0)
	add_child_and_update_enemies_on_field(enemy)

			
func spawn_ring_of_enemies_around_point_simultaneous(enemy_scene, num_enemies, point:Vector2, radius):
	var enemy
	var intersections = circle_walls_intersect(point, radius)
	if intersections == null:
		var angle_between_enemies = (2.0 * PI) / num_enemies
		var random_start_offset = randf_range(0.0, angle_between_enemies)
	#	x = cx + r * cos(a)
	#	y = cy + r * sin(a)
	#	...where r is the radius, cx,cy the origin, and a the angle.
		for i in num_enemies:
			enemy = enemy_scene.instantiate()
			enemy.global_position.x = point.x + radius * cos(random_start_offset + angle_between_enemies * (i))
			enemy.global_position.y = point.y + radius * sin(random_start_offset + angle_between_enemies * (i))
			add_child_and_update_enemies_on_field(enemy)
	else:
		#atan2(y - cy, x - cx)
		#to get angle to point on circle
		var start_theta = atan2(intersections[1].y - point.y, intersections[1].x - point.x)
		var end_theta = atan2(intersections[0].y - point.y, intersections[0].x - point.x)
		var angle_between_enemies
		const BUFFER_FROM_WALL = 0.05 
		if intersections[2] == 1 or intersections[2] == 2 or intersections[2] == 3:
			end_theta += 2.0*PI
			angle_between_enemies = ((end_theta - start_theta)*(1.0-2.0*BUFFER_FROM_WALL))/(num_enemies-1)
			start_theta += (end_theta - start_theta)*BUFFER_FROM_WALL
		elif intersections[2] == 4 or intersections[2] == 5:
			end_theta -= 2.0*PI
			angle_between_enemies = ((end_theta - start_theta)*(1.0-2.0*BUFFER_FROM_WALL))/(num_enemies-1)
			start_theta += (end_theta - start_theta)*BUFFER_FROM_WALL
		elif intersections[2] == 6 or intersections[2] == 7 or intersections[2] == 8:
			start_theta += 2.0*PI
			end_theta += 2.0*PI
			angle_between_enemies = ((end_theta - start_theta)*(1.0-2.0*BUFFER_FROM_WALL))/(num_enemies-1)
			start_theta += (end_theta - start_theta)*BUFFER_FROM_WALL

		for i in (num_enemies):
			enemy = enemy_scene.instantiate()
			enemy.global_position.x = point.x + radius * cos(start_theta + angle_between_enemies * i)
			enemy.global_position.y = point.y + radius * sin(start_theta + angle_between_enemies * i)
			add_child_and_update_enemies_on_field(enemy)
	
func set_last_ship_pos(pos):
	last_ship_pos = pos
	
func fade_out_forcefield():
	var tween = create_tween()
	tween.tween_property($BossArena, "modulate:a", 0.0, 1.0).finished.connect(outro_prep)
	
func outro_prep():
	$BossArena/ArenaCollisionPolygon2D.disabled = true
	$TopWall/CollisionShape2D.disabled = true
	$TopWallLeftOutro/CollisionShape2D.disabled = false
	$TopWallRightOutro/CollisionShape2D.disabled = false

func get_last_ship_pos():
	return last_ship_pos
	
func show_all():
	visible = true
	for i in get_tree().get_nodes_in_group("pausehide"):
		i.visible = true
	
func hide_all_but_stars():
	visible = false
	for i in get_tree().get_nodes_in_group("pausehide"):
		i.visible = false
		
func get_player():
	return $PlayerShip

func get_player_position():
	return $PlayerShip.position

func _on_credits_trigger_area_body_entered(body):
	if body.is_in_group('player') && !credits_triggered:
		body.start_credits_shift_x()
		credits_triggered = true
		$Camera2D.credits()
		$CreditsBlastoffTimer.start()
		$EndingSong.play()
#		$EndingSong/EndingSongFadeOut.play("ending_song_fade")
#		print('credits triggered')

func _on_credits_blastoff_timer_timeout():
	$CreditsEndBoostTimer.start()
	$PlayerShip.boost()
	$PlayerShip.play_credits()
#	var boost_cam_tween = create_tween()
	$PlayerShip/GPUParticles2D.emitting = true
	$PlayerShip/GPUParticles2D2.emitting = true
	$PlayerShip/GPUParticles2D3.emitting = true
#	boost_cam_tween.tween_property($Camera2D, 'offset', Vector2(400, 40), 0.5).set_ease(Tween.EASE_OUT)
#	boost_cam_tween.tween_property($Camera2D, 'offset', Vector2(400, 0), 0.5).set_ease(Tween.EASE_IN)


#func old_waves():
#		var time_start = 0.0
#	#	#START COMMENT OUT TO SKIP TO LATER GAME#
#		#total 4
#		spawn_four_interm_corners(wanderer_scene, time_start, 0.75)
#		time_start += 7.5
#
#		#total 10
#		spawn_two_interm_columns_consec_left_and_right_random_two_enemies(wanderer_scene, blue_guy_scene, time_start, 3, 0.25, 4.0)
#		time_start += 9.5
#
#		#total 14
#		spawn_inside_corners_simul(blue_guy_scene, time_start)
#		time_start += 4.5
#
#		#total 24
#		spawn_two_interm_rows_consec_top_and_bottom_random(blue_guy_scene, time_start, 5, 0.125, 4.0)
#		time_start += 9.0
#
#		#total 25
#		spawn_single_enemy_center_look(rammer_scene, time_start)
#		time_start += 4.0
#
#		#total 31
#		spawn_multiple_enemies_random(blue_guy_scene, 6, time_start, 0.25, 50, DEFAULT_PLAYER_ENEMY_MIN_SPACE)
#		time_start += 7.0
#
#		#total 41
#		spawn_multiple_enemies_random(blue_guy_scene, 10, time_start, 0.2, 50, DEFAULT_PLAYER_ENEMY_MIN_SPACE)
#		time_start += 5.0
#
#		#total 43
#		spawn_interm_top_and_bottom_random(rammer_scene, time_start, 2.0)
#		time_start += 2.0
#
#		#total 49
#		spawn_multiple_enemies_random(blue_guy_scene, 6, time_start, 1.0, 50, DEFAULT_PLAYER_ENEMY_MIN_SPACE)
#		time_start += 9.0
#
#		#total 62
#		spawn_med_blob_of_small_enemies_random(blue_guy_scene, time_start, 200, 500) #13 enemies
#		time_start += 1.0
#
#		#total 68
#		spawn_multiple_enemies_random(blue_guy_scene, 6, time_start, 1.0, 50, DEFAULT_PLAYER_ENEMY_MIN_SPACE)
#		time_start += 7.0
#
#		#total 96
#		spawn_lg_blob_of_small_enemies_random(blue_guy_scene, time_start, 200, 500) #28 enemies
#		time_start += 7.0
#
#		#total 126
#		spawn_multiple_enemies_random(blue_guy_scene, 30, time_start, 0.3, 50, DEFAULT_PLAYER_ENEMY_MIN_SPACE)
#		time_start += 1.0
#
#		#total 129
#		spawn_multiple_enemies_random(rammer_scene, 3, time_start, 4.0, 50, DEFAULT_PLAYER_ENEMY_MIN_SPACE)
#		time_start += 16.0
#
#		#total 130
#		spawn_single_enemy_center_look(swarmer_scene, time_start)
#		time_start += 4.0
#
#		#total 134
#		spawn_four_interm_corners(swarmer_scene, time_start, 2.0)


func _on_wave_advance_timer_timeout():
	advance_wave()

func _on_boss_song_intro_finished():
#	$BossSongLoop.play()
	pass

func _on_intro_song_timer_timeout():
	$BossSongLoop.play()
	$BossSongTimer.start()

func _on_credits_end_boost_timer_timeout():
	$PlayerShip.boost()
	$PlayerShip.end_credits_shift_y()

func _on_boss_song_timer_timeout():
	$BossSongLoop.play()
	$BossSongTimer.start()
	
func play_theme():
	$ThemeSong.play()
	$ThemeSong/ThemeSongTimer.start()

func _on_theme_song_timer_timeout():
	play_theme()
