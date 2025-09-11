@tool
class_name ElevatedTileMap;
extends Node2D;

# Height difference between layers in px, i.e. how much to shift an item from (x, y, z) to (x, y, z+1)
@export var tile_z: int = 8;

# Tile Set to use
@export var tile_set: TileSet;

@export_tool_button("Clear TileMap", "Callable") var clear_tile_map_action = ClearTileMap

@export_group("Import Voxels")
@export var voxels_to_import: Array[VoxelInfo] = [];
@export_tool_button("Draw Imported Voxels", "Callable") var import_voxels_action = ImportVoxels

func ImportVoxels() -> void:
	ClearTileMap();
	DrawVoxels(voxels_to_import);

var xy_heightmap: Dictionary[Vector2i, int] = {}

func _ready() -> void:
	GenerateXYHeightmap();

func GenerateXYHeightmap():
	for tile_map_layer: CustomTileMapLayer in get_children():
		for cell_coords: Vector2i in tile_map_layer.get_used_cells():
			if xy_heightmap.has(cell_coords):
				xy_heightmap[cell_coords] = max(xy_heightmap[cell_coords], tile_map_layer.layer);
			else:
				xy_heightmap[cell_coords] = tile_map_layer.layer;

func MapToLocal(xy_coords: Vector2i) -> Vector2:
	if !xy_heightmap.has(xy_coords):
		return Vector2i(0,0)
	var z = xy_heightmap[xy_coords];
	var tile_map_layer = GetOrCreateTileMapLayer(z);
	return tile_map_layer.map_to_local(xy_coords) - Vector2(0, tile_z*z);
	
func MapToGlobal(xy_coords: Vector2i) -> Vector2:
	return to_global(MapToLocal(xy_coords));

func DrawVoxels(voxels: Array[VoxelInfo]) -> void:
	# Validate tile_set before proceeding
	if tile_set == null:
		push_error("TileSet is not assigned!")
		return
	for voxel_info: VoxelInfo in voxels:
		match voxel_info.tile_type:
			Enums.TileType.FROM_ATLAS:
				var tile_map_layer = GetOrCreateTileMapLayer(voxel_info.coords.z);
				var coords = Vector2i(voxel_info.coords.x, voxel_info.coords.y);
				var source_id = voxel_info.atlas_info.source_id;
				var atlas_coords = voxel_info.atlas_info.atlas_coords;
				var alternative_tile = voxel_info.atlas_info.alternative_tile;
				tile_map_layer.set_cell(coords, source_id, atlas_coords, alternative_tile);
			Enums.TileType.FROM_TERRAIN:
				var layer_paths: Dictionary[int, Array] = {}
				var middle_layer_paths: Dictionary[int, Array] = {}
				var bottom_layer_paths: Dictionary[int, Array] = {}
				for cell: Vector3i in voxel_info.path:
					if !voxel_info.path.has(cell+Vector3i(0,0,1)):
						if !layer_paths.has(cell.z):
							layer_paths[cell.z] = [];
						layer_paths[cell.z].push_back(Vector2i(cell.x, cell.y));
					elif !voxel_info.path.has(cell-Vector3i(0,0,1)):
						if !bottom_layer_paths.has(cell.z):
							bottom_layer_paths[cell.z] = [];
						bottom_layer_paths[cell.z].push_back(Vector2i(cell.x, cell.y));
					else:
						if !middle_layer_paths.has(cell.z):
							middle_layer_paths[cell.z] = [];
						middle_layer_paths[cell.z].push_back(Vector2i(cell.x, cell.y));
				for z: int in layer_paths:
					var path = layer_paths[z];
					var tile_map_layer = GetOrCreateTileMapLayer(z);
					var terrain_set = voxel_info.terrain_info.terrain_set;
					var terrain = voxel_info.terrain_info.terrain;
					var ignore_empty_terrains = voxel_info.terrain_info.ignore_empty_terrains;
					match voxel_info.terrain_info.terrain_type:
						Enums.TerrainType.CONNECT:
							tile_map_layer.set_cells_terrain_connect(path, terrain_set, terrain, ignore_empty_terrains);
						Enums.TerrainType.PATH:
							tile_map_layer.set_cells_terrain_path(path, terrain_set, terrain, ignore_empty_terrains);
				for z: int in middle_layer_paths:
					var path = middle_layer_paths[z];
					var tile_map_layer = GetOrCreateTileMapLayer(z);
					var terrain_set = TerrainInfo.GetMiddleTerrainSet(voxel_info.terrain_info);
					var terrain = TerrainInfo.GetMiddleTerrain(voxel_info.terrain_info);
					var ignore_empty_terrains = voxel_info.terrain_info.ignore_empty_terrains;
					match voxel_info.terrain_info.terrain_type:
						Enums.TerrainType.CONNECT:
							tile_map_layer.set_cells_terrain_connect(path, terrain_set, terrain, ignore_empty_terrains);
						Enums.TerrainType.PATH:
							tile_map_layer.set_cells_terrain_path(path, terrain_set, terrain, ignore_empty_terrains);
				for z: int in bottom_layer_paths:
					var path = bottom_layer_paths[z];
					var tile_map_layer = GetOrCreateTileMapLayer(z);
					var terrain_set = TerrainInfo.GetBottomTerrainSet(voxel_info.terrain_info);
					var terrain = TerrainInfo.GetBottomTerrain(voxel_info.terrain_info);
					var ignore_empty_terrains = voxel_info.terrain_info.ignore_empty_terrains;
					match voxel_info.terrain_info.terrain_type:
						Enums.TerrainType.CONNECT:
							tile_map_layer.set_cells_terrain_connect(path, terrain_set, terrain, ignore_empty_terrains);
						Enums.TerrainType.PATH:
							tile_map_layer.set_cells_terrain_path(path, terrain_set, terrain, ignore_empty_terrains);

# Add a tool button to clear all layers

func ClearTileMap() -> void:
	for child: CustomTileMapLayer in get_children():
		remove_child(child);
		child.queue_free()

func GetOrCreateTileMapLayer(z: int) -> CustomTileMapLayer:
	var existing_child: CustomTileMapLayer = find_child("TileMapLayer"+str(z));
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
