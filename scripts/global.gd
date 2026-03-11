extends Node

var players = {}
var redScore : int = 0
var blueScore : int = 0
var isPaused : bool = false
var ballRespawnPoint : Vector3
var currentLobby : int
var lobbyHostID : int
var practiceModeBool
var maxPlayers : int = 2
enum Map {
	warehouse,
	bagel,
	cylinder,
	dome,
	vents,
	sumo,
	sumo2,
	sisyphus,
	dome_goalflip,
	church
}
var map
var lobbies = {}
var singleplayer : bool = false
var funnyMode : bool = false
var FOV := 75.0
var sensitivity := 0.003
var kFactor = 20
var yourElo:int
var theirElo:int
var holdSprint := true
var autoSprint := false

signal redScored                ##connects to score_display.gd, player.gd, ball.gd and scoreboard.gd from goal_score.gd
signal blueScored               ##connects to score_display.gd, player.gd, ball.gd and scoreboard.gd from goal_score.gd
signal playBlueScoreNoise       ##connects to player_ui.gd from goal_score.gd
signal playBlueConcedeNoise     ##connects to player_ui from goal_score
signal playRedScoreNoise        ##connects to player_ui from goal_score
signal playRedConcedeNoise      ##connects to player_ui from goal_score
signal playerTouchWall          ##connects to player.gd from goal_score.gd
signal playerNoTouchWall        ##connects to player.gd from goal_score.gd
signal gameEnd                  ##connects to goal_score.gd, alot from score_display.gd
signal gameStart                ##connects to alot from score_display.gd (technically a game restart not a game start)
signal goldenGoal               ##connects to goal_score.gd from score_display.gd
signal endGoldenGoal            ##connects to goal_score.gd, alot from score_display.gd
signal pauseScreenLeaveLobby    ##connects to client.gd from pause_screen.gd
signal backToMainMenu           ##connects to main_menu.gd from pause_screen.gd and client.gd
signal practiceMode             ##connects to player_ui.gd and bagel.gd from main_menu.gd
signal oneVone                  ##connects to absolutely nothing from lobby_menu.gd
signal twoVtwo                  ##connects to absolutely nothing from lobby_menu.gd
signal hideTitleImages          ##connects to main_menu.gd from lobby_menu_v_2.gd
signal muteTitleMusic           ##connects to main_menu.gd from lobby_menu_v_2.gd
signal levelFinishedLoading     ##connects to ball.gd, player.gd from scene_manager.gd
signal disableOneWayBagelMap    ##connects to goal_score.gd from player.gd
signal enableOneWayBagelMap     ##connects to goal_score.gd from player.gd
signal fovChange                ##connects to player.gd from video_settings.gd
signal startGameTimer           ##connects to score_display.gd from what john you forgot to write what
signal sensChange               ##connects to player.gd from settings.gd
signal gameCountdown            ##connects to score_display.gd & noise_maker.gd from player_ui.gd
signal closeGoals               ##connects to goal_score.gd from score_display.gd
signal gameCountdownNoises      ##connects to noise_maker.gd from player_ui.gd

signal youSalmon(id:int)        ##connects to noise_maker.gd from insult_selector.gd
signal youMackerel(id:int)      ##connects to noise_maker.gd from insult_selector.gd
signal absoluteMollusc(id:int)  ##connects to noise_maker.gd from insult_selector.gd
signal bloodyTrout(id:int)      ##connects to noise_maker.gd from insult_selector.gd
signal slimyWorm(id:int)        ##connects to noise_maker.gd from insult_selector.gd
signal soggyBagel(id:int)       ##connects to noise_maker.gd from insult_selector.gd
#signal joinGamePartwayThrough   ##connects to scene_manager.gd from client.gd
##too difficult to implement

func _ready() -> void:
	OS.set_environment("SteamAppID", str(3620440))
	OS.set_environment("SteamGameID", str(3620440))
	Steam.steamInit(3620440)
	if Steam.getSteamID() == 76561197977486399 or Steam.getSteamID() == 76561198982262924 or Steam.getSteamID() == 76561199112943203:
		var achievement = Steam.getAchievement("truebagelballchampion")
		if achievement.ret && !achievement.achieved:
			Steam.setAchievement("truebagelballchampion")
			Steam.storeStats() ##need to call this to fire the stat

func _process(delta: float) -> void:
	Steam.run_callbacks()
