extends Control

@onready var mapSelector = $Initial/SingleplayerMapSelectorModal/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/MapsOptions
@onready var testingtesting = $testingtesting
@onready var client = $"Lobby Browser/Client"
@onready var mainMenuMusic = $"Main Menu Music"
@onready var spaceStation = $"space station"
@onready var spaceStation2 = $"space station2"
@onready var customLobbyVariables = $"Custom Lobby Variables"
@onready var bagelAtmosphere = $"Bagel Atmosphere"
@onready var initialMenu = $Initial
@onready var mapSelectorSingleplayer = $Initial/SingleplayerMapSelectorModal
@onready var lobbyBrowser = $"Lobby Browser"
@onready var settingsMenu = $Settings
@onready var controlsMenu = $Controls
@onready var thumbnails = $Thumbnails
@onready var characterCreatorScene = preload("res://scenes/character creator.tscn")
var characterCreator
var currentThumbnail

func _ready() -> void:
	if client.localServer == true:
		testingtesting.show()
	else:
		testingtesting.hide()
	global.backToMainMenu.connect(reset_main_menu)
	global.hideTitleImages.connect(hide_title_images)
	global.muteTitleMusic.connect(mute_title_music)
	global.deleteCharacterCreator.connect(character_creator_queue_free)
	start_main_menu()

func character_creator_queue_free():
	characterCreator.queue_free()

func start_main_menu():
	characterCreator = characterCreatorScene.instantiate()
	add_child(characterCreator)
	characterCreator.connect("show_main_menu", _on_character_creator_show_main_menu)
	mainMenuMusic.play()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var rng = RandomNumberGenerator.new()
	var num = rng.randi_range(1,get_tree().get_nodes_in_group("thumbnail").size())
	spaceStation.hide()
	spaceStation2.hide()
	customLobbyVariables.hide()
	var numSpecial = rng.randi_range(1,1000)
	if numSpecial == 7:
		var num2 = rng.randi_range(1,2)
		if num2 == 1:
			spaceStation.show()
			currentThumbnail = spaceStation
		elif num2 == 2:
			spaceStation2.show()
			currentThumbnail = spaceStation2
		mainMenuMusic.stop()
		bagelAtmosphere.play()
	else:
		for t in get_tree().get_nodes_in_group("thumbnail"):
			t.hide()
		for t in get_tree().get_nodes_in_group("thumbnail"):
			if t.name == "TextureRect" + str(num):
				t.show()
				print("showing: ", t.name)
				currentThumbnail = t
	hide_all_others(initialMenu)
	mapSelectorSingleplayer.hide()

func hide_all_others(menuOptionWeWant : Control):
	for menuOption in get_tree().get_nodes_in_group("MainMenuOption"):
		if menuOption != menuOptionWeWant:
			menuOption.hide()
	menuOptionWeWant.show()

func _on_lobby_browser_pressed() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()
	#$"Lobby Browser/Client".get_lobby_list()
	#$"Lobby Browser".create_lobby_list()
	hide_all_others(lobbyBrowser)
	testingtesting.hide()

func _on_settings_pressed() -> void:
	hide_all_others(settingsMenu)

func _notification(what):
	##if player alt f4's or something then we quit the tree is my guess. i dont really know
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit() # default behavior

func _on_quit_game_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func mute_title_music() -> void:
	##runs when someone hits start game
	mainMenuMusic.stop()
	bagelAtmosphere.stop()

func _on_controls_pressed() -> void:
	hide_all_others(controlsMenu)

func hide_title_images() -> void:
	for t in get_tree().get_nodes_in_group("thumbnail"):
		t.hide()
	spaceStation.hide()
	spaceStation2.hide()

func reset_main_menu():
	start_main_menu()
	if $"../main level":
		$"../main level".queue_free()
	self.show()
	settingsMenu.bug_fix() ##idk why it hides initial but it does but we fix it
	lobbyBrowser.reset_lobby_browser()


func _on_practice_singleplayer_pressed() -> void:
	mapSelectorSingleplayer.show()

func _on_sp_map_back_pressed() -> void:
	mapSelectorSingleplayer.hide()

func _on_select_map_button_pressed() -> void:
	mapSelectorSingleplayer.hide()
	global.singleplayer = true
	mapSelector.select_map()
	global.maxPlayers = 2 ##sets spawnpoint to a 1v1 spawn point
	mute_title_music()
	hide_title_images()
	GLV.quantumBagels = true
	global.players[0] = {
		"steam_id": Steam.getSteamID(),
		"name": name,
		"multiplayer_id": 0,
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
	customLobbyVariables.set_options_singleplayer()
	self.hide() ##hides main menu

func _on_custom_lobby_variables_pressed() -> void:
	customLobbyVariables.show()
	initialMenu.hide()
	customLobbyVariables.enable_clv_buttons() ##otherwise its disabled if theyve just
	##played multiplayer as the client

func _on_texture_button_pressed() -> void:
	OS.shell_open("http://discord.gg/WZUTqWG3XN")

##if it's in video settings it triggers twice since there are 2 videosettings.gd when u play the game
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			settingsMenu.VideoSettings._on_check_box_toggled(false)
		elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			settingsMenu.VideoSettings._on_check_box_toggled(true)

func _on_character_creator_pressed() -> void:
	initialMenu.hide()
	thumbnails.hide()
	if !characterCreator.music.playing:
		characterCreator.music.play()
	else:
		characterCreator.music.volume_db = -10
		characterCreator.music.pitch_scale += 0.01
	mute_title_music()
	characterCreator.show_all_ui()

func _on_character_creator_show_main_menu() -> void:
	initialMenu.show()
	thumbnails.show()
	mainMenuMusic.play()
	
