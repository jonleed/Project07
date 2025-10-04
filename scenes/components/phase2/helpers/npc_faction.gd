extends Faction
class_name NPC_Faction

var friendly_relations:Dictionary[int, Faction]
var neutral_relations:Dictionary[int, Faction]
var hostile_relations:Dictionary[int, Faction]

func faction_specific_setup(relationship_to_player:int)->void:
	# Any initialization that needs to be done when the faction is first made
	var faction_dict:Dictionary[int, Faction] = unit_manager.provide_factions()
	for faction_id_entry in faction_dict:
		if faction_id_entry != Globals.PLAYER_FACTION_ID and faction_id_entry != Globals.TRAP_FACTION_ID:
			var pulled_faction:NPC_Faction = faction_dict.get(faction_id_entry)
			var pulled_faction_relations:Array = pulled_faction.provide_relations()
			if (faction_id not in pulled_faction_relations[UnitManager.relation_types.HOSTILE]) and (faction_id not in pulled_faction_relations[UnitManager.relation_types.NEUTRAL] and (faction_id not in pulled_faction_relations[UnitManager.relation_types.FRIENDLY])):
				pulled_faction.add_new_relation(UnitManager.relation_types.HOSTILE, faction_id)
		elif faction_id_entry == Globals.TRAP_FACTION_ID:
			add_new_relation(UnitManager.relation_types.HOSTILE, faction_id_entry)
		else:
			match relationship_to_player:
				UnitManager.relation_types.HOSTILE:
					add_new_relation(UnitManager.relation_types.HOSTILE, faction_id_entry)
				UnitManager.relation_types.NEUTRAL:
					add_new_relation(UnitManager.relation_types.NEUTRAL, faction_id_entry)
				UnitManager.relation_types.FRIENDLY:
					add_new_relation(UnitManager.relation_types.FRIENDLY, faction_id_entry)

func execute_turn()->void:
	# Turn actions
	emit_signal("turn_complete")


# PURPOSE: This adds a new 'relationship' entry in any of the three relations dictionaries
# ADDENDUMN: Relations are used for NPC AI to know how to respond to units from different factions
func add_new_relation(relation_type:int, provided_faction_id:int)->void:
	var other_faction_obj:Faction = unit_manager.provide_factions().get(provided_faction_id)
	match relation_type:
		UnitManager.relation_types.HOSTILE:
			hostile_relations[provided_faction_id] = other_faction_obj
		UnitManager.relation_types.NEUTRAL:
			neutral_relations[provided_faction_id] = other_faction_obj
		UnitManager.relation_types.FRIENDLY:
			friendly_relations[provided_faction_id] = other_faction_obj

# PURPOSE: Adjust the relationship entry for a faction.
# ADDENDUMN: This is NOT specifically made to make relations dynamic, but moreso as an aid during initialization; (But it CAN do that)
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

# PURPOSE: Return the type of relationship THIS FACTION has with another Faction. (How this faction views another)
func provide_relation_type(other_faction_id)->int:
	if other_faction_id in hostile_relations:
		return UnitManager.relation_types.HOSTILE
	elif other_faction_id in neutral_relations:
		return UnitManager.relation_types.NEUTRAL
	elif other_faction_id in friendly_relations:
		return UnitManager.relation_types.FRIENDLY
	else:
		return UnitManager.relation_types.UNKNOWN

# PURPOSE: Provides an array of all three relationship dictionaries
func provide_relations()->Array[Dictionary]:
	return [hostile_relations, neutral_relations, friendly_relations]

# PURPOSE: Erases all entries referencing another faction's (soon-to-be-deleted) unit
func remove_ref_to_other_faction_unit(provided_unit:Unit)->void:
	var unit_affiliation:int = provided_unit.get_faction_id()
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

# PURPOSE: Mark what Units this faction can see and where, assigning them to 'hostile', 'neutral', and 'friendly' based off of relations
func scan_all_relations()->void:
	increment_sight_entry(remembered_friendlies)
	increment_sight_entry(remembered_neutrals)	
	increment_sight_entry(remembered_hostiles)
	var active_factions:Dictionary[int, Faction] = unit_manager.provide_factions()
	for faction_id_entry in active_factions:
		if faction_id_entry == faction_id:
			continue
		var other_faction_units:Dictionary[Vector3i, Entity] = active_factions.get(faction_id_entry).provide_faction_units()
		if faction_id_entry in hostile_relations:
			tile_memory_update_and_check(other_faction_units, remembered_hostiles)
		elif faction_id_entry in friendly_relations:
			tile_memory_update_and_check(other_faction_units, remembered_friendlies)
		else:
			tile_memory_update_and_check(other_faction_units, remembered_neutrals)	

# PURPOSE: scan_all_relations, but only for hostile units
func scan_for_hostiles()->void:
	increment_sight_entry(remembered_hostiles)
	var active_factions = unit_manager.provide_factions()
	for faction_id_entry in active_factions:
		if faction_id_entry == faction_id:
			continue
		if faction_id_entry in hostile_relations:
			var other_faction_units = active_factions.get(faction_id_entry).provide_units()
			tile_memory_update_and_check(other_faction_units, remembered_hostiles)
		
# PURPOSE: Return true if the provided unit is viewed as hostile by THIS FACTION
func is_this_unit_hostile(provided_unit:Unit)->bool:
	var unit_faction_id:int = provided_unit._get_unit_type()
	return unit_faction_id in hostile_relations
	
# PURPOSE: Return true if the provided unit is viewed as neutral by THIS FACTION
func is_this_unit_neutral(provided_unit:Unit)->bool:
	var unit_faction_id:int = provided_unit._get_unit_type()
	return unit_faction_id in neutral_relations
	
# PURPOSE: Return true if the provided unit is viewed as friendly by THIS FACTION
func is_this_unit_friendly(provided_unit:Unit)->bool:
	var unit_faction_id:int = provided_unit._get_unit_type()
	return unit_faction_id in friendly_relations
	
