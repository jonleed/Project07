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
	if not (actions_vbox):
		printerr("Control Node Missing!!!")

@export_subgroup("Control Nodes")
@export var actions_vbox:VBoxContainer
func add_to_action_container(act:Action):
	#create button for action
	var but:Button = Button.new()
	but.text = act.action_name
	
	#connect button to our state machine
	
	#add button to the vbox container
	actions_vbox.add_child(but)


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
