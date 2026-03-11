extends Node

##from https://youtu.be/tfqJjDw0o7Y

var config = ConfigFile.new()
const SETTINGS_FILE_PATH = "user://settings.ini" ##in %appdata%

var inputActions = {
	"raycast_bagel": "Pickup/Drop Bagel",
	"quantum_bagel_switch": "Quantum Bagel Switch",
	"forward": "Move Forward",
	"left": "Move Left",
	"back": "Move Back",
	"right": "Move Right",
	"jump": "Jump",
	"sprint": "Sprint",
	"close_bagel": "Close Bagel",
	"far_bagel": "Far Bagel",
	"fastfall": "Fast Fall",
	"scoreboard": "Scoreboard",
	"insult_selector": "Insult Selector",
	"fullscreen": "Toggle Fullscreen",
}

func _ready():
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.set_value("keybinding_primary", "raycast_bagel", "mouse_1")
		config.set_value("keybinding_primary", "quantum_bagel_switch", "mouse_2")
		config.set_value("keybinding_primary", "forward", "W")
		config.set_value("keybinding_primary", "left", "A")
		config.set_value("keybinding_primary", "back", "S")
		config.set_value("keybinding_primary", "right", "D")
		config.set_value("keybinding_primary", "jump", "space")
		config.set_value("keybinding_primary", "sprint", "shift")
		config.set_value("keybinding_primary", "close_bagel", "mouse_5")
		config.set_value("keybinding_primary", "far_bagel", "mouse_4")
		config.set_value("keybinding_primary", "fastfall", "ctrl")
		config.set_value("keybinding_primary", "scoreboard", "tab")
		config.set_value("keybinding_primary", "insult_selector", "c")
		config.set_value("keybinding_primary", "fullscreen", "f11")

		config.set_value("keybinding_secondary", "raycast_bagel", "")
		config.set_value("keybinding_secondary", "quantum_bagel_switch", "")
		config.set_value("keybinding_secondary", "forward", "")
		config.set_value("keybinding_secondary", "left", "")
		config.set_value("keybinding_secondary", "back", "")
		config.set_value("keybinding_secondary", "right", "")
		config.set_value("keybinding_secondary", "jump", "")
		config.set_value("keybinding_secondary", "sprint", "")
		config.set_value("keybinding_secondary", "close_bagel", "q")
		config.set_value("keybinding_secondary", "far_bagel", "e")
		config.set_value("keybinding_secondary", "fastfall", "")
		config.set_value("keybinding_secondary", "scoreboard", "")
		config.set_value("keybinding_secondary", "insult_selector", "")
		config.set_value("keybinding_secondary", "fullscreen", "")

		config.set_value("video", "fullscreen", false)
		config.set_value("video", "resolution", "960x540")
		
		config.set_value("audio", "master_volume", 1.0)
		config.set_value("audio", "music_volume", 1.0)
		config.set_value("audio", "sfx_volume", 1.0)
		
		config.set_value("sensitivity", "sensitivity", 0.03) ##*10 from default value cos the slider doesnt like it if i dont
		config.set_value("controls", "auto_sprint", "false")
		config.set_value("controls", "hold_sprint", "true")
		
		config.save(SETTINGS_FILE_PATH)
	else:
		config.load(SETTINGS_FILE_PATH)
	
	if config.has_section("keybinding"):
		for key in config.get_section_keys("keybinding"):
			var tempKeybindingStorage = config.get_value("keybinding", key)
			config.erase_section_key("keybinding", key)
			config.set_value("keybinding_primary", key, tempKeybindingStorage)
			config.set_value("keybinding_secondary", key, "")
		config.set_value("controls", "auto_sprint", "false")
		config.set_value("controls", "hold_sprint", "true")
		config.save(SETTINGS_FILE_PATH)
		
	if config.get_value("keybinding_primary","scoreboard", "boobs") == "boobs":
		config.set_value("keybinding_primary", "scoreboard", "tab")
		config.set_value("keybinding_primary", "insult_selector", "c")
		config.set_value("keybinding_primary", "fullscreen", "f11")
		config.set_value("keybinding_secondary", "scoreboard", "")
		config.set_value("keybinding_secondary", "insult_selector", "")
		config.set_value("keybinding_secondary", "fullscreen", "")
		config.save(SETTINGS_FILE_PATH)

func save_video_setting(key : String, value):
	config.set_value("video", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_video_settings():
	var video_settings = {}
	for key in config.get_section_keys("video"):
		video_settings[key] = config.get_value("video", key)
	return video_settings

func save_controls_setting(key : String, value):
	config.set_value("controls", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_controls_settings():
	var controls_settings = {}
	for key in config.get_section_keys("controls"):
		controls_settings[key] = config.get_value("controls", key)
	return controls_settings

func save_sensitivity(key : String, value):
	config.set_value("sensitivity", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_sensitivity():
	return config.get_value("sensitivity", "sensitivity")

func save_audio_setting(key : String, value):
	config.set_value("audio", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_audio_settings():
	var audio_settings = {}
	for key in config.get_section_keys("audio"):
		audio_settings[key] = config.get_value("audio", key)
	return audio_settings

func save_keybinding_primary(action: StringName, event: InputEvent):
	var event_str
	if event is InputEventKey:
		event_str = OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventMouseButton:
		event_str = "mouse_" + str(event.button_index)
	config.set_value("keybinding_primary", action, event_str)
	config.save(SETTINGS_FILE_PATH)

func save_keybinding_secondary(action: StringName, event: InputEvent):
	var event_str
	if event is InputEventKey:
		event_str = OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventMouseButton:
		event_str = "mouse_" + str(event.button_index)
	config.set_value("keybinding_secondary", action, event_str)
	config.save(SETTINGS_FILE_PATH)

func load_keybindings():
	var keybindingsPrimary = {}
	var keybindingsSecondary = {}
	var keysPrimary = config.get_section_keys("keybinding_primary")
	for key in keysPrimary:
		var input_event
		var event_str = config.get_value("keybinding_primary", key)
		
		if event_str.contains("mouse_"):
			input_event = InputEventMouseButton.new()
			input_event.button_index = int(event_str.split("_")[1])
		else:
			input_event = InputEventKey.new()
			input_event.keycode = OS.find_keycode_from_string(event_str)
		
		keybindingsPrimary[key] = input_event
	var keysSecondary = config.get_section_keys("keybinding_secondary")
	for key in keysSecondary:
		var input_event
		var event_str = config.get_value("keybinding_secondary", key)
		
		if event_str.contains("mouse_"):
			input_event = InputEventMouseButton.new()
			input_event.button_index = int(event_str.split("_")[1])
		else:
			input_event = InputEventKey.new()
			input_event.keycode = OS.find_keycode_from_string(event_str)
		
		keybindingsSecondary[key] = input_event
	var keybindings = [keybindingsPrimary,keybindingsSecondary]
	return keybindings
