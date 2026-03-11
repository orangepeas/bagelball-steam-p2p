extends Panel

var newText : String

func _on_back_pressed() -> void:
	$"..".enable_buttons()
	self.hide()
