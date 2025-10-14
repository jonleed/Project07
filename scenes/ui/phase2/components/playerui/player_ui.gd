extends Control

#This script controls how the player interacts with the UI
@export_subgroup("Game Nodes")
@export var map_manager:MapManager
@export var turn_manager:Turn_Manager
@export var player_unit_manager:Player_Unit_Manager

##check if any managers are missing
func _ready() -> void:
	if not (map_manager and turn_manager and player_unit_manager):
		printerr("Game Node Missing!!!")
	if not (actions_box):
		printerr("Control Node Missing!!!")

@export_subgroup("Control Nodes")
@export var actions_box:BoxContainer
@export var units_box:BoxContainer
@export var action_but_packed:PackedScene
@export var unit_icon_packed:PackedScene
##load all actions of the unit given
func load_unit_actions(un:Unit):
	clear_action_container()
	for act in un.action_array:
		add_to_action_container(act)

func add_to_action_container(act:Action):
	#create button for action
	var action_but_instance=action_but_packed.instantiate()
	action_but_instance.load_action(act)
	actions_box.add_child(action_but_instance)
	#connect action_but_instance signal
	action_but_instance.action_pressed.connect() #this signal emits with an Action variable

func clear_action_container():
	for child in actions_box.get_children():
		child.queue_free()
##Load all unit icons in the array after clearing the box
func load_unit_icons(un_array:Array[Unit]):
	clear_unit_container()
	for un:Unit in un_array:
		add_to_unit_container(un)

func add_to_unit_container(un:Unit):
	var unit_icon_instance = unit_icon_packed.instantiate()
	unit_icon_instance.load_unit(un)
	units_box.add_child(unit_icon_instance)

func clear_unit_container():
	for child in units_box.get_children():
		child.queue_free()

#we need a state machine
#the states are
##selecting
#selecting is when an action is selected and the player must either cancel to go back to idle or select the targets to move to thinking
##thinking
#thinking is when an action and target are decided and the appropriate channels are sent signals, we await a length of time then idle once more
##idle
#idle is when the player has a bunch of UI on the screen and can click most things, including the end turn
##hidden
#the player doesnt see any button UI elements, they cannot select anything and must simply watch things play out

#for the undo and redo we need a stack of things we plan on doing
#in our document we suggest that all things happen with their time as processing
#we will be making our player choices, which will be sent to resolve player choices (action decoder)
