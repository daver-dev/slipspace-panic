extends CanvasLayer
class_name Hud
const SAVE_PATH := "user://score.save"
var you_died_color
var started = false
var pb:float = 0.0
var boss_defeated := false
var boss_defeated_previously := false
@onready var level = get_tree().get_first_node_in_group("level")
@export var debug:bool


func _ready():
	G.HUD = self
	if debug:
		$DebugLabel.visible = true
		$DebugTitle.visible = true
	hide_you_died()
	load_high_score()
#	var pb_game_clock = str(round_place(pb, 1)) + '.0' if !str(round_place(pb, 1)).contains('.') else str(round_place(pb, 1))
#	$BestTime.text = "PB: " + str(pb_game_clock)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if started && !boss_defeated:
#		var ship = get_tree().get_first_node_in_group("player")
		var game_clock = str(round_place(level.clock, 1)) + '.0' if !str(round_place(level.clock, 1)).contains('.') else str(round_place(level.clock, 1))
		$Time.text = game_clock

func hud_print(message:String):
	if debug:
		$DebugLabel.text = message + "\n" + $DebugLabel.text

func boss_defeated_stuff():
	if !boss_defeated_previously:
		update_pb_first_boss_defeat()
		reveal_pb_star()
	else:
		update_pb_boss_defeat()
	boss_defeated = true

func reveal_pb_star():
	$BestTime/Star.show()

func show_you_died():
	$Message.show()
	$DeathMessage.show()
	$DeathMessage/Tip/AnimationPlayer.play("fade_in")
	
func show_boost_shield1():
	$BoostGauge/Gem1.visible = true
	
func hide_boost_shield1():
	$BoostGauge/Gem1.visible = false
	
func show_boost_shield2():
	$BoostGauge/Gem2.visible = true
	
func hide_boost_shield2():
	$BoostGauge/Gem2.visible = false

func show_boost_shield3():
	$BoostGauge/Gem3.visible = true
	
func hide_boost_shield3():
	$BoostGauge/Gem3.visible = false

func hide_you_died():
	$Message.hide()
	$DeathMessage.hide()
	$DeathMessage/Tip.modulate.a = 0
	
func round_place(num,places):
	return (round(num*pow(10,places))/pow(10,places))

func update_pb_first_boss_defeat():
	pb = level.clock
	var pb_game_clock = str(round_place(pb, 1)) + '.0' if !str(round_place(pb, 1)).contains('.') else str(round_place(pb, 1))
	$BestTime.text = "PB: " + str(pb_game_clock)
	boss_defeated_previously = true
	save_score()

func update_pb_boss_defeat():
	if  level.clock < pb:
#		print("need high score sound and visuals again?")
		pb = level.clock
		var pb_game_clock = str(round_place(pb, 1)) + '.0' if !str(round_place(pb, 1)).contains('.') else str(round_place(pb, 1))
		$BestTime.text = "PB: " + str(pb_game_clock)
		save_score()
		
func update_pb(alive_time:float):
	if  alive_time > pb && !boss_defeated_previously:
#		print("need high score sound and visuals")
		pb = alive_time
		var pb_game_clock = str(round_place(pb, 1)) + '.0' if !str(round_place(pb, 1)).contains('.') else str(round_place(pb, 1))
		$BestTime.text = "PB: " + str(pb_game_clock)
		save_score()

func save_score():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_float(pb)
	file.store_64(boss_defeated_previously)
	#TODO: update DB?
	
func load_high_score():
	if not FileAccess.file_exists(SAVE_PATH):
		return # Error! We don't have a save to load.
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var prior_pb = save_file.get_float()
	pb = prior_pb
	boss_defeated_previously = save_file.get_64()
	if boss_defeated_previously:
		reveal_pb_star()
	var pb_game_clock = str(round_place(pb, 1)) + '.0' if !str(round_place(pb, 1)).contains('.') else str(round_place(pb, 1))
	$BestTime.text = "PB: " + str(pb_game_clock)

func play_credits():
	var credits_tween = create_tween()
	$Credits/CreditsTimer.start()
	for i in [1,2,3,4]:
		var credits_node = get_node("Credits/Credits%d" % i)
		credits_tween.tween_property(credits_node, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		credits_tween.tween_property(credits_node, "modulate:a", 1.0, 2)
		credits_tween.tween_property(credits_node, "modulate:a", 0.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		

func _on_timer_timeout():
	started = true

func _on_credits_timer_timeout():
	get_parent().get_parent().find_child("EndingSongFadeOut").play("ending_song_fade")
	$Credits/EndingFader.play("fade_out")

func _on_ending_fader_animation_finished(_animation_name: String):
	get_tree().change_scene_to_file("res://game.tscn")
