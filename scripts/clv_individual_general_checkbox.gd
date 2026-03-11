extends HBoxContainer
var variable : LobbyVariable

@export var exportOption : GLV.generalOptions
@export var exportValue : bool

func _ready():
	$VariableLabel.text = str(GLV.generalOptions.keys()[exportOption])
	$VariableCheckbox.button_pressed = exportValue
	variable = LobbyVariable.new(exportOption,exportValue)

func _on_variable_checkbox_toggled(toggled_on: bool) -> void:
	broadcast_value.rpc(toggled_on)

@rpc("any_peer","call_local")
func broadcast_value(value : bool):
	$VariableCheckbox.button_pressed = value
	for glv in GLV.generalOptionsList:
		if variable != null: ##idk why theyre sometimes null
			if variable.option == glv.option:
				glv.value = value
				variable.value = value
