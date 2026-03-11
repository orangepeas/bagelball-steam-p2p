extends Button
signal primaryInputRebind
signal secondaryInputRebind

@onready var primaryButton = $MarginContainer/HBoxContainer/LabelInput
@onready var secondaryButton = $MarginContainer/HBoxContainer/LabelInput2
@onready var actionLabel = $MarginContainer/HBoxContainer/LabelAction
@onready var inputLabel = $MarginContainer/HBoxContainer/LabelInput
@onready var inputLabel2 = $MarginContainer/HBoxContainer/LabelInput2

func _on_label_input_pressed() -> void:
	primaryInputRebind.emit()

func _on_label_input_2_pressed() -> void:
	secondaryInputRebind.emit()
