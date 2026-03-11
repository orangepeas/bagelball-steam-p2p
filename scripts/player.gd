extends CharacterBody3D

class_name Player;

var SENSITIVITY := global.sensitivity
const RAY_LENGTH := 2000.0

@export var normalSpeed : int
@export var sprintSpeed : int
@export var jumpVelocity : float
@export var bagelSpeedModifier : int
@export var gravityModifier : float
@export var airAcceleration : float
@export var floorDecelaration : float 
@export var terminalSpeed : float
@export var wallJumpVelocity : int
@export var noOfJumps : int

@onready var camera = $Camera3D
@export var mpSync : MultiplayerSynchronizer
@onready var bagelDistance = $"Camera3D/bagel distance"
@onready var spawnPosition
@onready var displayName : String
@onready var mesh = $MeshInstance3D
@onready var redTeam : bool
@onready var noiseMaker = $"Noise Maker"

var SPEED : float
var bagel : RigidBody3D
var jumpsLeft : int = noOfJumps
var holdJumpTimer : int = 0
var closeBagel : bool
var wallJumpDirection : Vector3
var canWallJump : bool
var singleplayer : bool
var quantumBagel : RigidBody3D
var playersWhoHaveLoaded = 0
var sprintToggled := false

var wasOnFloor : bool = true
var isOnWall : bool

var spectator : bool = false ##for use in noisemaker.gd
var disallowQuantumSwitch := false
var fastfallCooldown := false
var scrollThrowEnabled := false
var disallowScrollThrow := false
var isFastfalling := false
var canSuperJump := false
var prevVelocity : Vector3
var superJumpVelocity : Vector3
var bhopVelocity : Vector3
var horizontalSpeed : float
var canbhop := false

func _ready() -> void:
	$"Player UI".hide()
	$"Player UI".find_child("PlayerID").text = self.name
	global.isPaused = false
	SPEED = normalSpeed
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED#
	mpSync.set_multiplayer_authority(str(name).to_int())
	##when client connects to server its id is set to its name. nice way of doing it
	if mpSync.get_multiplayer_authority() == multiplayer.get_unique_id() or global.singleplayer == true:
		camera.make_current()
		$"Player UI".show() ##pause screen bug
		self.hide()
		$MeshInstance3D/MeshInstance3D3.hide()
		change_fov()
	
	global.connect("blueScored", respawn_player)
	global.connect("redScored", respawn_player)
	global.connect("playerTouchWall", can_wall_jump)
	global.connect("playerNoTouchWall", no_can_wall_jump)
	global.connect("gameStart", game_start)
	global.connect("practiceMode", practice_mode)
	global.connect("fovChange", change_fov)
	global.connect("sensChange", sens_change)
	await get_tree().create_timer(0.02).timeout ##doesnt work without this dunno why
	$"display name".text = displayName
	self.look_at(global.ballRespawnPoint)
	self.rotation.x = 0
	self.rotation.z = 0
	
	normalSpeed = GLV.playerNormalSpeed.value
	sprintSpeed = GLV.playerSprintSpeed.value
	terminalSpeed = GLV.playerMaxSpeed.value
	jumpVelocity = GLV.playerJumpVelocity.value
	wallJumpVelocity = GLV.playerWallJumpVelocity.value
	airAcceleration = GLV.playerAirAcceleration.value
	floorDecelaration = GLV.playerFloorDeceleration.value
	noOfJumps = GLV.playerJumps.value
	self.scale = GLV.playerSizeScale.value * Vector3(7,7,7)
	scrollThrowEnabled = GLV.scrollThrow.value
	print("scroll throw enabled: ", GLV.scrollThrow.value)

func sens_change():
	SENSITIVITY = global.sensitivity

func change_fov():
	camera.fov = global.FOV

func game_start():
	respawn_player()

func practice_mode():
	singleplayer = true

func can_wall_jump():
	canWallJump = true
func no_can_wall_jump():
	canWallJump = false

func _unhandled_input(event: InputEvent) -> void:
	if mpSync.get_multiplayer_authority() == multiplayer.get_unique_id() or global.singleplayer == true:
		if global.isPaused == false:
			if event is InputEventMouseMotion: #if the mouse is moved
				self.rotate_y(-event.relative.x * SENSITIVITY) #the event.relative.x is the x co-ordinate of the vector2 of the difference of where the mouse was to where the mouse is
				camera.rotate_x(-event.relative.y * SENSITIVITY) #some weird euler angles occur if you rotate body in both x and y axes, so we dont
				camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90)) #maximum degrees we can rotate vertically
			if global.funnyMode == true:
				if event is InputEventMouseButton && event.pressed && event.button_index == 2:
					velocity += camera.project_ray_normal(event.position) * RAY_LENGTH

