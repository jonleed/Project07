extends Manager
class_name Player_Manager


# PURPOSE: Provide a function-hook for any initialization that needs to be run once at the start
func manager_specific_setup(not_used:int)->void:
	# Any initialization that needs to be done when the manager is first made
	pass


# PURPOSE: Run the player-manager turn
func execute_turn()->void:
	# Turn actions
	
	emit_signal("turn_complete")

# Player managers don't have relations, so we need to override scan_all_relations to use the other_manager's relations
# PURPOSE: Mark the location of other manager's units if in view
func scan_all_relations()->void:
	increment_sight_entry(remembered_friendlies)
	increment_sight_entry(remembered_neutrals)	
	increment_sight_entry(remembered_hostiles)
	var active_managers:Dictionary[int, Manager] = turn_manager.provide_managers()
	for manager_id_entry in active_managers:
		if manager_id_entry == manager_id:
			continue
		var other_manager:Manager = active_managers.get(manager_id_entry)
		var other_manager_units:Dictionary[Vector3i, Entity] = other_manager.provide_manager_units()
		if manager_id_entry == Globals.TRAP_MANAGER_ID:
			tile_memory_update_and_check(other_manager_units, remembered_hostiles)
		else:
			var other_manager_view_of_player = other_manager.provide_relation_type(manager_id)
			if other_manager_view_of_player == TurnManager.relation_types.HOSTILE:
				tile_memory_update_and_check(other_manager_units, remembered_hostiles)
			elif other_manager_view_of_player == TurnManager.relation_types.FRIENDLY:
				tile_memory_update_and_check(other_manager_units, remembered_friendlies)
			else:
				tile_memory_update_and_check(other_manager_units, remembered_neutrals)
