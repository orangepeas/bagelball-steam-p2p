extends Control

##from https://www.youtube.com/watch?v=ZDPM45cHHlI

@onready var inputButtonScene = preload("res://scenes/input_button.tscn")
@onready var actionList = $InputMap/MarginContainer/VBoxContainer/ScrollContainer/ActionList
@onready var autoSprintCheckbox = $Initial/VBoxContainer/HBoxContainer2/AutoSprintCheckbox
@onready var holdOrToggle = $Initial/VBoxContainer/HBoxContainer/HoldOrToggle

var isRemappingPrimary = false
var isRemappingSecondary = false
var actionToRemap = null
var remappingButton = null

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
	$InputMap.hide()
	load_keybindings_from_settings()
	create_action_list()
	load_controls_settings()
	self.show()

func load_keybindings_from_settings():
	var keybindingsPrimary = ConfigFileHandler.load_keybindings()[0]
	var keybindingsSecondary = ConfigFileHandler.load_keybindings()[1]
	for action in keybindingsPrimary.keys():
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, keybindingsPrimary[action])
	for action in keybindingsSecondary.keys():
		InputMap.action_add_event(action, keybindingsSecondary[action])

func load_controls_settings():
	var controls_settings = ConfigFileHandler.load_controls_settings()
	if controls_settings.auto_sprint == "true":
		autoSprintCheckbox.button_pressed = true
	else:
		autoSprintCheckbox.button_pressed = false
	if controls_settings.hold_sprint == "true":
		holdOrToggle.selected = 0
		global.holdSprint = true
	else:
		holdOrToggle.selected = 1
		global.holdSprint = false

func create_action_list():
	for item in actionList.get_children():
		item.queue_free()

	#InputMap.load_from_project_settings()
	for action in inputActions:
		var button = inputButtonScene.instantiate()
		actionList.add_child(button)
		button.actionLabel.text = inputActions[action]
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			button.inputLabel.text = events[0].as_text().trim_suffix(" (Physical)")
			if events.size() > 1:
				button.inputLabel2.text = events[1].as_text().trim_suffix(" (Physical)")
				if events[1].as_text().trim_suffix(" (Physical)") == "(Unset)":
					button.inputLabel2.text = "     "
			else:
				button.inputLabel2.text = "     "
		else:
			button.inputLabel.text = "     "
		
		button.primaryInputRebind.connect(primary_input_button_pressed.bind(button.primaryButton, action))
		button.secondaryInputRebind.connect(secondary_input_button_pressed.bind(button.secondaryButton, action))
		#button.pressed.connect(input_button_pressed.bind(button,action))

##this doesnt work im just going to give up. the rest of it works
func check_other_events_for_same_input(inputToCheck, actionToNotCheck):
	for action in inputActions:
		var events = InputMap.action_get_events(action)
		for e in events:
			##we need to check the keycode/button_index since the key we just pressed has a bool
			##named pressed and it is on for inputToCheck and off for the event associated with the
			##action
			if action != actionToNotCheck:
				##THIS SHIT DONT WORK WHY
				if e is InputEventMouseButton && inputToCheck == InputEventMouseButton:
					if e.button_index == inputToCheck.button_index:
						erase_action(e,action)
				elif e is InputEventKey && inputToCheck == InputEventKey:
					if e.keycode == inputToCheck.keycode:
						erase_action(e,action)

func erase_action(event, action):
	InputMap.action_erase_event(action, event)
	for button in actionList.get_children():
		if button.actionLabel.text == inputActions[action]:
			update_action_list(button, event)

func primary_input_button_pressed(button, action):
	##i think remapping button needs to be changed
	if !isRemappingPrimary:
		isRemappingPrimary = true
		actionToRemap = action
		remappingButton = button
		button.text = "Press key to bind..."

func secondary_input_button_pressed(button, action):
	if !isRemappingSecondary:
		isRemappingSecondary = true
		actionToRemap = action
		remappingButton = button
		button.text = "Press key to bind..."

