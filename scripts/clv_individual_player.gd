extends HBoxContainer

var variable : LobbyVariable

@export var exportOption : GLV.playerOptions
@export var exportValue : float
@export var minValue : float
@export var maxValue : float
@export var step : float

func _ready():
	$VariableLabel.text = str(GLV.playerOptions.keys()[exportOption])
	$VariableNum.value = exportValue
	variable = LobbyVariable.new(exportOption,exportValue)
	$VariableNum.min_value = minValue
	$VariableNum.max_value = maxValue
	$VariableNum.step = step

func _on_variable_num_value_changed(value: float) -> void:
	broadcast_value.rpc(value)

@rpc("any_peer","call_local")
func broadcast_value(value : float):
	$VariableNum.value = value
	for glv in GLV.playerOptionsList:
		if variable != null: ##idk why theyre sometimes null
			if variable.option == glv.option:
				glv.value = value
				variable.value = value
