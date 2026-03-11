extends Message

var id : int = 0
var hostId : int
var lobbyValue = ""
var maxPlayersTemp = 2 ##default is 1v1
var privateLobby = 0

#@onready var blueIcon = ImageTexture.create_from_image(Image.load_from_file("res://assets/blue icon.png"))
#@onready var redIcon = ImageTexture.create_from_image(Image.load_from_file("res://assets/red icon.png"))
@onready var redIcon = Sprite2D.new()
@onready var blueIcon = Sprite2D.new()
@onready var lobbyMenu = $".."
@export var localServer : bool
@onready var lobbyName = $"../Create Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby Name Input"
@onready var joinPrivateLobbyUsername = $"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Username Input"
@onready var createLobbyUsername = $"../Create Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Username Input"
@onready var joinPrivateLobbyID = $"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input"
@onready var lobbyBrowser = $".."

var isHostingBool : bool = false
var hasJoinedBool : bool = false

signal isHosting
signal isNotHosting
signal hasJoined
signal canStartGame
signal noCanStartGame
signal gameAlreadyStarted
signal receivedLobbyList
signal canSwitchTeams
signal noCanSwitchTeams

var lobby_id = 0
var peer = SteamMultiplayerPeer.new()

#signal canJoinGamePartway ##too difficult and pointless to implement
#signal noCanJoinGamePartway
#signal getCurrentGameScene

