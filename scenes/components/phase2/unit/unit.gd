extends Entity
class_name Unit

@export var action_array:Array[Action]

#to check if has acted, check if action_count<action_max
@export var action_max:int = 1
var action_count:int = action_max
@export var move_max:int = 5
var move_count:int = move_max
