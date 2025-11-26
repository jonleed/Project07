extends Action
class_name Pullaction
@export var base_dmg:int = 0:
	set(value):
		base_dmg = value
		dmg = float(base_dmg)*dmg_mult
@export var dmg_mult:float = 1.0:
	set(value):
		dmg_mult = value
		dmg = float(base_dmg)*dmg_mult
var dmg : float = float(base_dmg)*dmg_mult
@export var bonus_dmg:int = 0
