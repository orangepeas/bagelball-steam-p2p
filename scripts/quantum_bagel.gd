extends Bagel

func quantum_switch():
	player.global_position.x = self.global_position.x - 2
	player.global_position.y = self.global_position.y
	player.global_position.z = self.global_position.z - 2
