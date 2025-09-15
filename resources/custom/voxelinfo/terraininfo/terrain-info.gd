class_name TerrainInfo
extends Resource

@export var terrain_set: int = 0
@export var terrain: int = 0
@export var ignore_empty_terrains: bool = true
@export var terrain_type: Enums.TerrainType = Enums.TerrainType.PATH;
@export var raw_middle_terrain_set: int = -1;
@export var raw_middle_terrain: int = -1;
@export var raw_bottom_terrain_set: int = -1;
@export var raw_bottom_terrain: int = -1;

static func get_middle_terrain_set(terrain_info: TerrainInfo)->int:
	return terrain_info.terrain_set if terrain_info.raw_middle_terrain_set < 0 else terrain_info.raw_middle_terrain_set;
static func get_middle_terrain(terrain_info: TerrainInfo)->int:
	return terrain_info.terrain if terrain_info.raw_middle_terrain < 0 else terrain_info.raw_middle_terrain;
static func get_bottom_terrain_set(terrain_info: TerrainInfo)->int:
	return get_middle_terrain_set(terrain_info) if terrain_info.raw_bottom_terrain_set < 0 else terrain_info.raw_bottom_terrain_set;
static func get_bottom_terrain(terrain_info: TerrainInfo)->int:
	return get_middle_terrain(terrain_info) if terrain_info.raw_bottom_terrain < 0 else terrain_info.raw_bottom_terrain;

func _init(_terrain_set: int = 0, _terrain: int = 0, _ignore_empty_terrains: bool = true, _terrain_type: Enums.TerrainType = Enums.TerrainType.PATH, _middle_terrain_set: int = -1, _middle_terrain: int = -1, _bottom_terrain_set: int = -1, _bottom_terrain: int = -1) -> void:
	self.terrain_type = _terrain_type;
	self.terrain_set = _terrain_set;
	self.terrain = _terrain;
	self.ignore_empty_terrains = _ignore_empty_terrains;
	self.raw_middle_terrain_set = _middle_terrain_set;
	self.raw_middle_terrain = _middle_terrain;
	self.raw_bottom_terrain_set = _bottom_terrain_set;
	self.raw_bottom_terrain = _bottom_terrain;
