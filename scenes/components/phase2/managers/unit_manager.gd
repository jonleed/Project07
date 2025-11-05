class_name Unit_Manager
extends Node

# Todo: add _on_unit_health_changed

signal faction_turn_complete()

var faction_name: String = "Base Faction"
var banner_text: String = "Unit Manager Start"
var units: Array[Unit] = []
var used_units: Array = []
var is_active: bool = false 
#reference to the map
@export var map_manager:MapManager
@export var action_decoder:ActionDecoder

func _ready():
	get_units()
	if units.size() == 0:
		end_turn()

# Called by TurnManager; Starts this Unit Manager's turn
func start_turn():
	print(faction_name, " Turn Start")
	is_active = true
	used_units.clear()
	reset_unit_turns()
	_step_turn()

# Main logic for Unit Manager - skeleton for the base class
func _step_turn():
	print(faction_name)
	var unused_units = get_unused_units()
	for unit in unused_units:
		unit.execute_turn()
	
	# Base case - No unused units remaining
	if unused_units.is_empty():
		end_turn()

func end_turn() -> void:
	print(faction_name, " Turn End")
	is_active = false
	emit_signal("faction_turn_complete")

# Adds childen to Units array
func get_units() -> void:
	units.clear()
	for child in get_children():
		if child is Unit:
			units.append(child)
	#also check the group
	reset_unit_turns()

@onready var base_unit_packed:PackedScene = preload("res://scenes/components/phase2/unit/Base Unit.tscn")

##use this in tandem with add_unit to create a unit resource from scratch, we do not edit these resources directly
func create_unit_from_res(res:UnitResource)->Unit:
	var un :Unit = base_unit_packed.instantiate()
	add_child(un)
	un.u_res = res
	un.load_unit_res(res)
	un.ready_entity()
	un.add_to_group("Unit")
	un.health_changed.connect(unit_health_updated)
	return un

# Add a unit to this unit manager
func add_unit(unit: Unit,coord:Vector2i) -> void:
	if unit not in units:
		if map_manager.spawn_entity(unit,coord):
			units.append(unit)
			add_child(unit)
			unit.health_changed.connect(unit_health_updated)

# Remove a unit from this unit manager
func remove_unit(unit: Unit) -> void:
	if unit in units:
		map_manager.map_dict.erase(unit.cur_pos)
		units.erase(unit)
		unit.queue_free()

# Resets all unit manager's units so they can act again
func reset_unit_turns() -> void:
	for unit in units:
		unit.action_count = unit.action_max
		unit.move_count = unit.move_max

# Returns array of unused units for this unit manager's turn
func get_unused_units() -> Array:
	var unused_units = []
	for u in units:
		if u.action_count>0 or u.move_count > 0:
			unused_units.append(u)
	return unused_units

# Returns Unit's vector2i position
func get_unit_position(unit: Unit)-> Vector2i:
	return unit.cur_pos

func unit_health_updated(given_entity:Entity) -> void:
	if given_entity.health <= 0:
		remove_unit(given_entity)

## Move a unit directly to a specific tile (don't bother finding the path to move down, has no safeties for if it exceeds move_count)
func move_unit(unit:Unit,coord:Vector2i, teleport:bool=false):
	##the true distance or the move count on a grid is just the difference between the x values and the difference between the y values
	var x_delta:int = abs(coord.x) - abs(unit.cur_pos.x)
	var y_delta:int = abs(coord.y) - abs(unit.cur_pos.y)
	var true_distance:int = abs(x_delta) + abs(y_delta)
	print("Unit Move Count: %s\ntrue distance: %s"%[unit.move_count,true_distance])
	if not teleport:
		unit.move_count-= int(true_distance)
	map_manager.entity_move(unit.cur_pos,coord)
	unit.cur_pos = coord

## Move a unit down a provided Vector2 path; go_final_distance should be TRUE for Moves, and FALSE for Attacks
func move_unit_via_path(unit:Unit, path:PackedVector2Array, go_final_distance:bool=true):
	var start_pos:Vector2i = unit.cur_pos
	unit.move_down_path(path, go_final_distance)
	var end_pos:Vector2i = unit.cur_pos
	map_manager.entity_move(start_pos, end_pos)