func _input(event: InputEvent) -> void:
	if isRemappingPrimary:
		if (
			event is InputEventKey or
			event is InputEventMouseButton && event.pressed
		):
			##turn double click into single click cos u can bind to double click
			if event is InputEventMouseButton && event.double_click:
				event.double_click = false
				
			var eventsOld = InputMap.action_get_events(actionToRemap) ##so we dont delete secondary actions & retain order
			InputMap.action_erase_events(actionToRemap) ##clears previous actions
			InputMap.action_add_event(actionToRemap, event)
			ConfigFileHandler.save_keybinding_primary(actionToRemap, event)
			if eventsOld.size() > 1:
				InputMap.action_add_event(actionToRemap, eventsOld[0]) ##replace secondary actions
				ConfigFileHandler.save_keybinding_primary(actionToRemap, event)
			check_other_events_for_same_input(event, actionToRemap)
			update_action_list(remappingButton, event)
			#create_action_list()
			#for button in actionList.get_children():
				#update_action_list(button, )
			isRemappingPrimary = false
			actionToRemap = null
			remappingButton = null
			
			##cant be arsed to implement this
			
			accept_event() ##stops event from propagating further up the tree, e.g. if you rebind something to esc
			##its not going to just leave the menu
			
	if isRemappingSecondary:
		if (
			event is InputEventKey or
			event is InputEventMouseButton && event.pressed
		):
			if event is InputEventMouseButton && event.double_click:
				event.double_click = false
				
			var eventsOld = InputMap.action_get_events(actionToRemap)
			InputMap.action_erase_events(actionToRemap) ##clears previous action
			InputMap.action_add_event(actionToRemap, eventsOld[0]) ##replaces primary action
			InputMap.action_add_event(actionToRemap, event)
			ConfigFileHandler.save_keybinding_secondary(actionToRemap, event)
			if eventsOld.size() > 1:
				InputMap.action_add_event(actionToRemap, eventsOld[0]) ##replace secondary actions
				ConfigFileHandler.save_keybinding_secondary(actionToRemap, event)
			check_other_events_for_same_input(event, actionToRemap)
			update_action_list(remappingButton, event)
			
			isRemappingSecondary = false
			actionToRemap = null
			remappingButton = null
			
			accept_event()

func update_action_list(button, event):
	button.text = event.as_text().trim_suffix(" (Physical)")

func hide_all_others(menuOptionWeWant : Control):
	for menuOption in get_tree().get_nodes_in_group("SettingsMenuOption"):
		if menuOption != menuOptionWeWant:
			menuOption.hide()
	menuOptionWeWant.show()

func _on_back_pressed() -> void:
	$"..".hide_all_others($"../Initial")

func _on_reset_button_pressed() -> void:
	InputMap.load_from_project_settings()
	for action in inputActions:
		var events = InputMap.action_get_events(action)
		if events.size() == 2:
			ConfigFileHandler.save_keybinding_primary(action, events[0])
			ConfigFileHandler.save_keybinding_secondary(action, events[1])
		elif events.size() == 1:
			ConfigFileHandler.save_keybinding_primary(action, events[0])
			ConfigFileHandler.save_keybinding_secondary(action, InputEventKey.new())

	create_action_list()

func _on_hold_or_toggle_item_selected(index: int) -> void:
	if index == 0:
		global.holdSprint = true
		ConfigFileHandler.save_controls_setting("hold_sprint", "true")
	elif index == 1:
		global.holdSprint = false
		ConfigFileHandler.save_controls_setting("hold_sprint", "false")

func _on_auto_sprint_checkbox_toggled(toggled_on: bool) -> void:
	if toggled_on:
		global.autoSprint = true
		ConfigFileHandler.save_controls_setting("auto_sprint", "true")
	elif !toggled_on:
		global.autoSprint = false
		ConfigFileHandler.save_controls_setting("auto_sprint", "false")


func _on_input_map_button_pressed() -> void:
	$InputMap.show()
	$Initial.hide()

func _on_input_map_back_pressed() -> void:
	$InputMap.hide()
	$Initial.show()
