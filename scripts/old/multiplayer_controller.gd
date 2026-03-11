extends Control

@export var address = ""
@export var port = 6921
var peer
var upnp
@onready var nameInput = $Name

func _ready() -> void:
	##bunch of signals
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		host_game()

#gets called on  the server & clients whenever someone connects
func peer_connected(id):
	print("Player Connected: " + str(id))

#gets called on  the server & clients whenever someone connects
func peer_disconnected(id):
	##when running a server the disconnect script is working very slowly and for some reason
	##players are remembered by the server so they spawn in in the sky as incumbent capsules.... hmmm.....
	print("Player Disconnected: " + str(id))
	global.players.erase(id)
	var players = get_tree().get_nodes_in_group("player")
	for i in players:
		if i.name == str(id):
			i.queue_free()

#gets fired only from clients
func connected_to_server():
	print("Connected to Server")
	send_player_info.rpc_id(1, nameInput.text, multiplayer.get_unique_id())
	#rpc_id of 1, sends it just to our server

@rpc("any_peer", "call_remote") #call_remote means it will only be executed on the remote peer, whereas call_local
#would mean it gets called on the local machine and remote peer, meaing infinite recursion in the if multiplayer.is_server() bit
func send_player_info(name, id):
	if !global.players.has(id):
		global.players[id] ={
			"displayName": name,
			"id": id,
			"goals": 0
		}
		
	if multiplayer.is_server(): #the server then sends the info to all clients
		for i in global.players:
			send_player_info.rpc(global.players[i].displayName, i)

#gets fired only from clients
func connection_failed():
	print("Connection failed")


func host_game():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 2) #max 2 players
	if error != OK:
		print("Cannot host, error number: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer) #this sets the server as one of the peers
	multiplayer.server_relay = true
	print("Waiting For Players")
	#print(multiplayer.get_multiplayer_peer())

func _on_host_button_down() -> void:
	host_game()
	send_player_info(nameInput.text, multiplayer.get_unique_id())

#
func _on_join_button_down() -> void:
	var address : String = $"Host IP (to connect to)".text
	#if not address.is_valid_ip_address():
		#OS.alert("IP address is invalid.")
		#return
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error != OK:
		print("Cannot join, error number: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer) #this sets the client as one of the peers
	#print(multiplayer.get_multiplayer_peer())

func _on_start_game_button_down() -> void:
	start_game.rpc()

@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://scenes/main level.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func _on_copy_to_clipboard_pressed() -> void:
	if $IP.text != "":
		DisplayServer.clipboard_set($IP.text)
