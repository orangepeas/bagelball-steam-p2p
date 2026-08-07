extends Node3D

signal show_main_menu

var headPieceIndex := 0
var bodyPieceIndex := 0
var legsPieceIndex := 0
var headTextureIndex := 0
var bodyTextureIndex := 0
var legsTextureIndex := 0

var allow_rotate := false
var mouse_last_position := Vector2(0,0)

@onready var character := $character
@onready var music = $CharacterCreatorTheme

@onready var pieceForwardSound = $PieceChangeForward
@onready var pieceBackSound = $PieceChangeBackward

@onready var characterPieces = $character/CharacterPieces

@onready var redSelected := $UI/RedSelected
@onready var blueSelected := $UI/BlueSelected

@onready var headLabel = $UI/MarginContainer/VBoxContainer/HeadContainer/HeadSelector/HeadLabel
@onready var bodyLabel = $UI/MarginContainer/VBoxContainer/BodyContainer/BodySelector/BodyLabel
@onready var legsLabel = $UI/MarginContainer/VBoxContainer/LegsContainer/LegsSelector/LegsLabel

@onready var headTextureButtons = $UI/MarginContainer/VBoxContainer/HeadContainer/HeadTextureButtons
@onready var bodyTextureButtons = $UI/MarginContainer/VBoxContainer/BodyContainer/BodyTextureButtons
@onready var legsTextureButtons = $UI/MarginContainer/VBoxContainer/LegsContainer/LegsTextureButtons

@onready var headMaterial = StandardMaterial3D.new()
@onready var bodyMaterial = StandardMaterial3D.new()
@onready var legsMaterial = StandardMaterial3D.new()
@onready var materialArray = [headMaterial, bodyMaterial, legsMaterial]
@onready var materialPlonk = StandardMaterial3D.new()

