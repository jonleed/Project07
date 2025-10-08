extends Manager
class_name NPC_Manager

var friendly_relations:Dictionary[int, Manager]
var neutral_relations:Dictionary[int, Manager]
var hostile_relations:Dictionary[int, Manager]

func manager_specific_setup(relationship_to_player:int)->void:
	# Any initialization that needs to be done when the manager is first made
	var manager_dict:Dictionary[int, Manager] = turn_manager.provide_managers()
	for manager_id_entry in manager_dict:
		if manager_id_entry != Globals.PLAYER_MANAGER_ID and manager_id_entry != Globals.TRAP_MANAGER_ID:
			var pulled_manager:NPC_Manager = manager_dict.get(manager_id_entry)
			var pulled_manager_relations:Array = pulled_manager.provide_relations()
			if (manager_id not in pulled_manager_relations[TurnManager.relation_types.HOSTILE]) and (manager_id not in pulled_manager_relations[TurnManager.relation_types.NEUTRAL] and (manager_id not in pulled_manager_relations[TurnManager.relation_types.FRIENDLY])):
				pulled_manager.add_new_relation(TurnManager.relation_types.HOSTILE, manager_id)
		elif manager_id_entry == Globals.TRAP_MANAGER_ID:
			add_new_relation(TurnManager.relation_types.HOSTILE, manager_id_entry)
		else:
			match relationship_to_player:
				TurnManager.relation_types.HOSTILE:
					add_new_relation(TurnManager.relation_types.HOSTILE, manager_id_entry)
				TurnManager.relation_types.NEUTRAL:
					add_new_relation(TurnManager.relation_types.NEUTRAL, manager_id_entry)
				TurnManager.relation_types.FRIENDLY:
					add_new_relation(TurnManager.relation_types.FRIENDLY, manager_id_entry)

func execute_turn()->void:
	# Turn actions
	emit_signal("turn_complete")


# PURPOSE: This adds a new 'relationship' entry in any of the three relations dictionaries
# ADDENDUMN: Relations are used for NPC AI to know how to respond to units from different managers
func add_new_relation(relation_type:int, provided_manager_id:int)->void:
	var other_manager_obj:Manager = turn_manager.provide_managers().get(provided_manager_id)
	match relation_type:
		TurnManager.relation_types.HOSTILE:
			hostile_relations[provided_manager_id] = other_manager_obj
		TurnManager.relation_types.NEUTRAL:
			neutral_relations[provided_manager_id] = other_manager_obj
		TurnManager.relation_types.FRIENDLY:
			friendly_relations[provided_manager_id] = other_manager_obj

# PURPOSE: Adjust the relationship entry for a manager.
# ADDENDUMN: This is NOT specifically made to make relations dynamic, but moreso as an aid during initialization; (But it CAN do that)
func change_relation(relation_type:int, provided_manager_id:int)->void:
	var other_manager_obj:Manager = turn_manager.provide_managers().get(provided_manager_id)
	var other_manager_relation = provide_relation_type(provided_manager_id)
	match other_manager_relation:
		TurnManager.relation_types.HOSTILE:
			hostile_relations.erase(provided_manager_id)
		TurnManager.relation_types.NEUTRAL:
			neutral_relations.erase(provided_manager_id)
		TurnManager.relation_types.FRIENDLY:
			friendly_relations.erase(provided_manager_id)
	match relation_type:
		TurnManager.relation_types.HOSTILE:
			hostile_relations[provided_manager_id] = other_manager_obj
		TurnManager.relation_types.NEUTRAL:
			neutral_relations[provided_manager_id] = other_manager_obj
		TurnManager.relation_types.FRIENDLY:
			friendly_relations[provided_manager_id] = other_manager_obj
	scan_all_relations()

# PURPOSE: Return the type of relationship THIS MANAGER has with another Manager. (How this manager views another)
func provide_relation_type(other_manager_id)->int:
	if other_manager_id in hostile_relations:
		return TurnManager.relation_types.HOSTILE
	elif other_manager_id in neutral_relations:
		return TurnManager.relation_types.NEUTRAL
	elif other_manager_id in friendly_relations:
		return TurnManager.relation_types.FRIENDLY
	else:
		return TurnManager.relation_types.UNKNOWN

# PURPOSE: Provides an array of all three relationship dictionaries
func provide_relations()->Array[Dictionary]:
	return [hostile_relations, neutral_relations, friendly_relations]

# PURPOSE: Erases all entries referencing another manager's (soon-to-be-deleted) unit
func remove_ref_to_other_manager_unit(provided_unit:Unit)->void:
	var unit_affiliation:int = provided_unit.get_manager_id()
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

# PURPOSE: Mark what Units this manager can see and where, assigning them to 'hostile', 'neutral', and 'friendly' based off of relations
func scan_all_relations()->void:
	increment_sight_entry(remembered_friendlies)
	increment_sight_entry(remembered_neutrals)	
	increment_sight_entry(remembered_hostiles)
	var active_managers:Dictionary[int, Manager] = turn_manager.provide_managers()
	for manager_id_entry in active_managers:
		if manager_id_entry == manager_id:
			continue
		var other_manager_units:Dictionary[Vector3i, Entity] = active_managers.get(manager_id_entry).provide_manager_units()
		if manager_id_entry in hostile_relations:
			tile_memory_update_and_check(other_manager_units, remembered_hostiles)
		elif manager_id_entry in friendly_relations:
			tile_memory_update_and_check(other_manager_units, remembered_friendlies)
		else:
			tile_memory_update_and_check(other_manager_units, remembered_neutrals)	

# PURPOSE: scan_all_relations, but only for hostile units
func scan_for_hostiles()->void:
	increment_sight_entry(remembered_hostiles)
	var active_managers = turn_manager.provide_managers()
	for manager_id_entry in active_managers:
		if manager_id_entry == manager_id:
			continue
		if manager_id_entry in hostile_relations:
			var other_manager_units = active_managers.get(manager_id_entry).provide_units()
			tile_memory_update_and_check(other_manager_units, remembered_hostiles)
		
# PURPOSE: Return true if the provided unit is viewed as hostile by THIS MANAGER
func is_this_unit_hostile(provided_unit:Unit)->bool:
	var turn_manager_id:int = provided_unit._get_unit_type()
	return turn_manager_id in hostile_relations
	
# PURPOSE: Return true if the provided unit is viewed as neutral by THIS MANAGER
func is_this_unit_neutral(provided_unit:Unit)->bool:
	var turn_manager_id:int = provided_unit._get_unit_type()
	return turn_manager_id in neutral_relations
	
# PURPOSE: Return true if the provided unit is viewed as friendly by THIS MANAGER
func is_this_unit_friendly(provided_unit:Unit)->bool:
	var turn_manager_id:int = provided_unit._get_unit_type()
	return turn_manager_id in friendly_relations
	
