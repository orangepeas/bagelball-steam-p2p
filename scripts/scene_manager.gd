extends Node3D

@onready var playerScene : PackedScene = load("res://scenes/player.tscn")
@onready var spectatorScene : PackedScene = load("res://scenes/spectator_player.tscn")
@onready var QBScene : PackedScene = load("res://scenes/quantum bagel.tscn")
@onready var bagelScene : PackedScene = load("res://scenes/bagel.tscn")
var spawnPointGroup
var QBspawnPointGroup
var scene
@onready var defaultMapScale := Vector3(1,1,1)
@onready var ogBagelSize : float = GLV.bagelSizeScale.value


#func _ready() -> void:


func start_game():
	print("start game pressed")
	print(global.players)
	global.redScore = 0
	global.blueScore = 0
	match global.maxPlayers:
		2:
			spawnPointGroup = "playerSpawnPoint1v1"
			QBspawnPointGroup = "QBspawnpoint1v1"
		4:
			spawnPointGroup = "playerSpawnPoint2v2"
			QBspawnPointGroup = "QBspawnpoint2v2"
		32:
			spawnPointGroup = "playerSpawnPoint2v2"
			QBspawnPointGroup = "QBspawnpoint2v2"
	match global.map:
		global.Map.warehouse:
			scene = load("res://scenes/main level model/main level model.tscn").instantiate()
		global.Map.cylinder:
			scene = load("res://scenes/cylinder level model/cylinder level model.tscn").instantiate()
		global.Map.bagel:
			scene = load("res://scenes/bagel level model/bagel_level_model.tscn").instantiate()
			match global.maxPlayers:
				2:
					defaultMapScale = Vector3(2.5,2.5,2.5)
				4:
					defaultMapScale = Vector3(4,4,4)
		global.Map.dome:
			scene = load("res://scenes/dome level model/dome_level_model.tscn").instantiate()
		global.Map.vents:
			scene = load("res://scenes/racecourse vent/racecourse vent model.tscn").instantiate()
		global.Map.dome_goalflip:
			scene = load("res://scenes/dome level model/dome_level_model.tscn").instantiate()
			scene.goal_flip()
			match global.maxPlayers:
				2:
					defaultMapScale = Vector3(1,1,1)
				4:
					defaultMapScale = Vector3(1.5,1.5,1.5)
			
		global.Map.church:
			scene = load("res://scenes/church level model/church level model.tscn").instantiate()
		global.Map.sumo:
			defaultMapScale = Vector3(1.4,1.4,1.4)
			scene = load("res://scenes/sumo level model/sumo level model.tscn").instantiate()
		global.Map.sumo2:
			defaultMapScale = Vector3(1.4,1.4,1.4)
			scene = load("res://scenes/sumo level model/sumo_level_model_2.tscn").instantiate()
		global.Map.sisyphus:
			scene = load("res://scenes/sisyphus level model/sisyphus_level_model_2.tscn").instantiate()

	
	if global.maxPlayers == 32:
		defaultMapScale = Vector3(1,1,1)
		
	print("map scale value", GLV.mapScale.value)
	scene.scale = defaultMapScale * GLV.mapScale.value
	self.add_child(scene)
	#global.joinGamePartwayThrough.connect(join_partway)
	var index : int = 1
	var redPlayerCount := 0 
	var bluePlayerCount := 0
	for i in global.players:
		if global.players[i].spectator == false:
			if global.players[i].redTeam == true:
				redPlayerCount += 1
			elif global.players[i].redTeam == false:
				bluePlayerCount += 1
	var blueSpawnPointArray
	var redSpawnPointArray
	#var greenSpawnPointArray
	for spawnBox in get_tree().get_nodes_in_group("spawnbox"):
		if spawnBox.team == spawnBox.Team.red:
			redSpawnPointArray = spawnBox.get_spawn_point_array(redPlayerCount)
		elif spawnBox.team == spawnBox.Team.blue:
			blueSpawnPointArray = spawnBox.get_spawn_point_array(bluePlayerCount)
	bluePlayerCount = 0
	redPlayerCount = 0
	for i in global.players:
		if global.players[i].spectator == false: ##if within the player limit, spawn as players
			var currentPlayer : Player = playerScene.instantiate()
			var material = StandardMaterial3D.new()
			var materialPartsRed = StandardMaterial3D.new()
			var materialPartsBlue = StandardMaterial3D.new()
			currentPlayer.name = str(int(global.players[i].id)) ##name is an inherent property of godot's nodes
			currentPlayer.displayName = global.players[i].displayName
			add_child(currentPlayer)
			if global.players[i].redTeam == true:
				redPlayerCount += 1
				material.albedo_color = Color(255,0,0,255)
				materialPartsRed.albedo_color = Color(2,1,0,255)
				for meshPart in currentPlayer.mesh.get_children():
					meshPart.material_override = materialPartsRed
				currentPlayer.redTeam = true
				currentPlayer.global_position = redSpawnPointArray[redPlayerCount - 1]
				currentPlayer.spawnPosition = redSpawnPointArray[redPlayerCount - 1]
				if GLV.quantumBagels == true:
					if global.map == global.Map.sumo or global.map == global.Map.sumo2:
						GLV.bagelSizeScale.value = ogBagelSize * 3
					spawn_quantum_bagel(currentPlayer.spawnPosition, index)
				if (global.map == global.Map.sumo or global.map == global.Map.sumo2) && GLV.quantumBagels != true:
					GLV.bagelSizeScale.value = ogBagelSize * 3
					spawn_bagel(currentPlayer.spawnPosition, index)
						#currentPlayer.spawnPosition = spawn.global_position
				#for spawn in get_tree().get_nodes_in_group(spawnPointGroup):
					#print(str(int(global.players[i].index)))
					#print(spawn.name)
					#if spawn.redSpawn == true && str(int(global.players[i].index)) == spawn.name:
						#currentPlayer.global_position = spawn.global_position
						#currentPlayer.spawnPosition = spawn.global_position
			elif global.players[i].redTeam == false:
				bluePlayerCount += 1
				material.albedo_color = Color(0,150,255,255)
				materialPartsBlue.albedo_color = Color(0,0,2,255)
				for meshPart in currentPlayer.mesh.get_children():
					meshPart.material_override = materialPartsBlue
				currentPlayer.redTeam = false
				currentPlayer.global_position = blueSpawnPointArray[bluePlayerCount - 1]
				currentPlayer.spawnPosition = blueSpawnPointArray[bluePlayerCount - 1]
				if GLV.quantumBagels == true:
					if global.map == global.Map.sumo or global.map == global.Map.sumo2:
						GLV.bagelSizeScale.value = ogBagelSize * 3
					spawn_quantum_bagel(currentPlayer.spawnPosition, index)
				if (global.map == global.Map.sumo or global.map == global.Map.sumo2) && GLV.quantumBagels != true:
					GLV.bagelSizeScale.value = ogBagelSize * 3
					spawn_bagel(currentPlayer.spawnPosition, index)
				#for spawn in get_tree().get_nodes_in_group(spawnPointGroup):
					#if (spawn.redSpawn == false && str(int(global.players[i].index)) == spawn.name) or global.singleplayer == true: ##blue spawn
						#currentPlayer.global_position = spawn.global_position
						#currentPlayer.spawnPosition = spawn.global_position
			currentPlayer.mesh.material_override = material
			#print("mesh text: ", currentPlayer.displayName, " currentPlayer.name: ", currentPlayer.name)

			index += 1

		else: ##if outside the player limit, spawn as spectators
			var spectator : SpectatorPlayer = spectatorScene.instantiate()
			spectator.name = str(int(global.players[i].id))
			add_child(spectator)
			if global.map != global.Map.sumo:
				spectator.global_position = scene.find_child("BallRespawnPoint").global_position
				spectator.global_position.y = scene.find_child("BallRespawnPoint").global_position.y + 25
			else:
				spectator.global_position = Vector3(0,150,0)
	
	#if GLV.quantumBagels == true:
		#for QBspawn in get_tree().get_nodes_in_group(QBspawnPointGroup):
			#var QB = QBScene.instantiate()
			#QBspawn.add_child(QB)
			#QB.global_position = QBspawn.global_position

	global.levelFinishedLoading.emit()
	

