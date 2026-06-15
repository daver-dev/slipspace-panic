extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func play_shoot_sound_1():
	$GunSound1.play()

func play_spawn_sound_1():
	$SpawnSound1.play()

func play_spawn_sound_2():
	$SpawnSound2.play()

func play_spawn_sound_3():
	$SpawnSound3.play()

func play_spawn_sound_4():
	$SpawnSound4.play()

func play_explode_sound_1():
	$ExplosionSound1.play()

func play_explode_sound_2():
	$ExplosionSound2.play()

func play_explode_sound_3():
	$ExplosionSound3.play()

func play_explode_sound_4():
	$ExplosionSound4.play()

func play_explode_sound_5():
	$ExplosionSound5.play()
	$ExplosionSound2.play()
	
func play_ping_sound():
	$PingSound.play()

func play_damage_sound():
	$DamageSound.play()
	
func play_damage_sound2():
	$DamageSound2.play()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