func raycast_bagel(eventPos : Vector2):
	await get_tree().process_frame ##this fixes the bug where both players need to click before the raycast works
	var rayCastSuccess = false
	var space_state = get_world_3d().direct_space_state
	var collisionMask = 64 ##collision layer 7, bagel pickup area
	var from = camera.project_ray_origin(eventPos)
	var to = from + camera.project_ray_normal(eventPos) * RAY_LENGTH
	var rayQuery = PhysicsRayQueryParameters3D.create(from, to, collisionMask)
	rayQuery.collide_with_areas = true
	var result = space_state.intersect_ray(rayQuery)
	#print(result)
	#DrawLine3D.DrawLine(from, to, Color(1, 0, 0), 1.5)
	if !result.is_empty() && rayCastSuccess == false:
		if result.collider.is_in_group("bagel"):
			if result.collider.is_in_group("QuantumBagel"):
				quantumBagel = result.collider.get_parent()
			rayCastSuccess = true
			bagel = result.collider.get_parent()
			bagel.pick_up_bagel.rpc(self.name)
			#if global.funnyMode == false:
			#print("multiplayer id: ", mpSync.get_multiplayer_authority(), " result.collider", result.collider)
			#print("is it in bagel group: ", result.collider.is_in_group("bagel"))
			#print("bagel is: ", bagel)

func allow_super_jump():
	canSuperJump = true
	await get_tree().create_timer(0.15).timeout
	canSuperJump = false

func allow_bunny_hop():
	canbhop = true
	await get_tree().create_timer(0.09).timeout
	canbhop = false
	
