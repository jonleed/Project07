@tool
class_name TerrainTileMap
extends ElevatedTileMap

# Custom Data Layer Names
const HEIGHT_MULTIPLIER = "height_multiplier";
const SURFACE_TYPE = "surface_type"

static var default_validator := func(_a): return true;

static func generate_custom_data_helper(layer_name: String, default_value: Variant, validator: Callable = default_validator) -> Callable:
	return func(tile_data: TileData):
		var res = default_value;
		if tile_data != null and tile_data.has_custom_data(layer_name):
			var unvalidated = tile_data.get_custom_data(layer_name);
			if validator.call(unvalidated) == true:
				res = tile_data.get_custom_data(layer_name);
		return res;

static var get_height_multiplier := generate_custom_data_helper(HEIGHT_MULTIPLIER, 1.0);

static var surface_type_validator := func(a): return a >= 0 and a < Enums.SurfaceType.MAX;
static var get_surface_type := generate_custom_data_helper(SURFACE_TYPE, Enums.SurfaceType.SURFACE, surface_type_validator);

var surface_map: Dictionary[Vector2i, int] = {};

var dirty_coords: Array[Vector2i] = [];

@export var up_checks: int = 5 # Controls the number of upward probe steps for surface detection to handle varying tile_z and height_multiplier values more flexibly.

func _ready() -> void:
	generate_surface();
	cells_changed.connect(_on_cells_changed);

func _on_cells_changed(changes: Array[ElevatedTileMap.CellChangedInfo]) -> void:
	for change in changes:
		var coord := change.coord
		var coord_2d := Vector2i(coord.x, coord.y)
		if not dirty_coords.has(coord_2d):
			dirty_coords.append(coord_2d)
	generate_surface_incremental();

static func sort_custom_tile_layers(a: CustomTileMapLayer, b: CustomTileMapLayer) -> bool:
	return a.layer < b.layer;

func generate_surface():
	# Full regeneration for initial load or explicit call
	dirty_coords.clear();
	surface_map.clear();
	var tile_map_layers := get_children();
	tile_map_layers.sort_custom(sort_custom_tile_layers);
	for tile_map_layer: CustomTileMapLayer in tile_map_layers:
		for cell_coords: Vector2i in tile_map_layer.get_used_cells():
			var tile_data := tile_map_layer.get_cell_tile_data(cell_coords);
			var surface_type: Enums.SurfaceType = get_surface_type.call(tile_data);
			match surface_type:
				Enums.SurfaceType.BLOCKING:
					if surface_map.has(cell_coords):
						surface_map.erase(cell_coords);
				Enums.SurfaceType.STATIC_ENTITY:
					pass ;
				Enums.SurfaceType.SURFACE:
					surface_map[cell_coords] = tile_map_layer.layer;

func generate_surface_incremental():
	if dirty_coords.is_empty():
		return
	var affected_coords: Array[Vector2i] = dirty_coords.duplicate()
	dirty_coords.clear()
	# For each dirty coord, re-evaluate from high to low Z
	var layers := get_children().duplicate()
	layers.sort_custom(sort_custom_tile_layers)
	layers.reverse() # High to low
	for coord in affected_coords:
		surface_map.erase(coord)
		for layer in layers:
			if layer is CustomTileMapLayer:
				var tile_data: TileData = layer.get_cell_tile_data(coord)
				if tile_data:
					var st: Enums.SurfaceType = get_surface_type.call(tile_data)
					if st == Enums.SurfaceType.SURFACE:
						surface_map[coord] = layer.layer
						break # Topmost surface
					elif st == Enums.SurfaceType.BLOCKING:
						break # No surface at or below

func surface_to_local(surface_position: Vector2i):
	if !surface_map.has(surface_position):
		return null;
	var z := surface_map[surface_position];
	var coords := Vector3i(surface_position.x, surface_position.y, z);
	var center_location := map_to_local(coords);
	var tile_data := get_cell_tile_data(coords);
	var height_multiplier: float = get_height_multiplier.call(tile_data);
	var height_adjustment := 1 - height_multiplier;
	return center_location + Vector2(0, tile_z * height_adjustment);

func surface_to_global(surface_position: Vector2i):
	var terrain_to_local_res = surface_to_local(surface_position);
	if terrain_to_local_res == null:
		return null;
	return to_global(terrain_to_local_res);
	
func _provide_surface_map() -> Dictionary[Vector2i, int]:
	return surface_map

func global_to_surface(_global_position: Vector2):
	var tile_map_layers := get_children();
	tile_map_layers.sort_custom(sort_custom_tile_layers);
	tile_map_layers.reverse();
	for tile_map_layer: CustomTileMapLayer in tile_map_layers:
		# Number of upward probe steps for surface detection; increase for finer precision if tile_z varies
		for i in range(up_checks + 1):
			var local_pos := tile_map_layer.to_local(_global_position);
			var adjusted_local_pos := local_pos + Vector2.UP * tile_z * (i / float(up_checks));
			var local_to_map_res := tile_map_layer.local_to_map(adjusted_local_pos);
			if surface_map.has(local_to_map_res) and surface_map[local_to_map_res] == tile_map_layer.layer:
				return local_to_map_res;
	return null;