extends Control

signal highlight_action_tiles(tiles: Array[Vector2i], color: Color, pattern:int)

#This script controls how the player interacts with the UI
@export_subgroup("Game Nodes")
@export var map_manager:MapManager
@export var turn_manager:Turn_Manager
@export var player_unit_manager:Player_Unit_Manager

@export_subgroup("Control Nodes")
@export var actions_box:BoxContainer
@export var action_but_packed:PackedScene
@onready var unit_gui: Control = $"Unit GUI"
@onready var turn_control_gui: Control = $"Turn Control GUI"
@onready var ui_state_machine: Control = $"UI State Machine"

func _ready() -> void:
	## Check if any managers are missing
	if not (map_manager and turn_manager and player_unit_manager):
		printerr("Game Node Missing!!!")
	if not (actions_box):
		printerr("Control Node Missing!!!")
	
	## Connect to state machine
	ui_state_machine.toggle_ui.connect(_on_toggle_ui)
	ui_state_machine.toggle_inputs.connect(_on_toggle_inputs)

## For State Machine
func _on_toggle_ui(visiblity: bool):
	turn_control_gui.visible = visiblity
	unit_gui.visible = visiblity
	actions_box.visible = visiblity

# ToDo Disable Actions Container
func _on_toggle_inputs(enabled: bool):
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
			if child is Button:
				child.disabled = not enabled

## Load all actions of the unit given
var cur_unit_selected:Unit = null

##is for when right click is pressed with cursor
func deselect():
	clear_action_container()
	cur_unit_selected = null

func load_unit_actions(unit:Unit):
	clear_action_container()
	for act in unit.action_array:
		add_to_action_container(act)
	cur_unit_selected = unit

func add_to_action_container(action:Action):
	#create button for action
	var action_but_instance=action_but_packed.instantiate()
	action_but_instance.load_action(action)
	actions_box.add_child(action_but_instance)
	#connect action_but_instance signala
	if action_but_instance.has_signal("action_pressed"):
		action_but_instance.action_pressed.connect(highlight_selected_action) #this signal emits with an Action variable
	else:
		print("Action button instance missing signal")

func clear_action_container():
	for child in actions_box.get_children():
		child.queue_free()

##this function highlights actions on the map manager
func highlight_selected_action(act:Action):
	print("WOPIADOPIW")
	if not cur_unit_selected:
		return
	var assembled_tiles:Array[Vector2i] = []
	if act.range_type == 0:
		assembled_tiles = Globals.get_scaled_pattern_tiles(cur_unit_selected.cur_pos,act.range_pattern,act.range_dist,map_manager)
	elif act.range_type == 1:
		assembled_tiles = Globals.get_bfs_tiles(cur_unit_selected.cur_pos,act.range_dist,map_manager)
	
	var action_color:Color = Color.BLACK
	
	if act is Attackaction:
		action_color = Color.RED
	elif act is Healaction:
		action_color = Color.GREEN
	elif act is Moveaction:
		action_color = Color.BLUE
	
	highlight_action_tiles.emit(assembled_tiles,action_color,1)
	

#for the undo and redo we need a stack of things we plan on doing
#in our document we suggest that all things happen with their time as processing
#we will be making our player choices, which will be sent to resolve player choices (action decoder)
