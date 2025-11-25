class_name MapManager
extends Node2D

@export var surface_layer:TileMapLayer
@export var wall_layer:TileMapLayer
@export var remove_layer:TileMapLayer


##This map will hold everything in a Vector2i
var map_dict:Dictionary ={}
var trap_dict: Dictionary = {}
var map_dict_all_non_wall_tiles:Dictionary

## A* grid for pathfinding, synced with map_dict
var astar_grid := AStarGrid2D.new() # <-- NEW

func init_walls():
	## Go through the wall layer and fill in the spots in map_dict.
	## This assumes your tiles in the wall layer's tileset have a custom data
	## layer named "TileType" of type Int, where the integer corresponds
	## to the TileType enum.
	for entry in surface_layer.get_used_cells():
		map_dict_all_non_wall_tiles[entry] = true
		
	map_dict.clear()
	
	var used_cells = wall_layer.get_used_cells()
	for cell_coords in used_cells:
		var tile_data: TileData = wall_layer.get_cell_tile_data(cell_coords)
		
		# Check for valid tile data and the custom data property.
		if tile_data and tile_data.has_custom_data("TileType"):
			var type_enum_value = tile_data.get_custom_data("TileType")
			
			# Ensure the value is a valid enum index before adding it.
			if type_enum_value >= 0 and type_enum_value <= 4: # Corresponds to the 5 members of TileType
				map_dict[cell_coords] = type_enum_value

				map_dict_all_non_wall_tiles.erase(cell_coords)
				#print("using: ",cell_coords)
			else:
				push_warning("Tile at %s has an invalid TileType value: %s" % [cell_coords, type_enum_value])
		else:
			push_warning("Wall tile at %s is missing 'TileType' custom data." % cell_coords)

enum TileType{
	Ground,#0
	Ice,#1
	Water,#2
	Lava,#3
	Misc,#4
	Air#5
}

## This will use the surface layer to map a global world position to a tile coordinate.
func glob_to_coords(glob:Vector2)->Vector2i:
	# Convert the global world position to the TileMap's local coordinate space,
	# then convert that local position into a grid coordinate (Vector2i).
	return surface_layer.local_to_map(surface_layer.to_local(glob))

## This will use the surface layer to get the global world position of a tile's center.
func coords_to_glob(coord:Vector2i)->Vector2:
	# Convert the grid coordinate (Vector2i) into a position in the TileMap's
	# local space, then convert that local position into a global world position.
	return surface_layer.to_global(surface_layer.map_to_local(coord))

func get_surface_tile(coord:Vector2i)->int:
	# Get the TileData object for the specific tile at this coordinate.
	var tile_data: TileData = surface_layer.get_cell_tile_data(coord)
	
	# First, check if a tile with our custom data actually exists.
	if tile_data and tile_data.has_custom_data("TileType"):
		# If it exists, return the integer value from the custom data.
		return tile_data.get_custom_data("TileType")
	
	# If no tile exists, or if it's missing the custom data, return 5 for an Air tile
	# to signify an empty or invalid tile.
	return 5

##this is the movement function for all members of the map dict dictionary
func entity_move(prev_coord:Vector2i, new_coord:Vector2i):
	var entity = map_dict.get(prev_coord)
	if entity and not entity is int:
		map_dict.erase(prev_coord)
		map_dict.set(new_coord, entity)
		entity.cur_pos = new_coord
		entity.global_position = coords_to_glob(new_coord)
		
		# --- A* UPDATE ---
		# The old spot is now empty, so update its solidity based on the surface
		update_astar_solidity(prev_coord)

		# The new spot is occupied by an entity, set solidity depending on entity type
		if entity is Trap:
			trap_dict.erase(prev_coord)
			trap_dict[new_coord] = entity
			astar_grid.set_point_solid(new_coord, false)
		else: # Units should NOT make a tile solid.
			astar_grid.set_point_solid(new_coord, false)

		# --- END A* UPDATE ---

func swap_entities(entity_a:Entity, entity_b:Entity) -> void:
	# Store current positions
	var pos_a = entity_a.cur_pos
	var pos_b = entity_b.cur_pos

	# Swap entities in the map dictionary
	map_dict[pos_a] = entity_b
	map_dict[pos_b] = entity_a

	# Update each entity's current position
	entity_a.cur_pos = pos_b
	entity_b.cur_pos = pos_a

	# Update their global positions 
	entity_a.global_position = coords_to_glob(pos_b)
	entity_b.global_position = coords_to_glob(pos_a)

	# Update A* grid for both positions
	update_astar_solidity(pos_a)
	update_astar_solidity(pos_b)


func spawn_entity(entity:Entity, coord:Vector2i) -> bool:
	# Check if the coordinate is valid (not solid)
	if astar_grid.is_point_solid(coord):
		printerr("Tried to spawn entity in wall or inside another entity")
		return false
	else:
		map_dict.set(coord, entity)

		# --- A* UPDATE ---
		# If the thing we're spawning is a trap, keep the spot walkable.
		if entity is Trap:
			trap_dict[coord] = entity   # <-- FIX
			astar_grid.set_point_solid(coord, false)
		else:
			# This spot is now occupied by a blocking entity, so it's solid
			astar_grid.set_point_solid(coord, true)
		# --- END A* UPDATE ---
		
		return true

