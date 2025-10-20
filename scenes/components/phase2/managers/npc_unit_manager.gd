extends Unit_Manager
class_name NPC_Manager

var pathfinder:Pathfinder
func _ready():
	get_units()
	if units.size() == 0:
		end_turn()
	pathfinder = Pathfinder.new(get_parent().get_parent().get_child(0))
	pathfinder._rebuild_connections()
	faction_name = "Hostile Faction"
	print(pathfinder)

func _step_turn():
	var unused_units = get_unused_units()
	for unit in unused_units:
		unit.execute_turn()
	unused_units = get_unused_units()
	
	# Base case - No unused units remaining
	if unused_units.is_empty():
		end_turn()

@onready var npc_unit_packed:PackedScene = preload("res://scenes/components/phase2/unit/NPC Unit.tscn")

##use this in tandem with add_unit to create a unit resource from scratch, we do not edit these resources directly
func create_unit_from_res(res:UnitResource)->Hostile_Unit:
	var un :Hostile_Unit = npc_unit_packed.instantiate()
	add_child(un)
	un.u_res = res
	un.load_unit_res(res)
	un.ready_entity()
	un.add_to_group("Unit")
	un.add_to_group("Enemy Unit")
	return un

func get_random_generator():
	return get_parent().get_random_generator()
	
func get_pathfinder() -> Pathfinder:
	return pathfinder
