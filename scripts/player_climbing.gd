extends Player;

var wallJumpsleft := 2
var dashesLeft := 2
var canDash := true
var groundPounding := false
var allowSuperJump := false
var allowSpeedySuperJump := false
var superJumpWindow := 0.3
var youWasSpeedy := false
var youWasSpeedyVelocity : Vector3
var allowWallJumpSpeedRetention := false
var prevOnWall := false
var prevHorizontalVelocity : float
var prevOnFloor := false
var prevVerticalVelocity : float
var extraSuperJumpVelocity : float
var legSwitch := false
var isWalkPlaying := false
var someOtherBool := false
var fullscreen := false

@onready var body = $MeshInstance3D

func _ready() -> void:
	camera = $CameraPivot/Camera3D
	$body/honker.hide()
	$"body/arms pivot/left arm pivot/left arm".hide()
	$body/pill.hide()
	$"body/arms pivot/right arm".hide()
	$"body/legs pivot".hide()
	normalSpeed = 5.0
	sprintSpeed = 10.0
	SPEED = normalSpeed
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera.rotation.x -= event.relative.y * SENSITIVITY
		camera.rotation.y += -event.relative.x * SENSITIVITY
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		self.rotation.y += -event.relative.x * SENSITIVITY
	if event is InputEventMouseButton && Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var horizontalVelocity = sqrt(abs(velocity.x)**2 + abs(velocity.z)**2)
	#UI.wallJumpsLeftLabel.text = "Wall Jumps Left: " + str(wallJumpsleft)
	#UI.jumpsLeftLabel.text = "Jumps Left: " + str(jumpsLeft)
	#UI.dashesLeftLabel.text = "Dashes Left: " + str(dashesLeft)
	#UI.extraSuperJumpVelLabel.text = "Extra Super Jump Velocity: " + str(extraSuperJumpVelocity)
	
	if is_on_floor():
		$"body/legs pivot/leg 1".rotation.x = deg_to_rad(0)
		$"body/legs pivot/leg 2".rotation.x = deg_to_rad(0)
		
	if is_on_wall_only() && prevOnWall == false:
		someOtherBool = false
		noiseMaker.airNoise.stop()
		noiseMaker.airNoiseTimer.stop()
		prevOnWall = true
		wallJumpVelocity = horizontalVelocity
		await get_tree().create_timer(0.7).timeout
		wallJumpVelocity = 7/5
		if dashesLeft < 2:
			dashesLeft += 1

	if !is_on_wall_only():
		wallJumpVelocity = 7/5
		prevOnWall = false

	if is_on_floor() && prevOnFloor == false:
		prevOnFloor = true
		extraSuperJumpVelocity = prevVerticalVelocity + 38/5
		noiseMaker.touchedGroundNoise.play()

	if !is_on_floor():
		prevOnFloor = false



	if not is_on_floor():
		velocity += get_gravity() * gravityModifier * delta
	if is_on_floor():
		someOtherBool = false
		noiseMaker.airNoise.stop()
		noiseMaker.airNoiseTimer.stop()
		wallJumpsleft = 2
		jumpsLeft = 2
		dashesLeft = 2
		if groundPounding == true:
			groundPounding = false
			if youWasSpeedy == true:
				#$"../touched ground with speed".play()
				allowSpeedySuperJump = true
				body.scale.y *= 0.8
			else:
				allowSuperJump = true
				body.scale.y *= 0.8
			youWasSpeedy = false
			await get_tree().create_timer(superJumpWindow).timeout
			body.scale.y /= 1
			allowSpeedySuperJump = false
			allowSuperJump = false

	if !is_on_floor() && someOtherBool == false:
		someOtherBool = true
		noiseMaker.airNoiseTimer.start()

	##jump
	if Input.is_action_just_pressed("jump"):
		leg_switch(horizontalVelocity)
		#print("wall jumps left is: ", wallJumpsleft)
		#print("jumps left is: ", jumpsLeft)
		if allowSpeedySuperJump:
			noiseMaker.speedySuperJumpNoise.play()
			if extraSuperJumpVelocity > -17/5:
				extraSuperJumpVelocity -= 10/5
			print ("super speed yupser jump")
			velocity = youWasSpeedyVelocity * 2
			velocity.y = ((jumpVelocity * -40/get_gravity().y) - extraSuperJumpVelocity)/2
			allowSpeedySuperJump = false
		elif allowSuperJump:
			noiseMaker.superJumpNoise.play()
			if extraSuperJumpVelocity > -17/5:
				extraSuperJumpVelocity -= 10/5
			velocity.y = ((jumpVelocity * -40/get_gravity().y) - extraSuperJumpVelocity)/2
			allowSuperJump = false
		elif is_on_wall_only() && wallJumpsleft > 0:
			noiseMaker.wallJumpNoise.play()
			wallJumpDirection = get_wall_normal()
			velocity = wallJumpDirection * wallJumpVelocity
			holdJumpTimer = 1
			velocity.y = (jumpVelocity * -40/get_gravity().y)/2 ##default value is -40, so jump is affected by negative gravity properly
			wallJumpsleft -= 1
			jumpsLeft = 1
		else:
			if jumpsLeft > 0:
				noiseMaker.jumpNoise.play()
				holdJumpTimer = 1
				velocity.y = (jumpVelocity * -40/get_gravity().y)/2 ##default value is -40, so jump is affected by negative gravity properly
				jumpsLeft -= 1
			
	if Input.is_action_pressed("jump") and holdJumpTimer < 20 and holdJumpTimer != 0:
		$"body/arms pivot".rotation.x = deg_to_rad(10)
		holdJumpTimer += 1
		velocity.y += 0.3/5
	else:
		$"body/arms pivot".rotation.x = 0
		holdJumpTimer = 0
