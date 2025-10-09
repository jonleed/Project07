class_name Player_Unit_Manager
extends Unit_Manager

# Todo: Action Selection, Move Highlights, Deselection

signal unit_selected(Unit)
signal unit_deselected 
signal update_unit_display(Array) # Updates UnitGUI to current Party

var selected_unit: Unit = null
@onready var cursor = get_tree().current_scene.get_node("Cursor")


func _ready():
	faction_name = "Player"
	cursor.unit_selected.connect(_on_unit_selected)
	cursor.deselected.connect(_on_unit_deselected)
	
	get_units()
	if units.size() == 0:
		end_turn()
	
	emit_signal("update_unit_display", units) # Refresh UnitGUI

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
func _on_unit_selected(unit) -> void:
	# Base Cases
	if not is_active: # Prevent unit selection outside of Player turn
		print("Not Player Turn")
		return
	if unit not in units: # Check if Player unit
		print("Unit not a player unit")
		return
	if unit.has_acted: # Check if Unit is unused
		print("Unit already acted")
		return
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
