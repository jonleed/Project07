extends Node
class_name Faction

var unit_manager:UnitManager
var faction_id:int
var unit_positions:Dictionary[Vector3i, Entity]
var visible_tiles:Dictionary[Vector3i, int] # Dictionary to make lookups faster (plus it acts like a set)
var explored_tiles:Dictionary[Vector3i, int] # Dictionary to make lookups faster (plus it acts like a set)
var remembered_hostiles:Dictionary[Vector3i, Array]
var remembered_neutrals:Dictionary[Vector3i, Array]
var remembered_friendlies:Dictionary[Vector3i, Array]
var max_tile_memory_time:int = 2

func _init(provided_id:int, unit_manager_ref:UnitManager):
	faction_id = provided_id
	unit_manager = unit_manager_ref

func execute_turn()->void:
	# Turn actions
	
	
	
	
	emit_signal("turn_complete")


func send_attack_action(entity_id:int, provided_action:Attackaction)->void:
	emit_signal("ATK-"+str(entity_id), provided_action)
	
func send_health_change(entity_id:int, provided_action:Healaction)->void:
	emit_signal("HEL-"+str(entity_id), provided_action)

# PURPOSE: Return an Array of Nodes of units that haven't finished their turn
func get_unfinished_turns()->Array[Entity]:
	var unfinished_arr = []
	for coordinate in unit_positions:
		var entity_obj = unit_positions.get(coordinate)
		if entity_obj.is_turn_unfinished:
			unfinished_arr.append(entity_obj)
	return unfinished_arr

# PURPOSE: Update the faction's record of a unit's position-- does not actually move the unit
func change_unit_position_ref(prior_coord:Vector3i, new_coord)->void:
	var obj_ref_holder = unit_positions.get(prior_coord)
	if prior_coord == new_coord: 
		return
	if unit_positions.get(prior_coord) == null or unit_positions.get(new_coord) != null:
		return
	unit_positions.erase(prior_coord)
	unit_positions[new_coord] = obj_ref_holder

# PURPOSE: Update the faction's record of units to include the new unit; Does not actually assign the unit to the faction.
func add_unit_ref(provided_unit:Unit)->void:
	if provided_unit == null: return
	var given_coord:Vector3i = provided_unit.provide_coordinate()
	if given_coord in unit_positions: return
	unit_positions[given_coord] = provided_unit
	provided_unit.unit_type = faction_id
	add_child(provided_unit)
	assemble_faction_vision()
	
# PURPOSE: FULLY REMOVES a given unit/Trap; DO NOT USE EXPLICITLY, use remove_unit_from_game in unit-manager, which calls this
func remove_unit(provided_unit:Entity)->void:
	var unit_type = provided_unit.provide_entity_type()
	if provided_unit == null:
		return
	if unit_type == Entity.entity_types.INTERACTABLE or unit_type == Entity.entity_types.STATIC:
		return
	var given_coord:Vector3i = provided_unit.provide_coordinate()
	if unit_type == Entity.entity_types.TRAP or unit_type == Entity.entity_types.PLAYER_UNIT or unit_type == Entity.entity_types.NPC_UNIT:
		if given_coord in unit_positions: 
			unit_positions.erase(given_coord)
		remove_child(provided_unit)
		if provided_unit is Trap:
			provided_unit.destroy_trap()
		else:
			provided_unit.destroy_unit()
		assemble_faction_vision()

# Overridden by both Player_Faction and NPC_Faction, whilst Trap_Faction will ignore it
# PURPOSE: Remove dictionary references (determined via coordinate) to a (soon-to-be-removed) unit
func remove_ref_to_other_faction_unit(provided_unit:Unit)->void:
	pass

# PURPOSE: Compile a dictionary of what tiles are visible or known of
func assemble_faction_vision()->void:
	var temp_vision_dict:Dictionary[Vector3i, int] = {}
	for current_coordinate in unit_positions:
		var current_unit:Unit = unit_positions.get(current_coordinate)
		var unit_vision = current_unit.provide_vision()
		for tile in unit_vision:
			temp_vision_dict[tile] = 1
			explored_tiles[tile] = 1
	scan_all_relations()

