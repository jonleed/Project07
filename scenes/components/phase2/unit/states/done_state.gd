extends NPC_State
class_name Done_State

func _ready() -> void:
	state_name = "Done_State"

func _execute_state(prior_state:int, plan_pos:Vector2i, target_unit:Entity=null, target_action:Action=null) -> Array:
	# This state doesn't actually do anything
	return [State_Machine.states.DONE_STATE, plan_pos, target_unit, target_action]
