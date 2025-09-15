@tool
class_name TerrainTileMap
extends ElevatedTileMap

# Custom Data Layer Names
const IS_TERRAIN = "is_terrain";
const HEIGHT_MULTIPLIER = "height_multiplier";

var terrain_map: Dictionary[Vector2i, int] = {};

func _ready() -> void:
	GenerateTerrain();

func GenerateTerrain():
	for tile_map_layer: CustomTileMapLayer in get_children():
		for cell_coords: Vector2i in tile_map_layer.get_used_cells():
			var tile_data: TileData = tile_map_layer.get_cell_tile_data(cell_coords);
			var is_terrain: bool = false;
			if tile_data.has_custom_data(IS_TERRAIN):
				is_terrain = tile_data.get_custom_data(IS_TERRAIN);
			if is_terrain:
				if terrain_map.has(cell_coords):
					terrain_map[cell_coords] = max(terrain_map[cell_coords], tile_map_layer.layer);
				else:
					terrain_map[cell_coords] = tile_map_layer.layer;

func TerrainToLocal(terrain_position: Vector2i):
	if !terrain_map.has(terrain_position):
		return null;
	var z: int = terrain_map[terrain_position];
	var coords: Vector3i = Vector3i(terrain_position.x, terrain_position.y, z);
	var center_location: Vector2 = MapToLocal(coords);
	var tile_data: TileData = GetCellTileData(coords);
	var height_multiplier: float = 1;
	if tile_data.has_custom_data(HEIGHT_MULTIPLIER):
		height_multiplier = tile_data.get_custom_data(HEIGHT_MULTIPLIER);
	var inverse_height_multiplier: float = 1-height_multiplier;
	return center_location + Vector2(0, tile_z*inverse_height_multiplier);

func TerrainToGlobal(terrain_position: Vector2i):
	var terrain_to_local_res = TerrainToLocal(terrain_position);
	if terrain_to_local_res == null:
		return null;
	return to_global(terrain_to_local_res);
