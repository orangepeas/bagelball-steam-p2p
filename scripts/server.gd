extends Message

var peer = WebSocketMultiplayerPeer.new()
var users = {}
var lobbies = {}

var Characters = "abcdefghijlmnopqrstuvxyzABCDEFGHIJLMNOPQRSTUVWXYZ0123456789"

var hostPort = global.port

func _ready() -> void:
	peer.connect("peer_connected", peer_connected)
	peer.connect("peer_disconnected", peer_disconnected)
	if "--testbuild" in OS.get_cmdline_args():
		hostPort = 2121 ##test port
	if "--server" in OS.get_cmdline_args():
		print("hosting on " + str(hostPort))
		peer.create_server(hostPort)

func _process(_delta: float) -> void:
	peer.poll()  ## this holds the socket open for a second and gets data if it comes through, since the peer is basically a socket
	if peer.get_available_packet_count() > 0:  ##if we have received data
		var packet = peer.get_packet() ##get data
		if packet != null: ##if its not garbage data
			var dataString = packet.get_string_from_utf8() ##get our string from utf8 byte array (byte arrays are how we send data)
			var data = JSON.parse_string(dataString) ##parse string into json object
			#print(data)
			if data.message == Message.M.lobby:
				join_lobby(data)
				
			if data.message == Message.M.offer or data.message == Message.M.answer or data.message == Message.M.candidate:
				##relays the offer message and candidate to the other peer
				#if data.message == Message.M.offer or data.message == Message.M.answer:
					#print("source id is " + str(data.orgPeer) + " Message.M Data is " + data.data)
				#elif data.message == Message.M.candidate:
					#print("source id is " + str(data.orgPeer) + " Message.M index is " + str(data.index) + ", mid is " + str(data.mid) + ", sdp is " + str(data.sdp))
				send_to_player(data.peer, data)
			
			if data.message == Message.M.destroylobby:
				destroy_lobby(data.lobbyValue)
			if data.message == Message.M.leavelobby:
				data.id = int(data.id)
				##if the host leaves then the lobby is destroyed, for pause screen functionality
				if lobbies.has(data.lobbyValue): ##if the host has already destroyed the lobby this errors
					if lobbies[data.lobbyValue].HostID == data.id:
						destroy_lobby(data.lobbyValue)
					else:
						leave_lobby(data.id, data.lobbyValue)

			if data.message == Message.M.gameStarted:
				lobbies[data.lobbyValue].GameHasStarted = true
				lobbies[data.lobbyValue].Map = data.map
				##this is quite high amounts of sending, so maybe it crashes server in the future
				send_lobby_list_to_everyone()
			
			if data.message == Message.M.getLobbyList:
				data.id = int(data.id)
				send_lobby_list(data.id)

func peer_connected(id):
	print("Peer Connected: " + str(id))
	id = int(id)
	users[id] = {
		"id": id,
		"message" : Message.M.id
	}
	peer.get_peer(id).put_packet(JSON.stringify(users[id]).to_utf8_buffer())
	##this get_peer(id) thing means it only sends this data to the peer that has just connected
	##otherwise it just sends it to all peers with socket open which we dont want

func peer_disconnected(id):
	print("Peer Disconnected: " + str(id))
	id = int(id)
	for key in lobbies.keys(): ##loops through all lobby keys
		if lobbies.get(key).HostID == id: ##if there is a lobby with a hostID equal to the disconnected ID, i.e. if the host leaves
			destroy_lobby(key)
	users.erase(id)

func send_lobby_list(userId):
	var data = {
		"message": Message.M.resetLobbyList
	}
	send_to_player(userId, data)
	print("server says: ", lobbies)
	if lobbies.size() != 0:
		for lobby in lobbies:
			data = {
				"message": Message.M.sendLobbyList,
				"lobbyId": JSON.stringify(lobby),
				"currentPlayers": lobbies[lobby].Players.size(),
				"maxPlayers": lobbies[lobby].MaxPlayers,
				"gameHasStarted": lobbies[lobby].GameHasStarted,
				"privateLobby": lobbies[lobby].PrivateLobby,
				"lobbyName": lobbies[lobby].LobbyName
			}
			send_to_player(userId, data)
	else:
		data = {
			"message": Message.M.sendLobbyList,
			"lobbyId": "null",
			"currentPlayers": 0,
			"maxPlayers": 0,
			"gameHasStarted": false,
			"privateLobby": 0,
			"lobbyName": ""
		}
		send_to_player(userId, data)

func destroy_lobby(lobbyid):
	var lobby = lobbies.get(lobbyid)
	for p in lobby.Players:
		if peer.get_peer(int(p)):
			##this kicks the players out that are in the lobby
			var lobbyInfo = {
				"message": Message.M.destroyedlobby,
				"playersToDestroy": JSON.stringify(lobbies[lobbyid].Players),
				"lobbyValue": lobbyid
			}
			send_to_player(int(p), lobbyInfo)
	lobbies.erase(lobbyid)
	##this removes it from possible joinables
	send_lobby_list_to_everyone()


