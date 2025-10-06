extends Node

#this node will contain global variables and useful functions
var party_units:Dictionary ={}

##this will pass the possible tiles back
##now tile validation will have to come from whoever makes the tiles
func get_bfs_range(start_pos: Vector2i, _range: int, tilemap_layer: TileMapLayer) -> Array[Vector2i]:
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
