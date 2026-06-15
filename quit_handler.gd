## Autoload singleton that centralizes all quit logic.
##
## Register as an autoload in Project → Project Settings → Autoload
## with the name "QuitHandler".
##
## IMPORTANT: Set Auto Accept Quit to OFF in
## Project → Project Settings → Application → Config
##
## Usage:
##   - Anywhere you would call get_tree().quit(), instead call:
##       QuitHandler.quit(game_clock)
##
##   - Window close (X button / Alt+F4) is handled automatically
##     via _notification. You must provide a way for QuitHandler
##     to know the current game clock value — see game_clock_sec.

extends Node

const SUBMIT_URL: String = "https://jrose.me/ssp/api/submit.php"
const TIMEOUT_SEC: float = 3.0

## Set this from your game script every frame the player is
## actively playing, so QuitHandler always has access to the
## current elapsed time when a window-close event fires.
## Example (in your player/game script _process):
##   QuitHandler.game_clock_sec = game_clock
var game_clock_sec: float = 0.0

#var _http: HTTPRequest
#var _timeout_timer: Timer
var _is_quitting: bool = false
#
#
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
#	_http = HTTPRequest.new()
#	_http.request_completed.connect(_on_request_completed)
#	add_child(_http)
#
#	_timeout_timer = Timer.new()
#	_timeout_timer.one_shot = true
#	_timeout_timer.wait_time = TIMEOUT_SEC
#	_timeout_timer.timeout.connect(_on_timeout)
#	add_child(_timeout_timer)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit(game_clock_sec)


## Call this instead of get_tree().quit() everywhere in your
## game. [param elapsed_sec] is the current game clock value
## since the last death/reset.
func quit(elapsed_sec: float) -> void:
	if _is_quitting:
		return
	_is_quitting = true
	get_tree().quit()
#
	PlaySession.finalize(elapsed_sec)
#	var json_payload: String = PlaySession.to_json_string()
#
#	var headers: PackedStringArray = ["Content-Type: application/json"]
#	var err: int = _http.request(SUBMIT_URL, headers, HTTPClient.METHOD_POST, json_payload)
#
#	if err != OK:
#		push_warning("QuitHandler: HTTP request failed to send (error %d). Quitting anyway." % err)
#		get_tree().quit()
#		return
#
#	_timeout_timer.start()
#
#
#func _on_request_completed(_result: int, _code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
#	_timeout_timer.stop()
#	get_tree().quit()
#
#
#func _on_timeout() -> void:
#	push_warning("QuitHandler: Server did not respond within %.1f seconds. Quitting anyway." % TIMEOUT_SEC)
#	_http.cancel_request()
#	get_tree().quit()
