extends Control

func _ready() -> void:
	##intialising settings
	var video_settings = ConfigFileHandler.load_video_settings()
	$HBoxContainer/VBoxContainer/fullscreen/CheckBox.button_pressed = video_settings.fullscreen
	match video_settings.resolution:
		"1920x1080":
			DisplayServer.window_set_size(Vector2i(1920,1080))
		"1600x900":
			DisplayServer.window_set_size(Vector2i(1600,900))
		"1280x720":
			DisplayServer.window_set_size(Vector2i(1280,720))
		"960x540":
			DisplayServer.window_set_size(Vector2i(960,540))
	if video_settings.has("fov"):
		$HBoxContainer/VBoxContainer/fov/MarginContainer/HSlider.value = video_settings.fov
		$HBoxContainer/VBoxContainer/fov/fovlabel.text = "FOV: " + str(int(video_settings.fov))
		global.FOV = int(video_settings.fov)

func _on_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		$HBoxContainer/VBoxContainer/resolution/Resolutions.disabled = true
	elif !toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		$HBoxContainer/VBoxContainer/resolution/Resolutions.disabled = false
	ConfigFileHandler.save_video_setting("fullscreen", toggled_on)

func _on_resolutions_item_selected(index: int) -> void:
	match index:
		0: 
			DisplayServer.window_set_size(Vector2i(1920,1080))
			ConfigFileHandler.save_video_setting("resolution", "1920x1080")
		1:
			DisplayServer.window_set_size(Vector2i(1600,900))
			ConfigFileHandler.save_video_setting("resolution", "1600x900")
		2:
			DisplayServer.window_set_size(Vector2i(1280,720))
			ConfigFileHandler.save_video_setting("resolution", "1280x720")
		3:
			DisplayServer.window_set_size(Vector2i(960,540))
			ConfigFileHandler.save_video_setting("resolution", "960x540")

func _on_h_slider_value_changed(value: float) -> void:
	#print(value)
	$HBoxContainer/VBoxContainer/fov/fovlabel.text = "FOV: " + str(int(value))

func _on_h_slider_drag_ended(value_changed: bool) -> void:
	ConfigFileHandler.save_video_setting("fov", $HBoxContainer/VBoxContainer/fov/MarginContainer/HSlider.value)
	global.FOV = $HBoxContainer/VBoxContainer/fov/MarginContainer/HSlider.value
	global.fovChange.emit()
