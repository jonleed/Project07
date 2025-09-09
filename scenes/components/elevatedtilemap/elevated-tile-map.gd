@tool
class_name ElevatedTileMap;
extends Node2D;

# Height difference between layers in px, i.e. how much to shift an item from (x, y, z) to (x, y, z+1)
@export var tile_z: int = 8;

# Tile Set to use
@export var tile_set: TileSet;

# Heightmap generation parameters, generating heightmaps are optional, but can speed up level creation
@export_group("Procedural Voxel Generation")
@export var heightmap_size_x: int = 25;
@export var heightmap_size_y: int = 25;
@export var heightmap_size_z: int = 25;  # Number of possible height values (0 to heightmap_size_z-1)
@export var noise_scale: float = 4.0;

var max_seed_value: int = 999999999;

@export var top_atlas_coords: Vector2i = Vector2i(0,0)
@export var under_atlas_coords: Vector2i = Vector2i(1,0)
@export var stone_atlas_coords: Vector2i = Vector2i(2,0)
@export var water_atlas_coords: Vector2i = Vector2i(3,0)
@export var fog_atlas_coords: Vector2i = Vector2i(4,0)
@export var water_level: int = 13

@export_tool_button("Generate Voxels", "Callable") var generate_voxels_action = generate_voxels

func generate_voxels() -> void:
	clear_tilemap();
	var heightmap: Array[VoxelInfo] = generate_random_voxels();
	draw_voxels(heightmap)

@export_group("Import Voxels")
@export var voxels_to_import: Array[VoxelInfo] = [];
@export_tool_button("Draw Imported Voxels", "Callable") var import_voxels_action = import_voxels
func import_voxels() -> void:
	clear_tilemap();
	draw_voxels(voxels_to_import);
@export_group("")

var xy_heightmap: Dictionary[Vector2i, int] = {}

func generate_random_voxels() -> Array[VoxelInfo]:
	var noise = FastNoiseLite.new();
	# Seed has a max value
	noise.seed = randi() % max_seed_value;
	var random_voxels: Array[VoxelInfo] = [];
	
	for x: int in range(heightmap_size_x):
		for y: int in range(heightmap_size_y):
			# noise.get_noise_2d returns values between -1 and 1
			# Adding 1 gives 0-2, dividing by 2 gives 0-1
			# Multiplying by (heightmap_size_z - 1) gives height values 0-(heightmap_size_z-1)
			var height = floor((heightmap_size_z - 1)*(noise.get_noise_2d(noise_scale*x, noise_scale*y) + 1)/2);
			for z: int in range(height):
				var atlas_coords = under_atlas_coords if z>height-5 else stone_atlas_coords;
				random_voxels.append(VoxelInfo.from_atlas(Vector3i(x,y,z), 0, atlas_coords));
			random_voxels.append(VoxelInfo.from_atlas(Vector3i(x,y,height), 0, top_atlas_coords if height >= water_level else under_atlas_coords));
			if water_level > height:
				random_voxels.append(VoxelInfo.from_atlas(Vector3i(x,y,water_level), 0, water_atlas_coords));
			#if height > water_level:
				#random_voxels.append(VoxelInfo.from_atlas(Vector3i(x,y,max(water_level, height)+1), 0, fog_atlas_coords))
	return random_voxels;

func _ready() -> void:
	generate_xy_heightmap();

func generate_xy_heightmap():
	for tile_map_layer: CustomTileMapLayer in get_children():
		for cell_coords: Vector2i in tile_map_layer.get_used_cells():
			if xy_heightmap.has(cell_coords):
				xy_heightmap[cell_coords] = max(xy_heightmap[cell_coords], tile_map_layer.layer);
			else:
				xy_heightmap[cell_coords] = tile_map_layer.layer;

func map_to_local(xy_coords: Vector2i) -> Vector2:
	if !xy_heightmap.has(xy_coords):
		return Vector2i(0,0)
	var z = xy_heightmap[xy_coords];
	var tile_map_layer = get_or_create_tilemap_layer(z);
	return tile_map_layer.map_to_local(xy_coords) - Vector2(0, tile_z*z);
	
func map_to_global(xy_coords: Vector2i) -> Vector2:
	return to_global(map_to_local(xy_coords));

func draw_voxels(voxels: Array[VoxelInfo]) -> void:
	# Validate tile_set before proceeding
	if tile_set == null:
		push_error("TileSet is not assigned!")
		return
	for voxel_info: VoxelInfo in voxels:
		match voxel_info.tile_type:
			Enums.TileType.FROM_ATLAS:
				var tile_map_layer = get_or_create_tilemap_layer(voxel_info.coords.z);
				var coords = Vector2i(voxel_info.coords.x, voxel_info.coords.y);
				var source_id = 0;
				var atlas_coords = voxel_info.atlas_coords;
				tile_map_layer.set_cell(coords, source_id, atlas_coords);
			Enums.TileType.FROM_TERRAIN:
				var layer_paths: Dictionary[int, Array] = {}
				for cell: Vector3i in voxel_info.path:
					if !layer_paths.has(cell.z):
						layer_paths[cell.z] = [];
					layer_paths[cell.z].push_back(Vector2i(cell.x, cell.y));
				for z: int in layer_paths:
					var path = layer_paths[z];
					var tile_map_layer = get_or_create_tilemap_layer(z);
					match voxel_info.terrain_type:
						Enums.TerrainType.CONNECT:
							tile_map_layer.set_cells_terrain_connect(path, voxel_info.terrain_set, voxel_info.terrain, voxel_info.ignore_empty_terrains);
						Enums.TerrainType.PATH:
							tile_map_layer.set_cells_terrain_path(path, voxel_info.terrain_set, voxel_info.terrain, voxel_info.ignore_empty_terrains);

# Add a tool button to clear all layers
@export_tool_button("Clear TileMap", "Callable") var clear_tilemap_action = clear_tilemap

func clear_tilemap() -> void:
	for child: CustomTileMapLayer in get_children():
		remove_child(child);
		child.queue_free()

func get_or_create_tilemap_layer(z: int) -> CustomTileMapLayer:
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
