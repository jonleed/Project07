extends Manager
class_name Trap_Manager

func manager_specific_setup(not_used:int)->void:
	# Any initialization that needs to be done when the manager is first made
	pass

func execute_turn()->void:
	# Turn actions
	emit_signal("turn_complete")
