extends Node2D

@export var debug_entity:Entity

func _update_timeout():
	##connected to a timer because process function was too fast
	var input_dir:Vector2 = Input.get_vector("Left","Right","Up","Down")
	
	if input_dir:
		attempt_entity_move(input_dir)

func _ready() -> void:
	attempt_entity_move(Vector2.ZERO)

##this is an example of how to move an entity
func attempt_entity_move(dir:Vector2):
	# Rotate the input vector by -45 degrees to align with the isometric grid
	var iso_dir: Vector2 = dir.rotated(-PI / 4)
	# Round the result to get the nearest clear isometric direction (e.g., (1,0) or (1,1))
	var coord_dir: Vector2i = Vector2i(iso_dir.round()) 
	var coord:Vector2i = coord_dir + debug_entity.cur_pos
	print("moving to: ",coord,$MapManager.map_dict.get(coord,null))
	if $MapManager.map_dict.get(coord,null)!=null:
		#if occupied, that means something exists here, so we will just print it
		print($MapManager.map_dict.get(coord))
	else:
		#if not occupied, that means nothing is here, so we must check whether its a walkable tile, there is an enum on the mapdict
		if $MapManager.get_surface_tile(coord) == 0:
			$MapManager.entity_move(debug_entity.cur_pos,coord)
			debug_entity.cur_pos = coord
			debug_entity.global_position = $MapManager.coords_to_glob(coord)
