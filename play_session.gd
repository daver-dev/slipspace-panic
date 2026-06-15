## Autoload singleton that accumulates play session data and
## exports it as a JSON string for the analytics endpoint.
##
## Register as an autoload in Project → Project Settings → Autoload
## with the name "PlaySession".
##
## Usage:
##   - Each frame the player is actively playing (not paused/menu),
##     add delta to your own clock. When the player dies, call:
##       PlaySession.record_death(killed_by_id, wave_id, elapsed_sec)
##
##   - When the player beats a miniboss or boss:
##       PlaySession.set_beat_miniboss()
##       PlaySession.set_beat_boss()
##
##   - When the player quits the game, call:
##       PlaySession.finalize(elapsed_sec)
##     then hand the result of to_json_string() to your HTTP script.

extends Node

const API_KEY: String = ""

# ── Session state ─────────────────────────────────────────────

var machine_id: String
var playtime_sec: float = 0.0
var highest_wave_id_defeated: int = 0
var has_beat_miniboss: bool = false
var has_beat_boss: bool = false
var beat_boss_at: String = ""  # ISO 8601 or empty

var _deaths: Array = []


func _ready() -> void:
	machine_id = OS.get_unique_id().sha256_text()

# ── Public API ────────────────────────────────────────────────

## Call each time the player dies.
## [param killed_by_id] maps to the death_reasons lookup table.
## [param wave_id] the wave the player died in.
## [param elapsed_sec] seconds on the game clock since the last
##     reset (death or session start). This is added to the
##     running playtime total.
func record_death(killed_by_id: int, wave_id: int, elapsed_sec: float) -> void:
	playtime_sec += elapsed_sec
	if wave_id > highest_wave_id_defeated:
		highest_wave_id_defeated = wave_id

	_deaths.append({
		"killed_by": killed_by_id,
		"killed_in_wave_id": wave_id,
		"created_at": _now_iso(),
		"player_quit_after": false,
	})


## Call when the player defeats the miniboss.
func set_beat_miniboss() -> void:
	print("CALLING STEAM API FOR MINIBOSS ACHIEVEMENT")
	Steamworks.set_achievement("BEAT_MINIBOSS")
	has_beat_miniboss = true


## Call when the player defeats the boss.
func set_beat_boss() -> void:
	print("CALLING STEAM API FOR BOSS ACHIEVEMENT")
	Steamworks.set_achievement("BEAT_BOSS")
	has_beat_boss = true
	if beat_boss_at.is_empty():
		beat_boss_at = _now_iso()
	

## Call once when the player exits / quits the game.
## [param elapsed_sec] seconds on the game clock since the last
##     reset. Added to the running playtime total.
## If there were any deaths, the last one is flagged as the quit
## point. If there were no deaths, the player quit without dying.
func finalize(elapsed_sec: float) -> void:
	# print("playtime before: ", playtime_sec)
	playtime_sec += elapsed_sec
	# print("playtime after: ", playtime_sec)

	if _deaths.size() > 0:
		_deaths[_deaths.size() - 1]["player_quit_after"] = true


## Returns the full session payload as a JSON string, ready to
## POST to the analytics endpoint.
func to_json_string() -> String:
	var payload: Dictionary = {
		"pw": API_KEY,
		"machine_id": machine_id,
		"playtime_sec": snapped(playtime_sec, 0.01),
		"highest_wave_id_defeated": highest_wave_id_defeated,
		"has_beat_miniboss": has_beat_miniboss,
		"has_beat_boss": has_beat_boss,
		"beat_boss_at": beat_boss_at if beat_boss_at != "" else null,
		"deaths": _deaths,
	}
	return JSON.stringify(payload)


## Resets all session data. Call if you need to start a fresh
## session without restarting the application.
func reset() -> void:
	playtime_sec = 0.0
	highest_wave_id_defeated = 0
	has_beat_miniboss = false
	has_beat_boss = false
	beat_boss_at = ""
	_deaths.clear()


# ── Internals ─────────────────────────────────────────────────

## Returns the current system time as an ISO 8601 string that
## the PHP endpoint expects: "2025-06-15T14:23:01"
func _now_iso() -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [
		dt["year"], dt["month"], dt["day"],
		dt["hour"], dt["minute"], dt["second"],
	]

