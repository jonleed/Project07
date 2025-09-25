#we need to look into trap placement
#tile gen
extends Node2D
class_name Trap

#TODO Look into turn sequence cause traps will need to trigger inbetween a turn(?)
@export_subgroup("Base Trap Val")
#varible but will have be in close vicinity to actually commit action <5?
@export var vision_dist:  int
@export var health : int = 5
@export var move_dist : int = -1

#local vars
var action_max : int = 1
