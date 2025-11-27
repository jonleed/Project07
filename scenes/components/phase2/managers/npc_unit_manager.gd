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
		#print("Turn log: ",unit.turn_log)
	unused_units = get_unused_units()
	
	# Base case - No unused units remaining
	if unused_units.is_empty():
		end_turn()

func end_turn() -> void:
	modulate_important_enemy()
	remove_retreating_units()
	print(faction_name, " Turn End")
	is_active = false
	emit_signal("faction_turn_complete")

var most_recent_modulated_enemy:Node2D = null

func modulate_important_enemy()->void:
	var chosen_enemy:Node2D = get_most_important_target()
	if chosen_enemy:
		if most_recent_modulated_enemy:
			most_recent_modulated_enemy.target.hide()
		most_recent_modulated_enemy = chosen_enemy
		chosen_enemy.target.show()

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

func remove_retreating_units():
	var removing_tiles:Array[Vector2i] = map_manager.remove_layer.get_used_cells()
	for tile:Vector2i in removing_tiles:
		var tile_value = map_manager.map_dict.get(tile)
		if tile_value is Unit:
			print("Removing Unit: ",tile_value)
			if tile_value in units:
				map_manager.map_dict.erase(tile_value.cur_pos)
				map_manager.update_astar_solidity(tile_value.cur_pos)
				units.erase(tile_value)
				tile_value.queue_free()
			

signal update_kill_count()
func remove_unit(unit: Unit) -> void:
	if unit.health>0:
		return
	if unit in units:
		map_manager.map_dict.erase(unit.cur_pos)
		map_manager.update_astar_solidity(unit.cur_pos)
		units.erase(unit)
		unit.queue_free()
		update_kill_count.emit()
