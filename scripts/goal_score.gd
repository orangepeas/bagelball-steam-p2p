class_name MainLevel

extends Node3D

var goldenGoal : bool = false
var closedGoals : bool = false
var ownGoal : bool
var timeAfterGoal : float = 1.08
var playerWhoScored
var singleplayer : bool
#var originalLinearVelocity : Vector3
var originalAngularVelocity : Vector3
var slowDownFactor : float
var yYoinkSpeed : int
var normOLV : Vector3
var goalFlip : bool = false
var playersWhoHaveLoaded : int
#var isFastFalling : bool
var kFactor = 20

func _ready() -> void:
	global.connect("gameStart", game_start)
	global.connect("goldenGoal", golden_goal_start)
	global.connect("endGoldenGoal", golden_goal_end)
	global.connect("practiceMode", practice_mode)
	global.connect("levelFinishedLoading", level_finished_loading)
	global.connect("closeGoals", close_goals)
	#global.connect("gameEnd",update_elo.bind(global.yourElo,global.theirElo,))
	#global.connect("disableOneWayBagelMap", fall_through_platform)
	#global.connect("enableOneWayBagelMap", stop_fall_through_platform)
	self.set_multiplayer_authority(global.lobbyHostID)
	slowDownFactor = 2 * GLV.mapScale.value
	yYoinkSpeed = 1000 * GLV.mapScale.value
	Engine.time_scale = GLV.engineTimescale.value
	#if global.map == global.Map.sisyphus:
		#global.goldenGoal.emit()

func level_finished_loading():
	print("level finished loading")
	player_loaded_map.rpc()

@rpc("any_peer","call_local")
func player_loaded_map():
	if multiplayer.get_unique_id() == global.lobbyHostID:
		playersWhoHaveLoaded += 1
		print("players who have loaded ", playersWhoHaveLoaded)
		if playersWhoHaveLoaded == global.players.size():
			game_start_rpc.rpc()

@rpc("any_peer","call_local")
func game_start_rpc():
	global.gameCountdown.emit()
	await get_tree().create_timer(3).timeout
	global.gameStart.emit()

func game_start():
	closedGoals = false
	global.redScore = 0
	global.blueScore = 0

func close_goals():
	closedGoals = true

func golden_goal_end():
	closedGoals = true
	goldenGoal = false

func golden_goal_start():
	closedGoals = false
	goldenGoal = true
	global.gameStart.emit()

func practice_mode():
	singleplayer = true

func _on_blue_goal_body_entered(body: Node3D) -> void:
	if body.is_in_group("ball") && closedGoals == false:
		if singleplayer != true:
			if multiplayer.get_unique_id() == global.lobbyHostID:
				red_scored.rpc()
				increase_players_score.rpc()
		else:
			red_scored()
			increase_players_score()
		var goalNoisePlayed = false
		if goalNoisePlayed == false:
			global.playRedScoreNoise.emit()
			global.playBlueConcedeNoise.emit()
			goalNoisePlayed = true

		closedGoals = true
		await get_tree().create_timer(timeAfterGoal).timeout ##length of goal score noise
		closedGoals = false
		global.redScored.emit() ##connects to score_display.gd
		if goldenGoal == true:
			global.gameEnd.emit()

func _on_red_goal_body_entered(body: Node3D) -> void:
	if body.is_in_group("ball") && closedGoals == false:
		if singleplayer != true:
			if multiplayer.get_unique_id() == global.lobbyHostID:
				blue_scored.rpc()
				increase_players_score.rpc()
		else:
			blue_scored()
			increase_players_score()
		var goalNoisePlayed = false

		if goalNoisePlayed == false:
			global.playBlueScoreNoise.emit()
			global.playRedConcedeNoise.emit()
			goalNoisePlayed = true
		
		closedGoals = true
		await get_tree().create_timer(timeAfterGoal).timeout ##length of goal score noise
		closedGoals = false
		global.blueScored.emit() ##connects to score_display.gd
		if goldenGoal == true:
			global.gameEnd.emit()
			
@rpc("authority","call_local")
func increase_players_score():
	var id : int = get_tree().get_first_node_in_group("ball").playerIDWhoLastHit
	if id != 0:
		if !global.singleplayer:
			if global.players.has(str(id)):
				global.players[str(id)].goals += 1
		else:
			global.players[global.players.keys()[0]].goals += 1

@rpc("authority","call_local")
func red_scored():
	global.redScore += 1
	prints("score is red: ", global.redScore,"blue: ",global.blueScore)

@rpc("authority","call_local")
func blue_scored():
	global.blueScore += 1
	prints("score is red: ", global.redScore,"blue: ",global.blueScore)

func _on_walljump_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if multiplayer.get_unique_id() == body.mpSync.get_multiplayer_authority() or singleplayer == true:
			body.noiseMaker.play_wall_touch_noise()
			global.playerTouchWall.emit()
			#print("touching wall")
	elif body.is_in_group("bagel") or body.is_in_group("ball"):
		body.toggle_continuous_cd.rpc()
		

