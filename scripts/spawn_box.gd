extends CollisionShape3D

enum Team {
	red,
	blue,
	green
}

@export var team : Team

func get_spawn_point_array(playerCount : int) -> Array:
	var spawnPointArray : Array
#	print("player count is ", playerCount)
	for nMinusOne in playerCount:
		var n = nMinusOne + 1
#		print("n = ",n)
#		print("pos.z = ", self.global_position.z, "size.z/2 = ", shape.size.z/2, "nsize.z/n+1 = ", (n)*(shape.size.z/(playerCount + 1)))
		var zCoord = self.global_position.z - shape.size.z/2 + (n)*(shape.size.z/(playerCount + 1))
		var spawnPoint : Vector3 = Vector3(global_position.x, global_position.y, zCoord)
#		print("spawn point is ", spawnPoint)
		spawnPointArray.append(spawnPoint)
	return spawnPointArray
