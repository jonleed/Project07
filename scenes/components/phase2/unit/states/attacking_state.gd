extends NPC_State
class_name Attacking_State

func _ready() -> void:
	state_name = "Attacking_State"

func _execute_state(prior_state:int, plan_pos:Vector2i, target_unit:Entity=null, target_action:Action=null) -> Array:
	cached_parent.get_plan().add_item_to_plan(target_action, [], target_unit)
	return [State_Machine.states.DONE_STATE, plan_pos,target_unit, target_action]	
	
