@tool
class_name TerrainTileMap
extends ElevatedTileMap

# Custom Data Layer Names
const IS_TERRAIN = "is_terrain";
const HEIGHT_MULTIPLIER = "height_multiplier";

var surface_map: Dictionary[Vector2i, int] = {};

func _ready() -> void:
	generate_surface();

func generate_surface():
	for tile_map_layer: CustomTileMapLayer in get_children():
		for cell_coords: Vector2i in tile_map_layer.get_used_cells():
			var tile_data: TileData = tile_map_layer.get_cell_tile_data(cell_coords);
			var is_terrain: bool = false;
			if tile_data.has_custom_data(IS_TERRAIN):
				is_terrain = tile_data.get_custom_data(IS_TERRAIN);
			if is_terrain:
				if surface_map.has(cell_coords):
					surface_map[cell_coords] = max(surface_map[cell_coords], tile_map_layer.layer);
				else:
					surface_map[cell_coords] = tile_map_layer.layer;

func surface_to_local(surface_position: Vector2i):
	if !surface_map.has(surface_position):
		return null;
	var z: int = surface_map[surface_position];
	var coords: Vector3i = Vector3i(surface_position.x, surface_position.y, z);
	var center_location: Vector2 = map_to_local(coords);
	var tile_data: TileData = get_cell_tile_data(coords);
	var height_multiplier: float = 1;
	if tile_data.has_custom_data(HEIGHT_MULTIPLIER):
		height_multiplier = tile_data.get_custom_data(HEIGHT_MULTIPLIER);
	var inverse_height_multiplier: float = 1-height_multiplier;
	return center_location + Vector2(0, tile_z*inverse_height_multiplier);

func surface_to_global(surface_position: Vector2i):
	var terrain_to_local_res = surface_to_local(surface_position);
	if terrain_to_local_res == null:
		return null;
	return to_global(terrain_to_local_res);
