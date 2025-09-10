class_name TerrainInfo
extends Resource

@export var terrain_set: int = 0
@export var terrain: int = 0
@export var ignore_empty_terrains: bool = true
@export var terrain_type: Enums.TerrainType = Enums.TerrainType.PATH;

func _init(_terrain_set: int = 0, _terrain: int = 0, _ignore_empty_terrains: bool = true, _terrain_type: Enums.TerrainType = Enums.TerrainType.PATH) -> void:
	self.terrain_type = _terrain_type;
	self.terrain_set = _terrain_set;
	self.terrain = _terrain;
	self.ignore_empty_terrains = _ignore_empty_terrains;