# Gets overriden by NPC_Faction and Player_Faction, ignored by Trap_Faction
# PURPOSE: Mark the location of other faction's units if in view
func scan_all_relations()->void:
	pass

# PURPOSE: Return a dictionary of known tiles; This is what the faction knows about their surroundings
func provide_faction_exploration()->Dictionary[Vector3i, int]:
	return explored_tiles

# PURPOSE: Return a dictionary of visible tiles; This is what the faction can actively see
func provide_faction_vision()->Dictionary[Vector3i, int]:
	return visible_tiles

# PURPOSE: Returns a boolean on whether the tile is in view or not
func is_tile_visible(provided_coordinate:Vector3i)->bool:
	return provided_coordinate in visible_tiles

# PURPOSE: Returns a boolean on whether the tile is known of or not
func has_seen_tile_before(provided_coordinate:Vector3i)->bool:
	return provided_coordinate in explored_tiles

# PURPOSE: Updates time-since-last-seen for remembered unit-posistions (last time you saw a unit when it left your vision)
func increment_sight_entry(provided_dictionary:Dictionary[Vector3i, Array])->void:
	for entry in provided_dictionary:
		provided_dictionary[entry][1] += 1
		if provided_dictionary.get(entry)[1] > max_tile_memory_time:
			provided_dictionary.erase(entry)

# PURPOSE: If the unit is visible- add a dictionary entry with the coordinate keyed to an array of [Unit, Time-since-last-seen]; Heloer function
func tile_memory_update_and_check(other_faction_units:Dictionary[Vector3i, Entity], provided_dictionary:Dictionary[Vector3i, Array])->void: 
	for tile in other_faction_units:
		if tile in visible_tiles:
			provided_dictionary[tile] = [other_faction_units.get(tile), 0]

# PURPOSE: (Limited Vision) Based off of what YOU know, returns true if you know of a unit at that coordinate
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
		
# PURPOSE: (Limited Vision) Based off of what YOU know, returns true if you know a hostile unit is at that coordinate
func is_there_a_known_hostile_there(provided_coordinate:Vector3i)->bool:
	return provided_coordinate in remembered_hostiles
	
# PURPOSE: Returns true if the unit is 'yours' (of the same faction)
func is_this_our_unit(provided_unit:Unit)->bool:
	var unit_faction_id:int = provided_unit.get_faction_id()
	return unit_faction_id == faction_id

# PURPOSE: Returns a Dictionary with coordinates keyed to an array of [Unit, time-since-last-seen], for hostiles
# ADDENDUMN: This is what should be called to get Units visible to the player (to draw on the GUI)
func provide_hostile_units()->Dictionary[Vector3i, Array]:
	return remembered_hostiles
	
# PURPOSE: Returns a Dictionary with coordinates keyed to an array of [Unit, time-since-last-seen], for neutrals
# ADDENDUMN: This is what should be called to get Units visible to the player (to draw on the GUI)
func provide_neutral_units()->Dictionary[Vector3i, Array]:
	return remembered_neutrals
	
# PURPOSE: Returns a Dictionary with coordinates keyed to an array of [Unit, time-since-last-seen], for friendlies
# ADDENDUMN: This is what should be called to get Units visible to the player (to draw on the GUI); 
func provide_friendly_units()->Dictionary[Vector3i, Array]:
	return remembered_friendlies
	
# PURPOSE: Returns a Dictionary with coordinates keyed to a Unit object of YOUR (this faction's) units
# ADDENDUMN: Do not use this for knowing what faction's units to draw on the GUI. Calling a faction's provide_faction_units() is Omniescent and performs no vision checks to see if they're visible to the player
func provide_faction_units()->Dictionary[Vector3i, Entity]:
	return unit_positions

# PURPOSE: Helper function to map a remembered_X dictionary to an array of Nodes
func map_dictionary_memory_to_array(provided_dictionary:Dictionary[Vector3i, Entity], include_units_lost_vision_of=false)->Array[Entity]:
	var return_arr = []
	for coordinate in provided_dictionary:
		var dict_entry = provided_dictionary.get(coordinate)
		if include_units_lost_vision_of:
			return_arr.append(dict_entry[0])
		else:
			# We can still see this unit
			if dict_entry[1] == 0:
				return_arr.append(dict_entry[0])
	return return_arr			
