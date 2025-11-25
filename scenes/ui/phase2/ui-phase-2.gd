extends Control

signal highlight_action_tiles(tiles: Array[Vector2i], color: Color, pattern:int)

#This script controls how the player interacts with the UI
@export_subgroup("Game Nodes")
@export var map_manager:MapManager
@export var turn_manager:Turn_Manager
@export var player_unit_manager:Player_Unit_Manager
@export var round_initalizer: RoundInitializer
@export var cursor:Cursor

@export_subgroup("Control Nodes")
@export var actions_box:BoxContainer
@export var action_but_packed:PackedScene
@onready var unit_gui: Control = $"Unit GUI"
@onready var turn_control_gui: Control = $"Turn Control GUI"
@onready var movement_gui: Control = $"Movement GUI"
@onready var turn_banner_gui: Control = $"TurnBanner GUI"

var selected_coords:Array[Vector2i] = []
var cur_unit_selected:Unit = null # Load all actions of selected unit

func _ready() -> void:
	## Check if any managers are missing
	if not (map_manager and turn_manager and player_unit_manager):
		printerr("Game Node Missing!!!")
	if not (actions_box):
		printerr("Control Node Missing!!!")
	
	## Connect to Player Unit Manager
	player_unit_manager.unit_deselected.connect(deselect)
	player_unit_manager.tile_selection.connect(select_tile)
	player_unit_manager.movement_selection.connect(select_unit)
	player_unit_manager.action_selection.connect(highlight_selected_action)
	player_unit_manager.enable_ui_inputs.connect(_on_toggle_inputs)
	player_unit_manager.enemy_selected.connect(select_enemy_unit)


## Helper Functions
# Only Hides Movement GUI and Action Box
func _on_toggle_selected_unit_ui(visiblity: bool):
	#turn_control_gui.visible = visiblity
	#unit_gui.visible = visiblity
	if actions_box:
		actions_box.visible = visiblity
	if movement_gui:
		movement_gui.visible = visiblity

func _on_toggle_inputs(enabled: bool):
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
			if child is Button:
				child.disabled = not enabled

## Generate all Action Buttons for Selected Unit
func load_unit_actions(unit:Unit):
	if not unit is PlayerUnit:
		return
	clear_action_container()
	for act in unit.action_array:
		add_to_action_container(act)

func add_to_action_container(action:Action):
	#create button for action
	var action_but_instance=action_but_packed.instantiate()
	action_but_instance.load_action(action)
	actions_box.add_child(action_but_instance)
	#connect action_but_instance signala
	if action_but_instance.has_signal("action_pressed"):
		#action_but_instance.action_pressed.connect(highlight_selected_action) #this signal emits with an Action variable
		
		# Set selected action in Player Unit Manager and enter Acting State
		action_but_instance.action_pressed.connect(
			func(act: Action):
				player_unit_manager.selected_action = act
				player_unit_manager.enter_state(Player_Unit_Manager.State.ACTING)
				Globals.play_ui_sound(["Confirm","Select"].pick_random())
				)
	else:
		print("Action button instance missing signal")

func clear_action_container():
	for child in actions_box.get_children():
		child.queue_free()

## Selection Functions
##This is a simple highlight tiles example, set up with the new cursor signal, tile clicked
func select_tile(coord:Vector2i) -> void:
	if selected_coords.has(coord):
		selected_coords.erase(coord)
	else:
		selected_coords.append(coord)
	map_manager.highlight_tiles(selected_coords,Color.GREEN)

##this is a simple highlight example for a bfs targeting implementation
func select_unit(unit: Unit) -> void:
	if cur_unit_selected != null and cur_unit_selected is Hostile_Unit:
		cur_unit_selected.select_ui.hide()
	_on_toggle_selected_unit_ui(true)
	draw_unit_movement(unit)
	load_unit_actions(unit)
	cur_unit_selected = unit
	@warning_ignore("unused_variable")
	var bfs_tiles = Globals.get_bfs_empty_tiles(unit.cur_pos,unit.move_count,map_manager)
	#print("bfs tiles: ",bfs_tiles)
	@warning_ignore("unused_variable")
	var pattern_tiles = Globals.get_scaled_pattern_empty_tiles(unit.cur_pos,load("res://resources/range_patterns/debug pattern.tres"),unit.move_count,map_manager)
	#print(pattern_tiles)
	map_manager.highlight_tiles(bfs_tiles,Color.BLUE,3)

func select_enemy_unit(unit: Hostile_Unit) -> void:
	if cur_unit_selected is Hostile_Unit:
		cur_unit_selected.select_ui.hide()
	draw_unit_movement(unit)
	@warning_ignore("unused_variable")
	var bfs_tiles = Globals.get_bfs_empty_tiles(unit.cur_pos,unit.move_count,map_manager)
	#print("bfs tiles: ",bfs_tiles)
	@warning_ignore("unused_variable")
	var pattern_tiles = Globals.get_scaled_pattern_empty_tiles(unit.cur_pos,load("res://resources/range_patterns/debug pattern.tres"),unit.move_count,map_manager)
	#print(pattern_tiles)
	map_manager.highlight_tiles(bfs_tiles,Color.DARK_RED,3)
	
	# Show Enemey Select UI
	unit.select_ui.show()
	unit.hp_label.text = str(int(unit.health)) 
	unit.dmg_label.text = str(int(unit.action_array[0].dmg)) 
	cur_unit_selected = unit

func deselect():
	if cur_unit_selected is Hostile_Unit:
		cur_unit_selected.select_ui.hide()
	_on_toggle_selected_unit_ui(false)
	# Clear Actions
	clear_action_container()
	# Clear Tile Highlights
	selected_coords = []
	map_manager.highlight_tiles(selected_coords)
	# Deselect Unit
	cur_unit_selected = null

## Tile Highlights
func draw_unit_movement(unit:Unit):
	if not unit is PlayerUnit:
		return
	var bfs_tiles = Globals.get_bfs_empty_tiles(unit.cur_pos,unit.move_count,map_manager)
	map_manager.highlight_tiles(bfs_tiles,Color.BLUE,3)

##this function highlights actions on the map manager
func highlight_selected_action(act:Action):
	#print("WOPIADOPIW")
	if not cur_unit_selected:
		return
	var assembled_tiles:Array[Vector2i] = []
	if act.range_type == 0:
		assembled_tiles = Globals.get_scaled_pattern_tiles(cur_unit_selected.cur_pos,act.range_pattern,act.range_dist,map_manager)
	elif act.range_type == 1:
		assembled_tiles = Globals.get_bfs_tiles(cur_unit_selected.cur_pos,act.range_dist,map_manager)
	
	var action_color:Color = Color.BLACK
	
	if act is Attackaction or act is Takeaction or act is Pushaction:
		action_color = Color.RED
	elif act is Healaction:
		action_color = Color.GREEN
	elif act is Moveaction:
		action_color = Color.BLUE
	elif act is Swapaction: # Only highlights selectable units
		action_color = Color.BLUE_VIOLET
		# Filter only tiles with an Entity on them
		var entity_tiles:Array[Vector2i] = []
		for tile in assembled_tiles:
			var entity = map_manager.map_dict.get(tile, null)
			if entity != null and entity is Entity:
				entity_tiles.append(tile)
		assembled_tiles = entity_tiles
		
	
	highlight_action_tiles.emit(assembled_tiles,action_color,1)

#for the undo and redo we need a stack of things we plan on doing
#in our document we suggest that all things happen with their time as processing
#we will be making our player choices, which will be sent to resolve player choices (action decoder)
