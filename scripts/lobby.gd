extends RefCounted ##even more basic object than a node apparently
class_name Lobby

var HostID : int
var Players : Dictionary = {}
var GameHasStarted : bool
var MaxPlayers : int
var LobbyName : String
var PrivateLobby : int
var Map

func _init(id):
	HostID = id

func AddPlayer(id, name):
	##this creates an entry in the dictionary of players, with the entry being a dictionary named the id containing the 5 things in the dictionary there
	Players[id] = {
		"name": name,
		"id": id,
		"index": Players.size() + 1,
		"displayName": name,
		"goals": 0,
		"spectator": false,
		"redTeam": false
	}
	return Players[id]
