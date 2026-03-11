extends Area3D

var teleportCounter : int

func _ready():
	$"../conveyer belt".hide()
	$"../conveyer belt".process_mode = Node.PROCESS_MODE_DISABLED

func _on_body_entered(body: Node3D) -> void:
	body.global_position.y = -body.global_position.y
	teleportCounter+=1
	if teleportCounter == 10:
		$"../conveyer belt".show()
		$"../conveyer belt".process_mode = Node.PROCESS_MODE_INHERIT
