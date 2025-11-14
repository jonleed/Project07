extends Node

#this node will contain global variables and useful functions
var party_units:Array
var LOW_HEALTH_THRESHOLD:int = 2
var MID_HEALTH_THRESHOLD:int = 4
var THREATENING_DISTANCE:float = 10
var SUMMONING_DISTANCE:float = 20

## Calculates reachable tiles using Breadth-First Search, respecting obstacles
## defined in the MapManager's dictionary.
func get_bfs_empty_tiles(start_pos: Vector2i, _range: int, map_manager: MapManager) -> Array[Vector2i]:
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

			# NEW LOGIC: A tile is valid for movement if it hasn't been visited AND
			# it does not exist as a key in the map_dict (meaning it's not a wall or entity).
			if not visited.has(neighbor_pos) and not map_manager.map_dict.has(neighbor_pos) and map_manager.get_surface_tile(neighbor_pos) != MapManager.TileType.Air:
				
				visited[neighbor_pos] = current_dist + 1
				frontier.append(neighbor_pos)
				valid_tiles.append(neighbor_pos)

	return valid_tiles

func get_bfs_tiles(start_pos: Vector2i, _range: int, map_manager: MapManager) -> Array[Vector2i]:
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

			# NEW LOGIC: A tile is valid for movement if it hasn't been visited AND
			# it does not exist as a key in the map_dict (meaning it's not a wall or entity).
			if not visited.has(neighbor_pos) and map_manager.get_surface_tile(neighbor_pos) != MapManager.TileType.Air:
				
				visited[neighbor_pos] = current_dist + 1
				frontier.append(neighbor_pos)
				valid_tiles.append(neighbor_pos)

	return valid_tiles

## Gets all tiles affected by a scaled pattern, checking for validity
## using the MapManager's surface tile data.
func get_scaled_pattern_tiles(origin: Vector2i, pattern: Pattern2D, distance: int, map_manager: MapManager) -> Array[Vector2i]:
	var valid_tiles: Array[Vector2i] = []
	if not pattern:
		return valid_tiles # Return empty if no pattern is provided.

	var effective_distance = max(1, distance)
	#this repeats the pattern
	for offset in pattern.affected_tiles:
		for increment in effective_distance:
			var scaled_offset = (offset * increment).round()
			var target_pos = origin + Vector2i(scaled_offset)

			# NEW LOGIC: A target position is valid if the MapManager considers its
			# surface tile to be anything other than 'Air'.
			if map_manager.get_surface_tile(target_pos) != MapManager.TileType.Air:
				valid_tiles.append(target_pos)

	return valid_tiles

func get_scaled_pattern_empty_tiles(origin: Vector2i, pattern: Pattern2D, distance: int, map_manager: MapManager) -> Array[Vector2i]:
	var valid_tiles: Array[Vector2i] = []
	if not pattern:
		return valid_tiles # Return empty if no pattern is provided.

	var effective_distance = max(1, distance)
	#this repeats the pattern
	for offset in pattern.affected_tiles:
		for increment in effective_distance:
			var scaled_offset = (offset * increment).round()
			var target_pos = origin + Vector2i(scaled_offset)

			# NEW LOGIC: A target position is valid if the MapManager considers its
			# surface tile to be anything other than 'Air'.
			if not map_manager.map_dict.has(target_pos) and map_manager.get_surface_tile(target_pos) != MapManager.TileType.Air:
				valid_tiles.append(target_pos)

	return valid_tiles

@onready var ui_sounds:Dictionary[String,AudioStream] ={
	"Confirm":preload("res://assets/audio/Confirm 1.wav"),
	"Cancel":preload("res://assets/audio/Cancel 1.wav")
}

func play_ui_sound(stream_source):
	var stream:AudioStream = null
	if stream_source is String or stream_source is StringName:
		if ui_sounds.has(stream_source):
			stream = ui_sounds[stream_source]
		elif FileAccess.file_exists(stream_source):
			var source = load(stream_source)
			if source and source is AudioStream:
				stream = source
		else:
			sound_finished.emit()
			return
	elif stream_source is AudioStream:
		stream = stream_source
	$UI.stream = stream
	$UI.play()

signal sound_finished
func _on_ui_finished() -> void:
	sound_finished.emit()

func show_options():
	$PauseMenu.visible = true
