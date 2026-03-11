extends Control

@export var practiceMode : bool
@onready var general = $PanelContainer/MarginContainer/VBoxContainer/General/hbox
@onready var ball = $PanelContainer/MarginContainer/VBoxContainer/Ball/hbox
@onready var bagel = $PanelContainer/MarginContainer/VBoxContainer/Bagel/hbox2
@onready var bagel2 = $PanelContainer/MarginContainer/VBoxContainer/Bagel/hbox3
@onready var player = $PanelContainer/MarginContainer/VBoxContainer/Player/hbox3
@onready var player2 = $PanelContainer/MarginContainer/VBoxContainer/Player/hbox4
@onready var player3 = $PanelContainer/MarginContainer/VBoxContainer/Player/hbox5
var config = ConfigFile.new()
const FIRST_HALF_FILE_PATH = "user://lobby_variables" ##in %appdata%
#var newLobbyPreset = FIRST_HALF_FILE_PATH + whichever number preset we are on + ".ini"

var defaultGeneralOptions = {
	GLV.generalOptions.keys()[GLV.generalOptions.Gravity]: "40",
	GLV.generalOptions.keys()[GLV.generalOptions.Match_Length]: "300",
	GLV.generalOptions.keys()[GLV.generalOptions.Engine_Timescale]: "1.0",
	GLV.generalOptions.keys()[GLV.generalOptions.Map_Scale]: "1.0"
}

var defaultBallOptions = {
	GLV.ballOptions.keys()[GLV.ballOptions.Size_Scale]: "1.0",
	GLV.ballOptions.keys()[GLV.ballOptions.Bounciness]: "0.3",
	GLV.ballOptions.keys()[GLV.ballOptions.Weight]: "4.2",
	GLV.ballOptions.keys()[GLV.ballOptions.Friction]: "1.0",
}

var defaultBagelOptions = {
	GLV.bagelOptions.keys()[GLV.bagelOptions.Size_Scale]: "1.0",
	GLV.bagelOptions.keys()[GLV.bagelOptions.Bounciness]: "0.3",
	GLV.bagelOptions.keys()[GLV.bagelOptions.Weight_When_Held]: "0.8",
	GLV.bagelOptions.keys()[GLV.bagelOptions.Weight_When_Not_Held]: "15",
	GLV.bagelOptions.keys()[GLV.bagelOptions.Friction]: "1.0",
}

var defaultPlayerOptions = {
	GLV.playerOptions.keys()[GLV.playerOptions.Normal_Speed]: "60",
	GLV.playerOptions.keys()[GLV.playerOptions.Sprint_Speed]: "90",
	GLV.playerOptions.keys()[GLV.playerOptions.Max_Speed]: "150",
	GLV.playerOptions.keys()[GLV.playerOptions.Jump_Velocity]: "45",
	GLV.playerOptions.keys()[GLV.playerOptions.Wall_Jump_Velocity]: "120",
	GLV.playerOptions.keys()[GLV.playerOptions.Air_Acceleration]: "10",
	GLV.playerOptions.keys()[GLV.playerOptions.Floor_Deceleration]: "5",
	GLV.playerOptions.keys()[GLV.playerOptions.Size_Scale]: "1",
	GLV.playerOptions.keys()[GLV.playerOptions.Jumps]: "2",
}

func set_options():
	if multiplayer.get_unique_id() == global.lobbyHostID:
		for clv in general.get_children():
			if clv.is_in_group("CLVGeneral"):
				clv.broadcast_value.rpc(clv.variable.value)
				
		for clv in ball.get_children():
			if clv.is_in_group("CLVBall"):
				clv.broadcast_value.rpc(clv.variable.value)
				
		for clv in bagel.get_children():
			if clv.is_in_group("CLVBagel"):
				clv.broadcast_value.rpc(clv.variable.value)
		for clv in bagel2.get_children():
			if clv.is_in_group("CLVBagel"):
				clv.broadcast_value.rpc(clv.variable.value)
				
		for clv in player.get_children():
			if clv.is_in_group("CLVPlayer"):
				clv.broadcast_value.rpc(clv.variable.value)
		for clv in player2.get_children():
			if clv.is_in_group("CLVPlayer"):
				clv.broadcast_value.rpc(clv.variable.value)
		for clv in player3.get_children():
			if clv.is_in_group("CLVPlayer"):
				clv.broadcast_value.rpc(clv.variable.value)

