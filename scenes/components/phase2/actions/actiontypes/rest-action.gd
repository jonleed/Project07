extends Action
class_name Healaction
@export var base_heal:int = 0:
	set(value):
		base_heal = value
		heal = float(base_heal)*heal_mult
@export var heal_mult:float = 1.0:
	set(value):
		heal_mult = value
		heal = float(base_heal)*heal_mult
var heal : float = float(base_heal)*heal_mult
