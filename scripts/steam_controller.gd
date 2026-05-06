extends Control

@export var leaderboardUserScore : PackedScene

func _ready():
	Steam.steamInit(3620440) ##MUST HAVE APP ID OR IT DOESNT FUCKING WORK
	var steamRunning = Steam.isSteamRunning()
	print (steamRunning)
	if !steamRunning:
		print("steam isnt running you bastard")
		return
	
	var userId = Steam.getSteamID()
	var name = Steam.getFriendPersonaName(userId)
	print("your steam name is ", name, " your id is ", userId)
	$TestingThings/FriendCard/HBoxContainer/Name.text = name
	Steam.avatar_loaded.connect(avatar_loaded)
	Steam.getPlayerAvatar()
	Steam.leaderboard_find_result.connect(leaderboard_find_result)
	Steam.leaderboard_score_uploaded.connect(leaderboard_score_uploaded)
	Steam.leaderboard_scores_downloaded.connect(leaderboard_scores_downloaded)

func _process(delta: float) -> void:
	Steam.run_callbacks() ##apparently steam stores callbacks and you need to get them
	##for signals to work

func avatar_loaded(id, size, buffer):
	##takes the buffer (whatever that is) we take from steam and converts it into an image
	var avatarImage = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, buffer)
	var texture = ImageTexture.create_from_image(avatarImage)
	$TestingThings/FriendCard/HBoxContainer/Avatar.texture = texture

func _on_achievement_get_pressed() -> void:
	##when you breakpoint it returns an achievement, ret bool is if it exists or not
	var achievement = Steam.getAchievement("testachievement")
	print(achievement)
	if achievement.ret && !achievement.achieved:
		##THIS FUCKING WORKS HAHAHAHAHA
		print("achievement got")
		Steam.setAchievement("testachievement")
		Steam.storeStats() ##need to call this to fire the stat

func _on_get_test_stat_pressed() -> void:
	$"TestingThings/Get Test Stat/Test stat is".text = "test stat = " + str(Steam.getStatInt("teststat"))

func _on_set_test_stat_pressed() -> void:
	Steam.setStatInt("teststat", int($"TestingThings/Set Test Stat/SetTestStatInput".text))
	Steam.storeStats()

func _on_get_goals_scored_pressed() -> void:
	$"TestingThings/Get Goals Scored/Goals Scored is".text = "goals scored = " + str(Steam.getStatInt("goalsScored"))

func _on_set_goals_scored_pressed() -> void:
	print(Steam.setStatInt("goalsScored", int($"TestingThings/Set Goals Scored/SetGoalsScoredInput".text)))
	Steam.storeStats()

func _on_get_leaderboard_pressed() -> void:
	Steam.findLeaderboard("Leaderboard")

func leaderboard_find_result(handle, found):
	print("leaderboaard handle: ", handle, " has it been found: ", found)

func leaderboard_score_uploaded(success, handle, score):
	prints("success is:",success, "handle is:",handle,"score is:", score)

func _on_submit_leaderboard_score_pressed() -> void:
	Steam.uploadLeaderboardScore(int($"TestingThings/Submit Leaderboard Score/SubmitScore".text))

func _on_get_leaderboard_score_pressed() -> void:
	$TestingThings.hide()
	$Panel.show()
	Steam.downloadLeaderboardEntries(0,10)

func leaderboard_scores_downloaded(message, handle, result):
	print(message, handle, result)
	
	for i in result:
		var score = leaderboardUserScore.instantiate()
		score.setup_leaderboard_score(i.global_rank, Steam.getFriendPersonaName(i.steam_id), i.score)
		$Panel/VBoxContainer.add_child(score)
