extends Node
class_name Plan

var num_planned_actions: int = 0
var current_plan:Dictionary[int, Dictionary] = {}

func _ready() -> void:
	pass

func add_item_to_plan(provided_action:Action, path_used_for_action:PackedVector2Array=[], unit_targetted:Entity=null) -> void:
	current_plan[num_planned_actions] = Dictionary()
	current_plan[num_planned_actions]["Action"] = provided_action
	current_plan[num_planned_actions]["Path"] = path_used_for_action
	current_plan[num_planned_actions]["Targetted Unit"] = unit_targetted
	num_planned_actions += 1
	
func get_plan() -> Dictionary[int, Dictionary]:
	return current_plan

func get_num_planned_actions() -> int:
	return num_planned_actions
