class_name Player_Unit_Manager
extends Unit_Manager

# TODO 
# Add Attempt Action func and calls
# DISABLED State is never called
# Wait Time / Thinking Period tied to Animation Length

@export var cursor:Cursor

signal update_unit_display(arr:Array) # Updates UnitGUI to current Party
signal unit_deselected # Deselects Selected Unit for UI
signal tile_selection(target_coord:Vector2i) # Calls for Tile Highlights
signal movement_selection(unit:Unit) # Calls for Movement Highlights
signal action_selection(act:Action) # Calls for Action Highlights
signal enable_ui_inputs(enabled:bool) # Toogles UI Inputs
signal unit_moved(unit:Unit) # Sends Unit position to Map Manager

var selected_unit: Unit = null
var selected_action: Action = null
var current_state: State = State.IDLE
var is_acting:bool = false

enum State { IDLE, MOVING, ACTING, DISABLED }
##Idle
# When it is the player's turn and a Unit is not selected
##Moving
# When an unit is selected and the player must either cancel to go back to idle or select the tile to move
##Acting
# When an action and target are decided, movement selection is disabled and actions are attempted
##Disabled
# When it is not the player's turn

func _ready() -> void:
	is_active = true
	## Connect to Cursor
	cursor.deselected.connect(_on_unit_deselected)
	cursor.unit_selected.connect(_on_unit_selected)
	cursor.tile_selected.connect(_on_tile_selection)

# var pathfinder:Pathfinder

func start():
	faction_name = "Player"
	banner_text = "Player Start"
	get_units()
	if units.size() == 0:
		print("Empty Units Array on Ready")
		end_turn()
		
	# Pathfinder can be substituted in if desired for move pattern based movement; 
	#pathfinder = Pathfinder.new(map_manager, load("res://resources/range_patterns/adjacent_tiles.tres"))
	#pathfinder._rebuild_connections()
	
	# Enter IDLE State
	enter_state(State.IDLE)

## Player Unit Manager State Machine
func enter_state(new_state: State):
	exit_state(current_state)
	current_state = new_state
	match current_state:
		State.IDLE:
			_on_enter_idle()
		State.MOVING:
			_on_enter_moving()
		State.ACTING:
			_on_enter_acting()
		State.DISABLED:
			_on_enter_disabled()

func exit_state(old_state: State):
	match old_state:
		State.IDLE:
			_on_exit_idle()
		State.MOVING:
			_on_exit_moving()
		State.ACTING:
			_on_exit_acting()
		State.DISABLED:
			_on_exit_disabled()

## State Logic
# IDLE
func _on_enter_idle():
	print("Enter Player Idle State")
	# Player IDLE phase, waits for cursor input
	var unused_units = get_unused_units()
	# Base case - No unused units remaining
	if unused_units.is_empty():
		call_deferred("end_turn") # Prevent overflow if empty manager
		return
	
	# Reset Selected Unit after check
	selected_unit = null

func _on_exit_idle():
	pass

# MOVING
func _on_enter_moving():
	print("Enter Player Moving State")
	refresh_gui()
	print("Selected unit: ", selected_unit.name)
	emit_signal("movement_selection", selected_unit) # Call Movement Highlights
	# Wait for valid tile click

func _on_exit_moving():
	pass

# ACTING
func _on_enter_acting():
	print("Enter Player Acting State")
	is_acting = true
	if not selected_unit or not selected_action:
		print("Action State Failed - No unit or action selected")
		_on_unit_deselected()
		return
	if selected_unit.action_count <= 0:
		print("Action State Failed - Out of actions")
		_on_unit_deselected()
		return
	
	emit_signal("action_selection", selected_action) # Call Action Highlights

func _on_exit_acting():
	is_acting = false

# DISABLED
func _on_enter_disabled():
	print("Enter Player Disabled State")
	emit_signal("enable_ui_inputs", false)
	is_active = false

func _on_exit_disabled():
	emit_signal("enable_ui_inputs", false)
	is_active = true

## Unit Selection
# On cursor or UnitGUI selection
func _on_unit_selected(unit:Unit) -> void:
	# Base Cases
	if not is_active: # Prevent unit selection outside of Player turn
		print("Not Player Turn")
		return
	if is_acting and unit != selected_unit: # Prevent Selection if in Acting
		print("Target unit selected: ", unit)
		player_attempt_action(unit)
		return
	if unit not in units: # Check if Player unit
		print("Unit not a player unit")
		return
	if unit.health <= 0:
		print("Unit is dead.")
		return
	if unit.action_count<1 and unit.move_count<1: # Check if Unit has actions left, if it doesnt, then unit has already acted
		print("Unit is exhausted (is out of actions and moves)")
		return
	if unit.action_count<1:
		print("Unit is out of Actions")
	if unit.move_count<1:
		print("Unit is out of movement")

	# If unit is already in moving go to IDLE / Deselect
	if unit == selected_unit:
		#enter_state(State.IDLE)
		_on_unit_deselected()
		return
	
	# Move the selected unit to front of array for GUI
	selected_unit = unit
	units.erase(unit)
	units.insert(0, unit)
	
	#enter_state(State.MOVING)
	call_deferred("enter_state", State.MOVING)

# For removing highlights for Selected Unit / Right click
func _on_unit_deselected() -> void:
	selected_unit = null
	selected_action = null
	emit_signal("unit_deselected")
	enter_state(State.IDLE)


