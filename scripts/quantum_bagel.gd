extends Bagel

@onready var teleport_noise : AudioStreamPlayer3D = $TeleportNoise
@onready var starting_db = teleport_noise.volume_db

func quantum_switch():
	player.global_position.x = self.global_position.x - 2
	player.global_position.y = self.global_position.y
	player.global_position.z = self.global_position.z - 2
	play_teleport_noise.rpc()

@rpc("any_peer","call_local")
func play_teleport_noise():
	teleport_noise.pitch_scale = randf_range(0.95,1.05)
	teleport_noise.volume_db = randf_range(0.95,1.05) * starting_db
	teleport_noise.play()
