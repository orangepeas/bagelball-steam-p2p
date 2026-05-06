extends Control

@onready var lobbyScene = preload("res://scenes/lobby individual.tscn")
@onready var lobbyList = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/LobbyList

func _ready():
	$Client.receivedLobbyList.connect(create_lobby_list)
	for oldLobby in lobbyList.get_children():
		oldLobby.queue_free()
	reset_lobby_browser()

func reset_lobby_browser():
	$"Create Lobby".hide()
	$"Join Private Lobby".hide()
	$"Lobby Menu V2".hide()
	enable_buttons()
	$PanelContainer.show()


func create_lobby_list():
	#prints("creating lobby list", global.lobbies)
	for oldLobby in lobbyList.get_children():
		oldLobby.queue_free()
	
	if !global.lobbies.values()[0].lobbyId == ("null"):
		for lobbyId in global.lobbies:
			if global.lobbies[lobbyId].privateLobby == 0:
				var lobbyDisplay = lobbyScene.instantiate()
				lobbyDisplay.lobbyId = lobbyId
				var lobbyName = lobbyDisplay.find_child("LabelLobbyName")
				var joinLobbyButton = lobbyDisplay.find_child("JoinLobbyButton")
				var currentPlayers = lobbyDisplay.find_child("CurrentPlayerDisplay")
				if global.lobbies[lobbyId].gameHasStarted == true:
					joinLobbyButton.disabled = true
				#if lobbyId.length() > 25:
					#lobbyName.text = str(lobbyId).left(25) + "..."
				#else:
					#lobbyName.text = lobbyId
				lobbyName.text = global.lobbies[lobbyId].lobbyName
				currentPlayers.text = (str(int(global.lobbies[lobbyId].currentPlayers)) + "/" + str((int(global.lobbies[lobbyId].maxPlayers))))
				lobbyList.add_child(lobbyDisplay)
				if global.currentLobby == lobbyId:
					joinLobbyButton.disabled = true

func hide_all_others(menuOptionWeWant : Control):
	for menuOption in get_tree().get_nodes_in_group("SettingsMenuOption"):
		if menuOption != menuOptionWeWant:
			menuOption.hide()
	menuOptionWeWant.show()

func _on_refresh_lobby_pressed() -> void:
	$Client.get_lobby_list()
	##the client emits received lobby list which runs create_lobby_list once we got the lobby list

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
