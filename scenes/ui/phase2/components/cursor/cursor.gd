class_name Cursor
extends Node2D

# TODO: Add support for keyboard

#signal entity_selected(entity:Entity)
signal unit_selected(unit:Unit)
signal deselected()
signal tile_selected(coord:Vector2i)

@onready var map_manager: MapManager = $"../MapManager"
@onready var surface_layer: TileMapLayer = map_manager.surface_layer

var cursor_position: Vector2i = Vector2i.ZERO

func _process(_delta: float) -> void:
	# Convert mouse global coords to tile coords
	var mouse_global := get_global_mouse_position()
	var marker_coord := map_manager.glob_to_coords(mouse_global)

	# Ignore invalid tiles outside the tilemap
	if not surface_layer.get_used_cells().has(marker_coord):
		return

	# Only update when the tile changes
	if marker_coord == cursor_position:
		return

	# Update cursor global position to tile
	cursor_position = marker_coord
	global_position = map_manager.coords_to_glob(marker_coord)

func _unhandled_input(event):
	# Left click: Entity Selection
	if event.is_action_pressed("Left_Click"):
		var entity = map_manager.map_dict.get(cursor_position, null)
		var tile = map_manager.get_surface_tile(cursor_position)
		if entity == null:
			if tile != 5:
				print("No entity at Selected Tile: %s Tile Type: %s"% [cursor_position, tile])
				tile_selected.emit(cursor_position)
				return
			print("Invalid tile:", cursor_position, entity)
			return
		# Determine if Unit or Entity 
		if entity is Unit:
			print("Selected unit:", entity.name)
			emit_signal("unit_selected", entity)
		elif entity is Entity:
			print("Selected entity:", entity.name)
			#emit_signal("entity_selected", entity)
		else: 
			print("Selected Wall")
	
	# Right click: Deselect
	if event.is_action_pressed("Cancel"):
		emit_signal("deselected")
