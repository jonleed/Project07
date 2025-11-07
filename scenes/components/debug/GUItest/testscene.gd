@tool
extends Node2D

@export var debug_entity:Entity

func _update_timeout():
	##connected to a timer because process function was too fast
	var input_dir:Vector2 = Input.get_vector("Left","Right","Up","Down")
	
	if input_dir:
		attempt_entity_move(debug_entity,input_dir)

func _ready() -> void:
	if Engine.is_editor_hint():
		$"CanvasLayer/UI-Phase-2".visible = false
	else:
		$"CanvasLayer/UI-Phase-2".visible = true
		#attempt_entity_spawn(debug_entity,Vector2i.ZERO)
		#attempt_entity_move(debug_entity,Vector2.ZERO)
		#var temp_vec:Vector2i = Vector2i.ONE
		#var unit:Unit
		#for res in Globals.party_units:
			#print_rich("[color=Red]",res,"->",temp_vec)
			#unit = $Turn_Manager/Player_Unit_Manager.create_unit_from_res(res)
			#$Turn_Manager/Player_Unit_Manager.add_unit(unit,Vector2i.ZERO)
			#$Turn_Manager/Player_Unit_Manager.move_unit(unit,temp_vec)
			#await get_tree().process_frame
			#temp_vec.x+=2
		#await get_tree().process_frame
		#$Turn_Manager/Player_Unit_Manager.refresh_gui(unit)
		#print($MapManager.map_dict)
		print_rich("[b]This is the party array: ",Globals.party_units,"[/b]")
		$Turn_Manager/Player_Unit_Manager.start_turn()
		$Cursor.deselected.emit()

func attempt_entity_spawn(entity:Entity,coord:Vector2i):
	if $MapManager.map_dict.get(coord,null)!=null:
		#if occupied, that means something exists here, so we will just print it
		print($MapManager.map_dict.get(coord))
	else:
		#if not occupied, that means nothing is here, so we must check whether its a walkable tile, there is an enum on the mapdict
		if $MapManager.get_surface_tile(coord) == 0:
			$MapManager.spawn_entity(entity,coord)
			entity.cur_pos = coord
			entity.global_position = $MapManager.coords_to_glob(coord)

##this is an example of how to move an entity
func attempt_entity_move(entity:Entity,dir:Vector2):
	# Rotate the input vector by -45 degrees to align with the isometric grid
	#var iso_dir: Vector2 = dir.rotated(-PI / 4)
	var iso_dir: Vector2 = dir.rotated(0)
	# Round the result to get the nearest clear isometric direction (e.g., (1,0) or (1,1))
	var coord_dir: Vector2i = Vector2i(iso_dir.round()) 
	var coord:Vector2i = coord_dir + entity.cur_pos
	print("moving to: ",coord,$MapManager.map_dict.get(coord,null))
	if $MapManager.map_dict.get(coord,null)!=null:
		#if occupied, that means something exists here, so we will just print it
		print($MapManager.map_dict.get(coord))
	else:
		#if not occupied, that means nothing is here, so we must check whether its a walkable tile, there is an enum on the mapdict
		if $MapManager.get_surface_tile(coord) == 0:
			$MapManager.entity_move(entity.cur_pos,coord)
			#entity.cur_pos = coord
			#entity.global_position = $MapManager.coords_to_glob(coord)

##This is a simple highlight tiles example, set up with the new cursor signal, tile clicked
var selected_coords:Array[Vector2i] = []
func _on_cursor_tile_selected(coord:Vector2i) -> void:
	if selected_coords.has(coord):
		selected_coords.erase(coord)
	else:
		selected_coords.append(coord)
	#$MapManager.highlight_tiles(selected_coords,Color.GREEN)

##this is a simple highlight example for a bfs targeting implementation
func _on_cursor_entity_selected(entity: Entity) -> void:
	if entity is Unit:
		@warning_ignore("unused_variable")
		var bfs_tiles = Globals.get_bfs_empty_tiles(entity.cur_pos,entity.move_count,$MapManager)
		#print("bfs tiles: ",bfs_tiles)
		@warning_ignore("unused_variable")
		var pattern_tiles = Globals.get_scaled_pattern_empty_tiles(entity.cur_pos,load("res://resources/range_patterns/debug pattern.tres"),entity.move_count,$MapManager)
		#print(pattern_tiles)
		$MapManager.highlight_tiles(bfs_tiles,Color.BLUE,3)


func _on_cursor_deselected() -> void:
	selected_coords = []
	$MapManager.highlight_tiles(selected_coords)
