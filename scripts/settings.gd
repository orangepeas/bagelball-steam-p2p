extends Control

@onready var Intitial = $Initial
@onready var AudioSettings = $"Audio Settings"
@onready var VideoSettings = $"Video Settings"
@onready var sensSlider = $Initial/HBoxContainer/VBoxContainer/HBoxContainer/MarginContainer2/SensSlider
@onready var sensDisplay = $Initial/HBoxContainer/VBoxContainer/HBoxContainer/MarginContainer/SensDisplay

func _ready() -> void:
	hide_all_others($Initial)
	global.sensitivity = ConfigFileHandler.load_sensitivity()/10
	sensDisplay.text = str(global.sensitivity*1000)
	sensSlider.value = global.sensitivity*10

func bug_fix():
	hide_all_others($Initial)

func hide_all_others(menuOptionWeWant : Control):
	for menuOption in get_tree().get_nodes_in_group("SettingsMenuOption"):
		if menuOption != menuOptionWeWant:
			menuOption.hide()
	menuOptionWeWant.show()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit() # default behavior

func _on_video_settings_pressed() -> void:
	hide_all_others(VideoSettings)

func _on_audio_settings_pressed() -> void:
	hide_all_others(AudioSettings)

func _on_back_pressed() -> void:
	hide_all_others(Intitial)
	#$Initial.show()

func _on_full_back_pressed() -> void:
	$"..".hide_all_others($"../Initial")

func _on_sens_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		ConfigFileHandler.save_sensitivity("sensitivity", sensSlider.value)
		global.sensitivity = sensSlider.value/10 ##cant be the actual value cos the slider shits itself
		global.sensChange.emit()
		#sensDisplay.text = str(global.sensitivity*1000)

func _on_sens_slider_value_changed(value: float) -> void:
	sensDisplay.text = str(value*100)
