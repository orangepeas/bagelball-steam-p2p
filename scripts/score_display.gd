extends Control

var goldenGoal : bool = false
var practiceModeBool : bool = false
var warmup : bool = true

@onready var blueScoreDisplay = $"MarginContainer/HBoxContainer/blue score"
@onready var redScoreDisplay = $"MarginContainer/HBoxContainer/red score"

signal initiateGoldenGoal

func _ready() -> void:
	global.blueScored.connect(blue_scored)
	global.redScored.connect(red_scored)
	global.gameStart.connect(game_start)
	global.gameEnd.connect(game_end)
	global.goldenGoal.connect(golden_goal_start)
	global.endGoldenGoal.connect(golden_goal_end)
	global.practiceMode.connect(practice_mode)
	print("GLV  match length is = ", GLV.matchLength.value)
	$"../Game Timer".wait_time = GLV.matchLength.value
	$"Timer Display".text = "∞"
	#$"../Game Timer".start()

func golden_goal_start():
	goldenGoal = true
	await get_tree().process_frame
	$"Timer Display".text = "∞"

func golden_goal_end():
	goldenGoal = false

##technically game restart rather than start
func game_start():
	warmup = false
	if goldenGoal == false:
		$"../Game Timer".start()
	blueScoreDisplay.text = "0"
	redScoreDisplay.text = "0"

func blue_scored():
	blueScoreDisplay.text = str(global.blueScore)

func red_scored():
	redScoreDisplay.text = str(global.redScore)

func _process(_delta):
	##the timer displays 4:60 instead of 5:00 for some reason
	if goldenGoal == false && practiceModeBool == false && warmup == false:
		var time_left = $"../Game Timer".time_left
		var minutes = floor(time_left/60)
		var seconds = ceil(time_left - minutes*60)
		$"Timer Display".text = str(int(minutes)) + ":" + str(int(seconds))
		if seconds < 10:
			$"Timer Display".text = str(int(minutes)) + ":" + "0" + str(int(seconds))

func practice_mode():
	$"Timer Display".text = "∞"
	practiceModeBool = true
	$"../Game Timer".stop()

func _on_game_timer_timeout() -> void:
	if global.blueScore == global.redScore:
		initiateGoldenGoal.emit()
	else:
		global.gameEnd.emit() ##connects to player_ui and others
	global.closeGoals.emit()

func game_end():
	global.endGoldenGoal.emit() ##just in case
	await get_tree().create_timer(10).timeout
	global.gameStart.emit()