func spawn_quantum_bagel(spawnPos : Vector3, index : int):
	var QB = QBScene.instantiate()
	QB.name = "QB" + str(index)
	add_child(QB)
	QB.global_position.x = spawnPos.x - 0.3 * spawnPos.x
	QB.global_position.z = spawnPos.z - 0.3 * spawnPos.z
	QB.global_position.y = spawnPos.y
	QB.respawnPoint.x = spawnPos.x - 0.3 * spawnPos.x
	QB.respawnPoint.z = spawnPos.z - 0.3 * spawnPos.z
	QB.respawnPoint.y = spawnPos.y

func spawn_bagel(spawnPos : Vector3, index : int):
	##sumo map only
	var bagel = bagelScene.instantiate()
	bagel.name = "bagel" + str(index)
	add_child(bagel)
	bagel.global_position.x = spawnPos.x - 0.3 * spawnPos.x
	bagel.global_position.z = spawnPos.z - 0.3 * spawnPos.z
	bagel.global_position.y = spawnPos.y
	bagel.respawnPoint.x = spawnPos.x - 0.3 * spawnPos.x
	bagel.respawnPoint.z = spawnPos.z - 0.3 * spawnPos.z
	bagel.respawnPoint.y = spawnPos.y

@rpc("any_peer","call_local")
func join_game_as_spec():
	prints("global.map = ", global.map)
	var spectator : SpectatorPlayer = spectatorScene.instantiate()
	spectator.name = str(multiplayer.get_unique_id())
	add_child(spectator)
	spectator.global_position = global.ballRespawnPoint
	spectator.global_position.y = global.ballRespawnPoint.y + 25
	match global.map:
		global.Map.warehouse:
			scene = load("res://scenes/main level model/main level model.tscn").instantiate()
			self.add_child(scene)
		
		global.Map.church:
			scene = load("res://scenes/church level model/church level model.tscn").instantiate()
			self.add_child(scene)
	prints("added map", global.map, multiplayer.get_unique_id())

