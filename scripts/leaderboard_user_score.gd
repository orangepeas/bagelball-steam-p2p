extends Panel

func setup_leaderboard_score(rank,name,score):
	$HBoxContainer/Rank.text = str(rank)
	$HBoxContainer/Name.text = name
	$HBoxContainer/Score.text = str(score)
