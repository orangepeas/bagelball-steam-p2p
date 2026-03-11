extends Control

@onready var lobbyScene = preload("res://scenes/lobby individual.tscn")
@onready var lobbyList = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/LobbyList
@onready var joinPrivateLobbyID = $"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input"
@onready var peer : SteamMultiplayerPeer = SteamMultiplayerPeer.new()

signal isHosting
signal hasJoined
signal playersUpdated

func _ready():
	#Steam.lobby_match_list.connect(create_lobby_list)
	#Steam.join_requested.connect(_on_lobby_join_requested)
	#Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	#Steam.lobby_created.connect(_on_lobby_created)
	#Steam.lobby_joined.connect(_on_lobby_joined)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	check_command_line()
	for oldLobby in lobbyList.get_children():
		oldLobby.queue_free()
	reset_lobby_browser()

func connected_to_server():
	print("connected to server")
	add_player.rpc_id(int(Steam.getLobbyData(global.currentLobby, "host")), Steam.getSteamID())

@rpc("any_peer","call_local")
func add_player(steam_id):
	var sender_id = multiplayer.get_remote_sender_id()
	global.players.append({
		"steam_id":steam_id,
		"steam_name":Steam.getFriendPersonaName(steam_id),
		"multiplayer_id":sender_id,
		})
	playersUpdated.emit()
	send_updated_players.rpc(global.players)

@rpc("any_peer","call_remote")
func send_updated_players(players : Array):
	global.players = players
	for player in global.players:
		player.steam_name = Steam.getFriendPersonaName(player.steam_id)##so the friend nicknames dont get shared around
	playersUpdated.emit()

func peer_connected(id):
	print("peer connected ", id)

func peer_disconnected(id):
	peer.close()

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	print("lobby joined signal received")
	var id = Steam.getLobbyOwner(this_lobby_id)
	if id != Steam.getSteamID():
		peer = SteamMultiplayerPeer.new()
		peer.create_client(id, 0)
		multiplayer.set_multiplayer_peer(peer)
		print("lobby joined but not created")
		if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
			$LobbyList.hide()
			$LobbyMenu.show()
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
			request_lobby_list()

func request_lobby_list():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

func _on_refresh_lobby_pressed() -> void:
	request_lobby_list()

func _on_gamemode_options_item_selected(index: int) -> void:
	match index:
		0:  #1v1
			global.maxPlayers = 2
		1:  #2v2
			global.maxPlayers = 4
		2:  #custom
			global.maxPlayers = 32

#func _on_create_lobby_button_pressed() -> void:
	#if global.currentLobby == 0:
		#Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, global.maxPlayers)
		#$LobbyList.hide()
		#$LobbyMenu.show()
	#multiplayer.multiplayer_peer = peer
	#$"../Create Lobby".hide()
	#$"../PanelContainer".hide()
	#$"../Lobby Menu V2".show()
	#isHosting.emit()
	##isHostingBool = true
	#global.lobbyHostID = Steam.getSteamID()

func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	print("lobby created signal received")
	if connect == 1:
		peer = SteamMultiplayerPeer.new()
		peer.create_host(0)
		multiplayer.set_multiplayer_peer(peer)
		global.currentLobby = this_lobby_id
		global.players.append({
			"steam_id":Steam.getSteamID(), 
			"steam_name":Steam.getFriendPersonaName(Steam.getSteamID()), 
			"multiplayer_id":multiplayer.get_unique_id(),
			"lobby_host":true
			})
		global.currentLobby = this_lobby_id
		#global.lobby_host_id = multiplayer.get_unique_id()
		playersUpdated.emit()
		print("Created a lobby: %s" % global.currentLobby)
		Steam.setLobbyJoinable(global.currentLobby, true)
		Steam.setLobbyData(global.currentLobby, "name", str(Steam.getPersonaName()) + "'s Lobby")
		print("did set lobby host work: ", Steam.setLobbyData(global.currentLobby, "host", str(int(multiplayer.get_unique_id()))))

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