## Helper Functions
func get_units() -> void:
	units.clear()
	for child in get_tree().get_nodes_in_group("Player Unit"):
		if not units.has(child):
			units.append(child)
	#also check the group
	reset_unit_turns() # Problematic if get_units() is run mid-turn
	print("Getting Units: ", units)

var game_over:bool = false
func _on_player_unit_health_changed(changed_node: Entity) -> void:
	if changed_node.health<=0:
		remove_unit(changed_node)
		if units.is_empty():
			print("GAME OVER")
			game_over = true
			await get_tree().process_frame
			get_tree().change_scene_to_file("res://scenes/ui/main/Main-Menu.tscn")
		refresh_gui()

# Refreshes GUI
func refresh_gui() -> void:
	emit_signal("update_unit_display", units) # Refresh UnitGUI

# Ends Turn Manager's Turn
func end_turn() -> void:
	if game_over:
		return
	print(faction_name, " Turn End")
	refresh_gui()
	_on_unit_deselected()
	#enter_state(State.DISABLED)
	emit_signal("faction_turn_complete")

# ***WIP/NEVER CALLED*** 
# Ends the selected unit's turn
func end_selected_unit_turn() -> void:
	if selected_unit:
		selected_unit.move_count = 0
		selected_unit.action_count = 0
		refresh_gui() # Always call before deselection
		_on_unit_deselected()
		print("Turn has ended")

## Tile Selection - Attempt Move / Act

func _on_tile_selection(target_coord: Vector2i):
	if not selected_unit:
		emit_signal("tile_selection", target_coord)
		return
	if is_acting:
		player_attempt_action_tile(target_coord)
	else:
		player_attempt_to_move_unit(target_coord)

func player_attempt_to_move_unit(target_coord: Vector2i):
	# 1. Ask the MapManager for the path
	var path: Array[Vector2i] = map_manager.get_star_path(selected_unit.cur_pos, target_coord)
	
	# Pathfinder can be substituted in if desired for move-pattern based movement
	# var path:PackedVector2Array = pathfinder._return_path(selected_unit.cur_pos, target_coord)

	if path.is_empty() or path[0] == Vector2i(-INF, -INF):
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
	refresh_gui()
	
	# Note: Your map_manager.entity_move function already sets
	# unit.cur_pos = new_coord, so you don't need to do it here.
	unit_moved.emit(selected_unit)
	
	# Enter new State Post-Movement Completion
	if selected_unit.move_count > 0:
		enter_state(State.MOVING)
	else: # Idk if to switch to idle when out of moves, its a preference thing 
		#enter_state(State.IDLE)
		enter_state(State.MOVING)

func player_attempt_action(target_unit: Unit):
	if not selected_unit or not selected_action:
		print("No selected unit or selected action.")
		return
	if not target_unit:
		print("No valid target unit.")
		return
	if not action_decoder:
		printerr("No ActionDecoder node assigned.")
		return
	
	print("Attempting action:", selected_action.action_name, "from", selected_unit, "on", target_unit)
	
	# 1. Check if target is in range
	var range_tiles = []
	if selected_action.range_type == 0:
		range_tiles = Globals.get_scaled_pattern_tiles(selected_unit.cur_pos, selected_action.range_pattern, selected_action.range_dist, map_manager)
	elif selected_action.range_type == 1:
		range_tiles = Globals.get_bfs_tiles(selected_unit.cur_pos, selected_action.range_dist, map_manager)
	
	if not target_unit.cur_pos in range_tiles:
		print("Target out of range.")
		return

	# 2. Prepare Array and Position for Decoder
	var targets: Array[Entity] = []
	targets.append(target_unit)
	print("Targets: ", targets)
		
	# 3. Decode and apply the effect ---
	action_decoder.decode_action(selected_action, targets, selected_unit)
	
	# 4. Reduce action count and go back to idle
	selected_unit.action_count = max(selected_unit.action_count - 1, 0)
	refresh_gui()
	
	print(selected_unit.name, "has", selected_unit.action_count, "actions left out of", selected_unit.action_max)
	if selected_unit.action_count > 0:
		enter_state(State.ACTING)
	else: 
		_on_unit_deselected()

func player_attempt_action_tile(target_coord: Vector2i):
	if not selected_unit or not selected_action:
		print("No selected unit/action.")
		return
	if selected_action is not Moveaction and selected_action is not Takeaction:
		print("Cannot use action on tile") 
		return
	
	var targets : Array[Entity] = []
	selected_action.chosen_pos = target_coord
	action_decoder.decode_action(selected_action, targets, selected_unit)

	selected_unit.action_count = max(selected_unit.action_count - 1, 0)
	refresh_gui()
	
	if selected_unit.action_count > 0:
		enter_state(State.ACTING)
	else: 
		_on_unit_deselected()



## Unit Creation
@export var unit_packed:PackedScene

func create_unit_from_res(res:UnitResource)->PlayerUnit:
	var un :PlayerUnit = unit_packed.instantiate()
	add_child(un)
	un.u_res = res
	un.load_unit_res(res)
	un.ready_entity()
	un.add_to_group("Unit")
	un.add_to_group("Player Unit")
	un.health_changed.connect(_on_player_unit_health_changed)
	return un