func _ready() -> void:
	blueIcon.texture = load("res://assets/blue icon.png")
	redIcon.texture = load("res://assets/red icon.png")
	global.pauseScreenLeaveLobby.connect(_on_pause_screen_leave_lobby_pressed)
	Steam.lobby_created.connect(on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.server_disconnected.connect(disconnected_from_server)
	Steam.lobby_chat_update.connect(peer_connected_disconnected)
	await get_tree().create_timer(0.5).timeout #need to wait for steam to intialise
	joinPrivateLobbyUsername.text = Steam.getPersonaName()
	createLobbyUsername.text = Steam.getPersonaName()

func connected_to_server():
	add_player.rpc_id(int(Steam.getLobbyData(global.currentLobby, "host")))

func disconnected_from_server():
	pass ##erase player

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		global.currentLobby = this_lobby_id
		peer.connect_lobby(this_lobby_id)
		multiplayer.multiplayer_peer = peer
		add_player(Steam.getSteamID(), joinPrivateLobbyUsername.text)
		hasJoined.emit()

@rpc("any_peer","call_local")
func sync_global_players(players):
	global.players = players

func _on_lobby_match_list(lobbies):
	lobbyBrowser.create_lobby_list(lobbies)

func peer_connected_disconnected(lobby_id:int, changed_id:int, making_change_id:int, chat_state:int):
	print("received player dc or connect")
	if chat_state == Steam.ChatMemberStateChange.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("peer connected: " + str(changed_id))
		add_player(changed_id, Steam.getFriendPersonaName(changed_id))
		if global.players.size() >= global.maxPlayers or global.maxPlayers == 32:
			canSwitchTeams.emit()
			canStartGame.emit()
			print("can start game")
	else:
		print("peer disconnected: " + str(changed_id))
		global.players.erase(changed_id)
		if global.players.size() <= 1:
			noCanStartGame.emit()
			print("no can start game")
	updateLobbyBoard()
#func updateLobbyBoard():
	#print("updating lobby board")
	#$"../Lobby Menu V2".playerNames.clear()
	#$"../Lobby Menu V2".playerCount.text = "Players Connected: " + str(global.players.size())
	#for i in global.players:
		#var displayName = global.players[i].displayName
		#if global.maxPlayers != 32:
			#if global.players[i].index - 1 < global.maxPlayers:
				#if global.players[i].redTeam == true:
					#if displayName != "":
						#$"../Lobby Menu V2".playerNames.add_item(global.players[i].displayName, redIcon.texture)
					#else:
						#$"../Lobby Menu V2".playerNames.add_item("this idiot didnt enter a name (Soldat)", redIcon.texture)
				#if global.players[i].redTeam == false:
					#if displayName != "":
						#$"../Lobby Menu V2".playerNames.add_item(global.players[i].displayName, blueIcon.texture)
					#else:
						#$"../Lobby Menu V2".playerNames.add_item("this idiot didnt enter a name (Soldat)", blueIcon.texture)
			#else:
					#$"../Lobby Menu V2".playerNames.add_item("Spectator: " + global.players[i].displayName)
					#global.players[i].spectator = true
		#else:
			#if global.players[i].spectator == true:
				#$"../Lobby Menu V2".playerNames.add_item("Spectator: " + global.players[i].displayName)
			#elif global.players[i].spectator == false:
				#if global.players[i].redTeam == true:
						#if displayName != "":
							#$"../Lobby Menu V2".playerNames.add_item(global.players[i].displayName, redIcon.texture)
						#else:
							#$"../Lobby Menu V2".playerNames.add_item("this idiot didnt enter a name (Soldat)", redIcon.texture)
				#if global.players[i].redTeam == false:
					#if displayName != "":
						#$"../Lobby Menu V2".playerNames.add_item(global.players[i].displayName, blueIcon.texture)
					#else:
						#$"../Lobby Menu V2".playerNames.add_item("this idiot didnt enter a name (Soldat)", blueIcon.texture)

func _on_pause_screen_leave_lobby_pressed() -> void:
	Steam.leaveLobby(global.currentLobby)

func _on_leave_lobby_pressed() -> void:
	Steam.leaveLobby(global.currentLobby)
	if global.lobbyHostID == Steam.getSteamID():
		isNotHosting.emit()

#func _on_create_lobby_button_pressed() -> void:
	#global.maxPlayers = maxPlayersTemp
	#Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC,)
	#multiplayer.multiplayer_peer = peer
	#$"../Create Lobby".hide()
	#$"../PanelContainer".hide()
	#$"../Lobby Menu V2".show()
	#isHosting.emit()
	#isHostingBool = true
	#global.lobbyHostID = Steam.getSteamID()
	#add_player(Steam.getSteamID(), createLobbyUsername.text)

func on_lobby_created(connect, id):
	if connect:
		lobby_id = id
		Steam.setLobbyData(lobby_id,"name",lobbyName.text)
		Steam.setLobbyJoinable(lobby_id,true)
		global.currentLobby = lobby_id
		$"../Lobby Menu V2".lobbyIdOutput.text = str(lobby_id)

func _on_join_lobby_button_down(lobbyId : int) -> void:
	$"../Join Private Lobby".show()
	$"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input".hide()
	$"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input".text = str(lobbyId)
	$"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/Lobby ID label".hide()

#func _on_join_private_lobby_button_pressed() -> void:
	#Steam.joinLobby(int(joinPrivateLobbyID.text))
	#print("join game pressed")

func join_game_as_spectator():
	$"../Lobby Menu V2".stop_main_menu_behaviour()
	self.get_parent().hide() ##hides main menu
	var scene = load("res://scenes/main_level_join_late.tscn").instantiate()
	get_tree().root.add_child(scene)
	scene.join_game_as_spec.rpc()

func _on_private_lobby_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		privateLobby = 1 ##true
	else:
		privateLobby = 0

#func _on_gamemode_options_item_selected(index: int) -> void:
	#match index:
		#0:  #1v1
			#maxPlayersTemp = 2
		#1:  #2v2
			#maxPlayersTemp = 4
		#2:  #custom
			#maxPlayersTemp = 32
	#print("maxPlayersTemp = ",  maxPlayersTemp)

@rpc("any_peer","call_local")
func add_player(id, name):
	global.players[id] = {
		"name": name,
		"id": id,
		"index": global.players.size() + 1,
		"displayName": name,
		"goals": 0,
		"spectator": false,
		"redTeam": false
	}

#func peer_connected(id):
	#print("peer connected: " + str(id))
	#if global.players.size() >= global.maxPlayers or global.maxPlayers == 32:
		#canSwitchTeams.emit()
		#canStartGame.emit()
		#print("can start game")
#
#func peer_disconnected(id):
	#print("peer disconnected: " + str(id))
	#$"../User Disconnected".play()
	#if global.players.size() <= 1:
		#noCanStartGame.emit()
		#print("no can start game")

#func _process(_delta: float) -> void:

#if data.message == Message.M.lobby:
###emitted by server when anyone joins the lobby
#if data.gameHasStarted != true:
	#print("game hasnt started")
	#$"../Join Private Lobby".hide()
	#$"../PanelContainer".hide()
	#$"../Lobby Menu V2".show()
	#$"../User Connected".play()
	#global.players = JSON.parse_string(data.players)
	#hostId = data.host
	#global.lobbyHostID = data.host
	#global.maxPlayers = data.maxPlayers
	#print("max players received ",global.maxPlayers)
	#lobbyValue = data.lobbyValue
	#$"../Lobby Menu V2".lobbyIdOutput.text = data.lobbyValue
	#$"../Lobby Menu V2".lobbyName.text = data.lobbyName
	#global.currentLobby = data.lobbyValue
	##join_game_as_spectator()
	#if hostId == self.id:
		#isHosting.emit()
		#isHostingBool = true
	#else:
		#hasJoinedBool = true
		#hasJoined.emit()
		#$"../Lobby Menu V2".myId = id
#else:
	#print("game has started you nobhead")
	#$"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input".text = "Lobby already started. Sorry."
#updateLobbyBoard()
#
#if data.message == Message.M.leftLobby:
#global.players = JSON.parse_string(data.players)
#$"../User Disconnected".play()
#$"../Lobby Menu V2".playerNames.clear()
#if str(id) != str(data.disconnectedPlayer): ##so it only works if we are actually in the lobby
	#rtcPeer.remove_peer(data.disconnectedPlayer)
	#updateLobbyBoard()
#else: ##resets the lobby ui for the dced player
	#global.currentLobby = ""
#
#if data.message == Message.M.destroyedlobby:
###if i dont do this nonsense godot automatically updates the playerlist and it never works
#var playerList : Array 
#for l in global.players:
	#playerList.append(l)
#
###needs to be in this order for the no start game code to work
#global.players.clear()
#for p in playerList:
	#if id != int(p):
		#pass
		#rtcPeer.remove_peer(int(p))
#print(rtcPeer.get_peers())
#updateLobbyBoard()
#isNotHosting.emit()
#receivedLobbyList.emit()
#$"..".reset_lobby_browser()
#
#var mainLevel = get_tree().get_first_node_in_group("mainLevel")
#if mainLevel != null:
	#mainLevel.queue_free()
	#global.backToMainMenu.emit()
#
#
#if data.message == Message.M.invalidLobby:
#$"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input".text = "Invalid Lobby ID/Game Already Started"
