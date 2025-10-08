extends Node

#this node will contain global variables and useful functions

var PLAYER_MANAGER_ID:int = 0
var TRAP_MANAGER_ID:int = 1


##this will pass the possible tiles back
##now tile validation will have to come from whoever makes the tiles
# func get_bfs_range(start_pos: Vector2i, _range: int, tilemap_layer: TileMapLayer) -> Array[Vector2i]:
func get_bfs_range(start_pos: Vector2i, _range: int) -> Array[Vector2i]:
	var frontier: Array[Vector2i] = [start_pos]
	var visited: Dictionary = {start_pos: 0} # Use a Dictionary to store distance
	var valid_tiles: Array[Vector2i] = [start_pos]

	var head = 0
	while head < frontier.size():
		var current_pos = frontier[head]
		head += 1

		var current_dist = visited[current_pos]
		if current_dist >= _range:
			continue

		# Check neighbors (up, down, left, right)
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor_pos = current_pos + direction
			if not visited.has(neighbor_pos):
				# YOUR LOGIC HERE: Check if the neighbor is a valid, non-blocking tile.
				# Example: if tilemap_layer.get_cell_source_id(neighbor_pos) != WALL_TILE:
				# The layer index (0) is no longer needed.
				visited[neighbor_pos] = current_dist + 1
				frontier.append(neighbor_pos)
				valid_tiles.append(neighbor_pos)

	return valid_tiles

##now we need to transfer patterns into a TileArray
func get_scaled_pattern_tiles(origin: Vector2i, pattern: Pattern2D, distance: int, tilemap_layer: TileMapLayer) -> Array[Vector2i]:
	var valid_tiles: Array[Vector2i] = []
	if not pattern:
		# If no pattern is provided, return an empty array.
		return valid_tiles

	# Ensure distance is at least 1 to prevent the pattern from collapsing to a single point.
	# A distance of 1 will use the pattern as-is.
	var effective_distance = max(1, distance)

	for offset in pattern.affected_tiles:
		# Scale the pattern's offset vector by the given distance.
		var scaled_offset = (offset * effective_distance).round()
		var target_pos = origin + Vector2i(scaled_offset)

		# Check if the target cell on the given tilemap layer actually exists (is not empty).
		# The layer index (0) is no longer needed as we are passed the specific layer.
		if tilemap_layer.get_cell_source_id(target_pos) != -1:
			valid_tiles.append(target_pos)

	return valid_tiles

func get_3d_vectors() -> Array[Vector3i]:
	return [
		Vector3i.UP + Vector3i.LEFT,
		Vector3i.UP + Vector3i.LEFT + Vector3i.FORWARD,
		Vector3i.UP + Vector3i.LEFT + Vector3i.BACK,
		Vector3i.UP,
		Vector3i.UP + Vector3i.FORWARD,
		Vector3i.UP + Vector3i.BACK,
		Vector3i.UP + Vector3i.RIGHT,
		Vector3i.UP + Vector3i.RIGHT + Vector3i.FORWARD,
		Vector3i.UP + Vector3i.RIGHT + Vector3i.BACK,
		Vector3i.LEFT,
		Vector3i.LEFT + Vector3i.FORWARD,
		Vector3i.LEFT + Vector3i.BACK,
		Vector3i.FORWARD,
		Vector3i.BACK,
		Vector3i.RIGHT,
		Vector3i.RIGHT + Vector3i.FORWARD,
		Vector3i.RIGHT + Vector3i.BACK,
		Vector3i.DOWN + Vector3i.LEFT,
		Vector3i.DOWN + Vector3i.LEFT + Vector3i.FORWARD,
		Vector3i.DOWN + Vector3i.LEFT + Vector3i.BACK,
		Vector3i.DOWN,
		Vector3i.DOWN + Vector3i.FORWARD,
		Vector3i.DOWN + Vector3i.BACK,
		Vector3i.DOWN + Vector3i.RIGHT,
		Vector3i.DOWN + Vector3i.RIGHT + Vector3i.FORWARD,
		Vector3i.DOWN + Vector3i.RIGHT + Vector3i.BACK	
	]

func get_2d_euclidean_distance(origin:Vector2i, target:Vector2i) -> float:
	return sqrt(pow(origin.x-target.x, 2)+pow(origin.y-target.y, 2))
	
func get_3d_euclidean_distance(origin:Vector3i, target:Vector3i) -> float:
	return sqrt(pow(origin.x-target.x, 2)+pow(origin.y-target.y, 2)+pow(origin.z-target.z, 2))
