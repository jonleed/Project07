class_name Player_Unit_Manager
extends Unit_Manager

# Todo: Action Selection, Move Highlights, Deselection

signal unit_selected(unit:Unit)
signal unit_deselected 
signal update_unit_display(arr:Array) # Updates UnitGUI to current Party

var selected_unit: Unit = null
#@onready var cursor = get_tree().current_scene.get_node("Cursor")
@export var cursor:Cursor

func _ready():
	faction_name = "Player"
	banner_text = "Player Start"
	cursor.unit_selected.connect(_on_unit_selected)
	cursor.deselected.connect(_on_unit_deselected)
	get_units()
	if units.size() == 0:
		print("Empty Units Array on Ready")
		end_turn()
	#refresh_gui(units[0]) #Initalize GUI
	#call_deferred("refresh_gui", units[0])

func get_units() -> void:
	units.clear()
	for child in get_tree().get_nodes_in_group("Player Unit"):
		if not units.has(child):
			units.append(child)
	#also check the group
	reset_unit_turns() # Problematic if get_units() is run mid-turn
	print("Getting Units: ", units)

# Player control phase, waits for cursor input
func _step_turn() -> void:
	var unused_units = get_unused_units()
	# Base case - No unused units remaining
	if unused_units.is_empty():
		call_deferred("end_turn") # Prevent overflow if empty manager
		return
	
	# Reset Selected Unit after check
	selected_unit = null
	
	print("Unit Selection active")

# On cursor or UnitGUI selection
func _on_unit_selected(unit:Unit) -> void:
	# Base Cases
	if not is_active: # Prevent unit selection outside of Player turn
		print("Not Player Turn")
		return
	if unit not in units: # Check if Player unit
		print("Unit not a player unit")
		return
	if unit.action_count<1 and unit.move_count<1: # Check if Unit has actions left, if it doesnt, then unit has already acted
		print("Unit is exhausted (is out of actions and moves)")
		return
	if unit.action_count<1:
		print("Unit is out of Actions")

	if unit.move_count<1:
		print("Unit is out of movement")

	if unit == selected_unit:
		_on_unit_deselected()
	
	# Move the selected unit to front of array for GUI
	units.erase(unit)
	units.insert(0, unit)

	# Update Selected Unit and GUI
	selected_unit = unit
	refresh_gui(unit)
	print("Selected unit: ", unit.name)

# For removing highlights for Selected Unit / Right click maybe
func _on_unit_deselected() -> void:
	selected_unit = null
	emit_signal("unit_deselected")
	return

# Ends the selected unit's turn
func end_selected_unit_turn() -> void:
	if selected_unit:
		selected_unit.move_count = 0
		selected_unit.action_count = 0
		refresh_gui(selected_unit) # Always call before deselection
		_on_unit_deselected()
		print("Turn has ended")

func attempt_to_move_unit(target_coord: Vector2i):
	if not selected_unit:
		return
	# 1. Ask the MapManager for the path
	var path: Array[Vector2i] = map_manager.get_star_path(selected_unit.cur_pos, target_coord)

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
	if true_distance > selected_unit.move_count:
		print("Not enough movement. Cost: %s, Has: %s" % [true_distance, selected_unit.move_count])
		return

	# 4. If everything is valid, execute the move
	print("Unit Move Count: %s\nTrue Path Cost: %s" % [selected_unit.move_count, true_distance])
	selected_unit.move_count -= true_distance
	
	# Tell the map_manager to update its dictionary and the unit's position
	map_manager.entity_move(selected_unit.cur_pos, target_coord)
	refresh_gui(selected_unit)
	
	# Note: Your map_manager.entity_move function already sets
	# unit.cur_pos = new_coord, so you don't need to do it here.

@onready var unit_packed:PackedScene = preload("res://scenes/components/phase2/unit/Player Unit.tscn")

func create_unit_from_res(res:UnitResource)->PlayerUnit:
	var un :PlayerUnit = unit_packed.instantiate()
	add_child(un)
	un.u_res = res
	un.load_unit_res(res)
	un.ready_entity()
	un.add_to_group("Unit")
	un.add_to_group("Player Unit")
	return un

func _on_player_unit_health_changed(changed_node: Entity) -> void:
	if changed_node.health<=0:
		remove_unit(changed_node)

# Refreshes GUI
func refresh_gui(unit) -> void:
	emit_signal("unit_selected", unit) # Refresh ActionGUI
	emit_signal("update_unit_display", units) # Refresh UnitGUI

#im not sure who will be holding the call to the Action Decoder to perform the operation of the action
