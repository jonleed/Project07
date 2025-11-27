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

func start():
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

@export var base_unit_packed:PackedScene = preload("res://scenes/components/phase2/unit/Base Unit.tscn")

##use this in tandem with add_unit to create a unit resource from scratch, we do not edit these resources directly
func create_unit_from_res(res:UnitResource)->Unit:
	var un :Unit = base_unit_packed.instantiate()
	add_child(un)
	un.u_res = res
	un.load_unit_res(res)
	un.ready_entity()
	un.add_to_group("Unit")
	un.health_changed.connect(unit_health_updated)
	un.health_changed.connect(remove_unit)
	return un

# Add a unit to this unit manager
func add_unit(unit: Unit,coord:Vector2i) -> void:
	if unit not in units:
		if map_manager.spawn_entity(unit,coord):
			units.append(unit)
			if not unit.get_parent():
				add_child(unit)
				unit.health_changed.connect(unit_health_updated)


# Remove a unit from this unit manager
func remove_unit(unit: Unit) -> void:
	if unit.health>0:
		return
	if unit in units:
		map_manager.map_dict.erase(unit.cur_pos)
		map_manager.update_astar_solidity(unit.cur_pos)
		units.erase(unit)
		unit.queue_free()
	Globals.play_ui_sound("Unit_Died")

# Resets all unit manager's units so they can act again
func reset_unit_turns() -> void:
	for unit in units:
		unit.action_count = unit.action_max
		unit.move_count = unit.move_max

# Returns array of unused units for this unit manager's turn
func get_unused_units() -> Array:
	var unused_units = []
	for u in units:
		if not u:
			continue
		if (u.action_count>0 or u.move_count > 0) and u.health > 0:
			unused_units.append(u)
	return unused_units

# Returns Unit's vector2i position
func get_unit_position(unit: Unit)-> Vector2i:
	return unit.cur_pos

func unit_health_updated(given_entity:Entity) -> void:
	if given_entity.health <= 0:
		remove_unit(given_entity)

func move_unit(unit:Unit,coord:Vector2i):
	map_manager.entity_move(unit.cur_pos,coord)
	unit.cur_pos = coord

func attempt_to_move_unit(unit:Unit,target_coord: Vector2i):
	if not unit:
		return
	# 1. Ask the MapManager for the path
	var path: Array[Vector2i] = map_manager.get_star_path(unit.cur_pos, target_coord)

	if path.is_empty():
		print("No valid path found to target.")
		return # The target is unreachable (blocked by wall, entity, or water)

	# 2. Calculate the *true* distance
	# The path includes the start point, so the cost is size - 1
	var true_distance: int = path.size() - 1

	if true_distance <= 0:
		# This can happen if the path is empty or the unit is already there
		return

	# 3. Check if the unit has enough movement
	if true_distance > unit.move_count:
		print("Not enough movement. Cost: %s, Has: %s" % [true_distance, unit.move_count])
		return

	# 4. If everything is valid, execute the move
	print("Unit Move Count: %s\nTrue Path Cost: %s" % [unit.move_count, true_distance])
	unit.move_count -= true_distance
	
	# Tell the map_manager to update its dictionary and the unit's position
	map_manager.entity_move(unit.cur_pos, target_coord)
	
	# Note: Your map_manager.entity_move function already sets
	# unit.cur_pos = new_coord, so you don't need to do it here.
