class_name TerrainOrAtlasInfo;
extends Resource;

@export var type := Enums.TileType.FROM_ATLAS;
@export var atlas_info: AtlasInfo = null;
@export var terrain_info: TerrainInfo = null;

static func from_defined_atlas(_atlas: AtlasInfo) -> TerrainOrAtlasInfo:
	var res := TerrainOrAtlasInfo.new();
	res.type = Enums.TileType.FROM_ATLAS;
	res.atlas_info = _atlas;
	return res;

static func from_defined_terrain(_terrain: TerrainInfo) -> TerrainOrAtlasInfo:
	var res := TerrainOrAtlasInfo.new();
	res.type = Enums.TileType.FROM_TERRAIN;
	res.terrain_info = _terrain;
	return res;
