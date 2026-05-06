extends Message

var socketPeer = WebSocketMultiplayerPeer.new()
var id : int = 0
var rtcPeer : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new() ##1 this is how you do your connection to other people
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

#signal canJoinGamePartway ##too difficult and pointless to implement
#signal noCanJoinGamePartway
#signal getCurrentGameScene

func _ready() -> void:
	if global.port == 6969:
		print("client live build")
	elif global.port == 2121:
		print("client test build")
	else:
		print("unknown build")
	blueIcon.texture = load("res://assets/images/blue icon.png")
	redIcon.texture = load("res://assets/images/red icon.png")
	multiplayer.connected_to_server.connect(RTC_connected_to_server)
	multiplayer.peer_connected.connect(RTC_peer_connected)
	multiplayer.peer_disconnected.connect(RTC_peer_disconnected)
	global.pauseScreenLeaveLobby.connect(_on_pause_screen_leave_lobby_pressed)
	local_server()

func local_server():
	if localServer == false:
		connect_to_server()

func RTC_connected_to_server():
	print("RTC server connected")

func RTC_peer_connected(id):
	print("RTC peer connected: " + str(id))
	if global.players.size() >= global.maxPlayers or global.maxPlayers == 32:
		canSwitchTeams.emit()
		canStartGame.emit()
		print("can start game")

func RTC_peer_disconnected(id):
	print("RTC peer disconnected: " + str(id))
	$"../User Disconnected".play()
	if global.players.size() <= 1:
		noCanStartGame.emit()
		print("no can start game")

func _process(_delta: float) -> void:
	socketPeer.poll()  ## keeps socket open and listening
	if socketPeer.get_available_packet_count() > 0:  ##if we have received data
		var packet = socketPeer.get_packet() ##get data
		if packet != null: ##if its not garbage data
			var dataString = packet.get_string_from_utf8() ##get our string from utf8 byte array (byte arrays are how we send data)
			var data = JSON.parse_string(dataString) ##parse string into json object
			
			if data.message == Message.M.id:
				id = int(data.id) ##in the switch from 4.3 to 4.4 godot has decided to add a .0 on the end of the id when putting it in a message. very nice.
				connected(id)
			
			if data.message == Message.M.userConnected:
				create_peer(data.id)
			
			if data.message == Message.M.lobby:
				##emitted by server when anyone joins the lobby
				if data.gameHasStarted != true:
					print("game hasnt started")
					$"../Join Private Lobby".hide()
					$"../PanelContainer".hide()
					$"../Lobby Menu V2".show()
					$"../User Connected".play()
					global.players = JSON.parse_string(data.players)
					hostId = data.host
					global.lobbyHostID = data.host
					global.maxPlayers = data.maxPlayers
					print("max players received ",global.maxPlayers)
					lobbyValue = data.lobbyValue
					$"../Lobby Menu V2".lobbyIdOutput.text = data.lobbyValue
					$"../Lobby Menu V2".lobbyName.text = data.lobbyName
					global.currentLobby = data.lobbyValue
					#join_game_as_spectator()
					if hostId == self.id:
						isHosting.emit()
						isHostingBool = true
					else:
						hasJoinedBool = true
						hasJoined.emit()
						$"../Lobby Menu V2".myId = id
				else:
					print("game has started you nobhead")
					$"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input".text = "Lobby already started. Sorry."
				updateLobbyBoard()

			if data.message == Message.M.leftLobby:
				global.players = JSON.parse_string(data.players)
				$"../User Disconnected".play()
				$"../Lobby Menu V2".playerNames.clear()
				if str(id) != str(data.disconnectedPlayer): ##so it only works if we are actually in the lobby
					rtcPeer.remove_peer(data.disconnectedPlayer)
					updateLobbyBoard()
				else: ##resets the lobby ui for the dced player
					global.currentLobby = ""

			if data.message == Message.M.destroyedlobby:
				##if i dont do this nonsense godot automatically updates the playerlist and it never works
				var playerList : Array 
				for l in global.players:
					playerList.append(l)
				
				##needs to be in this order for the no start game code to work
				global.players.clear()
				for p in playerList:
					if id != int(p):
						pass
						rtcPeer.remove_peer(int(p))
				print(rtcPeer.get_peers())
				updateLobbyBoard()
				isNotHosting.emit()
				receivedLobbyList.emit()
				$"..".reset_lobby_browser()
				
				var mainLevel = get_tree().get_first_node_in_group("mainLevel")
				if mainLevel != null:
					mainLevel.queue_free()
					global.backToMainMenu.emit()

			if data.message == Message.M.resetLobbyList:
				global.lobbies.clear()

			if data.message == Message.M.sendLobbyList:
				##for some reason it expects data.lobbyId to be a bool but it just sets the value to
				##null which isnt bad so i leave it (on the line below where we JSON.parse_string()
				global.lobbies[JSON.parse_string(data.lobbyId)] = {
					"lobbyId": data.lobbyId,
					"currentPlayers": data.currentPlayers,
					"maxPlayers": data.maxPlayers,
					"gameHasStarted": data.gameHasStarted,
					"privateLobby": data.privateLobby,
					"lobbyName": data.lobbyName
				}
				receivedLobbyList.emit()

			if data.message == Message.M.invalidLobby:
				$"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input".text = "Invalid Lobby ID/Game Already Started"

			if data.message == Message.M.candidate:
				data.orgPeer = int(data.orgPeer)
				if rtcPeer.has_peer(data.orgPeer):
					print("Got Candidate: " + str(data.orgPeer) + " my id" + str(id))
					var error = rtcPeer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
					print("candidate error is ", error_string(error))
					##OS.alert("candidate error = " + error_string(error))
					
					
			if data.message == Message.M.offer:
				if rtcPeer.has_peer(data.orgPeer):
					print("Got offer")
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("offer", data.data)
			
			if data.message == Message.M.answer:
				if rtcPeer.has_peer(data.orgPeer):
					print("Got answer")
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("answer", data.data)


