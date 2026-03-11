extends Control

var scoreboardShowing : bool = false
@onready var individualScene = preload("res://scenes/scoreboard_individual.tscn")
@onready var redScoreboard = $Scoreboard/ScoreboardRed/VBoxContainer
@onready var blueScoreboard = $Scoreboard/ScoreboardBlue/VBoxContainer

func _ready() -> void:
	global.connect("blueScored", update_scoreboard_goals)
	global.connect("redScored", update_scoreboard_goals)
	await get_tree().create_timer(0.2).timeout ##else it populates without players loading in, will be fixed
	##with addition of warmup
	populate_scoreboards()


func populate_scoreboards():
	for r in redScoreboard.get_children():
		r.queue_free()
	for b in redScoreboard.get_children():
		b.queue_free()
	for playerId in global.players:
		var individualPlayer = individualScene.instantiate()
		individualPlayer.size_flags_vertical = SIZE_EXPAND_FILL
		var playerNameLabel = individualPlayer.find_child("LabelPlayerName")
		var playerGoalsLabel = individualPlayer.find_child("LabelPlayerGoals")
		individualPlayer.playerID = playerId
		playerNameLabel.text = str(global.players[playerId].displayName)
		playerGoalsLabel.text = str(int(global.players[playerId].goals))
		if str(int(playerId)) == str(multiplayer.get_unique_id()):
			#prints(str(global.players[playerId]), str(multiplayer.get_unique_id()))
			if playerNameLabel.text == "":
				playerNameLabel.text += "(me)"
			else:
				playerNameLabel.text += " (me)"
		
		for player in get_tree().get_nodes_in_group("player"):
			#prints("player facts: red team:", player.redTeam,"player name:",player.name, "playerId",playerId)
			if player.name == str(playerId):
				if player.redTeam == true:
					redScoreboard.add_child(individualPlayer)
				elif player.redTeam == false:
					blueScoreboard.add_child(individualPlayer)

	if blueScoreboard.get_child_count() > 1: ##2v2
		blueScoreboard.get_parent().custom_minimum_size.y = blueScoreboard.get_child_count() * blueScoreboard.get_children()[0].find_child("VBoxContainer").size.y + 20
	if redScoreboard.get_child_count() > 1:
		redScoreboard.get_parent().custom_minimum_size.y = redScoreboard.get_child_count() * redScoreboard.get_children()[0].find_child("VBoxContainer").size.y + 20
	if global.players.size() == 1: ##for practice mode
		redScoreboard.get_parent().queue_free() 
		$Scoreboard.size.y = $Scoreboard.size.y

func update_scoreboard_goals():
	for playerId in global.players:
		if !global.singleplayer:
			for r in redScoreboard.get_children():
				if r.playerID == int(playerId):
					r.find_child("LabelPlayerGoals").text = str(int(global.players[playerId].goals))
		for b in blueScoreboard.get_children():
			if b.playerID == int(playerId):
				b.find_child("LabelPlayerGoals").text = str(int(global.players[playerId].goals))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("scoreboard"):
		if scoreboardShowing == false:
			self.show()
			scoreboardShowing = true
	if event.is_action_released("scoreboard"):
		if scoreboardShowing == true:
			self.hide()
			scoreboardShowing = false
