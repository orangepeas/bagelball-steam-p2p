extends Control

var i = 0
signal playerDestroyed

func _ready() -> void:
	hide_all_others($Initial)

func hide_all_others(menuOptionWeWant : Control):
	for menuOption in get_tree().get_nodes_in_group("PauseMenuOption"):
		if menuOption != menuOptionWeWant:
			menuOption.hide()
	menuOptionWeWant.show()

func _on_resume_game_pressed() -> void:
	if $"../..".mpSync.get_multiplayer_authority() == multiplayer.get_unique_id() or global.singleplayer == true:
		unpause_game()
		global.isPaused = !global.isPaused

func _notification(what):
	##if player alt f4's or something then we quit the tree is my guess. i dont really know
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		destroy_player.rpc(multiplayer.get_unique_id()) ##so if they alt f4 theres no funny behaviour
		global.pauseScreenLeaveLobby.emit()
		get_tree().quit() # default behavior

func _on_quit_game_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _on_settings_pressed() -> void:
	hide_all_others($Settings)
	$Settings.hide_all_others($Settings/Initial)

func _unhandled_input(_event: InputEvent) -> void:
	if $"../..".mpSync.get_multiplayer_authority() == multiplayer.get_unique_id() or global.singleplayer == true:
		if Input.is_action_just_pressed("pause"):
			if global.isPaused == false:
				pause_game()
			elif global.isPaused == true:
				unpause_game()
			global.isPaused = !global.isPaused

func pause_game() -> void:
	$"../MarginContainer/Cursor".hide()
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hide_all_others($Initial)
	self.show()

func unpause_game() -> void:
	$"../MarginContainer/Cursor".show()
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	self.hide()

func _on_controls_pressed() -> void:
	hide_all_others($Controls)

@rpc("any_peer","call_local")
func destroy_player(disconnectedId : int):
	for player in get_tree().get_nodes_in_group("player"):
		if player.name == str(disconnectedId):
			##if we queue_free godot's multiplayersync shits itself so i just hide them
			##and put them at the top of the map lol
			player.hide()
			player.global_position = Vector3(0,350,0) ##DisconnectedSpot in main level model
	
	##maybe could have it share the same group but scared to test
	for player in get_tree().get_nodes_in_group("spectatorPlayer"):
		if player.name == str(disconnectedId):
			##if we queue_free godot's multiplayersync shits itself so i just hide them
			##and put them at the top of the map lol
			player.hide()
			player.global_position = Vector3(0,350,0) ##DisconnectedSpot in main level model

func _on_leave_lobby_pressed() -> void:
	if global.singleplayer == false:
		destroy_player.rpc(multiplayer.get_unique_id())
		global.pauseScreenLeaveLobby.emit()
	elif global.singleplayer == true:
		global.singleplayer = false
	global.backToMainMenu.emit()

func _on_debug_timer_timeout() -> void:
	#print("**************",i,"**************")
	#print(
	#"is_visible_in_tree: ", self.is_visible_in_tree(),
	#", visible: ", self.visible,
	#", parent: ", self.get_parent().get_parent()
	#)
	#i+=1
	pass
