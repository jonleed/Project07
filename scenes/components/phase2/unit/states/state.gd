extends Node
class_name NPC_State

var state_name:String = "Unnamed State"
var cached_unit:Hostile_Unit
var cached_parent:State_Machine

func _ready() -> void:
	pass
	
func _execute_state(prior_state:int, plan_pos:Vector2i, target_unit:Entity=null, target_action:Action=null) -> Array:
	return [State_Machine.states.DONE_STATE, plan_pos, target_unit, target_action]

func set_unit_to_reference(provided_unit:Hostile_Unit) -> void:
	cached_unit = provided_unit
	cached_parent = get_parent()