func updateLobbyBoard():
	$"../Lobby Menu V2".playerNames.clear()
	$"../Lobby Menu V2".playerCount.text = "Players Connected: " + str(global.players.size())
	for i in global.players:
		var displayName = global.players[i].displayName
		if global.maxPlayers != 32:
			if global.players[i].index - 1 < global.maxPlayers:
				if global.players[i].redTeam == true:
				#if int(global.players[i].index) % 2 == 1:##global.player[i].index goes up by 1 for each dict entry
					if displayName != "":
						$"../Lobby Menu V2".playerNames.add_item(global.players[i].displayName, redIcon.texture)
					else:
						$"../Lobby Menu V2".playerNames.add_item("this idiot didnt enter a name (Soldat)", redIcon.texture)
				if global.players[i].redTeam == false:
				#elif int(global.players[i].index) % 2 == 0:
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
					#if int(global.players[i].index) % 2 == 1:##global.player[i].index goes up by 1 for each dict entry
						if displayName != "":
							$"../Lobby Menu V2".playerNames.add_item(global.players[i].displayName, redIcon.texture)
						else:
							$"../Lobby Menu V2".playerNames.add_item("this idiot didnt enter a name (Soldat)", redIcon.texture)
				if global.players[i].redTeam == false:
				#elif int(global.players[i].index) % 2 == 0:
					if displayName != "":
						$"../Lobby Menu V2".playerNames.add_item(global.players[i].displayName, blueIcon.texture)
					else:
						$"../Lobby Menu V2".playerNames.add_item("this idiot didnt enter a name (Soldat)", blueIcon.texture)
				
				

func connected(id):
	rtcPeer.create_mesh(id) ##creates a mesh network, gcse computer science innit
	multiplayer.multiplayer_peer = rtcPeer ##hooks up RPC calls

##web rtc connection
func create_peer(id):
	if id != self.id:
		print("peer create start")
		noCanStartGame.emit()
		noCanSwitchTeams.emit()
		##2 this describes the connection, this is who this person is, this is their information, this is how i do the information
		var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
		peer.initialize({
			"iceServers": [{ 
				"urls": ["stun:134.209.181.224:3478", "stun:stun.l.google.com:19302"],
			 }] ##my attempt at fixing a connectivity bug some americans where having, have 2 stun servers
				##one is googles free, other is hosted on my digital ocean droplet
		})
		#print("binding id " + str(id) + " my id is " + str(self.id))
		
		##below signal is emitted after peer.create_offer runs
		peer.session_description_created.connect(self.offer_created.bind(id)) ##bind allows you to pass variables into functions when signal is triggered
		peer.ice_candidate_created.connect(self.ice_candidate_created.bind(id))
		rtcPeer.add_peer(peer, id)
		
		if id < rtcPeer.get_unique_id(): ##dunno, apparently its so we only create the offer if we are a peer, not a lobby
			peer.create_offer()
		print("peer create end")
		##i think the issue is to do with this line below. 
		
		#if id < rtcPeer.get_unique_id(): ##dunno, apparently its so we only create the offer if we are a peer, not a lobby
			#peer.create_offer()


func offer_created(type, data, id):
	if !rtcPeer.has_peer(id): ##avoid sending rtc offer to peers that dont exist
		return
	rtcPeer.get_peer(id).connection.set_local_description(type, data) ##local_description is my description of me, for other peers this is their remote description of me, how to connect
	
	if type == "offer":
		send_offer(id, data)
	else:
		send_answer(id, data)

