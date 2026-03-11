extends Control

var isHosting : bool = false
var gameAlreadyStarted : bool 
var isSpectator : bool = false
var myId : int = 0


signal stopHostingPressed
signal leaveLobbyPressed
signal lobbyMenuBack
signal canStartGame

signal disableCLVButtons
signal enableCLVButtons
var map

@onready var client = $"../Client" 
@onready var hostOptions = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/Host Options"
@onready var startGame = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Start Game"
@onready var stopHosting = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/Host Options/Stop Hosting"
@onready var leaveLobby = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/Host Options/Leave Lobby"
@onready var lobbyIdOutput = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/LobbyID Output"
@onready var lobbyName = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/Lobby Name"
@onready var copyToClipboard = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Copy To Clipboard"
@onready var mapsOptions = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/Host Options/MapsOptions"
@onready var playerNames = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/HBoxContainer5/Lobby Player Names"
@onready var playerCount = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/Lobby Player Count"
@onready var quantumBagelOptions = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/Host Options/QuantumBagelsOptions"
@onready var customLobbyVariables = $"Custom Lobby Variables"
@onready var switchTeam = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/Switch Teams"
@onready var switchSpec = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/Switch Spectator"
@onready var redIcon = Sprite2D.new()
@onready var blueIcon = Sprite2D.new()
#signal getCurrentGameScene

func _ready():
	global.map = mapsOptions.selected ##defaults to warehouse
	$"Custom Lobby Variables".hide()
	reset_lobby_menu()

func reset_lobby_menu():
	stopHosting.disabled = true
	leaveLobby.disabled = true
	mapsOptions.disabled = true
	startGame.disabled = true
	switchTeam.disabled = true
	switchSpec.disabled = true

func started_hosting():
	isHosting = true
	leaveLobby.disabled = true
	stopHosting.disabled = false
	mapsOptions.disabled = false
	switchTeam.disabled = false
	if global.maxPlayers == 32:
		switchSpec.disabled = false
	quantumBagelOptions.disabled = false
	customLobbyVariables.enable_clv_buttons()

func stopped_hosting():
	isHosting = false
	global.currentLobby = 0
	reset_lobby_menu()

func joined_game():
	startGame.disabled = true
	switchSpec.disabled = true
	switchTeam.disabled = true
	leaveLobby.disabled = false
	stopHosting.disabled = true
	mapsOptions.disabled = true
	quantumBagelOptions.disabled = true
	customLobbyVariables.disable_clv_buttons()

func can_start_game():
	if multiplayer.get_unique_id() == global.lobbyHostID:
		canStartGame.emit() ##connects to CLV
		print("lobby menu can start game")
		broadcast_all_options_rpc.rpc_id(global.lobbyHostID)
		##if its not converted to a string it doesnt work. unclear why
		var id = str(multiplayer.get_unique_id())
		startGame.disabled = false

func no_can_start_game():
	startGame.disabled = true
	switchTeam.disabled = true
	switchSpec.disabled = true
	#$"Join Game (it's already started)".disabled = true

func stop_main_menu_behaviour() -> void:
	global.muteTitleMusic.emit()
	global.hideTitleImages.emit()

@rpc("any_peer", "call_local")
func start_game():
	startGame.disabled = true
	switchTeam.disabled = true
	switchSpec.disabled = true
	#taken from godot docs, how to set gravity at runtime
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, GLV.gravity.value)
	broadcast_all_options()
	stop_main_menu_behaviour()
	Steam.setLobbyData(global.currentLobby,"gameHasStarted","true")
	self.get_parent().hide() ##hides main menu
	var scene = load("res://scenes/main level.tscn").instantiate()
	get_tree().root.add_child(scene)
	scene.start_game()

@rpc("any_peer", "call_local")
func broadcast_map(index : int):
	mapsOptions.select(index)
	mapsOptions.select_map()

@rpc("any_peer","call_local")
func broadcast_all_options_rpc():
	broadcast_map.rpc(mapsOptions.selected)
	broadcast_quantum_bagels.rpc(quantumBagelOptions.selected)

func broadcast_all_options():
	broadcast_map.rpc(mapsOptions.selected)
	broadcast_quantum_bagels.rpc(quantumBagelOptions.selected)

func _on_maps_options_item_selected(index: int) -> void:
	print(mapsOptions.selected)
	broadcast_map.rpc(index)

func _on_copy_to_clipboard_pressed() -> void:
	if lobbyIdOutput.text != "":
		DisplayServer.clipboard_set(lobbyIdOutput.text)

func _on_start_game_pressed() -> void:
	##only one person needs to tell the server the game started
	Steam.setLobbyJoinable(global.currentLobby,false)
	client.send_game_started_to_server()
	start_game.rpc()