func set_options_singleplayer():
	if multiplayer.get_unique_id() == global.lobbyHostID:
		for clv in general.get_children():
			if clv.is_in_group("CLVGeneral"):
				clv.broadcast_value.rpc(clv.variable.value)
				
		for clv in ball.get_children():
			if clv.is_in_group("CLVBall"):
				clv.broadcast_value.rpc(clv.variable.value)
				
		for clv in bagel.get_children():
			if clv.is_in_group("CLVBagel"):
				clv.broadcast_value.rpc(clv.variable.value)
		for clv in bagel2.get_children():
			if clv.is_in_group("CLVBagel"):
				clv.broadcast_value.rpc(clv.variable.value)
				
		for clv in player.get_children():
			if clv.is_in_group("CLVPlayer"):
				clv.broadcast_value.rpc(clv.variable.value)
		for clv in player2.get_children():
			if clv.is_in_group("CLVPlayer"):
				clv.broadcast_value.rpc(clv.variable.value)
		for clv in player3.get_children():
			if clv.is_in_group("CLVPlayer"):
				clv.broadcast_value.rpc(clv.variable.value)

func _on_back_pressed() -> void:
	if practiceMode == false:
		$"../MarginContainer/PanelContainer".show()
	elif practiceMode == true:
		$"../Initial".show()
	self.hide()

func _on_lobby_menu_v_2_can_start_game() -> void:
	set_options()


func enable_clv_buttons() -> void:
	for variable in get_tree().get_nodes_in_group("CLV"):
		if variable.find_child("VariableNum"):
			variable.find_child("VariableNum").editable = true
		elif variable.find_child("VariableCheckbox"):
			variable.find_child("VariableCheckbox").disabled = false
	$"PanelContainer/MarginContainer/save load & reset/Reset to Default".disabled = false
	$"PanelContainer/MarginContainer/save load & reset/Load".disabled = false
	$"PanelContainer/MarginContainer/save load & reset/Save".disabled = false

func disable_clv_buttons() -> void:
	for variable in get_tree().get_nodes_in_group("CLV"):
		if variable.find_child("VariableNum"):
			variable.find_child("VariableNum").editable = false
		elif variable.find_child("VariableCheckbox"):
			variable.find_child("VariableCheckbox").disabled = true
	$"PanelContainer/MarginContainer/save load & reset/Reset to Default".disabled = true
	$"PanelContainer/MarginContainer/save load & reset/Load".disabled = true
	$"PanelContainer/MarginContainer/save load & reset/Save".disabled = false

func _on_reset_to_default_pressed() -> void:
	for clvGen in get_tree().get_nodes_in_group("CLVGeneral"):
		for defaultKey in defaultGeneralOptions:
			if GLV.generalOptions.keys()[clvGen.variable.option] == defaultKey:
				clvGen.broadcast_value(float(defaultGeneralOptions[defaultKey]))
	for clvBall in get_tree().get_nodes_in_group("CLVBall"):
		for defaultKey in defaultBallOptions:
			if GLV.ballOptions.keys()[clvBall.variable.option] == defaultKey:
				clvBall.broadcast_value(float(defaultBallOptions[defaultKey]))
	for clvBagel in get_tree().get_nodes_in_group("CLVBagel"):
		for defaultKey in defaultBagelOptions:
			if GLV.bagelOptions.keys()[clvBagel.variable.option] == defaultKey:
				clvBagel.broadcast_value(float(defaultBagelOptions[defaultKey]))
	for clvPlayer in get_tree().get_nodes_in_group("CLVPlayer"):
		for defaultKey in defaultPlayerOptions:
			if GLV.playerOptions.keys()[clvPlayer.variable.option] == defaultKey:
				clvPlayer.broadcast_value(float(defaultPlayerOptions[defaultKey]))
