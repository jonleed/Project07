@tool
extends Node2D

var spawn_locations: Array[Vector2] = [
	Vector2(-7, 4),
	Vector2(-7, 6),
	Vector2(-5, 4),
	Vector2(-5, 6)
]

func _ready() -> void:
	if Engine.is_editor_hint():
		$"CanvasLayer/UI-Phase-2".visible = false
	else:
		$"CanvasLayer/UI-Phase-2".visible = true
		#var spawn_pos = spawn_locations.pop_back()
		#var unit:Unit
		#for res in Globals.party_units:
			#print_rich("[color=Red]",res,"->",spawn_pos)
			#unit = $Turn_Manager/Player_Unit_Manager.create_unit_from_res(res)
			#$Turn_Manager/Player_Unit_Manager.add_unit(unit,Vector2i.ZERO)
			#$Turn_Manager/Player_Unit_Manager.move_unit(unit,spawn_pos)
			#await get_tree().process_frame
			#spawn_pos.x+=2
		#await get_tree().process_frame
		#$Turn_Manager/Player_Unit_Manager.refresh_gui(unit)
		#print($MapManager.map_dict)
		print_rich("[b]This is the party array: ",Globals.party_units,"[/b]")
		$Turn_Manager/Player_Unit_Manager.start_turn()
		#$Cursor.deselected.emit()

##This is a simple highlight tiles example, set up with the new cursor signal, tile clicked
var selected_coords:Array[Vector2i] = []
func _on_cursor_tile_selected(coord:Vector2i) -> void:
	if selected_coords.has(coord):
		selected_coords.erase(coord)
	else:
		selected_coords.append(coord)
	$MapManager.highlight_tiles(selected_coords,Color.GREEN)

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