func leave_lobby(userid, lobbyid):
	#if lobbies.get(lobbyid): ##only works if the lobby exists
	var lobby = lobbies.get(lobbyid)
	##if i dont do this nonsense godot automatically updates the playerlist and it never works
	var playerList : Array 
	for l in lobby.Players:
		playerList.append(l)
	
	lobby.Players.erase(userid)
	
	for p in playerList:
		var lobbyInfo = {
			"message": Message.M.leftLobby,
			"players": JSON.stringify(lobbies[lobbyid].Players), ##godot gets confused with lists of objects so safe bet is to JSON stringify
			"host": lobbies[lobbyid].HostID,
			"lobbyValue": lobbyid,
			"disconnectedPlayer": userid
		}
		send_to_player(p, lobbyInfo)
	send_lobby_list_to_everyone()

func start_server():
	peer.create_server(hostPort)
	print("started server")

func join_lobby(user):
	#var result = ""
	user.id = int(user.id) ##just 4.4 things
	if user.lobbyValue == "":
		user.lobbyValue = generate_random_string()
		lobbies[user.lobbyValue] = Lobby.new(user.id)
		lobbies[user.lobbyValue].MaxPlayers = user.maxPlayers
		lobbies[user.lobbyValue].PrivateLobby = user.privateLobby
		lobbies[user.lobbyValue].LobbyName = user.lobbyName
	if !lobbies.has(user.lobbyValue) or lobbies[user.lobbyValue].GameHasStarted == true:
		var data = {
			"message": Message.M.invalidLobby
		}
		send_to_player(user.id, data)
	else:
		lobbies[user.lobbyValue].AddPlayer(user.id, user.name)
		var lobbyCount = lobbies[user.lobbyValue].Players.size()
		if lobbyCount % 2 == 1:
			lobbies[user.lobbyValue].Players[user.id].redTeam = false
		elif lobbyCount % 2 == 0:
			lobbies[user.lobbyValue].Players[user.id].redTeam = true
		for p in lobbies[user.lobbyValue].Players:
			
			############idfk what the point of this bit is
			var data = {
				"message": Message.M.userConnected,
				"id": user.id
			}
			send_to_player(p, data)
			
			var data2 = {
				"message": Message.M.userConnected,
				"id": p
			}
			send_to_player(user.id, data2)
			##############idk man
			##seems to send players each others data which then the client handles and creates peers. surely itd create multiple peers
			##for the same user though. not sure. not touching.
			
			var lobbyInfo = {
				"message": Message.M.lobby,
				"players": JSON.stringify(lobbies[user.lobbyValue].Players), ##godot gets confused with lists of objects so safe bet is to JSON stringify
				"host": lobbies[user.lobbyValue].HostID,
				"lobbyValue": user.lobbyValue,
				"gameHasStarted": lobbies[user.lobbyValue].GameHasStarted,
				"maxPlayers": lobbies[user.lobbyValue].MaxPlayers,
				"map": lobbies[user.lobbyValue].Map,
				"lobbyName": lobbies[user.lobbyValue].LobbyName
			}
			send_to_player(p, lobbyInfo)
		
		var data = {
			"message": Message.M.userConnected,
			"id": user.id,
			"host": lobbies[user.lobbyValue].HostID,
			"player": lobbies[user.lobbyValue].Players[user.id],
			"lobbyValue": user.lobbyValue,
			"map": lobbies[user.lobbyValue].Map,
			"lobbyName": lobbies[user.lobbyValue].LobbyName
		}
		send_to_player(user.id, data)
		
	##everytime someone joins or creates a lobby it updates. mnaybe this is bad for resource usage. we'll see
	for u in users:
		send_lobby_list(u)

func send_to_player(userId, data):
	##kind of bad code but i cba. makes sure that the peer exists before trying to send info to them
	##otherwise the server explodes
	if peer.get_peer(userId):
		peer.get_peer(userId).put_packet(JSON.stringify(data).to_utf8_buffer())

func generate_random_string():
	var result = ""
	for i in range(32):
		var index = randi() % Characters.length()
		result += Characters[index]
	return result

func _on_start_server_button_down() -> void:
	start_server()


func _on_send_test_packet_server_button_down() -> void:
	var message = {
		"message" : Message.M.join,
		"data": "i am the server"
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	##utf32 is probably the one ill want to use since it handles symbols
	##id need to refactor more than just this one though
	##to utf8 turns it into a bytearray, which is how we send data across the internet apparently

func _on_update_lobby_list_timer_timeout() -> void:
	##every 30 seconds update the lobby list
	send_lobby_list_to_everyone()

func send_lobby_list_to_everyone():
	for user in users:
		prints("user being sent a lobby list: ", user)
		send_lobby_list(user)