func _on_walljump_detection_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		if multiplayer.get_unique_id() == body.mpSync.get_multiplayer_authority() or singleplayer == true:
			global.playerNoTouchWall.emit()
			#print("player not touching wall")
	elif body.is_in_group("bagel") or body.is_in_group("ball"):
		body.toggle_continuous_cd.rpc()

func _on_oneway_detector_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") && (multiplayer.get_unique_id() == body.mpSync.get_multiplayer_authority() or global.singleplayer == true):
		$"middle cylinder one way".collision_layer += 128
		$"middle cylinder one way".collision_mask += 128

func _on_oneway_detector_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") && (multiplayer.get_unique_id() == body.mpSync.get_multiplayer_authority() or global.singleplayer == true):
		$"middle cylinder one way".collision_mask -= 128
		$"middle cylinder one way".collision_layer -= 128

func _on_ball_normal_physics_body_entered(body: Node3D) -> void:
	if body.is_in_group("ball"):
		body.set_collision_mask_value(1, true)
		body.set_collision_layer_value(1, true)
		body.continuous_cd = false
		#if originalLinearVelocity.length() > 10:
			#body.linear_velocity = originalLinearVelocity
		#else:
			#body.linear_velocity = normOLV * 50
		body.linear_velocity/=slowDownFactor
		body.angular_velocity = originalAngularVelocity
		body.physics_material_override.bounce = GLV.ballBounciness.value
		body.physics_material_override.friction = 1
		body.lock_rotation = false



func _on_ball_normal_physics_body_exited(body: Node3D) -> void:
	if body.is_in_group("ball"):
		body.continuous_cd = true
		#originalLinearVelocity = body.linear_velocity
		originalAngularVelocity = body.angular_velocity
		#normOLV = originalLinearVelocity.normalized()
		body.lock_rotation = true
		body.rotation = Vector3(0,0,0)
		body.physics_material_override.bounce = 0.1
		body.physics_material_override.friction = 0
		#body.linear_velocity.x = 10000 * normOLV.x
		#body.linear_velocity.z = 10000 * normOLV.z
		body.linear_velocity.x = 0
		body.linear_velocity.z = 0
		body.linear_velocity.y = 1000
		body.find_child("torus thwoom").play()
		body.set_collision_mask_value(1, false)
		body.set_collision_layer_value(1, false)

func _on_goal_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("ball"):
		if goalFlip == false:
			if body.linear_velocity.x > 0:
				_on_red_goal_body_entered(body)
			elif body.linear_velocity.x < 0:
				_on_blue_goal_body_entered(body)
		elif goalFlip == true:
			if body.linear_velocity.x > 0:
				_on_blue_goal_body_entered(body)
			elif body.linear_velocity.x < 0:
				_on_red_goal_body_entered(body)

func goal_flip():
	goalFlip = true
	$"goal model".rotate_y(deg_to_rad(180))

func _on_kill_zone_body_entered(body: Node3D) -> void:
	##sumo map
	if closedGoals == false:
		if body.is_in_group("player"):
			if body.redTeam == true:
				if singleplayer != true:
					if multiplayer.get_unique_id() == global.lobbyHostID:
						blue_scored.rpc()
						increase_players_score.rpc()
				else:
					blue_scored()
					increase_players_score()
				var goalNoisePlayed = false
				if goalNoisePlayed == false:
					global.playBlueScoreNoise.emit()
					global.playRedConcedeNoise.emit()
					goalNoisePlayed = true
				closedGoals = true
				await get_tree().create_timer(timeAfterGoal).timeout ##length of goal score noise
				closedGoals = false
				global.blueScored.emit() ##connects to score_display.gd
				
			elif body.redTeam == false:
				if singleplayer != true:
					if multiplayer.get_unique_id() == global.lobbyHostID:
						red_scored.rpc()
						increase_players_score.rpc()
				else:
					red_scored()
					increase_players_score()
				var goalNoisePlayed = false
				if goalNoisePlayed == false:
					global.playRedScoreNoise.emit()
					global.playBlueConcedeNoise.emit()
					goalNoisePlayed = true
				closedGoals = true
				await get_tree().create_timer(timeAfterGoal).timeout ##length of goal score noise
				closedGoals = false
				global.redScored.emit() ##connects to score_display.gd



func _on_safe_zone_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_on_kill_zone_body_entered(body)
		

func update_elo(yourElo:int, theirElo:int, redWin:bool):
	# Calculate the Winning Probability of Player B
	var outcome
	if redWin == true:
		if global.players[multiplayer.get_unique_id()].redTeam == true:
			outcome = 1
		else:
			outcome = 0
	elif redWin == false:
		if global.players[multiplayer.get_unique_id()].redTeam == false:
			outcome = 1
		else:
			outcome = 0
	var Pb = calculate_probability(yourElo, theirElo)

	# Calculate the Winning Probability of Player A
	var Pa = calculate_probability(theirElo, yourElo)

	# Update the Elo Ratings
	yourElo = yourElo + kFactor * (outcome - Pa)
	theirElo = theirElo + kFactor * ((1 - outcome) - Pb)

	# Print updated ratings
	print("Updated Ratings:-")
	prints("your elo is now: ",yourElo, "their elo is now: ",theirElo)

func calculate_probability(rating1, rating2):
	1/(1 + (10** ((rating1 - rating2) / 400.0)))
