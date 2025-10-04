extends Faction
class_name Trap_Faction

func faction_specific_setup(not_used:int)->void:
	# Any initialization that needs to be done when the faction is first made
	pass

func execute_turn()->void:
	# Turn actions
	emit_signal("turn_complete")
