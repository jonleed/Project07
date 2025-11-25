extends Unit_Manager
class_name NPC_Manager

var debugging_allowed:bool = false
var pathfinder:Pathfinder
func _ready():
	get_units()
	if units.size() == 0:
		end_turn()
	pathfinder = Pathfinder.new(get_parent().get_parent().get_child(0))
	pathfinder._rebuild_connections()
	faction_name = "Hostile Faction"
	# print(pathfinder)

func _step_turn():
	var unused_units = get_unused_units()
	# print("HOSTILE: ", unused_units, " ", units, " ", get_children())
	for unit in unused_units:
		unit.execute_turn()
	unused_units = get_unused_units()
	
	# Base case - No unused units remaining
	if unused_units.is_empty():
		end_turn()

func end_turn() -> void:
	modulate_important_enemy()
	print(faction_name, " Turn End")
	is_active = false
	emit_signal("faction_turn_complete")

var most_recent_modulated_enemy:Node2D = null

func modulate_important_enemy()->void:
	var chosen_enemy:Node2D = get_most_important_target()
	if chosen_enemy:
		if most_recent_modulated_enemy:
			most_recent_modulated_enemy.modulate = Color.WHITE
		most_recent_modulated_enemy = chosen_enemy
		chosen_enemy.modulate = Color.RED

func get_most_important_target()->Entity:
	var ent_dict:Dictionary[Entity,int] = {}
	var answer:Entity = null
	
	for unit in units:
		if not unit is Hostile_Unit:
			continue
		unit.determine_enemy_we_care_about()
		var cared_unit:Entity = unit.enemy_that_we_care_about
		ent_dict[cared_unit] = ent_dict.get_or_add(cared_unit,0)+1
		if ent_dict.get(cared_unit,0) > ent_dict.get(answer,0):
			answer = cared_unit
	print(ent_dict)
	return answer


# If we wait for onready, we seem to get issues with it being null?
@onready var npc_unit_packed:PackedScene = preload("res://scenes/components/phase2/unit/NPC Unit.tscn")

##use this in tandem with add_unit to create a unit resource from scratch, we do not edit these resources directly
func create_unit_from_res(res:UnitResource)->Hostile_Unit:
	if npc_unit_packed == null:
		npc_unit_packed = preload("res://scenes/components/phase2/unit/NPC Unit.tscn")
	
	var un :Hostile_Unit = npc_unit_packed.instantiate()
	add_child(un)
	un.u_res = res
	un.load_unit_res(res)
	un.ready_entity()
	un.add_to_group("Unit")
	un.add_to_group("Enemy Unit")
	un.health_changed.connect(remove_unit)
	return un
	
func get_pathfinder() -> Pathfinder:
	return pathfinder