#func join_partway():
	#add_player.rpc()
#
#@rpc("any_peer","call_local")
#func add_player():
	#for player in global.players:
		#for spawnedPlayer in get_tree().get_nodes_in_group("player"):
			#if player != spawnedPlayer:
				#var currentPlayer : Player = playerScene.instantiate()
				#var material = StandardMaterial3D.new()
				#currentPlayer.name = str(global.players[player].id) ##name is an inherent property of godot's nodes
				#currentPlayer.displayName = global.players[player].displayName 
				#add_child(currentPlayer)
				#if int(global.players[player].index) % 2 == 1: ##global.players[i].index goes up by 1 with each dictionary entry
					###if we are on red team
					#material.albedo_color = Color(255,0,0,255)
					#currentPlayer.redTeam = true
					#for spawn in get_tree().get_nodes_in_group("playerSpawnPoint"):
						#if spawn.redSpawn == true:
							#currentPlayer.global_position = spawn.global_position
							#currentPlayer.spawnPosition = spawn.global_position
				#elif int(global.players[player].index) % 2 == 0:
					###if we are on blue team
					#material.albedo_color = Color(0,150,255,255)
					#currentPlayer.redTeam = false
					#for spawn in get_tree().get_nodes_in_group("playerSpawnPoint"):
						#if spawn.redSpawn == false: ##blue spawn
							#currentPlayer.global_position = spawn.global_position
							#currentPlayer.spawnPosition = spawn.global_position
				#currentPlayer.mesh.material_override = material
