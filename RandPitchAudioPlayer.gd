extends AudioStreamPlayer
class_name RandPitchAudio

var pitch_rand = 0.5
var base_pitch
var pitch_min
var pitch_max


# Called when the node enters the scene tree for the first time.
func _ready():
	base_pitch = pitch_scale
	pitch_min = pitch_scale * (1-pitch_rand)
	pitch_max = pitch_scale * (1+pitch_rand)
	
func set_pitch_rand(new_rand:float):
	pitch_rand = new_rand
	pitch_min = pitch_scale * (1-pitch_rand)
	pitch_max = pitch_scale * (1+pitch_rand)
	
func play_sound():
	pitch_scale = randf_range(pitch_min, pitch_max)
	play()
	pitch_scale = base_pitch
