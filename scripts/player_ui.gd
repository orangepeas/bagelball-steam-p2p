extends Control

var noisePlaying : bool  = false ##ive included this cos for some reason it runs the game_end thing a bajillion times
var goldenGoal : bool = false
var stopRecursingPlease := false

signal redWinNoises
signal blueWinNoises

signal youSalmon
signal youMackerel
signal absoluteMollusc
signal bloodyTrout
signal slimyWorm

@onready var PauseScreen = $"Pause Screen"

func _ready() -> void:
	global.connect("gameEnd", game_end)
	global.connect("gameStart", game_start)
	global.connect("goldenGoal", golden_goal)
	global.connect("endGoldenGoal", end_golden_goal)
	global.connect("gameCountdown", game_countdown)
	#global.connect("practiceMode", practice_mode)
	$"Pause Screen".hide()
	#get_tree().create_timer(0.2).timeout
	#self.set_multiplayer_authority($"..".mpSync.get_multiplayer_authority())

#func practice_mode():
	

func game_end():
	if global.blueScore > global.redScore && noisePlaying == false:
		blue_win()
	if global.blueScore < global.redScore && noisePlaying == false:
		red_win()
	if global.blueScore == global.redScore && noisePlaying == false:
		golden_goal()

func game_start():
	if global.map == global.Map.sisyphus && stopRecursingPlease == false:
		stopRecursingPlease = true
		global.goldenGoal.emit()
	if goldenGoal == false:
		$"win message".text = ""
		$"Game Timer".start()
	else:
		$"Game Timer".stop()

func blue_win():
	$"win message".label_settings.font_color = Color(0,150,255,255)
	$"win message".text = "BLUE HAS REACHED THE PEARLY GATES OF HEAVEN"
	blueWinNoises.emit()

func red_win():
	$"win message".label_settings.font_color = Color(255,0,0,255)
	$"win message".text = "RED HAS REACHED THE PEARLY GATES OF HEAVEN"
	redWinNoises.emit()

func golden_goal():
	goldenGoal = true
	await get_tree().create_timer(2).timeout
	stopRecursingPlease = false

func end_golden_goal():
	goldenGoal = false

func _on_score_display_initiate_golden_goal() -> void:
	$"win message".label_settings.font_color = Color(0,0,0,255)
	$"win message".text = "NOBODY HAS REACHED THE PEARLY GATES OF HEAVEN"
	await get_tree().create_timer(2).timeout
	$"win message".text = "INITIATING GOLDEN GOAL."
	await get_tree().create_timer(0.5).timeout
	$"win message".text = "INITIATING GOLDEN GOAL.."
	await get_tree().create_timer(0.5).timeout
	$"win message".text = "INITIATING GOLDEN GOAL..."
	await get_tree().create_timer(0.5).timeout
	global.gameCountdownNoises.emit()
	$"win message".text = "3"
	await get_tree().create_timer(1).timeout
	$"win message".text = "2"
	await get_tree().create_timer(1).timeout
	$"win message".text = "1"
	await get_tree().create_timer(1).timeout
	$"win message".label_settings.outline_size = 10
	$"win message".text = "REACH THE PEARLY GATES!"
	global.goldenGoal.emit()
	await get_tree().create_timer(1).timeout
	$"win message".text = ""
	$"win message".label_settings.outline_size = 0

func game_countdown():
	$"win message".label_settings.font_color = Color(0,0,0,255)
	$"win message".text = "3"
	await get_tree().create_timer(1).timeout
	$"win message".text = "2"
	await get_tree().create_timer(1).timeout
	$"win message".text = "1"
	await get_tree().create_timer(1).timeout
	$"win message".text = "bagelball"
	await get_tree().create_timer(0.7).timeout
	$"win message".text = ""


func _on_insult_selector_absolute_mollusc() -> void:
	absoluteMollusc.emit()

func _on_insult_selector_bloody_trout() -> void:
	bloodyTrout.emit()

func _on_insult_selector_slimy_worm() -> void:
	slimyWorm.emit()

func _on_insult_selector_you_mackerel() -> void:
	youMackerel.emit()

func _on_insult_selector_you_salmon() -> void:
	youSalmon.emit()