func _physics_process(delta: float) -> void:
	if mpSync.get_multiplayer_authority() == multiplayer.get_unique_id() or global.singleplayer == true:
	##only the authority can change the value that we synchronize e.g. it will only move when the client moves it
	##jumping, hold for extra height & double jump
		horizontalSpeed = sqrt(abs(velocity.x)**2 + abs(velocity.z)**2)
		if not is_on_floor():
			velocity += get_gravity() * gravityModifier * delta
		if not wasOnFloor && is_on_floor() && velocity.y == 0:
			noiseMaker.play_floor_touch_noise()
			allow_bunny_hop()
			bhopVelocity = prevVelocity
			if isFastfalling == true: ##is reset on the next line
				allow_super_jump()
				superJumpVelocity = prevVelocity
		if is_on_floor():
			isFastfalling = false
			jumpsLeft = noOfJumps

		wasOnFloor = is_on_floor()
		
		##all the inputs in the pause script
		if global.isPaused == false:
			##raycast bagel
			if Input.is_action_just_pressed("raycast_bagel"):
				if bagel == null:
					raycast_bagel($"Player UI/ScreenCenter".position) #.rpc_id(mpSync.get_multiplayer_authority(),
				elif bagel != null:
					if bagel.bagelPickedUp == true && (multiplayer.get_unique_id() == bagel.playerIDHoldingBagel or global.singleplayer == true):
						if global.funnyMode == false && disallowScrollThrow == false:
							bagel.drop_bagel.rpc()
							disallowQuantumSwitch = true
							await get_tree().create_timer(0.1).timeout
							disallowQuantumSwitch = false
					else:
						raycast_bagel($"Player UI/ScreenCenter".position) #.rpc_id(mpSync.get_multiplayer_authority(),


			##jump
			if Input.is_action_just_pressed("jump") and jumpsLeft > 0:
				noiseMaker.play_jump_noise()
				holdJumpTimer = 1
				if canSuperJump:
					velocity = superJumpVelocity
					velocity.y = jumpVelocity * -70/get_gravity().y ##default value is -40, so jump is affected by negative gravity properly
				elif canbhop == true:
					velocity = bhopVelocity
					velocity.y = jumpVelocity * -40/get_gravity().y ##default value is -40, so jump is affected by negative gravity properly
				else:
					velocity.y = jumpVelocity * -40/get_gravity().y ##default value is -40, so jump is affected by negative gravity properly

				jumpsLeft -= 1
			if Input.is_action_pressed("jump") and holdJumpTimer < 20 and holdJumpTimer != 0:
				holdJumpTimer += 1
				velocity.y += 0.5
			else:
				holdJumpTimer = 0
				

			##wall jump
			if is_on_wall():
				wallJumpDirection = get_wall_normal()
			if canWallJump == true or is_on_wall_only():
				if Input.is_action_just_pressed("jump") && not is_on_floor():
					noiseMaker.play_jump_noise()
					jumpsLeft = noOfJumps - 1
					holdJumpTimer = 1
					velocity.y = jumpVelocity
					velocity += wallJumpDirection * wallJumpVelocity
				if Input.is_action_pressed("jump") and holdJumpTimer < 20 and holdJumpTimer != 0:
					holdJumpTimer += 1
					velocity.y += 0.5
				else:
					holdJumpTimer = 0


			##sprinting
			if global.autoSprint == true:
				if SPEED < sprintSpeed:
					SPEED += 0.5
			else:
				if global.holdSprint == true:
					if Input.is_action_just_pressed("sprint"):
						SPEED = sprintSpeed - 10
					if Input.is_action_pressed("sprint"):
						if SPEED < sprintSpeed:
							SPEED += 0.5
					else:
						if SPEED > normalSpeed:
							SPEED -=1.5
				elif global.holdSprint == false:
					if Input.is_action_just_pressed("sprint"):
						sprintToggled = !sprintToggled
						if sprintToggled:
							SPEED = sprintSpeed - 10
					if sprintToggled == true:
						if SPEED < sprintSpeed:
							SPEED += 0.5
					elif SPEED > normalSpeed:
						SPEED -=1.5


			##close and far bagel
			if Input.is_action_just_pressed("close_bagel") && closeBagel == false:
				closeBagel = true
				bagelSpeedModifier -= 13
				bagelDistance.position.z += 20
			if Input.is_action_just_pressed("far_bagel") && closeBagel == true:
				closeBagel = false
				bagelSpeedModifier += 13
				bagelDistance.position.z -= 20
				if !scrollThrowEnabled:
					disallowScrollThrow = true
					await get_tree().create_timer(0.1).timeout
					disallowScrollThrow = false


			if Input.is_action_just_pressed("quantum_bagel_switch"):
				if quantumBagel != null:
					if !quantumBagel.bagelPickedUp && disallowQuantumSwitch == false:
						if bagel != null:
							if !global.singleplayer:
								bagel.drop_bagel.rpc()
							else:
								bagel.drop_bagel()
							#bagel.bagelPickedUp == false
						if !global.singleplayer:
							quantumBagel.pick_up_bagel.rpc(self.name)
						else:
							quantumBagel.pick_up_bagel(self.name)
						bagel = quantumBagel
						quantumBagel.quantum_switch()


			##fast fall
			if Input.is_action_just_pressed("fastfall") and not is_on_floor() && fastfallCooldown == false:
				isFastfalling = true
				if velocity.y > 0:
					velocity.y = -40
				else:
					velocity.y -= 40
				fastfallCooldown = true
				await get_tree().create_timer(0.05).timeout
				fastfallCooldown = false
				
			if Input.is_action_pressed("fastfall") and not is_on_floor() && fastfallCooldown == false:
				velocity.y -= 2



			##splonk(throw) bagel forward
			#if Input.is_action_just_pressed("splonk_bagel_forward"):
				#if closeBagel == true && bagel != null:
					#closeBagel = false
					#bagelSpeedModifier += 13
					#bagelDistance.position.z -= 20
					#await get_tree().create_timer(0.04).timeout
					#bagel.drop_bagel.rpc()


			##bagel map fall thru platform
			#if Input.is_action_just_pressed("fastfall"):
				#global.disableOneWayBagelMap.emit()
			#if Input.is_action_just_released("fastfall"):
				#global.enableOneWayBagelMap.emit()


			##little boost
			#if Input.is_action_just_pressed("little_boost"):
				#var cursorPos = DisplayServer.screen_get_size()/2
				#velocity += camera.project_ray_origin(cursorPos)


		##putting movement outside of pause script
		##moving, air accel and decel
		var input_dir = Input.get_vector("left", "right", "forward", "back")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if is_on_floor():
			if direction && global.isPaused == false:
				velocity.x = move_toward(velocity.x, direction.x * SPEED, SPEED)
				velocity.z = move_toward(velocity.z, direction.z * SPEED, SPEED)
			else:
				#await get_tree().create_timer(0.04).timeout ##fails to allow bhopping to maintain speed
				velocity.x = move_toward(velocity.x, 0, floorDecelaration)
				velocity.z = move_toward(velocity.z, 0, floorDecelaration)
		elif not is_on_floor():
			if direction:
				if horizontalSpeed < SPEED:
					##if we are in the air, inputting movement and below target speed, accelerate towards it
					velocity.x = move_toward(velocity.x, direction.x * SPEED, airAcceleration)
					velocity.z = move_toward(velocity.z, direction.z * SPEED, airAcceleration)
				elif floor(horizontalSpeed) > SPEED + 7:
					##if we are in the air, inputting movement, and above target speed, accelerate towards terminal speed
					velocity.x = move_toward(velocity.x, direction.x * terminalSpeed, airAcceleration)
					velocity.z = move_toward(velocity.z, direction.z * terminalSpeed, airAcceleration)
				else:
					##else we still in between speed + 7 and speed then we still need to be able to move
					velocity.x = move_toward(velocity.x, direction.x * SPEED, airAcceleration)
					velocity.z = move_toward(velocity.z, direction.z * SPEED, airAcceleration)
			elif horizontalSpeed < SPEED:
				##if we are not moving and we are below target speed, decelerate to 0
				velocity.x = move_toward(velocity.x, 0, airAcceleration/5)
				velocity.z = move_toward(velocity.z, 0, airAcceleration/5)
		prevVelocity = velocity
		#prints("sprint speed: ", sprintSpeed, "normal speed: ", normalSpeed, "current speed: ", sqrt(abs(velocity.x)**2 + abs(velocity.z)**2), "SPEED: ", SPEED)
		move_and_slide()

func respawn_player():
	if bagel != null:
		if bagel.bagelPickedUp == true:
			bagel.player_respawn_bagel(spawnPosition)
	self.global_position = spawnPosition
	self.look_at(global.ballRespawnPoint)
	self.rotation.x = 0 ##otherwise look_at beans the rotation
	self.rotation.z = 0
