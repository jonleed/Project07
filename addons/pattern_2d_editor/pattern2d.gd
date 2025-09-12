@tool
extends Resource
class_name Pattern2D

const GRIDMINIMUM:int = 1

@export var affected_tiles:PackedVector2Array 

@export var grid_size: Vector2i = Vector2i(5, 5):
	set(value):
		var new_size = Vector2i(maxi(value.x, GRIDMINIMUM), maxi(value.y, GRIDMINIMUM))
		if grid_size == new_size:
			return # No change, do nothing
		
		grid_size = new_size
		# This is the magic line. It tells the editor to rebuild the inspector.
		if Engine.is_editor_hint():
			notify_property_list_changed()


func debug():
	print("GRID SIZE : %s x %s"%[grid_size.x,grid_size.y])
	print("Entries: \n"+str(affected_tiles))
