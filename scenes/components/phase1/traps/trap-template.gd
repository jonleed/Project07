#we need to look into trap placement
#tile gen
extends Entity
class_name Trap

#TODO Look into turn sequence cause traps will need to trigger inbetween a turn(?)
@export_subgroup("Base Trap Val")
#varible but will have be in close vicinity to actually commit action <5?
@export var vision_dist:  int
@export var health : int = 5
@export var move_dist : int = -1

#local vars
var action_max : int = 1
var turn_manager_ref:TurnManager
var has_activated:bool = false
var finished_turn:bool = false
var is_functional:bool = true

func run_set_up(provided_info:Dictionary, provided_manager_id:int, given_turn_manager:TurnManager)->void:
	entity_type = Entity.entity_types.TRAP
	# Parse dictionary info

func execute_turn()->void:
	finished_turn = false
	if not has_activated and can_I_activate():
		has_activated = true			
	finished_turn = true
	
func on_activate()->void:
	# Put effects of triggering the trap here
	pass
	
func can_I_activate()->bool:
	if not is_functional:
		return false	
	# Put conditions to trigger trap here. 
	return false

func get_trap_status()->bool:
	return has_activated

func is_turn_unfinished()->bool:
	return not finished_turn

func dismantle_trap()->void:
	is_functional = false

func destroy_trap()->void:
	queue_free()
