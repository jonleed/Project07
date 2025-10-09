@tool
class_name TerrainOrAtlasInfo;
extends Resource;

@export var type := Enums.TileType.FROM_ATLAS;
@export_group("From Atlas")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var enable_atlas: bool:
	get:
		return type == Enums.TileType.FROM_ATLAS;
	set(value):
		type = Enums.TileType.FROM_ATLAS if value else Enums.TileType.FROM_TERRAIN;
@export var atlas_info: AtlasInfo = null;
@export_group("From Terrain")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var enable_terrain: bool:
	get:
		return type == Enums.TileType.FROM_TERRAIN;
	set(value):
		type = Enums.TileType.FROM_TERRAIN if value else Enums.TileType.FROM_ATLAS;
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
