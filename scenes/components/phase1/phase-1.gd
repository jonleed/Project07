extends Node

@onready var spawn_coords: Array[Vector2i] = [
	Vector2i(24,11),
	Vector2i(24,10),
	Vector2i(26,8),
	Vector2i(27,8)
]

@export var map_manager: MapManager
@export var player_ui: Node
@onready var unit_packed: PackedScene = preload("res://scenes/components/phase2/unit/Player Unit.tscn")


func _ready():
	player_ui.connect("unit_display_update", Callable(self, "_on_unit_display_update"))

func create_unit_from_res(res:UnitResource) -> Unit:
	var un: Unit = unit_packed.instantiate()
	add_child(un)
	un.u_res = res
	un.load_unit_res(res)
	un.ready_entity()
	un.add_to_group("Unit")
	un.add_to_group("Player Unit")
	return un

func _on_unit_display_update(unit_array: Array):
	# Remove all existing player units
	for old_unit in get_tree().get_nodes_in_group("Player Unit"):
		# Remove from MapManager if present
		if map_manager.map_dict.has(old_unit.cur_pos):
			map_manager.map_dict.erase(old_unit.cur_pos)
		old_unit.queue_free()
	
	# Spawn in Units
	for i in range(unit_array.size()):
		var res: UnitResource = unit_array[i]
		var unit: Unit = create_unit_from_res(res)

		unit.scale = Vector2(4, 4)
		
		# Spawn on preset coordinates
		var coord: Vector2i = spawn_coords[i]
		if not map_manager.spawn_entity(unit, coord):
			printerr("Failed to spawn unit %s at %s" % [res.unit_name, coord])
		else:
			unit.cur_pos = coord
			unit.global_position = map_manager.coords_to_glob(coord)