func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	##this is for if they join off your friends list or an invite
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	print("Joining %s's lobby..." % owner_name)
	# Attempt to join the lobby
	join_lobby(this_lobby_id)

func join_lobby(id : int) -> void:
	Steam.joinLobby(id)
	print("join game pressed")

func reset_lobby_browser():
	$"Create Lobby".hide()
	$"Join Private Lobby".hide()
	$"Lobby Menu V2".hide()
	enable_buttons()
	$PanelContainer.show()

func create_lobby_list(lobbies : Array):
	#prints("creating lobby list", global.lobbies)
	for oldLobby in lobbyList.get_children():
		oldLobby.queue_free()
	for lobby in lobbies:
		var lobbyDisplay = lobbyScene.instantiate()
		lobbyDisplay.lobbyId = lobby
		if lobby.gameHasStarted == true or global.currentLobby == lobby:
			lobbyDisplay.find_child("JoinLobbyButton").disabled = true
		lobbyDisplay.find_child("LabelLobbyName").text = Steam.getLobbyData(lobby,"name")
		lobbyDisplay.find_child("CurrentPlayerDisplay").text = str(Steam.getNumLobbyMembers(lobby)) + "/" + "idk"
		lobbyList.add_child(lobbyDisplay)

func hide_all_others(menuOptionWeWant : Control):
	for menuOption in get_tree().get_nodes_in_group("SettingsMenuOption"):
		if menuOption != menuOptionWeWant:
			menuOption.hide()
	menuOptionWeWant.show()

func _on_full_back_pressed() -> void:
	$"..".hide_all_others($"../Initial")

func _on_join_lobby_pressed() -> void:
	disable_buttons()
	$"Join Private Lobby".show()
	$"Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input".show()
	$"Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input".text = ""
	$"Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/Lobby ID label".show()

func _on_create_lobby_pressed() -> void:
	disable_buttons()
	$"Create Lobby".show()

func disable_buttons() -> void:
	for button in $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer.get_children():
		button.disabled = true

func enable_buttons() -> void:
	for button in $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer.get_children():
		button.disabled = false

func _on_start_server_pressed() -> void:
	$Server.start_server()

func _on_start_client_pressed() -> void:
	$Client._on_start_client_button_down()

func _on_lobby_menu_v_2_lobby_menu_back() -> void:
	enable_buttons()
	$PanelContainer.show()
	$"Lobby Menu V2".hide()


func _on_username_input_text_changed() -> void:
	var inputText = $"Create Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Username Input"
	sanitise_username_input(inputText)

func _on_username_input_join_text_changed() -> void:
	var inputText = $"Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Username Input"
	sanitise_username_input(inputText)
	
func _on_lobby_name_input_text_changed() -> void:
	var inputText = $"Create Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby Name Input"
	var caret = inputText.get_caret_column()
	var newText = inputText.text
	#var blah = inputText.text.right(1).to_ascii_buffer()
	if inputText.text.length() > 32:
		newText = inputText.text.left(-(inputText.text.length()-32)) ##removes last character
	if inputText.text.contains("\n"):
		newText = inputText.text.replace("\n","")
	inputText.text = newText
	inputText.set_caret_column(caret)

func sanitise_username_input(inputText):
	var caret = inputText.get_caret_column()
	var newText = inputText.text
	#var blah = inputText.text.right(1).to_ascii_buffer()
	if inputText.text.length() > 32:
		newText = inputText.text.left(-(inputText.text.length()-64)) ##removes last character
	if inputText.text.contains("\n"):
		newText = inputText.text.replace("\n","")
	inputText.text = newText
	inputText.set_caret_column(caret)

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

func _on_join_private_lobby_button_pressed() -> void:
	join_lobby(int(joinPrivateLobbyID.text))
