@tool
class_name VoxelInfo
extends Resource

@export var tile_type := Enums.TileType.FROM_ATLAS;

# Atlas Properties - only visible when tile_type is FROM_ATLAS
@export_group("From Atlas")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var enable_atlas: bool:
	get:
		return tile_type == Enums.TileType.FROM_ATLAS;
	set(value):
		tile_type = Enums.TileType.FROM_ATLAS if value else Enums.TileType.FROM_TERRAIN;
@export var coords := Vector3i(0, 0, 0);
@export var atlas_info: AtlasInfo = null;

# Terrain Properties - only visible when tile_type is FROM_TERRAIN
@export_group("From Terrain")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var enable_terrain: bool:
	get:
		return tile_type == Enums.TileType.FROM_TERRAIN;
	set(value):
		tile_type = Enums.TileType.FROM_TERRAIN if value else Enums.TileType.FROM_ATLAS;
@export var path: Array[Vector3i] = []
@export var terrain_info: TerrainInfo = null;


static func from_atlas(_coords: Vector3i, _source_id := 0, _atlas_coords := Vector2i(0, 0), _alternative_tile := 0):
	var res := VoxelInfo.new();
	res.tile_type = Enums.TileType.FROM_ATLAS;
	res.coords = _coords;
	res.atlas_info = AtlasInfo.new(_source_id, _atlas_coords, _alternative_tile);
	return res;

static func from_defined_atlas(_coords: Vector3i, _atlas_info: AtlasInfo):
	var res := VoxelInfo.new();
	res.tile_type = Enums.TileType.FROM_ATLAS;
	res.coords = _coords;
	res.atlas_info = _atlas_info;
	return res;

static func from_terrain(_path: Array[Vector3i], _terrain_set := 0, _terrain := 0, _ignore_empty_terrains := true, _terrain_type := Enums.TerrainType.PATH):
	var res := VoxelInfo.new();
	res.tile_type = Enums.TileType.FROM_TERRAIN;
	res.path = _path;
	res.terrain_info = TerrainInfo.new(_terrain_set, _terrain, _ignore_empty_terrains, _terrain_type)
	return res;

static func from_defined_terrain(_path: Array[Vector3i], _terrain_info: TerrainInfo):
	var res := VoxelInfo.new();
	res.tile_type = Enums.TileType.FROM_TERRAIN;
	res.path = _path;
	res.terrain_info = _terrain_info;
	return res;
