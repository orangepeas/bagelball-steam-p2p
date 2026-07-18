extends Node3D

signal show_main_menu

var headPieceIndex := 0
var bodyPieceIndex := 0
var legsPieceIndex := 0
var allow_rotate := false


@onready var character := $character
@onready var music = $CharacterCreatorTheme

@onready var pieceForwardSound = $PieceChangeForward
@onready var pieceBackSound = $PieceChangeBackward

@onready var headPieceParent = $character/head
@onready var bodyPieceParent = $character/body
@onready var legsPieceParent = $character/legs

@onready var headLabel = $UI/MarginContainer/VBoxContainer/HeadSelector/HeadLabel
@onready var bodyLabel = $UI/MarginContainer/VBoxContainer/BodySelector/BodyLabel
@onready var legsLabel = $UI/MarginContainer/VBoxContainer/LegsSelector/LegsLabel

func _ready():
	hide_all_ui()
	for headPiece in headPieceParent.get_children():
		headPiece.hide()
	for bodyPiece in bodyPieceParent.get_children():
		bodyPiece.hide()
	for legsPiece in legsPieceParent.get_children():
		legsPiece.hide()
	var character_pieces = ConfigFileHandler.load_character_pieces()
	headPieceIndex = int(character_pieces.head_piece)
	bodyPieceIndex = int(character_pieces.body_piece)
	legsPieceIndex = int(character_pieces.legs_piece)
	headPieceParent.get_children()[headPieceIndex].show()
	bodyPieceParent.get_children()[bodyPieceIndex].show()
	legsPieceParent.get_children()[legsPieceIndex].show()
	headLabel.text = headPieceParent.get_children()[headPieceIndex].name
	bodyLabel.text = bodyPieceParent.get_children()[bodyPieceIndex].name
	legsLabel.text = legsPieceParent.get_children()[legsPieceIndex].name
	global.headPiece = headPieceIndex
	global.bodyPiece = bodyPieceIndex
	global.legsPiece = legsPieceIndex

func hide_all_ui():
	hide()
	$UI.hide()

func show_all_ui():
	show()
	$UI.show()

func piece_change(pieceParent, pieceIndex, label, increase : bool):
	pieceParent.get_children()[pieceIndex].hide()
	if increase:
		pieceIndex += 1
		pieceForwardSound.play()
	else:
		pieceIndex -= 1
		pieceBackSound.play()
	pieceIndex = check_index_loop(pieceIndex, pieceParent.get_child_count() - 1)
	pieceParent.get_children()[pieceIndex].show()
	label.text = pieceParent.get_children()[pieceIndex].name
	return pieceIndex

func _unhandled_input(event: InputEvent) -> void:
	if visible:
		if Input.is_action_just_pressed("raycast_bagel"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			allow_rotate = true
		elif Input.is_action_just_released("raycast_bagel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			allow_rotate = false
		if event is InputEventMouseMotion && allow_rotate:
			#character.rotate_y(-event.relative.x * 0.005)
			#character.rotate_x(event.relative.y * 0.005)
			character.apply_torque(Vector3(0, -event.relative.x * 0.5, 0))
			character.apply_torque(Vector3(event.relative.y * 0.5, 0, 0))

func _on_head_forward_pressed() -> void:
	headPieceIndex = piece_change(headPieceParent, headPieceIndex, headLabel, true)

func _on_head_back_pressed() -> void:
	headPieceIndex = piece_change(headPieceParent, headPieceIndex, headLabel, false)

func _on_body_forward_pressed() -> void:
	bodyPieceIndex = piece_change(bodyPieceParent, bodyPieceIndex, bodyLabel, true)

func _on_body_back_pressed() -> void:
	bodyPieceIndex = piece_change(bodyPieceParent, bodyPieceIndex, bodyLabel, false)

func _on_legs_forward_pressed() -> void:
	legsPieceIndex = piece_change(legsPieceParent, legsPieceIndex, legsLabel, true)

func _on_legs_back_pressed() -> void:
	legsPieceIndex = piece_change(legsPieceParent, legsPieceIndex, legsLabel, false)

func check_index_loop(index, max_index):
	if index < 0:
		index = max_index
	elif index > max_index:
		index = 0
	return index

func _on_back_pressed() -> void:
	ConfigFileHandler.save_character_pieces("head_piece", headPieceIndex)
	ConfigFileHandler.save_character_pieces("body_piece", bodyPieceIndex)
	ConfigFileHandler.save_character_pieces("legs_piece", legsPieceIndex)
	global.headPiece = headPieceIndex
	global.bodyPiece = bodyPieceIndex
	global.legsPiece = legsPieceIndex
	music.volume_db = -99
	hide_all_ui()
	show_main_menu.emit()
