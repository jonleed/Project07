extends Node
class_name UnitManager

@export var attack_action: Attackaction

func get_enemies() -> Array: #checks for new enemies
	return get_tree().get_nodes_in_group("enemies")

func get_pc_units() -> Array: #checks for new pc-units
	return get_tree().get_nodes_in_group("PCunits")

func in_view(user: Node, target: Node) -> bool:
	var distance = user.global_position.distance_to(target.global_position) #checks distance of target
	return distance <= user.vision_dist
