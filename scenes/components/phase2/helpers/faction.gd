extends Node
class_name Faction

var unit_manager:UnitManager
var faction_id:int
var unit_positions:Dictionary[Vector3i, Unit]
var visible_tiles:Dictionary[Vector3i, int] # Dictionary to make lookups faster (plus it acts like a set)
var explored_tiles:Dictionary[Vector3i, int] # Dictionary to make lookups faster (plus it acts like a set)
var remembered_hostiles:Dictionary[Vector3i, Array]
var remembered_neutrals:Dictionary[Vector3i, Array]
var remembered_friendlies:Dictionary[Vector3i, Array]
var friendly_relations:Dictionary[int, Faction]
var neutral_relations:Dictionary[int, Faction]
var hostile_relations:Dictionary[int, Faction]
var max_tile_memory_time:int = 2

func _init(provided_id:int, unit_manager_ref:UnitManager):
	faction_id = provided_id
	unit_manager = unit_manager_ref

func add_new_relation(relation_type:int, provided_faction_id:int)->void:
	var other_faction_obj:Faction = unit_manager.provide_factions().get(provided_faction_id)
	match relation_type:
		UnitManager.relation_types.HOSTILE:
			hostile_relations[provided_faction_id] = other_faction_obj
		UnitManager.relation_types.NEUTRAL:
			neutral_relations[provided_faction_id] = other_faction_obj
		UnitManager.relation_types.FRIENDLY:
			friendly_relations[provided_faction_id] = other_faction_obj

func change_relation(relation_type:int, provided_faction_id:int)->void:
	var other_faction_obj:Faction = unit_manager.provide_factions().get(provided_faction_id)
	var other_faction_relation = provide_relation_type(provided_faction_id)
	match other_faction_relation:
		UnitManager.relation_types.HOSTILE:
			hostile_relations.erase(provided_faction_id)
		UnitManager.relation_types.NEUTRAL:
			neutral_relations.erase(provided_faction_id)
		UnitManager.relation_types.FRIENDLY:
			friendly_relations.erase(provided_faction_id)
	match relation_type:
		UnitManager.relation_types.HOSTILE:
			hostile_relations[provided_faction_id] = other_faction_obj
		UnitManager.relation_types.NEUTRAL:
			neutral_relations[provided_faction_id] = other_faction_obj
		UnitManager.relation_types.FRIENDLY:
			friendly_relations[provided_faction_id] = other_faction_obj
	scan_all_relations()

func provide_relation_type(other_faction_id)->int:
	if other_faction_id in hostile_relations:
		return UnitManager.relation_types.HOSTILE
	elif other_faction_id in neutral_relations:
		return UnitManager.relation_types.NEUTRAL
	elif other_faction_id in friendly_relations:
		return UnitManager.relation_types.FRIENDLY
	else:
		return UnitManager.relation_types.UNKNOWN

func provide_relations()->Array[Dictionary]:
	return [hostile_relations, neutral_relations, friendly_relations]

func change_unit_position(prior_coord:Vector3i, new_coord)->void:
	var obj_ref_holder = unit_positions.get(prior_coord)
	if prior_coord == new_coord: 
		return
	if unit_positions.get(prior_coord) == null or unit_positions.get(new_coord) != null:
		return
	unit_positions.erase(prior_coord)
	unit_positions[new_coord] = obj_ref_holder

func add_unit(provided_unit:Unit)->void:
	if provided_unit == null: return
	var given_coord:Vector3i = provided_unit.provide_coordinate()
	if given_coord in unit_positions: return
	unit_positions[given_coord] = provided_unit
	provided_unit.unit_type = faction_id
	assemble_faction_vision()
	
func remove_unit(provided_unit:Unit)->void:
	if provided_unit == null or provided_unit._get_unit_type() != faction_id: return
	var given_coord:Vector3i = provided_unit.provide_coordinate()
	if given_coord in unit_positions: 
		unit_positions.erase(given_coord)
		provided_unit.destroy_unit()
		assemble_faction_vision()

func remove_other_faction_unit(provided_unit:Unit)->void:
	var unit_affiliation:int = provided_unit._get_unit_type()
	var unit_coord = provided_unit.provide_coordinate()
	if unit_affiliation in hostile_relations:
		if unit_coord in remembered_hostiles:
			remembered_hostiles.erase(unit_coord)
	elif unit_affiliation in friendly_relations:
		if unit_coord in remembered_friendlies:
			remembered_friendlies.erase(unit_coord)
	elif unit_affiliation in neutral_relations:
		if unit_coord in remembered_neutrals:
			remembered_neutrals.erase(unit_coord)

