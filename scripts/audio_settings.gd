extends Control

@onready var masterSlider = $"HBoxContainer/VBoxContainer/Master Volume"
@onready var musicSlider = $"HBoxContainer/VBoxContainer/Music Volume"
@onready var sfxSlider = $"HBoxContainer/VBoxContainer/SFX Volume"

var masterBus : String = "Master"
var musicBus : String = "Music"
var sfxBus : String = "SFX"

var masterBusIndex : int
var musicBusIndex : int
var sfxBusIndex : int

func _ready() -> void:
	masterBusIndex = AudioServer.get_bus_index(masterBus)
	musicBusIndex = AudioServer.get_bus_index(musicBus)
	sfxBusIndex = AudioServer.get_bus_index(sfxBus)
	
	masterSlider.value_changed.connect(on_master_value_changed)
	musicSlider.value_changed.connect(on_music_value_changed)
	sfxSlider.value_changed.connect(on_sfx_value_changed)
	
	var audio_settings = ConfigFileHandler.load_audio_settings()
	AudioServer.set_bus_volume_db(masterBusIndex, linear_to_db(audio_settings.master_volume))
	AudioServer.set_bus_volume_db(musicBusIndex, linear_to_db(audio_settings.music_volume))
	AudioServer.set_bus_volume_db(sfxBusIndex, linear_to_db(audio_settings.sfx_volume))
	
	masterSlider.value = db_to_linear(AudioServer.get_bus_volume_db(masterBusIndex))
	musicSlider.value = db_to_linear(AudioServer.get_bus_volume_db(musicBusIndex))
	sfxSlider.value = db_to_linear(AudioServer.get_bus_volume_db(sfxBusIndex))


func on_master_value_changed(value : float):
	AudioServer.set_bus_volume_db(masterBusIndex, linear_to_db(value))

func on_music_value_changed(value : float):
	AudioServer.set_bus_volume_db(musicBusIndex, linear_to_db(value))

func on_sfx_value_changed(value : float):
	AudioServer.set_bus_volume_db(sfxBusIndex, linear_to_db(value))

##stops it saving on every frame
func _on_master_volume_drag_ended(value_changed: bool) -> void:
	if value_changed:
		ConfigFileHandler.save_audio_setting("master_volume", masterSlider.value)

func _on_music_volume_drag_ended(value_changed: bool) -> void:
	if value_changed:
		ConfigFileHandler.save_audio_setting("music_volume", musicSlider.value)

func _on_sfx_volume_drag_ended(value_changed: bool) -> void:
	if value_changed:
		ConfigFileHandler.save_audio_setting("sfx_volume", sfxSlider.value)
