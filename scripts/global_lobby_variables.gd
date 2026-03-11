extends Node
##the enums are here so they can be accessed from any script, they dont store anything
enum generalOptions {
	Gravity,
	Match_Length,
	Engine_Timescale,
	Map_Scale,
	Scroll_Throw
}
enum bagelOptions {
	Size_Scale,
	Bounciness,
	Weight_When_Held,
	Weight_When_Not_Held,
	Friction,
}
enum ballOptions {
	Size_Scale,
	Bounciness,
	Weight,
	Friction,
}
enum playerOptions {
	Normal_Speed,
	Sprint_Speed,
	Max_Speed,
	Jump_Velocity,
	Wall_Jump_Velocity,
	Air_Acceleration,
	Floor_Deceleration,
	Size_Scale,
	Jumps,
}
##DONT USE the ENUMS TO SET VALUES, theyre only there to share between scripts
##lobby_menu_v2.gd on start_game()
var gravity : LobbyVariable = LobbyVariable.new(GLV.generalOptions.Gravity, 40.0)
##score_display.gd
var matchLength : LobbyVariable = LobbyVariable.new(GLV.generalOptions.Match_Length, 300.0)
##goal_score.gd
var engineTimescale : LobbyVariable = LobbyVariable.new(GLV.generalOptions.Engine_Timescale, 1.0)
##scene_manager.gd & goalscore.gd to fix dome map
var mapScale : LobbyVariable = LobbyVariable.new(GLV.generalOptions.Map_Scale, 1.0)
##player.gd
var scrollThrow : LobbyVariable = LobbyVariable.new(GLV.generalOptions.Scroll_Throw, false)
var generalOptionsList = [gravity,matchLength,engineTimescale,mapScale,scrollThrow]

var quantumBagels := false

##all ball.gd
var ballSizeScale : LobbyVariable = LobbyVariable.new(GLV.ballOptions.Size_Scale, 1.0)
var ballBounciness : LobbyVariable = LobbyVariable.new(GLV.ballOptions.Bounciness, 0.3)
var ballWeight : LobbyVariable = LobbyVariable.new(GLV.ballOptions.Weight, 4.2)
var ballFriction : LobbyVariable = LobbyVariable.new(GLV.ballOptions.Friction, 1.0)
var ballOptionsList = [ballSizeScale,ballBounciness,ballWeight]

##all bagel.gd
var bagelSizeScale : LobbyVariable = LobbyVariable.new(GLV.bagelOptions.Size_Scale, 1.0)
var bagelBounciness : LobbyVariable = LobbyVariable.new(GLV.bagelOptions.Bounciness, 0.2)
var bagelWeightWhenHeld : LobbyVariable = LobbyVariable.new(GLV.bagelOptions.Weight_When_Held, 0.8)
var bagelWeightWhenNotHeld : LobbyVariable = LobbyVariable.new(GLV.bagelOptions.Weight_When_Not_Held, 15)
var bagelFriction : LobbyVariable = LobbyVariable.new(GLV.bagelOptions.Friction, 1.0)
var bagelOptionsList = [bagelSizeScale,bagelBounciness,bagelWeightWhenHeld,bagelWeightWhenNotHeld,bagelFriction]

##all player.gd
var playerNormalSpeed : LobbyVariable = LobbyVariable.new(GLV.playerOptions.Normal_Speed, 60.0)
var playerSprintSpeed : LobbyVariable = LobbyVariable.new(GLV.playerOptions.Sprint_Speed, 90.0)
var playerMaxSpeed : LobbyVariable = LobbyVariable.new(GLV.playerOptions.Max_Speed, 150.0)
var playerJumpVelocity : LobbyVariable = LobbyVariable.new(GLV.playerOptions.Jump_Velocity, 45.0)
var playerWallJumpVelocity : LobbyVariable = LobbyVariable.new(GLV.playerOptions.Wall_Jump_Velocity, 120.0)
var playerAirAcceleration : LobbyVariable = LobbyVariable.new(GLV.playerOptions.Air_Acceleration, 10.0)
var playerFloorDeceleration : LobbyVariable = LobbyVariable.new(GLV.playerOptions.Floor_Deceleration, 5.0)
var playerSizeScale : LobbyVariable = LobbyVariable.new(GLV.playerOptions.Size_Scale, 1.0)
var playerJumps : LobbyVariable = LobbyVariable.new(GLV.playerOptions.Jumps, 2)


var playerOptionsList = [playerNormalSpeed,playerSprintSpeed,playerMaxSpeed,playerJumpVelocity,playerWallJumpVelocity,playerAirAcceleration,playerFloorDeceleration,playerSizeScale,playerJumps]
