class_name VoxelInfo
extends Resource

@export var tile_type: Enums.TileType = Enums.TileType.FROM_ATLAS;

# Atlas Properties - only visible when tile_type is FROM_ATLAS
@export_group("Atlas Properties")
@export var coords: Vector3i = Vector3i(0,0,0);
@export var source_id: int = 0
@export var atlas_coords: Vector2i = Vector2i(0,0)
@export var alternative_tile: int = 0

# Terrain Properties - only visible when tile_type is FROM_TERRAIN
@export_group("Terrain Properties")
@export var path: Array[Vector3i] = []
@export var terrain_set: int = 0
@export var terrain: int = 0
@export var ignore_empty_terrains: bool = true
@export var terrain_type: Enums.TerrainType = Enums.TerrainType.PATH;


static func from_atlas(_coords: Vector3i, _source_id: int = 0, _atlas_coords: Vector2i = Vector2i(0,0), _alternative_tile: int = 0):
	var res = VoxelInfo.new();
	res.tile_type = Enums.TileType.FROM_ATLAS;
	res.coords = _coords;
	res.source_id = _source_id;
	res.atlas_coords = _atlas_coords;
	res.alternative_tile = _alternative_tile;
	return res;

static func from_terrain(_path: Array[Vector3i], _terrain_set: int = 0, _terrain: int = 0, _ignore_empty_terrains: bool = true, _terrain_type: Enums.TerrainType = Enums.TerrainType.PATH):
	var res = VoxelInfo.new();
	res.tile_type = Enums.TileType.FROM_TERRAIN;
	res.path = _path;
	res.terrain_set = _terrain_set;
	res.terrain = _terrain;
	res.ignore_empty_terrains = _ignore_empty_terrains;
	res.terrain_type = _terrain_type;
	return res;
