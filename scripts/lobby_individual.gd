extends Button

@onready var client = $"../../../../../../Client"
@onready var lobbyId

func _on_join_lobby_button_pressed() -> void:
	$"../../../../../..".disable_buttons()
	client._on_join_lobby_button_down(lobbyId)