#
	###sprinting
	if Input.is_action_pressed("sprint"):
		if SPEED < sprintSpeed:
			SPEED += 0.4
	else:
		if SPEED > normalSpeed:
			SPEED -=0.8

	if Input.is_action_just_pressed("groundpound") && !is_on_floor():
		noiseMaker.groundPoundNoise.play()
		leg_switch(horizontalVelocity)
		velocity.y = 0
		velocity/=2
		await get_tree().create_timer(0.2).timeout
		velocity.y = -45/5
		if horizontalVelocity > 15/5:
			print("youwasspeedyt")
			youWasSpeedy = true
			youWasSpeedyVelocity = get_real_velocity() ##apparently this takes into account diagonals better
		groundPounding = true

	if Input.is_action_just_pressed("dash") && dashesLeft > 0 && !is_on_floor():
		noiseMaker.dashNoise.play()
		leg_switch(horizontalVelocity)
		velocity.x = 30/2 * camera.project_ray_normal(get_viewport().get_mouse_position()).x
		velocity.y = 10/2 * camera.project_ray_normal(get_viewport().get_mouse_position()).y
		velocity.z = 30/2 * camera.project_ray_normal(get_viewport().get_mouse_position()).z
		dashesLeft -= 1
		jumpsLeft += 1
		
	##moving, air accel and decel
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = (direction.rotated(Vector3.UP, camera.rotation.y).normalized())
	if direction != Vector3.ZERO:
		var looking_direction = direction.normalized()
		body.basis = Basis.looking_at(looking_direction)
	if is_on_floor():
		if direction:
			if isWalkPlaying == false:
				noiseMaker.walkNoise.play()
				isWalkPlaying = true
			velocity.x = move_toward(velocity.x, direction.x * SPEED, SPEED)
			velocity.z = move_toward(velocity.z, direction.z * SPEED, SPEED)
			#print(SPEED)
		else:
			noiseMaker.walkNoise.stop()
			isWalkPlaying = false
			velocity.x = move_toward(velocity.x, 0, floorDecelaration)
			velocity.z = move_toward(velocity.z, 0, floorDecelaration)
	elif not is_on_floor():
		noiseMaker.walkNoise.stop()
		isWalkPlaying = false
		if direction:
			if horizontalVelocity < SPEED:
				##if we are in the air, inputting movement and below target speed, accelerate towards it
				velocity.x = move_toward(velocity.x, direction.x * SPEED, airAcceleration)
				velocity.z = move_toward(velocity.z, direction.z * SPEED, airAcceleration)
			elif floor(horizontalVelocity) > SPEED:
				##if we are in the air, inputting movement, and above target speed, accelerate towards terminal speed
				velocity.x = move_toward(velocity.x, direction.x * terminalSpeed, airAcceleration)
				velocity.z = move_toward(velocity.z, direction.z * terminalSpeed, airAcceleration)
			else:
				##else we still in between speed + 7 and speed then we still need to be able to move
				velocity.x = move_toward(velocity.x, direction.x * SPEED, airAcceleration)
				velocity.z = move_toward(velocity.z, direction.z * SPEED, airAcceleration)
		elif horizontalVelocity < SPEED:
			##if we are not moving and we are below target speed, decelerate to 0
			velocity.x = move_toward(velocity.x, 0, airAcceleration/20)
			velocity.z = move_toward(velocity.z, 0, airAcceleration/20)
	prevHorizontalVelocity = horizontalVelocity
	prevVerticalVelocity = velocity.y
	#print(horizontalVelocity)
	#prints("sprint speed: ", sprintSpeed, "normal speed: ", normalSpeed, "current speed: ", horizontalVelocity, "SPEED: ", SPEED)
	move_and_slide()

func leg_switch(horizontalVelocity):
	legSwitch = !legSwitch
	var balls = 1
	if legSwitch == true:
		balls = -1
	$"body/legs pivot/leg 1".rotation.x = deg_to_rad(balls * -30)
	$"body/legs pivot/leg 2".rotation.x = deg_to_rad(balls * 30)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("player entered")
		$"../win".playing = true
		$UI.notWon = false

func _on_air_noise_timer_timeout() -> void:
	noiseMaker.airNoise.play()
