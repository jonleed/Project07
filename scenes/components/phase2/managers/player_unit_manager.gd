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
	cursor.unit_selected.connect(_on_unit_selected)
	cursor.deselected.connect(_on_unit_deselected)
	
	get_units()
	if units.size() == 0:
		end_turn()
	emit_signal("update_unit_display", units) # Refresh UnitGUI

func get_units() -> void:
	units.clear()
	for child in get_tree().get_nodes_in_group("Player Unit"):
		if not units.has(child):
			units.append(child)
	#also check the group
	reset_unit_turns()

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
	emit_signal("unit_selected", unit) # Refresh ActionGUI
	emit_signal("update_unit_display", units) # Refresh UnitGUI
	print("Selected unit: ", unit.name)

# For removing highlights for Selected Unit / Right click maybe
func _on_unit_deselected() -> void:
	selected_unit = null
	emit_signal("unit_deselected")
	return

# Ends the selected unit's turn
func end_selected_unit_turn() -> void:
	if selected_unit:
		selected_unit.has_acted = true
		_on_unit_deselected()
		print(selected_unit.name, "'s turn has ended")

func attempt_to_move_unit(coord:Vector2i):
	if selected_unit:
		if selected_unit.move_count>0 and Globals.get_bfs_empty_tiles(coord,selected_unit.move_count,map_manager).has(coord):
			move_unit(selected_unit,coord)


func _on_player_unit_health_changed(changed_node: Entity) -> void:
	if changed_node.health<=0:
		remove_unit(changed_node)

#im not sure who will be holding the call to the Action Decoder to perform the operation of the action
