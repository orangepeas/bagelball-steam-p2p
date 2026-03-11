extends RigidBody3D

class_name Bagel

@export var bagelPickedUp : bool ##for access in plyaer and ball
var player : Player
var bagelDestination
var singlePlayer : bool
@onready var playerIDHoldingBagel : int ##so the ball can access it
var respawnPoint : Vector3

#var previousGlobalPos
#@export var k : int
#@export var m : int

func _ready() -> void:
	global.practiceMode.connect(practice_mode)
	continuous_cd = false
	if global.map == global.Map.dome:
		print("dome map")
		collision_layer += 128
		collision_mask += 128
	if singlePlayer != true:
		$MultiplayerSynchronizer.set_multiplayer_authority(global.lobbyHostID)
		playerIDHoldingBagel = $MultiplayerSynchronizer.get_multiplayer_authority()
	global.connect("blueScored", respawn_bagel)
	global.connect("redScored", respawn_bagel)
	
	
	self.physics_material_override.bounce = GLV.bagelBounciness.value
	self.physics_material_override.friction = GLV.bagelFriction.value
	self.mass = GLV.bagelWeightWhenNotHeld.value
	$Bagel.scale *= GLV.bagelSizeScale.value
	$CollisionShape3D.scale *= GLV.bagelSizeScale.value
	$Area3D/CollisionShape3D.scale *= GLV.bagelSizeScale.value
	$"Bagel Pickup Zone/CollisionShape3D".scale *= GLV.bagelSizeScale.value
	if GLV.bagelSizeScale.value >= 2:
		$"Bagel Pickup Zone/CollisionShape3D".shape.height = $CollisionShape3D.shape.height * 3.5
		$"Bagel Pickup Zone/CollisionShape3D".shape.radius = $CollisionShape3D.shape.radius * 1.1
	if physics_material_override.friction == 0 && physics_material_override.bounce == 1:
		linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
		linear_damp = 0
		angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
		angular_damp = 0

func practice_mode():
	singlePlayer = true

func _on_area_3d_body_entered(_body: Node3D) -> void:
	if _body.is_in_group("ball"):
		$"Ball Hit Noise".play()
	else:
		$"Bagel Hit Noise".play()

@rpc("any_peer","call_local","reliable")
func set_bagel_authority(playerName : String):
	$MultiplayerSynchronizer.set_multiplayer_authority(playerName.to_int())

@rpc("any_peer","call_local")
func pick_up_bagel(playerId : String):
	##it has trouble rpcing an object across, so im using player id
	if !bagelPickedUp:
		self.mass = GLV.bagelWeightWhenHeld.value
		for p in get_tree().get_nodes_in_group("player"):
			if p.name == playerId:
				player = p
		if singlePlayer != true:
			playerIDHoldingBagel = player.name.to_int()
			set_bagel_authority.rpc(player.name)
		bagelPickedUp = true
		bagelDestination = player.bagelDistance
		#self.apply_central_force(Vector3(0,0,0)) ##rigid bodies fall asleep and integrate_forces doesnt get called unless a force is applied
	##so this just wakes it up

@rpc("any_peer","call_local")
func drop_bagel():
	self.mass = GLV.bagelWeightWhenNotHeld.value
	player = null
	bagelPickedUp = false
	bagelDestination = null


@rpc("any_peer","call_local")
func toggle_continuous_cd():
	continuous_cd = !continuous_cd
	#print("bagel continuous cd is: ", continuous_cd)

func _physics_process(_delta: float) -> void:
	##print("ncotnsitnous  cd:  ", continuous_cd)
	if player != null && bagelPickedUp == true:
		if self.global_position != bagelDestination.global_position:
			if global.funnyMode == false:
				self.linear_velocity = player.bagelSpeedModifier*(bagelDestination.global_position - self.global_position)
			elif global.funnyMode == true:
				self.apply_central_force(0.1*player.bagelSpeedModifier*(bagelDestination.global_position - self.global_position))
				
	if linear_velocity.length() > 250:
		#$GPUParticles3D.draw_pass_1.material.albedo_color.h = randi_range(1,255)
		#$GPUParticles3D.draw_pass_1.surface_get_material(1).albedo_color.h = randi_range(1,255)
		$GPUParticles3D.emitting = true
	else:
		$GPUParticles3D.emitting = false

func respawn_bagel() -> void:
	if global.map == global.Map.sumo or global.map == global.Map.sumo2:
		print("bagel respawn")
		global_position = respawnPoint

func player_respawn_bagel(playerRespawnPoint : Vector3):
	global_position.x = playerRespawnPoint.x - 0.3 * playerRespawnPoint.x
	global_position.z = playerRespawnPoint.z - 0.3 * playerRespawnPoint.z
	global_position.y = playerRespawnPoint.y
			#previousGlobalPos = self.global_position


##the docs say to use integrate forces instead of physics process for rigid bodies because normally the velocity of a rigidbody
##is determined by the physics engine by forces, and overwriting linear velocity bungulates it but it doesnt really work
##the bagels just become orbital so i will not bother

##tried doing some fuckin maths to convert velocity to acceleration and failed. the bagelball equation.
#func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#if player != null && bagelPickedUp == true:
		#if self.global_position != bagelDestination.global_position:
			##var vector = player.bagelSpeedModifier*(bagelDestination.global_position - self.global_position)
#
			##var vector : Vector3
			##vector.x = 0.5 * player.bagelSpeedModifier*(bagelDestination.global_position.x - self.global_position.x)**2
			##vector.y = 0.5 * player.bagelSpeedModifier*(bagelDestination.global_position.y - self.global_position.y)**2
			##vector.z = 0.5 * player.bagelSpeedModifier*(bagelDestination.global_position.z - self.global_position.z)**2
			###print(vector)
			##
			#var force : Vector3
			#var displacement : Vector3 = bagelDestination.global_position - self.global_position
#
			#force.x = displacement.x - 10 * sin(k * displacement.x) * 100**(-1 * m * displacement.x**2)
			#force.y = displacement.y - 10 * sin(k * displacement.y) * 100**(-1 * m * displacement.y**2)
			#force.z = displacement.z - 10 * sin(k * displacement.z) * 100**(-1 * m * displacement.z**2)
#
#
#
			#
			##var force : Vector3
			##var displacement : Vector3 = bagelDestination.global_position - self.global_position
			##var r = sqrt(displacement.x**2 + displacement.y**2 + displacement.z**2)
			##var theta = acos(displacement.z/r)
			##var phi = sign(displacement.y) * acos(displacement.x/sqrt(displacement.x**2 + displacement.y**2))
			####polar coordinate conversions dictated by simi
			##force = r
#
			##force = displacement - 10 * sinkx * 2 ** (-1 * m * displacementSquared)
			##force.x = (bagelDestination.global_position.x - self.global_position.x)
			##force.y = (bagelDestination.global_position.y - self.global_position.y)
			##force.z = (bagelDestination.global_position.z - self.global_position.z)
			##if previousGlobalPos != null:
				##diff = previousGlobalPos - self.global_position
			##if diff
			#force*=100
			#print("we moving")
			#previousGlobalPos = self.global_position
			#state.apply_central_force(force)
