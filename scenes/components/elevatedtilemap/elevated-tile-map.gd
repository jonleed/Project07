@tool
class_name ElevatedTileMap;
extends Node2D;

# Height difference between layers in px, i.e. how much to shift an item from (x, y, z) to (x, y, z+1)
@export var tile_z: int = 8;

# Tile Set to use
@export var tile_set: TileSet;

@export_tool_button("Clear TileMap", "Callable") var clear_tile_map_action = ClearTileMap

func ClearTileMap() -> void:
	for child: CustomTileMapLayer in get_children():
		remove_child(child);
		child.queue_free()

@export_group("Import Voxels")
@export var voxels_to_import: Array[VoxelInfo] = [];
@export_tool_button("Draw Imported Voxels", "Callable") var import_voxels_action = ImportVoxels

func ImportVoxels() -> void:
	ClearTileMap();
	DrawVoxels(voxels_to_import);

func MapToLocal(map_position: Vector3i) -> Vector2:
	var tile_map_layer: CustomTileMapLayer = GetOrCreateTileMapLayer(map_position.z);
	return tile_map_layer.map_to_local(Vector2i(map_position.x, map_position.y)) + tile_map_layer.position;

func MapToGlobal(map_position: Vector3i) -> Vector2:
	return to_global(MapToLocal(map_position));

func DrawVoxels(voxels: Array[VoxelInfo]) -> void:
	# Validate tile_set before proceeding
	if tile_set == null:
		push_error("TileSet is not assigned!")
		return
	for voxel_info: VoxelInfo in voxels:
		match voxel_info.tile_type:
			Enums.TileType.FROM_ATLAS:
				var coords: Vector3i = voxel_info.coords;
				var source_id: int = voxel_info.atlas_info.source_id;
				var atlas_coords: Vector2i = voxel_info.atlas_info.atlas_coords;
				var alternative_tile: int = voxel_info.atlas_info.alternative_tile;
				SetCell(coords, source_id, atlas_coords, alternative_tile);
			Enums.TileType.FROM_TERRAIN:
				var top_layer_cells: Array[Vector3i] = [];
				var middle_layer_cells: Array[Vector3i] = [];
				var bottom_layer_cells: Array[Vector3i] = [];
				
				for cell: Vector3i in voxel_info.path:
					var layer_cells: Array[Vector3i];
					
					if !voxel_info.path.has(cell+Vector3i(0,0,1)):
						layer_cells = top_layer_cells;
					elif !voxel_info.path.has(cell-Vector3i(0,0,1)):
						layer_cells = bottom_layer_cells;
					else:
						layer_cells = middle_layer_cells;
					
					layer_cells.push_back(cell);
				for i: int in range(3):
					var layer_cells: Array[Vector3i];
					var terrain_set: int;
					var terrain: int;
					var ignore_empty_terrains: bool = voxel_info.terrain_info.ignore_empty_terrains;
					match i:
						0:
							layer_cells = top_layer_cells;
							terrain_set = voxel_info.terrain_info.terrain_set;
							terrain = voxel_info.terrain_info.terrain;
						1:
							layer_cells = middle_layer_cells;
							terrain_set = TerrainInfo.GetMiddleTerrainSet(voxel_info.terrain_info);
							terrain = TerrainInfo.GetMiddleTerrain(voxel_info.terrain_info);
						2:
							layer_cells = bottom_layer_cells;
							terrain_set = TerrainInfo.GetBottomTerrainSet(voxel_info.terrain_info);
							terrain = TerrainInfo.GetBottomTerrain(voxel_info.terrain_info);
					match voxel_info.terrain_info.terrain_type:
						Enums.TerrainType.CONNECT:
							SetCellsTerrainConnect(layer_cells, terrain_set, terrain, ignore_empty_terrains);
						Enums.TerrainType.PATH:
							SetCellsTerrainPath(layer_cells, terrain_set, terrain, ignore_empty_terrains);

func EraseCell(coords: Vector3i) -> void:
	var tile_map_layer: CustomTileMapLayer = GetTileMapLayer(coords.z);
	if tile_map_layer == null:
		return;
	tile_map_layer.erase_cell(Vector2i(coords.x, coords.y));

