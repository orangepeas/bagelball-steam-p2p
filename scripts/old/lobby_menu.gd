extends Control

var isHosting : bool = false
var gameAlreadyStarted : bool 

signal muteTitleMusic
signal lobbyMenuBack
signal hideTitleImages
var map

@onready var client = $Client
#signal getCurrentGameScene

func _ready():
	$"Host Options".hide()
	$"Start Game".disabled = true
	$"game already started".hide()

func _process(_delta: float) -> void:
	if isHosting == false:
		if $"LobbyID Input".text.length() < 32:
			$"Join Lobby".disabled = true
		else:
			$"Join Lobby".disabled = false

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		_on_back_pressed()

func started_hosting():
	map = global.Map.warehouse
	isHosting = true ##not really need for both hiding and 
	$"Join Lobby".hide()
	$"LobbyID Input".hide()
	$"Host Lobby".hide()
	$"Stop Hosting".show()
	$"LobbyID Output Placeholder".hide()
	$"Host Options".show()
	$Gamemode/GamemodeOptions.disabled = true

func stopped_hosting():
	##havent implemented yet on client.gd
	map = null
	isHosting = false
	$"Stop Hosting".hide()
	$"Join Lobby".show()
	$"LobbyID Input".show()
	$"Host Lobby".show()
	$"LobbyID Output".text = ""
	$"LobbyID Input".text = ""
	$"LobbyID Output Placeholder".show()
	$"Host Options".hide()
	$Gamemode/GamemodeOptions.disabled = false
	
	global.currentLobby = ""

func joined_game():
	$"Join Lobby".hide()
	$"Host Lobby".hide()
	$"LobbyID Output".hide()
	$"Copy To Clipboard".hide()
	$"Join Lobby".disabled = true
	$"Leave Lobby".show()
	$"LobbyID Output Placeholder".hide()
	$"Start Game".hide() ##only host can start game
	$Gamemode.hide()

func no_joined_game():
	if isHosting == false:
		$"Leave Lobby".hide()
		$"Host Lobby".show()
		$"Join Lobby".disabled = false
		$"Join Lobby".show()
		$"Copy To Clipboard".show()
		$"LobbyID Output".show()
		$"LobbyID Output".text = ""
		$"LobbyID Input".text = ""
		$"LobbyID Output Placeholder".show()
		$"Start Game".show()
		$"game already started".hide()
		$Gamemode.show()
		
		##just resets it
		if gameAlreadyStarted == true:
			gameAlreadyStarted = false
		
		global.currentLobby = ""

func can_start_game():
	if gameAlreadyStarted == false:
		$"Start Game".disabled = false
		#$"Join Game (it's already started)".disabled = false

func no_can_start_game():
	$"Start Game".disabled = true
	#$"Join Game (it's already started)".disabled = true

func _on_back_pressed() -> void:
	lobbyMenuBack.emit()

func stop_main_menu_behaviour() -> void:
	muteTitleMusic.emit()
	hideTitleImages.emit()

func _on_client_game_already_started() -> void:
	$"Start Game".hide()
	gameAlreadyStarted = true
	$"game already started".show()

func _on_gamemode_options_item_selected(index: int) -> void:
	match index:
		0:  ##1v1
			global.oneVone.emit()
			$Client.maxPlayersTemp = 2 
		1:  ##2v2
			global.twoVtwo.emit()
			$Client.maxPlayersTemp = 4

func _on_maps_options_item_selected(index: int) -> void:
	match index:
		0:  ##warehouse
			map = global.Map.warehouse
		1:  ##church
			map = global.Map.church
	print(map)

@rpc("authority","call_local","reliable")
func broadcast_map(map):
	global.map = map
	prints("broadcast map called by ", multiplayer.get_unique_id(), "map: ", map,"global.map: ", global.map)

@rpc("any_peer", "call_local")
func start_game():
	self.set_multiplayer_authority(global.lobbyHostID)
	$"Start Game".disabled = true
	broadcast_map.rpc(map)
	await get_tree().create_timer(3).timeout ##could implement some communication between clients
	##to make sure theyve all received the map but instead we have a 3 second timer
	stop_main_menu_behaviour()
	self.get_parent().hide() ##hides main menu
	var scene = load("res://scenes/main level.tscn").instantiate()
	get_tree().root.add_child(scene)

#@rpc("any_peer","call_local")
#func broadcast_map_again_please():
	#print("broadcast map again")
	#broadcast_map.rpc(map)

#func _on_client_can_join_game_partway() -> void:
	#$"Start Game".hide()
	#$"Join Game (it's already started)".show()
#
#func _on_client_no_can_join_game_partway() -> void:
	#$"Start Game".show()
	#$"Join Game (it's already started)".hide()

#func _on_client_get_current_game_scene() -> void:
	#getCurrentGameScene.emit()
