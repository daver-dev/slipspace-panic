extends Node

var _file: FileAccess

func _enter_tree() -> void:
	_file = FileAccess.open("user://ssp_log.txt", FileAccess.WRITE)

func log(message: String) -> void:
	var line := "[%s] %s" % [Time.get_datetime_string_from_system(), message]
	print(line)
	if _file:
		_file.store_line(line)
		_file.flush()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _file:
		_file.close()
