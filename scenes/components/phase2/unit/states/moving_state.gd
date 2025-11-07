extends NPC_State
class_name Moving_State

func _ready() -> void:
	state_name = "Moving_State"

func _execute_state(prior_state:int, plan_pos:Vector2i, target_unit:Entity=null, target_action:Action=null) -> Array:
	return [State_Machine.states.DONE_STATE, plan_pos]
