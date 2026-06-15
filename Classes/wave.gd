extends Node
class_name Wave

var spawns:Array[Spawn]
var time_length_sec: int
var time_delay_start: float
var started:= false
var id: int
var setup: Callable
var data: Dictionary #optional parameter
var is_setup := false
var complete := false


func set_values(_spawns:Array[Spawn], _time:int, _delay:float, _id:int, _setup:Callable = func(): return {}, _data:Dictionary = {}):
	spawns = _spawns
	time_length_sec = _time
	time_delay_start = _delay
	id = _id
	setup = _setup
	data = _data
	
func call_setup():
	var return_data = setup.call()
#	print(return_data.keys())
	if return_data: #of setup doesnt return anything we assume the user passed in data through _data so we dont want to overwrite it
		data = return_data