func _on_stop_hosting_pressed() -> void:
	print("glboal clobby ", global.currentLobby)
	Steam.leaveLobby(global.currentLobby)
	stopHostingPressed.emit()
	lobbyMenuBack.emit()
	global.players.clear()
	global.currentLobby = 0

func _on_leave_lobby_pressed() -> void:
	leaveLobbyPressed.emit()
	Steam.leaveLobby(global.currentLobby)
	lobbyMenuBack.emit()
	global.players.clear()
	global.currentLobby = 0##fixes the unable to rejoin bug, button is disabled if global.currentlobby = the lobby id of that lobby individual

func _on_quantum_bagels_options_item_selected(index: int) -> void:
		broadcast_quantum_bagels.rpc(index)
		
@rpc("any_peer","call_local")
func broadcast_quantum_bagels(index : int):
	quantumBagelOptions.select(index)
	match quantumBagelOptions.selected:
		0:  ##no
			GLV.quantumBagels = false
		1:  ##yes
			GLV.quantumBagels = true


func _on_custom_lobby_variables_pressed() -> void:
	$"Custom Lobby Variables".show()
	$MarginContainer/PanelContainer.hide()

@rpc("any_peer","call_local")
func switch_teams(id : int):
	#prints("self mpid",multiplayer.get_unique_id(),"switch mpid",id,"redteam of switch preswitch",global.players[str(id)].redTeam)
	global.players[str(id)].redTeam = !global.players[str(id)].redTeam
	$"../Client".updateLobbyBoard()
	#prints("redteam of postswitch",global.players[str(id)].redTeam)

func _on_switch_teams_pressed() -> void:
	switch_teams.rpc(multiplayer.get_unique_id())

func _on_client_can_switch_teams() -> void:
	print("can switch teams")
	switchTeam.disabled = false
	if global.maxPlayers == 32:
		switchSpec.disabled = false

func focus() -> void:
	##https://forum.godotengine.org/t/how-to-cause-the-game-window-to-jump-to-the-foreground-when-an-event-occurs/80823
	#DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
	#DisplayServer.window_set_flag(DisplayServer.WindowFlags.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	#DisplayServer.window_set_flag(DisplayServer.WindowFlags.WINDOW_FLAG_ALWAYS_ON_TOP,false)
	#DisplayServer.window_request_attention()
	pass

@rpc("any_peer","call_local")
func switch_spectator(id : int):
	#prints("self mpid",multiplayer.get_unique_id(),"switch mpid",id,"redteam of switch preswitch",global.players[str(id)].redTeam)
	global.players[str(id)].spectator = !global.players[str(id)].spectator
	$"../Client".updateLobbyBoard()

func _on_switch_spectator_pressed() -> void:
	switch_spectator.rpc(multiplayer.get_unique_id())

##func no_can_switch_teams():


func _on_client_no_can_switch_teams() -> void:
	print("no can switch teams")
	switchTeam.disabled = true
	switchSpec.disabled = true
	##no_can_switch_teams.rpc()

func updateLobbyBoard():
	print("updating lobby board")
	playerNames.clear()
	playerCount.text = "Players Connected: " + str(global.players.size())
	for i in global.players:
		var displayName = global.players[i].displayName
		if global.maxPlayers != 32:
			if global.players[i].index - 1 < global.maxPlayers:
				if global.players[i].redTeam == true:
					if displayName != "":
						playerNames.add_item(global.players[i].displayName, redIcon.texture)
					else:
						playerNames.add_item("this idiot didnt enter a name (Soldat)", redIcon.texture)
				if global.players[i].redTeam == false:
					if displayName != "":
						playerNames.add_item(global.players[i].displayName, blueIcon.texture)
					else:
						playerNames.add_item("this idiot didnt enter a name (Soldat)", blueIcon.texture)
			else:
					playerNames.add_item("Spectator: " + global.players[i].displayName)
					global.players[i].spectator = true
		else:
			if global.players[i].spectator == true:
				playerNames.add_item("Spectator: " + global.players[i].displayName)
			elif global.players[i].spectator == false:
				if global.players[i].redTeam == true:
						if displayName != "":
							playerNames.add_item(global.players[i].displayName, redIcon.texture)
						else:
							playerNames.add_item("this idiot didnt enter a name (Soldat)", redIcon.texture)
				if global.players[i].redTeam == false:
					if displayName != "":
						playerNames.add_item(global.players[i].displayName, blueIcon.texture)
					else:
						playerNames.add_item("this idiot didnt enter a name (Soldat)", blueIcon.texture)
