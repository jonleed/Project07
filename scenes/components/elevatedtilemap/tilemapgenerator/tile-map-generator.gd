@tool
class_name TileMapGenerator;
extends Node2D;

## Height difference between layers in px, i.e. how much to shift an item from `(x, y, z)` to `(x, y, z+1)`
@export var tile_z: int = 8;

## Tile Set to use
@export var tile_set: TileSet;

@export_tool_button("Generate", "Callable") var generate_terrain_action = generate_terrain
@export_tool_button("Clear", "Callable") var clear_terrain_action = clear_terrain

@export_group("Terrain Generation")
@export var heightmap_size_x: int = 25;
@export var heightmap_size_y: int = 25;
@export var heightmap_size_z: int = 25;  # Number of possible height values (0 to heightmap_size_z-1)
@export var noise_scale: float = 4.0;

var max_seed_value: int = 999999999; # There seems to be a max seed for FastNoiseLite

@export_subgroup("Tile Info")
@export var top_tile_info: TerrainOrAtlasInfo = TerrainOrAtlasInfo.from_defined_atlas(AtlasInfo.new(0, Vector2i(1,0)));
@export var under_tile_info: TerrainOrAtlasInfo = TerrainOrAtlasInfo.from_defined_atlas(AtlasInfo.new(0, Vector2i(0,0)));
@export var stone_tile_info: TerrainOrAtlasInfo = TerrainOrAtlasInfo.from_defined_atlas(AtlasInfo.new(0, Vector2i(2,0)))

@export_group("Water Generation")
@export var enable_water: bool = true;
#@export var water_tile_info: TerrainOrAtlasInfo = TerrainOrAtlasInfo.from_defined_atlas(AtlasInfo.new(0, Vector2i(7,0)))
@export var water_tile_info: TerrainOrAtlasInfo = TerrainOrAtlasInfo.from_defined_terrain(TerrainInfo.new(0,0, true, Enums.TerrainType.CONNECT, -1, 1, -1, -1))
@export var water_level: int = 13

@export_group("Fog Generation")
@export var enable_fog: bool = false;
@export var fog_tile_info: TerrainOrAtlasInfo = TerrainOrAtlasInfo.from_defined_atlas(AtlasInfo.new(0, Vector2i(1,9)))
@export var is_fog_on_water = false;

func create_elevated_tile_map(_name: String) -> ElevatedTileMap:
	var elevated_tile_map: ElevatedTileMap = ElevatedTileMap.new();
	elevated_tile_map.tile_set = tile_set;
	elevated_tile_map.tile_z = tile_z;
	elevated_tile_map.name = _name;
	add_child(elevated_tile_map)
	elevated_tile_map.owner = get_tree().edited_scene_root;
	return elevated_tile_map;

func create_terrain_tile_map(_name: String) -> TerrainTileMap:
	var terrain_tile_map: TerrainTileMap = TerrainTileMap.new();
	terrain_tile_map.tile_set = tile_set;
	terrain_tile_map.tile_z = tile_z;
	terrain_tile_map.name = _name;
	add_child(terrain_tile_map)
	terrain_tile_map.owner = get_tree().edited_scene_root;
	return terrain_tile_map;

func generate_terrain() -> void:
	clear_terrain();
	
	var voxels: GenerateVoxelsOutput = generate_voxels();
	
	var terrain_tile_map: TerrainTileMap = create_terrain_tile_map("TerrainTileMap");
	
	terrain_tile_map.draw_voxels(voxels.terrain_voxels)
	if enable_water:
		terrain_tile_map.draw_voxels(voxels.water_voxels)
	
	if enable_fog:
		var fog_tile_map: ElevatedTileMap = create_elevated_tile_map("FogTileMap");
		
		fog_tile_map.draw_voxels(voxels.fog_voxels);

func clear_terrain() -> void:
	for elevated_tile_map: ElevatedTileMap in [get_terrain(), get_fog()]:
		if elevated_tile_map != null:
			remove_child(elevated_tile_map);
			elevated_tile_map.queue_free();

func get_terrain() -> TerrainTileMap:
	return find_child("TerrainTileMap");

func get_fog() -> ElevatedTileMap:
	return find_child("FogTileMap");

# Helper function to process tile info and append appropriate voxels to the target array
func _process_tile_info(target_voxels: Array[VoxelInfo], coords: Array[Vector3i], tile_info: TerrainOrAtlasInfo) -> void:
	match tile_info.type:
		Enums.TileType.FROM_ATLAS:
			target_voxels.append_array(coords.map(func(coord): return VoxelInfo.from_defined_atlas(coord, tile_info.atlas_info)));
		Enums.TileType.FROM_TERRAIN:
			target_voxels.append(VoxelInfo.from_defined_terrain(coords, tile_info.terrain_info));

class GenerateVoxelsOutput:
	var terrain_voxels: Array[VoxelInfo] = [];
	var water_voxels: Array[VoxelInfo] = [];
	var fog_voxels: Array[VoxelInfo] = [];

func generate_voxels() -> GenerateVoxelsOutput:
	var res: GenerateVoxelsOutput = GenerateVoxelsOutput.new();
	var noise: FastNoiseLite = FastNoiseLite.new();
	# Seed has a max value
	noise.seed = randi() % max_seed_value;
	
	var terrain_voxels: Array[VoxelInfo] = [];
	var water_voxels: Array[VoxelInfo] = [];
	var fog_voxels: Array[VoxelInfo] = [];
	
	var terrain_top_coords: Array[Vector3i] = [];
	var terrain_under_coords: Array[Vector3i] = [];
	var terrain_stone_coords: Array[Vector3i] = [];
	
	var water_coords: Array[Vector3i] = [];
	
	var fog_coords: Array[Vector3i] = [];
	
	for x: int in range(heightmap_size_x):
		for y: int in range(heightmap_size_y):
			# noise.get_noise_2d returns values between -1 and 1
			# Adding 1 gives 0-2, dividing by 2 gives 0-1
			# Multiplying by (heightmap_size_z - 1) gives height values 0-(heightmap_size_z-1)
			var height: int = floor((heightmap_size_z - 1)*(noise.get_noise_2d(noise_scale*x, noise_scale*y) + 1)/2);
			for z: int in range(height):
				if z > height - 5:
					terrain_under_coords.append(Vector3i(x,y,z));
				else:
					terrain_stone_coords.append(Vector3i(x,y,z));
			if not (height < water_level and enable_water):
				terrain_top_coords.append(Vector3i(x,y,height));
			else:
				terrain_under_coords.append(Vector3i(x,y,height));
			if enable_fog and (is_fog_on_water or height >= water_level):
				fog_coords.append(Vector3i(x,y,max(height, water_level)+1));
			for _z: int in range(water_level-height):
				var z: int = _z+height+1;
				water_coords.append(Vector3i(x,y,z))
	
	# Process terrain tile info
	_process_tile_info(terrain_voxels, terrain_stone_coords, stone_tile_info);
	_process_tile_info(terrain_voxels, terrain_under_coords, under_tile_info);
	_process_tile_info(terrain_voxels, terrain_top_coords, top_tile_info);
	
	# Process water tile info
	_process_tile_info(water_voxels, water_coords, water_tile_info);
	
	# Process fog tile info
	_process_tile_info(fog_voxels, fog_coords, fog_tile_info);
	
	res.terrain_voxels = terrain_voxels;
	res.water_voxels = water_voxels;
	res.fog_voxels = fog_voxels;
	return res;
