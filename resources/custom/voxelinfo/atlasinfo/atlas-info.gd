class_name AtlasInfo
extends Resource

@export var source_id: int = -1
@export var atlas_coords: Vector2i = Vector2i(-1,-1)
@export var alternative_tile: int = 0

func _init(_source_id: int = -1, _atlas_coords: Vector2i = Vector2i(-1,-1), _alternative_tile: int = 0) -> void:
	self.source_id = _source_id;
	self.atlas_coords = _atlas_coords;
	self.alternative_tile = _alternative_tile;
