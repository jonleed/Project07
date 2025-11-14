extends Node
class_name Flag

var counter:int = 0
var mode:bool = false # True means we've lost of this unit before, false means this is the first time we've lost sight
var clear_flag_time:int = 3
var tracking_unit:Unit
var set_position:Vector2i

func _init(provided_unit:Unit, provided_counter:int=0, provided_mode:bool=false, position_override:Vector2i=Vector2i.ZERO) -> void:
	counter = provided_counter
	mode = provided_mode
	tracking_unit = provided_unit
	if position_override == Vector2i.ZERO:
		set_position = tracking_unit.cur_pos
	else:
		set_position = position_override

func get_counter() -> int:
	return counter

func increment_counter() -> bool:
	counter += 1
	if counter > clear_flag_time:
		destroy_flag()
		return true
	return false

func get_mode() -> bool:
	return mode
	
func get_tracking_unit() -> Unit:
	return tracking_unit

func get_last_known_pos() -> Vector2i:
	return set_position
	
func destroy_flag() -> void:
	queue_free()
