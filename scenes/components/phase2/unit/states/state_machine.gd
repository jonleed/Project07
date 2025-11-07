extends Node
class_name State_Machine

var cached_unit:Hostile_Unit
var current_plan:Plan

enum states {
	IDLE_STATE,
	DONE_STATE,
	ACTING_STATE,
	ATTACKING_STATE,
	SUPPORTING_STATE,
	MOVING_STATE,
	RUNNING_STATE,
	RUSHING_STATE
}


func _ready() -> void:
	cached_unit = get_parent()
	provide_unit_to_children()

func make_plan() -> void:
	var new_plan = Plan.new()
	var next_state:int = states.IDLE_STATE
	var plan_position:Vector2i = cached_unit.cur_pos
	while next_state != states.DONE_STATE:
		var prior_state:int = next_state
		var state_info:Array = grab_state_object(next_state)._execute_state(prior_state, plan_position)
		next_state = state_info[0]
		plan_position = state_info[1]
		
	
	current_plan = new_plan
	
func grab_state_object(provided_state_id:int) -> NPC_State:
	match provided_state_id:
		states.IDLE_STATE: return $Idle_State
		states.DONE_STATE: return $Done_State
		states.ACTING_STATE: return $Acting_State
		states.ATTACKING_STATE: return $Attacking_State
		states.SUPPORTING_STATE: return $Supporting_State
		states.MOVING_STATE: return $Moving_State
		states.RUNNING_STATE: return $Running_State
		states.RUSHING_STATE: return $Rushing_State
	return $Done_State
	
func provide_unit_to_children() -> void:
	for node:NPC_State in get_children():
		node.set_unit_to_reference(cached_unit)

func get_plan() -> Plan:
	return current_plan
