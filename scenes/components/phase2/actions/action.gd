extends Resource
class_name Action
##this is the base class for the action type
#Q:1 does this action have infinite range?
@export_group("Action Stats")
@export var can_target_anywhere:bool = false #A:1 

#Q:3 can this action be used outside of vision?
#A:3 boolean check
@export var is_vision_based:bool = true

#Q:2 If not infinite range, how many tiles can it go from here
#A:2 An enum value of type of range, pattern is specific pattern, flow is waterbucket
@export_enum("Pattern","Flow") var range_type:int = 0
@export var range_pattern : Pattern2D
@export var range_dist : int = 1

#Q:4 How many tiles can this at the same time?
#A:4 same way for the range, there is a pattern and a flow
@export_enum("Pattern","Flow") var multihit_type:int = 0
@export var multihit_pattern : Pattern2D
@export var multihit_dist :int = 1

@export_group("Cosmetics")
@export var action_name:String = "Action 1"
@export var action_icon:Texture2D
@export_multiline var tool_tip:String = ""
