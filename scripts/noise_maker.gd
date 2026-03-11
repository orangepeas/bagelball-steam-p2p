extends Node3D

@onready var rng := RandomNumberGenerator.new()

func _ready() -> void:
	global.connect("playBlueConcedeNoise", play_blue_concede_noise)
	global.connect("playBlueScoreNoise", play_blue_score_noise)
	global.connect("playRedConcedeNoise", play_red_concede_noise)
	global.connect("playRedScoreNoise", play_red_score_noise)
	global.connect("gameCountdown", play_countdown_noises)
	global.connect("gameCountdownNoises", play_countdown_noises)
	
	global.absoluteMollusc.connect(absolute_mollusc)
	global.connect("bloodyTrout",bloody_trout)
	global.connect("youMackerel",you_mackerel)
	global.connect("youSalmon",you_salmon)
	global.connect("slimyWorm",slimy_worm)
	global.connect("soggyBagel",soggy_bagel)

func play_blue_score_noise():
	if $"..".spectator == false:
		if $"..".redTeam == false:
			$"Goal Score Noise".play()
		#print("redteam = " + str($"..".redTeam) + " blue score noise")
	if $"..".spectator == true:
		$"Goal Score Noise".play()

func play_blue_concede_noise():
	if $"..".spectator == false:
		if $"..".redTeam == false:
			$"Goal Concede Noise".play()
		#print( "redteam = " + str($"..".redTeam)+ " blue concede noise" + " player = " + $"..".name)

func play_red_score_noise():
	if $"..".spectator == false:
		if $"..".redTeam == true:
			$"Goal Score Noise".play()
		#print( "redteam = " + str($"..".redTeam)+ " red score noise" + " player = " + $"..".name)
	if $"..".spectator == true:
		$"Goal Score Noise".play()

func play_red_concede_noise():
	if $"..".spectator == false:
		if $"..".redTeam == true:
			$"Goal Concede Noise".play()
		#print("redteam = " + str($"..".redTeam) + " red concede noise")

func play_red_win_noises():
	if $"..".redTeam == true:
		$"Win Noise".play()
	elif $"..".redTeam == false:
		$"Lose Noise".play()

func play_blue_win_noises():
	if $"..".redTeam == true:
		$"Lose Noise".play()
	elif $"..".redTeam == false:
		$"Win Noise".play()

func _on_player_ui_blue_win_noises() -> void:
	play_blue_win_noises()

func _on_player_ui_red_win_noises() -> void:
	play_red_win_noises()

func play_wall_touch_noise():
	$"Wall Touch Noise".play()

func play_floor_touch_noise():
	$"Floor Touch Noise".play()

func play_jump_noise():
	$"Jump Noise".pitch_scale = rng.randf_range(0.7,0.71)
	$"Jump Noise".play()

func play_countdown_noises():
	$Three.play()
	await get_tree().create_timer(1).timeout
	$Two.play()
	await get_tree().create_timer(1).timeout
	$One.play()
	await get_tree().create_timer(1).timeout
	$Bagelball.play()

@rpc("any_peer","call_local")
func absolute_mollusc_rpc(id : int):
	if $"..".name == str(id) or global.singleplayer == true:
		$"Absolute Mollusc".play()
@rpc("any_peer","call_local")
func bloody_trout_rpc(id : int):
	if $"..".name == str(id) or global.singleplayer == true:
		$"Bloody Trout".play()
@rpc("any_peer","call_local")
func you_mackerel_rpc(id : int):
	if $"..".name == str(id) or global.singleplayer == true:
		$"You Mackerel".play()
@rpc("any_peer","call_local")
func you_salmon_rpc(id : int):
	if $"..".name == str(id) or global.singleplayer == true:
		$"You Salmon".play()
@rpc("any_peer","call_local")
func slimy_worm_rpc(id : int):
	if $"..".name == str(id) or global.singleplayer == true:
		$"Slimy Worm".play()
@rpc("any_peer","call_local")
func soggy_bagel_rpc(id : int):
	if $"..".name == str(id) or global.singleplayer == true:
		$"Soggy Bagel".play()

func absolute_mollusc(id : int) -> void:
	absolute_mollusc_rpc.rpc(id)
func bloody_trout(id : int) -> void:
	bloody_trout_rpc.rpc(id)
func you_mackerel(id : int) -> void:
	you_mackerel_rpc.rpc(id)
func you_salmon(id : int) -> void:
	you_salmon_rpc.rpc(id)
func slimy_worm(id : int) -> void:
	slimy_worm_rpc.rpc(id)
func soggy_bagel(id : int) -> void:
	soggy_bagel_rpc.rpc(id)
