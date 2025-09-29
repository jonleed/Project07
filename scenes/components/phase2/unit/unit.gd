extends Node2D
class_name Unit

#export variables
@export_subgroup("Base Unit Abilities")
@export var move_dist : int = 5
@export var health : int = 10
@export var action_max : int = 1
@export var vision_dist : int = 15

#local variables
var has_moved:bool = false
var action_count : int
#this should be probably managed by damage function but i wanted something for the trap
func isHurt(amount: int):
	health -= amount;
	print("owie");
