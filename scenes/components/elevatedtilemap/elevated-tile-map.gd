@tool
class_name ElevatedTileMap;
extends Node2D;

class CellChangedInfo:
	var coord: Vector3i;
	var change_type: Enums.CellChangeType;
	func _init(_coord: Vector3i, _change_type: Enums.CellChangeType):
		self.coord = _coord;
		self.change_type = _change_type;

signal cells_changed(changes: Array[CellChangedInfo]); # Each dict: {"coord": Vector3i, "change_type": Enums.CellChangeType}; duplicates allowed for multi-type per coord

# Height difference between layers in px, i.e. how much to shift an item from (x, y, z) to (x, y, z+1)
@export var tile_z := 8;

# Tile Set to use
@export var tile_set: TileSet;

@export_tool_button("Clear TileMap", "Callable") var clear_tile_map_action := clear_tile_map

func clear_tile_map() -> void:
	for child: CustomTileMapLayer in get_children():
		remove_child(child);
		child.queue_free()

@export_group("Import Voxels")
@export var voxels_to_import: Array[VoxelInfo] = [];
@export_tool_button("Draw Imported Voxels", "Callable") var import_voxels_action := import_voxels

func import_voxels() -> void:
	clear_tile_map();
	draw_voxels(voxels_to_import);

func map_to_local(map_position: Vector3i) -> Vector2:
	var tile_map_layer := get_or_create_tile_map_layer(map_position.z);
	return tile_map_layer.map_to_local(Vector2i(map_position.x, map_position.y)) + tile_map_layer.position;

func map_to_global(map_position: Vector3i) -> Vector2:
	return to_global(map_to_local(map_position));

# Helper function to group cells by z-coordinate
func _group_cells_by_z(cells: Array[Vector3i]) -> Dictionary[int, Array]:
	var cells_by_z: Dictionary[int, Array] = {};
	for cell: Vector3i in cells:
		if !cells_by_z.has(cell.z):
			cells_by_z[cell.z] = [];
		cells_by_z[cell.z].append(Vector2i(cell.x, cell.y));
	return cells_by_z;

func draw_voxels(voxels: Array[VoxelInfo]) -> void:
	# Validate tile_set before proceeding
	if tile_set == null:
		push_error("TileSet is not assigned!")
		return
	for voxel_info: VoxelInfo in voxels:
		match voxel_info.tile_type:
			Enums.TileType.FROM_ATLAS:
				var coords := voxel_info.coords;
				var source_id := voxel_info.atlas_info.source_id;
				var atlas_coords := voxel_info.atlas_info.atlas_coords;
				var alternative_tile := voxel_info.atlas_info.alternative_tile;
				set_cell(coords, source_id, atlas_coords, alternative_tile);
			Enums.TileType.FROM_TERRAIN:
				var top_layer_cells: Array[Vector3i] = [];
				var middle_layer_cells: Array[Vector3i] = [];
				var bottom_layer_cells: Array[Vector3i] = [];
				
				# Pre-build lookup set for O(1) has() checks
				var path_set: Dictionary[Vector3i, bool] = {};
				for c in voxel_info.path:
					path_set[c] = true;
						
				for cell: Vector3i in voxel_info.path:
					var layer_cells: Array[Vector3i];
					
					var has_cell_above := path_set.has(cell + Vector3i.BACK); # BACK refers to UP in our 3D axes
					var has_cell_below := path_set.has(cell - Vector3i.BACK);
					
					if !has_cell_above:
						# Top cell (or standalone cell)
						layer_cells = top_layer_cells;
					elif !has_cell_below:
						# Bottom cell
						layer_cells = bottom_layer_cells;
					else:
						# Middle cell (has both above and below)
						layer_cells = middle_layer_cells;
					
					layer_cells.push_back(cell);
				for i: int in range(3):
					var layer_cells: Array[Vector3i];
					var terrain_set: int;
					var terrain: int;
					var ignore_empty_terrains := voxel_info.terrain_info.ignore_empty_terrains;
					match i:
						0:
							layer_cells = top_layer_cells;
							terrain_set = voxel_info.terrain_info.terrain_set;
							terrain = voxel_info.terrain_info.terrain;
						1:
							layer_cells = middle_layer_cells;
							terrain_set = TerrainInfo.get_middle_terrain_set(voxel_info.terrain_info);
							terrain = TerrainInfo.get_middle_terrain(voxel_info.terrain_info);
						2:
							layer_cells = bottom_layer_cells;
							terrain_set = TerrainInfo.get_bottom_terrain_set(voxel_info.terrain_info);
							terrain = TerrainInfo.get_bottom_terrain(voxel_info.terrain_info);
					match voxel_info.terrain_info.terrain_type:
						Enums.TerrainType.CONNECT:
							set_cells_terrain_connect(layer_cells, terrain_set, terrain, ignore_empty_terrains);
						Enums.TerrainType.PATH:
							set_cells_terrain_path(layer_cells, terrain_set, terrain, ignore_empty_terrains);

# Helper function to execute a method on a tile map layer if it exists
func _execute_on_layer(coords: Vector3i, method_name: String, default_value = null, args: Array = [], coords_index: int = 0):
	var tile_map_layer := get_tile_map_layer(coords.z);
	if tile_map_layer == null:
		return default_value;
	# Convert 3D coords to 2D for the layer method
	var coords_2d := Vector2i(coords.x, coords.y);
	# Insert coords_2d at the specified index in args
	var call_args := args.duplicate();
	call_args.insert(coords_index, coords_2d);
	return tile_map_layer.callv(method_name, call_args);