func GetCellAlternativeTile(coords: Vector3i) -> int:
	var tile_map_layer: CustomTileMapLayer = GetTileMapLayer(coords.z);
	if tile_map_layer == null:
		return -1;
	return tile_map_layer.get_cell_alternative_tile(Vector2i(coords.x, coords.y));

func GetCellAtlasCoords(coords: Vector3i) -> Vector2i:
	var tile_map_layer: CustomTileMapLayer = GetTileMapLayer(coords.z);
	if tile_map_layer == null:
		return Vector2i(-1,-1);
	return tile_map_layer.get_cell_atlas_coords(Vector2i(coords.x, coords.y));

func GetCellSourceId(coords: Vector3i) -> int:
	var tile_map_layer: CustomTileMapLayer = GetTileMapLayer(coords.z);
	if tile_map_layer == null:
		return -1;
	return tile_map_layer.get_cell_source_id(Vector2i(coords.x, coords.y));

func GetCellTileData(coords: Vector3i) -> TileData:
	var tile_map_layer: CustomTileMapLayer = GetTileMapLayer(coords.z);
	if tile_map_layer == null:
		return null;
	return tile_map_layer.get_cell_tile_data(Vector2i(coords.x, coords.y));

func SetCell(coords: Vector3i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1,-1), alternative_tile: int = 0):
	var tile_map_layer: CustomTileMapLayer = GetOrCreateTileMapLayer(coords.z);
	tile_map_layer.set_cell(Vector2i(coords.x, coords.y), source_id, atlas_coords, alternative_tile);

func SetCellsTerrainConnect(cells: Array[Vector3i], terrain_set:int, terrain: int, ignore_empty_terrains:bool = true):
	var cells_by_z: Dictionary[int, Array] = {};
	for cell: Vector3i in cells:
		if !cells_by_z.has(cell.z):
			cells_by_z[cell.z] = [];
		cells_by_z[cell.z].append(Vector2i(cell.x, cell.y));
	for z: int in cells_by_z:
		var tile_map_layer: CustomTileMapLayer = GetOrCreateTileMapLayer(z);
		var new_cells: Array = cells_by_z[z];
		tile_map_layer.set_cells_terrain_connect(new_cells, terrain_set, terrain, ignore_empty_terrains);

func SetCellsTerrainPath(cells: Array[Vector3i], terrain_set:int, terrain: int, ignore_empty_terrains:bool = true):
	var cells_by_z: Dictionary[int, Array] = {};
	for cell: Vector3i in cells:
		if !cells_by_z.has(cell.z):
			cells_by_z[cell.z] = [];
		cells_by_z[cell.z].append(Vector2i(cell.x, cell.y));
	for z: int in cells_by_z:
		var tile_map_layer: CustomTileMapLayer = GetOrCreateTileMapLayer(z);
		var new_cells: Array = cells_by_z[z];
		tile_map_layer.set_cells_terrain_path(new_cells, terrain_set, terrain, ignore_empty_terrains);

func GetTileMapLayer(z: int) -> CustomTileMapLayer:
	return find_child("TileMapLayer"+str(z));

func GetOrCreateTileMapLayer(z: int) -> CustomTileMapLayer:
	var existing_child: CustomTileMapLayer = GetTileMapLayer(z);
	if existing_child != null:
		return existing_child;
	
	var tile_map_layer: CustomTileMapLayer = CustomTileMapLayer.new();
	
	tile_map_layer.layer = z;

	tile_map_layer.name = "TileMapLayer"+str(z)
	
	tile_map_layer.tile_set = tile_set;
	
	# Enable y-sort
	tile_map_layer.y_sort_enabled = true;
	tile_map_layer.y_sort_origin = -z;
	
	add_child(tile_map_layer);
	tile_map_layer.owner = get_tree().edited_scene_root
	
	# Shift layer up for each layer using Vector2 for translation
	tile_map_layer.translate(Vector2(0, -tile_z * z));
	
	return tile_map_layer;
