extends CharacterBody3D

class_name SpectatorPlayer;

const SENSITIVITY = 0.003

@onready var camera = $Camera3D
@export var mpSync : MultiplayerSynchronizer
@onready var mesh = $MeshInstance3D
@onready var SPEED : int = 100
var spectator : bool = true

func _ready() -> void:
	$"Player UI".hide()
	global.isPaused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mpSync.set_multiplayer_authority(str(name).to_int()) ##this is an arbitrary authority we set which we can check with later
	##when client connects to server its id is set to its name. nice way of doing it
	prints(mpSync.get_multiplayer_authority(), multiplayer.get_unique_id())
	if mpSync.get_multiplayer_authority() == multiplayer.get_unique_id():
		camera.make_current()
		$"Player UI".show()
		self.hide()
		change_fov()
	await get_tree().create_timer(0.02).timeout ##doesnt work without this dunno why
	global.connect("fovChange", change_fov)
	global.connect("gameStart", respawn_player)

func change_fov():
	camera.fov = global.FOV

func _unhandled_input(event: InputEvent) -> void:
	if mpSync.get_multiplayer_authority() == multiplayer.get_unique_id():
		if global.isPaused == false:
			if event is InputEventMouseMotion: #if the mouse is moved
				self.rotate_y(-event.relative.x * SENSITIVITY) #the event.relative.x is the x co-ordinate of the vector2 of the difference of where the mouse was to where the mouse is
				camera.rotate_x(-event.relative.y * SENSITIVITY) #some weird euler angles occur if you rotate body in both x and y axes, so we dont
				camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90)) #maximum degrees we can rotate vertically


func _physics_process(_delta: float) -> void:
	if mpSync.get_multiplayer_authority() == multiplayer.get_unique_id():
		if global.isPaused == false:
			if Input.is_action_pressed("sprint"):
				SPEED = 200
			else:
				SPEED = 100
			
			if Input.is_action_pressed("jump"):
				velocity.y = SPEED
			elif Input.is_action_pressed("fastfall"):
				velocity.y = -SPEED
			else:
				velocity.y = 0
			
			##copied from brackey's tutorial
			var input_dir = Input.get_vector("left", "right", "forward", "back")
			var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			
			move_and_slide()

@rpc("any_peer","call_local")
func destroy_player():
	self.queue_free()

func _on_player_ui_destroy_player() -> void:
	destroy_player.rpc()

func respawn_player():
	global_position = get_tree().get_first_node_in_group("BallRespawnPoint").global_position
	global_position.y += 25
	self.look_at(global.ballRespawnPoint)
	self.rotation.x = 0 ##otherwise look_at beans the rotation
	self.rotation.z = 0
