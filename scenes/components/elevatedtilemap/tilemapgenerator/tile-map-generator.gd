@tool
class_name TileMapGenerator;
extends Node2D;

## Height difference between layers in px, i.e. how much to shift an item from `(x, y, z)` to `(x, y, z+1)`
@export var tile_z: int = 8;

## Tile Set to use
@export var tile_set: TileSet;

@export_tool_button("Generate", "Callable") var generate_terrain_action = GenerateTerrain
@export_tool_button("Clear", "Callable") var clear_terrain_action = ClearTerrain

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

func GenerateTerrain() -> void:
	ClearTerrain();
	
	var voxels: GenerateVoxelsOutput = GenerateVoxels();
	
	var terrain_tile_map = ElevatedTileMap.new();
	terrain_tile_map.tile_set = tile_set;
	terrain_tile_map.tile_z = tile_z;
	terrain_tile_map.name = "TerrainTileMap";
	add_child(terrain_tile_map);
	terrain_tile_map.owner = get_tree().edited_scene_root
	
	terrain_tile_map.DrawVoxels(voxels.terrain_voxels)
	terrain_tile_map.DrawVoxels(voxels.water_voxels)
	
	if enable_fog:
		var fog_tile_map = ElevatedTileMap.new();
		fog_tile_map.tile_set = tile_set;
		fog_tile_map.tile_z = tile_z;
		fog_tile_map.name = "FogTileMap";
		add_child(fog_tile_map);
		fog_tile_map.owner = get_tree().edited_scene_root
		
		fog_tile_map.DrawVoxels(voxels.fog_voxels);

func ClearTerrain() -> void:
	var terrain_tile_map = GetTerrain();
	if terrain_tile_map != null:
		remove_child(terrain_tile_map);
		terrain_tile_map.queue_free();
	var fog_tile_map = GetFog();
	if fog_tile_map != null:
		remove_child(fog_tile_map);
		fog_tile_map.queue_free();

func GetTerrain() -> ElevatedTileMap:
	return find_child("TerrainTileMap");

func GetFog() -> ElevatedTileMap:
	return find_child("FogTileMap");

class GenerateVoxelsOutput:
	var terrain_voxels: Array[VoxelInfo] = [];
	var water_voxels: Array[VoxelInfo] = [];
	var fog_voxels: Array[VoxelInfo] = [];

func GenerateVoxels() -> GenerateVoxelsOutput:
	var res = GenerateVoxelsOutput.new();
	var noise = FastNoiseLite.new();
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
			var height = floor((heightmap_size_z - 1)*(noise.get_noise_2d(noise_scale*x, noise_scale*y) + 1)/2);
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
			for _z in range(water_level-height):
				var z = _z+height+1;
				water_coords.append(Vector3i(x,y,z))
	
	match stone_tile_info.type:
		Enums.TileType.FROM_ATLAS:
			terrain_voxels.append_array( terrain_stone_coords.map(func(coord): return VoxelInfo.from_defined_atlas(coord, stone_tile_info.atlas_info)) );
		Enums.TileType.FROM_TERRAIN:
			terrain_voxels.append(VoxelInfo.from_defined_terrain(terrain_stone_coords, stone_tile_info.terrain_info));
	match under_tile_info.type:
		Enums.TileType.FROM_ATLAS:
			terrain_voxels.append_array( terrain_under_coords.map(func(coord): return VoxelInfo.from_defined_atlas(coord, under_tile_info.atlas_info)) );
		Enums.TileType.FROM_TERRAIN:
			terrain_voxels.append(VoxelInfo.from_defined_terrain(terrain_under_coords, under_tile_info.terrain_info));
	match top_tile_info.type:
		Enums.TileType.FROM_ATLAS:
			terrain_voxels.append_array( terrain_top_coords.map(func(coord): return VoxelInfo.from_defined_atlas(coord, top_tile_info.atlas_info)) );
		Enums.TileType.FROM_TERRAIN:
			terrain_voxels.append(VoxelInfo.from_defined_terrain(terrain_top_coords, top_tile_info.terrain_info));
	
	match water_tile_info.type:
		Enums.TileType.FROM_ATLAS:
			water_voxels.append_array( water_coords.map(func(coord): return VoxelInfo.from_defined_atlas(coord, water_tile_info.atlas_info)) );
		Enums.TileType.FROM_TERRAIN:
			water_voxels.append(VoxelInfo.from_defined_terrain(water_coords, water_tile_info.terrain_info));
	
	match fog_tile_info.type:
		Enums.TileType.FROM_ATLAS:
			fog_voxels.append_array( fog_coords.map(func(coord): return VoxelInfo.from_defined_atlas(coord, fog_tile_info.atlas_info)) );
		Enums.TileType.FROM_TERRAIN:
			fog_voxels.append(VoxelInfo.from_defined_terrain(fog_coords, fog_tile_info.terrain_info));
	
	res.terrain_voxels = terrain_voxels;
	res.water_voxels = water_voxels;
	res.fog_voxels = fog_voxels;
	return res;