func send_offer(id, data):
	var message = {
		"peer": id,
		"orgPeer": self.id,
		"message": Message.M.offer,
		"data": data,
		"lobby": lobbyValue 
	}
	socketPeer.put_packet(JSON.stringify(message).to_utf8_buffer())

func send_answer(id, data):
	var message = {
		"peer": id,
		"orgPeer": self.id,
		"message": Message.M.answer,
		"data": data,
		"lobby": lobbyValue 
	}
	socketPeer.put_packet(JSON.stringify(message).to_utf8_buffer())

func ice_candidate_created(midName, indexName, sdpName, id):
	var message = {
		"peer": id,
		"orgPeer": self.id,
		"message": Message.M.candidate,
		"mid": midName,
		"index": indexName,
		"sdp": sdpName,
		"lobby": lobbyValue 
	}
	socketPeer.put_packet(JSON.stringify(message).to_utf8_buffer())

func connect_to_server():
	if localServer == true:
		socketPeer.create_client("ws://127.0.0.1:" + str(global.port)) ##ws means websocket
		print("BOoTING IN LOCAL MODE")
	else:
		print("BootITIng in SERVER MODE")
		var error = socketPeer.create_client("ws://134.209.181.224:" + str(global.port)) ##comment this line out for local server behaviour
		print("connection error: ", error_string(error))
	print("started client")


func _on_start_client_button_down() -> void:
	connect_to_server()

func send_game_started_to_server() -> void:
	var message = {
		"message": Message.M.gameStarted,
		"lobbyValue": global.currentLobby,
		"map": global.map
	}
	socketPeer.put_packet(JSON.stringify(message).to_utf8_buffer())


@rpc("any_peer")
func ping():
	print("ping from " + str(multiplayer.get_remote_sender_id()))

func _on_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		localServer = true
	if toggled_on == false:
		localServer = false
	local_server()

func _on_stop_hosting_pressed() -> void:
	var message = {
		"message": Message.M.destroylobby,
		"lobbyValue": $"../Lobby Menu V2".lobbyIdOutput.text,
	}
	socketPeer.put_packet(JSON.stringify(message).to_utf8_buffer())

func _on_pause_screen_leave_lobby_pressed() -> void:
	var message = {
		"id": id,
		"message": Message.M.leavelobby,
		"lobbyValue": global.currentLobby
	}
	socketPeer.put_packet(JSON.stringify(message).to_utf8_buffer())

func _on_leave_lobby_pressed() -> void:
	var message = {
		"id": id,
		"message": Message.M.leavelobby,
		"lobbyValue": $"../Lobby Menu V2".lobbyIdOutput.text,
	}
	socketPeer.put_packet(JSON.stringify(message).to_utf8_buffer())

func get_lobby_list() -> void:
	var message = {
		"message": Message.M.getLobbyList,
		"id": id
	}
	socketPeer.put_packet(JSON.stringify(message).to_utf8_buffer())
	print("sent get lobby list")



#@rpc("any_peer","call_remote")
#func get_current_game_scene():
	#getCurrentGameScene.emit()
#
#func _on_join_game_its_already_started_pressed() -> void:
	#get_current_game_scene.rpc()
	#get_tree().root.add_child(global.currentGameScene)
	#global.joinGamePartwayThrough.emit()


func _on_create_lobby_button_pressed() -> void:
	global.maxPlayers = maxPlayersTemp
	var playerName = $"../Create Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Username Input".text
	var message = {
		"id": id,
		"message": Message.M.lobby,
		"name": playerName,
		"lobbyValue": "",
		"maxPlayers": global.maxPlayers,
		"privateLobby": privateLobby,
		"lobbyName": lobbyName.text
	}
	socketPeer.put_packet(JSON.stringify(message).to_utf8_buffer())
	$"../Create Lobby".hide()
	$"../PanelContainer".hide()
	$"../Lobby Menu V2".show()

func _on_join_lobby_button_down(lobbyId : String) -> void:
	$"../Join Private Lobby".show()
	$"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input".hide()
	$"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input".text = lobbyId
	$"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/Lobby ID label".hide()

func _on_join_private_lobby_button_pressed() -> void:
	print("join game pressed")
	var message = {
		"id": id,
		"message": Message.M.lobby,
		"name": $"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Username Input".text,
		"lobbyValue": $"../Join Private Lobby/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input".text,
	}
	socketPeer.put_packet(JSON.stringify(message).to_utf8_buffer())

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

func _on_gamemode_options_item_selected(index: int) -> void:
	match index:
		0:  #1v1
			maxPlayersTemp = 2
		1:  #2v2
			maxPlayersTemp = 4
		2:  #custom
			maxPlayersTemp = 32
	print("maxPlayersTemp = ",  maxPlayersTemp)
