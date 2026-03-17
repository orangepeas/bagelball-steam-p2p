extends Message

var id : int = 0
var send_channel = 1
var hostId : int
var lobbyValue = ""
var maxPlayersTemp = 2 ##default is 1v1
var privateLobby = 0

#@onready var blueIcon = ImageTexture.create_from_image(Image.load_from_file("res://assets/blue icon.png"))
#@onready var redIcon = ImageTexture.create_from_image(Image.load_from_file("res://assets/red icon.png"))
@onready var redIcon = Sprite2D.new()
@onready var blueIcon = Sprite2D.new()
@onready var lobbyMenu = $"../Lobby Menu V2"
@export var localServer : bool
@onready var lobbyName = $"../Create Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby Name Input"
@onready var joinPrivateLobbyUsername = $"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Username Input"
@onready var createLobbyUsername = $"../Create Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Username Input"
@onready var joinPrivateLobbyID = $"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input"
@onready var lobbyBrowser = $".."
@onready var lobbyList = $"../PanelContainer"

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

var peer = SteamMultiplayerPeer.new()

#signal canJoinGamePartway ##too difficult and pointless to implement
#signal noCanJoinGamePartway
#signal getCurrentGameScene

func _ready() -> void:
	blueIcon.texture = load("res://assets/images/blue icon.png")
	redIcon.texture = load("res://assets/images/red icon.png")
	global.pauseScreenLeaveLobby.connect(_on_pause_screen_leave_lobby_pressed)
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	check_command_line()
	
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	await get_tree().create_timer(0.5).timeout #need to wait for steam to intialise
	joinPrivateLobbyUsername.text = Steam.getPersonaName()
	createLobbyUsername.text = Steam.getPersonaName()
	id = Steam.getSteamID()

func connected_to_server():
	add_player_steam.rpc_id(int(Steam.getLobbyData(global.currentLobby, "host")), Steam.getSteamID())

func add_player(steam_id, sender_id):
	var isLobbyHost = false
	if sender_id == 1:
		isLobbyHost = true
	global.players[sender_id] = {
		"steam_id":steam_id,
		"steam_name":Steam.getFriendPersonaName(steam_id),
		"multiplayer_id":sender_id,
		"lobby_host":isLobbyHost,
		"index": global.players.size() + 1,
		"displayName": Steam.getFriendPersonaName(steam_id),
		"goals": 0,
		"spectator": false,
		"redTeam": false
	}
	if global.players.size() % 2 == 0:
		global.players[sender_id].redTeam = true

@rpc("any_peer","call_local")
func add_player_steam(steam_id):
	#for player in global.players:
		#if player.multiplayer_id == multiplayer.get_unique_id():
			#player.lobby_host = true
	add_player(steam_id, multiplayer.get_remote_sender_id())
	updateLobbyBoard()
	send_updated_players.rpc(global.players)

@rpc("any_peer","call_remote")
func send_updated_players(players : Dictionary):
	global.players = players
	for player in global.players:
		global.players[player].steam_name = Steam.getFriendPersonaName(global.players[player].steam_id)##so the friend nicknames dont get shared around
		#if player.steam_id == Steam.getLobbyOwner(global.lobby_id):
			#global.lobby_host_id = player.multiplayer_id
	updateLobbyBoard()

func peer_connected(multiplayer_id):
	print("peer connected ", multiplayer_id)

func peer_disconnected(multiplayer_id):
	print("peer disconnected ", multiplayer_id)

func connection_failed():
	print("couldnt connect")

func _process(_delta: float) -> void:
	if global.currentLobby != 0:
		read_messages()

func check_command_line() -> void:
	##this is if someone hasn't got the game launched but clicks on an invite
	var these_arguments: Array = OS.get_cmdline_args()
	if these_arguments.size() > 0:
		if these_arguments[0] == "+connect_lobby":
			if int(these_arguments[1]) > 0:
				# At this point, you'll probably want to change scenes
				# Something like a loading into lobby screen
				print("Command line lobby ID: %s" % these_arguments[1])
				join_lobby(int(these_arguments[1]))

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	print("lobby joined signal received")
	var lobbyOwnerId = Steam.getLobbyOwner(this_lobby_id)
	if lobbyOwnerId != Steam.getSteamID():
		peer = SteamMultiplayerPeer.new()
		peer.create_client(id)
		multiplayer.set_multiplayer_peer(peer)
		print("lobby joined")
		if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
			lobbyList.hide()
			lobbyMenu.show()
			$"../Join Private Lobby".hide()
			global.currentLobby = this_lobby_id
			hasJoined.emit()
		else:
			var fail_reason: String
			match response:
				Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
				Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
				Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
				Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
				Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
				Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
				Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
				Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
				Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
				Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."
			print("Failed to join this chat room: %s" % fail_reason)
			Steam.requestLobbyList()

func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	print("lobby created signal received")
	if connect == 1:
		peer = SteamMultiplayerPeer.new()
		peer.create_host()
		multiplayer.set_multiplayer_peer(peer)
		add_player(Steam.getSteamID(), 1)
		global.currentLobby = this_lobby_id
		updateLobbyBoard()
		print("Created a lobby: %s" % global.currentLobby)
		Steam.setLobbyJoinable(global.currentLobby, true)
		Steam.setLobbyData(global.currentLobby, "name", str(Steam.getPersonaName()) + "'s Lobby")
		Steam.setLobbyData(global.currentLobby, "gameHasStarted", "false")
		print("did set lobby host work: ", Steam.setLobbyData(global.currentLobby, "host", str(int(multiplayer.get_unique_id()))))

