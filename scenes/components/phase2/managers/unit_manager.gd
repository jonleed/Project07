class_name Unit_Manager
extends Node

# Todo: add _on_unit_health_changed

signal faction_turn_complete()

var faction_name: String = "Base Faction"
var units: Array = []
var used_units: Array = []
var is_active: bool = false 

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
	reset_unit_turns()

# Add a unit to this unit manager
func add_unit(unit: Node) -> void:
	if unit not in units:
		units.append(unit)
		add_child(unit)
		unit.has_acted = false

# Remove a unit from this unit manager
func remove_unit(unit: Node) -> void:
	if unit in units:
		units.erase(unit)
		unit.queue_free()

# Resets all unit manager's units so they can act again
func reset_unit_turns() -> void:
	for unit in units:
		unit.has_moved = false
		unit.has_acted = false

# Returns array of unused units for this unit manager's turn
func get_unused_units() -> Array:
	var unused_units = []
	for u in units:
		if not u.get("has_acted"):
			unused_units.append(u)
	return unused_units

# Returns Unit's vector2i position
func get_unit_position(unit: Entity)-> Vector2i:
	return unit.cur_pos
