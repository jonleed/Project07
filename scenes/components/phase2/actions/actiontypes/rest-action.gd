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

func execute(unit:Unit) -> void:
	var unit_manager:Unit_Manager = unit.get_parent()
	var unit_manager_units:Array = unit_manager.units
	for friendly_unit in unit_manager_units:
		if Vector2(friendly_unit.cur_pos) in multihit_pattern.affected_tiles:
			friendly_unit.heal_damage(heal)
	unit.heal_damage(heal)
