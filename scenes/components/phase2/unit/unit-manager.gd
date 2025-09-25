extends Node

enum unit_types {
	ENEMY,
	FRIENDLY,
	PLAYER
}

var pathfinder:Pathfinder

func _init() -> void:
	pathfinder = Pathfinder.new()
	
func _ready() -> void:
	pass
	
func _create_unit(provided_unit_type:int, coordinate:Vector2i) -> Unit:
	var new_unit = null
	match provided_unit_type:
		unit_types.ENEMY:
			Enemy_Unit.new(pathfinder, coordinate)
			pass
		unit_types.FRIENDLY:
			Friendly_Unit.new(pathfinder, coordinate)
		unit_types.PLAYER:
			Player_Unit.new(pathfinder, coordinate)
	return new_unit