func _on_create_lobby_button_pressed() -> void:
	global.maxPlayers = maxPlayersTemp
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, global.maxPlayers)
	#multiplayer.multiplayer_peer = peer
	$"../Create Lobby".hide()
	$"../PanelContainer".hide()
	$"../Lobby Menu V2".show()
	isHosting.emit()
	isHostingBool = true
	global.lobbyHostID = Steam.getSteamID()

func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	##this is for if they join off your friends list or an invite
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	print("Joining %s's lobby..." % owner_name)
	# Attempt to join the lobby
	join_lobby(this_lobby_id)

func join_lobby(this_lobby_id: int) -> void:
	print("Attempting to join lobby %s" % this_lobby_id)
	global.players.clear()
	Steam.joinLobby(this_lobby_id)

@rpc("any_peer","call_local")
func sync_global_players(players):
	global.players = players

func _on_lobby_match_list(lobbies):
	lobbyBrowser.create_lobby_list(lobbies)

func _on_lobby_chat_update(_this_lobby_id: int, change_id: int, _making_change_id: int, chat_state: int) -> void:
	var changer_name: String = Steam.getFriendPersonaName(change_id)
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s has been banned from the lobby." % changer_name)
	else:
		print("%s did... something." % changer_name)

func updateLobbyBoard():
	print("updating lobby board")
	$"../Lobby Menu V2".playerNames.clear()
	$"../Lobby Menu V2".playerCount.text = "Players Connected: " + str(global.players.size())
	for i in global.players:
		var displayName = global.players[i].displayName
		if global.maxPlayers != 32:
			if global.players[i].index - 1 < global.maxPlayers:
				if global.players[i].redTeam == true:
					if displayName != "":
						$"../Lobby Menu V2".playerNames.add_item(global.players[i].displayName, redIcon.texture)
					else:
						$"../Lobby Menu V2".playerNames.add_item("this idiot didnt enter a name (Soldat)", redIcon.texture)
				if global.players[i].redTeam == false:
					if displayName != "":
						$"../Lobby Menu V2".playerNames.add_item(global.players[i].displayName, blueIcon.texture)
					else:
						$"../Lobby Menu V2".playerNames.add_item("this idiot didnt enter a name (Soldat)", blueIcon.texture)
			else:
					$"../Lobby Menu V2".playerNames.add_item("Spectator: " + global.players[i].displayName)
					global.players[i].spectator = true
		else:
			if global.players[i].spectator == true:
				$"../Lobby Menu V2".playerNames.add_item("Spectator: " + global.players[i].displayName)
			elif global.players[i].spectator == false:
				if global.players[i].redTeam == true:
						if displayName != "":
							$"../Lobby Menu V2".playerNames.add_item(global.players[i].displayName, redIcon.texture)
						else:
							$"../Lobby Menu V2".playerNames.add_item("this idiot didnt enter a name (Soldat)", redIcon.texture)
				if global.players[i].redTeam == false:
					if displayName != "":
						$"../Lobby Menu V2".playerNames.add_item(global.players[i].displayName, blueIcon.texture)
					else:
						$"../Lobby Menu V2".playerNames.add_item("this idiot didnt enter a name (Soldat)", blueIcon.texture)

func _on_pause_screen_leave_lobby_pressed() -> void:
	Steam.leaveLobby(global.currentLobby)
	peer.close()

func _on_leave_lobby_pressed() -> void:
	Steam.leaveLobby(global.currentLobby)
	if global.lobbyHostID == Steam.getSteamID():
		isNotHosting.emit()

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

func read_messages() -> void:
	# The maximum number of messages you want to read per call
	var max_messages: int = 10
	var messages : Array = Steam.receiveMessagesOnChannel(send_channel, max_messages)
	for message in messages:
		if message.is_empty() or message == null:
			print("WARNING: read an empty message with non-zero size!")
		else:
			message.payload = bytes_to_var(message.payload).decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
			# Get the remote user's ID
			#var message_sender: int = message.identity
			print("Message Payload: %s" % message.payload)

#func peer_connected_disconnected(lobby_id:int, changed_id:int, making_change_id:int, chat_state:int):
	#print("received player dc or connect")
	#if chat_state == Steam.ChatMemberStateChange.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		#print("peer connected: " + str(changed_id))
		#add_player(changed_id, Steam.getFriendPersonaName(changed_id))
		#if global.players.size() >= global.maxPlayers or global.maxPlayers == 32:
			#canSwitchTeams.emit()
			#canStartGame.emit()
			#print("can start game")
	#else:
		#print("peer disconnected: " + str(changed_id))
		#global.players.erase(changed_id)
		#if global.players.size() <= 1:
			#noCanStartGame.emit()
			#print("no can start game")
	#updateLobbyBoard()


#func on_lobby_created(connect, id):
	#if connect:
		#lobby_id = id
		#Steam.setLobbyData(lobby_id,"name",lobbyName.text)
		#Steam.setLobbyJoinable(lobby_id,true)
		#global.currentLobby = lobby_id
		#$"../Lobby Menu V2".lobbyIdOutput.text = str(lobby_id)



#func _on_gamemode_options_item_selected(index: int) -> void:
	#match index:
		#0:  #1v1
			#maxPlayersTemp = 2
		#1:  #2v2
			#maxPlayersTemp = 4
		#2:  #custom
			#maxPlayersTemp = 32
	#print("maxPlayersTemp = ",  maxPlayersTemp)
#
#@rpc("any_peer","call_local")
#func add_player(id, name):
	#global.players[id] = {
		#"name": name,
		#"id": id,
		#"index": global.players.size() + 1,
		#"displayName": name,
		#"goals": 0,
		#"spectator": false,
		#"redTeam": false
	#}

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