func _ready():
	hide_all_ui()
	for headPiece in characterPieces.head.get_children():
		headPiece.hide()
	for bodyPiece in characterPieces.body.get_children():
		bodyPiece.hide()
	for legsPiece in characterPieces.legs.get_children():
		legsPiece.hide()
	var character_pieces = ConfigFileHandler.load_character_pieces()
	_on_red_pressed()
	await get_tree().process_frame
	headPieceIndex = int(character_pieces.head_piece)
	bodyPieceIndex = int(character_pieces.body_piece)
	legsPieceIndex = int(character_pieces.legs_piece)
	headTextureIndex = int(character_pieces.head_texture)
	bodyTextureIndex = int(character_pieces.body_texture)
	legsTextureIndex = int(character_pieces.legs_texture)
	var initialHead = characterPieces.head.get_children()[headPieceIndex]
	var initialBody = characterPieces.body.get_children()[bodyPieceIndex]
	var initialLegs = characterPieces.legs.get_children()[legsPieceIndex]
	if headTextureIndex != 0:
		initialHead.material.albedo_texture = headTextureButtons.textureArray[headTextureIndex]
	if bodyTextureIndex != 0:
		initialBody.material.albedo_texture = bodyTextureButtons.textureArray[bodyTextureIndex]
	if legsTextureIndex != 0:
		initialLegs.material.albedo_texture = legsTextureButtons.textureArray[legsTextureIndex]
	initialHead.show()
	initialBody.show()
	initialLegs.show()
	headLabel.text = initialHead.name
	bodyLabel.text = initialBody.name
	legsLabel.text = initialLegs.name
	headTextureButtons.show_selected(headTextureIndex)
	bodyTextureButtons.show_selected(bodyTextureIndex)
	legsTextureButtons.show_selected(legsTextureIndex)
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
			mouse_last_position = event.position
		elif Input.is_action_just_released("raycast_bagel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			allow_rotate = false
			get_viewport().warp_mouse(mouse_last_position)
		if event is InputEventMouseMotion && allow_rotate:
			character.apply_torque(Vector3(0, -event.relative.x * 0.5, 0))
			character.apply_torque(Vector3(event.relative.y * 0.5, 0, 0))

func _on_head_forward_pressed() -> void:
	headPieceIndex = piece_change(characterPieces.head, headPieceIndex, headLabel, true)

func _on_head_back_pressed() -> void:
	headPieceIndex = piece_change(characterPieces.head, headPieceIndex, headLabel, false)

func _on_body_forward_pressed() -> void:
	bodyPieceIndex = piece_change(characterPieces.body, bodyPieceIndex, bodyLabel, true)

func _on_body_back_pressed() -> void:
	bodyPieceIndex = piece_change(characterPieces.body, bodyPieceIndex, bodyLabel, false)

func _on_legs_forward_pressed() -> void:
	legsPieceIndex = piece_change(characterPieces.legs, legsPieceIndex, legsLabel, true)

func _on_legs_back_pressed() -> void:
	legsPieceIndex = piece_change(characterPieces.legs, legsPieceIndex, legsLabel, false)

func check_index_loop(index, max_index):
	if index < 0:
		index = max_index
	elif index > max_index:
		index = 0
	return index

func _on_red_pressed() -> void:
	redSelected.show()
	blueSelected.hide()
	colour_character(false)

func _on_blue_pressed() -> void:
	blueSelected.show()
	redSelected.hide()
	colour_character(true)

func colour_character(blue : bool):
	if blue:
		for m in materialArray:
			m.albedo_color = Color(0, 1, 50, 1)
		materialPlonk.albedo_color = Color(0.0, 0.68, 0.091, 1.0)
	else:
		for m in materialArray:
			m.albedo_color = Color(1.7, 0, 0, 1)
		materialPlonk.albedo_color = Color(1.298, 0.705, 0.212, 1)
	for headPiece in characterPieces.head.get_children():
		for directionalPlonk in headPiece.find_child("DirectionalPlonk").get_children():
			directionalPlonk.material = materialPlonk

	for i in characterPieces.characterPieceArray.size():
		for p in get_all_children(characterPieces.characterPieceArray[i]):
			if p.is_in_group("normalColourPiece"):
				p.material = materialArray[i]

func get_all_children(node,arr:=[]):
	##https://forum.godotengine.org/t/how-to-get-all-children-from-a-node/18587/2
	arr.push_back(node)
	for child in node.get_children():
		arr = get_all_children(child,arr)
	return arr

func _on_head_texture_buttons_texture_picked(i: int) -> void:
	for headPiece in get_all_children(characterPieces.head):
		if headPiece.is_in_group("normalColourPiece"):
			if i != 0:
				headPiece.material.albedo_texture = headTextureButtons.textureArray[i]
			else:
				headPiece.material.albedo_texture = null
			headTextureIndex = i

func _on_body_texture_buttons_texture_picked(i: int) -> void:
	for bodyPiece in get_all_children(characterPieces.body):
		if bodyPiece.is_in_group("normalColourPiece"):
			if i != 0:
				bodyPiece.material.albedo_texture = bodyTextureButtons.textureArray[i]
			else:
				bodyPiece.material.albedo_texture = null
			bodyTextureIndex = i

func _on_legs_texture_buttons_texture_picked(i: int) -> void:
	for legsPiece in get_all_children(characterPieces.legs):
		if legsPiece.is_in_group("normalColourPiece"):
			if i != 0:
				legsPiece.material.albedo_texture = legsTextureButtons.textureArray[i]
			else:
				legsPiece.material.albedo_texture = null
			legsTextureIndex = i

func _on_back_pressed() -> void:
	ConfigFileHandler.save_character_pieces("head_piece", headPieceIndex)
	ConfigFileHandler.save_character_pieces("body_piece", bodyPieceIndex)
	ConfigFileHandler.save_character_pieces("legs_piece", legsPieceIndex)
	ConfigFileHandler.save_character_pieces("head_texture", headTextureIndex)
	ConfigFileHandler.save_character_pieces("body_texture", bodyTextureIndex)
	ConfigFileHandler.save_character_pieces("legs_texture", legsTextureIndex)
	global.headPiece = headPieceIndex
	global.bodyPiece = bodyPieceIndex
	global.legsPiece = legsPieceIndex

	music.volume_db = -99
	hide_all_ui()
	show_main_menu.emit()
