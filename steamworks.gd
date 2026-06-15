extends Node
var is_running = false

func _ready():
	var init := Steam.steamInit()
	Log.log("Steam init result: %s" % init)
	if not init:
		Log.log("Steam failed to initialize")
		return
	Log.log("Logged in: %s" % Steam.loggedOn())
	Log.log("App ID: %s" % Steam.getAppID())

func _process(_delta: float) -> void:
	Steam.run_callbacks()
	is_running = Steam.isSteamRunning()

func set_achievement(this_achievement: String) -> void:
	if Steam.isSteamRunning():
		if not Steam.setAchievement(this_achievement):
			Log.log("Failed to set achievement: %s" % this_achievement)
			return
		Log.log("Set acheivement: %s" % this_achievement)
		Steam.storeStats()
	else:
		Log.log("skipped setting achievement, Steam wasn't running")
		
func _on_user_stats_received(game_id: int, result: int, user_id: int):
	if result == 1: # 1 means success
		Log.log("Stats and Achievements are ready!")
	else:
		Log.log("Failed to receive stats. Error: %s" % result)
