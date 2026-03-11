extends Panel

var isHosting : bool

func _on_back_pressed() -> void:
	$"..".enable_buttons()
	self.hide()

func _process(_delta: float) -> void:
	if isHosting == false:
		if $"MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lobby ID Input".text.length() < 18:
			$"MarginContainer/VBoxContainer/HBoxContainer2/Join Private Lobby Button".disabled = true
		else:
			$"MarginContainer/VBoxContainer/HBoxContainer2/Join Private Lobby Button".disabled = false

func _on_client_is_hosting() -> void:
	isHosting = true

func _on_client_is_not_hosting() -> void:
	isHosting = false
