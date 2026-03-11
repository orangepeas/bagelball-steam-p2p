extends Control

func _ready() -> void:
	if $"Lobby Browser/Client".localServer == true:
		$testingtesting.show()
	else:
		$testingtesting.hide()
	global.backToMainMenu.connect(reset_main_menu)
	global.hideTitleImages.connect(hide_title_images)
	global.muteTitleMusic.connect(mute_title_music)
	start_main_menu()


func start_main_menu():
	$"Main Menu Music".play()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var rng = RandomNumberGenerator.new()
	var num = rng.randi_range(1,get_tree().get_nodes_in_group("thumbnail").size())
	$"space station".hide()
	$"space station2".hide()
	$"Custom Lobby Variables".hide()
	var numSpecial = rng.randi_range(1,1000)
	if numSpecial == 69:
		var num2 = rng.randi_range(1,2)
		if num2 == 1:
			$"space station".show()
		elif num2 == 2:
			$"space station2".show()
		$"Main Menu Music".stop()
		$"Bagel Atmosphere".play()
	else:
		for t in get_tree().get_nodes_in_group("thumbnail"):
			t.hide()
		for t in get_tree().get_nodes_in_group("thumbnail"):
			if t.name == "TextureRect" + str(num):
				t.show()
				print("showing: ", t.name)
	hide_all_others($Initial)
	$Initial/SingleplayerMapSelectorModal.hide()

func hide_all_others(menuOptionWeWant : Control):
	for menuOption in get_tree().get_nodes_in_group("MainMenuOption"):
		if menuOption != menuOptionWeWant:
			menuOption.hide()
	menuOptionWeWant.show()

func _on_createjoinlobby_pressed() -> void:
	hide_all_others($"Lobby Menu")

func _on_lobby_browser_pressed() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()
	#$"Lobby Browser/Client".get_lobby_list()
	#$"Lobby Browser".create_lobby_list()
	hide_all_others($"Lobby Browser")
	$testingtesting.hide()

func _on_settings_pressed() -> void:
	hide_all_others($Settings)

func _notification(what):
	##if player alt f4's or something then we quit the tree is my guess. i dont really know
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit() # default behavior

func _on_quit_game_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func mute_title_music() -> void:
	##runs when someone hits start game
	$"Main Menu Music".stop()
	$"Bagel Atmosphere".stop()

func _on_controls_pressed() -> void:
	hide_all_others($Controls)

func hide_title_images() -> void:
	for t in get_tree().get_nodes_in_group("thumbnail"):
		t.hide()
	$"space station".hide()
	$"space station2".hide()

func reset_main_menu():
	start_main_menu()
	if $"../main level":
		$"../main level".queue_free()
	self.show()
	$Settings.bug_fix() ##idk why it hides initial but it does but we fix it
	$"Lobby Browser".reset_lobby_browser()


func _on_practice_singleplayer_pressed() -> void:
	$Initial/SingleplayerMapSelectorModal.show()

#func _on_lobby_menu_get_current_game_scene() -> void:
	#send_current_game_scene_to_other_peer()
#
#@rpc("any_peer","call_local")
#func send_current_game_scene_to_other_peer():
	#global.currentGameScene = $"../main level"

func _on_sp_map_back_pressed() -> void:
	$Initial/SingleplayerMapSelectorModal.hide()


func _on_select_map_button_pressed() -> void:
	$Initial/SingleplayerMapSelectorModal.hide()
	global.singleplayer = true
	$Initial/SingleplayerMapSelectorModal/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/MapsOptions.select_map()
	global.maxPlayers = 2 ##sets spawnpoint to a 1v1 spawn point
	mute_title_music()
	hide_title_images()
	GLV.quantumBagels = true
	global.players[0] = {
		"name": name,
		"id": 0,
		"index": 0,
		"displayName": "Practice",
		"redTeam": true,
		"goals": 0,
		"spectator": false,
	}
	var scene = load("res://scenes/main level.tscn").instantiate()
	get_tree().root.add_child(scene)
	scene.start_game()
	global.practiceMode.emit()
	$"Custom Lobby Variables".set_options_singleplayer()
	self.hide() ##hides main menu


func _on_custom_lobby_variables_pressed() -> void:
	$"Custom Lobby Variables".show()
	$Initial.hide()
	$"Custom Lobby Variables".enable_clv_buttons() ##otherwise its disabled if theyve just
	##played multiplayer as the client

func _on_texture_button_pressed() -> void:
	OS.shell_open("http://discord.gg/WZUTqWG3XN")

##if it's in video settings it triggers twice since there are 2 videosettings.gd when u play the game
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			$Settings.VideoSettings._on_check_box_toggled(false)
		elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			$Settings.VideoSettings._on_check_box_toggled(true)
