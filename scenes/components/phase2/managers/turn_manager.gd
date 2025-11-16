class_name Turn_Manager
extends Node

signal turn_banner_update(text: String)
signal turn_started(manager)

var unit_managers: Array[Unit_Manager] = []
var cur_turn_index: int = 0

func start():
	# Grabs all children to populate Managers array
	for manager in get_children():
		if manager.has_method("start_turn"):
			unit_managers.append(manager)
			manager.faction_turn_complete.connect(end_faction_turn)
	
	# Start first turn if exists at least one manager
	if unit_managers.size() > 0:
		call_deferred("start_faction_turn")

func start_faction_turn() -> void:
	var current_manager = unit_managers[cur_turn_index]
	emit_signal("turn_started", current_manager)
	print("On faction: ", unit_managers[cur_turn_index].faction_name)
	
	var has_units:bool = false
	for manager in unit_managers:
		manager.get_units()
		if not manager.units.is_empty():
			has_units = true
	
	if not has_units:
		return
	
	# Sends signal to TurnBannerGUI
	emit_signal("turn_banner_update", current_manager.banner_text)
	
	print("New Manager Turn Start")
	current_manager.start_turn() 

func end_faction_turn() -> void:
	cur_turn_index = (cur_turn_index + 1) % unit_managers.size()
	start_faction_turn()

func gameover() -> void:
	emit_signal("turn_banner_update", "Failure")
	
func victory() -> void:
	emit_signal("turn_banner_update", "Survived")
	
func get_random_generator() -> RandomNumberGenerator:
	return get_parent().get_random_generator()
