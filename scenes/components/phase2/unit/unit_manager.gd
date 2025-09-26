extends Node

enum unit_types {
	ENEMY,
	FRIENDLY,
	PLAYER
}

var pathfinder:Pathfinder
var primer

func _init(primer:Object) -> void:
	pathfinder = Pathfinder.new(primer.get_terrain_tile_map())
	
func _ready() -> void:
	pass
	
func _create_unit(provided_unit_type:int, coordinate:Vector2i, info:Dictionary) -> Unit:
	var new_unit = null
	match provided_unit_type:
		unit_types.ENEMY:
			Enemy_Unit.new(pathfinder, coordinate, info)
			pass
		unit_types.FRIENDLY:
			Friendly_Unit.new(pathfinder, coordinate, info)
		unit_types.PLAYER:
			Player_Unit.new(pathfinder, coordinate, info)
	return new_unit
