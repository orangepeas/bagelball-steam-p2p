extends Control

var insultSelectorShowing := false
var id
func _ready() -> void:
	$PanelContainer.hide()
	id = multiplayer.get_unique_id()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("insult_selector"):
		if insultSelectorShowing == false:
			$PanelContainer.show()
		else:
			$PanelContainer.hide()
		insultSelectorShowing = !insultSelectorShowing
	if insultSelectorShowing == true:
		if event.is_action_pressed("1"):
			global.youSalmon.emit(id)
			insultSelectorShowing = !insultSelectorShowing
			$PanelContainer.hide()
		if event.is_action_pressed("2"):
			global.youMackerel.emit(id)
			insultSelectorShowing = !insultSelectorShowing
			$PanelContainer.hide()
		if event.is_action_pressed("3"):
			global.absoluteMollusc.emit(id)
			insultSelectorShowing = !insultSelectorShowing
			$PanelContainer.hide()
		if event.is_action_pressed("4"):
			global.bloodyTrout.emit(id)
			insultSelectorShowing = !insultSelectorShowing
			$PanelContainer.hide()
		if event.is_action_pressed("5"):
			global.slimyWorm.emit(id)
			insultSelectorShowing = !insultSelectorShowing
			$PanelContainer.hide()
		if event.is_action_pressed("6"):
			global.soggyBagel.emit(id)
			insultSelectorShowing = !insultSelectorShowing
			$PanelContainer.hide()