func assemble_faction_vision()->void:
	var temp_vision_dict:Dictionary[Vector3i, int] = {}
	for current_coordinate in unit_positions:
		var current_unit:Unit = unit_positions.get(current_coordinate)
		var unit_vision = current_unit.provide_vision()
		for tile in unit_vision:
			temp_vision_dict[tile] = 1
			explored_tiles[tile] = 1
	scan_all_relations()

func provide_faction_exploration()->Dictionary[Vector3i, int]:
	return explored_tiles

func provide_faction_vision()->Dictionary[Vector3i, int]:
	return visible_tiles

func is_tile_visible(provided_coordinate:Vector3i)->bool:
	return provided_coordinate in visible_tiles

func has_seen_tile_before(provided_coordinate:Vector3i)->bool:
	return provided_coordinate in explored_tiles

func increment_sight_entry(provided_dictionary:Dictionary[Vector3i, Array])->void:
	for entry in provided_dictionary:
		provided_dictionary[entry][1] += 1
		if provided_dictionary.get(entry)[1] > max_tile_memory_time:
			provided_dictionary.erase(entry)

func tile_allegiance_check(other_faction_units:Dictionary[Vector3i, Unit], provided_dictionary:Dictionary[Vector3i, Array])->void: 
	for tile in other_faction_units:
		if tile in visible_tiles:
			provided_dictionary[tile] = [other_faction_units.get(tile), 0]

func scan_all_relations()->void:
	increment_sight_entry(remembered_friendlies)
	increment_sight_entry(remembered_neutrals)	
	increment_sight_entry(remembered_hostiles)
	var active_factions:Dictionary[int, Faction] = unit_manager.provide_factions()
	for faction_id_entry in active_factions:
		if faction_id_entry == faction_id:
			continue
		var other_faction_units:Dictionary[Vector3i, Unit] = active_factions.get(faction_id_entry).provide_faction_units()
		if faction_id_entry in hostile_relations:
			tile_allegiance_check(other_faction_units, remembered_hostiles)
		elif faction_id_entry in friendly_relations:
			tile_allegiance_check(other_faction_units, remembered_friendlies)
		else:
			tile_allegiance_check(other_faction_units, remembered_neutrals)	

# This function should be called in conjunction with assemble_vision
func scan_for_hostiles()->void:
	increment_sight_entry(remembered_hostiles)
	var active_factions = unit_manager.provide_factions()
	for faction_id_entry in active_factions:
		if faction_id_entry == faction_id:
			continue
		if faction_id_entry in hostile_relations:
			var other_faction_units = active_factions.get(faction_id_entry).provide_units()
			tile_allegiance_check(other_faction_units, remembered_hostiles)

func can_we_see_a_unit_there(provided_coordinate:Vector3i)->bool:
	if provided_coordinate in remembered_hostiles:
		return true
	elif provided_coordinate in remembered_neutrals:
		return true
	elif provided_coordinate in remembered_friendlies:
		return true
	elif provided_coordinate in unit_positions:
		return true
	return false
		
func is_there_a_known_hostile_there(provided_coordinate:Vector3i)->bool:
	return provided_coordinate in remembered_hostiles
					
func is_this_unit_hostile(provided_unit:Unit)->bool:
	var unit_faction_id:int = provided_unit._get_unit_type()
	return unit_faction_id in hostile_relations
	
func is_this_unit_neutral(provided_unit:Unit)->bool:
	var unit_faction_id:int = provided_unit._get_unit_type()
	return unit_faction_id in neutral_relations
	
func is_this_unit_friendly(provided_unit:Unit)->bool:
	var unit_faction_id:int = provided_unit._get_unit_type()
	return unit_faction_id in friendly_relations
	
func is_this_our_unit(provided_unit:Unit)->bool:
	var unit_faction_id:int = provided_unit._get_unit_type()
	return unit_faction_id == faction_id

func provide_hostile_units()->Dictionary[Vector3i, Array]:
	return remembered_hostiles
	
func provide_neutral_units()->Dictionary[Vector3i, Array]:
	return remembered_neutrals
	
func provide_friendly_units()->Dictionary[Vector3i, Array]:
	return remembered_friendlies
	
func provide_faction_units()->Dictionary[Vector3i, Unit]:
	return unit_positions

	
