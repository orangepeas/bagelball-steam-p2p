@tool
extends HBoxContainer
signal texturePicked(i : int)

@export var emptyTexture : CompressedTexture2D
@export var texture1 : CompressedTexture2D
@export var texture2 : CompressedTexture2D
@export var texture3 : CompressedTexture2D
@onready var textureArray = [emptyTexture,texture1,texture2,texture3]
@onready var emptyTextureButton = $EmptyTexture
##empty texture must be the first texture in the array

func _ready() -> void:
	for i in get_child_count():
		var styleBox : StyleBoxTexture = StyleBoxTexture.new()
		styleBox.texture = textureArray[i]
		get_children()[i].add_theme_stylebox_override("normal", styleBox)
		i += 1
	
	for textureButton in get_children():
		textureButton.find_child("TextureSelected").hide()

func show_selected(i : int):
	for textureButton in get_children():
		textureButton.find_child("TextureSelected").hide()
	get_children()[i].find_child("TextureSelected").show()

func _on_texture_1_pressed() -> void:
	show_selected(1)
	texturePicked.emit(1)

func _on_texture_2_pressed() -> void:
	show_selected(2)
	texturePicked.emit(2)

func _on_texture_3_pressed() -> void:
	show_selected(3)
	texturePicked.emit(3)

func _on_empty_texture_pressed() -> void:
	show_selected(0)
	texturePicked.emit(0)
