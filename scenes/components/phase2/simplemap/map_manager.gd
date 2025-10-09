class_name MapManager
extends Node2D

@export var surface_layer:TileMapLayer
@export var wall_layer:TileMapLayer

##This map will hold everything in a Vector2i
var map_dict:Dictionary

func init_walls():
	## Go through the wall layer and fill in the spots in map_dict.
	## This assumes your tiles in the wall layer's tileset have a custom data
	## layer named "TileType" of type Int, where the integer corresponds
	## to the TileType enum.
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
				print("using: ",cell_coords)
			else:
				push_warning("Tile at %s has an invalid TileType value: %s" % [cell_coords, type_enum_value])
		else:
			push_warning("Wall tile at %s is missing 'TileType' custom data." % cell_coords)
	print(map_dict)

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
func entity_move(prev_coord:Vector2i,new_coord:Vector2i):
	var entity = map_dict.get(prev_coord)
	if entity and not entity is int:
		map_dict.erase(prev_coord)
		map_dict.set(new_coord,entity)

func spawn_entity(entity:Entity,coord:Vector2i):
	if map_dict.get(coord):
		printerr("Tried to spawn entity in wall or inside another entity")
	else:
		map_dict.set(coord,entity)

func _ready() -> void:
	init_walls()