func erase_cell(coords: Vector3i) -> void:
	var does_tile_exist := get_cell_tile_data(coords) != null;
	_execute_on_layer(coords, "erase_cell");
	if not does_tile_exist:
		var changes: Array[CellChangedInfo] = [CellChangedInfo.new(coords, Enums.CellChangeType.DELETE)];
		cells_changed.emit(changes);

func get_cell_alternative_tile(coords: Vector3i) -> int:
	return _execute_on_layer(coords, "get_cell_alternative_tile", -1);

func get_cell_atlas_coords(coords: Vector3i) -> Vector2i:
	return _execute_on_layer(coords, "get_cell_atlas_coords", Vector2i(-1, -1));

func get_cell_source_id(coords: Vector3i) -> int:
	return _execute_on_layer(coords, "get_cell_source_id", -1);

func get_cell_tile_data(coords: Vector3i) -> TileData:
	return _execute_on_layer(coords, "get_cell_tile_data", null);

func set_cell(coords: Vector3i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0):
	var changes:Array[CellChangedInfo] = [];
	var tile_map_layer := get_or_create_tile_map_layer(coords.z);
	var changed_type: Enums.CellChangeType;
	var cell_exists := tile_map_layer.get_cell_tile_data(Vector2i(coords.x, coords.y)) != null;
	match cell_exists:
		true:
			changed_type = Enums.CellChangeType.MODIFY;
		false:
			changed_type = Enums.CellChangeType.CREATE;
	changes.append(CellChangedInfo.new(coords, changed_type));
	tile_map_layer.set_cell(Vector2i(coords.x, coords.y), source_id, atlas_coords, alternative_tile);
	cells_changed.emit(changes)

func set_cells_terrain_connect(cells: Array[Vector3i], terrain_set: int, terrain: int, ignore_empty_terrains: bool = true):
	var changes: Array[CellChangedInfo] = []
	for cell in cells:
		var changed_type: Enums.CellChangeType;
		var cell_exists := get_cell_tile_data(cell) != null;
		match cell_exists:
			false:
				changed_type = Enums.CellChangeType.CREATE;
			true:
				changed_type = Enums.CellChangeType.MODIFY;
		changes.append(CellChangedInfo.new(cell, changed_type));
	var cells_by_z := _group_cells_by_z(cells);
	for z in cells_by_z:
		var tile_map_layer := get_or_create_tile_map_layer(z);
		var new_cells := cells_by_z[z];
		tile_map_layer.set_cells_terrain_connect(new_cells, terrain_set, terrain, ignore_empty_terrains);
	cells_changed.emit(changes);

func set_cells_terrain_path(path: Array[Vector3i], terrain_set: int, terrain: int, ignore_empty_terrains: bool = true):
	var changes: Array[CellChangedInfo] = []
	for point in path:
		var changed_type: Enums.CellChangeType;
		var cell_exists := get_cell_tile_data(point) != null;
		match cell_exists:
			false:
				changed_type = Enums.CellChangeType.CREATE;
			true:
				changed_type = Enums.CellChangeType.MODIFY;
		changes.append(CellChangedInfo.new(point, changed_type));
	var sub_paths: Array[Dictionary] = [];
	var prev_z = null;
	var current_path: Array[Vector2i] = [];
	for point in path:
		if prev_z != null and point.z != prev_z:
			sub_paths.append({"z": prev_z, "path": current_path});
			current_path = [];
		current_path.append(Vector2i(point.x, point.y));
		prev_z = point.z;
	if len(current_path) > 0:
		sub_paths.append({"z": prev_z, "path": current_path});
	for sub_path in sub_paths:
		var tile_map_layer := get_or_create_tile_map_layer(sub_path["z"]);
		tile_map_layer.set_cells_terrain_path(sub_path["path"], terrain_set, terrain, ignore_empty_terrains);
	cells_changed.emit(changes);

func get_tile_map_layer(z: int) -> CustomTileMapLayer:
	return find_child("TileMapLayer" + str(z));

func get_or_create_tile_map_layer(z: int) -> CustomTileMapLayer:
	var existing_child := get_tile_map_layer(z);
	if existing_child != null:
		return existing_child;
	
	var tile_map_layer := CustomTileMapLayer.new();
	
	tile_map_layer.layer = z;

	tile_map_layer.name = "TileMapLayer" + str(z)
	
	tile_map_layer.tile_set = tile_set;
	
	# Enable y-sort
	tile_map_layer.y_sort_enabled = true;
	tile_map_layer.y_sort_origin = -z;
	
	add_child(tile_map_layer);
	tile_map_layer.owner = get_tree().edited_scene_root
	
	# Shift layer up for each layer using position.y for clarity on negative Z handling
	tile_map_layer.position.y = - tile_z * z;
	
	return tile_map_layer;

@export_tool_button("Cleanup Layers", "Callable") var cleanup_layers_action := cleanup_layers

func cleanup_layers() -> void:
	for child in get_children():
		if child is CustomTileMapLayer and child.get_used_cells().is_empty():
			remove_child(child)
			child.queue_free()
