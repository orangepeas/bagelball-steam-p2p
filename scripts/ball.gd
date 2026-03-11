extends RigidBody3D

@onready var spawnPos : Vector3
var playerIDWhoLastHit : int
var sisyphusBall : bool
@onready var originalScale := scale

func _ready() -> void:
	self.set_multiplayer_authority(global.lobbyHostID)
	#multiplayerAuthority = global.lobbyHostID
	global.connect("blueScored", respawn_ball)
	global.connect("redScored", respawn_ball)
	global.connect("gameStart", respawn_ball)
	global.connect("levelFinishedLoading", set_spawn_pos)
	continuous_cd = false
	self.mass = GLV.ballWeight.value
	self.physics_material_override.bounce = GLV.ballBounciness.value
	self.physics_material_override.friction = GLV.ballFriction.value
	$MeshInstance3D.scale = $MeshInstance3D.scale * GLV.ballSizeScale.value
	$CollisionShape3D.scale = $CollisionShape3D.scale * GLV.ballSizeScale.value
	if physics_material_override.friction == 0 && physics_material_override.bounce == 1:
		linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
		linear_damp = 0
		angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
		angular_damp = 0
	if global.map == global.Map.sisyphus:
		sisyphusBall = true
	#prints("self.mass",self.mass.value,"self.bounce",self.physics_material_override.bounce.value,"self.scale",$CollisionShape3D.scale.value)

##signal is fired and sets spawn pos once main level finished loading
func set_spawn_pos():
	if global.map != global.Map.sumo and global.map != global.Map.sumo2:
		spawnPos = get_tree().get_first_node_in_group("BallRespawnPoint").global_position
		respawn_ball()

func respawn_ball():
	if global.map != global.Map.sumo:
		if global.map != global.Map.sumo2:
			linear_velocity = Vector3(0,0,0)
			angular_velocity = Vector3(0,0,0)
			global_position = spawnPos

@rpc("any_peer","call_local")
func toggle_continuous_cd():
	continuous_cd = !continuous_cd
	#print("ball continuous cd is: ", continuous_cd)

func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > 150:
		$big.emitting = true
		$medium.emitting = true
		$smol.emitting = true
	else:
		$big.emitting = false
		$medium.emitting = false
		$smol.emitting = false
	if sisyphusBall == true:
		mass = (global_position.y - spawnPos.y + 3)/4.4 + GLV.ballWeight.value
		##scale = originalScale * ((global_position.y - spawnPos.y + 3)/3 + GLV.ballSizeScale.value)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("bagel"):
		playerIDWhoLastHit = body.playerIDHoldingBagel
		#print(body.mass)