##patterns
#0, blank
#1, X
#2, -
#3, eye
@export var select_layer:TileMapLayer
var _highlight_atlas_coords: Dictionary = {}
## Scans the select_layer's tileset and caches the atlas coordinates
## for each tile that has a "TileType" custom data property.
func _cache_highlight_tiles():
	if not select_layer:
		push_warning("Select Layer is not assigned in the MapManager.")
		return
	
	var tile_set: TileSet = select_layer.tile_set
	if not tile_set:
		push_warning("Select Layer has no TileSet assigned.")
		return

	# Get the number of sources in the TileSet
	var source_count = tile_set.get_source_count()

	# Loop through all available sources by their index (0 to count-1)
	for i in range(source_count):
		# Get the unique ID for the source at the current index
		var source_id = tile_set.get_source_id(i)
		# Use that retrieved ID to get the actual source object
		var source: TileSetSource = tile_set.get_source(source_id)
		
		# Optional but good practice: Only process atlas sources
		if not source is TileSetAtlasSource:
			continue

		var tile_count = source.get_tiles_count()

		for j in range(tile_count):
			var atlas_coords = source.get_tile_id(j)
			var tile_data: TileData = source.get_tile_data(atlas_coords, 0)
			
			if tile_data and tile_data.has_custom_data("TileType"):
				var tile_type = tile_data.get_custom_data("TileType")
				_highlight_atlas_coords[tile_type] = atlas_coords
				#print("Cached highlight tile: Type %s at %s" % [tile_type, atlas_coords])

## Clears the selection layer and draws a new set of highlights.
## Uses a pre-cached dictionary for fast lookups of pattern tiles.
func highlight_tiles(tiles: Array[Vector2i], color: Color = Color.WHITE, pattern: int = 0):
	select_layer.clear()
	select_layer.modulate = color
	
	# 1. Check if the requested pattern was found and cached.
	if not _highlight_atlas_coords.has(pattern):
		push_warning("Highlight pattern %s not found in the tileset's 'TileType' custom data." % pattern)
		return

	# 2. Get the atlas coordinates for the desired pattern tile from the cache.
	var atlas_coord_to_use: Vector2i = _highlight_atlas_coords[pattern]
	
	# 3. Loop through the input coordinates and place the tile.
	# The source ID is 0, assuming you have one tileset source.
	for tile_pos: Vector2i in tiles:
		#print("attemptint to set : ",tile_pos)
		select_layer.set_cell(tile_pos, 0, atlas_coord_to_use)

func _ready() -> void:
	init_walls()
	_cache_highlight_tiles()
	_initialize_astar_grid()

## Initializes the AStar grid based on the current map state.
func _initialize_astar_grid():
	astar_grid.clear()
	# Use the surface layer's rectangle to define the grid bounds
	var map_bounds: Rect2i = surface_layer.get_used_rect()
	if map_bounds.size == Vector2i.ZERO:
		push_warning("MapManager: Surface layer has no tiles. A* grid will be empty.")
		return
	
	# We expand the region by one tile in all directions to avoid "out of bounds"
	# errors if pathfinding to the very edge.
	astar_grid.region = map_bounds.grow(1)
	astar_grid.cell_size = Vector2(1, 1) # Assumes 1:1 grid
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	# Iterate all cells *within the playable map boundaries*
	for x in range(map_bounds.position.x, map_bounds.end.x):
		for y in range(map_bounds.position.y, map_bounds.end.y):
			var coord := Vector2i(x, y)
			# Update solidity for each cell based on its content
			update_astar_solidity(coord)


func update_astar_solidity(coord: Vector2i):
	# 1a. If there's a trap at this coord, traps are walkable
	if trap_dict.has(coord):
		# trap = walkable
		astar_grid.set_point_solid(coord, false)
		return

	# 1b. Check if an entity or wall (from init_walls) is at the coordinate
	if map_dict.has(coord):
		var value = map_dict[coord]
		# allows traps stored in map_dict to be walked over
		if value is Trap:
			astar_grid.set_point_solid(coord, false) # trap = walkable
			return
		else:
			# If it's in map_dict, it's solid (either a wall or a blocking entity)
			astar_grid.set_point_solid(coord, true)
			return

	# 2. If the cell is empty in map_dict, check the surface type
	var surface_type = get_surface_tile(coord)
	
	match surface_type:
		TileType.Ground, TileType.Ice, TileType.Misc:
			# These are walkable surfaces
			astar_grid.set_point_solid(coord, false)
		TileType.Water, TileType.Lava, TileType.Air:
			# These are non-walkable surfaces
			astar_grid.set_point_solid(coord, true)
		_:
			# Default for any other unknown tile type
			astar_grid.set_point_solid(coord, true)

## Calculates the shortest path, respecting obstacles.
## Returns an empty array if no path is found.
func get_star_path(start_coord: Vector2i, end_coord: Vector2i) -> Array[Vector2i]:
	# Check if the end point is solid. A* can't path to a solid point.
	if astar_grid.is_point_solid(end_coord):
		#print("Pathfinding failed: Target is solid.")
		var empty_array:Array[Vector2i] = [Vector2i(-INF, -INF)]
		return empty_array # Return empty array
		
	# get_id_path() finds the path using grid coordinates
	return astar_grid.get_id_path(start_coord, end_coord)
