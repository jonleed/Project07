extends Faction
class_name Player_Faction


# PURPOSE: Provide a function-hook for any initialization that needs to be run once at the start
func faction_specific_setup(not_used:int)->void:
	# Any initialization that needs to be done when the faction is first made
	pass


# PURPOSE: Run the player-faction turn
func execute_turn()->void:
	# Turn actions
	
	emit_signal("turn_complete")

# Player factions don't have relations, so we need to override scan_all_relations to use the other_faction's relations
# PURPOSE: Mark the location of other faction's units if in view
func scan_all_relations()->void:
	increment_sight_entry(remembered_friendlies)
	increment_sight_entry(remembered_neutrals)	
	increment_sight_entry(remembered_hostiles)
	var active_factions:Dictionary[int, Faction] = unit_manager.provide_factions()
	for faction_id_entry in active_factions:
		if faction_id_entry == faction_id:
			continue
		var other_faction:Faction = active_factions.get(faction_id_entry)
		var other_faction_units:Dictionary[Vector3i, Entity] = other_faction.provide_faction_units()
		if faction_id_entry == Globals.TRAP_FACTION_ID:
			tile_memory_update_and_check(other_faction_units, remembered_hostiles)
		else:
			var other_faction_view_of_player = other_faction.provide_relation_type(faction_id)
			if other_faction_view_of_player == UnitManager.relation_types.HOSTILE:
				tile_memory_update_and_check(other_faction_units, remembered_hostiles)
			elif other_faction_view_of_player == UnitManager.relation_types.FRIENDLY:
				tile_memory_update_and_check(other_faction_units, remembered_friendlies)
			else:
				tile_memory_update_and_check(other_faction_units, remembered_neutrals)
